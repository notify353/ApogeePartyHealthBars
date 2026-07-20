[CmdletBinding()]
param(
    [string]$WowRoot,
    [string]$RepoRoot,
    [ValidateSet('classicEra', 'tbcAnniversary', 'All')]
    [string]$Target = 'All'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (-not $RepoRoot) { $RepoRoot = Split-Path -Parent $PSScriptRoot }
$RepoRoot = [System.IO.Path]::GetFullPath($RepoRoot)

function Find-WowRoot {
    if ($env:WOW_ROOT) { return [System.IO.Path]::GetFullPath($env:WOW_ROOT) }
    if ([System.IO.Path]::DirectorySeparatorChar -eq '\') {
        $standardRoot = 'C:\Program Files (x86)\World of Warcraft'
        if (Test-Path -LiteralPath $standardRoot -PathType Container) { return $standardRoot }
    }
    return $null
}

if (-not $WowRoot) { $WowRoot = Find-WowRoot }
if (-not $WowRoot -or -not (Test-Path -LiteralPath $WowRoot -PathType Container)) {
    throw 'World of Warcraft root was not found. Pass -WowRoot or set WOW_ROOT.'
}
$WowRoot = [System.IO.Path]::GetFullPath($WowRoot)

if (-not (Test-Path -LiteralPath (Join-Path $RepoRoot 'ApogeePartyHealthBars.toc') -PathType Leaf)) {
    throw "Repository root is invalid or missing the TOC: $RepoRoot"
}

$definitions = @(
    [pscustomobject]@{ Name = 'classicEra'; ClientDirectory = '_classic_era_' },
    [pscustomobject]@{ Name = 'tbcAnniversary'; ClientDirectory = '_anniversary_' }
)
if ($Target -ne 'All') {
    $definitions = @($definitions | Where-Object Name -eq $Target)
}

$branch = (& git -C $RepoRoot branch --show-current 2>$null | Select-Object -First 1)
$commit = (& git -C $RepoRoot rev-parse --short HEAD 2>$null | Select-Object -First 1)
$workingChanges = @(& git -C $RepoRoot status --porcelain 2>$null).Count -gt 0
if (-not $branch) { $branch = '(detached or unavailable)' }
if (-not $commit) { $commit = '(unavailable)' }
Write-Host "Workspace: $RepoRoot"
Write-Host "Git: $branch @ $commit$(if ($workingChanges) { ' + working changes' })"

$failures = @()
$results = foreach ($definition in $definitions) {
    $clientPath = Join-Path $WowRoot $definition.ClientDirectory
    $linkPath = Join-Path $clientPath 'Interface\AddOns\ApogeePartyHealthBars'
    $status = 'Not installed'
    $actualTarget = $null

    if (Test-Path -LiteralPath $clientPath -PathType Container) {
        if (-not (Test-Path -LiteralPath $linkPath)) {
            $status = 'Missing link'
            $failures += "$($definition.Name): add-on link is missing"
        }
        else {
            $item = Get-Item -LiteralPath $linkPath -Force
            $actualTarget = $item.Target -join ','
            if ($item.LinkType -ne 'Junction') {
                $status = 'Not a junction'
                $failures += "$($definition.Name): add-on path is not a junction"
            }
            elseif (-not [System.StringComparer]::OrdinalIgnoreCase.Equals(
                    [System.IO.Path]::GetFullPath($actualTarget), $RepoRoot)) {
                $status = 'Wrong workspace'
                $failures += "$($definition.Name): points to '$actualTarget'"
            }
            elseif (-not (Test-Path -LiteralPath (Join-Path $linkPath 'ApogeePartyHealthBars.toc') -PathType Leaf)) {
                $status = 'Broken junction'
                $failures += "$($definition.Name): linked TOC is missing"
            }
            else {
                $status = 'Ready'
            }
        }
    }

    [pscustomobject]@{
        Client = $definition.Name
        Status = $status
        Link = $linkPath
        Target = $actualTarget
    }
}

foreach ($result in $results) {
    Write-Host "$($result.Client): $($result.Status)"
    Write-Host "  Link:   $($result.Link)"
    Write-Host "  Target: $($result.Target)"
}
if ($failures.Count -gt 0) {
    throw "Development link check failed: $($failures -join '; '). Run 'pwsh ./scripts/set-dev-links.ps1 -Target $Target' with WoW closed."
}
