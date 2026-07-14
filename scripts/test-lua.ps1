[CmdletBinding()]
param(
    [string]$LuaPath,
    [string]$LuacPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repoRoot = Split-Path -Parent $PSScriptRoot

function Resolve-Executable {
    param(
        [string]$ExplicitPath,
        [string[]]$Candidates,
        [string]$Label
    )

    if ($ExplicitPath) {
        if (Test-Path -LiteralPath $ExplicitPath -PathType Leaf) {
            return (Resolve-Path -LiteralPath $ExplicitPath).Path
        }
        $explicitCommand = Get-Command $ExplicitPath -CommandType Application -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($explicitCommand) { return $explicitCommand.Source }
        throw "$Label executable was not found at '$ExplicitPath'."
    }

    foreach ($candidate in $Candidates) {
        $command = Get-Command $candidate -CommandType Application -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($command) { return $command.Source }
    }

    throw "$Label was not found. Install Lua for Windows 5.1.5, restart PowerShell, or pass an explicit path."
}

$lua = Resolve-Executable -ExplicitPath $LuaPath -Candidates @('lua5.1', 'lua51', 'lua') -Label 'Lua 5.1'
$luac = Resolve-Executable -ExplicitPath $LuacPath -Candidates @('luac5.1', 'luac51', 'luac') -Label 'Lua 5.1 compiler'

$luaVersion = (& $lua -e 'io.write(_VERSION)' 2>&1 | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $luaVersion -ne 'Lua 5.1') {
    throw "Expected Lua 5.1 at '$lua', found '$luaVersion'."
}

$luacVersion = (& $luac -v 2>&1 | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $luacVersion -notmatch 'Lua 5\.1') {
    throw "Expected a Lua 5.1 compiler at '$luac', found '$luacVersion'."
}

Push-Location $repoRoot
try {
    $sourceFiles = @(Get-ChildItem -LiteralPath $repoRoot -File -Filter '*.lua' | Sort-Object Name)
    if ($sourceFiles.Count -eq 0) { throw 'No add-on Lua source files were found.' }
    foreach ($file in $sourceFiles) {
        & $luac -p $file.FullName
        if ($LASTEXITCODE -ne 0) { throw "Lua parsing failed: $($file.Name)." }
    }

    $specFiles = @(Get-ChildItem -LiteralPath (Join-Path $repoRoot 'tests') -File -Filter '*_spec.lua' | Sort-Object Name)
    if ($specFiles.Count -eq 0) { throw 'No Lua specifications were found.' }
    foreach ($spec in $specFiles) {
        & $lua $spec.FullName
        if ($LASTEXITCODE -ne 0) { throw "Lua test failed: $($spec.Name)." }
    }

    Write-Host "Lua 5.1 validation passed: $($sourceFiles.Count) source files and $($specFiles.Count) specs."
}
finally {
    Pop-Location
}
