# Windows Task Scheduler Script for Duplicate Cleanup
# Generated: 2026-03-06 15:11:41

$TaskName = "OpenClaw-Duplicate-Cleanup"
$TaskDescription = "OpenClaw Duplicate File Cleanup - Weekly automatic cleanup"
$ScriptPath = "C:\Users\luchaochao\.openclaw\workspace\clean-duplicates-optimized.ps1"
$WorkingDirectory = "C:\Users\luchaochao\.openclaw\workspace"

# Create scheduled task
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File "$ScriptPath" -Strategy KeepNewest" -WorkingDirectory $WorkingDirectory
$Trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 03:00
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable

# Register task
Register-ScheduledTask -TaskName $TaskName -Description $TaskDescription -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Force

Write-Host "Scheduled task created: $TaskName" -ForegroundColor Green
Write-Host "Runs: Weekly on Sunday at 03:00" -ForegroundColor Gray
