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

if (-not (Test-Path -LiteralPath $MetadataPath -PathType Leaf)) {
    throw "WoW API export recording failed: metadata is missing at '$MetadataPath'."
}

$metadata = Get-Content -LiteralPath $MetadataPath -Raw | ConvertFrom-Json
$requiredProperties = @('product', 'clientDirectory', 'generatedDocumentationPath')
foreach ($property in $requiredProperties) {
    if (-not $metadata.PSObject.Properties[$property] -or -not $metadata.$property) {
        throw "WoW API export recording failed: metadata property '$property' is missing."
    }
}

if (-not $WowRoot) {
    if ($env:WOW_ROOT) {
        $WowRoot = $env:WOW_ROOT
    }
    else {
        $current = [System.IO.DirectoryInfo]::new([System.IO.Path]::GetFullPath($repoRoot))
        while ($current -and -not (Test-Path -LiteralPath (Join-Path $current.FullName '.build.info') -PathType Leaf)) {
            $current = $current.Parent
        }
        if ($current) { $WowRoot = $current.FullName }
    }
}
if (-not $WowRoot) {
    $standardRoot = 'C:\Program Files (x86)\World of Warcraft'
    if (Test-Path -LiteralPath (Join-Path $standardRoot '.build.info') -PathType Leaf) {
        $WowRoot = $standardRoot
    }
}
if (-not $WowRoot -or -not (Test-Path -LiteralPath (Join-Path $WowRoot '.build.info') -PathType Leaf)) {
    throw 'WoW API export recording failed: the WoW installation and .build.info could not be found. Set WOW_ROOT or pass -WowRoot.'
}

$buildLines = @(Get-Content -LiteralPath (Join-Path $WowRoot '.build.info'))
$headers = @($buildLines[0].Split('|'))
$productIndex = -1
$versionIndex = -1
for ($index = 0; $index -lt $headers.Count; $index++) {
    if ($headers[$index] -like 'Product!*') { $productIndex = $index }
    if ($headers[$index] -like 'Version!*') { $versionIndex = $index }
}
if ($productIndex -lt 0 -or $versionIndex -lt 0) {
    throw 'WoW API export recording failed: .build.info has no Product or Version column.'
}

$installedVersion = $null
foreach ($line in $buildLines | Select-Object -Skip 1) {
    $values = @($line.Split('|'))
    if ($values.Count -gt [Math]::Max($productIndex, $versionIndex) -and $values[$productIndex] -eq $metadata.product) {
        $installedVersion = $values[$versionIndex]
        break
    }
}
if (-not $installedVersion) {
    throw "WoW API export recording failed: product '$($metadata.product)' is not installed."
}

$documentationRoot = Join-Path (Join-Path $WowRoot $metadata.clientDirectory) ($metadata.generatedDocumentationPath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
foreach ($requiredFile in @('Blizzard_APIDocumentationGenerated.toc', 'UnitDocumentation.lua')) {
    if (-not (Test-Path -LiteralPath (Join-Path $documentationRoot $requiredFile) -PathType Leaf)) {
        throw "WoW API export recording failed: '$requiredFile' is missing from '$documentationRoot'. Run 'exportInterfaceFiles code' and close WoW before retrying."
    }
}

$clientExecutablePath = Join-Path (Join-Path $WowRoot $metadata.clientDirectory) 'WowClassic.exe'
$exportMarkerPath = Join-Path $documentationRoot 'Blizzard_APIDocumentationGenerated.toc'
if ((Test-Path -LiteralPath $clientExecutablePath -PathType Leaf) -and
    ([System.IO.File]::GetLastWriteTimeUtc($exportMarkerPath) -lt [System.IO.File]::GetLastWriteTimeUtc($clientExecutablePath))) {
    throw "WoW API export recording failed: the generated documentation predates '$clientExecutablePath'. Run 'exportInterfaceFiles code', close WoW, and retry."
}

$tocLine = Get-Content -LiteralPath $TocPath | Where-Object { $_ -match '^## Interface:\s*(\d+)\s*$' } | Select-Object -First 1
if (-not $tocLine) { throw 'WoW API export recording failed: TOC Interface metadata is missing or malformed.' }
$tocInterface = [int]([regex]::Match($tocLine, '^## Interface:\s*(\d+)\s*$').Groups[1].Value)

$record = [ordered]@{
    product = $metadata.product
    clientDirectory = $metadata.clientDirectory
    clientVersion = $installedVersion
    interface = $tocInterface
    exportedOn = (Get-Date).ToString('yyyy-MM-dd')
    generatedDocumentationPath = $metadata.generatedDocumentationPath
}
$json = ($record | ConvertTo-Json) -replace "`r`n", "`n"
[System.IO.File]::WriteAllText($MetadataPath, $json + "`n", [System.Text.UTF8Encoding]::new($false))

& (Join-Path $PSScriptRoot 'check-wow-api-export.ps1') -WowRoot $WowRoot -MetadataPath $MetadataPath -TocPath $TocPath
Write-Host "Recorded WoW API export for $($metadata.product) build $installedVersion and interface $tocInterface."
