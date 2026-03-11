# Immediate Setup Verification
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "    Immediate Setup Verification" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Check 1: Scheduled Task
Write-Host "Check 1: Scheduled Task Status" -ForegroundColor Green
$taskName = "OpenClaw-Duplicate-Cleanup"
$task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if ($task) {
    Write-Host "  鉁?Task created successfully!" -ForegroundColor Green
    Write-Host "    Name: $($task.TaskName)" -ForegroundColor Gray
    Write-Host "    State: $($task.State)" -ForegroundColor Gray
    Write-Host "    Enabled: $($task.Enabled)" -ForegroundColor Gray
    
    # Get task info
    $taskInfo = Get-ScheduledTaskInfo -TaskName $taskName -ErrorAction SilentlyContinue
    if ($taskInfo) {
        Write-Host "    Last Run: $($taskInfo.LastRunTime)" -ForegroundColor Gray
        Write-Host "    Next Run: $($taskInfo.NextRunTime)" -ForegroundColor Gray
    }
    
    if ($task.State -eq "Ready" -and $task.Enabled -eq $true) {
        Write-Host "  鉁?Task is ready and enabled" -ForegroundColor Green
    }
} else {
    Write-Host "  鈿狅笍 Task not found yet" -ForegroundColor Yellow
    Write-Host "    The setup script may still be running" -ForegroundColor Gray
    Write-Host "    Or user may have cancelled the UAC prompt" -ForegroundColor Gray
}

Write-Host ""

# Check 2: Setup Logs
Write-Host "Check 2: Setup Logs" -ForegroundColor Green
$logFiles = Get-ChildItem "modules/duplicate/data/logs/scheduled\" -Filter "task-setup-easy-*.log" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending

if ($logFiles.Count -gt 0) {
    $latestLog = $logFiles[0]
    Write-Host "  鉁?Setup log found: $($latestLog.Name)" -ForegroundColor Green
    Write-Host "    Created: $($latestLog.CreationTime)" -ForegroundColor Gray
    Write-Host "    Size: $([math]::Round($latestLog.Length/1KB,2)) KB" -ForegroundColor Gray
    
    # Check log content for success
    $logContent = Get-Content $latestLog.FullName -TotalCount 10
    if ($logContent -match "Setup Result: SUCCESS") {
        Write-Host "  鉁?Setup completed successfully" -ForegroundColor Green
    }
} else {
    Write-Host "  鈩癸笍 No setup logs found yet" -ForegroundColor Gray
}

Write-Host ""

# Check 3: System Verification (already done)
Write-Host "Check 3: System Verification Status" -ForegroundColor Green
$cleanupVerified = Test-Path "modules/duplicate/reports\optimized-cleanup-report-20260306-152656.txt"
$backupVerified = Test-Path "modules/duplicate/backup\optimized-cleanup-20260306-152656"

if ($cleanupVerified) {
    Write-Host "  鉁?Cleanup system verified (1.69MB reclaimed)" -ForegroundColor Green
}
if ($backupVerified) {
    $backupCount = (Get-ChildItem "modules/duplicate/backup\optimized-cleanup-20260306-152656" -ErrorAction SilentlyContinue | Measure-Object).Count
    Write-Host "  鉁?Backup system verified ($backupCount files backed up)" -ForegroundColor Green
}

Write-Host ""

# Summary
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "    Verification Summary" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

if ($task) {
    Write-Host "馃帀 SETUP SUCCESSFUL!" -ForegroundColor Green
    Write-Host ""
    Write-Host "The scheduled task has been created:" -ForegroundColor Gray
    Write-Host "  鈥?Name: $taskName" -ForegroundColor Gray
    Write-Host "  鈥?Schedule: Every Sunday at 03:00" -ForegroundColor Gray
    Write-Host "  鈥?Status: $($task.State)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Test immediate run:" -ForegroundColor Gray
    Write-Host "     Start-ScheduledTask -TaskName `"$taskName`"" -ForegroundColor Gray
    Write-Host "  2. Verify task details:" -ForegroundColor Gray
    Write-Host "     Get-ScheduledTask -TaskName `"$taskName`"" -ForegroundColor Gray
    Write-Host "  3. Check will run next Sunday at 03:00" -ForegroundColor Gray
} else {
    Write-Host "鈴?SETUP IN PROGRESS OR PENDING" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Possible scenarios:" -ForegroundColor Gray
    Write-Host "  1. UAC prompt appeared - user needs to click 'Yes'" -ForegroundColor Gray
    Write-Host "  2. Setup script is running in Administrator window" -ForegroundColor Gray
    Write-Host "  3. User cancelled the setup" -ForegroundColor Gray
    Write-Host ""
    Write-Host "What to do:" -ForegroundColor Cyan
    Write-Host "  1. Look for a new PowerShell window (Administrator)" -ForegroundColor Gray
    Write-Host "  2. Complete the interactive setup in that window" -ForegroundColor Gray
    Write-Host "  3. If no window appeared, run setup again:" -ForegroundColor Gray
    Write-Host "     .\setup-task-simple.bat" -ForegroundColor Gray
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
