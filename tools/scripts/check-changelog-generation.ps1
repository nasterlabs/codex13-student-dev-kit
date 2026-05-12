Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..")).Path
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

$OutputEncoding = $utf8NoBom
[Console]::InputEncoding = $utf8NoBom
[Console]::OutputEncoding = $utf8NoBom

$tag = "v0.7.0-alpha.1"
$scriptPath = Join-Path $Root "tools/scripts/update-changelog.ps1"
$nodeBinPath = Join-Path $Root "node_modules/.bin"
$rocket = [char]::ConvertFromUtf32(0x1F680)
$glowingStar = [char]::ConvertFromUtf32(0x1F31F)
$sparkles = [char]::ConvertFromUtf32(0x2728)
$bug = [char]::ConvertFromUtf32(0x1F41B)
$construction = [char]::ConvertFromUtf32(0x1F3D7) + [char] 0xFE0F
$upArrow = [char]::ConvertFromUtf32(0x2B06) + [char] 0xFE0F

function Invoke-Git {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]] $Arguments)

    $output = & git -C $Root @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        $details = ($output | Out-String).Trim()
        throw "git $($Arguments -join ' ') failed. $details"
    }

    return $output
}

function Sync-GitHistory {
    $isShallow = ((Invoke-Git rev-parse --is-shallow-repository) | Out-String).Trim()
    if ($isShallow -eq "true") {
        Invoke-Git fetch --unshallow --tags --prune origin | Out-Null
    }
    else {
        Invoke-Git fetch --tags --prune origin | Out-Null
    }
}

Sync-GitHistory

$testRoot = Join-Path $Root ".build/changelog-generation-check"
$testRepo = Join-Path $testRoot "repo"
$testChangelog = Join-Path $testRepo "CHANGELOG.md"

if (Test-Path -LiteralPath $testRoot) {
    Remove-Item -LiteralPath $testRoot -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $testRoot | Out-Null
Invoke-Git clone --local --no-hardlinks $Root $testRepo | Out-Null

Push-Location $testRepo
$previousPath = $env:PATH
try {
    $env:PATH = "$nodeBinPath$([System.IO.Path]::PathSeparator)$previousPath"
    $existingTags = @(& git tag --list)
    if ($LASTEXITCODE -ne 0) {
        throw "git tag --list failed in changelog test repository."
    }

    if ($existingTags.Count -gt 0) {
        & git tag --delete @existingTags | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to delete tags in changelog test repository."
        }
    }

    $preview = (& pwsh -NoProfile -ExecutionPolicy Bypass -File $scriptPath -Tag $tag -ConfigPath (Join-Path $Root ".git-cliff.toml") -Preview) -join "`n"
    if ($LASTEXITCODE -ne 0) {
        throw "Changelog preview generation failed."
    }
}
finally {
    $env:PATH = $previousPath
    Pop-Location
}

if ([string]::IsNullOrWhiteSpace($preview)) {
    throw "Changelog preview is empty."
}

$requiredFragments = @(
    "## $rocket [0.7.0-alpha.1]",
    "### $glowingStar Highlights",
    "### $sparkles Features",
    "### $bug Fixes",
    "### $construction Build, CI and Release Automation",
    "### $upArrow Dependencies",
    'Updated `actions/create-github-app-token` from `2.1.1` to `3.1.1`'
)

foreach ($fragment in $requiredFragments) {
    if (-not $preview.Contains($fragment)) {
        throw "Changelog preview is missing expected fragment: $fragment"
    }
}

$forbiddenPatterns = @(
    [string] [char] 0xFFFD,
    ([char] 0x00AD) + ([char] 0x010D),
    [string] [char] 0x00D4,
    ([char] 0x00B4) + ([char] 0x015E) + ([char] 0x0106),
    "3.1.1 in the github-actions group",
    "3.1.1 across 1 directory"
)

foreach ($pattern in $forbiddenPatterns) {
    if ($preview.Contains($pattern)) {
        throw "Changelog preview contains forbidden text: $pattern"
    }
}

[System.IO.File]::WriteAllText(
    $testChangelog,
    "# Changelog`n`n<!-- New release entries go here -->`n",
    $utf8NoBom
)

Push-Location $testRepo
$previousPath = $env:PATH
try {
    $env:PATH = "$nodeBinPath$([System.IO.Path]::PathSeparator)$previousPath"
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $scriptPath -Tag $tag -ConfigPath (Join-Path $Root ".git-cliff.toml") -ChangelogPath $testChangelog
    if ($LASTEXITCODE -ne 0) {
        throw "Changelog insertion check failed."
    }
}
finally {
    $env:PATH = $previousPath
    Pop-Location
}

$inserted = [System.IO.File]::ReadAllText($testChangelog, $utf8NoBom)
foreach ($fragment in $requiredFragments) {
    if (-not $inserted.Contains($fragment)) {
        throw "Inserted changelog is missing expected fragment: $fragment"
    }
}

foreach ($pattern in $forbiddenPatterns) {
    if ($inserted.Contains($pattern)) {
        throw "Inserted changelog contains forbidden text: $pattern"
    }
}

Write-Host "Changelog generation check passed."
