[CmdletBinding()]
param(
    [string]$WowRoot,
    [string]$MetadataPath,
    [string]$TocPath,
    [ValidateSet('classicEra', 'tbcAnniversary', 'All')]
    [string]$Target = 'All'
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot

if (-not $MetadataPath) { $MetadataPath = Join-Path $repoRoot 'docs/wow-api-export.json' }
if (-not $TocPath) { $TocPath = Join-Path $repoRoot 'ApogeePartyHealthBars.toc' }

function Fail([string]$Message) {
    throw "WoW API export validation failed: $Message"
}

function Find-WowRoot([string]$StartPath) {
    if ($env:WOW_ROOT) { return $env:WOW_ROOT }

    $current = [System.IO.DirectoryInfo]::new([System.IO.Path]::GetFullPath($StartPath))
    while ($current) {
        if (Test-Path -LiteralPath (Join-Path $current.FullName '.build.info') -PathType Leaf) {
            return $current.FullName
        }
        $current = $current.Parent
    }

    if ([System.IO.Path]::DirectorySeparatorChar -eq '\') {
        $standardRoot = 'C:\Program Files (x86)\World of Warcraft'
        if (Test-Path -LiteralPath (Join-Path $standardRoot '.build.info') -PathType Leaf) {
            return $standardRoot
        }
    }
    return $null
}

function Get-TocInterfaces([string]$Path) {
    $matches = @(Get-Content -LiteralPath $Path | Where-Object { $_ -match '^## Interface:' })
    if ($matches.Count -ne 1) { Fail 'TOC must contain exactly one Interface metadata line.' }

    $value = ([regex]::Match($matches[0], '^## Interface:\s*(.+?)\s*$')).Groups[1].Value
    $parts = @($value.Split(',') | ForEach-Object { $_.Trim() })
    $malformedParts = @($parts | Where-Object { $_ -notmatch '^\d+$' })
    if ($parts.Count -eq 0 -or $malformedParts.Count -gt 0) {
        Fail "TOC Interface metadata '$value' is malformed."
    }

    $interfaces = @($parts | ForEach-Object { [int]$_ })
    if (@($interfaces | Sort-Object -Unique).Count -ne $interfaces.Count) {
        Fail 'TOC Interface metadata contains duplicate values.'
    }
    return $interfaces
}

function Get-InstalledBuilds([string]$Root) {
    $buildInfoPath = Join-Path $Root '.build.info'
    if (-not (Test-Path -LiteralPath $buildInfoPath -PathType Leaf)) {
        Fail "WoW build metadata was not found at '$buildInfoPath'."
    }

    $lines = @(Get-Content -LiteralPath $buildInfoPath)
    if ($lines.Count -lt 2) { Fail "'$buildInfoPath' is empty or malformed." }

    $headers = @($lines[0].Split('|'))
    $productIndex = -1
    $versionIndex = -1
    for ($index = 0; $index -lt $headers.Count; $index++) {
        if ($headers[$index] -like 'Product!*') { $productIndex = $index }
        if ($headers[$index] -like 'Version!*') { $versionIndex = $index }
    }
    if ($productIndex -lt 0 -or $versionIndex -lt 0) {
        Fail "'$buildInfoPath' does not contain Product and Version columns."
    }

    $builds = @{}
    foreach ($line in $lines | Select-Object -Skip 1) {
        $values = @($line.Split('|'))
        if ($values.Count -gt [Math]::Max($productIndex, $versionIndex)) {
            $builds[$values[$productIndex]] = $values[$versionIndex]
        }
    }
    return $builds
}

if (-not (Test-Path -LiteralPath $MetadataPath -PathType Leaf)) {
    Fail "tracked metadata is missing at '$MetadataPath'."
}
if (-not (Test-Path -LiteralPath $TocPath -PathType Leaf)) {
    Fail "TOC is missing at '$TocPath'."
}

try {
    $metadata = Get-Content -LiteralPath $MetadataPath -Raw | ConvertFrom-Json
}
catch {
    Fail "'$MetadataPath' is not valid JSON: $($_.Exception.Message)"
}
if (-not $metadata.PSObject.Properties['schemaVersion'] -or [int]$metadata.schemaVersion -ne 2) {
    Fail "metadata schemaVersion must be 2."
}
if (-not $metadata.PSObject.Properties['targets'] -or $null -eq $metadata.targets) {
    Fail "metadata property 'targets' is missing."
}

$targetProperties = @($metadata.targets.PSObject.Properties)
if ($targetProperties.Count -eq 0) { Fail 'metadata targets collection is empty.' }
$requiredTargets = @('classicEra', 'tbcAnniversary')
$targetNames = @($targetProperties.Name)
$sortedTargetNames = ($targetNames | Sort-Object) -join ','
$sortedRequiredTargets = ($requiredTargets | Sort-Object) -join ','
if ($sortedTargetNames -ne $sortedRequiredTargets) {
    Fail "metadata targets must be exactly: $($requiredTargets -join ', ')."
}

$interfaces = @()
$products = @()
$directories = @()
foreach ($targetProperty in $targetProperties) {
    $targetName = $targetProperty.Name
    $record = $targetProperty.Value
    foreach ($property in @('product', 'clientDirectory', 'clientVersion', 'interface', 'exportedOn', 'generatedDocumentationPath')) {
        if (-not $record.PSObject.Properties[$property] -or $null -eq $record.$property -or "$($record.$property)" -eq '') {
            Fail "metadata target '$targetName' property '$property' is missing."
        }
    }
    if ($record.clientVersion -notmatch '^\d+\.\d+\.\d+\.\d+$') {
        Fail "metadata target '$targetName' clientVersion '$($record.clientVersion)' must use X.Y.Z.BUILD format."
    }
    if ("$($record.interface)" -notmatch '^\d+$') {
        Fail "metadata target '$targetName' interface '$($record.interface)' must be numeric."
    }
    if ($record.exportedOn -notmatch '^\d{4}-\d{2}-\d{2}$') {
        Fail "metadata target '$targetName' exportedOn '$($record.exportedOn)' must use YYYY-MM-DD format."
    }
    $interfaces += [int]$record.interface
    $products += "$($record.product)"
    $directories += "$($record.clientDirectory)"
}
if (@($interfaces | Sort-Object -Unique).Count -ne $interfaces.Count) { Fail 'metadata target interfaces must be unique.' }
if (@($products | Sort-Object -Unique).Count -ne $products.Count) { Fail 'metadata target products must be unique.' }
if (@($directories | Sort-Object -Unique).Count -ne $directories.Count) { Fail 'metadata target client directories must be unique.' }

$tocInterfaces = @(Get-TocInterfaces $TocPath)
$sortedRecordedInterfaces = ($interfaces | Sort-Object) -join ','
$sortedTocInterfaces = ($tocInterfaces | Sort-Object) -join ','
if ($sortedRecordedInterfaces -ne $sortedTocInterfaces) {
    Fail "recorded interfaces '$(@($interfaces | Sort-Object) -join ', ')' do not match TOC interfaces '$(@($tocInterfaces | Sort-Object) -join ', ')'. Refresh the exports and run 'pwsh ./scripts/record-wow-api-export.ps1'."
}

if ($PSBoundParameters.ContainsKey('WowRoot')) {
    if (-not (Test-Path -LiteralPath $WowRoot -PathType Container)) {
        Fail "the explicitly supplied WoW root '$WowRoot' does not exist."
    }
}
else {
    $WowRoot = Find-WowRoot $repoRoot
}

if (-not $WowRoot) {
    if ($Target -ne 'All') {
        Fail "the explicitly requested target '$Target' could not be checked because the WoW installation was not found."
    }
    Write-Warning 'WoW installation not found. Metadata and TOC agree, but local export freshness was not checked.'
    return
}

$installedBuilds = Get-InstalledBuilds $WowRoot
$selectedNames = if ($Target -eq 'All') { $requiredTargets } else { @($Target) }
$validated = 0
foreach ($targetName in $selectedNames) {
    $record = $metadata.targets.$targetName
    $installedVersion = $installedBuilds["$($record.product)"]
    if (-not $installedVersion) {
        if ($Target -ne 'All') {
            Fail "explicitly requested target '$targetName' product '$($record.product)' is not installed."
        }
        Write-Warning "Skipping uninstalled target '$targetName' ($($record.product))."
        continue
    }
    if ($installedVersion -ne $record.clientVersion) {
        Fail "installed target '$targetName' build '$installedVersion' does not match recorded export build '$($record.clientVersion)'. Follow docs/WOW_INTERFACE_EXPORT.md, then run 'pwsh ./scripts/record-wow-api-export.ps1 -Target $targetName'."
    }

    $clientRoot = Join-Path $WowRoot $record.clientDirectory
    $documentationRoot = Join-Path $clientRoot ($record.generatedDocumentationPath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    $markerPath = Join-Path $documentationRoot 'Blizzard_APIDocumentationGenerated.toc'
    $representativePath = Join-Path $documentationRoot 'UnitDocumentation.lua'
    if (-not (Test-Path -LiteralPath $markerPath -PathType Leaf) -or -not (Test-Path -LiteralPath $representativePath -PathType Leaf)) {
        Fail "target '$targetName' generated documentation is missing or incomplete at '$documentationRoot'. Follow docs/WOW_INTERFACE_EXPORT.md, then run 'pwsh ./scripts/record-wow-api-export.ps1 -Target $targetName'."
    }

    $clientExecutablePath = Join-Path $clientRoot 'WowClassic.exe'
    if ((Test-Path -LiteralPath $clientExecutablePath -PathType Leaf) -and
        ([System.IO.File]::GetLastWriteTimeUtc($markerPath) -lt [System.IO.File]::GetLastWriteTimeUtc($clientExecutablePath))) {
        Fail "target '$targetName' generated documentation predates '$clientExecutablePath' and may belong to an older client build. Follow docs/WOW_INTERFACE_EXPORT.md, then run 'pwsh ./scripts/record-wow-api-export.ps1 -Target $targetName'."
    }

    $validated++
    Write-Host "WoW API export validation passed for $targetName ($($record.product)) build $installedVersion and interface $($record.interface)."
}
if ($validated -eq 0) {
    Write-Warning 'No recorded WoW target is installed. Metadata and TOC agree, but local export freshness was not checked.'
}
