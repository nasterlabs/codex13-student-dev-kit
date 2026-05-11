param(
  [AllowEmptyString()]
  [string] $Tag = "",

  [string] $BaseBranch = "main",

  [AllowEmptyString()]
  [string] $SupersedeTag = "",

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
$normalizedSupersedeTag = if ([string]::IsNullOrWhiteSpace($SupersedeTag)) { "" } else { Resolve-ReleaseTag -Value $SupersedeTag }

if ($normalizedSupersedeTag -eq $normalizedTag) {
  throw "Superseded release tag must be different from the new release tag."
}

function Write-Utf8NoBom {
  param(
    [Parameter(Mandatory = $true)]
    [string] $Path,

    [Parameter(Mandatory = $true)]
    [string] $Content
  )

  [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function ConvertTo-NormalizedNewlines {
  param([Parameter(Mandatory = $true)][string] $Text)

  return ($Text -replace "`r`n", "`n") -replace "`r", "`n"
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

function Update-SupersededChangelogSection {
  param(
    [Parameter(Mandatory = $true)]
    [string] $OldTag,

    [Parameter(Mandatory = $true)]
    [string] $NewTag,

    [string] $FollowUpSection = ""
  )

  $changelogPath = Join-Path $Root "CHANGELOG.md"
  $oldVersion = $OldTag.Substring(1)
  $newVersion = $NewTag.Substring(1)
  $oldBegin = "<!-- BEGIN RELEASE $OldTag -->"
  $oldEnd = "<!-- END RELEASE $OldTag -->"
  $newBegin = "<!-- BEGIN RELEASE $NewTag -->"
  $newEnd = "<!-- END RELEASE $NewTag -->"

  $changelog = [System.IO.File]::ReadAllText($changelogPath, $utf8NoBom)
  $changelog = ConvertTo-NormalizedNewlines -Text $changelog

  if ($changelog.Contains($newBegin) -or $changelog.Contains("[$newVersion]")) {
    throw "CHANGELOG.md already contains a section for $NewTag. Edit that section manually."
  }

  $startIndex = $changelog.IndexOf($oldBegin, [System.StringComparison]::Ordinal)
  $endIndex = $changelog.IndexOf($oldEnd, [System.StringComparison]::Ordinal)
  if ($startIndex -lt 0 -or $endIndex -lt 0 -or $endIndex -le $startIndex) {
    throw "CHANGELOG.md must contain release markers for superseded tag $OldTag."
  }

  $sectionEndIndex = $endIndex + $oldEnd.Length
  $section = $changelog.Substring($startIndex, $sectionEndIndex - $startIndex)
  $section = $section.Replace($oldBegin, $newBegin)
  $section = $section.Replace($oldEnd, $newEnd)
  $section = $section.Replace("releases/tag/$OldTag", "releases/tag/$NewTag")
  $section = $section.Replace("[$oldVersion]", "[$newVersion]")
  $section = $section.Replace("[``$oldVersion``]", "[``$newVersion``]")
  $section = $section.Replace("``$OldTag``", "``$NewTag``")

  if (-not [string]::IsNullOrWhiteSpace($FollowUpSection)) {
    $releaseAssetsPattern = '(?m)^###\s+.*Release Assets\s*$'
    $releaseAssetsMatch = [regex]::Match($section, $releaseAssetsPattern)
    if (-not $releaseAssetsMatch.Success) {
      throw "Cannot insert retry follow-up changes because the moved changelog section does not contain a Release Assets heading."
    }

    $retryBlock = @(
      "<!-- BEGIN RELEASE RETRY FOLLOW-UP $OldTag -->",
      $FollowUpSection.Trim(),
      "",
      "<!-- END RELEASE RETRY FOLLOW-UP $OldTag -->",
      ""
    ) -join "`n"

    $section = $section.Insert($releaseAssetsMatch.Index, "$retryBlock`n")
  }

  $updated = $changelog.Substring(0, $startIndex) + $section + $changelog.Substring($sectionEndIndex)
  Write-Utf8NoBom -Path $changelogPath -Content $updated
}

function Get-GeneratedRetryFollowUpSection {
  param([Parameter(Mandatory = $true)][string] $Tag)

  $env:GIT_CLIFF_INCLUDE_EMPTY_SECTIONS = "0"
  $preview = @(
    & pwsh -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Root "tools/scripts/update-changelog.ps1") -Tag $Tag -Preview
  )
  if ($LASTEXITCODE -ne 0) {
    throw "Changelog retry follow-up generation failed."
  }

  $previewText = ConvertTo-NormalizedNewlines -Text ($preview -join "`n")
  $lines = @($previewText -split "`n")

  $start = -1
  $end = -1
  for ($index = 0; $index -lt $lines.Count; $index++) {
    $line = $lines[$index]
    if ($start -lt 0 -and $line -match '^###\s+' -and $line -notmatch '^###\s+.*Highlights\s*$' -and $line -notmatch '^###\s+.*Release Assets\s*$') {
      $start = $index
      continue
    }

    if ($start -ge 0 -and $line -match '^###\s+.*Release Assets\s*$') {
      $end = $index
      break
    }
  }

  if ($start -lt 0) {
    return ""
  }

  if ($end -lt 0) {
    $end = $lines.Count
  }

  $changeLines = @($lines[$start..($end - 1)])
  $changeText = ($changeLines -join "`n").Trim()
  if ([string]::IsNullOrWhiteSpace($changeText)) {
    return ""
  }

  return $changeText
}

function Write-SupersededReleaseFollowUpCommits {
  param([Parameter(Mandatory = $true)][string] $OldTag)

  $releaseCommit = ""
  $releaseLog = @(& git -C $Root log --format="%H`t%s")
  if ($LASTEXITCODE -eq 0) {
    $subjectPattern = "^chore\(release\): prepare $([regex]::Escape($OldTag))( \(#[0-9]+\))?$"
    foreach ($entry in $releaseLog) {
      $parts = $entry -split "`t", 2
      if ($parts.Count -eq 2 -and $parts[1] -match $subjectPattern) {
        $releaseCommit = $parts[0]
        break
      }
    }
  }

  if ([string]::IsNullOrWhiteSpace($releaseCommit)) {
    Write-Host "Could not find the previous release preparation commit for $OldTag."
    return
  }

  $followUpCommits = @(& git -C $Root log --reverse --format="- %s (%h)" "$releaseCommit..HEAD" -- .)
  if ($LASTEXITCODE -ne 0 -or $followUpCommits.Count -eq 0) {
    Write-Host "No follow-up commits found after the failed $OldTag release preparation."
    return
  }

  Write-Host ""
  Write-Host "Review these commits after the failed $OldTag preparation and decide whether to mention them in CHANGELOG.md:"
  foreach ($commit in $followUpCommits) {
    Write-Host $commit
  }
  Write-Host ""
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

if ([string]::IsNullOrWhiteSpace($normalizedSupersedeTag)) {
  & pwsh -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Root "tools/scripts/update-changelog.ps1") -Tag $normalizedTag
  if ($LASTEXITCODE -ne 0) {
    throw "Changelog generation failed."
  }
}
else {
  $retryFollowUpSection = Get-GeneratedRetryFollowUpSection -Tag $normalizedTag
  Update-SupersededChangelogSection -OldTag $normalizedSupersedeTag -NewTag $normalizedTag -FollowUpSection $retryFollowUpSection
  Write-Host "Retargeted changelog section from $normalizedSupersedeTag to $normalizedTag."
  if ([string]::IsNullOrWhiteSpace($retryFollowUpSection)) {
    Write-SupersededReleaseFollowUpCommits -OldTag $normalizedSupersedeTag
  }
  else {
    Write-Host "Inserted git-cliff retry follow-up changes generated after $normalizedSupersedeTag."
  }
}

Write-Host "Prepared $normalizedTag on branch $releaseBranch."
Write-Host "Next: edit CHANGELOG.md, then run task release:conclude TAG=$normalizedTag"
