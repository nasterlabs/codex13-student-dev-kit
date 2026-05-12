param(
    [string] $From = "main",
    [string] $To = "HEAD",
    [switch] $RequireVerifiedSignatures
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$range = "$From..$To"
$Root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..")).Path

function Resolve-GitCommand {
    $isWindowsVariable = Get-Variable -Name IsWindows -ErrorAction SilentlyContinue
    $isWindowsPlatform = if ($isWindowsVariable) { [bool] $isWindowsVariable.Value } else { $true }

    if ($isWindowsPlatform) {
        $command = Get-Command "git.exe" -ErrorAction SilentlyContinue
        if ($command) {
            return $command.Source
        }
    }

    $command = Get-Command "git" -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $command = Get-Command "git.exe" -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $toolsRoot = Join-Path (Split-Path -Parent $Root) "tools"
    foreach ($candidate in @(
            (Join-Path $toolsRoot "git\cmd\git.exe"),
            (Join-Path $toolsRoot "git\bin\git.exe")
        )) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    throw "git.exe was not found. Add Git to PATH or install it under the sibling tools directory."
}

$GitCommand = Resolve-GitCommand

function Get-GitHubCommitVerification {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Commit
    )

    if ([string]::IsNullOrWhiteSpace($env:GITHUB_REPOSITORY) -or [string]::IsNullOrWhiteSpace($env:GITHUB_TOKEN)) {
        return $null
    }

    $uri = "https://api.github.com/repos/$env:GITHUB_REPOSITORY/commits/$Commit"
    $headers = @{
        Accept                 = "application/vnd.github+json"
        Authorization          = "Bearer $env:GITHUB_TOKEN"
        "X-GitHub-Api-Version" = "2022-11-28"
    }

    try {
        return (Invoke-RestMethod -Method Get -Uri $uri -Headers $headers).commit.verification
    }
    catch {
        Write-Warning "GitHub signature verification lookup failed for $Commit`: $($_.Exception.Message)"
        return $null
    }
}

function Test-CommitSignature {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Commit
    )

    $verification = Get-GitHubCommitVerification -Commit $Commit
    if ($null -ne $verification) {
        if ($verification.verified -eq $true) {
            return $true
        }

        Write-Error "Unverified commit signature: $Commit ($($verification.reason))" -ErrorAction Continue
        return $false
    }

    $global:LASTEXITCODE = 0
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = & $GitCommand -C $Root verify-commit $Commit 2>&1
        $gitExitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    if ($gitExitCode -eq 0) {
        return $true
    }

    $details = ($output | Out-String).Trim()
    if ([string]::IsNullOrWhiteSpace($details)) {
        $details = "git verify-commit failed"
    }

    Write-Error "Unverified commit signature: $Commit ($details)" -ErrorAction Continue
    return $false
}

function Get-CommitAuthor {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Commit
    )

    $global:LASTEXITCODE = 0
    $author = & $GitCommand -C $Root log -1 --format="%an%x1f%ae" $Commit
    if ($LASTEXITCODE -ne 0) {
        throw "git log failed while reading author for commit $Commit"
    }

    $parts = ([string] $author) -split ([char] 0x1f), 2
    if ($parts.Count -ne 2 -or [string]::IsNullOrWhiteSpace($parts[1])) {
        throw "Cannot read commit author identity for $Commit"
    }

    return [pscustomobject]@{
        Name  = $parts[0].Trim()
        Email = $parts[1].Trim()
    }
}

function Get-SignedOffByTrailers {
    param(
        [string[]] $MessageLines
    )

    $trailers = @()
    foreach ($line in $MessageLines) {
        $match = [regex]::Match($line, "^Signed-off-by:\s+(.+?)\s+<([^>]+)>\s*$", "IgnoreCase")
        if ($match.Success) {
            $trailers += [pscustomobject]@{
                Name  = $match.Groups[1].Value.Trim()
                Email = $match.Groups[2].Value.Trim()
            }
        }
    }

    return $trailers
}

function Test-IsBotAuthor {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject] $Author
    )

    return $Author.Name -match "\[bot\]$" -or $Author.Email -match "(?i)(\[bot\]|bot@|support@github\.com|noreply\.github\.com)$"
}

function Test-IsTrustedUnsignedAutomationAuthor {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject] $Author
    )

    return $Author.Name -eq "nasterlabs-release-bot[bot]" -and
        $Author.Email -eq "nasterlabs-release-bot[bot]@users.noreply.github.com"
}

function Test-AuthorSignOff {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Commit,

        [string[]] $MessageLines
    )

    $author = Get-CommitAuthor -Commit $Commit
    if (Test-IsBotAuthor -Author $author) {
        return $true
    }

    $trailers = @(Get-SignedOffByTrailers -MessageLines $MessageLines)
    $authorEmail = $author.Email.ToLowerInvariant()
    foreach ($trailer in $trailers) {
        if ($trailer.Email.ToLowerInvariant() -eq $authorEmail) {
            return $true
        }
    }

    $subject = & $GitCommand -C $Root log -1 --format=%s $Commit
    $trailerList = if ($trailers.Count -gt 0) {
        ($trailers | ForEach-Object { "$($_.Name) <$($_.Email)>" }) -join ", "
    }
    else {
        "(none)"
    }

    Write-Error "DCO Signed-off-by trailer does not match commit author: $commit $subject. Author: $($author.Name) <$($author.Email)>. Signed-off-by: $trailerList" -ErrorAction Continue
    return $false
}

$global:LASTEXITCODE = 0
$commits = @(& $GitCommand -C $Root rev-list --no-merges $range)
if ($LASTEXITCODE -ne 0) {
    throw "git rev-list failed for range $range"
}

$failed = $false
foreach ($commit in $commits) {
    $global:LASTEXITCODE = 0
    $body = & $GitCommand -C $Root log -1 --format=%B $commit
    if ($LASTEXITCODE -ne 0) {
        throw "git log failed for commit $commit"
    }

    if (($body -join "`n") -notmatch "(?mi)^Signed-off-by:\s+.+\s+<[^>]+>\s*$") {
        $global:LASTEXITCODE = 0
        $subject = & $GitCommand -C $Root log -1 --format=%s $commit
        Write-Error "Missing DCO Signed-off-by trailer: $commit $subject" -ErrorAction Continue
        $failed = $true
    }
    elseif (-not (Test-AuthorSignOff -Commit $commit -MessageLines $body)) {
        $failed = $true
    }

    $author = Get-CommitAuthor -Commit $commit
    if ($RequireVerifiedSignatures -and
        -not (Test-IsTrustedUnsignedAutomationAuthor -Author $author) -and
        -not (Test-CommitSignature -Commit $commit)) {
        $failed = $true
    }
}

if ($failed) {
    if ($RequireVerifiedSignatures) {
        throw "DCO and signature checks failed."
    }

    throw "DCO check failed."
}

if ($RequireVerifiedSignatures) {
    Write-Host "DCO and signature checks passed for $range."
}
else {
    Write-Host "DCO check passed for $range."
}
