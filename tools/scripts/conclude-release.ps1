param(
  [AllowEmptyString()]
  [string] $Tag = "",

  [string] $BaseBranch = "main",

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

$normalizedTag = Resolve-ReleaseTag -Value $Tag
$version = $normalizedTag.Substring(1)
$versionCore = ($version -split '[-+]', 2)[0]
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

& git -C $Root commit -m $commitSubject
if ($LASTEXITCODE -ne 0) {
  throw "git commit failed."
}

Write-Host "Created release commit: $commitSubject"

if ($OpenPullRequest) {
  & git -C $Root push -u origin $releaseBranch
  if ($LASTEXITCODE -ne 0) {
    throw "git push failed."
  }

  & gh pr create `
    --base $BaseBranch `
    --head $releaseBranch `
    --title $commitSubject `
    --body "Prepares $normalizedTag for release."
  if ($LASTEXITCODE -ne 0) {
    throw "gh pr create failed."
  }
}
