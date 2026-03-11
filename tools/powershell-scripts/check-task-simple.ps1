$task = Get-ScheduledTask -TaskName 'OpenClaw-Duplicate-Cleanup' -ErrorAction SilentlyContinue
if ($task) {
    Write-Host 'SUCCESS: Task created!' -ForegroundColor Green
    Write-Host 'Task Name:' $task.TaskName
    Write-Host 'State:' $task.State
    Write-Host 'Enabled:' $task.Enabled
    
    # Get more details
    $taskInfo = Get-ScheduledTaskInfo -TaskName 'OpenClaw-Duplicate-Cleanup' -ErrorAction SilentlyContinue
    if ($taskInfo) {
        Write-Host 'Last Run:' $taskInfo.LastRunTime
        Write-Host 'Next Run:' $taskInfo.NextRunTime
    }
} else {
    Write-Host 'Task not found yet.' -ForegroundColor Yellow
    Write-Host 'The setup may still be running or was cancelled.' -ForegroundColor Gray
}