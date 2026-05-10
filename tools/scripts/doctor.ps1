$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$Root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..")).Path
$PackageJsonPath = Join-Path $Root "package.json"
$DriveToolsRoot = Join-Path (Split-Path -Parent $Root) "tools"
$EnvFiles = @(
  @{ Label = ".env"; Path = (Join-Path $Root ".env"); Required = $false },
  @{ Label = ".env.prod"; Path = (Join-Path $Root ".env.prod"); Required = $false }
)

$okCount = 0
$warnCount = 0
$failCount = 0

function Write-Check {
  param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("OK", "WARN", "FAIL")]
    [string] $Status,

    [Parameter(Mandatory = $true)]
    [string] $Label,

    [string] $Detail = ""
  )

  $color = switch ($Status) {
    "OK" { "Green" }
    "WARN" { "Yellow" }
    "FAIL" { "Red" }
  }
  $symbol = switch ($Status) {
    "OK" { "[OK]  " }
    "WARN" { "[WARN]" }
    "FAIL" { "[FAIL]" }
  }

  $line = "$symbol $Label"
  if ($Detail) { $line += " - $Detail" }
  Write-Host $line -ForegroundColor $color

  switch ($Status) {
    "OK" { $script:okCount++ }
    "WARN" { $script:warnCount++ }
    "FAIL" { $script:failCount++ }
  }
}

function Resolve-CommandPath {
  param(
    [Parameter(Mandatory = $true)]
    [string] $Exe,

    [string[]] $CandidatePaths = @()
  )

  $command = Get-Command $Exe -ErrorAction SilentlyContinue
  if ($command) {
    return $command.Source
  }

  foreach ($candidate in $CandidatePaths) {
    if ([string]::IsNullOrWhiteSpace($candidate)) { continue }
    if (Test-Path -LiteralPath $candidate -PathType Leaf) {
      return (Resolve-Path -LiteralPath $candidate).Path
    }
  }

  return $null
}

function Test-Command {
  param(
    [Parameter(Mandatory = $true)]
    [string] $Label,

    [Parameter(Mandatory = $true)]
    [string] $Exe,

    [string] $Arguments = "--version",

    [string] $Expected = "",

    [string[]] $CandidatePaths = @()
  )

  $resolvedExe = Resolve-CommandPath -Exe $Exe -CandidatePaths $CandidatePaths
  if (-not $resolvedExe) {
    Write-Check "FAIL" $Label "not found in PATH or local tool paths"
    return
  }

  $global:LASTEXITCODE = 0
  try {
    $quotedExe = '"' + ($resolvedExe -replace '"', '\"') + '"'
    $cmdLine = "$quotedExe $Arguments"
    $out = (& cmd.exe /d /s /c $cmdLine 2>&1) |
      Where-Object { -not [string]::IsNullOrWhiteSpace("$_") } |
      Select-Object -First 1
    if ($LASTEXITCODE -ne 0) {
      Write-Check "FAIL" $Label "exit $LASTEXITCODE"
      return
    }
    if ([string]::IsNullOrWhiteSpace("$out")) {
      Write-Check "OK" $Label "found at $resolvedExe; version output unavailable in this shell"
    }
    elseif ($Expected -and ("$out" -notmatch [regex]::Escape($Expected))) {
      Write-Check "WARN" $Label "expected $Expected; got: $out"
    }
    else {
      Write-Check "OK" $Label "$out ($resolvedExe)"
    }
  }
  catch {
    Write-Check "FAIL" $Label "failed to run: $resolvedExe"
  }
}

function Resolve-VsWhere {
  $path = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\vswhere.exe"
  if (Test-Path -LiteralPath $path -PathType Leaf) {
    return $path
  }

  return $null
}

function Resolve-MSBuildPath {
  $command = Get-Command "MSBuild.exe" -ErrorAction SilentlyContinue
  if ($command) {
    return $command.Source
  }

  $vswhere = Resolve-VsWhere
  if ($vswhere) {
    $installationPath = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($installationPath)) {
      foreach ($candidate in @(
          (Join-Path $installationPath "MSBuild\Current\Bin\amd64\MSBuild.exe"),
          (Join-Path $installationPath "MSBuild\Current\Bin\MSBuild.exe")
        )) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
          return (Resolve-Path -LiteralPath $candidate).Path
        }
      }
    }
  }

  foreach ($root in @("${env:ProgramFiles}\Microsoft Visual Studio", "${env:ProgramFiles(x86)}\Microsoft Visual Studio")) {
    if (-not (Test-Path -LiteralPath $root -PathType Container)) { continue }
    $candidate = Get-ChildItem -LiteralPath $root -Recurse -Filter "MSBuild.exe" -ErrorAction SilentlyContinue |
      Where-Object { $_.FullName -match "\\MSBuild\\Current\\Bin\\(amd64\\)?MSBuild\.exe$" } |
      Sort-Object FullName -Descending |
      Select-Object -First 1
    if ($candidate) { return $candidate.FullName }
  }

  return $null
}

function Resolve-VcTargetsPath {
  if (-not [string]::IsNullOrWhiteSpace($env:VCTargetsPath)) {
    $candidate = Join-Path $env:VCTargetsPath "Microsoft.Cpp.Default.props"
    if (Test-Path -LiteralPath $candidate -PathType Leaf) {
      return $env:VCTargetsPath
    }
  }

  $vswhere = Resolve-VsWhere
  if ($vswhere) {
    $installationPath = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($installationPath)) {
      $candidate = Join-Path $installationPath "MSBuild\Microsoft\VC\v170"
      if (Test-Path -LiteralPath (Join-Path $candidate "Microsoft.Cpp.Default.props") -PathType Leaf) {
        return $candidate
      }
    }
  }

  foreach ($root in @("${env:ProgramFiles}\Microsoft Visual Studio", "${env:ProgramFiles(x86)}\Microsoft Visual Studio")) {
    if (-not (Test-Path -LiteralPath $root -PathType Container)) { continue }
    $candidate = Get-ChildItem -LiteralPath $root -Recurse -Filter "Microsoft.Cpp.Default.props" -ErrorAction SilentlyContinue |
      Select-Object -First 1
    if ($candidate) { return $candidate.DirectoryName }
  }

  return $null
}

function Resolve-SignToolPath {
  $command = Get-Command "signtool.exe" -ErrorAction SilentlyContinue
  if ($command) {
    return $command.Source
  }

  foreach ($sdkRoot in @("${env:ProgramFiles(x86)}\Windows Kits\10\bin", "${env:ProgramFiles}\Windows Kits\10\bin")) {
    if (-not (Test-Path -LiteralPath $sdkRoot -PathType Container)) { continue }
    $candidate = Get-ChildItem -LiteralPath $sdkRoot -Recurse -Filter "signtool.exe" -ErrorAction SilentlyContinue |
      Where-Object { $_.FullName -match "\\x64\\signtool\.exe$" } |
      Sort-Object FullName -Descending |
      Select-Object -First 1
    if ($candidate) { return $candidate.FullName }
  }

  return $null
}

function Read-DotEnvValue {
  param(
    [Parameter(Mandatory = $true)]
    [string] $Path,

    [Parameter(Mandatory = $true)]
    [string] $Name
  )

  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
  foreach ($line in Get-Content -LiteralPath $Path) {
    $trimmed = $line.Trim()
    if ($trimmed.Length -eq 0 -or $trimmed.StartsWith("#")) { continue }
    $parts = $line -split "=", 2
    if ($parts.Count -eq 2 -and $parts[0].Trim() -eq $Name) {
      return [System.Environment]::ExpandEnvironmentVariables($parts[1].Trim())
    }
  }

  return $null
}

$packageData = Get-Content -LiteralPath $PackageJsonPath -Raw | ConvertFrom-Json
$expectedNode = $packageData.engines.node
$expectedPnpm = $packageData.engines.pnpm

Write-Host ""
Write-Host "Codex 13 SDK dev environment doctor" -ForegroundColor Cyan
Write-Host ("=" * 40)
Write-Host ""

$psVer = $PSVersionTable.PSVersion
if ($PSVersionTable.PSEdition -eq "Core" -and $psVer.Major -ge 7) {
  Write-Check "OK" "PowerShell 7" "$psVer"
}
else {
  Write-Check "FAIL" "PowerShell 7" "pwsh 7+ required; got $($PSVersionTable.PSEdition) $psVer"
}

Test-Command -Label "Task runner (go-task)" -Exe "task" -Arguments "--version" -CandidatePaths @(
  (Join-Path $DriveToolsRoot "task\task.exe")
)
Test-Command -Label "Node.js" -Exe "node" -Arguments "--version" -Expected "v$expectedNode" -CandidatePaths @(
  (Join-Path $DriveToolsRoot "volta\node.exe")
)
Test-Command -Label "pnpm" -Exe "pnpm" -Arguments "--version" -Expected $expectedPnpm -CandidatePaths @(
  (Join-Path $DriveToolsRoot "volta\pnpm.cmd")
)
Test-Command -Label "Git" -Exe "git" -Arguments "--version" -CandidatePaths @(
  (Join-Path $DriveToolsRoot "git\cmd\git.exe"),
  (Join-Path $DriveToolsRoot "git\bin\git.exe")
)
Test-Command -Label ".NET SDK" -Exe "dotnet" -Arguments "--version" -CandidatePaths @(
  (Join-Path $DriveToolsRoot "dotnet-sdk\dotnet.exe")
)
Test-Command -Label "act" -Exe "act" -Arguments "--version" -CandidatePaths @(
  (Join-Path $DriveToolsRoot "act\act.exe")
)

$msbuild = Resolve-MSBuildPath
if ($msbuild) { Write-Check "OK" "MSBuild" $msbuild } else { Write-Check "FAIL" "MSBuild" "Visual Studio Build Tools with C++ workload required for plugin rebuilds" }

$vcTargets = Resolve-VcTargetsPath
if ($vcTargets) { Write-Check "OK" "MSVC C++ targets" $vcTargets } else { Write-Check "FAIL" "MSVC C++ targets" "Microsoft.Cpp.Default.props not found" }

$signTool = Resolve-SignToolPath
if ($signTool) { Write-Check "OK" "signtool.exe" $signTool } else { Write-Check "WARN" "signtool.exe" "required only when SIGNING_ENABLED=1" }

if (Get-Module -ListAvailable -Name PSScriptAnalyzer) {
  $psaVer = (Get-Module -ListAvailable -Name PSScriptAnalyzer | Sort-Object Version -Descending | Select-Object -First 1).Version
  Write-Check "OK" "PSScriptAnalyzer" "v$psaVer"
}
else {
  Write-Check "FAIL" "PSScriptAnalyzer" "run: Install-Module PSScriptAnalyzer -Scope CurrentUser"
}

foreach ($envFile in $EnvFiles) {
  $label = [string] $envFile.Label
  $path = [string] $envFile.Path
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    Write-Check "WARN" $label "not found"
    continue
  }

  Write-Check "OK" $label "exists"
  $nsisPath = Read-DotEnvValue -Path $path -Name "NSIS_PATH"
  if ([string]::IsNullOrWhiteSpace($nsisPath)) {
    Write-Check "WARN" "$label NSIS_PATH" "not set"
  }
  elseif (Test-Path -LiteralPath $nsisPath -PathType Leaf) {
    $nsisVer = & $nsisPath /VERSION 2>&1
    Write-Check "OK" "$label makensis.exe" "NSIS $nsisVer"
  }
  else {
    Write-Check "FAIL" "$label makensis.exe" "file not found: $nsisPath"
  }

  $signingEnabled = Read-DotEnvValue -Path $path -Name "SIGNING_ENABLED"
  if ($signingEnabled -eq "1" -and -not $signTool) {
    Write-Check "FAIL" "$label signing" "SIGNING_ENABLED=1 but signtool.exe was not found"
  }
}

Write-Host ""
Write-Host ("=" * 40)
$summary = "OK: $okCount   WARN: $warnCount   FAIL: $failCount"
$summaryColor = if ($failCount -gt 0) { "Red" } elseif ($warnCount -gt 0) { "Yellow" } else { "Green" }
Write-Host $summary -ForegroundColor $summaryColor
Write-Host ""

if ($failCount -gt 0) {
  throw "Doctor found $failCount failing check(s). Fix the issues above before building."
}
