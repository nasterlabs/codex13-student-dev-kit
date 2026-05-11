param(
  [AllowEmptyString()]
  [string] $Tag = "",

  [string] $BaseBranch = "main",

  [switch] $NoBranch
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..")).Path
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
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

function Write-Utf8NoBom {
  param(
    [Parameter(Mandatory = $true)]
    [string] $Path,

    [Parameter(Mandatory = $true)]
    [string] $Content
  )

  [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function Assert-CleanWorktree {
  $status = @(& git -C $Root status --porcelain)
  if ($LASTEXITCODE -ne 0) {
    throw "git status failed."
  }

  if ($status.Count -gt 0) {
    throw "Working tree must be clean before preparing a release branch."
  }
}

Assert-CleanWorktree

if (-not $NoBranch) {
  & git -C $Root fetch origin $BaseBranch --quiet
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to fetch origin/$BaseBranch."
  }

  & git -C $Root switch -c $releaseBranch "origin/$BaseBranch"
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to create release branch $releaseBranch from origin/$BaseBranch."
  }
}

$packagePath = Join-Path $Root "package.json"
$package = [System.IO.File]::ReadAllText($packagePath, $utf8NoBom) | ConvertFrom-Json
$package.version = $version
$packageJson = (($package | ConvertTo-Json -Depth 20) -replace "`r`n", "`n") -replace "`r", "`n"
Write-Utf8NoBom -Path $packagePath -Content "$packageJson`n"

$configPath = Join-Path $Root "apps/setup/src/nsis/config.nsh"
$configText = [System.IO.File]::ReadAllText($configPath, $utf8NoBom)
$configText = [regex]::Replace(
  $configText,
  '(?m)^(!define\s+APP_VERSION\s+")([^"]+)(")',
  "`${1}$versionCore`${3}",
  1
)
Write-Utf8NoBom -Path $configPath -Content $configText

& pwsh -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Root "tools/scripts/update-changelog.ps1") -Tag $normalizedTag
if ($LASTEXITCODE -ne 0) {
  throw "Changelog generation failed."
}

Write-Host "Prepared $normalizedTag on branch $releaseBranch."
Write-Host "Next: edit CHANGELOG.md, then run task release:conclude TAG=$normalizedTag"
