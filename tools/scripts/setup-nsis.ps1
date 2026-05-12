#requires -version 5.1

param(
    [string] $Version = "3.12",
    [string] $InstallRoot = ".build\nsis"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$archiveName = "nsis-$Version.zip"
$downloadUrl = "https://master.dl.sourceforge.net/project/nsis/NSIS%203/$Version/${archiveName}?viasf=1"
$expectedArchiveSha256 = "56581F90DB321581C5381193D796FFFCF2D24B2F8FED2160A6C6A3BAA67F2C4F"
$expectedMakensisSha256 = "B043E554AFEFBFC56315669D0B4779793AEAE67F0F2A7A790E2EA91F05298EFF"

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..")).Path
$installRootPath = if ([System.IO.Path]::IsPathRooted($InstallRoot)) {
    $InstallRoot
}
else {
    Join-Path $repoRoot $InstallRoot
}
$installRootPath = [System.IO.Path]::GetFullPath($installRootPath)
$nsisHome = Join-Path $installRootPath "nsis-$Version"
$makensisPath = Join-Path $nsisHome "makensis.exe"
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) "codex13-nsis-$([Guid]::NewGuid().ToString('N'))"
$archivePath = Join-Path $tempRoot $archiveName

function Publish-NsisPath {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    Write-Host "NSIS_PATH=$Path"

    if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_ENV)) {
        "NSIS_PATH=$Path" | Add-Content -LiteralPath $env:GITHUB_ENV -Encoding ASCII
    }
}

try {
    New-Item -ItemType Directory -Force -Path $installRootPath | Out-Null

    if (Test-Path -LiteralPath $makensisPath -PathType Leaf) {
        $cachedMakensisSha256 = (Get-FileHash -LiteralPath $makensisPath -Algorithm SHA256).Hash.ToUpperInvariant()
        if ($cachedMakensisSha256 -eq $expectedMakensisSha256) {
            Write-Host "Using cached NSIS $Version at $nsisHome"
            Write-Host "makensis.exe verified: $cachedMakensisSha256"
            $versionOutput = & $makensisPath /VERSION
            Write-Host "NSIS installed: $versionOutput"
            Publish-NsisPath -Path $makensisPath
            return
        }

        Write-Warning "Cached makensis.exe SHA256 mismatch. Expected: $expectedMakensisSha256 Actual: $cachedMakensisSha256. Reinstalling NSIS $Version."
    }

    New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null

    Write-Host "Downloading NSIS $Version from $downloadUrl"
    Invoke-WebRequest -Uri $downloadUrl -OutFile $archivePath

    $archiveSha256 = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToUpperInvariant()
    if ($archiveSha256 -ne $expectedArchiveSha256) {
        throw "NSIS archive SHA256 mismatch. Expected: $expectedArchiveSha256 Actual: $archiveSha256"
    }
    Write-Host "NSIS archive verified: $archiveSha256"

    if (Test-Path -LiteralPath $nsisHome) {
        Remove-Item -LiteralPath $nsisHome -Recurse -Force
    }

    Expand-Archive -LiteralPath $archivePath -DestinationPath $installRootPath -Force

    if (-not (Test-Path -LiteralPath $makensisPath -PathType Leaf)) {
        throw "makensis.exe was not found after NSIS extraction: $makensisPath"
    }

    $makensisSha256 = (Get-FileHash -LiteralPath $makensisPath -Algorithm SHA256).Hash.ToUpperInvariant()
    if ($makensisSha256 -ne $expectedMakensisSha256) {
        throw "makensis.exe SHA256 mismatch. Expected: $expectedMakensisSha256 Actual: $makensisSha256"
    }
    Write-Host "makensis.exe verified: $makensisSha256"

    $versionOutput = & $makensisPath /VERSION
    Write-Host "NSIS installed: $versionOutput"
    Publish-NsisPath -Path $makensisPath
}
finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
