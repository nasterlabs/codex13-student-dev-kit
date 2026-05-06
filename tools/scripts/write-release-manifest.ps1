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

$notes = New-Object System.Collections.Generic.List[string]
$notes.Add("Codex 13 Student Dev Kit $BuildVersion")
$notes.Add("")
$notes.Add("This alpha release packages the Windows installer used to set up a portable Windows development environment under ``%LOCALAPPDATA%\Codex13\StudentDevKit``.")
$notes.Add("")
$notes.Add("It is intended for release validation and early classroom testing. Public builds stay on the ``$appVersion-alpha.<build_number>`` line while the installer, signing and update process are being hardened.")
$notes.Add("")
$notes.Add("Signing status: this workflow build is unsigned unless production signing is explicitly enabled for the release run.")
$notes.Add("")
$notes.Add("## Included Profiles")
$notes.Add("")
$notes.Add("- ``Start`` profile installs Visual Studio Code portable.")
$notes.Add("- ``Classroom`` profile installs Visual Studio Code portable, Git for Windows portable and XAMPP portable.")
$notes.Add("")
$notes.Add("## Included Tools")
$notes.Add("")
$notes.Add("| Tool | Version | Install state | Support state | Notes |")
$notes.Add("|---|---:|---|---|---|")
foreach ($tool in $tools) {
  $notes.Add("| $($tool.name) | ``$($tool.version)`` | $($tool.installState) | $($tool.supportState) | $($tool.notes) |")
}
$notes.Add("")
$notes.Add("## Release Files")
$notes.Add("")
$notes.Add("- ``$releaseAssetBaseName`` - Windows x64 installer.")
$notes.Add("- ``$releaseAssetBaseName.sha256`` - SHA256 checksum for the installer.")
$notes.Add("- ``$releaseManifestFileName`` - machine-readable tool/profile manifest with pinned URLs and hashes.")
$notes.Add("- ``$releaseChangelogFileName`` - changelog snapshot from this repository.")
$notes.Add("")
$notes.Add("The changelog snapshot included in this release is copied from the repository ``CHANGELOG.md``. Automated changelog generation is planned for a future release workflow revision.")
[System.IO.File]::WriteAllText($notesFullPath, (($notes -join "`n") + "`n"), [System.Text.UTF8Encoding]::new($false))

Write-Host "Release manifest written: $outputFullPath"
Write-Host "Release notes written: $notesFullPath"
Write-Host "Release changelog written: $changelogFullPath"
