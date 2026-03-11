# OpenClaw Duplicate File Cleanup Automation
# Version: 1.0.0
# Description: Integrate duplicate cleanup into automation system
# Author: Hell Cat (Digital Ghost Assistant)
# Date: 2026-03-06

param(
    [switch]$Setup,
    [switch]$Test,
    [switch]$Run,
    [switch]$Help
)

Write-Host "=== OpenClaw Duplicate File Cleanup Automation ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

if ($Help) {
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\automate-duplicate-cleanup.ps1 -Setup    # Setup automation integration" -ForegroundColor Gray
    Write-Host "  .\automate-duplicate-cleanup.ps1 -Test     # Test automation integration" -ForegroundColor Gray
    Write-Host "  .\automate-duplicate-cleanup.ps1 -Run      # Run automated cleanup" -ForegroundColor Gray
    exit 0
}

# Configuration
$config = @{
    AutomationConfig = "automation-config-english.json"
    DuplicateConfig = "modules/duplicate/config\modules/duplicate/config.json"
    TaskName = "DuplicateCleanup"
    TaskDescription = "OpenClaw Duplicate File Cleanup - Weekly automatic cleanup"
    Schedule = @{
        Frequency = "Weekly"
        DayOfWeek = "Sunday"
        Time = "03:00"
    }
    EmailConfig = "modules/email/config\modules/email/config.json"
    LogDirectory = "modules/duplicate/data/logs/automation"
    ReportDirectory = "modules/duplicate/reports\automation"
}

# Setup automation integration
function Setup-Automation {
    Write-Host "Setting up duplicate cleanup automation..." -ForegroundColor Yellow
    
    # 1. Check if automation config exists
    if (-not (Test-Path $config.AutomationConfig)) {
        Write-Host "ERROR: Automation config not found: $($config.AutomationConfig)" -ForegroundColor Red
        return $false
    }
    
    # 2. Load automation config
    try {
        $automationConfig = Get-Content $config.AutomationConfig -Raw | ConvertFrom-Json
        Write-Host "Loaded automation config" -ForegroundColor Green
    } catch {
        Write-Host "ERROR: Cannot load automation config" -ForegroundColor Red
        return $false
    }
    
    # 3. Add duplicate cleanup task to automation config
    $duplicateTask = @{
        Name = $config.TaskName
        Description = $config.TaskDescription
        Script = "clean-duplicates-optimized.ps1"
        Arguments = "-Strategy KeepNewest"
        Enabled = $true
        Schedule = $config.Schedule
        EmailNotification = $true
        LogFile = "$($config.LogDirectory)\duplicate-cleanup-{timestamp}.log"
        ReportFile = "$($config.ReportDirectory)\duplicate-cleanup-{timestamp}.txt"
        BackupDirectory = "modules/duplicate/backup\automated-{timestamp}"
        MaxRuntimeMinutes = 60
        RetryCount = 2
        Priority = "High"
    }
    
    # Check if task already exists
    $existingTask = $automationConfig.Tasks | Where-Object { $_.Name -eq $config.TaskName }
    if ($existingTask) {
        Write-Host "Task already exists, updating..." -ForegroundColor Yellow
        $existingTaskIndex = [array]::IndexOf($automationConfig.Tasks, $existingTask)
        $automationConfig.Tasks[$existingTaskIndex] = $duplicateTask
    } else {
        Write-Host "Adding new task to automation config..." -ForegroundColor Green
        $automationConfig.Tasks += $duplicateTask
    }
    
    # 4. Save updated config
    try {
        $automationConfig | ConvertTo-Json -Depth 10 | Out-File $config.AutomationConfig -Encoding UTF8
        Write-Host "Updated automation config: $($config.AutomationConfig)" -ForegroundColor Green
    } catch {
        Write-Host "ERROR: Cannot save automation config" -ForegroundColor Red
        return $false
    }
    
    # 5. Create directories
    $directories = @($config.LogDirectory, $config.ReportDirectory)
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Host "Created directory: $dir" -ForegroundColor Green
        }
    }
    
    # 6. Create Windows Task Scheduler script
    $taskScript = @"
# Windows Task Scheduler Script for Duplicate Cleanup
# Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

`$TaskName = "OpenClaw-Duplicate-Cleanup"
`$TaskDescription = "$($config.TaskDescription)"
`$ScriptPath = "C:\Users\luchaochao\.openclaw\workspace\clean-duplicates-optimized.ps1"
`$WorkingDirectory = "C:\Users\luchaochao\.openclaw\workspace"

# Create scheduled task
`$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"`$ScriptPath`" -Strategy KeepNewest" -WorkingDirectory `$WorkingDirectory
`$Trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 03:00
`$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
`$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable

# Register task
Register-ScheduledTask -TaskName `$TaskName -Description `$TaskDescription -Action `$Action -Trigger `$Trigger -Principal `$Principal -Settings `$Settings -Force

Write-Host "Scheduled task created: `$TaskName" -ForegroundColor Green
Write-Host "Runs: Weekly on Sunday at 03:00" -ForegroundColor Gray
"@
    
    $taskScriptPath = "setup-duplicate-task.ps1"
    $taskScript | Out-File $taskScriptPath -Encoding UTF8
    Write-Host "Created task scheduler script: $taskScriptPath" -ForegroundColor Green
    
    # 7. Create run script
    $runScript = @"
# Run Duplicate Cleanup Automation
# Usage: .\run-duplicate-automation.ps1

Write-Host "=== Running Duplicate Cleanup Automation ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray

# Step 1: Scan for duplicates
Write-Host "`nStep 1: Scanning for duplicates..." -ForegroundColor Yellow
.\scan-duplicates-hash.ps1

# Step 2: Run optimized cleanup
Write-Host "`nStep 2: Running optimized cleanup..." -ForegroundColor Yellow
.\clean-duplicates-optimized.ps1 -Strategy KeepNewest

# Step 3: Send email notification
Write-Host "`nStep 3: Sending email notification..." -ForegroundColor Yellow
if (Test-Path "send-email-fixed.ps1") {
    .\send-email-fixed.ps1 -Subject "OpenClaw Duplicate Cleanup Completed" -Body "Weekly duplicate file cleanup completed. Check modules/duplicate/reports\ directory for details."
} else {
    Write-Host "Email script not found, skipping notification" -ForegroundColor Yellow
}

Write-Host "`n=== Automation Complete ===" -ForegroundColor Green
"@
    
    $runScriptPath = "run-duplicate-automation.ps1"
    $runScript | Out-File $runScriptPath -Encoding UTF8
    Write-Host "Created run script: $runScriptPath" -ForegroundColor Green
    
    # 8. Create test script
    $testScript = @"
# Test Duplicate Cleanup Automation
# Usage: .\test-duplicate-automation.ps1

Write-Host "=== Testing Duplicate Cleanup Automation ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray

# Test 1: Check required files
Write-Host "`nTest 1: Checking required files..." -ForegroundColor Yellow
`$requiredFiles = @(
    "scan-duplicates-hash.ps1",
    "clean-duplicates-optimized.ps1",
    "modules/duplicate/config\modules/duplicate/config.json",
    "automation-config-english.json"
)

`$allExist = `$true
foreach (`$file in `$requiredFiles) {
    if (Test-Path `$file) {
        Write-Host "  鉁?`$file" -ForegroundColor Green
    } else {
        Write-Host "  鉁?`$file" -ForegroundColor Red
        `$allExist = `$false
    }
}

# Test 2: Test scan in preview mode
Write-Host "`nTest 2: Testing scan in preview mode..." -ForegroundColor Yellow
.\scan-duplicates-hash.ps1 -Test

# Test 3: Test cleanup in preview mode
Write-Host "`nTest 3: Testing cleanup in preview mode..." -ForegroundColor Yellow
.\clean-duplicates-optimized.ps1 -Preview -Strategy KeepNewest

# Test 4: Check automation config
Write-Host "`nTest 4: Checking automation config..." -ForegroundColor Yellow
if (Test-Path "automation-config-english.json") {
    `$autoConfig = Get-Content "automation-config-english.json" -Raw | ConvertFrom-Json
    `$duplicateTask = `$autoConfig.Tasks | Where-Object { `$_.Name -eq "$($config.TaskName)" }
    if (`$duplicateTask) {
        Write-Host "  鉁?Duplicate cleanup task found in automation config" -ForegroundColor Green
        Write-Host "    Name: `$(`$duplicateTask.Name)" -ForegroundColor Gray
        Write-Host "    Schedule: `$(`$duplicateTask.Schedule.Frequency) on `$(`$duplicateTask.Schedule.DayOfWeek) at `$(`$duplicateTask.Schedule.Time)" -ForegroundColor Gray
    } else {
        Write-Host "  鉁?Duplicate cleanup task not found in automation config" -ForegroundColor Red
    }
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan
if (`$allExist) {
    Write-Host "All tests passed! Automation is ready." -ForegroundColor Green
} else {
    Write-Host "Some tests failed. Check missing files." -ForegroundColor Red
}
"@
    
    $testScriptPath = "test-duplicate-automation.ps1"
    $testScript | Out-File $testScriptPath -Encoding UTF8
    Write-Host "Created test script: $testScriptPath" -ForegroundColor Green
    
    Write-Host "`n=== Setup Complete ===" -ForegroundColor Green
    Write-Host "Created files:" -ForegroundColor Yellow
    Write-Host "  - $taskScriptPath (Windows Task Scheduler setup)" -ForegroundColor Gray
    Write-Host "  - $runScriptPath (Manual run script)" -ForegroundColor Gray
    Write-Host "  - $testScriptPath (Test script)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Run: .\test-duplicate-automation.ps1" -ForegroundColor Gray
    Write-Host "  2. Run: .\setup-duplicate-task.ps1 (as Administrator)" -ForegroundColor Gray
    Write-Host "  3. Test: .\run-duplicate-automation.ps1" -ForegroundColor Gray
    
    return $true
}

# Test automation integration
function Test-Automation {
    Write-Host "Testing duplicate cleanup automation..." -ForegroundColor Yellow
    
    # Check if test script exists
    if (Test-Path "test-duplicate-automation.ps1") {
        Write-Host "Running test script..." -ForegroundColor Green
        .\test-duplicate-automation.ps1
    } else {
        Write-Host "Test script not found, creating it..." -ForegroundColor Yellow
        Setup-Automation
        if (Test-Path "test-duplicate-automation.ps1") {
            .\test-duplicate-automation.ps1
        }
    }
}

# Run automated cleanup
function Run-Automation {
    Write-Host "Running automated duplicate cleanup..." -ForegroundColor Yellow
    
    # Check if run script exists
    if (Test-Path "run-duplicate-automation.ps1") {
        Write-Host "Running automation script..." -ForegroundColor Green
        .\run-duplicate-automation.ps1
    } else {
        Write-Host "Run script not found, creating it..." -ForegroundColor Yellow
        Setup-Automation
        if (Test-Path "run-duplicate-automation.ps1") {
            .\run-duplicate-automation.ps1
        }
    }
}

# Main execution
if ($Setup) {
    Setup-Automation
} elseif ($Test) {
    Test-Automation
} elseif ($Run) {
    Run-Automation
} else {
    Write-Host "No action specified. Use -Setup, -Test, or -Run" -ForegroundColor Yellow
    Write-Host "Example: .\automate-duplicate-cleanup.ps1 -Setup" -ForegroundColor Gray
}
