[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$workflowPath = Join-Path $repoRoot '.github/workflows/release.yml'
$validationWorkflowPath = Join-Path $repoRoot '.github/workflows/lua-validation.yml'
$prepareReleasePath = Join-Path $PSScriptRoot 'prepare-release.ps1'
$workflow = [System.IO.File]::ReadAllText($workflowPath)
$validationWorkflow = [System.IO.File]::ReadAllText($validationWorkflowPath)
$prepareRelease = [System.IO.File]::ReadAllText($prepareReleasePath)

if ($workflow -match '(?m)^\s*args:\s+.*(?:^|\s)-c(?:\s|$)') {
    throw 'Release workflow must not pass -c to a separate packager action; it would skip copying runtime files.'
}
if ($workflow -notmatch 'gh release download') {
    throw 'Release workflow must download the public GitHub ZIP for post-publication validation.'
}
if ($workflow -notmatch 'validate-package\.ps1[^\r\n]*-ArchivePath') {
    throw 'Release workflow must validate an archive before completing.'
}
foreach ($entry in @(
    @{ Name = 'Release workflow'; Content = $workflow },
    @{ Name = 'Lua validation workflow'; Content = $validationWorkflow },
    @{ Name = 'Release preparation script'; Content = $prepareRelease }
)) {
    if ($entry.Content -notmatch 'test-lua\.ps1') {
        throw "$($entry.Name) must use the shared Lua 5.1 test runner."
    }
    if ($entry.Content -notmatch 'check-wow-api-export\.ps1') {
        throw "$($entry.Name) must validate the recorded WoW API export baseline."
    }
}

Write-Host 'Release workflow safety validation passed.'
