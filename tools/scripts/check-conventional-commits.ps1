param(
    [string] $From = "main",
    [string] $To = "HEAD"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$allowedTypes = "build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test"
$pattern = "^(?:$allowedTypes)(?:\([a-z0-9._-]+\))?!?: .+"
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
$messages = @(& $GitCommand -C $Root log --format=%s $range)
if ($LASTEXITCODE -ne 0) {
    throw "git log failed for range $range"
}

$failed = $false
foreach ($message in $messages) {
    if ($message -match "^Merge " -or $message -match "^Revert ") {
        continue
    }

    if ($message -notmatch $pattern) {
        Write-Error "Invalid conventional commit subject: $message" -ErrorAction Continue
        $failed = $true
    }
}

if ($failed) {
    throw "Conventional commit check failed."
}

Write-Host "Conventional commit check passed for $range."
