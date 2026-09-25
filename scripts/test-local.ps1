[CmdletBinding()]
param([string]$SourcesRoot = 'C:/Dev/WoW', [string]$ArtifactRoot)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = Split-Path -Parent $PSScriptRoot
if (-not $ArtifactRoot) { $ArtifactRoot = Join-Path $repo ('.release/validation-' + [guid]::NewGuid().ToString('N')) }
Push-Location $repo
try {
    & ./scripts/check-wow-api-export.ps1
    python -B tests/distribution/test_repository.py
    if ($LASTEXITCODE -ne 0) { throw 'Distribution repository validation failed.' }
    python -B tests/distribution/test_curseforge.py
    if ($LASTEXITCODE -ne 0) { throw 'CurseForge preflight validation failed.' }
    python -B tests/distribution/test_publisher.py
    if ($LASTEXITCODE -ne 0) { throw 'Publisher validation failed.' }
    foreach ($test in @('test_distribution','test_migration','test_dual')) {
        python -B "tests/distribution/$test.py" --sources-root $SourcesRoot --artifacts (Join-Path $ArtifactRoot $test)
        if ($LASTEXITCODE -ne 0) { throw "$test failed." }
    }
    python -B scripts/dual_distribution.py --sources-root $SourcesRoot --output (Join-Path $ArtifactRoot 'packages')
    if ($LASTEXITCODE -ne 0) { throw 'Aggregate build failed.' }
    git diff --check
    if ($LASTEXITCODE -ne 0) { throw 'Whitespace validation failed.' }
    Write-Host "Full distribution validation passed. Artifacts: $ArtifactRoot"
} finally { Pop-Location }
