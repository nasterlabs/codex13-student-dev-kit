@echo off

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [INFO] Podnoszenie uprawnien...
    powershell -Command "Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -File \"%~dp0install-vs-buildtools.ps1\"' -Verb RunAs"
    exit /b
)

powershell -ExecutionPolicy Bypass -File "%~dp0install-vs-buildtools.ps1"