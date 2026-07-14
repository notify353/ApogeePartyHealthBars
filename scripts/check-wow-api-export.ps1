[CmdletBinding()]
param(
    [string]$WowRoot,
    [string]$MetadataPath,
    [string]$TocPath
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot

if (-not $MetadataPath) { $MetadataPath = Join-Path $repoRoot 'docs/wow-api-export.json' }
if (-not $TocPath) { $TocPath = Join-Path $repoRoot 'ApogeePartyHealthBars.toc' }

function Fail([string]$Message) {
    throw "WoW API export validation failed: $Message"
}

function Find-WowRoot([string]$StartPath) {
    if ($env:WOW_ROOT) {
        return $env:WOW_ROOT
    }

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

function Get-InstalledBuild([string]$Root, [string]$Product) {
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

    foreach ($line in $lines | Select-Object -Skip 1) {
        $values = @($line.Split('|'))
        if ($values.Count -gt [Math]::Max($productIndex, $versionIndex) -and $values[$productIndex] -eq $Product) {
            return $values[$versionIndex]
        }
    }

    Fail "Product '$Product' was not found in '$buildInfoPath'."
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

foreach ($property in @('product', 'clientDirectory', 'clientVersion', 'interface', 'exportedOn', 'generatedDocumentationPath')) {
    if (-not $metadata.PSObject.Properties[$property] -or $null -eq $metadata.$property -or "$($metadata.$property)" -eq '') {
        Fail "metadata property '$property' is missing."
    }
}
if ($metadata.clientVersion -notmatch '^\d+\.\d+\.\d+\.\d+$') {
    Fail "metadata clientVersion '$($metadata.clientVersion)' must use X.Y.Z.BUILD format."
}
if ($metadata.exportedOn -notmatch '^\d{4}-\d{2}-\d{2}$') {
    Fail "metadata exportedOn '$($metadata.exportedOn)' must use YYYY-MM-DD format."
}

$tocLine = Get-Content -LiteralPath $TocPath | Where-Object { $_ -match '^## Interface:\s*(\d+)\s*$' } | Select-Object -First 1
if (-not $tocLine) { Fail 'TOC Interface metadata is missing or malformed.' }
$tocInterface = [int]([regex]::Match($tocLine, '^## Interface:\s*(\d+)\s*$').Groups[1].Value)
if ([int]$metadata.interface -ne $tocInterface) {
    Fail "recorded interface '$($metadata.interface)' does not match TOC interface '$tocInterface'. Refresh the export and run 'pwsh ./scripts/record-wow-api-export.ps1'."
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
    Write-Warning "WoW installation not found. Metadata and TOC agree, but local export freshness was not checked."
    return
}

$installedVersion = Get-InstalledBuild $WowRoot $metadata.product
if ($installedVersion -ne $metadata.clientVersion) {
    Fail "installed $($metadata.product) build '$installedVersion' does not match recorded export build '$($metadata.clientVersion)'. Follow docs/WOW_INTERFACE_EXPORT.md, then run 'pwsh ./scripts/record-wow-api-export.ps1'."
}

$clientRoot = Join-Path $WowRoot $metadata.clientDirectory
$documentationRoot = Join-Path $clientRoot ($metadata.generatedDocumentationPath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$markerPath = Join-Path $documentationRoot 'Blizzard_APIDocumentationGenerated.toc'
$representativePath = Join-Path $documentationRoot 'UnitDocumentation.lua'

if (-not (Test-Path -LiteralPath $markerPath -PathType Leaf) -or -not (Test-Path -LiteralPath $representativePath -PathType Leaf)) {
    Fail "generated documentation is missing or incomplete at '$documentationRoot'. Follow docs/WOW_INTERFACE_EXPORT.md, then run 'pwsh ./scripts/record-wow-api-export.ps1'."
}

$clientExecutablePath = Join-Path $clientRoot 'WowClassic.exe'
if ((Test-Path -LiteralPath $clientExecutablePath -PathType Leaf) -and
    ([System.IO.File]::GetLastWriteTimeUtc($markerPath) -lt [System.IO.File]::GetLastWriteTimeUtc($clientExecutablePath))) {
    Fail "the generated documentation predates '$clientExecutablePath' and may belong to an older client build. Follow docs/WOW_INTERFACE_EXPORT.md, then run 'pwsh ./scripts/record-wow-api-export.ps1'."
}

Write-Host "WoW API export validation passed for $($metadata.product) build $installedVersion and interface $tocInterface."
