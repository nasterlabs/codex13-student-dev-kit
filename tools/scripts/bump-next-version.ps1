param(
    [AllowEmptyString()]
    [string] $NextVersion = "",

    [string] $BaseBranch = "main",

    [switch] $NoBranch,

    [switch] $Commit,

    [switch] $OpenPullRequest,

    [switch] $SkipChecks
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..")).Path
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$semverPattern = '^v?(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(-((0|[1-9]\d*|\d*[A-Za-z-][0-9A-Za-z-]*)(\.(0|[1-9]\d*|\d*[A-Za-z-][0-9A-Za-z-]*))*))?(\+([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))?$'

function Resolve-NextVersion {
    param([AllowEmptyString()][string] $Value)

    $candidate = $Value.Trim()
    while ([string]::IsNullOrWhiteSpace($candidate)) {
        $candidate = (Read-Host "Next development version, for example 0.7.1-alpha.0").Trim()
    }

    if ($candidate -notmatch $semverPattern) {
        throw "Next version must be valid SemVer, for example 0.7.1-alpha.0. Actual: $candidate"
    }

    return $candidate.TrimStart("v")
}

function ConvertTo-NormalizedNewlines {
    param([Parameter(Mandatory = $true)][string] $Text)

    return ($Text -replace "`r`n", "`n") -replace "`r", "`n"
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

function Read-Utf8Text {
    param([Parameter(Mandatory = $true)][string] $Path)

    return [System.IO.File]::ReadAllText($Path, $utf8NoBom)
}

function Assert-CleanWorktree {
    $status = @(& git -C $Root status --porcelain)
    if ($LASTEXITCODE -ne 0) {
        throw "Cannot read git status."
    }

    if ($status.Count -gt 0) {
        throw "Working tree must be clean before preparing the next version."
    }
}

function Get-AppVersionCore {
    $configPath = Join-Path $Root "apps/setup/src/nsis/config.nsh"
    $configText = Read-Utf8Text -Path $configPath
    $match = [regex]::Match($configText, '(?m)^\s*!define\s+APP_VERSION\s+"(?<version>[^"]+)"')
    if (-not $match.Success) {
        throw "Cannot read APP_VERSION from $configPath."
    }

    return $match.Groups["version"].Value
}

function Get-NextPatchVersion {
    param([Parameter(Mandatory = $true)][string] $VersionCore)

    $parts = $VersionCore.Split(".")
    if ($parts.Count -ne 3) {
        throw "Version core must use major.minor.patch. Actual: $VersionCore"
    }

    return "$($parts[0]).$($parts[1]).$([int] $parts[2] + 1)"
}

function Update-TextFile {
    param(
        [Parameter(Mandatory = $true)]
        [string] $RelativePath,

        [Parameter(Mandatory = $true)]
        [string] $OldVersionCore,

        [Parameter(Mandatory = $true)]
        [string] $NewVersionCore
    )

    $path = Join-Path $Root $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        return
    }

    $oldNextPatch = Get-NextPatchVersion -VersionCore $OldVersionCore
    $newNextPatch = Get-NextPatchVersion -VersionCore $NewVersionCore
    $text = Read-Utf8Text -Path $path
    $text = ConvertTo-NormalizedNewlines -Text $text

    $text = $text.Replace($oldNextPatch, $newNextPatch)
    $text = $text.Replace($OldVersionCore, $NewVersionCore)

    Write-Utf8NoBom -Path $path -Content $text
}

$version = Resolve-NextVersion -Value $NextVersion
$versionCore = ($version -split '[-+]', 2)[0]
$branchName = "chore/start-v$version"
$commitSubject = "chore(release): start v$version"

Assert-CleanWorktree

if (-not $NoBranch) {
    & git -C $Root fetch origin $BaseBranch --quiet
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to fetch origin/$BaseBranch."
    }

    & git -C $Root switch -c $branchName "origin/$BaseBranch"
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create branch $branchName from origin/$BaseBranch."
    }
}

$oldVersionCore = Get-AppVersionCore

$packagePath = Join-Path $Root "package.json"
$package = Read-Utf8Text -Path $packagePath | ConvertFrom-Json
$package.version = $version
$packageJson = (($package | ConvertTo-Json -Depth 20) -replace "`r`n", "`n") -replace "`r", "`n"
Write-Utf8NoBom -Path $packagePath -Content "$packageJson`n"

$configPath = Join-Path $Root "apps/setup/src/nsis/config.nsh"
$configText = Read-Utf8Text -Path $configPath
$configText = [regex]::Replace(
    $configText,
    '(?m)^(!define\s+APP_VERSION\s+")([^"]+)(")',
    "`${1}$versionCore`${3}",
    1
)
Write-Utf8NoBom -Path $configPath -Content $configText

foreach ($doc in @("README.md", "docs/development.md", "docs/release.md")) {
    Update-TextFile -RelativePath $doc -OldVersionCore $oldVersionCore -NewVersionCore $versionCore
}

$metadataCommit = (& git -C $Root rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0) {
    throw "Cannot resolve metadata commit."
}

& pwsh -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Root "tools/scripts/update-release-metadata.ps1") `
    -BuildVersion $version `
    -Commit $metadataCommit `
    -ReleaseUrl "https://github.com/nasterlabs/codex13-student-dev-kit/releases/tag/v$version"
if ($LASTEXITCODE -ne 0) {
    throw "Next-version metadata update failed."
}

Write-Host "Prepared next development version $version on branch $branchName."

if ($OpenPullRequest) {
    $Commit = $true
}

if ($Commit) {
    if (-not $SkipChecks) {
        & task check
        if ($LASTEXITCODE -ne 0) {
            throw "task check failed."
        }
    }

    & git -C $Root diff --check
    if ($LASTEXITCODE -ne 0) {
        throw "git diff --check failed."
    }

    & git -C $Root add --all
    if ($LASTEXITCODE -ne 0) {
        throw "git add failed."
    }

    $staged = @(& git -C $Root diff --cached --name-only)
    if ($LASTEXITCODE -ne 0) {
        throw "git diff --cached failed."
    }

    if ($staged.Count -eq 0) {
        throw "No staged next-version changes to commit."
    }

    & git -C $Root commit -s -m $commitSubject
    if ($LASTEXITCODE -ne 0) {
        throw "git commit failed."
    }

    Write-Host "Created next-version commit: $commitSubject"
}

if ($OpenPullRequest) {
    & git -C $Root push -u origin $branchName
    if ($LASTEXITCODE -ne 0) {
        throw "git push failed."
    }

    $summaryIcon = [char]::ConvertFromUtf32(0x1F9ED)
    $verificationIcon = [char]::ConvertFromUtf32(0x2705)
    $notesIcon = [char]::ConvertFromUtf32(0x1F4DD)

    $pullRequestBodyLines = New-Object System.Collections.Generic.List[string]
    $pullRequestBodyLines.Add("## $summaryIcon Summary")
    $pullRequestBodyLines.Add("")
    $pullRequestBodyLines.Add("- start the next development version after the completed release")
    $pullRequestBodyLines.Add('- update `package.json` and Setup `APP_VERSION`')
    $pullRequestBodyLines.Add("- refresh citation/archive metadata for ``v$version``")
    $pullRequestBodyLines.Add("")
    $pullRequestBodyLines.Add("## $verificationIcon Verification")
    $pullRequestBodyLines.Add("")
    $pullRequestBodyLines.Add('- [x] `git diff --check`')
    $pullRequestBodyLines.Add('- [ ] `task check`')
    $pullRequestBodyLines.Add("- [ ] Manual installer smoke test when install, update or uninstall behavior changed")
    $pullRequestBodyLines.Add("")
    $pullRequestBodyLines.Add("## $notesIcon Notes")
    $pullRequestBodyLines.Add("")
    $pullRequestBodyLines.Add("- [x] Preserved UTF-8 encoding for NSIS files.")
    $pullRequestBodyLines.Add('- [x] Did not commit downloaded archives, cache folders, payload logs, `.env`, `.build`, `dist`, `node_modules`, or native `bin`/`obj` output.')
    $pullRequestBodyLines.Add("- [x] Updated documentation, release notes, changelog placeholders or workflow docs when needed.")
    $pullRequestBodyLines.Add("- [x] Commits are signed off for DCO.")

    $pullRequestBody = $pullRequestBodyLines -join "`n"

    & gh pr create `
        --base $BaseBranch `
        --head $branchName `
        --title $commitSubject `
        --body $pullRequestBody
    if ($LASTEXITCODE -ne 0) {
        throw "gh pr create failed."
    }
}
