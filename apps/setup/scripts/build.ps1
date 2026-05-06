param(
  # Env file to load. Overrides BUILD_ENV_FILE env var and the .env default.
  # Relative paths are resolved from the repository root.
  [string] $EnvFile = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Resolve-RequiredFile {
  param(
    [Parameter(Mandatory = $true)]
    [string] $Path,

    [Parameter(Mandatory = $true)]
    [string] $Label
  )

  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    throw "Not found: $Label ($Path)"
  }

  return (Resolve-Path -LiteralPath $Path).Path
}

function Resolve-RequiredDirectory {
  param(
    [Parameter(Mandatory = $true)]
    [string] $Path,

    [Parameter(Mandatory = $true)]
    [string] $Label
  )

  if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
    throw "Not found: $Label ($Path)"
  }

  return (Resolve-Path -LiteralPath $Path).Path
}

function Import-DotEnv {
  param(
    [Parameter(Mandatory = $true)]
    [string] $Path
  )

  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    return
  }

  foreach ($line in Get-Content -LiteralPath $Path) {
    $trimmed = $line.Trim()

    if ($trimmed.Length -eq 0 -or $trimmed.StartsWith("#")) {
      continue
    }

    $parts = $line -split "=", 2
    if ($parts.Count -ne 2 -or [string]::IsNullOrWhiteSpace($parts[0])) {
      continue
    }

    $name = $parts[0].Trim()
    $value = [System.Environment]::ExpandEnvironmentVariables($parts[1].Trim())
    if ([string]::IsNullOrEmpty([System.Environment]::GetEnvironmentVariable($name, "Process"))) {
      [System.Environment]::SetEnvironmentVariable($name, $value, "Process")
    }
  }
}

function Assert-NsisDefine {
  param(
    [Parameter(Mandatory = $true)]
    [string] $ConfigText,

    [Parameter(Mandatory = $true)]
    [string] $Name
  )

  $pattern = "(?m)^\s*!define\s+$([regex]::Escape($Name))\b"
  if ($ConfigText -notmatch $pattern) {
    throw "Missing required NSIS define in apps/setup/src/nsis/config.nsh or included metadata files: $Name"
  }
}

function Get-NsisDefineValue {
  param(
    [Parameter(Mandatory = $true)]
    [string] $ConfigText,

    [Parameter(Mandatory = $true)]
    [string] $Name
  )

  $pattern = "(?m)^\s*!define\s+$([regex]::Escape($Name))\s+`"([^`"]+)`""
  $match = [regex]::Match($ConfigText, $pattern)
  if (-not $match.Success) {
    throw "Cannot read NSIS define value: $Name"
  }

  return $match.Groups[1].Value
}

function Resolve-SignTool {
  if (-not [string]::IsNullOrWhiteSpace($env:SIGNTOOL_PATH)) {
    return Resolve-RequiredFile -Path $env:SIGNTOOL_PATH -Label "signtool.exe configured in SIGNTOOL_PATH"
  }

  $command = Get-Command "signtool.exe" -ErrorAction SilentlyContinue
  if ($command) {
    return $command.Source
  }

  $sdkRoot = "${env:ProgramFiles(x86)}\Windows Kits\10\bin"
  if (Test-Path -LiteralPath $sdkRoot -PathType Container) {
    $candidates = @(Get-ChildItem -LiteralPath $sdkRoot -Recurse -Filter "signtool.exe" -ErrorAction SilentlyContinue |
      Where-Object { $_.FullName -match "\\x64\\signtool\.exe$" } |
      Sort-Object FullName -Descending)

    if ($candidates.Count -gt 0) {
      return $candidates[0].FullName
    }
  }

  return $null
}

function Test-CodeSigningEnabled {
  return $env:SIGNING_ENABLED -eq "1"
}

function Get-SigningCertificate {
  param(
    [string] $Thumbprint
  )

  if (-not [string]::IsNullOrWhiteSpace($Thumbprint)) {
    $normalizedThumbprint = $Thumbprint -replace "\s", ""
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store(
      [System.Security.Cryptography.X509Certificates.StoreName]::My,
      [System.Security.Cryptography.X509Certificates.StoreLocation]::CurrentUser
    )

    try {
      $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadOnly)
      $cert = $store.Certificates |
        Where-Object { ($_.Thumbprint -replace "\s", "") -eq $normalizedThumbprint } |
        Select-Object -First 1
    }
    finally {
      $store.Close()
    }

    if (-not $cert) {
      throw "SIGN_CERT_THUMBPRINT certificate was not found in the CurrentUser\\My store."
    }

    if (-not $cert.HasPrivateKey) {
      throw "SIGN_CERT_THUMBPRINT certificate does not have a private key."
    }

    return $cert
  }

  throw "Set SIGN_CERT_THUMBPRINT in the env file or CI secrets."
}

function Invoke-AuthenticodeSigning {
  param(
    [Parameter(Mandatory = $true)]
    [string] $FilePath,

    [Parameter(Mandatory = $true)]
    [System.Security.Cryptography.X509Certificates.X509Certificate2] $Certificate,

    [string] $TimestampUrl
  )

  Write-Host "Signing with Authenticode via Set-AuthenticodeSignature: $FilePath"

  if ([string]::IsNullOrWhiteSpace($TimestampUrl)) {
    $signature = Set-AuthenticodeSignature -FilePath $FilePath -Certificate $Certificate -HashAlgorithm SHA256
  }
  else {
    try {
      $signature = Set-AuthenticodeSignature -FilePath $FilePath -Certificate $Certificate -HashAlgorithm SHA256 -TimestampServer $TimestampUrl
      if ($signature.Status -ne "Valid") {
        Write-Warning "Timestamped signature failed. Retrying without timestamp: $($signature.Status). $($signature.StatusMessage)"
        $signature = Set-AuthenticodeSignature -FilePath $FilePath -Certificate $Certificate -HashAlgorithm SHA256
      }
    }
    catch {
      Write-Warning "Timestamped signature failed. Retrying without timestamp: $_"
      $signature = Set-AuthenticodeSignature -FilePath $FilePath -Certificate $Certificate -HashAlgorithm SHA256
    }
  }

  if ($signature.Status -ne "Valid") {
    $signedFile = Get-AuthenticodeSignature -FilePath $FilePath
    if ($signedFile.SignerCertificate -and $signedFile.SignerCertificate.Thumbprint -eq $Certificate.Thumbprint) {
      Write-Warning "The file was signed, but Windows did not mark the signature as fully trusted: $($signedFile.Status). $($signedFile.StatusMessage)"
      return
    }

    throw "Authenticode signing failed. Status: $($signature.Status). $($signature.StatusMessage)"
  }
}

function Invoke-CodeSigning {
  param(
    [Parameter(Mandatory = $true)]
    [string] $FilePath
  )

  if (-not (Test-CodeSigningEnabled)) {
    Write-Host "Signing skipped. Set SIGNING_ENABLED=1 to enable it."
    return
  }

  $thumbprint = $env:SIGN_CERT_THUMBPRINT
  $signToolPath = Resolve-SignTool
  $timestampUrl = if ([string]::IsNullOrWhiteSpace($env:SIGN_TIMESTAMP_URL)) { "http://timestamp.digicert.com" } else { $env:SIGN_TIMESTAMP_URL }

  if ($signToolPath) {
    if (-not [string]::IsNullOrWhiteSpace($thumbprint)) {
      Write-Host "Signing with Authenticode via a certificate from CurrentUser\\My: $FilePath"
      & $signToolPath sign /sha1 $thumbprint /fd SHA256 /tr $timestampUrl /td SHA256 $FilePath
      if ($LASTEXITCODE -ne 0) {
        throw "signtool.exe sign exited with code $LASTEXITCODE."
      }
      & $signToolPath verify /pa /v $FilePath
      if ($LASTEXITCODE -ne 0) {
        throw "signtool.exe verify exited with code $LASTEXITCODE."
      }
    }
    else {
      throw "Set SIGN_CERT_THUMBPRINT in the env file or CI secrets."
    }
  }
  else {
    $cert = Get-SigningCertificate -Thumbprint $thumbprint
    Invoke-AuthenticodeSigning -FilePath $FilePath -Certificate $cert -TimestampUrl $timestampUrl
  }
}

function Resolve-BuildSettings {
  param(
    [Parameter(Mandatory = $true)]
    [string] $AppVersion
  )

  $channel = if ([string]::IsNullOrWhiteSpace($env:BUILD_CHANNEL)) { "dev" } else { $env:BUILD_CHANNEL.Trim().ToLowerInvariant() }

  switch ($channel) {
    "release" {
      return @{
        Channel = "release"
        Version = if ([string]::IsNullOrWhiteSpace($env:BUILD_VERSION)) { "$AppVersion-alpha.local" } else { $env:BUILD_VERSION.Trim() }
        ExeName = "Codex13SDK-Setup.exe"
      }
    }
    "dev" {
      return @{
        Channel = "dev"
        Version = if ([string]::IsNullOrWhiteSpace($env:BUILD_VERSION)) { "$AppVersion-dev" } else { $env:BUILD_VERSION.Trim() }
        ExeName = "Codex13SDK-Setup-dev.exe"
      }
    }
    default {
      $safeChannel = $channel -replace "[^a-z0-9._-]", "-"
      return @{
        Channel = $safeChannel
        Version = if ([string]::IsNullOrWhiteSpace($env:BUILD_VERSION)) { "$AppVersion-$safeChannel" } else { $env:BUILD_VERSION.Trim() }
        ExeName = "Codex13SDK-Setup-$safeChannel.exe"
      }
    }
  }
}

function Get-SemVerCore {
  param(
    [Parameter(Mandatory = $true)]
    [string] $Version
  )

  $core = ($Version -split "[-+]", 2)[0]
  if ($core -notmatch "^\d+\.\d+\.\d+$") {
    throw "BUILD_VERSION must start with SemVer major.minor.patch, for example 0.1.0 or 0.1.0-dev. Current value: $Version"
  }

  return $core
}

function Assert-BuildVersionMatchesAppVersion {
  param(
    [Parameter(Mandatory = $true)]
    [string] $BuildVersionCore,

    [Parameter(Mandatory = $true)]
    [string] $AppVersion
  )

  if ($BuildVersionCore -ne $AppVersion) {
    throw "BUILD_VERSION ($BuildVersionCore) does not match APP_VERSION ($AppVersion). Remove BUILD_VERSION from .env or set a matching version."
  }
}

function Get-NextBuildNumber {
  param(
    [Parameter(Mandatory = $true)]
    [string] $StateDir,

    [Parameter(Mandatory = $true)]
    [string] $VersionCore,

    [Parameter(Mandatory = $true)]
    [string] $Channel
  )

  New-Item -ItemType Directory -Force -Path $StateDir | Out-Null

  $safeVersion = $VersionCore -replace "[^0-9.]", "-"
  $safeChannel = $Channel -replace "[^a-z0-9._-]", "-"
  $counterPath = Join-Path $StateDir "build-$safeVersion-$safeChannel.txt"

  $current = 0
  if (Test-Path -LiteralPath $counterPath -PathType Leaf) {
    $raw = (Get-Content -LiteralPath $counterPath -Raw).Trim()
    if ($raw -match "^\d+$") {
      $current = [int] $raw
    }
  }

  $next = $current + 1
  Set-Content -LiteralPath $counterPath -Value $next -Encoding ASCII

  return $next
}

try {
  $Root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..\..")).Path
  $SetupRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
  $NsisDir = Join-Path $SetupRoot "src\nsis"
  $DistDir = Join-Path $Root "dist\setup"
  $BuildStateDir = Join-Path $Root ".build"
  $NsisScriptPath = Join-Path $NsisDir "Codex13StudentDevKit.nsi"
  $ConfigPath = Join-Path $NsisDir "config.nsh"
  $VerifyPackageScriptPath = Join-Path $SetupRoot "src\installer-scripts\verify-package.ps1"
  $WriteManifestScriptPath = Join-Path $SetupRoot "src\installer-scripts\write-manifest.ps1"
  $SevenZipPath = Join-Path $SetupRoot "vendor\tools\7zip\7za.exe"
  $PluginsDir = Join-Path $SetupRoot "vendor\plugins\x86-unicode"

  # Resolve env file: explicit param > BUILD_ENV_FILE env var > .env
  $resolvedEnvFile = if (-not [string]::IsNullOrWhiteSpace($EnvFile)) {
    if ([System.IO.Path]::IsPathRooted($EnvFile)) { $EnvFile } else { Join-Path $Root $EnvFile }
  } elseif (-not [string]::IsNullOrWhiteSpace($env:BUILD_ENV_FILE)) {
    $env:BUILD_ENV_FILE
  } else {
    Join-Path $Root ".env"
  }

  if (-not [string]::IsNullOrWhiteSpace($EnvFile) -and -not (Test-Path -LiteralPath $resolvedEnvFile -PathType Leaf)) {
    throw "The specified env file does not exist: $resolvedEnvFile"
  }

  Import-DotEnv -Path $resolvedEnvFile

  if ([string]::IsNullOrWhiteSpace($env:NSIS_PATH)) {
    throw "NSIS_PATH is not set. Add it to the .env file."
  }

  $NsisPath = Resolve-RequiredFile -Path $env:NSIS_PATH -Label "makensis.exe configured in NSIS_PATH"
  $NsisScriptPath = Resolve-RequiredFile -Path $NsisScriptPath -Label "NSIS installer script"
  $ConfigPath = Resolve-RequiredFile -Path $ConfigPath -Label "NSIS config file"
  $VerifyPackageScriptPath = Resolve-RequiredFile -Path $VerifyPackageScriptPath -Label "Package verification script"
  $WriteManifestScriptPath = Resolve-RequiredFile -Path $WriteManifestScriptPath -Label "Manifest writer script"
  $SevenZipPath = Resolve-RequiredFile -Path $SevenZipPath -Label "Bundled 7-Zip executable"
  $PluginsDir = Resolve-RequiredDirectory -Path $PluginsDir -Label "NSIS Unicode plugin directory"

  $configText = Get-Content -LiteralPath $ConfigPath -Raw
  foreach ($metadataInclude in @("i18n\version-pl.nsh", "i18n\version-en.nsh")) {
    $metadataPath = Join-Path $NsisDir $metadataInclude
    if (Test-Path -LiteralPath $metadataPath -PathType Leaf) {
      $configText += "`n" + (Get-Content -LiteralPath $metadataPath -Raw)
    }
  }
  $AppVersion = Get-NsisDefineValue -ConfigText $configText -Name "APP_VERSION"
  $BuildSettings = Resolve-BuildSettings -AppVersion $AppVersion
  $VersionCore = Get-SemVerCore -Version $BuildSettings.Version
  Assert-BuildVersionMatchesAppVersion -BuildVersionCore $VersionCore -AppVersion $AppVersion
  $BuildNumber = Get-NextBuildNumber -StateDir $BuildStateDir -VersionCore $VersionCore -Channel $BuildSettings.Channel
  $VersionQuad = "$VersionCore.$BuildNumber"

  $requiredPlugins = @(
    "INetC.dll",
    "nasterarchive.dll"
  )

  foreach ($plugin in $requiredPlugins) {
    Resolve-RequiredFile -Path (Join-Path $PluginsDir $plugin) -Label "Required NSIS plugin" | Out-Null
  }

  $requiredDefines = @(
    "APP_NAME",
    "APP_PUBLISHER",
    "APP_EXE_NAME",
    "APP_INTERNAL_NAME",
    "APP_REGISTRY_KEY",
    "APP_SETTINGS_REG_KEY",
    "APP_START_MENU_FOLDER",
    "APP_VERSION",
    "APP_VERSION_QUAD",
    "LANG_VERSION_POLISH",
    "LANG_VERSION_ENGLISH",
    "APP_FILE_DESCRIPTION_PL",
    "APP_FILE_DESCRIPTION_EN",
    "APP_DESCRIPTION_PL",
    "APP_DESCRIPTION_EN",
    "APP_COPYRIGHT_PL",
    "APP_COPYRIGHT_EN",
    "APP_TRADEMARKS_PL",
    "APP_TRADEMARKS_EN",
    "APP_PRIVATE_BUILD_PL",
    "APP_PRIVATE_BUILD_EN",
    "APP_SPECIAL_BUILD_PL",
    "APP_SPECIAL_BUILD_EN",
    "APP_WEBSITE",
    "BUILD_CHANNEL",
    "BUILD_VERSION",
    "DEFAULT_INSTALL_DIR",
    "TOOLS_DIR_NAME",
    "PACKAGES_DIR_NAME",
    "BIN_DIR_NAME",
    "LOGS_DIR_NAME",
    "VSCODE_INSTALL_DIR",
    "XAMPP_INSTALL_DIR",
    "VSCODE_EXE_REL",
    "XAMPP_CONTROL_EXE_REL",
    "VSCODE_VERSION",
    "VSCODE_URL",
    "VSCODE_SHA256",
    "VSCODE_SIZE_KB",
    "XAMPP_URL",
    "XAMPP_SHA256",
    "XAMPP_SIZE_KB",
    "GIT_VERSION",
    "GIT_URL",
    "GIT_SHA256",
    "GIT_SIZE_KB",
    "GIT_INSTALL_DIR",
    "GIT_BASH_EXE_REL",
    "GIT_CMD_EXE_REL",
    "OPENSSH_VERSION",
    "OPENSSH_URL",
    "OPENSSH_SHA256",
    "OPENSSH_SIZE_KB",
    "OPENSSH_INSTALL_DIR",
    "OPENSSH_SSH_EXE_REL"
  )

  foreach ($define in $requiredDefines) {
    Assert-NsisDefine -ConfigText $configText -Name $define
  }

  New-Item -ItemType Directory -Force -Path $DistDir | Out-Null
  $OutputPath = Join-Path $DistDir $BuildSettings.ExeName

  Push-Location -LiteralPath $NsisDir
  try {
    $addPluginDirArgument = "/X!addplugindir `"$PluginsDir`""
    $nsisArgs = @(
      "/INPUTCHARSET", "UTF8",
      "/DBUILD_CHANNEL=$($BuildSettings.Channel)",
      "/DBUILD_VERSION=$($BuildSettings.Version)",
      "/DAPP_VERSION_QUAD=$VersionQuad",
      "/DAPP_EXE_NAME=$($BuildSettings.ExeName)",
      "/DAPP_OUTPUT_PATH=$OutputPath",
      $addPluginDirArgument
    )
    if ($env:C13_DEBUG_LOG_ENABLED -eq "1") {
      $nsisArgs += "/DC13_DEBUG_LOG_ENABLED"
      if (-not [string]::IsNullOrWhiteSpace($env:C13_DEBUG_LOG_FILE)) {
        $nsisArgs += "/DC13_DBG_LOG=$($env:C13_DEBUG_LOG_FILE)"
      }
    }
    $nsisArgs += ".\Codex13StudentDevKit.nsi"
    $global:LASTEXITCODE = 0
    & $NsisPath @nsisArgs

    if ($LASTEXITCODE -ne 0) {
      throw "makensis.exe exited with code $LASTEXITCODE."
    }
  }
  finally {
    Pop-Location
  }

  Invoke-CodeSigning -FilePath $OutputPath

  Write-Host "Build finished: $OutputPath"
  Write-Host "Resource version: $VersionQuad"
}
catch {
  Write-Error -Message "NSIS build failed: $_" -ErrorAction Continue
  exit 1
}
