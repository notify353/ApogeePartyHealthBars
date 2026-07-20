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
    throw "WoW API export recording failed: $Message"
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

function Get-InstalledBuilds([string]$Root) {
    $buildInfoPath = Join-Path $Root '.build.info'
    if (-not (Test-Path -LiteralPath $buildInfoPath -PathType Leaf)) {
        Fail "the WoW installation metadata was not found at '$buildInfoPath'."
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
        Fail '.build.info has no Product or Version column.'
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
    Fail "metadata is missing at '$MetadataPath'."
}
try {
    $metadata = Get-Content -LiteralPath $MetadataPath -Raw | ConvertFrom-Json
}
catch {
    Fail "'$MetadataPath' is not valid JSON: $($_.Exception.Message)"
}
if (-not $metadata.PSObject.Properties['schemaVersion'] -or [int]$metadata.schemaVersion -ne 2 -or
    -not $metadata.PSObject.Properties['targets'] -or $null -eq $metadata.targets) {
    Fail 'metadata must use schemaVersion 2 with a targets collection.'
}
foreach ($requiredTarget in @('classicEra', 'tbcAnniversary')) {
    if (-not $metadata.targets.PSObject.Properties[$requiredTarget]) {
        Fail "metadata target '$requiredTarget' is missing."
    }
}
if ($Target -ne 'All' -and -not $metadata.targets.PSObject.Properties[$Target]) {
    Fail "metadata target '$Target' is missing."
}

if (-not $WowRoot) { $WowRoot = Find-WowRoot $repoRoot }
if (-not $WowRoot) {
    Fail 'the WoW installation and .build.info could not be found. Set WOW_ROOT or pass -WowRoot.'
}
$installedBuilds = Get-InstalledBuilds $WowRoot

$requestedNames = if ($Target -eq 'All') { @('classicEra', 'tbcAnniversary') } else { @($Target) }
$selectedNames = @()
foreach ($targetName in $requestedNames) {
    $record = $metadata.targets.$targetName
    foreach ($property in @('product', 'clientDirectory', 'clientVersion', 'interface', 'exportedOn', 'generatedDocumentationPath')) {
        if (-not $record.PSObject.Properties[$property] -or $null -eq $record.$property -or "$($record.$property)" -eq '') {
            Fail "metadata target '$targetName' property '$property' is missing."
        }
    }
    if ($installedBuilds.ContainsKey("$($record.product)")) {
        $selectedNames += $targetName
    }
    elseif ($Target -ne 'All') {
        Fail "explicitly requested target '$targetName' product '$($record.product)' is not installed."
    }
    else {
        Write-Warning "Skipping uninstalled target '$targetName' ($($record.product))."
    }
}
if ($selectedNames.Count -eq 0) { Fail 'none of the recorded WoW targets are installed.' }

foreach ($targetName in $selectedNames) {
    $record = $metadata.targets.$targetName
    $clientRoot = Join-Path $WowRoot $record.clientDirectory
    $documentationRoot = Join-Path $clientRoot ($record.generatedDocumentationPath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    foreach ($requiredFile in @('Blizzard_APIDocumentationGenerated.toc', 'UnitDocumentation.lua')) {
        if (-not (Test-Path -LiteralPath (Join-Path $documentationRoot $requiredFile) -PathType Leaf)) {
            Fail "target '$targetName' file '$requiredFile' is missing from '$documentationRoot'. Run 'exportInterfaceFiles code' in that client and close WoW before retrying."
        }
    }

    $clientExecutablePath = Join-Path $clientRoot 'WowClassic.exe'
    $exportMarkerPath = Join-Path $documentationRoot 'Blizzard_APIDocumentationGenerated.toc'
    if ((Test-Path -LiteralPath $clientExecutablePath -PathType Leaf) -and
        ([System.IO.File]::GetLastWriteTimeUtc($exportMarkerPath) -lt [System.IO.File]::GetLastWriteTimeUtc($clientExecutablePath))) {
        Fail "target '$targetName' generated documentation predates '$clientExecutablePath'. Run 'exportInterfaceFiles code', close WoW, and retry."
    }

    $record.clientVersion = $installedBuilds["$($record.product)"]
    $record.exportedOn = (Get-Date).ToString('yyyy-MM-dd')
}

$json = ($metadata | ConvertTo-Json -Depth 10) -replace "`r`n", "`n"
[System.IO.File]::WriteAllText($MetadataPath, $json + "`n", [System.Text.UTF8Encoding]::new($false))

& (Join-Path $PSScriptRoot 'check-wow-api-export.ps1') -WowRoot $WowRoot -MetadataPath $MetadataPath -TocPath $TocPath -Target $Target
Write-Host "Recorded WoW API export target(s): $($selectedNames -join ', ')."
