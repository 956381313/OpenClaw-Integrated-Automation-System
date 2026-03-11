# Update OpenClaw Automation with English Scripts

Write-Host "=== Updating OpenClaw Automation ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Check admin rights
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "ERROR: Need Administrator rights" -ForegroundColor Red
    Write-Host "Please run as Administrator" -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "Updating automation tasks with English scripts..." -ForegroundColor Yellow
Write-Host ""

# 1. Update hourly backup task
Write-Host "1. Updating hourly backup task..." -ForegroundColor Cyan
$backupScript = "backup-english.ps1"
if (Test-Path $backupScript) {
    # Delete existing task
    $taskName = "OpenClaw-AutoBackup"
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        Write-Host "  Removed existing task" -ForegroundColor Gray
    }
    
    # Create new task
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$backupScript`""
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 1)
    
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Description "Hourly OpenClaw backup using English script" -Force
    Write-Host "  Created updated task: $taskName" -ForegroundColor Green
} else {
    Write-Host "  ERROR: Backup script not found: $backupScript" -ForegroundColor Red
}

# 2. Update daily security check task
Write-Host "`n2. Updating daily security check task..." -ForegroundColor Cyan
$securityScript = "security-check-english.ps1"
if (Test-Path $securityScript) {
    # Delete existing task
    $taskName = "OpenClaw-SecurityCheck"
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        Write-Host "  Removed existing task" -ForegroundColor Gray
    }
    
    # Create new task
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$securityScript`""
    $trigger = New-ScheduledTaskTrigger -Daily -At "09:00"
    
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Description "Daily OpenClaw security check using English script" -Force
    Write-Host "  Created updated task: $taskName" -ForegroundColor Green
} else {
    Write-Host "  ERROR: Security script not found: $securityScript" -ForegroundColor Red
}

# 3. Update weekly audit task
Write-Host "`n3. Updating weekly audit task..." -ForegroundColor Cyan
$auditScript = "09-projects\security-tools\weekly_security_audit.ps1"
if (Test-Path $auditScript) {
    # Delete existing task
    $taskName = "OpenClaw-WeeklyAudit"
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        Write-Host "  Removed existing task" -ForegroundColor Gray
    }
    
    # Create new task
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$auditScript`""
    $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At "04:00"
    
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Description "Weekly OpenClaw security audit" -Force
    Write-Host "  Created updated task: $taskName" -ForegroundColor Green
} else {
    Write-Host "  WARNING: Audit script not found: $auditScript" -ForegroundColor Yellow
    Write-Host "  Task will be created but may fail to run" -ForegroundColor Gray
}

# 4. Create repository organization task
Write-Host "`n4. Creating repository organization task..." -ForegroundColor Cyan
$orgScript = "organize-english.ps1"
if (Test-Path $orgScript) {
    $taskName = "OpenClaw-RepositoryOrg"
    
    # Delete existing task if any
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        Write-Host "  Removed existing task" -ForegroundColor Gray
    }
    
    # Create new task
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$orgScript`""
    $trigger = New-ScheduledTaskTrigger -Daily -At "02:00"
    
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Description "Daily OpenClaw repository organization" -Force
    Write-Host "  Created new task: $taskName" -ForegroundColor Green
} else {
    Write-Host "  ERROR: Organization script not found: $orgScript" -ForegroundColor Red
}

# Show updated task list
Write-Host "`n=== Updated Automation Tasks ===" -ForegroundColor Green
Write-Host ""

$tasks = Get-ScheduledTask | Where-Object {$_.TaskName -like 'OpenClaw*'} | Sort-Object TaskName

foreach ($task in $tasks) {
    $statusColor = switch ($task.State) {
        "Ready"     { "Green" }
        "Running"   { "Cyan" }
        "Disabled"  { "Red" }
        default     { "Yellow" }
    }
    
    Write-Host "  $($task.TaskName)" -ForegroundColor $statusColor -NoNewline
    Write-Host " - $($task.State)" -ForegroundColor Gray
    
    if ($task.NextRunTime) {
        Write-Host "    Next run: $($task.NextRunTime)" -ForegroundColor Gray
    }
}

Write-Host "`n=== Update Complete ===" -ForegroundColor Green
Write-Host "Total tasks: $($tasks.Count)" -ForegroundColor Cyan
Write-Host "Ready tasks: $(($tasks | Where-Object {$_.State -eq 'Ready'}).Count)" -ForegroundColor Cyan

Write-Host "`nTest commands:" -ForegroundColor Yellow
Write-Host "  # Test backup" -ForegroundColor Gray
Write-Host "  Start-ScheduledTask -TaskName 'OpenClaw-AutoBackup'" -ForegroundColor Gray
Write-Host ""
Write-Host "  # Test security check" -ForegroundColor Gray
Write-Host "  Start-ScheduledTask -TaskName 'OpenClaw-SecurityCheck'" -ForegroundColor Gray
Write-Host ""
Write-Host "  # Test repository organization" -ForegroundColor Gray
Write-Host "  Start-ScheduledTask -TaskName 'OpenClaw-RepositoryOrg'" -ForegroundColor Gray

Write-Host "`nPress Enter to exit..." -ForegroundColor Gray
Read-Host