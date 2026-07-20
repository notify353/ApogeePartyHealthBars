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

$interfaceLines = @($tocLines | Where-Object { $_ -match '^## Interface:' })
if ($interfaceLines.Count -ne 1) { Fail 'TOC must contain exactly one Interface metadata line.' }
$interfaceValue = ([regex]::Match($interfaceLines[0], '^## Interface:\s*(.+?)\s*$')).Groups[1].Value
$interfaceParts = @($interfaceValue.Split(',') | ForEach-Object { $_.Trim() })
$malformedInterfaces = @($interfaceParts | Where-Object { $_ -notmatch '^\d+$' })
if ($interfaceParts.Count -eq 0 -or $malformedInterfaces.Count -gt 0) {
    Fail "TOC Interface metadata '$interfaceValue' is malformed."
}
$actualInterfaces = @($interfaceParts | ForEach-Object { [int]$_ } | Sort-Object -Unique)
$expectedInterfaces = @(11508, 20506)
if (($actualInterfaces -join ',') -ne ($expectedInterfaces -join ',')) {
    Fail "TOC interfaces must be exactly '$($expectedInterfaces -join ', ')'; found '$($actualInterfaces -join ', ')'."
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
$mediaRoot = Join-Path $repoRoot 'Media'
$requiredMediaFiles = @(
    'Media/ATTRIBUTION.md'
    'Media/LICENSE-CC-BY-3.0.txt'
    'Media/LICENSE-CC-SAMPLING-PLUS-1.0.txt'
    'Media/Sounds/Blast.ogg'
    'Media/Sounds/BoxingArenaSound.ogg'
    'Media/Sounds/Focus.ogg'
    'Media/Sounds/Glass.mp3'
    'Media/Sounds/RobotBlip.ogg'
    'Media/Sounds/Shotgun.ogg'
    'Media/Sounds/sonar.ogg'
    'Media/Sounds/SquishFart.ogg'
    'Media/Sounds/TempleBellHuge.ogg'
    'Media/Sounds/Torch.ogg'
    'Media/Sounds/WaterDrop.ogg'
)
foreach ($file in $requiredMediaFiles) {
    if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $file) -PathType Leaf)) {
        Fail "required bundled media file '$file' is missing."
    }
}
$mediaFiles = if (Test-Path -LiteralPath $mediaRoot -PathType Container) {
    Get-ChildItem -LiteralPath $mediaRoot -File -Recurse | ForEach-Object {
        $_.FullName.Substring($repoRoot.Length + 1).Replace('\', '/')
    }
}
else { @() }
$expectedFiles = @('ApogeePartyHealthBars.toc', 'LICENSE', 'README.md') + $runtimeFiles + $mediaFiles
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
