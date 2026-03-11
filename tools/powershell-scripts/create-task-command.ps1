# To create the scheduled task, run as Administrator:
powershell -ExecutionPolicy Bypass -File "setup-duplicate-task-admin.ps1"

# Or manually create with PowerShell (Admin):
$TaskName = "OpenClaw-Duplicate-Cleanup"
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File "C:\Users\luchaochao\.openclaw\workspace\clean-duplicates-optimized.ps1" -Strategy KeepNewest" -WorkingDirectory "C:\Users\luchaochao\.openclaw\workspace"
$Trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At "03:00"
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable
Register-ScheduledTask -TaskName $TaskName -Description "OpenClaw Duplicate File Cleanup - Weekly automatic cleanup" -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Force
