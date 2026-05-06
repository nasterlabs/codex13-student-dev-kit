param(
    [Parameter(Mandatory = $true)]
    [string] $ArchivePath,

    [Parameter(Mandatory = $true)]
    [string] $ExpectedSha256
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $ArchivePath -PathType Leaf)) {
    Write-Error "Archive not found: $ArchivePath"
    exit 1
}

$actual = (Get-FileHash -LiteralPath $ArchivePath -Algorithm SHA256).Hash.ToLower()
$expected = $ExpectedSha256.ToLower().Trim()

if ($actual -ne $expected) {
    Write-Error "SHA-256 mismatch for $ArchivePath`nExpected: $expected`nActual:   $actual"
    exit 1
}

Write-Host "OK  $ArchivePath"
exit 0
