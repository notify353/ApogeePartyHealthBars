[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repoRoot = Split-Path -Parent $PSScriptRoot

$legacyPatterns = @(
    'ApogeePartyHealthBars_(GeneralConfig|HealingConfig|Dot(Data|Tracker|Hud|Config)|Key(Data|Layouts|Actions|Config)|Wheel(Data|Layouts|Macros|Config)|ConfigUI|ConfigController|ConfigSurfaces)'
    '\b(configTab|RegisterTab|ActivateTab|RefreshTab|RefreshActiveTab)\b'
    '"(healing|keys|wheel|buttons|dots)"'
)

$migrationAllowlist = @(
    (Join-Path $repoRoot 'Core\Effects.lua')
    (Join-Path $repoRoot 'Profiles\ProfileStore.lua')
)

$sourceFiles = Get-ChildItem -LiteralPath $repoRoot -File -Recurse -Filter '*.lua' |
    Where-Object {
        $_.FullName -notlike (Join-Path $repoRoot 'tests\*') -and
        $_.FullName -notin $migrationAllowlist
    }

$violations = @()
foreach ($file in $sourceFiles) {
    $relativePath = $file.FullName.Substring($repoRoot.Length + 1)
    $lineNumber = 0
    foreach ($line in Get-Content -LiteralPath $file.FullName) {
        $lineNumber++
        foreach ($pattern in $legacyPatterns) {
            if ($line -cmatch $pattern) {
                $violations += "${relativePath}:${lineNumber}: $($Matches[0])"
            }
        }
    }
}

$unexpectedRootLua = Get-ChildItem -LiteralPath $repoRoot -File -Filter '*.lua' |
    Where-Object { $_.Name -ne 'ApogeePartyHealthBars.lua' }
foreach ($file in $unexpectedRootLua) {
    $violations += "$($file.Name): production modules belong in a domain folder"
}

if ($violations.Count -gt 0) {
    throw "Legacy terminology validation failed:`n$($violations -join "`n")"
}

Write-Host 'Internal terminology validation passed.'
