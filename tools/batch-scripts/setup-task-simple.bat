@echo off
echo ================================================
echo     OpenClaw Task Setup
echo ================================================
echo.
echo This will run the setup script as Administrator.
echo.
echo Steps:
echo 1. UAC prompt will appear - click Yes
echo 2. Follow prompts in PowerShell window
echo 3. Setup will create weekly cleanup task
echo.
echo Press Ctrl+C to cancel, or any key to continue...
pause >nul

echo.
echo Starting setup...
echo.

PowerShell -Command "Start-Process PowerShell -Verb RunAs -ArgumentList '-ExecutionPolicy Bypass -File \"%~dp0setup-scheduled-task-easy.ps1\"'"

echo.
echo Setup script started in Administrator PowerShell.
echo Please complete the setup in the new window.
echo.
echo Press any key to exit...
pause >nul