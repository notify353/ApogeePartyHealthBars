[CmdletBinding()]
param(
    [string]$ExpectedVersion,
    [string]$PackageRoot,
    [string]$ArchivePath
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$tocPath = Join-Path $repoRoot 'ApogeePartyHealthBars.toc'

function Fail([string]$Message) {
    throw "Package validation failed: $Message"
}

if (-not (Test-Path -LiteralPath $tocPath -PathType Leaf)) {
    Fail 'ApogeePartyHealthBars.toc is missing.'
}

$tocLines = Get-Content -LiteralPath $tocPath
$versionLine = $tocLines | Where-Object { $_ -match '^## Version:\s*(.+)$' } | Select-Object -First 1
if (-not $versionLine) { Fail 'TOC version metadata is missing.' }
$tocVersion = ([regex]::Match($versionLine, '^## Version:\s*(.+)$')).Groups[1].Value.Trim()

if ($ExpectedVersion -and $tocVersion -ne $ExpectedVersion) {
    Fail "TOC version '$tocVersion' does not match expected version '$ExpectedVersion'."
}

$curseLine = $tocLines | Where-Object { $_ -match '^## X-Curse-Project-ID:\s*1608100\s*$' }
if (-not $curseLine) { Fail 'TOC CurseForge project ID must be 1608100.' }

$runtimeFiles = @()
foreach ($line in $tocLines) {
    $value = $line.Trim()
    if (-not $value -or $value.StartsWith('#')) { continue }
    $runtimeFiles += $value.Replace('\', '/')
    if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $value) -PathType Leaf)) {
        Fail "TOC references missing file '$value'."
    }
}

if ($runtimeFiles.Count -eq 0) { Fail 'TOC contains no runtime files.' }
$expectedFiles = @('ApogeePartyHealthBars.toc', 'LICENSE', 'README.md') + $runtimeFiles
$expectedFiles = $expectedFiles | Sort-Object -Unique

if ($PackageRoot) {
    $resolvedPackage = (Resolve-Path -LiteralPath $PackageRoot).Path
    $packagePrefix = $resolvedPackage.TrimEnd([char[]]'\/') + [System.IO.Path]::DirectorySeparatorChar
    $actualFiles = Get-ChildItem -LiteralPath $resolvedPackage -File -Recurse | ForEach-Object {
        $_.FullName.Substring($packagePrefix.Length).Replace('\', '/')
    } | Sort-Object -Unique
    $missing = $expectedFiles | Where-Object { $_ -notin $actualFiles }
    $unexpected = $actualFiles | Where-Object { $_ -notin $expectedFiles }
    if ($missing) { Fail "Package directory is missing: $($missing -join ', ')." }
    if ($unexpected) { Fail "Package directory contains unexpected files: $($unexpected -join ', ')." }
}

if ($ArchivePath) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $ArchivePath).Path)
    try {
        $actualEntries = $archive.Entries | Where-Object { -not $_.FullName.EndsWith('/') } | ForEach-Object {
            $_.FullName.Replace('\', '/')
        } | Sort-Object -Unique
    }
    finally {
        $archive.Dispose()
    }
    $expectedEntries = $expectedFiles | ForEach-Object { "ApogeePartyHealthBars/$_" } | Sort-Object -Unique
    $missing = $expectedEntries | Where-Object { $_ -notin $actualEntries }
    $unexpected = $actualEntries | Where-Object { $_ -notin $expectedEntries }
    if ($missing) { Fail "Archive is missing: $($missing -join ', ')." }
    if ($unexpected) { Fail "Archive contains unexpected files or extra nesting: $($unexpected -join ', ')." }
}

Write-Host "Package validation passed for version $tocVersion with $($expectedFiles.Count) files."
