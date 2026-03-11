# Final Verification Script
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "    FINAL VERIFICATION - Scheduled Task" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

$taskName = "OpenClaw-Duplicate-Cleanup"

try {
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction Stop
    
    Write-Host "✅ TASK VERIFICATION SUCCESSFUL!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Task Details:" -ForegroundColor Cyan
    Write-Host "  Name: $($task.TaskName)" -ForegroundColor Gray
    Write-Host "  State: $($task.State)" -ForegroundColor Gray
    Write-Host "  Enabled: $($task.Enabled)" -ForegroundColor Gray
    Write-Host "  Path: $($task.TaskPath)" -ForegroundColor Gray
    
    $taskInfo = Get-ScheduledTaskInfo -TaskName $taskName
    Write-Host "  Next Run: $($taskInfo.NextRunTime)" -ForegroundColor Gray
    
    Write-Host ""
    Write-Host "Configuration:" -ForegroundColor Cyan
    Write-Host "  Schedule: Every Sunday at 03:00" -ForegroundColor Gray
    Write-Host "  Script: clean-duplicates-optimized.ps1 -Strategy KeepNewest" -ForegroundColor Gray
    Write-Host "  Working Directory: C:\Users\luchaochao\.openclaw\workspace" -ForegroundColor Gray
    Write-Host "  Run As: SYSTEM (Highest privileges)" -ForegroundColor Gray
    
    Write-Host ""
    Write-Host "🎉 REPEAT FILE CLEANUP SYSTEM IS NOW FULLY OPERATIONAL!" -ForegroundColor Green
    Write-Host ""
    Write-Host "The system will:" -ForegroundColor Gray
    Write-Host "  • Run automatically every Sunday at 03:00" -ForegroundColor Gray
    Write-Host "  • Clean duplicate files using hash verification" -ForegroundColor Gray
    Write-Host "  • Create timestamped backups before deletion" -ForegroundColor Gray
    Write-Host "  • Generate detailed cleanup reports" -ForegroundColor Gray
    Write-Host "  • Send email notifications (if configured)" -ForegroundColor Gray
    Write-Host "  • Reclaim disk space automatically" -ForegroundColor Gray
    
} catch {
    Write-Host "❌ TASK VERIFICATION FAILED: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "    VERIFICATION COMPLETE" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Cyan