[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Version
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

if ($Version -notmatch '^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$') {
    throw 'Version must use strict X.Y.Z semantic versioning.'
}
if ((git branch --show-current) -ne 'main') { throw 'Release preparation must run on main.' }
if (git status --porcelain) { throw 'Working tree must be clean.' }
git fetch origin main --tags
if ($LASTEXITCODE -ne 0) { throw 'Unable to refresh origin/main and tags.' }
if ((git rev-parse HEAD) -ne (git rev-parse origin/main)) { throw 'main must exactly match origin/main.' }
git rev-parse --verify --quiet "refs/tags/v$Version" | Out-Null
if ($LASTEXITCODE -eq 0) { throw "Tag v$Version already exists." }

$changelogPath = Join-Path $repoRoot 'CHANGELOG.md'
$changelog = [System.IO.File]::ReadAllText($changelogPath)
$match = [regex]::Match($changelog, '(?ms)^## \[Unreleased\]\r?\n(?<body>.*?)(?=^## \[)')
if (-not $match.Success -or $match.Groups['body'].Value -notmatch '(?m)^- ') {
    throw 'CHANGELOG.md Unreleased must contain at least one user-facing bullet.'
}
$date = Get-Date -Format 'yyyy-MM-dd'
$replacement = "## [Unreleased]`n`n## [$Version] - $date`n" + $match.Groups['body'].Value.Trim() + "`n`n"
$preparedChangelog = $changelog.Remove($match.Index, $match.Length).Insert($match.Index, $replacement)

$tocPath = Join-Path $repoRoot 'ApogeePartyHealthBars.toc'
$toc = [System.IO.File]::ReadAllText($tocPath)
$preparedToc = [regex]::Replace($toc, '(?m)^## Version:\s*.*$', "## Version: $Version")

try {
    [System.IO.File]::WriteAllText($changelogPath, $preparedChangelog, [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText($tocPath, $preparedToc, [System.Text.UTF8Encoding]::new($false))

    & (Join-Path $PSScriptRoot 'validate-package.ps1') -ExpectedVersion $Version

    $lua = Get-Command lua5.1 -ErrorAction SilentlyContinue
    $luac = Get-Command luac5.1 -ErrorAction SilentlyContinue
    if ($lua -and $luac) {
        Get-ChildItem -Filter '*.lua' | ForEach-Object {
            & $luac.Source -p $_.FullName
            if ($LASTEXITCODE -ne 0) { throw "Lua parsing failed for $($_.Name)." }
        }
        Get-ChildItem tests -Filter '*_spec.lua' | ForEach-Object {
            & $lua.Source $_.FullName
            if ($LASTEXITCODE -ne 0) { throw "Lua test failed: $($_.Name)." }
        }
    }
    else {
        Write-Warning 'Lua 5.1 is not installed locally; GitHub CI remains the authoritative Lua validation.'
    }

    git diff --check
    if ($LASTEXITCODE -ne 0) { throw 'Whitespace validation failed.' }
}
catch {
    [System.IO.File]::WriteAllText($changelogPath, $changelog, [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText($tocPath, $toc, [System.Text.UTF8Encoding]::new($false))
    throw
}

git add CHANGELOG.md ApogeePartyHealthBars.toc
git commit -m "Prepare Apogee Party Health Bars v$Version"
if ($LASTEXITCODE -ne 0) { throw 'Unable to create release-preparation commit.' }
Write-Host "Prepared v$Version. Review and push this commit, wait for CI, complete in-game checks, then create the annotated tag."
