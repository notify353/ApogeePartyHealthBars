[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$checkerPath = Join-Path $PSScriptRoot 'check-wow-api-export.ps1'
$recorderPath = Join-Path $PSScriptRoot 'record-wow-api-export.ps1'
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('apogee-wow-api-test-' + [guid]::NewGuid().ToString('N'))
$wowRoot = Join-Path $tempRoot 'World of Warcraft'
$metadataPath = Join-Path $tempRoot 'wow-api-export.json'
$tocPath = Join-Path $tempRoot 'ApogeePartyHealthBars.toc'
$documentationRelativePath = 'BlizzardInterfaceCode/Interface/AddOns/Blizzard_APIDocumentationGenerated'
$definitions = [ordered]@{
    classicEra = [ordered]@{
        product = 'wow_classic_era'
        clientDirectory = '_classic_era_'
        clientVersion = '1.15.8.67156'
        interface = 11508
    }
    tbcAnniversary = [ordered]@{
        product = 'wow_anniversary'
        clientDirectory = '_anniversary_'
        clientVersion = '2.5.6.68575'
        interface = 20506
    }
}

function Write-BuildInfo([string[]]$TargetNames = @('classicEra', 'tbcAnniversary'), [hashtable]$Versions = @{}) {
    $lines = @('Version!STRING:0|Product!STRING:0')
    foreach ($targetName in $TargetNames) {
        $definition = $definitions[$targetName]
        $version = if ($Versions.ContainsKey($targetName)) { $Versions[$targetName] } else { $definition.clientVersion }
        $lines += "$version|$($definition.product)"
    }
    $lines | Set-Content -LiteralPath (Join-Path $wowRoot '.build.info') -Encoding utf8NoBOM
}

function Write-Metadata([hashtable]$Versions = @{}, [hashtable]$Interfaces = @{}) {
    $targets = [ordered]@{}
    foreach ($targetName in @('classicEra', 'tbcAnniversary')) {
        $definition = $definitions[$targetName]
        $targets[$targetName] = [ordered]@{
            product = $definition.product
            clientDirectory = $definition.clientDirectory
            clientVersion = if ($Versions.ContainsKey($targetName)) { $Versions[$targetName] } else { $definition.clientVersion }
            interface = if ($Interfaces.ContainsKey($targetName)) { $Interfaces[$targetName] } else { $definition.interface }
            exportedOn = '2026-07-19'
            generatedDocumentationPath = $documentationRelativePath
        }
    }
    [ordered]@{ schemaVersion = 2; targets = $targets } |
        ConvertTo-Json -Depth 10 |
        Set-Content -LiteralPath $metadataPath -Encoding utf8NoBOM
}

function Initialize-Export([string]$TargetName) {
    $definition = $definitions[$TargetName]
    $clientRoot = Join-Path $wowRoot $definition.clientDirectory
    $documentationRoot = Join-Path $clientRoot $documentationRelativePath
    New-Item -ItemType Directory -Path $documentationRoot -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $documentationRoot 'Blizzard_APIDocumentationGenerated.toc') -Value '## Title: Blizzard API Documentation Generated' -Encoding utf8NoBOM
    Set-Content -LiteralPath (Join-Path $documentationRoot 'UnitDocumentation.lua') -Value '-- fixture' -Encoding utf8NoBOM
    Set-Content -LiteralPath (Join-Path $clientRoot 'WowClassic.exe') -Value 'fixture' -Encoding utf8NoBOM
    [System.IO.File]::SetLastWriteTimeUtc((Join-Path $clientRoot 'WowClassic.exe'), [DateTime]::UtcNow.AddMinutes(-10))
    [System.IO.File]::SetLastWriteTimeUtc((Join-Path $documentationRoot 'Blizzard_APIDocumentationGenerated.toc'), [DateTime]::UtcNow)
}

function Get-DocumentationRoot([string]$TargetName) {
    $definition = $definitions[$TargetName]
    return Join-Path (Join-Path $wowRoot $definition.clientDirectory) $documentationRelativePath
}

function Assert-Fails([scriptblock]$Action, [string]$Pattern) {
    $failed = $false
    try { & $Action }
    catch {
        $failed = $true
        if ($_.Exception.Message -notmatch $Pattern) {
            throw "Expected failure matching '$Pattern', received: $($_.Exception.Message)"
        }
    }
    if (-not $failed) { throw "Expected failure matching '$Pattern', but the command passed." }
}

New-Item -ItemType Directory -Path $wowRoot -Force | Out-Null
try {
    Set-Content -LiteralPath $tocPath -Value '## Interface: 11508, 20506' -Encoding utf8NoBOM
    foreach ($targetName in @('classicEra', 'tbcAnniversary')) { Initialize-Export $targetName }
    Write-BuildInfo
    Write-Metadata

    & $checkerPath -WowRoot $wowRoot -MetadataPath $metadataPath -TocPath $tocPath

    Write-BuildInfo -Versions @{ classicEra = '1.15.8.99999' }
    Assert-Fails { & $checkerPath -WowRoot $wowRoot -MetadataPath $metadataPath -TocPath $tocPath } "target 'classicEra'.*does not match recorded export build"

    Write-BuildInfo
    Set-Content -LiteralPath $tocPath -Value '## Interface: 20506' -Encoding utf8NoBOM
    Assert-Fails { & $checkerPath -WowRoot $wowRoot -MetadataPath $metadataPath -TocPath $tocPath } 'do not match TOC interfaces'
    Set-Content -LiteralPath $tocPath -Value '## Interface: 11508, 20506' -Encoding utf8NoBOM

    $eraDocumentationRoot = Get-DocumentationRoot 'classicEra'
    [System.IO.File]::SetLastWriteTimeUtc((Join-Path $eraDocumentationRoot 'Blizzard_APIDocumentationGenerated.toc'), [DateTime]::UtcNow.AddMinutes(-20))
    Assert-Fails { & $checkerPath -WowRoot $wowRoot -MetadataPath $metadataPath -TocPath $tocPath } "target 'classicEra'.*predates.*WowClassic\.exe"
    Assert-Fails { & $recorderPath -WowRoot $wowRoot -MetadataPath $metadataPath -TocPath $tocPath -Target classicEra } "target 'classicEra'.*predates"
    [System.IO.File]::SetLastWriteTimeUtc((Join-Path $eraDocumentationRoot 'Blizzard_APIDocumentationGenerated.toc'), [DateTime]::UtcNow)

    Remove-Item -LiteralPath (Join-Path $eraDocumentationRoot 'UnitDocumentation.lua') -Force
    Assert-Fails { & $checkerPath -WowRoot $wowRoot -MetadataPath $metadataPath -TocPath $tocPath } "target 'classicEra'.*missing or incomplete"
    Set-Content -LiteralPath (Join-Path $eraDocumentationRoot 'UnitDocumentation.lua') -Value '-- fixture' -Encoding utf8NoBOM

    Write-BuildInfo -TargetNames @('tbcAnniversary')
    $warnings = @()
    & $checkerPath -WowRoot $wowRoot -MetadataPath $metadataPath -TocPath $tocPath -WarningVariable +warnings
    if (-not ($warnings -join "`n").Contains("Skipping uninstalled target 'classicEra'")) {
        throw 'Checker did not warn for the uninstalled default target.'
    }
    Assert-Fails { & $checkerPath -WowRoot $wowRoot -MetadataPath $metadataPath -TocPath $tocPath -Target classicEra } "explicitly requested target 'classicEra'.*not installed"

    Set-Content -LiteralPath $metadataPath -Value '{ malformed' -Encoding utf8NoBOM
    Assert-Fails { & $checkerPath -WowRoot $wowRoot -MetadataPath $metadataPath -TocPath $tocPath } 'not valid JSON'
    Write-Metadata
    $malformed = Get-Content -LiteralPath $metadataPath -Raw | ConvertFrom-Json
    $malformed.schemaVersion = 1
    $malformed | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $metadataPath -Encoding utf8NoBOM
    Assert-Fails { & $checkerPath -WowRoot $wowRoot -MetadataPath $metadataPath -TocPath $tocPath } 'schemaVersion must be 2'

    Write-BuildInfo
    Write-Metadata -Versions @{ classicEra = '0.0.0.0'; tbcAnniversary = '0.0.0.0' }
    & $recorderPath -WowRoot $wowRoot -MetadataPath $metadataPath -TocPath $tocPath
    $recorded = Get-Content -LiteralPath $metadataPath -Raw | ConvertFrom-Json
    if ($recorded.targets.classicEra.clientVersion -ne $definitions.classicEra.clientVersion -or
        $recorded.targets.tbcAnniversary.clientVersion -ne $definitions.tbcAnniversary.clientVersion) {
        throw 'Recorder did not persist both installed target builds.'
    }
    $recordedText = [System.IO.File]::ReadAllText($metadataPath)
    if ($recordedText.Contains("`r") -or -not $recordedText.EndsWith("`n")) {
        throw 'Recorder did not persist LF-normalized JSON with a final newline.'
    }

    Write-Metadata -Versions @{ classicEra = '0.0.0.0'; tbcAnniversary = '9.9.9.9' }
    & $recorderPath -WowRoot $wowRoot -MetadataPath $metadataPath -TocPath $tocPath -Target classicEra
    $targeted = Get-Content -LiteralPath $metadataPath -Raw | ConvertFrom-Json
    if ($targeted.targets.classicEra.clientVersion -ne $definitions.classicEra.clientVersion -or
        $targeted.targets.tbcAnniversary.clientVersion -ne '9.9.9.9') {
        throw 'Targeted recorder changed an unrequested target or failed to update the requested target.'
    }

    Write-BuildInfo -TargetNames @('tbcAnniversary')
    Write-Metadata -Versions @{ tbcAnniversary = '0.0.0.0' }
    & $recorderPath -WowRoot $wowRoot -MetadataPath $metadataPath -TocPath $tocPath
    $singleRecorded = Get-Content -LiteralPath $metadataPath -Raw | ConvertFrom-Json
    if ($singleRecorded.targets.tbcAnniversary.clientVersion -ne $definitions.tbcAnniversary.clientVersion) {
        throw 'Default recorder did not update the only installed target.'
    }

    Write-Host 'WoW API export guard tests passed.'
}
finally {
    $safeTemp = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
    $resolvedTemp = [System.IO.Path]::GetFullPath($tempRoot)
    if ($resolvedTemp.StartsWith($safeTemp, [System.StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $resolvedTemp)) {
        Remove-Item -LiteralPath $resolvedTemp -Recurse -Force
    }
}
