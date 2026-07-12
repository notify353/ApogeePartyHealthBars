[CmdletBinding()]
param(
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$tocPath = Join-Path $repoRoot 'ApogeePartyHealthBars.toc'
$versionLine = Get-Content -LiteralPath $tocPath | Where-Object { $_ -match '^## Version:\s*(.+)$' } | Select-Object -First 1
if (-not $versionLine) { throw 'TOC version metadata is missing.' }
$version = ([regex]::Match($versionLine, '^## Version:\s*(.+)$')).Groups[1].Value.Trim()

if (-not $OutputPath) {
    $OutputPath = Join-Path $repoRoot ".release/ApogeePartyHealthBars-v$version.zip"
}
elseif (-not [System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath = Join-Path $repoRoot $OutputPath
}

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("apogee-package-" + [guid]::NewGuid().ToString('N'))
$packageRoot = Join-Path $tempRoot 'ApogeePartyHealthBars'
New-Item -ItemType Directory -Path $packageRoot -Force | Out-Null

try {
    $runtimeFiles = Get-Content -LiteralPath $tocPath | ForEach-Object { $_.Trim() } | Where-Object {
        $_ -and -not $_.StartsWith('#')
    }
    $files = @('ApogeePartyHealthBars.toc', 'LICENSE', 'README.md') + $runtimeFiles
    foreach ($file in ($files | Sort-Object -Unique)) {
        Copy-Item -LiteralPath (Join-Path $repoRoot $file) -Destination (Join-Path $packageRoot $file)
    }

    & (Join-Path $PSScriptRoot 'validate-package.ps1') -ExpectedVersion $version -PackageRoot $packageRoot
    $outputDirectory = Split-Path -Parent $OutputPath
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
    Compress-Archive -LiteralPath $packageRoot -DestinationPath $OutputPath -CompressionLevel Optimal -Force
    & (Join-Path $PSScriptRoot 'validate-package.ps1') -ExpectedVersion $version -ArchivePath $OutputPath
    Write-Host "Created $OutputPath"
}
finally {
    $safeTemp = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
    $resolvedTemp = [System.IO.Path]::GetFullPath($tempRoot)
    if ($resolvedTemp.StartsWith($safeTemp, [System.StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $resolvedTemp)) {
        Remove-Item -LiteralPath $resolvedTemp -Recurse -Force
    }
}
