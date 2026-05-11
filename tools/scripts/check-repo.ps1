$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$Root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..")).Path
$failed = $false
$GitCommand = Get-Command "git.exe" -ErrorAction SilentlyContinue
$GitIndexAvailable = $false

if ($GitCommand) {
  $global:LASTEXITCODE = 0
  $readmeTrackedProbe = @(& $GitCommand.Source -C $Root ls-files -- "README.md" 2>$null)
  if ($LASTEXITCODE -eq 0 -and $readmeTrackedProbe -contains "README.md") {
    $GitIndexAvailable = $true
  }
  else {
    Write-Warning "git.exe is available but did not return the expected repository index; tracked-path checks will be skipped in this environment."
  }
}

$DocExtensions = @(".md", ".txt", ".rtf")

function Add-Failure {
  param(
    [Parameter(Mandatory = $true)]
    [string] $Message
  )

  $script:failed = $true
  Write-Error -Message $Message -ErrorAction Continue
}

function Get-RepoTextFiles {
  if (-not $GitIndexAvailable) {
    Write-Warning "Git index is not available; skipping repository-wide text scans in this environment."
    return @()
  }

  $global:LASTEXITCODE = 0
  $files = @(& $GitCommand.Source -C $Root ls-files)
  if ($LASTEXITCODE -ne 0) {
    Add-Failure "git ls-files failed while collecting repository text files."
    return @()
  }

  return @($files | Where-Object {
    if ($_ -eq "tools/scripts/check-repo.ps1") { return $false }
    if ($_.StartsWith("apps/setup/src/payload/licenses/")) { return $false }

    $extension = [System.IO.Path]::GetExtension($_).ToLowerInvariant()
    $extension -in @(
      ".md", ".txt", ".ps1", ".cmd", ".bat", ".nsi", ".nsh", ".yml", ".yaml",
      ".json", ".cjs", ".js", ".xml", ".vcxproj", ".filters", ".props",
      ".targets", ".rc", ".h", ".c", ".cpp", ".hpp", ".ini", ".gitignore",
      ".gitattributes", ".npmrc"
    ) -or $_ -in @(
      "LICENSE", "NOTICE", "CHANGELOG.md", "README.md", "CONTRIBUTING.md",
      "SECURITY.md", "SUPPORT.md", "Taskfile.yml"
    )
  })
}

function Get-FileText {
  param(
    [Parameter(Mandatory = $true)]
    [string] $RelativePath
  )

  $path = Join-Path $Root $RelativePath
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    return ""
  }

  return Get-Content -LiteralPath $path -Raw
}

function Assert-File {
  param(
    [Parameter(Mandatory = $true)]
    [string] $RelativePath
  )

  $path = Join-Path $Root $RelativePath
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    Add-Failure "Missing required file: $RelativePath"
  }
}

function Assert-TrackedFile {
  param(
    [Parameter(Mandatory = $true)]
    [string] $RelativePath
  )

  if (-not $GitIndexAvailable) {
    Write-Warning "Git index is not available; skipping tracked-file check for $RelativePath."
    return
  }

  $global:LASTEXITCODE = 0
  $tracked = @(& $GitCommand.Source -C $Root ls-files -- $RelativePath)
  if ($LASTEXITCODE -ne 0) {
    Add-Failure "git ls-files failed for required file: $RelativePath"
    return
  }

  if ($tracked -notcontains $RelativePath) {
    Add-Failure "Required file exists in the release source set but is not tracked: $RelativePath"
  }
}

function Assert-Directory {
  param(
    [Parameter(Mandatory = $true)]
    [string] $RelativePath
  )

  $path = Join-Path $Root $RelativePath
  if (-not (Test-Path -LiteralPath $path -PathType Container)) {
    Add-Failure "Missing required directory: $RelativePath"
  }
}

function Assert-DocsLinks {
  param(
    [Parameter(Mandatory = $true)]
    [string[]] $RelativePaths
  )

  foreach ($relativePath in $RelativePaths) {
    $extension = [System.IO.Path]::GetExtension($relativePath).ToLowerInvariant()
    if ($extension -notin $DocExtensions) {
      continue
    }

    $text = Get-FileText -RelativePath $relativePath
    if ([string]::IsNullOrEmpty($text)) {
      continue
    }

    $linkMatches = [regex]::Matches($text, '!\[[^\]]*\]\(([^)]+)\)|\[[^\]]+\]\(([^)]+)\)')
    foreach ($match in $linkMatches) {
      $target = if ($match.Groups[1].Success) { $match.Groups[1].Value } else { $match.Groups[2].Value }
      $target = $target.Trim()

      if ($target -eq "" -or $target.StartsWith("#")) {
        continue
      }

      if ($target -match '^[a-z][a-z0-9+.-]*:' -or $target.StartsWith("mailto:")) {
        continue
      }

      $pathOnly = ($target -split "#", 2)[0]
      $pathOnly = ($pathOnly -split "\?", 2)[0]
      if ($pathOnly -eq "") {
        continue
      }

      $decoded = [System.Uri]::UnescapeDataString($pathOnly)
      $baseDir = Split-Path -Parent $relativePath
      $candidate = if ([string]::IsNullOrEmpty($baseDir)) {
        Join-Path $Root $decoded
      } else {
        Join-Path (Join-Path $Root $baseDir) $decoded
      }

      if (-not (Test-Path -LiteralPath $candidate)) {
        Add-Failure "Broken local documentation link in ${relativePath}: $target"
      }
    }
  }
}

function Assert-VersionConsistency {
  $configText = Get-FileText -RelativePath "apps/setup/src/nsis/config.nsh"
  $packageText = Get-FileText -RelativePath "package.json"
  $readmeText = Get-FileText -RelativePath "README.md"
  $releaseText = Get-FileText -RelativePath "docs/release.md"

  $appVersionMatch = [regex]::Match($configText, '(?m)^\s*!define\s+APP_VERSION\s+"([^"]+)"')
  if (-not $appVersionMatch.Success) {
    Add-Failure "Cannot read APP_VERSION from apps/setup/src/nsis/config.nsh."
    return
  }

  $appVersion = $appVersionMatch.Groups[1].Value

  try {
    $packageJson = $packageText | ConvertFrom-Json
    $packageVersion = [string] $packageJson.version
  }
  catch {
    Add-Failure "Cannot parse package.json: $_"
    return
  }

  $prerelease = '(-((0|[1-9]\d*|\d*[A-Za-z-][0-9A-Za-z-]*)(\.(0|[1-9]\d*|\d*[A-Za-z-][0-9A-Za-z-]*))*))?'
  $buildMetadata = '(\+([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))?'
  $semverForAppVersion = "^$([regex]::Escape($appVersion))$prerelease$buildMetadata$"
  if ($packageVersion -notmatch $semverForAppVersion) {
    Add-Failure "package.json version ($packageVersion) must be valid SemVer with core matching APP_VERSION ($appVersion)."
  }

  foreach ($doc in @(
    @{ Path = "README.md"; Text = $readmeText },
    @{ Path = "docs/release.md"; Text = $releaseText }
  )) {
    if ($doc.Text -notmatch [regex]::Escape("$appVersion-alpha.<build_number>")) {
      Add-Failure "$($doc.Path) does not mention $appVersion-alpha.<build_number>."
    }
  }
}

function Assert-NoRepositoryLocalPath {
  param(
    [Parameter(Mandatory = $true)]
    [string] $RelativePath
  )

  $path = Join-Path $Root $RelativePath
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    return
  }

  $content = Get-Content -LiteralPath $path -Raw
  $localPatterns = @(
    "W:\\tools\\",
    "W:/tools/",
    "C:\\Users\\"
  )

  foreach ($pattern in $localPatterns) {
    if ($content.Contains($pattern)) {
      Add-Failure "Repository config contains local path '$pattern': $RelativePath"
    }
  }
}

function Assert-NoTrackedPath {
  param(
    [Parameter(Mandatory = $true)]
    [string] $Pathspec
  )

  if (-not $GitIndexAvailable) {
    Write-Warning "Git index is not available; skipping tracked-path check for $Pathspec."
    return
  }

  $global:LASTEXITCODE = 0
  $tracked = @(& $GitCommand.Source -C $Root ls-files -- $Pathspec)
  if ($LASTEXITCODE -ne 0) {
    Add-Failure "git ls-files failed for pathspec: $Pathspec"
    return
  }

  foreach ($path in $tracked) {
    Add-Failure "Unexpected tracked generated/local file: $path"
  }
}

$requiredFiles = @(
  "AGENTS.md",
  "CHANGELOG.md",
  "CITATION.cff",
  "CODE_OF_CONDUCT.md",
  "CONTRIBUTING.md",
  "LICENSE",
  "NOTICE",
  "README.md",
  "SECURITY.md",
  "SUPPORT.md",
  "Taskfile.yml",
  ".editorconfig",
  ".env.example",
  ".gitattributes",
  ".gitignore",
  ".npmrc",
  ".zenodo.json",
  ".reuse/dep5",
  ".github/CODEOWNERS",
  ".github/ISSUE_TEMPLATE/bug_report.yml",
  ".github/ISSUE_TEMPLATE/config.yml",
  ".github/ISSUE_TEMPLATE/feature_request.yml",
  ".github/PULL_REQUEST_TEMPLATE.md",
  ".github/dependabot.yml",
  ".github/workflows/ci.yml",
  ".github/workflows/codeql.yml",
  ".github/workflows/release.yml",
  "AGENTS.md",
  "CLAUDE.md",
  "commitlint.config.cjs",
  "codemeta.json",
  "LICENSES/Apache-2.0.txt",
  "LICENSES/GPL-2.0-only.txt",
  "LICENSES/LicenseRef-third-party-vendored.txt",
  "LICENSES/LicenseRef-xampp-patch.txt",
  "docs/development.md",
  "docs/release.md",
  "docs/setup/manifest.md",
  "docs/setup/unattended.md",
  "docs/third-party.md",
  "package.json",
  "pnpm-lock.yaml",
  "apps/setup/scripts/build.ps1",
  "apps/setup/src/nsis/Codex13StudentDevKit.nsi",
  "apps/setup/src/nsis/config.nsh",
  "apps/setup/src/nsis/i18n/pl.nsh",
  "apps/setup/src/nsis/i18n/en.nsh",
  "apps/setup/assets/nsis/codex13-favicon.ico",
  "apps/setup/assets/nsis/codex13.ico",
  "apps/setup/assets/nsis/codex13-header.bmp",
  "apps/setup/assets/nsis/codex13-wizard.bmp",
  "apps/setup/src/installer-scripts/write-manifest.ps1",
  "apps/setup/src/installer-scripts/verify-package.ps1",
  "apps/setup/src/patches/xampp/commands.txt",
  "apps/setup/src/patches/xampp/delete.txt",
  "apps/setup/src/patches/xampp/validations.txt",
  "apps/setup/src/patches/xampp/root/install/install.original.php",
  "apps/setup/src/patches/xampp/root/install/install.php",
  "apps/setup/src/patches/xampp/root/install/repair-xampp-paths.php",
  "apps/setup/src/patches/xampp/root/install/diagnose-php-extensions.php",
  "apps/setup/src/patches/xampp/root/install/verify-xampp-paths.php",
  "apps/setup/src/patches/xampp/root/install/verify-xampp-runtime.php",
  "apps/setup/src/payload/licenses/git/LICENSE.txt",
  "apps/setup/src/payload/licenses/openssh/LICENSE.txt",
  "apps/setup/src/payload/licenses/openssh/NOTICE.txt",
  "apps/setup/src/payload/licenses/vscode/LICENSE.txt",
  "apps/setup/src/payload/licenses/vscode/LICENSE.rtf",
  "apps/setup/src/payload/licenses/vscode/NOTICE.txt",
  "apps/setup/src/payload/licenses/xampp/LICENSES.txt",
  "apps/setup/vendor/plugins/x86-unicode/INetC.dll",
  "apps/setup/vendor/plugins/x86-unicode/nasterarchive.dll",
  "apps/setup/vendor/tools/7zip/7za.exe",
  "assets/brand/codex13-favicon.ico",
  "assets/brand/codex13-favicon.svg",
  "assets/brand/codex13-signet-digital.svg",
  "packages/nsis-naster-archive/build.ps1",
  "packages/nsis-naster-archive/src/nasterarchive.cpp",
  "packages/nsis-naster-archive/src/nasterarchive.rc",
  "packages/nsis-naster-archive/src/nasterarchive.vcxproj",
  "packages/nsis-naster-archive/src/nasterarchive.vcxproj.filters",
  "packages/nsis-naster-archive/src/resource.h",
  "tools/scripts/check-dco.ps1",
  "tools/scripts/update-release-metadata.ps1",
  "tools/scripts/write-release-manifest.ps1"
)

foreach ($file in $requiredFiles) {
  Assert-File -RelativePath $file
  Assert-TrackedFile -RelativePath $file
}

Assert-Directory -RelativePath ".github/ISSUE_TEMPLATE"

Assert-NoRepositoryLocalPath -RelativePath ".vscode/settings.json"

foreach ($wrongLockfile in @("package-lock.json", "yarn.lock")) {
  if (Test-Path -LiteralPath (Join-Path $Root $wrongLockfile) -PathType Leaf) {
    Add-Failure "Unexpected lockfile for this pnpm project: $wrongLockfile"
  }
}

foreach ($forbiddenPathspec in @(
  ".env",
  ".build/**",
  "dist/*.exe",
  "dist/**",
  "dist/packages/**",
  "node_modules/**",
  "packages/nsis-naster-archive/bin/**",
  "packages/nsis-naster-archive/obj/**"
)) {
  Assert-NoTrackedPath -Pathspec $forbiddenPathspec
}

$textFiles = @(Get-RepoTextFiles)
foreach ($textFile in $textFiles) {
  $text = Get-FileText -RelativePath $textFile
  if ($text.Contains("beintouch@luczak.consulting")) {
    Add-Failure "Legacy contact address found in $textFile."
  }
  if ($text.Contains("installer/TODO.md")) {
    Add-Failure "Reference to missing installer/TODO.md found in $textFile."
  }
}

if ($textFiles.Count -gt 0) {
  Assert-DocsLinks -RelativePaths $textFiles
}
Assert-VersionConsistency

$unexpectedPayloadFiles = @(
  "apps/setup/src/payload/logs/install.log"
)

foreach ($payloadFile in $unexpectedPayloadFiles) {
  if (Test-Path -LiteralPath (Join-Path $Root $payloadFile) -PathType Leaf) {
    Add-Failure "Unexpected example/runtime payload file: $payloadFile"
  }
}

$nsisScript = Join-Path $Root "apps\setup\src\nsis\Codex13StudentDevKit.nsi"
if (Test-Path -LiteralPath $nsisScript -PathType Leaf) {
  $bytes = [System.IO.File]::ReadAllBytes($nsisScript)
  try {
    $utf8 = New-Object System.Text.UTF8Encoding($false, $true)
    $null = $utf8.GetString($bytes)
  }
  catch {
    Add-Failure "apps/setup/src/nsis/Codex13StudentDevKit.nsi is not valid UTF-8."
  }
}

if ($failed) {
  throw "Repository checks failed."
}

Write-Host "Repository checks passed."
