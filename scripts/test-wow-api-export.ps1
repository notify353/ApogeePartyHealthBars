[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$checkerPath = Join-Path $PSScriptRoot 'check-wow-api-export.ps1'
$recorderPath = Join-Path $PSScriptRoot 'record-wow-api-export.ps1'
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('apogee-wow-api-test-' + [guid]::NewGuid().ToString('N'))
$wowRoot = Join-Path $tempRoot 'World of Warcraft'
$clientRoot = Join-Path $wowRoot '_anniversary_'
$documentationRoot = Join-Path $clientRoot 'BlizzardInterfaceCode/Interface/AddOns/Blizzard_APIDocumentationGenerated'
$metadataPath = Join-Path $tempRoot 'wow-api-export.json'
$tocPath = Join-Path $tempRoot 'ApogeePartyHealthBars.toc'

function Write-BuildInfo([string]$Version) {
    @(
        'Version!STRING:0|Product!STRING:0'
        "$Version|wow_anniversary"
    ) | Set-Content -LiteralPath (Join-Path $wowRoot '.build.info') -Encoding utf8NoBOM
}

function Write-Metadata([string]$Version, [int]$Interface) {
    [ordered]@{
        product = 'wow_anniversary'
        clientDirectory = '_anniversary_'
        clientVersion = $Version
        interface = $Interface
        exportedOn = '2026-07-14'
        generatedDocumentationPath = 'BlizzardInterfaceCode/Interface/AddOns/Blizzard_APIDocumentationGenerated'
    } | ConvertTo-Json | Set-Content -LiteralPath $metadataPath -Encoding utf8NoBOM
}

function Assert-Fails([scriptblock]$Action, [string]$Pattern) {
    $failed = $false
    try {
        & $Action
    }
    catch {
        $failed = $true
        if ($_.Exception.Message -notmatch $Pattern) {
            throw "Expected failure matching '$Pattern', received: $($_.Exception.Message)"
        }
    }
    if (-not $failed) { throw "Expected failure matching '$Pattern', but the command passed." }
}

New-Item -ItemType Directory -Path $documentationRoot -Force | Out-Null
try {
    Set-Content -LiteralPath (Join-Path $documentationRoot 'Blizzard_APIDocumentationGenerated.toc') -Value '## Title: Blizzard API Documentation Generated' -Encoding utf8NoBOM
    Set-Content -LiteralPath (Join-Path $documentationRoot 'UnitDocumentation.lua') -Value '-- fixture' -Encoding utf8NoBOM
    Set-Content -LiteralPath (Join-Path $clientRoot 'WowClassic.exe') -Value 'fixture' -Encoding utf8NoBOM
    [System.IO.File]::SetLastWriteTimeUtc((Join-Path $clientRoot 'WowClassic.exe'), [DateTime]::UtcNow.AddMinutes(-10))
    [System.IO.File]::SetLastWriteTimeUtc((Join-Path $documentationRoot 'Blizzard_APIDocumentationGenerated.toc'), [DateTime]::UtcNow)
    Set-Content -LiteralPath $tocPath -Value '## Interface: 20506' -Encoding utf8NoBOM
    Write-BuildInfo '2.5.6.68575'
    Write-Metadata '2.5.6.68575' 20506

    & $checkerPath -WowRoot $wowRoot -MetadataPath $metadataPath -TocPath $tocPath

    Write-BuildInfo '2.5.6.99999'
    Assert-Fails { & $checkerPath -WowRoot $wowRoot -MetadataPath $metadataPath -TocPath $tocPath } 'does not match recorded export build'

    Write-BuildInfo '2.5.6.68575'
    Set-Content -LiteralPath $tocPath -Value '## Interface: 20507' -Encoding utf8NoBOM
    Assert-Fails { & $checkerPath -WowRoot $wowRoot -MetadataPath $metadataPath -TocPath $tocPath } 'does not match TOC interface'

    Set-Content -LiteralPath $tocPath -Value '## Interface: 20506' -Encoding utf8NoBOM
    [System.IO.File]::SetLastWriteTimeUtc((Join-Path $documentationRoot 'Blizzard_APIDocumentationGenerated.toc'), [DateTime]::UtcNow.AddMinutes(-20))
    Assert-Fails { & $checkerPath -WowRoot $wowRoot -MetadataPath $metadataPath -TocPath $tocPath } 'predates.*WowClassic\.exe'
    Assert-Fails { & $recorderPath -WowRoot $wowRoot -MetadataPath $metadataPath -TocPath $tocPath } 'predates'
    [System.IO.File]::SetLastWriteTimeUtc((Join-Path $documentationRoot 'Blizzard_APIDocumentationGenerated.toc'), [DateTime]::UtcNow)

    Remove-Item -LiteralPath (Join-Path $documentationRoot 'UnitDocumentation.lua') -Force
    Assert-Fails { & $checkerPath -WowRoot $wowRoot -MetadataPath $metadataPath -TocPath $tocPath } 'missing or incomplete'

    Set-Content -LiteralPath (Join-Path $documentationRoot 'UnitDocumentation.lua') -Value '-- fixture' -Encoding utf8NoBOM
    Write-Metadata '0.0.0.0' 20506
    & $recorderPath -WowRoot $wowRoot -MetadataPath $metadataPath -TocPath $tocPath
    $recorded = Get-Content -LiteralPath $metadataPath -Raw | ConvertFrom-Json
    if ($recorded.clientVersion -ne '2.5.6.68575' -or [int]$recorded.interface -ne 20506) {
        throw 'Recorder did not persist the installed build and TOC interface.'
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
