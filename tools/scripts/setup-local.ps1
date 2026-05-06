$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$Root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..")).Path
$EnvExample = Join-Path $Root ".env.example"
$EnvFile = Join-Path $Root ".env"

if (-not (Test-Path -LiteralPath $EnvFile)) {
    Copy-Item -LiteralPath $EnvExample -Destination $EnvFile
    Write-Host ".env created from .env.example - edit it to configure signing."
} else {
    Write-Host ".env already exists."
}

if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
    Write-Host "Installing PSScriptAnalyzer..."
    Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force -AllowClobber
    Write-Host "PSScriptAnalyzer installed."
} else {
    Write-Host "PSScriptAnalyzer already installed."
}

Write-Host "Local setup complete. See docs/development.md for next steps."
