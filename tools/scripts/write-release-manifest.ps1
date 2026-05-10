param(
  [Parameter(Mandatory = $true)]
  [string] $BuildVersion,

  [string] $ConfigPath = "apps/setup/src/nsis/config.nsh",

  [string] $OutputPath = "",

  [string] $ReleaseNotesPath = "dist/setup/Codex13SDK.release-notes.md",

  [string] $ChangelogOutputPath = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$Root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..")).Path

function Resolve-RepoPath {
  param(
    [Parameter(Mandatory = $true)]
    [string] $Path
  )

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return $Path
  }

  return Join-Path $Root $Path
}

function Get-NsisDefines {
  param(
    [Parameter(Mandatory = $true)]
    [string] $Path
  )

  $defines = @{}
  foreach ($line in Get-Content -LiteralPath $Path) {
    $match = [regex]::Match($line, '^\s*!define\s+([A-Za-z0-9_]+)\s+"([^"]*)"')
    if ($match.Success) {
      $defines[$match.Groups[1].Value] = $match.Groups[2].Value
    }
  }

  return $defines
}

function Expand-NsisValue {
  param(
    [Parameter(Mandatory = $true)]
    [string] $Value,

    [Parameter(Mandatory = $true)]
    [hashtable] $Defines
  )

  $null = $Defines

  return [regex]::Replace($Value, '\$\{([A-Za-z0-9_]+)\}', {
    param($Match)
    $name = $Match.Groups[1].Value
    if ($Defines.ContainsKey($name)) {
      return [string] $Defines[$name]
    }

    return $Match.Value
  })
}

function Get-Define {
  param(
    [Parameter(Mandatory = $true)]
    [hashtable] $Defines,

    [Parameter(Mandatory = $true)]
    [string] $Name
  )

  if (-not $Defines.ContainsKey($Name)) {
    throw "Missing required NSIS define: $Name"
  }

  return Expand-NsisValue -Value ([string] $Defines[$Name]) -Defines $Defines
}

function Format-JsonText {
  param(
    [Parameter(Mandatory = $true)]
    [string] $Json
  )

  $builder = [System.Text.StringBuilder]::new()
  $indent = 0
  $inString = $false
  $escaped = $false
  $quote = [char] 34
  $backslash = [char] 92

  foreach ($char in $Json.ToCharArray()) {
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

  $formatted = $builder.ToString()
  $formatted = $formatted -replace '\\u003c', '<'
  $formatted = $formatted -replace '\\u003e', '>'
  $formatted = $formatted -replace '\\u0026', '&'

  return $formatted
}

function New-ToolEntry {
  param(
    [Parameter(Mandatory = $true)]
    [string] $Id,

    [Parameter(Mandatory = $true)]
    [string] $Name,

    [Parameter(Mandatory = $true)]
    [string] $Version,

    [Parameter(Mandatory = $true)]
    [string] $InstallState,

    [Parameter(Mandatory = $true)]
    [string] $SupportState,

    [Parameter(Mandatory = $true)]
    [string] $ArchiveUrl,

    [Parameter(Mandatory = $true)]
    [string] $Sha256,

    [Parameter(Mandatory = $true)]
    [string] $InstallPath,

    [string] $Notes = ""
  )

  return [ordered]@{
    id           = $Id
    name         = $Name
    version      = $Version
    installState = $InstallState
    supportState = $SupportState
    archiveUrl   = $ArchiveUrl
    sha256       = $Sha256
    installPath  = $InstallPath
    notes        = $Notes
  }
}

function Get-ChangelogSection {
  param(
    [Parameter(Mandatory = $true)]
    [string] $Path,

    [Parameter(Mandatory = $true)]
    [string] $Version
  )

  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    return @()
  }

  $lines = @(Get-Content -LiteralPath $Path)
  $lineCount = $lines.Length
  $startPattern = "^\s*##\s+\[$([regex]::Escape($Version))\]"
  $startIndex = -1
  for ($index = 0; $index -lt $lineCount; $index++) {
    if ($lines[$index] -match $startPattern) {
      $startIndex = $index + 1
      break
    }
  }

  if ($startIndex -lt 0) {
    return @()
  }

  $sectionLines = New-Object System.Collections.Generic.List[string]
  for ($index = $startIndex; $index -lt $lineCount; $index++) {
    if ($lines[$index] -match '^\s*##\s+') {
      break
    }

    $sectionLines.Add($lines[$index])
  }

  return $sectionLines.ToArray()
}

function Add-ChangelogSection {
  param(
    [System.Collections.Generic.List[string]] $Notes,

    [string[]] $SectionLines
  )

  if ($null -eq $SectionLines -or $SectionLines.Length -eq 0) {
    return
  }

  $Notes.Add("## What's Changed")
  $Notes.Add("")

  foreach ($line in $SectionLines) {
    if ($line -match '^\s*###\s+(.+?)\s*$') {
      $Notes.Add("### $($Matches[1])")
    }
    elseif ($line -match '^\s*-\s+(.+?)\s*$') {
      $Notes.Add("- $($Matches[1])")
    }
    elseif (-not [string]::IsNullOrWhiteSpace($line)) {
      $Notes.Add($line)
    }
    else {
      $Notes.Add("")
    }
  }

  $Notes.Add("")
}

$configFullPath = Resolve-RepoPath -Path $ConfigPath
if (-not (Test-Path -LiteralPath $configFullPath -PathType Leaf)) {
  throw "Config file not found: $configFullPath"
}

$defines = Get-NsisDefines -Path $configFullPath
$appVersion = Get-Define -Defines $defines -Name "APP_VERSION"

$tools = @(
  New-ToolEntry `
    -Id "vscode" `
    -Name "Visual Studio Code portable" `
    -Version (Get-Define -Defines $defines -Name "VSCODE_VERSION") `
    -InstallState "installable" `
    -SupportState "supported" `
    -ArchiveUrl (Get-Define -Defines $defines -Name "VSCODE_URL") `
    -Sha256 (Get-Define -Defines $defines -Name "VSCODE_SHA256") `
    -InstallPath (Get-Define -Defines $defines -Name "VSCODE_INSTALL_DIR") `
    -Notes "Installed by the Start and Classroom profiles."

  New-ToolEntry `
    -Id "git" `
    -Name "Git for Windows portable" `
    -Version (Get-Define -Defines $defines -Name "GIT_VERSION") `
    -InstallState "installable" `
    -SupportState "supported" `
    -ArchiveUrl (Get-Define -Defines $defines -Name "GIT_URL") `
    -Sha256 (Get-Define -Defines $defines -Name "GIT_SHA256") `
    -InstallPath (Get-Define -Defines $defines -Name "GIT_INSTALL_DIR") `
    -Notes "Installed by the Classroom profile."

  New-ToolEntry `
    -Id "xampp" `
    -Name "XAMPP portable" `
    -Version (Get-Define -Defines $defines -Name "XAMPP_VERSION") `
    -InstallState "installable" `
    -SupportState "supported" `
    -ArchiveUrl (Get-Define -Defines $defines -Name "XAMPP_URL") `
    -Sha256 (Get-Define -Defines $defines -Name "XAMPP_SHA256") `
    -InstallPath (Get-Define -Defines $defines -Name "XAMPP_INSTALL_DIR") `
    -Notes "Installed by the Classroom profile; includes Codex 13 path and PHP extension diagnostics."

  New-ToolEntry `
    -Id "openssh" `
    -Name "OpenSSH for Windows portable" `
    -Version (Get-Define -Defines $defines -Name "OPENSSH_VERSION") `
    -InstallState "hidden" `
    -SupportState "experimental" `
    -ArchiveUrl (Get-Define -Defines $defines -Name "OPENSSH_URL") `
    -Sha256 (Get-Define -Defines $defines -Name "OPENSSH_SHA256") `
    -InstallPath (Get-Define -Defines $defines -Name "OPENSSH_INSTALL_DIR") `
    -Notes "Metadata and pinned downloads are present, but the component is not exposed in this alpha release."
)

$releaseAssetBaseName = "Codex13SDK-Setup-win-x64-$BuildVersion.exe"
$releaseManifestFileName = "codex13-sdk-$BuildVersion.release-manifest.json"
$releaseChangelogFileName = "codex13-sdk-$BuildVersion.changelog.md"

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
  $OutputPath = "dist/setup/$releaseManifestFileName"
}

if ([string]::IsNullOrWhiteSpace($ChangelogOutputPath)) {
  $ChangelogOutputPath = "dist/setup/$releaseChangelogFileName"
}

$manifest = [ordered]@{
  schemaVersion = 1
  manifestName  = [System.IO.Path]::GetFileName($OutputPath)
  product       = "Codex 13 Student Dev Kit"
  appVersion    = $appVersion
  buildVersion  = $BuildVersion
  generatedAt   = (Get-Date).ToUniversalTime().ToString("o")
  releaseLine   = "$appVersion-alpha.<build_number>"
  installer     = [ordered]@{
    fileName = $releaseAssetBaseName
    channel  = "release"
    platform = "win-x64"
  }
  profiles      = @(
    [ordered]@{
      id       = "start"
      preset   = "clean-vscode"
      tools    = @("vscode")
      status   = "installable"
    },
    [ordered]@{
      id       = "classroom"
      preset   = "php-mysql-classroom"
      tools    = @("vscode", "git", "xampp")
      status   = "installable"
    }
  )
  tools         = $tools
}

$outputFullPath = Resolve-RepoPath -Path $OutputPath
$notesFullPath = Resolve-RepoPath -Path $ReleaseNotesPath
$changelogFullPath = Resolve-RepoPath -Path $ChangelogOutputPath
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $outputFullPath) | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $notesFullPath) | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $changelogFullPath) | Out-Null

$json = Format-JsonText -Json ($manifest | ConvertTo-Json -Depth 10 -Compress)
[System.IO.File]::WriteAllText($outputFullPath, $json + "`n", [System.Text.UTF8Encoding]::new($false))

$sourceChangelogPath = Join-Path $Root "CHANGELOG.md"
if (Test-Path -LiteralPath $sourceChangelogPath -PathType Leaf) {
  Copy-Item -LiteralPath $sourceChangelogPath -Destination $changelogFullPath -Force
}
$changelogSection = Get-ChangelogSection -Path $sourceChangelogPath -Version $appVersion

$notes = New-Object System.Collections.Generic.List[string]
$notes.Add("# Codex 13 Student Dev Kit $BuildVersion")
$notes.Add("")
$notes.Add("A portable Windows classroom development kit installer for Visual Studio Code, Git and XAMPP.")
$notes.Add("")
$notes.Add("This alpha build is intended for release validation and early classroom testing. Public builds stay on the ``$appVersion-alpha.<build_number>`` line while installer signing and update hardening continue.")
$notes.Add("")
$notes.Add("## Highlights")
$notes.Add("")
$notes.Add("- Installs into ``%LOCALAPPDATA%\Codex13\StudentDevKit`` without administrator rights.")
$notes.Add("- Keeps the active alpha experience focused on ``Start`` and ``Classroom`` profiles.")
$notes.Add("- Uses pinned downloads and SHA256 checks for every bundled tool.")
$notes.Add("- Writes an installation manifest for future Manager and diagnostics workflows.")
$notes.Add("")
Add-ChangelogSection -Notes $notes -SectionLines $changelogSection
$notes.Add("## Included Profiles")
$notes.Add("")
$notes.Add("| Profile | Preset | Included tools | Status |")
$notes.Add("| --- | --- | --- | --- |")
$notes.Add("| Start | ``clean-vscode`` | Visual Studio Code portable | installable |")
$notes.Add("| Classroom | ``php-mysql-classroom`` | Visual Studio Code portable, Git for Windows portable, XAMPP portable | installable |")
$notes.Add("")
$notes.Add("## Included Tools")
$notes.Add("")
$notes.Add("| Tool | Version | State | Support | Notes |")
$notes.Add("| --- | ---: | --- | --- | --- |")
foreach ($tool in $tools) {
  $notes.Add("| $($tool.name) | ``$($tool.version)`` | $($tool.installState) | $($tool.supportState) | $($tool.notes) |")
}
$notes.Add("")
$notes.Add("## Release Assets")
$notes.Add("")
$notes.Add("- ``$releaseAssetBaseName`` - Windows x64 installer.")
$notes.Add("- ``$releaseAssetBaseName.sha256`` - SHA256 checksum for the installer.")
$notes.Add("- ``$releaseManifestFileName`` - machine-readable tool/profile manifest with pinned URLs and hashes.")
$notes.Add("- ``$releaseChangelogFileName`` - changelog snapshot from this repository.")
$notes.Add("")
$notes.Add("## Verification Notes")
$notes.Add("")
$notes.Add("- Installer signing is disabled unless production signing is explicitly enabled for the release run.")
$notes.Add("- The release manifest records the product version, build version, profiles, tools, pinned URLs and SHA256 hashes.")
$notes.Add("- The attached changelog snapshot is copied from repository ``CHANGELOG.md``.")
$notes.Add("")
$notes.Add("Full changelog: see ``$releaseChangelogFileName``.")
[System.IO.File]::WriteAllText($notesFullPath, (($notes -join "`n") + "`n"), [System.Text.UTF8Encoding]::new($false))

Write-Host "Release manifest written: $outputFullPath"
Write-Host "Release notes written: $notesFullPath"
Write-Host "Release changelog written: $changelogFullPath"
