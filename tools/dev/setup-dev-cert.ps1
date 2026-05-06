param(
    [string]$CertName = "Codex13 Dev Kit",
    [string]$FileToSign = ""
)

Write-Host "=== DEV CODE SIGNING SETUP ===" -ForegroundColor Cyan

# --- 1. Generate cert ---
Write-Host "[1/4] Generating self-signed certificate..."
$cert = New-SelfSignedCertificate `
    -Type CodeSigningCert `
    -Subject "CN=$CertName" `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -KeyExportPolicy NonExportable `
    -KeyLength 2048 `
    -HashAlgorithm SHA256

if (-not $cert) {
    Write-Error "Failed to create the certificate"
    exit 1
}

Write-Host "OK: Cert thumbprint = $($cert.Thumbprint)"

# --- 2. Export public certificate ---
Write-Host "[2/4] Exporting public certificate for local trust..."

$certPath = Join-Path ([System.IO.Path]::GetTempPath()) "codex13-dev-$($cert.Thumbprint).cer"

Export-Certificate `
    -Cert $cert `
    -FilePath $certPath `
    -Type CERT | Out-Null

if (-not (Test-Path $certPath)) {
    Write-Error "Failed to write the temporary CER file"
    exit 1
}

Write-Host "OK: Public certificate saved temporarily at $certPath"

# --- 3. Trust cert (IMPORTANT) ---
Write-Host "[3/4] Adding to TrustedPublisher + Root..."

try {
    Import-Certificate `
        -FilePath $certPath `
        -CertStoreLocation Cert:\CurrentUser\TrustedPublisher | Out-Null

    Import-Certificate `
        -FilePath $certPath `
        -CertStoreLocation Cert:\CurrentUser\Root | Out-Null
}
finally {
    Remove-Item -LiteralPath $certPath -Force -ErrorAction SilentlyContinue
}

Write-Host "OK: Cert trusted locally"

Write-Host ""
Write-Host "The certificate is in the CurrentUser\My store with this thumbprint:" -ForegroundColor Cyan
Write-Host $cert.Thumbprint
Write-Host ""
Write-Host "Add this to .env.dev to sign local builds without a password:" -ForegroundColor Cyan
Write-Host "SIGNING_ENABLED=1"
Write-Host "SIGN_CERT_THUMBPRINT=$($cert.Thumbprint)"
Write-Host "SIGN_TIMESTAMP_URL=http://timestamp.digicert.com"
Write-Host ""
Write-Host "You do not need a PFX or password in .env because the certificate is in the Windows store." -ForegroundColor Green
Write-Host "To build without signing, set SIGNING_ENABLED=0 or remove the signing variables."

# --- 4. Optional signing ---
if ($FileToSign -ne "") {
    Write-Host "[4/4] Signing file: $FileToSign"

    $signtool = Get-Command signtool.exe -ErrorAction SilentlyContinue

    if (-not $signtool) {
        Write-Warning "signtool.exe was not found in PATH"
        Write-Warning "Install the Windows SDK or provide the full path"
        exit 1
    }

    & $signtool.Source sign `
        /sha1 $cert.Thumbprint `
        /fd SHA256 `
        /tr http://timestamp.digicert.com `
        /td SHA256 `
        "$FileToSign"

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Signing failed"
        exit 1
    }

    Write-Host "OK: File signed"
}

Write-Host "=== DONE ===" -ForegroundColor Green
