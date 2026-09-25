[CmdletBinding()]
param([string]$WowRoot, [switch]$RequireInstalled)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = Split-Path -Parent $PSScriptRoot
$record = Get-Content -Raw (Join-Path $repo 'docs/wow-api-export.json') | ConvertFrom-Json
$lock = Get-Content -Raw (Join-Path $repo 'distribution/candidate.lock.json') | ConvertFrom-Json
if ($record.interface -ne 16001 -or $record.clientVersion -ne $lock.client.reviewedBuild -or $record.product -ne 'wow_classic_beta') { throw 'Forever baseline mismatch.' }
if (-not ((Get-Content (Join-Path $repo 'ApogeePartyHealthBars.toc')) -contains '## Interface: 16001')) { throw 'Root marker interface mismatch.' }
if (-not $WowRoot -and $IsWindows) { $WowRoot = 'C:/Program Files (x86)/World of Warcraft' }
$buildInfo = if ($WowRoot) { [IO.Path]::Combine($WowRoot, '.build.info') } else { $null }
if (-not $buildInfo -or -not (Test-Path -LiteralPath $buildInfo)) {
    if ($RequireInstalled) { throw 'Authoritative installed Forever export unavailable.' }
    Write-Warning 'No local WoW installation: authoritative installed-client export could not be checked; baseline only.'
    return
}
$lines = Get-Content -LiteralPath $buildInfo
$keys = @($lines[0].Split('|') | ForEach-Object { ($_ -split '!')[0] })
$products = [Array]::IndexOf($keys, 'Product'); $versions = [Array]::IndexOf($keys, 'Version')
if ($products -lt 0 -or $versions -lt 0) { throw 'Unknown client build metadata.' }
$matching = @($lines | Select-Object -Skip 1 | ForEach-Object { $p = $_.Split('|'); if ($p.Count -gt [Math]::Max($products,$versions) -and $p[$products] -eq $record.product) { $p[$versions] } })
if ($matching.Count -ne 1 -or $matching[0] -ne $record.clientVersion) { throw 'Forever build changed/missing; refresh and review API export.' }
$client = Join-Path $WowRoot $record.clientDirectory
$export = Join-Path $client 'BlizzardInterfaceCode/Interface/AddOns'
$exe = Join-Path $client 'WowB.exe'
foreach ($entry in $record.files) {
    $path = Join-Path $export $entry.path
    if (-not (Test-Path -LiteralPath $path) -or (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $entry.sha256) { throw "Missing/stale reviewed export: $($entry.path)" }
    if ((Test-Path -LiteralPath $exe) -and (Get-Item -LiteralPath $path).LastWriteTimeUtc -lt (Get-Item -LiteralPath $exe).LastWriteTimeUtc) { throw 'Export predates installed client.' }
}
Write-Host "Authoritative Forever export verified: $($record.clientVersion) / 16001."
