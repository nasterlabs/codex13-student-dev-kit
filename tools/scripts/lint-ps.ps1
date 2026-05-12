$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
    throw "PSScriptAnalyzer module not found. Run 'task setup' to install it."
}

$Root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..")).Path
$SettingsPath = Join-Path $Root "PSScriptAnalyzerSettings.psd1"

$scanDirs = @(
    Join-Path $Root "tools"
    Join-Path $Root "apps\setup\scripts"
    Join-Path $Root "apps\setup\src\installer-scripts"
)

$allResults = @()
foreach ($dir in $scanDirs) {
    if (Test-Path -LiteralPath $dir -PathType Container) {
        $scripts = Get-ChildItem -LiteralPath $dir -Filter "*.ps1" -Recurse -File
        foreach ($script in $scripts) {
            $text = Get-Content -LiteralPath $script.FullName -Raw
            if ($text -match '[^\x00-\x7F]') {
                throw "PowerShell scripts must stay ASCII-only to avoid BOM and encoding drift. Non-ASCII text found in $($script.FullName)."
            }

            $results = Invoke-ScriptAnalyzer -Path $script.FullName -Settings $SettingsPath
            $allResults += $results
        }
    }
}

if ($allResults.Count -gt 0) {
    $allResults | Format-Table -Property ScriptName, Line, RuleName, Message -AutoSize
    throw "PSScriptAnalyzer found $($allResults.Count) issue(s)."
}

Write-Host "PSScriptAnalyzer: no issues found."
