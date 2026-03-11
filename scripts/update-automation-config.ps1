# Update Automation Configuration with Optimized Settings
Write-Host "=== UPDATING AUTOMATION CONFIGURATION ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

$configPath = "system-core\configuration-files\automation-config-english.json"

if (Test-Path $configPath) {
    Write-Host "1. READING CURRENT CONFIGURATION" -ForegroundColor Yellow
    try {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
        Write-Host "   Current version: $($config.version)" -ForegroundColor Green
        Write-Host "   Tasks: $($config.tasks.Count)" -ForegroundColor Gray
        
        # Backup current configuration
        $backupPath = "system-core\configuration-files\automation-config-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
        $config | ConvertTo-Json -Depth 10 | Set-Content $backupPath -Encoding UTF8
        Write-Host "   Backup created: $backupPath" -ForegroundColor Green
        Write-Host ""
        
        # 2. Update monitoring thresholds
        Write-Host "2. UPDATING MONITORING THRESHOLDS" -ForegroundColor Yellow
        $currentThreshold = $config.monitoring.disk_threshold
        Write-Host "   Current disk threshold: ${currentThreshold}%" -ForegroundColor Gray
        
        # Create enhanced monitoring configuration
        $config.monitoring = @{
            disk_threshold_critical = 90
            disk_threshold_warning = 85
            memory_threshold_critical = 90
            memory_threshold_warning = 80
            emergency_cleanup_threshold = 95
            log_retention = 30
            report_retention = 90
            auto_cleanup_enabled = $true
        }
        
        Write-Host "   Updated thresholds:" -ForegroundColor Green
        Write-Host "   - Disk critical: 90%" -ForegroundColor Gray
        Write-Host "   - Disk warning: 85%" -ForegroundColor Gray
        Write-Host "   - Emergency cleanup: 95%" -ForegroundColor Gray
        Write-Host "   - Auto cleanup: Enabled" -ForegroundColor Gray
        Write-Host ""
        
        # 3. Add emergency cleanup task
        Write-Host "3. ADDING EMERGENCY CLEANUP TASK" -ForegroundColor Yellow
        
        # Check if emergency task already exists
        $emergencyExists = $config.tasks | Where-Object { $_.id -eq "emergency-cleanup" }
        if (-not $emergencyExists) {
            $emergencyTask = @{
                id = "emergency-cleanup"
                name = "OpenClaw-EmergencyCleanup"
                description = "Emergency disk cleanup for critical space situations"
                script = "tool-collections\powershell-scripts\emergency-disk-cleanup.ps1"
                trigger = "manual"  # Manual trigger only for safety
                enabled = $true
                parameters = @{
                    threshold = 90
                    preview_first = $true
                }
                notifications = @{
                    email = $true
                    immediate = $true
                }
                safety = @{
                    require_confirmation = $true
                    backup_before_delete = $true
                    max_deletion_per_run = "10GB"
                }
            }
            
            $config.tasks += $emergencyTask
            Write-Host "   Emergency cleanup task added" -ForegroundColor Green
        } else {
            Write-Host "   Emergency cleanup task already exists" -ForegroundColor Yellow
        }
        Write-Host ""
        
        # 4. Standardize task parameters
        Write-Host "4. STANDARDIZING TASK PARAMETERS" -ForegroundColor Yellow
        $updatedTasks = 0
        
        foreach ($task in $config.tasks) {
            # Convert array parameters to object format where needed
            if ($task.parameters -is [array]) {
                $originalParams = $task.parameters
                
                # Convert based on task type
                switch ($task.id) {
                    "duplicate-cleanup" {
                        $task.parameters = @{
                            strategy = "KeepNewest"
                            preview_first = $true
                            email_report = $true
                            backup = $true
                        }
                    }
                    "organization-cleanup" {
                        $task.parameters = @{
                            english = $true
                            report_chinese = $true
                            quick_mode = $false
                        }
                    }
                    "backup-system" {
                        $task.parameters = @{
                            silent = $true
                            email = $true
                            compression = $true
                        }
                    }
                    "security-check" {
                        $task.parameters = @{
                            full = $true
                            report = $true
                            fix_issues = $false
                        }
                    }
                    default {
                        # Keep as array for unknown tasks
                        $task.parameters = $originalParams
                    }
                }
                
                $updatedTasks++
                Write-Host "   Updated parameters for: $($task.id)" -ForegroundColor Gray
            }
        }
        
        Write-Host "   Standardized parameters for $updatedTasks tasks" -ForegroundColor Green
        Write-Host ""
        
        # 5. Add task dependencies
        Write-Host "5. ADDING TASK DEPENDENCIES" -ForegroundColor Yellow
        
        # Add dependencies property to tasks
        foreach ($task in $config.tasks) {
            if (-not $task.dependencies) {
                $task.dependencies = @()
            }
        }
        
        # Set specific dependencies
        $monthlyTask = $config.tasks | Where-Object { $_.id -eq "monthly-maintenance" }
        if ($monthlyTask) {
            $monthlyTask.dependencies = @("duplicate-cleanup", "organization-cleanup", "backup-system")
            Write-Host "   Monthly maintenance depends on: duplicate-cleanup, organization-cleanup, backup-system" -ForegroundColor Gray
        }
        
        Write-Host "   Task dependencies configured" -ForegroundColor Green
        Write-Host ""
        
        # 6. Add error handling configuration
        Write-Host "6. ADDING ERROR HANDLING CONFIGURATION" -ForegroundColor Yellow
        
        foreach ($task in $config.tasks) {
            if (-not $task.error_handling) {
                $task.error_handling = @{
                    max_retries = 3
                    retry_delay_seconds = 60
                    notify_on_failure = $true
                    stop_on_critical = $false
                }
            }
        }
        
        Write-Host "   Error handling added to all tasks" -ForegroundColor Green
        Write-Host ""
        
        # 7. Update version and metadata
        Write-Host "7. UPDATING VERSION AND METADATA" -ForegroundColor Yellow
        $config.version = "2.1"
        $config.last_updated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $config.optimizations = @{
            applied = @(
                "Enhanced monitoring thresholds",
                "Added emergency cleanup task",
                "Standardized task parameters",
                "Added task dependencies",
                "Added error handling"
            )
            timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        Write-Host "   Version updated to: $($config.version)" -ForegroundColor Green
        Write-Host ""
        
        # 8. Save updated configuration
        Write-Host "8. SAVING UPDATED CONFIGURATION" -ForegroundColor Yellow
        $config | ConvertTo-Json -Depth 10 | Set-Content $configPath -Encoding UTF8
        Write-Host "   Configuration saved: $configPath" -ForegroundColor Green
        Write-Host ""
        
        # 9. Create validation script
        Write-Host "9. CREATING CONFIGURATION VALIDATION SCRIPT" -ForegroundColor Yellow
        $validationScript = @'
# Automation Configuration Validation Script
param([string]$ConfigPath = "system-core\configuration-files\automation-config-english.json")

Write-Host "=== AUTOMATION CONFIGURATION VALIDATION ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

if (-not (Test-Path $ConfigPath)) {
    Write-Host "ERROR: Configuration file not found: $ConfigPath" -ForegroundColor Red
    exit 1
}

try {
    $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    
    # Validation 1: Check required fields
    Write-Host "1. CHECKING REQUIRED FIELDS" -ForegroundColor Yellow
    $requiredFields = @("version", "description", "tasks")
    $missingFields = @()
    
    foreach ($field in $requiredFields) {
        if (-not $config.$field) {
            $missingFields += $field
        }
    }
    
    if ($missingFields.Count -eq 0) {
        Write-Host "   [OK] All required fields present" -ForegroundColor Green
    } else {
        Write-Host "   [ERROR] Missing fields: $($missingFields -join ', ')" -ForegroundColor Red
    }
    
    # Validation 2: Check tasks
    Write-Host "2. CHECKING TASKS" -ForegroundColor Yellow
    if ($config.tasks.Count -gt 0) {
        Write-Host "   [OK] $($config.tasks.Count) tasks found" -ForegroundColor Green
        
        $invalidTasks = @()
        foreach ($task in $config.tasks) {
            if (-not $task.id -or -not $task.name -or -not $task.script) {
                $invalidTasks += $task.id
            }
        }
        
        if ($invalidTasks.Count -eq 0) {
            Write-Host "   [OK] All tasks have required fields" -ForegroundColor Green
        } else {
            Write-Host "   [ERROR] Invalid tasks: $($invalidTasks -join ', ')" -ForegroundColor Red
        }
    } else {
        Write-Host "   [ERROR] No tasks found" -ForegroundColor Red
    }
    
    # Validation 3: Check monitoring thresholds
    Write-Host "3. CHECKING MONITORING THRESHOLDS" -ForegroundColor Yellow
    if ($config.monitoring) {
        $thresholds = @("disk_threshold_critical", "disk_threshold_warning")
        $missingThresholds = @()
        
        foreach ($threshold in $thresholds) {
            if (-not $config.monitoring.$threshold) {
                $missingThresholds += $threshold
            }
        }
        
        if ($missingThresholds.Count -eq 0) {
            Write-Host "   [OK] Monitoring thresholds configured" -ForegroundColor Green
            Write-Host "     Critical: $($config.monitoring.disk_threshold_critical)%" -ForegroundColor Gray
            Write-Host "     Warning: $($config.monitoring.disk_threshold_warning)%" -ForegroundColor Gray
        } else {
            Write-Host "   [WARNING] Missing thresholds: $($missingThresholds -join ', ')" -ForegroundColor Yellow
        }
    } else {
        Write-Host "   [WARNING] No monitoring configuration" -ForegroundColor Yellow
    }
    
    # Validation 4: Check script files exist
    Write-Host "4. CHECKING SCRIPT FILES" -ForegroundColor Yellow
    $missingScripts = @()
    
    foreach ($task in $config.tasks) {
        if ($task.script -and -not (Test-Path $task.script)) {
            $missingScripts += "$($task.id): $($task.script)"
        }
    }
    
    if ($missingScripts.Count -eq 0) {
        Write-Host "   [OK] All script files exist" -ForegroundColor Green
    } else {
        Write-Host "   [ERROR] Missing script files:" -ForegroundColor Red
        foreach ($missing in $missingScripts) {
            Write-Host "     - $missing" -ForegroundColor Red
        }
    }
    
    # Summary
    Write-Host ""
    Write-Host "=== VALIDATION SUMMARY ===" -ForegroundColor Cyan
    Write-Host "Configuration: $ConfigPath" -ForegroundColor Gray
    Write-Host "Version: $($config.version)" -ForegroundColor Gray
    Write-Host "Tasks: $($config.tasks.Count)" -ForegroundColor Gray
    Write-Host "Status: $(if ($missingFields.Count -eq 0 -and $invalidTasks.Count -eq 0 -and $missingScripts.Count -eq 0) {'VALID'} else {'INVALID'})" -ForegroundColor $(if ($missingFields.Count -eq 0 -and $invalidTasks.Count -eq 0 -and $missingScripts.Count -eq 0) {"Green"} else {"Red"})
    
    return @{
        valid = ($missingFields.Count -eq 0 -and $invalidTasks.Count -eq 0 -and $missingScripts.Count -eq 0)
        errors = @($missingFields + $invalidTasks + $missingScripts)
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
} catch {
    Write-Host "ERROR: Failed to validate configuration: $_" -ForegroundColor Red
    return @{
        valid = $false
        error = $_.ToString()
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}
'@

        $validationPath = "tool-collections\powershell-scripts\validate-automation-config.ps1"
        $validationScript | Set-Content $validationPath -Encoding UTF8
        Write-Host "   Validation script created: $validationPath" -ForegroundColor Green
        Write-Host ""
        
        # 10. Summary
        Write-Host "=== UPDATE SUMMARY ===" -ForegroundColor Cyan
        Write-Host "Configuration updated successfully" -ForegroundColor Green
        Write-Host "Version: 2.0 → 2.1" -ForegroundColor Gray
        Write-Host "Tasks: $($config.tasks.Count) (added emergency-cleanup)" -ForegroundColor Gray
        Write-Host "Monitoring thresholds optimized" -ForegroundColor Gray
        Write-Host "Task parameters standardized" -ForegroundColor Gray
        Write-Host "Dependencies configured" -ForegroundColor Gray
        Write-Host "Error handling added" -ForegroundColor Gray
        Write-Host "Validation script created" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Backup saved: $backupPath" -ForegroundColor Gray
        Write-Host "Updated config: $configPath" -ForegroundColor Gray
        Write-Host ""
        Write-Host "To validate configuration:" -ForegroundColor Yellow
        Write-Host "  .\$validationPath" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Update completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
        
    } catch {
        Write-Host "ERROR: Failed to update configuration: $_" -ForegroundColor Red
    }
} else {
    Write-Host "ERROR: Configuration file not found: $configPath" -ForegroundColor Red
}