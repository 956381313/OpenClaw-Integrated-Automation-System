# Create Task with Admin Check
Write-Host "Checking permissions..." -ForegroundColor Yellow

# Check if running as Administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    Write-Host "ERROR: This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please run this script as Administrator:" -ForegroundColor Yellow
    Write-Host "1. Right-click on PowerShell" -ForegroundColor Gray
    Write-Host "2. Select 'Run as Administrator'" -ForegroundColor Gray
    Write-Host "3. Navigate to: cd C:\Users\luchaochao\.openclaw\workspace" -ForegroundColor Gray
    Write-Host "4. Run: .\create-task-admin.ps1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Or use the batch file: .\run-as-admin-direct.bat" -ForegroundColor Gray
    pause
    exit 1
}

Write-Host "鉁?Running as Administrator" -ForegroundColor Green
Write-Host ""

Write-Host "Creating scheduled task..." -ForegroundColor Yellow

$TaskName = "OpenClaw-Duplicate-Cleanup"
$WorkingDir = "C:\Users\luchaochao\.openclaw\workspace"
$ScriptPath = "$WorkingDir\clean-duplicates-optimized.ps1"

# Check if script exists
if (-not (Test-Path $ScriptPath)) {
    Write-Host "ERROR: Script not found: $ScriptPath" -ForegroundColor Red
    pause
    exit 1
}

Write-Host "鉁?Script found: $ScriptPath" -ForegroundColor Green

try {
    # Check if task already exists
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-Host "Task already exists. Removing..." -ForegroundColor Yellow
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-Host "鉁?Old task removed" -ForegroundColor Green
    }
    
    # Create action
    Write-Host "Creating task action..." -ForegroundColor Gray
    $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`" -Strategy KeepNewest" -WorkingDirectory $WorkingDir
    
    # Create trigger
    Write-Host "Creating trigger (every Sunday at 03:00)..." -ForegroundColor Gray
    $Trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At "03:00"
    
    # Create principal
    Write-Host "Setting up security (run as SYSTEM)..." -ForegroundColor Gray
    $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    # Create settings
    Write-Host "Configuring task settings..." -ForegroundColor Gray
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable
    
    # Register task
    Write-Host "Registering task..." -ForegroundColor Gray
    Register-ScheduledTask -TaskName $TaskName -Description "OpenClaw Duplicate File Cleanup - Weekly automatic cleanup" -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Force
    
    # Enable task
    Enable-ScheduledTask -TaskName $TaskName
    
    Write-Host ""
    Write-Host "鉁?SUCCESS: Task created successfully!" -ForegroundColor Green
    Write-Host ""
    
    # Verify task
    $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop
    Write-Host "Task Details:" -ForegroundColor Cyan
    Write-Host "  Name: $($task.TaskName)" -ForegroundColor Gray
    Write-Host "  State: $($task.State)" -ForegroundColor Gray
    Write-Host "  Enabled: $($task.Enabled)" -ForegroundColor Gray
    
    $taskInfo = Get-ScheduledTaskInfo -TaskName $TaskName
    Write-Host "  Next Run: $($taskInfo.NextRunTime)" -ForegroundColor Gray
    
    Write-Host ""
    Write-Host "Configuration:" -ForegroundColor Cyan
    Write-Host "  Schedule: Every Sunday at 03:00" -ForegroundColor Gray
    Write-Host "  Script: clean-duplicates-optimized.ps1 -Strategy KeepNewest" -ForegroundColor Gray
    Write-Host "  Working Directory: $WorkingDir" -ForegroundColor Gray
    Write-Host "  Run As: SYSTEM (Highest privileges)" -ForegroundColor Gray
    
    Write-Host ""
    Write-Host "The task will run automatically every Sunday at 03:00." -ForegroundColor Gray
    Write-Host "Check modules/duplicate/reports\scheduled\ for cleanup reports." -ForegroundColor Gray
    
} catch {
    Write-Host ""
    Write-Host "鉂?ERROR: Failed to create task: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "Press any key to exit..."
pause
