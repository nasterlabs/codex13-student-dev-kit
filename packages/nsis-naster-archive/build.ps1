param(
  [ValidateSet("DebugUnicode", "ReleaseUnicode")]
  [string] $Configuration = "ReleaseUnicode",

  [ValidateSet("Win32")]
  [string] $Platform = "Win32",

  [switch] $NoCopy
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Resolve-DotNet {
  $candidates = @(
    $env:DOTNET_ROOT,
    $env:DOTNET_HOME
  ) |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
    ForEach-Object { Join-Path $_ "dotnet.exe" }

  foreach ($candidate in $candidates) {
    if (Test-Path -LiteralPath $candidate -PathType Leaf) {
      return (Resolve-Path -LiteralPath $candidate).Path
    }
  }

  $command = Get-Command "dotnet.exe" -ErrorAction SilentlyContinue
  if ($command) {
    return $command.Source
  }

  throw "dotnet.exe was not found. Add the .NET SDK to PATH or set DOTNET_ROOT/DOTNET_HOME."
}

function Resolve-VcTargetsPath {
  if (-not [string]::IsNullOrWhiteSpace($env:VCTargetsPath)) {
    $candidate = Join-Path $env:VCTargetsPath "Microsoft.Cpp.Default.props"
    if (Test-Path -LiteralPath $candidate -PathType Leaf) {
      return $env:VCTargetsPath
    }
  }

  $vswherePath = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\vswhere.exe"
  if (Test-Path -LiteralPath $vswherePath -PathType Leaf) {
    $installationPath = & $vswherePath -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    $vswhereExitCode = if (Get-Variable -Name LASTEXITCODE -Scope Global -ErrorAction SilentlyContinue) { $global:LASTEXITCODE } else { 0 }
    if ($vswhereExitCode -eq 0 -and -not [string]::IsNullOrWhiteSpace($installationPath)) {
      $candidate = Join-Path $installationPath "MSBuild\Microsoft\VC\v170\"
      if (Test-Path -LiteralPath (Join-Path $candidate "Microsoft.Cpp.Default.props") -PathType Leaf) {
        return $candidate
      }
    }
  }

  $knownRoots = @(
    "${env:ProgramFiles}\Microsoft Visual Studio",
    "${env:ProgramFiles(x86)}\Microsoft Visual Studio"
  )

  foreach ($root in $knownRoots) {
    if (-not (Test-Path -LiteralPath $root -PathType Container)) {
      continue
    }

    $candidate = Get-ChildItem -LiteralPath $root -Recurse -Filter "Microsoft.Cpp.Default.props" -ErrorAction SilentlyContinue |
      Select-Object -First 1

    if ($candidate) {
      return $candidate.DirectoryName
    }
  }

  return $null
}

function Resolve-MSBuild {
  $vswherePath = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\vswhere.exe"
  if (Test-Path -LiteralPath $vswherePath -PathType Leaf) {
    $installationPath = & $vswherePath -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    $vswhereExitCode = if (Get-Variable -Name LASTEXITCODE -Scope Global -ErrorAction SilentlyContinue) { $global:LASTEXITCODE } else { 0 }
    if ($vswhereExitCode -eq 0 -and -not [string]::IsNullOrWhiteSpace($installationPath)) {
      $candidates = @(
        (Join-Path $installationPath "MSBuild\Current\Bin\amd64\MSBuild.exe"),
        (Join-Path $installationPath "MSBuild\Current\Bin\MSBuild.exe")
      )

      foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
          return (Resolve-Path -LiteralPath $candidate).Path
        }
      }
    }
  }

  $knownRoots = @(
    "${env:ProgramFiles}\Microsoft Visual Studio",
    "${env:ProgramFiles(x86)}\Microsoft Visual Studio"
  )

  foreach ($root in $knownRoots) {
    if (-not (Test-Path -LiteralPath $root -PathType Container)) {
      continue
    }

    $candidate = Get-ChildItem -LiteralPath $root -Recurse -Filter "MSBuild.exe" -ErrorAction SilentlyContinue |
      Where-Object { $_.FullName -match "\\MSBuild\\Current\\Bin\\(amd64\\)?MSBuild\.exe$" } |
      Sort-Object FullName -Descending |
      Select-Object -First 1

    if ($candidate) {
      return $candidate.FullName
    }
  }

  return $null
}

$PluginRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path -LiteralPath (Join-Path $PluginRoot "..\..")
$ProjectPath = Join-Path $PluginRoot "src\nasterarchive.vcxproj"
$OutputPath = Join-Path $PluginRoot "bin\$Platform\$Configuration\nasterarchive.dll"
$DistPluginDir = Join-Path $RepoRoot "dist\nsis-naster-archive\plugins\x86-unicode"
$DistOutputPath = Join-Path $DistPluginDir "nasterarchive.dll"
$InstallerPluginDir = Join-Path $RepoRoot "apps\setup\vendor\plugins\x86-unicode"
$VendorHashPath = Join-Path $RepoRoot "apps\setup\vendor\vendor.sha256"
$DotNetPath = Resolve-DotNet
$VcTargetsPath = Resolve-VcTargetsPath
$MSBuildPath = Resolve-MSBuild

if (-not [string]::IsNullOrWhiteSpace($VcTargetsPath) -and -not $VcTargetsPath.EndsWith("\")) {
  $VcTargetsPath = "$VcTargetsPath\"
}

if ([string]::IsNullOrWhiteSpace($VcTargetsPath)) {
  throw "Microsoft.Cpp.Default.props was not found. Building nsis-naster-archive requires MSVC C++ Build Tools with the VC.Tools.x86.x64 component and the Windows SDK. The .NET SDK does not include native C++ targets."
}

if ([string]::IsNullOrWhiteSpace($MSBuildPath)) {
  throw "MSBuild.exe from Visual Studio Build Tools was not found. .vcxproj projects require MSBuild from Build Tools even when the .NET SDK is available."
}

Write-Host "Building nsis-naster-archive: $Configuration|$Platform"
Write-Host "dotnet: $DotNetPath"
Write-Host "MSBuild: $MSBuildPath"
Write-Host "VCTargetsPath: $VcTargetsPath"
$env:VCTargetsPath = $VcTargetsPath
$msbuildArgs = @(
  $ProjectPath,
  "/t:Rebuild",
  "/v:minimal",
  "/p:Configuration=$Configuration",
  "/p:Platform=$Platform",
  "/p:RestoreIgnoreFailedSources=true"
)
$msbuildLog = Join-Path $PluginRoot "obj\msbuild.log"
$msbuildErrorLog = Join-Path $PluginRoot "obj\msbuild.err.log"
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $msbuildLog) | Out-Null
$quotedMsBuildPath = '"' + $MSBuildPath + '"'
$quotedArgs = $msbuildArgs | ForEach-Object { '"' + ($_ -replace '"', '\"') + '"' }
$cmdLine = "$quotedMsBuildPath $($quotedArgs -join ' ') > `"$msbuildLog`" 2> `"$msbuildErrorLog`""
& cmd.exe /d /s /c $cmdLine
$msbuildExitCode = if (Get-Variable -Name LASTEXITCODE -Scope Global -ErrorAction SilentlyContinue) { $global:LASTEXITCODE } else { 0 }
if (Test-Path -LiteralPath $msbuildLog -PathType Leaf) {
  Get-Content -LiteralPath $msbuildLog
}
if (Test-Path -LiteralPath $msbuildErrorLog -PathType Leaf) {
  Get-Content -LiteralPath $msbuildErrorLog
}
if ($msbuildExitCode -ne 0) {
  throw "MSBuild.exe exited with code $msbuildExitCode."
}

$OutputReady = $false
for ($attempt = 0; $attempt -lt 20; $attempt++) {
  if (Test-Path -LiteralPath $OutputPath -PathType Leaf) {
    $OutputReady = $true
    break
  }
  Start-Sleep -Milliseconds 250
}

if (-not $OutputReady) {
  throw "Built plugin was not found: $OutputPath"
}

$CopyReady = $false
for ($attempt = 0; $attempt -lt 20; $attempt++) {
  try {
    New-Item -ItemType Directory -Force -Path $DistPluginDir | Out-Null
    Copy-Item -LiteralPath $OutputPath -Destination $DistOutputPath -Force
    $CopyReady = $true
    break
  } catch [System.IO.IOException] {
    Start-Sleep -Milliseconds 250
  }
}
if (-not $CopyReady) {
  Copy-Item -LiteralPath $OutputPath -Destination $DistOutputPath -Force
}
Write-Host "Copied dist artifact to: $DistOutputPath"

if (-not $NoCopy) {
  New-Item -ItemType Directory -Force -Path $InstallerPluginDir | Out-Null
  $installerPluginPath = Join-Path $InstallerPluginDir "nasterarchive.dll"
  Copy-Item -LiteralPath $DistOutputPath -Destination $installerPluginPath -Force
  Write-Host "Copied plugin to: $InstallerPluginDir"

  $relativePluginPath = "plugins/x86-unicode/nasterarchive.dll"
  $pluginHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $installerPluginPath).Hash.ToLowerInvariant()
  $hashLine = "$pluginHash  $relativePluginPath"
  $hashUpdated = $false
  $hashLines = @()

  if (Test-Path -LiteralPath $VendorHashPath -PathType Leaf) {
    $hashLines = Get-Content -LiteralPath $VendorHashPath
  }

  $hashLines = @(
    foreach ($line in $hashLines) {
      if ($line -match "\s+$([regex]::Escape($relativePluginPath))$") {
        $hashUpdated = $true
        $hashLine
      }
      else {
        $line
      }
    }
  )

  if (-not $hashUpdated) {
    $hashLines += $hashLine
  }

  [System.IO.File]::WriteAllText($VendorHashPath, (($hashLines -join "`n") + "`n"), [System.Text.Encoding]::ASCII)
  Write-Host "Updated vendor checksum: $relativePluginPath"
}

Write-Host "Done: $DistOutputPath"
