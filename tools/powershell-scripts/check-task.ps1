$task = Get-ScheduledTask -TaskName 'OpenClaw-Duplicate-Cleanup' -ErrorAction SilentlyContinue
if ($task) {
    Write-Host 'Task exists:' $task.TaskName
    Write-Host 'State:' $task.State
    Write-Host 'Enabled:' $task.Enabled
} else {
    Write-Host 'Task not found'
}