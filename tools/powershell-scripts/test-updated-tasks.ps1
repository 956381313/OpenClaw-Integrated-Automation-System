# Test Updated Automation Tasks

Write-Host "=== Testing Updated OpenClaw Automation ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# 1. Check task status
Write-Host "1. Checking task status..." -ForegroundColor Yellow

$tasks = Get-ScheduledTask | Where-Object {$_.TaskName -like 'OpenClaw*'} | Sort-Object TaskName

if ($tasks.Count -eq 0) {
    Write-Host "  No OpenClaw tasks found" -ForegroundColor Yellow
} else {
    Write-Host "  Found $($tasks.Count) OpenClaw tasks" -ForegroundColor Green
    
    foreach ($task in $tasks) {
        $statusColor = switch ($task.State) {
            "Ready"     { "Green" }
            "Running"   { "Cyan" }
            "Disabled"  { "Red" }
            default     { "Yellow" }
        }
        
        Write-Host "  - $($task.TaskName)" -ForegroundColor $statusColor -NoNewline
        Write-Host " ($($task.State))" -ForegroundColor Gray
        
        if ($task.NextRunTime) {
            Write-Host "    Next run: $($task.NextRunTime)" -ForegroundColor Gray
        }
    }
}

# 2. Test backup task
Write-Host "`n2. Testing backup task..." -ForegroundColor Yellow

try {
    $backupTask = Get-ScheduledTask -TaskName "OpenClaw-AutoBackup" -ErrorAction Stop
    
    if ($backupTask.State -eq "Ready") {
        Write-Host "  Starting backup task..." -ForegroundColor Gray
        Start-ScheduledTask -TaskName "OpenClaw-AutoBackup" -ErrorAction Stop
        
        # Wait a moment
        Start-Sleep -Seconds 3
        
        # Check status
        $updatedTask = Get-ScheduledTask -TaskName "OpenClaw-AutoBackup"
        Write-Host "  Backup task status: $($updatedTask.State)" -ForegroundColor Green
        
        if ($updatedTask.State -eq "Running") {
            Write-Host "  Backup is running in background" -ForegroundColor Cyan
        }
    } else {
        Write-Host "  Backup task is not ready: $($backupTask.State)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ERROR: $_" -ForegroundColor Red
}

# 3. Check script files
Write-Host "`n3. Checking script files..." -ForegroundColor Yellow

$scriptFiles = @(
    "backup-english.ps1",
    "security-check-english.ps1", 
    "organize-english.ps1",
    "kb-simple.ps1"
)

$missingCount = 0
foreach ($script in $scriptFiles) {
    if (Test-Path $script) {
        Write-Host "  [OK] $script" -ForegroundColor Green
    } else {
        Write-Host "  [MISSING] $script" -ForegroundColor Red
        $missingCount++
    }
}

# 4. Check configuration
Write-Host "`n4. Checking configuration..." -ForegroundColor Yellow

$configFile = "automation-config-english.json"
if (Test-Path $configFile) {
    Write-Host "  Configuration file found: $configFile" -ForegroundColor Green
    
    try {
        $config = Get-Content $configFile | ConvertFrom-Json
        $scriptCount = $config.Scripts.Keys.Count
        Write-Host "  Configured scripts: $scriptCount" -ForegroundColor Gray
    } catch {
        Write-Host "  Cannot read configuration" -ForegroundColor Yellow
    }
} else {
    Write-Host "  Configuration file not found" -ForegroundColor Yellow
}

# Summary
Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan

$summary = @{
    "Total Tasks" = $tasks.Count
    "Ready Tasks" = ($tasks | Where-Object {$_.State -eq "Ready"}).Count
    "Running Tasks" = ($tasks | Where-Object {$_.State -eq "Running"}).Count
    "Script Files" = ($scriptFiles.Count - $missingCount)
    "Configuration" = if (Test-Path $configFile) { "OK" } else { "Missing" }
}

foreach ($key in $summary.Keys) {
    $value = $summary[$key]
    $color = if ($value -match "OK" -or ($value -is [int] -and $value -gt 0)) { "Green" } else { "Yellow" }
    
    Write-Host "  $key : $value" -ForegroundColor $color
}

# Recommendations
Write-Host "`n=== Recommendations ===" -ForegroundColor Yellow

if ($missingCount -gt 0) {
    Write-Host "1. Some script files are missing" -ForegroundColor Yellow
}

if (($tasks | Where-Object {$_.State -ne "Ready" -and $_.State -ne "Running"}).Count -gt 0) {
    Write-Host "2. Some tasks are not in Ready state" -ForegroundColor Yellow
}

Write-Host "`n=== Quick Commands ===" -ForegroundColor Cyan
Write-Host "Run backup manually: .\run-backup.bat" -ForegroundColor Gray
Write-Host "Check automation: .\check-automation.ps1" -ForegroundColor Gray
Write-Host "Detailed monitor: .\monitor-automation-english.ps1" -ForegroundColor Gray
Write-Host "View task details: Get-ScheduledTask -TaskName 'OpenClaw-*'" -ForegroundColor Gray

Write-Host "`nPress Enter to exit..." -ForegroundColor Gray
Read-Host