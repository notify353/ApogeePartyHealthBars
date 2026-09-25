[CmdletBinding()]
param([switch]$ConfirmReviewed, [string]$WowRoot = 'C:/Program Files (x86)/World of Warcraft')
$ErrorActionPreference = 'Stop'
if (-not $ConfirmReviewed) { throw 'Review current generated APIs/source first; pass -ConfirmReviewed only after that review.' }
$repo = Split-Path -Parent $PSScriptRoot
$path = Join-Path $repo 'docs/wow-api-export.json'
$record = Get-Content -Raw $path | ConvertFrom-Json
$export = Join-Path $WowRoot "$($record.clientDirectory)/BlizzardInterfaceCode/Interface/AddOns"
foreach ($entry in $record.files) { $entry.sha256 = (Get-FileHash -LiteralPath (Join-Path $export $entry.path) -Algorithm SHA256).Hash.ToLowerInvariant() }
$original = [IO.File]::ReadAllText($path)
try {
    [IO.File]::WriteAllText($path, ($record | ConvertTo-Json -Depth 10) + "`n", [Text.UTF8Encoding]::new($false))
    & (Join-Path $PSScriptRoot 'check-wow-api-export.ps1') -WowRoot $WowRoot -RequireInstalled
} catch { [IO.File]::WriteAllText($path, $original, [Text.UTF8Encoding]::new($false)); throw }
Write-Host 'Reviewed API hashes recorded; inspect and commit the diff.'
