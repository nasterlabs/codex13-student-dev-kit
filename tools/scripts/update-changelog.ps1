param(
  [ValidatePattern('^v?(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(-((0|[1-9]\d*|\d*[A-Za-z-][0-9A-Za-z-]*)(\.(0|[1-9]\d*|\d*[A-Za-z-][0-9A-Za-z-]*))*))?(\+([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))?$')]
  [string] $Tag,

  [string] $ChangelogPath = "CHANGELOG.md",

  [string] $ConfigPath = ".git-cliff.toml",

  [switch] $Preview,

  [switch] $IncludeEmptySections,

  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]] $RemainingArguments
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Marker = "<!-- New release entries go here -->"
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

$OutputEncoding = $utf8NoBom
[Console]::InputEncoding = $utf8NoBom
[Console]::OutputEncoding = $utf8NoBom

function Resolve-RepoPath {
  param([Parameter(Mandatory = $true)][string] $Path)

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return $Path
  }

  return Join-Path (Get-Location) $Path
}

function ConvertTo-NormalizedNewlines {
  param([Parameter(Mandatory = $true)][string] $Text)

  return ($Text -replace "`r`n", "`n") -replace "`r", "`n"
}

function Get-ChangelogSection {
  param(
    [Parameter(Mandatory = $true)][string] $Tag,
    [Parameter(Mandatory = $true)][string] $ConfigPath
  )

  $repoRoot = Get-Location
  $localGitCliff = Join-Path $repoRoot "node_modules/.bin/git-cliff.cmd"
  if (-not (Test-Path -LiteralPath $localGitCliff)) {
    $localGitCliff = Join-Path $repoRoot "node_modules/.bin/git-cliff"
  }

  if (Test-Path -LiteralPath $localGitCliff) {
    $output = & $localGitCliff --config $ConfigPath --unreleased --tag $Tag --strip header
  }
  elseif ($gitCliff = Get-Command git-cliff -ErrorAction SilentlyContinue) {
    $output = & $gitCliff.Source --config $ConfigPath --unreleased --tag $Tag --strip header
  }
  elseif ($gitCliff = Get-Command git-cliff.cmd -ErrorAction SilentlyContinue) {
    $output = & $gitCliff.Source --config $ConfigPath --unreleased --tag $Tag --strip header
  }
  else {
    $output = & pnpm exec git-cliff --config $ConfigPath --unreleased --tag $Tag --strip header
  }

  if ($LASTEXITCODE -ne 0) {
    throw "git-cliff failed with exit code $LASTEXITCODE."
  }

  $section = ConvertTo-NormalizedNewlines -Text ($output -join "`n")
  $section = $section.Trim()

  if ([string]::IsNullOrWhiteSpace($section)) {
    throw "git-cliff produced an empty changelog section."
  }

  return $section
}

$resolvedChangelogPath = Resolve-RepoPath -Path $ChangelogPath
$resolvedConfigPath = Resolve-RepoPath -Path $ConfigPath

$remaining = @($RemainingArguments)
for ($index = 0; $index -lt $remaining.Count; $index++) {
  $argument = $remaining[$index]
  if ([string]::IsNullOrWhiteSpace($argument)) {
    continue
  }

  if ($argument -eq "--") {
    continue
  }

  if ($argument -in @("-Tag", "--tag", "-tag")) {
    if ($index + 1 -ge $remaining.Count) {
      throw "$argument requires a version tag value."
    }

    $Tag = $remaining[$index + 1]
    $index++
    continue
  }

  if ($argument -match '^--tag=(.+)$') {
    $Tag = $Matches[1]
    continue
  }

  if ($argument -in @("-IncludeEmptySections", "--include-empty-sections")) {
    $IncludeEmptySections = $true
    continue
  }

  throw "Unknown changelog argument: $argument"
}

if ([string]::IsNullOrWhiteSpace($Tag)) {
  throw "Provide a release tag, for example: pnpm changelog --tag v0.7.0-alpha.1"
}

$semverTagPattern = '^v?(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(-((0|[1-9]\d*|\d*[A-Za-z-][0-9A-Za-z-]*)(\.(0|[1-9]\d*|\d*[A-Za-z-][0-9A-Za-z-]*))*))?(\+([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))?$'
if ($Tag -notmatch $semverTagPattern) {
  throw "Invalid release tag: $Tag"
}

$normalizedTag = if ($Tag.StartsWith("v")) { $Tag } else { "v$Tag" }
$version = $normalizedTag.Substring(1)
$sectionHeading = "[$version]"
$sectionMarker = "<!-- BEGIN RELEASE $normalizedTag -->"

if ($IncludeEmptySections) {
  $env:GIT_CLIFF_INCLUDE_EMPTY_SECTIONS = "1"
}
else {
  $env:GIT_CLIFF_INCLUDE_EMPTY_SECTIONS = "0"
}

$section = Get-ChangelogSection -Tag $normalizedTag -ConfigPath $resolvedConfigPath

if ($Preview) {
  $section
  exit 0
}

if (-not (Test-Path -LiteralPath $resolvedChangelogPath)) {
  throw "Changelog not found: $resolvedChangelogPath"
}

$current = [System.IO.File]::ReadAllText($resolvedChangelogPath, $utf8NoBom)
$current = ConvertTo-NormalizedNewlines -Text $current

if ($current.Contains($sectionMarker) -or $current.Contains($sectionHeading)) {
  throw "CHANGELOG.md already contains a section for $normalizedTag. Edit that section manually."
}

$markerIndex = $current.IndexOf($Marker, [System.StringComparison]::Ordinal)
if ($markerIndex -lt 0) {
  throw "CHANGELOG.md does not contain the insertion marker: $Marker"
}

$insertAt = $markerIndex + $Marker.Length
$before = $current.Substring(0, $insertAt).TrimEnd()
$after = $current.Substring($insertAt).TrimStart()
$updated = "$before`n`n$section`n"

if (-not [string]::IsNullOrWhiteSpace($after)) {
  $updated = "$updated`n$after"
}

[System.IO.File]::WriteAllText($resolvedChangelogPath, $updated, $utf8NoBom)
Write-Host "Inserted changelog section for $normalizedTag after marker in $ChangelogPath"
