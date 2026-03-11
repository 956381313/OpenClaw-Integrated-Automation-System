@echo off
echo ========================================
echo    OpenClaw Automation Update
echo ========================================
echo.
echo This script will update OpenClaw automation tasks
echo to use the new English version scripts.
echo.
echo IMPORTANT: Need Administrator rights
echo.
echo Please follow these steps:
echo.
echo 1. Right-click on PowerShell in Start Menu
echo 2. Select "Run as administrator"
echo 3. In the PowerShell window, navigate to:
echo    cd "C:\Users\luchaochao\.openclaw\workspace"
echo 4. Run the update script:
echo    .\update-automation.ps1
echo.
echo Or use this PowerShell command (as Admin):
echo.
echo powershell -ExecutionPolicy Bypass -Command "Set-Location 'C:\Users\luchaochao\.openclaw\workspace'; .\update-automation.ps1"
echo.
echo ========================================
echo    Script Details
echo ========================================
echo.
echo Script to run: update-automation.ps1
echo.
echo This script will:
echo - Update hourly backup task (using backup-english.ps1)
echo - Update daily security check task (using security-check-english.ps1)
echo - Update weekly audit task
echo - Create repository organization task (using organize-english.ps1)
echo.
echo Total tasks to create/update: 4
echo.
echo ========================================
echo    Current Automation Status
echo ========================================
echo.
echo Checking current tasks...
powershell -ExecutionPolicy Bypass -Command "Get-ScheduledTask | Where-Object {`$_.TaskName -like 'OpenClaw*'} | Format-Table TaskName, State -AutoSize"
echo.
echo ========================================
echo    Ready to Update?
echo ========================================
echo.
echo Press any key to open PowerShell instructions...
pause > nul

echo.
echo Opening PowerShell instructions...
echo.
echo Copy and paste these commands in PowerShell (as Admin):
echo.
echo -----------------------------------------------------
echo cd "C:\Users\luchaochao\.openclaw\workspace"
echo .\update-automation.ps1
echo -----------------------------------------------------
echo.
echo Or run this single command:
echo.
echo -----------------------------------------------------
echo powershell -ExecutionPolicy Bypass -Command "Set-Location 'C:\Users\luchaochao\.openclaw\workspace'; .\update-automation.ps1"
echo -----------------------------------------------------
echo.
pause