@echo off
chcp 65001 >nul
echo ================================================
echo     OpenClaw Scheduled Task Setup Script
echo ================================================
echo.
echo Preparing to run scheduled task setup script as Administrator...
echo.
echo Script: setup-scheduled-task-easy.ps1
echo Target: Create weekly automatic duplicate file cleanup task
echo Privileges: Administrator privileges required
echo.
echo Please follow these steps:
echo 1. When User Account Control (UAC) prompt appears, click "Yes"
echo 2. Follow the prompts in the PowerShell window
echo 3. Verify task status after setup completes
echo.
echo Press any key to start execution, or Ctrl+C to cancel...
pause >nul

echo.
echo Starting Administrator PowerShell...
echo.

REM Get current directory
set "WORKDIR=%~dp0"
set "SCRIPT=%WORKDIR%setup-scheduled-task-easy.ps1"

REM Check if script exists
if not exist "%SCRIPT%" (
    echo ERROR: Setup script not found
    echo Please ensure you are in the correct working directory
    echo Working directory: %WORKDIR%
    pause
    exit /b 1
)

REM Run PowerShell as Administrator
PowerShell -Command "Start-Process PowerShell -Verb RunAs -ArgumentList '-ExecutionPolicy Bypass -NoExit -Command \"cd ''%WORKDIR%''; .\setup-scheduled-task-easy.ps1\"'"

echo.
echo ================================================
echo     Administrator PowerShell Started
echo ================================================
echo.
echo In the newly opened PowerShell window:
echo 1. Follow the interactive prompts to complete setup
echo 2. Close the window after setup completes
echo 3. Return to this window to continue verification
echo.
echo Press any key to continue verification...
pause >nul

echo.
echo ================================================
echo     Verify Scheduled Task Setup
echo ================================================
echo.
echo Verifying task setup...
echo.

PowerShell -ExecutionPolicy Bypass -Command "& {
    Write-Host '=== Task Verification ===' -ForegroundColor Cyan
    Write-Host 'Time: ' (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') -ForegroundColor Gray
    
    $TaskName = 'OpenClaw-Duplicate-Cleanup'
    
    try {
        $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop
        
        Write-Host '✓ Task found: ' $task.TaskName -ForegroundColor Green
        Write-Host '  State: ' $task.State -ForegroundColor Gray
        Write-Host '  Enabled: ' $task.Enabled -ForegroundColor Gray
        
        $taskInfo = Get-ScheduledTaskInfo -TaskName $TaskName
        Write-Host '  Last Run: ' $taskInfo.LastRunTime -ForegroundColor Gray
        Write-Host '  Next Run: ' $taskInfo.NextRunTime -ForegroundColor Gray
        
        Write-Host '' 
        Write-Host '✓ Task is properly configured and ready' -ForegroundColor Green
        
    } catch {
        Write-Host '✗ Task not found or error: ' $_ -ForegroundColor Red
        Write-Host ''
        Write-Host 'Recommendations:' -ForegroundColor Yellow
        Write-Host '  1. Check if setup completed' -ForegroundColor Gray
        Write-Host '  2. Re-run setup script' -ForegroundColor Gray
        Write-Host '  3. Check setup logs: duplicate-logs\scheduled\' -ForegroundColor Gray
    }
    
    Write-Host ''
    Write-Host 'Verification completed' -ForegroundColor Gray
}"

echo.
echo ================================================
echo     Setup Complete
echo ================================================
echo.
echo Next steps:
echo 1. View detailed setup guide: SCHEDULED-TASK-SETUP-GUIDE.md
echo 2. View completion report: SCHEDULED-TASK-COMPLETION-REPORT.md
echo 3. Verify task: .\verify-task-easy.ps1
echo 4. Test immediate run: Start-ScheduledTask -TaskName "OpenClaw-Duplicate-Cleanup"
echo.
echo Task will run automatically every Sunday at 03:00 to clean duplicate files.
echo.
echo Press any key to exit...
pause >nul