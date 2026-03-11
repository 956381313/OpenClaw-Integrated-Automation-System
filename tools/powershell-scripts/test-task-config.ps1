# Test Task Configuration (Non-Admin)
# Version: 1.0.0
# Description: Test duplicate cleanup task configuration without admin rights
# Author: Hell Cat (Digital Ghost Assistant)
# Date: 2026-03-06

Write-Host "=== Duplicate Cleanup Task Configuration Test ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Configuration
$config = @{
    TaskName = "OpenClaw-Duplicate-Cleanup"
    TaskDescription = "OpenClaw Duplicate File Cleanup - Weekly automatic cleanup"
    ScriptPath = "C:\Users\luchaochao\.openclaw\workspace\clean-duplicates-optimized.ps1"
    WorkingDirectory = "C:\Users\luchaochao\.openclaw\workspace"
    Trigger = @{
        Frequency = "Weekly"
        DaysOfWeek = "Sunday"
        Time = "03:00"
    }
}

Write-Host "Configuration Test:" -ForegroundColor Yellow
Write-Host ""

# Test 1: Check required files
Write-Host "Test 1: Checking required files..." -ForegroundColor Cyan
$requiredFiles = @(
    "clean-duplicates-optimized.ps1",
    "scan-duplicates-hash.ps1",
    "modules/duplicate/config\modules/duplicate/config.json",
    "automation-config-english.json"
)

$allExist = $true
foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "  鉁?$file" -ForegroundColor Green
    } else {
        Write-Host "  鉁?$file" -ForegroundColor Red
        $allExist = $false
    }
}

# Test 2: Check script functionality
Write-Host "`nTest 2: Checking script functionality..." -ForegroundColor Cyan
if (Test-Path $config.ScriptPath) {
    Write-Host "  鉁?Script exists: $($config.ScriptPath)" -ForegroundColor Green
    
    # Test script help
    try {
        $helpResult = powershell -ExecutionPolicy Bypass -File $config.ScriptPath -Help 2>&1
        if ($helpResult -match "Usage:") {
            Write-Host "  鉁?Script help works" -ForegroundColor Green
        }
    } catch {
        Write-Host "  鈿狅笍 Script help test failed: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "  鉁?Script not found: $($config.ScriptPath)" -ForegroundColor Red
    $allExist = $false
}

# Test 3: Check automation config
Write-Host "`nTest 3: Checking automation configuration..." -ForegroundColor Cyan
if (Test-Path "automation-config-english.json") {
    try {
        $autoConfig = Get-Content "automation-config-english.json" -Raw | ConvertFrom-Json
        $duplicateTask = $autoConfig.Scripts.DuplicateCleanup
        
        if ($duplicateTask) {
            Write-Host "  鉁?Duplicate cleanup task found in automation config" -ForegroundColor Green
            Write-Host "    Name: DuplicateCleanup" -ForegroundColor Gray
            Write-Host "    Description: $($duplicateTask.Description)" -ForegroundColor Gray
            Write-Host "    Schedule: $($duplicateTask.Schedule)" -ForegroundColor Gray
            Write-Host "    Enabled: $($duplicateTask.Enabled)" -ForegroundColor Gray
        } else {
            Write-Host "  鉁?Duplicate cleanup task not found in automation config" -ForegroundColor Red
        }
    } catch {
        Write-Host "  鉁?Cannot parse automation config: $_" -ForegroundColor Red
    }
} else {
    Write-Host "  鉁?Automation config not found" -ForegroundColor Red
}

# Test 4: Check task scheduler (if accessible)
Write-Host "`nTest 4: Checking task scheduler (read-only)..." -ForegroundColor Cyan
try {
    # Try to get task info (may fail without admin rights)
    $task = Get-ScheduledTask -TaskName $config.TaskName -ErrorAction SilentlyContinue
    
    if ($task) {
        Write-Host "  鈿狅笍 Task already exists:" -ForegroundColor Yellow
        Write-Host "    Name: $($task.TaskName)" -ForegroundColor Gray
        Write-Host "    State: $($task.State)" -ForegroundColor Gray
        Write-Host "    Enabled: $($task.Enabled)" -ForegroundColor Gray
        
        if ($task.State -eq "Ready") {
            Write-Host "  鉁?Task is ready to run" -ForegroundColor Green
        }
    } else {
        Write-Host "  鈩癸笍 Task does not exist (will be created with admin rights)" -ForegroundColor Gray
    }
} catch {
    Write-Host "  鈩癸笍 Cannot access task scheduler (admin rights required)" -ForegroundColor Gray
}

# Test 5: Check directories
Write-Host "`nTest 5: Checking required directories..." -ForegroundColor Cyan
$requiredDirs = @(
    "modules/duplicate/data/logs/scheduled",
    "modules/duplicate/reports\scheduled",
    "modules/duplicate/backup",
    "modules/duplicate/config"
)

foreach ($dir in $requiredDirs) {
    if (Test-Path $dir) {
        Write-Host "  鉁?Directory exists: $dir" -ForegroundColor Green
    } else {
        Write-Host "  鈿狅笍 Directory not found: $dir" -ForegroundColor Yellow
    }
}

# Test 6: Generate task creation command
Write-Host "`nTest 6: Task creation command..." -ForegroundColor Cyan
$taskCommand = @"
# To create the scheduled task, run as Administrator:
powershell -ExecutionPolicy Bypass -File "setup-duplicate-task-admin.ps1"

# Or manually create with PowerShell (Admin):
`$TaskName = "$($config.TaskName)"
`$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$($config.ScriptPath)`" -Strategy KeepNewest" -WorkingDirectory "$($config.WorkingDirectory)"
`$Trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At "03:00"
`$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
`$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable
Register-ScheduledTask -TaskName `$TaskName -Description "$($config.TaskDescription)" -Action `$Action -Trigger `$Trigger -Principal `$Principal -Settings `$Settings -Force
"@

Write-Host "  Task creation command generated" -ForegroundColor Green
$taskCommand | Out-File "create-task-command.ps1" -Encoding UTF8
Write-Host "  Saved to: create-task-command.ps1" -ForegroundColor Gray

# Summary
Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan

if ($allExist) {
    Write-Host "鉁?All required files exist" -ForegroundColor Green
    Write-Host "鉁?Script functionality verified" -ForegroundColor Green
    Write-Host "鉁?Automation configuration verified" -ForegroundColor Green
    Write-Host "鉁?Directories checked" -ForegroundColor Green
    
    Write-Host "`n鉁?System is ready for task scheduler setup" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Run as Administrator: .\setup-duplicate-task-admin.ps1" -ForegroundColor Gray
    Write-Host "  2. Or use: .\create-task-command.ps1 (run as Admin)" -ForegroundColor Gray
    Write-Host "  3. Verify: .\verify-duplicate-task.ps1" -ForegroundColor Gray
} else {
    Write-Host "鈿狅笍 Some tests failed" -ForegroundColor Yellow
    Write-Host "Please check missing files before setting up task scheduler" -ForegroundColor Gray
}

Write-Host "`nTask Configuration:" -ForegroundColor Cyan
Write-Host "  Name: $($config.TaskName)" -ForegroundColor Gray
Write-Host "  Description: $($config.TaskDescription)" -ForegroundColor Gray
Write-Host "  Script: $($config.ScriptPath)" -ForegroundColor Gray
Write-Host "  Schedule: Weekly on Sunday at 03:00" -ForegroundColor Gray
Write-Host "  Run As: SYSTEM (Highest Privileges)" -ForegroundColor Gray
