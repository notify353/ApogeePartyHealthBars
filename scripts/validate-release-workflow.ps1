[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$workflowPath = Join-Path $repoRoot '.github/workflows/release.yml'
$workflow = [System.IO.File]::ReadAllText($workflowPath)

if ($workflow -match '(?m)^\s*args:\s+.*(?:^|\s)-c(?:\s|$)') {
    throw 'Release workflow must not pass -c to a separate packager action; it would skip copying runtime files.'
}
if ($workflow -notmatch 'gh release download') {
    throw 'Release workflow must download the public GitHub ZIP for post-publication validation.'
}
if ($workflow -notmatch 'validate-package\.ps1[^\r\n]*-ArchivePath') {
    throw 'Release workflow must validate an archive before completing.'
}

Write-Host 'Release workflow safety validation passed.'
