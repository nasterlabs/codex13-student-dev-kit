$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$Root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
$VendorRoot = Join-Path $Root "apps\setup\vendor"
$ManifestPath = Join-Path $VendorRoot "vendor.sha256"
$failed = $false

function Add-Failure {
  param(
    [Parameter(Mandatory = $true)]
    [string] $Message
  )

  $script:failed = $true
  Write-Error -Message $Message -ErrorAction Continue
}

if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
  Write-Error -Message "Missing vendor checksum manifest: apps/setup/vendor/vendor.sha256" -ErrorAction Continue
  exit 1
}

$lineNumber = 0
foreach ($line in Get-Content -LiteralPath $ManifestPath) {
  $lineNumber++
  $trimmed = $line.Trim()

  if ($trimmed -eq "" -or $trimmed.StartsWith("#")) {
    continue
  }

  $match = [regex]::Match($line, '^\s*([0-9a-fA-F]{64})\s+(.+?)\s*$')
  if (-not $match.Success) {
    Add-Failure "Invalid manifest line ${lineNumber}: expected '<64 hex chars>  <relative-path>'."
    continue
  }

  $expectedHash = $match.Groups[1].Value
  $relativePath = $match.Groups[2].Value

  if ([System.IO.Path]::IsPathRooted($relativePath) -or $relativePath -match '(^|[\\/])\.\.([\\/]|$)') {
    Add-Failure "Invalid manifest line ${lineNumber}: path must stay relative to apps/setup/vendor: $relativePath"
    continue
  }

  $path = Join-Path $VendorRoot $relativePath
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    Add-Failure "Missing vendored binary: apps/setup/vendor/$relativePath"
    continue
  }

  $actualHash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
  if (-not [string]::Equals($actualHash, $expectedHash, [System.StringComparison]::OrdinalIgnoreCase)) {
    Add-Failure "SHA256 mismatch for apps/setup/vendor/${relativePath}. Expected: $expectedHash Actual: $actualHash"
    continue
  }

  Write-Host "OK apps/setup/vendor/$relativePath"
}

if ($failed) {
  exit 1
}

Write-Host "Vendored binary verification passed."
exit 0
