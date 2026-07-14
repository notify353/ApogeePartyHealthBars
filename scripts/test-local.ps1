[CmdletBinding()]
param(
    [string]$LuaPath,
    [string]$LuacPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repoRoot = Split-Path -Parent $PSScriptRoot
$luaArguments = @{}
if ($PSBoundParameters.ContainsKey('LuaPath')) { $luaArguments.LuaPath = $LuaPath }
if ($PSBoundParameters.ContainsKey('LuacPath')) { $luaArguments.LuacPath = $LuacPath }

Push-Location $repoRoot
try {
    & (Join-Path $PSScriptRoot 'test-lua.ps1') @luaArguments
    & (Join-Path $PSScriptRoot 'validate-package.ps1')
    & (Join-Path $PSScriptRoot 'validate-release-workflow.ps1')
    & (Join-Path $PSScriptRoot 'build-package.ps1') -OutputPath (Join-Path $repoRoot '.release/local-validation.zip')

    git diff --check
    if ($LASTEXITCODE -ne 0) { throw 'Whitespace validation failed.' }

    Write-Host 'Full local validation passed.'
}
finally {
    Pop-Location
}
