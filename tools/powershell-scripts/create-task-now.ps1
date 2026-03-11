# Create Task Now Script
Write-Host "Creating scheduled task now..." -ForegroundColor Yellow

$TaskName = "OpenClaw-Duplicate-Cleanup"
$WorkingDir = "C:\Users\luchaochao\.openclaw\workspace"
$ScriptPath = "$WorkingDir\clean-duplicates-optimized.ps1"

# Check if script exists
if (-not (Test-Path $ScriptPath)) {
    Write-Host "ERROR: Script not found: $ScriptPath" -ForegroundColor Red
    exit 1
}

Write-Host "Script found: $ScriptPath" -ForegroundColor Green

try {
    # Create action
    $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`" -Strategy KeepNewest" -WorkingDirectory $WorkingDir
    
    # Create trigger
    $Trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At "03:00"
    
    # Create principal
    $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    # Create settings
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable
    
    # Register task
    Register-ScheduledTask -TaskName $TaskName -Description "OpenClaw Duplicate File Cleanup" -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Force
    
    # Enable task
    Enable-ScheduledTask -TaskName $TaskName
    
    Write-Host "SUCCESS: Task created!" -ForegroundColor Green
    Write-Host "Task Name: $TaskName" -ForegroundColor Gray
    Write-Host "Schedule: Every Sunday at 03:00" -ForegroundColor Gray
    Write-Host "Script: clean-duplicates-optimized.ps1 -Strategy KeepNewest" -ForegroundColor Gray
    
} catch {
    Write-Host "ERROR: Failed to create task: $_" -ForegroundColor Red
    Write-Host "This script may need Administrator privileges." -ForegroundColor Yellow
}