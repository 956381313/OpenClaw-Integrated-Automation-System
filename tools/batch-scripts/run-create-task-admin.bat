@echo off
echo ================================================
echo     Create Task as Administrator
echo ================================================
echo.
echo This will run the task creation script as Administrator.
echo.
echo The script will:
echo 1. Check Administrator privileges
echo 2. Create scheduled task automatically
echo 3. Show success/failure message
echo.
echo Press any key to start...
pause >nul

echo.
echo Starting Administrator PowerShell...
echo.

REM Run PowerShell as Administrator
PowerShell -Command "Start-Process PowerShell -Verb RunAs -ArgumentList '-ExecutionPolicy Bypass -File \"%~dp0create-task-admin.ps1\"'"

echo.
echo Script started in Administrator PowerShell.
echo Please check the new window for results.
echo.
echo Press any key to exit...
pause >nul