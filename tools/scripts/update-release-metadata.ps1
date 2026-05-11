param(
  [Parameter(Mandatory = $true)]
  [string] $BuildVersion,

  [string] $ReleaseDate = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd"),

  [string] $Commit = "",

  [string] $ReleaseUrl = "",

  [string] $Doi = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$Root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..")).Path

function Resolve-RepoPath {
  param(
    [Parameter(Mandatory = $true)]
    [string] $Path
  )

  return Join-Path $Root $Path
}

function Write-Utf8NoBom {
  param(
    [Parameter(Mandatory = $true)]
    [string] $Path,

    [Parameter(Mandatory = $true)]
    [string] $Content
  )

  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function Read-Utf8Text {
  param(
    [Parameter(Mandatory = $true)]
    [string] $Path
  )

  return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}

function ConvertTo-PrettyJson {
  param(
    [Parameter(Mandatory = $true)]
    [object] $Value
  )

  $json = $Value | ConvertTo-Json -Depth 20 -Compress
  $json = $json -replace '\\u003c', '<'
  $json = $json -replace '\\u003e', '>'
  $json = $json -replace '\\u0026', '&'

  $builder = [System.Text.StringBuilder]::new()
  $indent = 0
  $inString = $false
  $escaped = $false
  $quote = [char] 34
  $backslash = [char] 92

  foreach ($char in $json.ToCharArray()) {
    if ($inString) {
      [void] $builder.Append($char)
      if ($escaped) {
        $escaped = $false
      }
      elseif ($char -eq $backslash) {
        $escaped = $true
      }
      elseif ($char -eq $quote) {
        $inString = $false
      }
      continue
    }

    if ($char -eq $quote) {
      $inString = $true
      [void] $builder.Append($char)
    }
    elseif ($char -eq '{' -or $char -eq '[') {
      [void] $builder.Append($char)
      [void] $builder.Append("`n")
      $indent++
      [void] $builder.Append(" " * ($indent * 2))
    }
    elseif ($char -eq '}' -or $char -eq ']') {
      [void] $builder.Append("`n")
      $indent--
      [void] $builder.Append(" " * ($indent * 2))
      [void] $builder.Append($char)
    }
    elseif ($char -eq ',') {
      [void] $builder.Append($char)
      [void] $builder.Append("`n")
      [void] $builder.Append(" " * ($indent * 2))
    }
    elseif ($char -eq ':') {
      [void] $builder.Append(": ")
    }
    elseif (-not [char]::IsWhiteSpace($char)) {
      [void] $builder.Append($char)
    }
  }

  return $builder.ToString()
}

if ($BuildVersion -notmatch '^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(-[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?(\+[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?$') {
  throw "BuildVersion must be valid SemVer. Actual: $BuildVersion"
}

if ($ReleaseDate -notmatch '^\d{4}-\d{2}-\d{2}$') {
  throw "ReleaseDate must use yyyy-MM-dd. Actual: $ReleaseDate"
}

if ([string]::IsNullOrWhiteSpace($Commit)) {
  $Commit = (& git -C $Root rev-parse HEAD).Trim()
}

if ($Commit -notmatch '^[0-9a-fA-F]{40}$') {
  throw "Commit must be a full 40-character Git commit SHA. Actual: $Commit"
}

if ([string]::IsNullOrWhiteSpace($ReleaseUrl)) {
  $ReleaseUrl = "https://github.com/nasterlabs/codex13-student-dev-kit/releases/tag/v$BuildVersion"
}

$citationPath = Resolve-RepoPath -Path "CITATION.cff"
$citation = Read-Utf8Text -Path $citationPath
$citation = [regex]::Replace($citation, '(?m)^commit: .+$', "commit: $Commit")
$citation = [regex]::Replace($citation, '(?m)^version: .+$', "version: $BuildVersion")
$citation = [regex]::Replace($citation, '(?m)^date-released: .+$', "date-released: '$ReleaseDate'")

$identifierLines = New-Object System.Collections.Generic.List[string]
$identifierLines.Add("identifiers:")
$identifierLines.Add("  - type: url")
$identifierLines.Add("    value: >-")
$identifierLines.Add("      $ReleaseUrl")
$identifierLines.Add("    description: GitHub Release for Codex 13 Student Dev Kit $BuildVersion.")
if (-not [string]::IsNullOrWhiteSpace($Doi)) {
  $identifierLines.Add("  - type: doi")
  $identifierLines.Add("    value: $Doi")
  $identifierLines.Add("    description: Zenodo DOI for Codex 13 Student Dev Kit $BuildVersion.")
}
$identifierBlock = ($identifierLines -join "`n")
$citation = [regex]::Replace($citation, '(?ms)^identifiers:\r?\n(?:  .+\r?\n)+(?=abstract:)', $identifierBlock + "`n")
Write-Utf8NoBom -Path $citationPath -Content $citation

$zenodoPath = Resolve-RepoPath -Path ".zenodo.json"
$zenodo = Read-Utf8Text -Path $zenodoPath | ConvertFrom-Json
$zenodo | Add-Member -NotePropertyName "version" -NotePropertyValue $BuildVersion -Force
Write-Utf8NoBom -Path $zenodoPath -Content ((ConvertTo-PrettyJson -Value $zenodo) + "`n")

$codemetaPath = Resolve-RepoPath -Path "codemeta.json"
$codemeta = Read-Utf8Text -Path $codemetaPath | ConvertFrom-Json
$codemeta.version = $BuildVersion
$codemeta.datePublished = $ReleaseDate
$codemeta.downloadUrl = $ReleaseUrl
$codemeta.releaseNotes = "Release metadata for Codex 13 Student Dev Kit $BuildVersion. See the GitHub Release for installer artifacts, checksums, release notes and manifest."
Write-Utf8NoBom -Path $codemetaPath -Content ((ConvertTo-PrettyJson -Value $codemeta) + "`n")

Write-Host "Updated CITATION.cff, .zenodo.json and codemeta.json for $BuildVersion ($Commit)."
