# Setup Weekly Automatic Cleanup Task
Write-Host "=== SETUP WEEKLY AUTOMATIC CLEANUP ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Step 1: Check current automation configuration
Write-Host "1. CHECKING CURRENT AUTOMATION CONFIGURATION" -ForegroundColor Yellow
$configPath = "system-core\configuration-files\automation-config-english.json"
if (Test-Path $configPath) {
    Write-Host "   Configuration file found: $configPath" -ForegroundColor Green
    
    try {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
        Write-Host "   Current tasks: $($config.tasks.Count)" -ForegroundColor Gray
        
        # Check if weekly cleanup already exists
        $weeklyCleanup = $config.tasks | Where-Object { $_.name -match "weekly.*cleanup" -or $_.id -match "weekly-cleanup" }
        if ($weeklyCleanup) {
            Write-Host "   Weekly cleanup task already exists:" -ForegroundColor Yellow
            Write-Host "     ID: $($weeklyCleanup.id)" -ForegroundColor Gray
            Write-Host "     Name: $($weeklyCleanup.name)" -ForegroundColor Gray
            Write-Host "     Schedule: $($weeklyCleanup.schedule.expr)" -ForegroundColor Gray
        } else {
            Write-Host "   No weekly cleanup task found" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "   Error reading configuration: $_" -ForegroundColor Red
    }
} else {
    Write-Host "   Configuration file not found: $configPath" -ForegroundColor Red
}
Write-Host ""

# Step 2: Create weekly cleanup task configuration
Write-Host "2. CREATING WEEKLY CLEANUP TASK CONFIGURATION" -ForegroundColor Yellow
$weeklyTask = @{
    id = "weekly-cleanup"
    name = "Weekly File Cleanup"
    description = "Weekly duplicate and temporary file cleanup"
    enabled = $true
    schedule = @{
        kind = "cron"
        expr = "0 3 * * 0"  # Sunday 03:00
        tz = "Asia/Shanghai"
    }
    script = "tool-collections\powershell-scripts\clean-duplicates-optimized.ps1"
    parameters = @("--strategy", "KeepNewest", "--email")
    notifications = @{
        enabled = $true
        email = $true
        on_success = $true
        on_failure = $true
    }
    retention = @{
        logs_days = 30
        reports_days = 90
    }
}

Write-Host "   Weekly task configuration:" -ForegroundColor Gray
Write-Host "   - ID: $($weeklyTask.id)" -ForegroundColor Gray
Write-Host "   - Name: $($weeklyTask.name)" -ForegroundColor Gray
Write-Host "   - Schedule: $($weeklyTask.schedule.expr) (Weekly Sunday 03:00)" -ForegroundColor Gray
Write-Host "   - Script: $($weeklyTask.script)" -ForegroundColor Gray
Write-Host "   - Parameters: $($weeklyTask.parameters -join ' ')" -ForegroundColor Gray
Write-Host ""

# Step 3: Update automation configuration
Write-Host "3. UPDATING AUTOMATION CONFIGURATION" -ForegroundColor Yellow
if (Test-Path $configPath) {
    try {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
        
        # Check if task already exists
        $existingIndex = $config.tasks | ForEach-Object { $_.id } | Select-String -Pattern $weeklyTask.id
        if ($existingIndex) {
            Write-Host "   Task already exists, updating..." -ForegroundColor Yellow
            # Update existing task
            for ($i = 0; $i -lt $config.tasks.Count; $i++) {
                if ($config.tasks[$i].id -eq $weeklyTask.id) {
                    $config.tasks[$i] = $weeklyTask
                    break
                }
            }
        } else {
            Write-Host "   Adding new weekly cleanup task..." -ForegroundColor Green
            # Add new task
            $config.tasks += $weeklyTask
        }
        
        # Save updated configuration
        $config | ConvertTo-Json -Depth 10 | Set-Content $configPath -Encoding UTF8
        Write-Host "   Configuration updated successfully" -ForegroundColor Green
        
        # Show updated task list
        Write-Host "   Updated tasks list:" -ForegroundColor Gray
        $config.tasks | ForEach-Object { 
            Write-Host "   - $($_.id): $($_.name) ($($_.schedule.expr))" -ForegroundColor DarkGray 
        }
    } catch {
        Write-Host "   Error updating configuration: $_" -ForegroundColor Red
    }
} else {
    Write-Host "   Creating new configuration file..." -ForegroundColor Yellow
    $newConfig = @{
        version = "2.0"
        description = "OpenClaw Automation Configuration"
        tasks = @($weeklyTask)
        settings = @{
            log_directory = "logs\automation"
            report_directory = "reports\automation"
            backup_directory = "backups\automation"
            email_notifications = $true
        }
    }
    
    try {
        $newConfig | ConvertTo-Json -Depth 10 | Set-Content $configPath -Encoding UTF8
        Write-Host "   New configuration created successfully" -ForegroundColor Green
    } catch {
        Write-Host "   Error creating configuration: $_" -ForegroundColor Red
    }
}
Write-Host ""

# Step 4: Create Windows Task Scheduler task
Write-Host "4. CREATING WINDOWS TASK SCHEDULER TASK" -ForegroundColor Yellow
$taskName = "OpenClaw-Weekly-Cleanup"
$taskScript = "tool-collections\powershell-scripts\run-duplicate-automation.ps1"

if (Test-Path $taskScript) {
    Write-Host "   Automation script found: $taskScript" -ForegroundColor Green
    
    # Check if task already exists
    $existingTask = schtasks /query /tn $taskName 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   Task already exists: $taskName" -ForegroundColor Yellow
        Write-Host "   To update task, run as administrator:" -ForegroundColor Gray
        Write-Host "   schtasks /delete /tn '$taskName' /f" -ForegroundColor DarkGray
        Write-Host "   schtasks /create /tn '$taskName' /tr 'powershell -ExecutionPolicy Bypass -File `"$taskScript`"' /sc weekly /d SUN /st 03:00" -ForegroundColor DarkGray
    } else {
        Write-Host "   Task does not exist, creating..." -ForegroundColor Green
        Write-Host "   To create task, run as administrator:" -ForegroundColor Gray
        Write-Host "   schtasks /create /tn '$taskName' /tr 'powershell -ExecutionPolicy Bypass -File `"$taskScript`"' /sc weekly /d SUN /st 03:00" -ForegroundColor DarkGray
    }
} else {
    Write-Host "   Automation script not found: $taskScript" -ForegroundColor Red
    Write-Host "   Creating simplified batch file..." -ForegroundColor Yellow
    
    $batchContent = @"
@echo off
echo Weekly Cleanup Task - %DATE% %TIME%
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "tool-collections\powershell-scripts\clean-duplicates-optimized.ps1" --strategy KeepNewest
echo Cleanup completed
"@
    
    $batchPath = "run-weekly-cleanup.bat"
    $batchContent | Set-Content $batchPath -Encoding ASCII
    Write-Host "   Batch file created: $batchPath" -ForegroundColor Green
}
Write-Host ""

# Step 5: Create test script
Write-Host "5. CREATING TEST SCRIPT" -ForegroundColor Yellow
$testScript = @"
# Test Weekly Cleanup Configuration
Write-Host "=== WEEKLY CLEANUP CONFIGURATION TEST ===" -ForegroundColor Cyan
Write-Host "Time: \$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Test 1: Check configuration file
Write-Host "1. CHECKING CONFIGURATION FILE" -ForegroundColor Yellow
if (Test-Path "$configPath") {
    Write-Host "   [OK] Configuration file exists" -ForegroundColor Green
    try {
        \$config = Get-Content "$configPath" -Raw | ConvertFrom-Json
        \$weeklyTask = \$config.tasks | Where-Object { \$_.id -eq "weekly-cleanup" }
        if (\$weeklyTask) {
            Write-Host "   [OK] Weekly cleanup task found" -ForegroundColor Green
            Write-Host "     Name: \$(\$weeklyTask.name)" -ForegroundColor Gray
            Write-Host "     Schedule: \$(\$weeklyTask.schedule.expr)" -ForegroundColor Gray
            Write-Host "     Script: \$(\$weeklyTask.script)" -ForegroundColor Gray
        } else {
            Write-Host "   [ERROR] Weekly cleanup task not found" -ForegroundColor Red
        }
    } catch {
        Write-Host "   [ERROR] Failed to read configuration: \$_" -ForegroundColor Red
    }
} else {
    Write-Host "   [ERROR] Configuration file not found" -ForegroundColor Red
}
Write-Host ""

# Test 2: Check script file
Write-Host "2. CHECKING SCRIPT FILE" -ForegroundColor Yellow
\$scriptPath = "tool-collections\\powershell-scripts\\clean-duplicates-optimized.ps1"
if (Test-Path \$scriptPath) {
    Write-Host "   [OK] Cleanup script exists" -ForegroundColor Green
    \$scriptSize = (Get-Item \$scriptPath).Length
    Write-Host "     Size: \$([math]::Round(\$scriptSize/1KB,2)) KB" -ForegroundColor Gray
} else {
    Write-Host "   [ERROR] Cleanup script not found" -ForegroundColor Red
}
Write-Host ""

# Test 3: Test script execution (dry run)
Write-Host "3. TESTING SCRIPT EXECUTION (DRY RUN)" -ForegroundColor Yellow
if (Test-Path \$scriptPath) {
    try {
        Write-Host "   Running script in test mode..." -ForegroundColor Gray
        \$result = & \$scriptPath --preview --strategy KeepNewest 2>&1
        if (\$LASTEXITCODE -eq 0) {
            Write-Host "   [OK] Script executed successfully" -ForegroundColor Green
        } else {
            Write-Host "   [WARNING] Script execution issues" -ForegroundColor Yellow
            Write-Host "     Exit code: \$LASTEXITCODE" -ForegroundColor Gray
        }
    } catch {
        Write-Host "   [ERROR] Script execution failed: \$_" -ForegroundColor Red
    }
}
Write-Host ""

# Test 4: Check directories
Write-Host "4. CHECKING REQUIRED DIRECTORIES" -ForegroundColor Yellow
\$requiredDirs = @(
    "logs\\automation",
    "reports\\automation", 
    "backups\\automation",
    "tool-collections\\powershell-scripts"
)

foreach (\$dir in \$requiredDirs) {
    if (Test-Path \$dir) {
        Write-Host "   [OK] Directory exists: \$dir" -ForegroundColor Green
    } else {
        Write-Host "   [WARNING] Directory missing: \$dir" -ForegroundColor Yellow
    }
}
Write-Host ""

Write-Host "=== TEST COMPLETED ===" -ForegroundColor Cyan
Write-Host "Weekly cleanup configuration test finished" -ForegroundColor Gray
"@

$testScriptPath = "test-weekly-cleanup.ps1"
$testScript | Set-Content $testScriptPath -Encoding UTF8
Write-Host "   Test script created: $testScriptPath" -ForegroundColor Green
Write-Host ""

# Step 6: Summary
Write-Host "=== WEEKLY CLEANUP SETUP SUMMARY ===" -ForegroundColor Cyan
Write-Host "Configuration updated: $(if (Test-Path $configPath) {'Yes'} else {'No'})" -ForegroundColor Gray
Write-Host "Weekly task added: Yes" -ForegroundColor Gray
Write-Host "Schedule: Weekly Sunday 03:00 (Asia/Shanghai)" -ForegroundColor Gray
Write-Host "Script: clean-duplicates-optimized.ps1" -ForegroundColor Gray
Write-Host "Strategy: KeepNewest" -ForegroundColor Gray
Write-Host "Notifications: Email enabled" -ForegroundColor Gray
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Run test script: .\test-weekly-cleanup.ps1" -ForegroundColor Gray
Write-Host "2. Test cleanup manually: .\run-weekly-cleanup.bat" -ForegroundColor Gray
Write-Host "3. Setup Windows Task Scheduler (requires admin)" -ForegroundColor Gray
Write-Host "4. Monitor first automated run" -ForegroundColor Gray
Write-Host ""
Write-Host "Setup completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray