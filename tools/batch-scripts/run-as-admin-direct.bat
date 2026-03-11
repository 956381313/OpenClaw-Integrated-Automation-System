@echo off
echo ================================================
echo     Run as Administrator - Direct Setup
echo ================================================
echo.
echo This will run the direct setup script as Administrator.
echo.
echo Steps:
echo 1. UAC prompt will appear - click Yes
echo 2. Script will create scheduled task automatically
echo 3. No manual interaction required in PowerShell
echo.
echo Press Ctrl+C to cancel, or any key to continue...
pause >nul

echo.
echo Starting setup...
echo.

REM Run PowerShell as Administrator with the direct setup script
PowerShell -Command "Start-Process PowerShell -Verb RunAs -ArgumentList '-ExecutionPolicy Bypass -File \"%~dp0create-task-direct.ps1\"'"

echo.
echo Setup script started in Administrator PowerShell.
echo Please complete the setup in the new window.
echo.
echo Press any key to exit...
pause >nul