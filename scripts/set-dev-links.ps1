[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [string]$WowRoot,
    [string]$RepoRoot,
    [ValidateSet('classicEra', 'tbcAnniversary', 'All')]
    [string]$Target = 'All'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if ([System.IO.Path]::DirectorySeparatorChar -ne '\') {
    throw 'Development junction management is supported only on Windows.'
}
if (-not $RepoRoot) { $RepoRoot = Split-Path -Parent $PSScriptRoot }
$RepoRoot = [System.IO.Path]::GetFullPath($RepoRoot)

function Find-WowRoot {
    if ($env:WOW_ROOT) { return [System.IO.Path]::GetFullPath($env:WOW_ROOT) }
    $standardRoot = 'C:\Program Files (x86)\World of Warcraft'
    if (Test-Path -LiteralPath $standardRoot -PathType Container) { return $standardRoot }
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

$runningClients = @(Get-Process -Name 'Wow', 'WowClassic', 'WowClassicT' -ErrorAction SilentlyContinue |
    Where-Object {
        try {
            $_.Path -and [System.IO.Path]::GetFullPath($_.Path).StartsWith(
                $WowRoot, [System.StringComparison]::OrdinalIgnoreCase)
        }
        catch { $false }
    })
if ($runningClients.Count -gt 0) {
    $descriptions = $runningClients | ForEach-Object { "$($_.Name) (PID $($_.Id))" }
    throw "Close World of Warcraft before changing development junctions: $($descriptions -join ', ')."
}

$definitions = @(
    [pscustomobject]@{ Name = 'classicEra'; ClientDirectory = '_classic_era_' },
    [pscustomobject]@{ Name = 'tbcAnniversary'; ClientDirectory = '_anniversary_' }
)
if ($Target -ne 'All') {
    $definitions = @($definitions | Where-Object Name -eq $Target)
}

$operations = @()
foreach ($definition in $definitions) {
    $clientPath = Join-Path $WowRoot $definition.ClientDirectory
    if (-not (Test-Path -LiteralPath $clientPath -PathType Container)) {
        Write-Warning "Skipping uninstalled client '$($definition.Name)' at '$clientPath'."
        continue
    }
    $addOnsPath = Join-Path $clientPath 'Interface\AddOns'
    if (-not (Test-Path -LiteralPath $addOnsPath -PathType Container)) {
        throw "AddOns directory is missing for '$($definition.Name)': $addOnsPath"
    }
    $linkPath = Join-Path $addOnsPath 'ApogeePartyHealthBars'
    $originalTarget = $null
    if (Test-Path -LiteralPath $linkPath) {
        $item = Get-Item -LiteralPath $linkPath -Force
        if ($item.LinkType -ne 'Junction') {
            throw "Refusing to replace non-junction add-on path: $linkPath"
        }
        $originalTarget = $item.Target -join ','
    }
    $operations += [pscustomobject]@{
        Name = $definition.Name
        LinkPath = $linkPath
        OriginalTarget = $originalTarget
    }
}
if ($operations.Count -eq 0) { throw 'No installed supported clients were found.' }

$changed = @()
try {
    foreach ($operation in $operations) {
        if ($operation.OriginalTarget -and [System.StringComparer]::OrdinalIgnoreCase.Equals(
                [System.IO.Path]::GetFullPath($operation.OriginalTarget), $RepoRoot)) {
            Write-Host "$($operation.Name): already linked to $RepoRoot"
            continue
        }
        if (-not $PSCmdlet.ShouldProcess($operation.LinkPath, "link to $RepoRoot")) { continue }

        $changed += $operation
        if (Test-Path -LiteralPath $operation.LinkPath) {
            Remove-Item -LiteralPath $operation.LinkPath -Force
        }
        New-Item -ItemType Junction -Path $operation.LinkPath -Target $RepoRoot -ErrorAction Stop | Out-Null
        Write-Host "$($operation.Name): linked to $RepoRoot"
    }
}
catch {
    $failure = $_
    Write-Warning 'Link update failed; restoring every junction changed by this run.'
    for ($index = $changed.Count - 1; $index -ge 0; $index--) {
        $operation = $changed[$index]
        if (Test-Path -LiteralPath $operation.LinkPath) {
            $item = Get-Item -LiteralPath $operation.LinkPath -Force
            if ($item.LinkType -eq 'Junction') { Remove-Item -LiteralPath $operation.LinkPath -Force }
        }
        if ($operation.OriginalTarget) {
            New-Item -ItemType Junction -Path $operation.LinkPath -Target $operation.OriginalTarget | Out-Null
        }
    }
    throw $failure
}

if (-not $WhatIfPreference) {
    & (Join-Path $PSScriptRoot 'check-dev-links.ps1') -WowRoot $WowRoot -RepoRoot $RepoRoot -Target $Target
}
