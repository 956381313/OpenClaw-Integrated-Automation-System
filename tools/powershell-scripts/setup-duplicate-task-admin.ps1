# Windows Task Scheduler Setup for Duplicate Cleanup
# Version: 1.0.0
# Description: Create Windows scheduled task for duplicate cleanup
# Author: Hell Cat (Digital Ghost Assistant)
# Date: 2026-03-06
# IMPORTANT: Run this script as Administrator

param(
    [switch]$Test,
    [switch]$Remove,
    [switch]$Help
)

Write-Host "=== Windows Task Scheduler Setup for Duplicate Cleanup ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "IMPORTANT: This script requires Administrator privileges" -ForegroundColor Yellow
Write-Host ""

if ($Help) {
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\setup-duplicate-task-admin.ps1          # Create scheduled task" -ForegroundColor Gray
    Write-Host "  .\setup-duplicate-task-admin.ps1 -Test    # Test without creating" -ForegroundColor Gray
    Write-Host "  .\setup-duplicate-task-admin.ps1 -Remove  # Remove existing task" -ForegroundColor Gray
    exit 0
}

# Check if running as Administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    Write-Host "ERROR: This script must be run as Administrator" -ForegroundColor Red
    Write-Host "Please right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

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
    LogDirectory = "C:\Users\luchaochao\.openclaw\workspace\modules/duplicate/data/logs/scheduled"
    ReportDirectory = "C:\Users\luchaochao\.openclaw\workspace\modules/duplicate/reports\scheduled"
}

# Test mode - just show what would be created
if ($Test) {
    Write-Host "=== TEST MODE (No changes will be made) ===" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "Task Configuration:" -ForegroundColor Cyan
    Write-Host "  Name: $($config.TaskName)" -ForegroundColor Gray
    Write-Host "  Description: $($config.TaskDescription)" -ForegroundColor Gray
    Write-Host "  Script: $($config.ScriptPath)" -ForegroundColor Gray
    Write-Host "  Working Directory: $($config.WorkingDirectory)" -ForegroundColor Gray
    Write-Host "  Schedule: $($config.Trigger.Frequency) on $($config.Trigger.DaysOfWeek) at $($config.Trigger.Time)" -ForegroundColor Gray
    Write-Host ""
    
    # Check if script exists
    if (Test-Path $config.ScriptPath) {
        Write-Host "鉁?Script found: $($config.ScriptPath)" -ForegroundColor Green
    } else {
        Write-Host "鉁?Script not found: $($config.ScriptPath)" -ForegroundColor Red
    }
    
    # Check if task already exists
    try {
        $existingTask = Get-ScheduledTask -TaskName $config.TaskName -ErrorAction SilentlyContinue
        if ($existingTask) {
            Write-Host "鈿狅笍 Task already exists:" -ForegroundColor Yellow
            Write-Host "  State: $($existingTask.State)" -ForegroundColor Gray
            Write-Host "  Last Run: $($existingTask.LastRunTime)" -ForegroundColor Gray
            Write-Host "  Next Run: $($existingTask.NextRunTime)" -ForegroundColor Gray
        } else {
            Write-Host "鉁?Task does not exist (will be created)" -ForegroundColor Green
        }
    } catch {
        Write-Host "鉁?Task does not exist (will be created)" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "To create the task, run without -Test flag" -ForegroundColor Cyan
    exit 0
}

# Remove existing task
if ($Remove) {
    Write-Host "Removing scheduled task..." -ForegroundColor Yellow
    
    try {
        $existingTask = Get-ScheduledTask -TaskName $config.TaskName -ErrorAction SilentlyContinue
        if ($existingTask) {
            Unregister-ScheduledTask -TaskName $config.TaskName -Confirm:$false
            Write-Host "鉁?Task removed: $($config.TaskName)" -ForegroundColor Green
        } else {
            Write-Host "Task not found: $($config.TaskName)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "鉁?Error removing task: $_" -ForegroundColor Red
    }
    
    exit 0
}

# Main execution - Create scheduled task
Write-Host "Creating scheduled task..." -ForegroundColor Yellow

# Create directories
$directories = @($config.LogDirectory, $config.ReportDirectory)
foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "Created directory: $dir" -ForegroundColor Green
    }
}

# Check if script exists
if (-not (Test-Path $config.ScriptPath)) {
    Write-Host "ERROR: Script not found: $($config.ScriptPath)" -ForegroundColor Red
    Write-Host "Please ensure the duplicate cleanup system is properly installed" -ForegroundColor Yellow
    exit 1
}

# Create scheduled task
try {
    Write-Host "Configuring scheduled task..." -ForegroundColor Cyan
    
    # Create action
    $action = New-ScheduledTaskAction `
        -Execute "powershell.exe" `
        -Argument "-ExecutionPolicy Bypass -File `"$($config.ScriptPath)`" -Strategy KeepNewest" `
        -WorkingDirectory $config.WorkingDirectory
    
    Write-Host "  鉁?Action created" -ForegroundColor Green
    
    # Create trigger (Weekly on Sunday at 03:00)
    $trigger = New-ScheduledTaskTrigger `
        -Weekly `
        -DaysOfWeek Sunday `
        -At "03:00"
    
    Write-Host "  鉁?Trigger created: Weekly on Sunday at 03:00" -ForegroundColor Green
    
    # Create principal (run as SYSTEM with highest privileges)
    $principal = New-ScheduledTaskPrincipal `
        -UserId "SYSTEM" `
        -LogonType ServiceAccount `
        -RunLevel Highest
    
    Write-Host "  鉁?Principal created: SYSTEM account with highest privileges" -ForegroundColor Green
    
    # Create settings
    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -RunOnlyIfNetworkAvailable `
        -RestartCount 3 `
        -RestartInterval (New-TimeSpan -Minutes 5)
    
    Write-Host "  鉁?Settings created" -ForegroundColor Green
    
    # Register task
    Register-ScheduledTask `
        -TaskName $config.TaskName `
        -Description $config.TaskDescription `
        -Action $action `
        -Trigger $trigger `
        -Principal $principal `
        -Settings $settings `
        -Force
    
    Write-Host "鉁?Scheduled task created successfully!" -ForegroundColor Green
    Write-Host ""
    
    # Get task info
    $task = Get-ScheduledTask -TaskName $config.TaskName
    Write-Host "Task Information:" -ForegroundColor Cyan
    Write-Host "  Name: $($task.TaskName)" -ForegroundColor Gray
    Write-Host "  State: $($task.State)" -ForegroundColor Gray
    Write-Host "  Author: $($task.Author)" -ForegroundColor Gray
    Write-Host "  Description: $($task.Description)" -ForegroundColor Gray
    
    # Get trigger details
    $triggerInfo = $task.Triggers[0]
    Write-Host "  Schedule: $($triggerInfo.DaysOfWeek) at $($triggerInfo.StartBoundary.ToString('HH:mm'))" -ForegroundColor Gray
    
    # Enable the task
    Enable-ScheduledTask -TaskName $config.TaskName
    Write-Host "  Status: Enabled" -ForegroundColor Green
    
} catch {
    Write-Host "鉁?Error creating scheduled task: $_" -ForegroundColor Red
    exit 1
}

# Create task verification script
$verificationScript = @"
# Task Verification Script
# Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

Write-Host "=== Task Verification ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray

`$TaskName = "$($config.TaskName)"

try {
    `$task = Get-ScheduledTask -TaskName `$TaskName -ErrorAction Stop
    
    Write-Host "鉁?Task found: `$(`$task.TaskName)" -ForegroundColor Green
    Write-Host "  State: `$(`$task.State)" -ForegroundColor Gray
    Write-Host "  Enabled: `$(`$task.Enabled)" -ForegroundColor Gray
    Write-Host "  Last Run: `$(`$task.LastRunTime)" -ForegroundColor Gray
    Write-Host "  Next Run: `$(`$task.NextRunTime)" -ForegroundColor Gray
    
    # Check trigger
    if (`$task.Triggers.Count -gt 0) {
        `$trigger = `$task.Triggers[0]
        Write-Host "  Schedule: Weekly on Sunday at 03:00" -ForegroundColor Gray
    }
    
    # Check action
    if (`$task.Actions.Count -gt 0) {
        `$action = `$task.Actions[0]
        Write-Host "  Action: `$(`$action.Execute) `$(`$action.Arguments)" -ForegroundColor Gray
    }
    
    Write-Host "`n鉁?Task is properly configured" -ForegroundColor Green
    
} catch {
    Write-Host "鉁?Task not found or error: `$_" -ForegroundColor Red
}
"@

$verificationScriptPath = "verify-duplicate-task.ps1"
$verificationScript | Out-File $verificationScriptPath -Encoding UTF8
Write-Host "Created verification script: $verificationScriptPath" -ForegroundColor Green

# Create run log
$runLog = @"
Windows Task Scheduler Setup Log
================================
Setup Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Task Name: $($config.TaskName)
Description: $($config.TaskDescription)
Script: $($config.ScriptPath)
Working Directory: $($config.WorkingDirectory)
Schedule: Weekly on Sunday at 03:00
Run As: SYSTEM (Highest Privileges)

Directories Created:
- $($config.LogDirectory)
- $($config.ReportDirectory)

Files Created:
- verify-duplicate-task.ps1 (Task verification)

Verification Command:
  .\verify-duplicate-task.ps1

Manual Run Command:
  powershell -ExecutionPolicy Bypass -File "$($config.ScriptPath)" -Strategy KeepNewest

Task Management Commands:
  # View task
  Get-ScheduledTask -TaskName "$($config.TaskName)"
  
  # Run task immediately
  Start-ScheduledTask -TaskName "$($config.TaskName)"
  
  # Disable task
  Disable-ScheduledTask -TaskName "$($config.TaskName)"
  
  # Remove task
  Unregister-ScheduledTask -TaskName "$($config.TaskName)" -Confirm:`$false

---
Setup completed by OpenClaw Duplicate Cleanup Automation
"@

$runLogPath = "modules/duplicate/data/logs/scheduled\task-setup-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$runLog | Out-File $runLogPath -Encoding UTF8
Write-Host "Setup log saved: $runLogPath" -ForegroundColor Green

Write-Host "`n=== Setup Complete ===" -ForegroundColor Green
Write-Host "Scheduled task created: $($config.TaskName)" -ForegroundColor Cyan
Write-Host "Schedule: Weekly on Sunday at 03:00" -ForegroundColor Gray
Write-Host "Run As: SYSTEM (Highest Privileges)" -ForegroundColor Gray
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Verify task: .\verify-duplicate-task.ps1" -ForegroundColor Gray
Write-Host "  2. Test run: Start-ScheduledTask -TaskName `"$($config.TaskName)`"" -ForegroundColor Gray
Write-Host "  3. Check logs: modules/duplicate/data/logs/scheduled\" -ForegroundColor Gray
Write-Host ""
Write-Host "Task will automatically run every Sunday at 03:00" -ForegroundColor Cyan
