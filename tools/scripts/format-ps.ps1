$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
    throw "PSScriptAnalyzer module not found. Run 'task setup' to install it."
}

$Root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..")).Path

$scanDirs = @(
    Join-Path $Root "tools"
    Join-Path $Root "apps\setup\scripts"
    Join-Path $Root "apps\setup\src\installer-scripts"
)

$formattedCount = 0
foreach ($dir in $scanDirs) {
    if (Test-Path -LiteralPath $dir -PathType Container) {
        $scripts = Get-ChildItem -LiteralPath $dir -Filter "*.ps1" -Recurse -File
        foreach ($script in $scripts) {
            $original = Get-Content -LiteralPath $script.FullName -Raw
            $formatted = Invoke-Formatter -ScriptDefinition $original
            if ($formatted -ne $original) {
                Set-Content -LiteralPath $script.FullName -Value $formatted -Encoding UTF8 -NoNewline
                Write-Host "Formatted: $($script.Name)"
                $formattedCount++
            }
        }
    }
}

if ($formattedCount -gt 0) {
    Write-Host "Formatted $formattedCount file(s)."
} else {
    Write-Host "All PowerShell files are already consistently formatted."
}
