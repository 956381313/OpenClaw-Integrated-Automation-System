# Final Command for Task Creation
# Copy and paste this into Administrator PowerShell

$TaskName = "OpenClaw-Duplicate-Cleanup"
$WorkingDir = "C:\Users\luchaochao\.openclaw\workspace"
$ScriptPath = "$WorkingDir\clean-duplicates-optimized.ps1"

Write-Host "Creating scheduled task: $TaskName" -ForegroundColor Yellow
Write-Host "Script: $ScriptPath" -ForegroundColor Gray
Write-Host "Schedule: Every Sunday at 03:00" -ForegroundColor Gray
Write-Host ""

# Check if script exists
if (-not (Test-Path $ScriptPath)) {
    Write-Host "ERROR: Script not found: $ScriptPath" -ForegroundColor Red
    exit 1
}

Write-Host "鉁?Script found" -ForegroundColor Green

try {
    # Remove existing task if any
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-Host "Removing existing task..." -ForegroundColor Gray
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-Host "鉁?Old task removed" -ForegroundColor Green
    }
    
    # Create task components
    $Action = New-ScheduledTaskAction `
        -Execute "powershell.exe" `
        -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`" -Strategy KeepNewest" `
        -WorkingDirectory $WorkingDir
    
    $Trigger = New-ScheduledTaskTrigger `
        -Weekly `
        -DaysOfWeek Sunday `
        -At "03:00"
    
    $Principal = New-ScheduledTaskPrincipal `
        -UserId "SYSTEM" `
        -LogonType ServiceAccount `
        -RunLevel Highest
    
    $Settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -RunOnlyIfNetworkAvailable
    
    # Register and enable task
    Register-ScheduledTask `
        -TaskName $TaskName `
        -Description "OpenClaw Duplicate File Cleanup - Weekly automatic cleanup" `
        -Action $Action `
        -Trigger $Trigger `
        -Principal $Principal `
        -Settings $Settings `
        -Force
    
    Enable-ScheduledTask -TaskName $TaskName
    
    Write-Host ""
    Write-Host "鉁?SUCCESS: Task created successfully!" -ForegroundColor Green
    Write-Host ""
    
    # Verify
    $task = Get-ScheduledTask -TaskName $TaskName
    Write-Host "Task Details:" -ForegroundColor Cyan
    Write-Host "  Name: $($task.TaskName)" -ForegroundColor Gray
    Write-Host "  State: $($task.State)" -ForegroundColor Gray
    Write-Host "  Enabled: $($task.Enabled)" -ForegroundColor Gray
    
    Write-Host ""
    Write-Host "The task will run automatically every Sunday at 03:00." -ForegroundColor Gray
    Write-Host "Check modules/duplicate/reports\scheduled\ for cleanup reports." -ForegroundColor Gray
    
} catch {
    Write-Host ""
    Write-Host "鉂?ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "This script requires Administrator privileges." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
