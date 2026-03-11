@echo off
echo ========================================
echo    OpenClaw Admin Update Tool
echo ========================================
echo.

:: Check if running as admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: Not running as Administrator
    echo.
    echo Please right-click on this file and select:
    echo "Run as administrator"
    echo.
    echo Or follow these steps:
    echo 1. Search for "PowerShell" in Start Menu
    echo 2. Right-click -> "Run as administrator"
    echo 3. Run this command:
    echo    cd "C:\Users\luchaochao\.openclaw\workspace"
    echo    .\update-automation.ps1
    echo.
    pause
    exit /b 1
)

echo Running as Administrator - Good!
echo.

echo Starting OpenClaw automation update...
echo.

:: Run the PowerShell script
powershell -ExecutionPolicy Bypass -File "update-automation.ps1"

echo.
echo ========================================
echo    Update Complete!
echo ========================================
echo.
echo Automation tasks have been updated.
echo.
echo To verify, run:
echo   .\check-automation.ps1
echo   .\monitor-automation-english.ps1
echo.
pause