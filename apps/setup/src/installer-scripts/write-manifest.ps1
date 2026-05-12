param(
    [Parameter(Mandatory = $true)]
    [string] $InstallRoot,

    [Parameter(Mandatory = $true)]
    [string] $Profile,

    [Parameter(Mandatory = $true)]
    [string] $Preset,

    [Parameter(Mandatory = $true)]
    [string] $Mode,

    [Parameter(Mandatory = $true)]
    [string] $LogPath,

    [string] $VsCodeProfile = "",

    [object] $VsCodePortableData = $true,

    [string] $DesktopShortcuts = "",

    [string] $ManifestFileName = "codex13-sdk.manifest.json"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Test-LeafRelative {
    param(
        [Parameter(Mandatory = $true)]
        [string] $RelativePath
    )

    return Test-Path -LiteralPath (Join-Path $InstallRoot $RelativePath) -PathType Leaf
}

function New-Component {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Id,

        [Parameter(Mandatory = $true)]
        [string] $Name,

        [Parameter(Mandatory = $true)]
        [string] $Version,

        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter(Mandatory = $true)]
        [string] $Strategy
    )

    return [ordered]@{
        id       = $Id
        name     = $Name
        version  = $Version
        path     = $Path
        status   = "installed"
        strategy = $Strategy
    }
}

function ConvertTo-BooleanValue {
    param(
        [Parameter(Mandatory = $true)]
        [object] $Value
    )

    if ($Value -is [bool]) {
        return $Value
    }

    $text = ([string] $Value).Trim()
    if ($text -match "^(?i:true|1|yes|y)$") {
        return $true
    }

    if ($text -match "^(?i:false|0|no|n)$") {
        return $false
    }

    throw "Invalid boolean value: $Value"
}

$components = @()
$vsCodePortableDataValue = ConvertTo-BooleanValue -Value $VsCodePortableData

if (Test-LeafRelative "tools\VSCode\Code.exe") {
    $components += New-Component `
        -Id "vscode" `
        -Name "Visual Studio Code" `
        -Version "1.118.1" `
        -Path "tools\VSCode" `
        -Strategy "refresh-preserve-data"
}

if (Test-LeafRelative "tools\Git\git-bash.exe") {
    $components += New-Component `
        -Id "git" `
        -Name "Git for Windows" `
        -Version "2.54.0" `
        -Path "tools\Git" `
        -Strategy "keep-verify"
}

if (Test-LeafRelative "tools\OpenSSH-Win64\ssh.exe") {
    $components += New-Component `
        -Id "openssh" `
        -Name "OpenSSH for Windows" `
        -Version "10.0.0.0p2-Preview" `
        -Path "tools\OpenSSH-Win64" `
        -Strategy "keep-verify"
}

if (Test-LeafRelative "tools\xampp\xampp-control.exe") {
    $components += New-Component `
        -Id "xampp" `
        -Name "XAMPP" `
        -Version "8.2.12" `
        -Path "tools\xampp" `
        -Strategy "keep-or-refresh-preserve-data"
}

$desktop = @()
if (-not [string]::IsNullOrWhiteSpace($DesktopShortcuts)) {
    $desktop = @($DesktopShortcuts -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ })
}

$manifest = [ordered]@{
    schemaVersion = 1
    manifestName  = $ManifestFileName
    product       = "Codex 13 Student Dev Kit"
    installedAt   = (Get-Date).ToString("o")
    installRoot   = $InstallRoot
    mode          = $Mode
    profile       = $Profile
    preset        = $Preset
    components    = $components
    shortcuts     = [ordered]@{
        startMenu = $true
        desktop   = $desktop
    }
    vscode        = [ordered]@{
        profile                    = $VsCodeProfile
        portableData               = $vsCodePortableDataValue
        launcherAddsSdkToolsToPath = $true
    }
    logPath       = $LogPath
}

if (-not (Test-Path -LiteralPath $InstallRoot -PathType Container)) {
    New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null
}

function Format-Json {
    param([string] $Compact)
    $sb = [System.Text.StringBuilder]::new($Compact.Length * 2)
    $depth = 0
    $inStr = $false
    $esc = $false
    foreach ($ch in $Compact.ToCharArray()) {
        if ($esc) { [void]$sb.Append($ch); $esc = $false; continue }
        if ($ch -eq '\' -and $inStr) { [void]$sb.Append($ch); $esc = $true; continue }
        if ($ch -eq '"') { $inStr = -not $inStr; [void]$sb.Append($ch); continue }
        if ($inStr) { [void]$sb.Append($ch); continue }
        switch ($ch) {
            '{' { [void]$sb.Append($ch); [void]$sb.Append("`n"); $depth++; [void]$sb.Append('  ' * $depth) }
            '}' { [void]$sb.Append("`n"); $depth--; [void]$sb.Append('  ' * $depth); [void]$sb.Append($ch) }
            '[' { [void]$sb.Append($ch); [void]$sb.Append("`n"); $depth++; [void]$sb.Append('  ' * $depth) }
            ']' { [void]$sb.Append("`n"); $depth--; [void]$sb.Append('  ' * $depth); [void]$sb.Append($ch) }
            ',' { [void]$sb.Append($ch); [void]$sb.Append("`n"); [void]$sb.Append('  ' * $depth) }
            ':' { [void]$sb.Append(': ') }
            default { if ($ch -notin ' ', "`t", "`r", "`n") { [void]$sb.Append($ch) } }
        }
    }
    return $sb.ToString()
}

$outPath = Join-Path $InstallRoot $ManifestFileName
$json = Format-Json ($manifest | ConvertTo-Json -Depth 8 -Compress)
[System.IO.File]::WriteAllText($outPath, $json, (New-Object System.Text.UTF8Encoding($false)))

Write-Host "Manifest written: $outPath"
