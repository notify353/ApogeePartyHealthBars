[CmdletBinding()]
param([Parameter(Mandatory)][string]$Version, [switch]$ConfirmProduction, [string]$SourcesRoot = 'C:/Dev/WoW')
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if (-not $ConfirmProduction) { throw 'Explicit immediate approval and -ConfirmProduction are required.' }
if ($Version -notmatch '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$') { throw 'Stable X.Y.Z version required.' }
$repo = Split-Path -Parent $PSScriptRoot
Push-Location $repo
try {
    if ((git branch --show-current) -ne 'main' -or (git status --porcelain)) { throw 'Clean main required.' }
    if ((git remote get-url origin).TrimEnd('/') -notmatch '^https://github.com/notify353/ApogeePartyHealthBars(\.git)?$') { throw 'Unexpected remote.' }
    git fetch origin main
    if ($LASTEXITCODE -ne 0) { throw 'Fetch failed.' }
    $head = git rev-parse HEAD
    if ($head -ne (git rev-parse origin/main)) { throw 'Main is not synchronized.' }
    $lock = Get-Content distribution/candidate.lock.json -Raw | ConvertFrom-Json
    if ($lock.version -ne $Version) { throw 'Version does not match the preparation commit.' }
    $workflow = Get-Content .github/workflows/release.yml -Raw
    if ($workflow -notmatch 'publish_distribution.py upload') { throw 'Production workflow is inactive.' }
    $checks = gh api "repos/notify353/ApogeePartyHealthBars/commits/$head/check-runs?per_page=100" | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) { throw 'Cannot verify hosted checks.' }
    foreach ($name in @('test','aggregate','version')) {
        $check = @($checks.check_runs | Where-Object name -EQ $name | Sort-Object started_at -Descending | Select-Object -First 1)
        if ($check.Count -ne 1 -or $check[0].status -ne 'completed' -or $check[0].conclusion -ne 'success') { throw "Required check $name is not successful for this commit." }
    }
    $tag = "v$Version"
    $localTag = git tag --list $tag
    if ($localTag) { throw 'Local tag already exists; never reuse or move it.' }
    git ls-remote --exit-code --tags origin "refs/tags/$tag"
    $remoteTagExit = $LASTEXITCODE
    if ($remoteTagExit -eq 0) { throw 'Remote tag already exists; never reuse or move it.' }
    if ($remoteTagExit -ne 2) { throw 'Could not check remote tag.' }
    $stage = Join-Path $repo ('.release/tag-review-' + [guid]::NewGuid().ToString('N'))
    python -B scripts/publish_distribution.py stage --version $Version --sources-root $SourcesRoot --output $stage
    if ($LASTEXITCODE -ne 0) { throw 'Exact release validation failed.' }
    git tag -a $tag -m "Apogee Forever $Version" $head
    if ($LASTEXITCODE -ne 0) { throw 'Tag creation failed.' }
    git push origin "refs/tags/$tag"
    if ($LASTEXITCODE -ne 0) { throw 'Tag push failed or uncertain; inspect remote before any retry. Local tag retained.' }
    Write-Host 'Production tag pushed. Monitor Actions, CurseForge approval and remote-byte verification before declaring release complete.'
} finally { Pop-Location }
