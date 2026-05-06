param(
  [string] $From = "main",
  [string] $To = "HEAD"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$range = "$From..$To"
$Root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..")).Path

function Resolve-GitCommand {
  $command = Get-Command "git.exe" -ErrorAction SilentlyContinue
  if ($command) {
    return $command.Source
  }

  $command = Get-Command "git" -ErrorAction SilentlyContinue
  if ($command) {
    return $command.Source
  }

  $toolsRoot = Join-Path (Split-Path -Parent $Root) "tools"
  foreach ($candidate in @(
      (Join-Path $toolsRoot "git\cmd\git.exe"),
      (Join-Path $toolsRoot "git\bin\git.exe")
    )) {
    if (Test-Path -LiteralPath $candidate -PathType Leaf) {
      return (Resolve-Path -LiteralPath $candidate).Path
    }
  }

  throw "git.exe was not found. Add Git to PATH or install it under the sibling tools directory."
}

$GitCommand = Resolve-GitCommand

$global:LASTEXITCODE = 0
$commits = @(& $GitCommand -C $Root rev-list --no-merges $range)
if ($LASTEXITCODE -ne 0) {
  throw "git rev-list failed for range $range"
}

$failed = $false
foreach ($commit in $commits) {
  $global:LASTEXITCODE = 0
  $body = & $GitCommand -C $Root log -1 --format=%B $commit
  if ($LASTEXITCODE -ne 0) {
    throw "git log failed for commit $commit"
  }

  if (($body -join "`n") -notmatch "(?mi)^Signed-off-by:\s+.+\s+<[^>]+>\s*$") {
    $global:LASTEXITCODE = 0
    $subject = & $GitCommand -C $Root log -1 --format=%s $commit
    Write-Error "Missing DCO Signed-off-by trailer: $commit $subject" -ErrorAction Continue
    $failed = $true
  }
}

if ($failed) {
  throw "DCO check failed."
}

Write-Host "DCO check passed for $range."
