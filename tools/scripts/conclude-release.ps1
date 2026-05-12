param(
    [AllowEmptyString()]
    [string] $Tag = "",

    [string] $BaseBranch = "main",

    [AllowEmptyString()]
    [string] $NextVersion = "",

    [switch] $OpenPullRequest,

    [switch] $SkipChecks
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..")).Path
$semverTagPattern = '^v?(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(-((0|[1-9]\d*|\d*[A-Za-z-][0-9A-Za-z-]*)(\.(0|[1-9]\d*|\d*[A-Za-z-][0-9A-Za-z-]*))*))?(\+([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))?$'

function Resolve-ReleaseTag {
    param([AllowEmptyString()][string] $Value)

    $candidate = $Value.Trim()
    while ([string]::IsNullOrWhiteSpace($candidate)) {
        $candidate = (Read-Host "Release tag, for example v0.7.0-alpha.1").Trim()
    }

    if ($candidate -notmatch $semverTagPattern) {
        throw "Release tag must be valid SemVer with an optional leading v, for example v0.7.0-alpha.1. Actual: $candidate"
    }

    if ($candidate.StartsWith("v")) {
        return $candidate
    }

    return "v$candidate"
}

function Resolve-NextVersion {
    param([AllowEmptyString()][string] $Value)

    $candidate = $Value.Trim()
    if ([string]::IsNullOrWhiteSpace($candidate)) {
        return ""
    }

    if ($candidate -notmatch $semverTagPattern) {
        throw "Next version must be valid SemVer, for example 0.7.1-alpha.0. Actual: $candidate"
    }

    return $candidate.TrimStart("v")
}

$normalizedTag = Resolve-ReleaseTag -Value $Tag
$version = $normalizedTag.Substring(1)
$versionCore = ($version -split '[-+]', 2)[0]
$normalizedNextVersion = Resolve-NextVersion -Value $NextVersion
$releaseBranch = "release/$normalizedTag"
$commitSubject = "chore(release): prepare $normalizedTag"

function Read-Text {
    param([Parameter(Mandatory = $true)][string] $Path)

    return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}

function Assert-VersionState {
    $package = Read-Text -Path (Join-Path $Root "package.json") | ConvertFrom-Json
    if ($package.version -ne $version) {
        throw "package.json version ($($package.version)) must match $version."
    }

    $configPath = Join-Path $Root "apps/setup/src/nsis/config.nsh"
    $configText = Read-Text -Path $configPath
    $appVersionMatch = [regex]::Match($configText, '(?m)^\s*!define\s+APP_VERSION\s+"(?<version>[^"]+)"')
    if (-not $appVersionMatch.Success) {
        throw "Cannot read APP_VERSION from $configPath."
    }

    if ($appVersionMatch.Groups["version"].Value -ne $versionCore) {
        throw "APP_VERSION ($($appVersionMatch.Groups["version"].Value)) must match release version core ($versionCore)."
    }
}

function Get-ReleaseSection {
    $changelog = Read-Text -Path (Join-Path $Root "CHANGELOG.md")
    $begin = "<!-- BEGIN RELEASE $normalizedTag -->"
    $end = "<!-- END RELEASE $normalizedTag -->"
    $startIndex = $changelog.IndexOf($begin, [System.StringComparison]::Ordinal)
    $endIndex = $changelog.IndexOf($end, [System.StringComparison]::Ordinal)

    if ($startIndex -lt 0 -or $endIndex -lt 0 -or $endIndex -le $startIndex) {
        throw "CHANGELOG.md must contain release markers for $normalizedTag."
    }

    return $changelog.Substring($startIndex, $endIndex + $end.Length - $startIndex)
}

function Assert-ChangelogEdited {
    $section = Get-ReleaseSection
    $unresolvedMarkers = @(
        "TODO: Add a short release summary.",
        "TODO: Add the most important release highlight.",
        "<!-- BEGIN RELEASE DESCRIPTION -->",
        "<!-- END RELEASE DESCRIPTION -->",
        "<!-- BEGIN RELEASE HIGHLIGHTS -->",
        "<!-- END RELEASE HIGHLIGHTS -->"
    )

    foreach ($marker in $unresolvedMarkers) {
        if ($section.Contains($marker)) {
            throw "CHANGELOG.md still contains unresolved release-edit marker: $marker"
        }
    }
}

$currentBranch = (& git -C $Root branch --show-current).Trim()
if ($LASTEXITCODE -ne 0) {
    throw "Cannot read current git branch."
}

if ($currentBranch -ne $releaseBranch) {
    throw "Run release conclusion from $releaseBranch. Current branch: $currentBranch"
}

Assert-VersionState
Assert-ChangelogEdited

if (-not $SkipChecks) {
    & task check
    if ($LASTEXITCODE -ne 0) {
        throw "task check failed."
    }
}

& git -C $Root diff --check
if ($LASTEXITCODE -ne 0) {
    throw "git diff --check failed."
}

& git -C $Root add --all
if ($LASTEXITCODE -ne 0) {
    throw "git add failed."
}

$staged = @(& git -C $Root diff --cached --name-only)
if ($LASTEXITCODE -ne 0) {
    throw "git diff --cached failed."
}

if ($staged.Count -eq 0) {
    throw "No staged release changes to commit."
}

if ([string]::IsNullOrWhiteSpace($normalizedNextVersion)) {
    & git -C $Root commit -s -m $commitSubject
}
else {
    & git -C $Root commit -s -m $commitSubject -m "Release-Next-Version: $normalizedNextVersion"
}
if ($LASTEXITCODE -ne 0) {
    throw "git commit failed."
}

Write-Host "Created release commit: $commitSubject"

if ($OpenPullRequest) {
    & git -C $Root push -u origin $releaseBranch
    if ($LASTEXITCODE -ne 0) {
        throw "git push failed."
    }

    $summaryIcon = [char]::ConvertFromUtf32(0x1F9ED)
    $verificationIcon = [char]::ConvertFromUtf32(0x2705)
    $notesIcon = [char]::ConvertFromUtf32(0x1F4DD)

    $pullRequestBodyLines = New-Object System.Collections.Generic.List[string]
    $pullRequestBodyLines.Add("## $summaryIcon Summary")
    $pullRequestBodyLines.Add("")
    $pullRequestBodyLines.Add("- prepare $normalizedTag release metadata")
    $pullRequestBodyLines.Add("- update versioned release files")
    $pullRequestBodyLines.Add("- add the edited changelog entry for $normalizedTag")

    if (-not [string]::IsNullOrWhiteSpace($normalizedNextVersion)) {
        $pullRequestBodyLines.Add("- request a post-release development bump to ``v$normalizedNextVersion``")
    }

    $pullRequestBodyLines.Add("")
    $pullRequestBodyLines.Add("## $verificationIcon Verification")
    $pullRequestBodyLines.Add("")
    $pullRequestBodyLines.Add('- [x] `task check`')
    $pullRequestBodyLines.Add('- [x] `git diff --check`')
    $pullRequestBodyLines.Add("- [ ] Manual installer smoke test when install, update or uninstall behavior changed")
    $pullRequestBodyLines.Add("")
    $pullRequestBodyLines.Add("## $notesIcon Notes")
    $pullRequestBodyLines.Add("")
    $pullRequestBodyLines.Add("- [x] Preserved UTF-8 encoding for NSIS files.")
    $pullRequestBodyLines.Add('- [x] Did not commit downloaded archives, cache folders, payload logs, `.env`, `.build`, `dist`, `node_modules`, or native `bin`/`obj` output.')
    $pullRequestBodyLines.Add("- [x] Updated documentation, release notes, changelog placeholders or workflow docs when needed.")
    $pullRequestBodyLines.Add("- [x] Commits are signed off for DCO.")

    if (-not [string]::IsNullOrWhiteSpace($normalizedNextVersion)) {
        $pullRequestBodyLines.Add("")
        $pullRequestBodyLines.Add("Release-Next-Version: $normalizedNextVersion")
    }

    $pullRequestBody = $pullRequestBodyLines -join "`n"

    & gh pr create `
        --base $BaseBranch `
        --head $releaseBranch `
        --title $commitSubject `
        --body $pullRequestBody
    if ($LASTEXITCODE -ne 0) {
        throw "gh pr create failed."
    }
}
