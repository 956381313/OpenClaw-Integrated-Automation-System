# Direct Task Creation Script
# This script creates the scheduled task directly

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "    Creating Scheduled Task Directly" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Check if running as Administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

$isAdmin = Test-Administrator
if (-not $isAdmin) {
    Write-Host "ERROR: This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please run this script as Administrator:" -ForegroundColor Yellow
    Write-Host "1. Close this window" -ForegroundColor Gray
    Write-Host "2. Right-click on PowerShell" -ForegroundColor Gray
    Write-Host "3. Select 'Run as Administrator'" -ForegroundColor Gray
    Write-Host "4. Navigate to workspace: cd C:\Users\luchaochao\.openclaw\workspace" -ForegroundColor Gray
    Write-Host "5. Run: .\create-task-direct.ps1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Or use the batch file: .\setup-task-fixed.bat" -ForegroundColor Gray
    pause
    exit 1
}

Write-Host "鉁?Running as Administrator" -ForegroundColor Green
Write-Host ""

# Task configuration
$TaskName = "OpenClaw-Duplicate-Cleanup"
$WorkingDir = "C:\Users\luchaochao\.openclaw\workspace"
$ScriptPath = "$WorkingDir\clean-duplicates-optimized.ps1"

# Check if cleanup script exists
if (-not (Test-Path $ScriptPath)) {
    Write-Host "ERROR: Cleanup script not found: $ScriptPath" -ForegroundColor Red
    Write-Host "Please ensure the system is properly installed." -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "鉁?Cleanup script found: $ScriptPath" -ForegroundColor Green
Write-Host ""

# Check if task already exists
$existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Write-Host "鈿狅笍 Task already exists: $($existingTask.TaskName)" -ForegroundColor Yellow
    Write-Host "   State: $($existingTask.State)" -ForegroundColor Gray
    Write-Host "   Enabled: $($existingTask.Enabled)" -ForegroundColor Gray
    
    $choice = Read-Host "Do you want to recreate it? (Y/N)"
    if ($choice -ne "Y" -and $choice -ne "y") {
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        pause
        exit 0
    }
    
    # Remove existing task
    try {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-Host "鉁?Existing task removed" -ForegroundColor Green
    } catch {
        Write-Host "鉁?Failed to remove existing task: $_" -ForegroundColor Red
        pause
        exit 1
    }
}

Write-Host "Creating scheduled task..." -ForegroundColor Yellow

try {
    # Create task action
    Write-Host "  Creating task action..." -ForegroundColor Gray
    $Action = New-ScheduledTaskAction `
        -Execute "powershell.exe" `
        -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`" -Strategy KeepNewest" `
        -WorkingDirectory $WorkingDir
    
    # Create trigger (every Sunday at 03:00)
    Write-Host "  Creating trigger (every Sunday at 03:00)..." -ForegroundColor Gray
    $Trigger = New-ScheduledTaskTrigger `
        -Weekly `
        -DaysOfWeek Sunday `
        -At "03:00"
    
    # Create principal (run as SYSTEM with highest privileges)
    Write-Host "  Setting up security (run as SYSTEM)..." -ForegroundColor Gray
    $Principal = New-ScheduledTaskPrincipal `
        -UserId "SYSTEM" `
        -LogonType ServiceAccount `
        -RunLevel Highest
    
    # Create task settings
    Write-Host "  Configuring task settings..." -ForegroundColor Gray
    $Settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -RunOnlyIfNetworkAvailable `
        -RestartCount 3 `
        -RestartInterval (New-TimeSpan -Minutes 5)
    
    # Register the task
    Write-Host "  Registering task..." -ForegroundColor Gray
    Register-ScheduledTask `
        -TaskName $TaskName `
        -Description "OpenClaw Duplicate File Cleanup - Weekly automatic cleanup" `
        -Action $Action `
        -Trigger $Trigger `
        -Principal $Principal `
        -Settings $Settings `
        -Force
    
    # Enable the task
    Enable-ScheduledTask -TaskName $TaskName
    
    Write-Host "鉁?Scheduled task created successfully!" -ForegroundColor Green
    Write-Host ""
    
    # Verify task creation
    $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop
    Write-Host "Task Details:" -ForegroundColor Cyan
    Write-Host "  Name: $($task.TaskName)" -ForegroundColor Gray
    Write-Host "  State: $($task.State)" -ForegroundColor Gray
    Write-Host "  Enabled: $($task.Enabled)" -ForegroundColor Gray
    
    $taskInfo = Get-ScheduledTaskInfo -TaskName $TaskName
    Write-Host "  Next Run: $($taskInfo.NextRunTime)" -ForegroundColor Gray
    
    Write-Host ""
    Write-Host "Task Configuration:" -ForegroundColor Cyan
    Write-Host "  Schedule: Every Sunday at 03:00" -ForegroundColor Gray
    Write-Host "  Script: clean-duplicates-optimized.ps1 -Strategy KeepNewest" -ForegroundColor Gray
    Write-Host "  Working Directory: $WorkingDir" -ForegroundColor Gray
    Write-Host "  Run As: SYSTEM (Highest privileges)" -ForegroundColor Gray
    
    Write-Host ""
    Write-Host "鉁?Task setup complete!" -ForegroundColor Green
    Write-Host "The task will run automatically every Sunday at 03:00." -ForegroundColor Gray
    Write-Host "Check modules/duplicate/reports\scheduled\ for cleanup reports." -ForegroundColor Gray
    
} catch {
    Write-Host "鉁?Failed to create scheduled task: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Ensure you have Administrator privileges" -ForegroundColor Gray
    Write-Host "  2. Check if Task Scheduler service is running" -ForegroundColor Gray
    Write-Host "  3. Verify the script path is correct" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Press any key to exit..."
pause
