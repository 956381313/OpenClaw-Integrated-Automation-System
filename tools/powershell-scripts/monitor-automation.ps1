# OpenClaw Automation Monitor

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   OpenClaw Automation System Monitor" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# 1. Check all OpenClaw tasks
Write-Host "1. SCHEDULED TASKS STATUS:" -ForegroundColor Yellow
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
    
    if ($task.LastRunTime) {
        Write-Host "    Last run: $($task.LastRunTime)" -ForegroundColor Gray
    }
    
    if ($task.NextRunTime) {
        Write-Host "    Next run: $($task.NextRunTime)" -ForegroundColor Gray
    }
    
    Write-Host ""
}

# 2. Check backup status
Write-Host "2. BACKUP SYSTEM STATUS:" -ForegroundColor Yellow
Write-Host ""

# Check GitHub repository
$gitRepo = "services/github/cloud-backup"
if (Test-Path $gitRepo) {
    Write-Host "  GitHub Repository: " -NoNewline
    Write-Host "OK" -ForegroundColor Green
    
    try {
        Set-Location $gitRepo
        $commitCount = (git log --oneline).Count
        $lastCommit = git log --oneline -1
        Set-Location ..
        
        Write-Host "    Commits: $commitCount" -ForegroundColor Gray
        Write-Host "    Latest: $lastCommit" -ForegroundColor Gray
    } catch {
        Write-Host "    Error reading Git history" -ForegroundColor Yellow
    }
} else {
    Write-Host "  GitHub Repository: " -NoNewline
    Write-Host "Not Found" -ForegroundColor Yellow
}

# Check backup directory
$backupDir = "D:\OpenClaw-Backup"
if (Test-Path $backupDir) {
    $backupCount = (Get-ChildItem $backupDir -Directory).Count
    Write-Host "  Local Backups: " -NoNewline
    Write-Host "$backupCount backups" -ForegroundColor Green
} else {
    Write-Host "  Local Backups: " -NoNewline
    Write-Host "Directory not found" -ForegroundColor Yellow
}

# 3. Check script status
Write-Host "`n3. SCRIPT STATUS:" -ForegroundColor Yellow
Write-Host ""

$scripts = @(
    @{Name="Backup Script"; Path="upload-simple.ps1"},
    @{Name="Security Check"; Path="09-projects\security-tools\security-check-fixed.ps1"},
    @{Name="Automation Setup"; Path="setup-auto.ps1"},
    @{Name="Monitor Script"; Path="monitor-automation.ps1"}
)

foreach ($script in $scripts) {
    if (Test-Path $script.Path) {
        Write-Host "  $($script.Name): " -NoNewline
        Write-Host "OK" -ForegroundColor Green
    } else {
        Write-Host "  $($script.Name): " -NoNewline
        Write-Host "Missing" -ForegroundColor Red
    }
}

# 4. Next scheduled runs
Write-Host "`n4. NEXT SCHEDULED RUNS:" -ForegroundColor Yellow
Write-Host ""

$now = Get-Date
$nextHour = $now.AddHours(1)
$nextHour = Get-Date -Year $nextHour.Year -Month $nextHour.Month -Day $nextHour.Day -Hour $nextHour.Hour -Minute 0 -Second 0

Write-Host "  Next hourly backup: " -NoNewline
Write-Host "$nextHour" -ForegroundColor Cyan

$nextDaily = Get-Date -Hour 9 -Minute 0 -Second 0
if ($nextDaily -lt $now) {
    $nextDaily = $nextDaily.AddDays(1)
}
Write-Host "  Next daily check:   " -NoNewline
Write-Host "$nextDaily" -ForegroundColor Cyan

# Check if today is Sunday
if ((Get-Date).DayOfWeek -eq "Sunday") {
    $nextWeekly = Get-Date -Hour 4 -Minute 0 -Second 0
    if ($nextWeekly -lt $now) {
        $nextWeekly = $nextWeekly.AddDays(7)
    }
} else {
    # Find next Sunday
    $daysToSunday = (7 - [int](Get-Date).DayOfWeek) % 7
    if ($daysToSunday -eq 0) { $daysToSunday = 7 }
    $nextWeekly = (Get-Date).AddDays($daysToSunday).Date.AddHours(4)
}
Write-Host "  Next weekly audit:  " -NoNewline
Write-Host "$nextWeekly" -ForegroundColor Cyan

# 5. System health
Write-Host "`n5. SYSTEM HEALTH:" -ForegroundColor Yellow
Write-Host ""

# Check OpenClaw directory
$openclawPath = "C:\Users\luchaochao\.openclaw"
if (Test-Path $openclawPath) {
    $sizeMB = [math]::Round((Get-ChildItem $openclawPath -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
    Write-Host "  OpenClaw Directory: " -NoNewline
    Write-Host "OK ($sizeMB MB)" -ForegroundColor Green
} else {
    Write-Host "  OpenClaw Directory: " -NoNewline
    Write-Host "MISSING" -ForegroundColor Red
}

# Check core files
$coreFiles = @("openclaw.json", "gateway.cmd", "update-check.json")
$missingFiles = 0
foreach ($file in $coreFiles) {
    if (-not (Test-Path "$openclawPath\$file")) {
        $missingFiles++
    }
}

if ($missingFiles -eq 0) {
    Write-Host "  Core Files: " -NoNewline
    Write-Host "All present" -ForegroundColor Green
} else {
    Write-Host "  Core Files: " -NoNewline
    Write-Host "$missingFiles missing" -ForegroundColor Yellow
}

# Summary
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "MONITORING COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

$totalTasks = $tasks.Count
$readyTasks = ($tasks | Where-Object {$_.State -eq "Ready"}).Count
$runningTasks = ($tasks | Where-Object {$_.State -eq "Running"}).Count

Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Tasks: $totalTasks total, $readyTasks ready, $runningTasks running" -ForegroundColor Gray
Write-Host "  Next backup: $nextHour" -ForegroundColor Gray
Write-Host "  System: $(if ($missingFiles -eq 0) {'Healthy'} else {'Needs attention'})" -ForegroundColor $(if ($missingFiles -eq 0) {'Green'} else {'Yellow'})

Write-Host "`nQuick commands:" -ForegroundColor Yellow
Write-Host "  Run backup now: Start-ScheduledTask -TaskName 'OpenClaw-AutoBackup'" -ForegroundColor Gray
Write-Host "  View details: Get-ScheduledTask -TaskName 'OpenClaw-AutoBackup' | Format-List" -ForegroundColor Gray
Write-Host "  Check logs: Get-EventLog -LogName Application -Source 'TaskScheduler' -Newest 10" -ForegroundColor Gray

Write-Host "`nPress Enter to exit..." -ForegroundColor Gray
Read-Host
