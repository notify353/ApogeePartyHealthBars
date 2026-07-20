[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$checkerPath = Join-Path $PSScriptRoot 'check-dev-links.ps1'
$setterPath = Join-Path $PSScriptRoot 'set-dev-links.ps1'

$checker = Get-Content -LiteralPath $checkerPath -Raw
$setter = Get-Content -LiteralPath $setterPath -Raw
foreach ($required in @('classicEra', 'tbcAnniversary', 'Wrong workspace', 'Not a junction')) {
    if (-not $checker.Contains($required)) { throw "Development link checker is missing '$required'." }
}
foreach ($required in @('SupportsShouldProcess', "LinkType -ne 'Junction'", 'Get-Process', 'restoring every junction')) {
    if (-not $setter.Contains($required)) { throw "Development link setter is missing safety behavior '$required'." }
}

if ([System.IO.Path]::DirectorySeparatorChar -ne '\') {
    Write-Host 'Development link behavior test skipped outside Windows; source safety checks passed.'
    exit 0
}

$fixtureRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("aphb-dev-links-" + [guid]::NewGuid().ToString('N'))
$repo = Join-Path $fixtureRoot 'repo'
$wow = Join-Path $fixtureRoot 'wow'
try {
    New-Item -ItemType Directory -Path $repo -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $repo 'ApogeePartyHealthBars.toc') -Value '## Interface: 11508, 20506'
    foreach ($directory in @('_classic_era_', '_anniversary_')) {
        New-Item -ItemType Directory -Path (Join-Path $wow "$directory\Interface\AddOns") -Force | Out-Null
    }

    & $setterPath -WowRoot $wow -RepoRoot $repo -Target All
    & $checkerPath -WowRoot $wow -RepoRoot $repo -Target All

    $unsafePath = Join-Path $wow '_classic_era_\Interface\AddOns\ApogeePartyHealthBars'
    Remove-Item -LiteralPath $unsafePath -Force
    New-Item -ItemType Directory -Path $unsafePath | Out-Null
    $rejected = $false
    try { & $setterPath -WowRoot $wow -RepoRoot $repo -Target classicEra }
    catch { $rejected = $_.Exception.Message -like '*Refusing to replace non-junction*' }
    if (-not $rejected -or (Get-Item -LiteralPath $unsafePath).LinkType) {
        throw 'Development link setter did not preserve and reject a real add-on directory.'
    }
}
finally {
    if (Test-Path -LiteralPath $fixtureRoot) {
        Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
    }
}

Write-Host 'Development link management tests passed.'
