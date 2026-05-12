#requires -version 5.1

<#
.SYNOPSIS
  Installs Visual Studio Build Tools (C++ toolchain + Windows SDK)

.DESCRIPTION
  Downloads the installer and installs:
  - MSVC (x86/x64)
  - Windows SDK (Windows 11)

  Mode: quiet
#>

# --- configuration ---
$ErrorActionPreference = "Stop"

$DownloadUrl = "https://aka.ms/vs/17/release/vs_BuildTools.exe"
$InstallerPath = Join-Path $env:TEMP "vs_BuildTools.exe"

$Arguments = @(
    "--quiet",
    "--wait",
    "--norestart",
    "--nocache",
    "--add", "Microsoft.VisualStudio.Workload.VCTools",
    "--add", "Microsoft.VisualStudio.Component.VC.Tools.x86.x64",
    "--add", "Microsoft.VisualStudio.Component.Windows11SDK.26100"
)

# --- function: admin check ---
function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

# --- start ---
Write-Host "=== Visual Studio Build Tools Installer ===" -ForegroundColor Cyan

if (-not (Test-IsAdmin)) {
    Write-Host "[ERROR] Run this script as administrator." -ForegroundColor Red
    exit 1
}

# --- download ---
Write-Host "[INFO] Downloading installer..." -ForegroundColor Yellow
Write-Host "URL: $DownloadUrl"

Invoke-WebRequest -Uri $DownloadUrl -OutFile $InstallerPath

if (-not (Test-Path $InstallerPath)) {
    Write-Host "[ERROR] Failed to download the installer." -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Downloaded to: $InstallerPath" -ForegroundColor Green

# --- signature verification ---
Write-Host "[INFO] Verifying installer digital signature..." -ForegroundColor Yellow
$signature = Get-AuthenticodeSignature -FilePath $InstallerPath
if ($signature.Status -ne "Valid") {
    Remove-Item $InstallerPath -Force -ErrorAction SilentlyContinue
    Write-Host "[ERROR] Installer digital signature is invalid. Status: $($signature.Status)" -ForegroundColor Red
    exit 1
}
if ($signature.SignerCertificate.Subject -notmatch "Microsoft") {
    Remove-Item $InstallerPath -Force -ErrorAction SilentlyContinue
    Write-Host "[ERROR] Installer is not signed by Microsoft. Subject: $($signature.SignerCertificate.Subject)" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Signature verified: $($signature.SignerCertificate.Subject)" -ForegroundColor Green

# --- installation ---
Write-Host "[INFO] Running installer..." -ForegroundColor Yellow

$process = Start-Process -FilePath $InstallerPath `
    -ArgumentList $Arguments `
    -NoNewWindow `
    -Wait `
    -PassThru

# --- result ---
if ($process.ExitCode -eq 0) {
    Write-Host "[OK] Installation completed successfully." -ForegroundColor Green
}
else {
    Write-Host "[ERROR] Installation failed. ExitCode=$($process.ExitCode)" -ForegroundColor Red
    exit $process.ExitCode
}

# --- cleanup ---
Write-Host "[INFO] Removing installer..." -ForegroundColor Yellow
Remove-Item $InstallerPath -Force -ErrorAction SilentlyContinue

Write-Host "[DONE] Done." -ForegroundColor Cyan
