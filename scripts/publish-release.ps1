[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Version,

    [switch]$ConfirmProduction
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

if (-not $ConfirmProduction) {
    throw 'Production publishing requires -ConfirmProduction after explicit owner approval and completion of the in-game checklist.'
}
if ($Version -notmatch '^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$') {
    throw 'Version must use strict X.Y.Z semantic versioning.'
}
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'git is required.' }
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { throw 'GitHub CLI is required. Install it and run gh auth login.' }

gh auth status --hostname github.com
if ($LASTEXITCODE -ne 0) { throw 'GitHub CLI is not authenticated. Run gh auth login --hostname github.com --git-protocol https --web.' }
if ((git branch --show-current) -ne 'main') { throw 'Production publishing must run on main.' }
if (git status --porcelain) { throw 'Working tree must be clean.' }

git fetch origin main --tags
if ($LASTEXITCODE -ne 0) { throw 'Unable to refresh origin/main and tags.' }
if ((git rev-parse HEAD) -ne (git rev-parse origin/main)) { throw 'main must exactly match origin/main.' }
git rev-parse --verify --quiet "refs/tags/v$Version" | Out-Null
if ($LASTEXITCODE -eq 0) { throw "Tag v$Version already exists." }

$toc = Get-Content -LiteralPath (Join-Path $repoRoot 'ApogeePartyHealthBars.toc')
if ($toc -notcontains "## Version: $Version") { throw "TOC version does not match $Version." }
$changelog = Get-Content -Raw -LiteralPath (Join-Path $repoRoot 'CHANGELOG.md')
if ($changelog -notmatch "(?m)^## \[$([regex]::Escape($Version))\] - \d{4}-\d{2}-\d{2}$") {
    throw "CHANGELOG.md does not contain a dated $Version section."
}

& (Join-Path $PSScriptRoot 'validate-package.ps1') -ExpectedVersion $Version
git diff --check
if ($LASTEXITCODE -ne 0) { throw 'Whitespace validation failed.' }

git tag -a "v$Version" -m "Apogee Party Health Bars v$Version"
if ($LASTEXITCODE -ne 0) { throw "Unable to create annotated tag v$Version." }
git push origin "v$Version"
if ($LASTEXITCODE -ne 0) {
    Write-Warning "The local tag v$Version was created but could not be pushed. Resolve the connection or permission problem and rerun git push origin v$Version; do not recreate or move the tag."
    exit 1
}

Write-Host "Published production approval tag v$Version. GitHub Actions now owns packaging and publication to GitHub Releases and CurseForge."
Write-Host "Monitor: https://github.com/notify353/ApogeePartyHealthBars/actions"
