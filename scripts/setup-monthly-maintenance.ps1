# Setup Monthly Maintenance - Complete Cleanup
Write-Host "=== MONTHLY MAINTENANCE SETUP ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# 1. Create monthly maintenance script
Write-Host "1. CREATING MONTHLY MAINTENANCE SCRIPT" -ForegroundColor Yellow
$maintenanceScript = @'
# Monthly Complete Maintenance Script
param(
    [switch]$Preview,
    [switch]$Force,
    [string]$ReportPath = "data-storage\reports\maintenance\"
)

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFile = Join-Path $ReportPath "maintenance-$timestamp.log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    
    $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
    Add-Content -Path $logFile -Value $logEntry -Encoding UTF8
    
    switch ($Level) {
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "WARN"  { Write-Host $logEntry -ForegroundColor Yellow }
        "INFO"  { Write-Host $logEntry -ForegroundColor Gray }
    }
}

Write-Log "=== MONTHLY MAINTENANCE STARTED ==="

try {
    # Step 1: Disk space check
    Write-Log "Step 1: Checking disk space..."
    $disks = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3" | Select-Object DeviceID,
        @{Name="SizeGB";Expression={[math]::Round($_.Size/1GB,2)}},
        @{Name="FreeGB";Expression={[math]::Round($_.FreeSpace/1GB,2)}},
        @{Name="UsedGB";Expression={[math]::Round(($_.Size - $_.FreeSpace)/1GB,2)}},
        @{Name="UsedPercent";Expression={[math]::Round((($_.Size - $_.FreeSpace)/$_.Size)*100,2)}}
    
    Write-Log "Disk space check completed"
    
    # Step 2: Duplicate file cleanup
    Write-Log "Step 2: Running duplicate file cleanup..."
    $dupScript = "tool-collections\powershell-scripts\clean-duplicates-optimized.ps1"
    if (Test-Path $dupScript) {
        if ($Preview) {
            & $dupScript --strategy KeepNewest --preview 2>&1 | Out-Host
            Write-Log "Duplicate cleanup preview completed"
        } else {
            & $dupScript --strategy KeepNewest 2>&1 | Out-Host
            Write-Log "Duplicate cleanup completed"
        }
    } else {
        Write-Log "ERROR: Duplicate cleanup script not found" -Level "ERROR"
    }
    
    # Step 3: Temporary file cleanup
    Write-Log "Step 3: Cleaning temporary files..."
    $tempPatterns = @("*.tmp", "*.temp", "*.bak", "*.log", "Thumbs.db", ".DS_Store", "~*")
    $tempFiles = @()
    
    foreach ($pattern in $tempPatterns) {
        $files = Get-ChildItem -Path "." -Filter $pattern -Recurse -ErrorAction SilentlyContinue
        $tempFiles += $files
    }
    
    if ($tempFiles.Count -gt 0) {
        Write-Log "Found $($tempFiles.Count) temporary files"
        
        if (-not $Preview) {
            $deleted = 0
            foreach ($file in $tempFiles) {
                try {
                    Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
                    $deleted++
                } catch {
                    Write-Log "Failed to delete: $($file.Name)" -Level "WARN"
                }
            }
            Write-Log "Deleted $deleted temporary files"
        }
    } else {
        Write-Log "No temporary files found"
    }
    
    # Step 4: Archive old backups (>30 days)
    Write-Log "Step 4: Archiving old backups..."
    $backupDir = "backup-archive\"
    if (Test-Path $backupDir) {
        $thirtyDaysAgo = (Get-Date).AddDays(-30)
        $oldBackups = Get-ChildItem -Path $backupDir -Directory -ErrorAction SilentlyContinue | 
            Where-Object { $_.CreationTime -lt $thirtyDaysAgo }
        
        if ($oldBackups.Count -gt 0) {
            Write-Log "Found $($oldBackups.Count) old backups (>30 days)"
            
            # Create archive directory
            $archiveDir = Join-Path $backupDir "archived-$(Get-Date -Format 'yyyy-MM')"
            if (-not (Test-Path $archiveDir)) {
                New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
            }
            
            if (-not $Preview) {
                foreach ($backup in $oldBackups) {
                    try {
                        Move-Item -Path $backup.FullName -Destination (Join-Path $archiveDir $backup.Name) -Force -ErrorAction SilentlyContinue
                        Write-Log "Archived: $($backup.Name)"
                    } catch {
                        Write-Log "Failed to archive: $($backup.Name)" -Level "WARN"
                    }
                }
            }
        } else {
            Write-Log "No old backups found"
        }
    }
    
    # Step 5: Clean empty directories
    Write-Log "Step 5: Cleaning empty directories..."
    function Get-EmptyDirectories {
        param([string]$Path)
        
        $emptyDirs = @()
        $dirs = Get-ChildItem -Path $Path -Directory -ErrorAction SilentlyContinue
        
        foreach ($dir in $dirs) {
            $items = Get-ChildItem -Path $dir.FullName -Recurse -ErrorAction SilentlyContinue
            if ($items.Count -eq 0) {
                $emptyDirs += $dir
            } else {
                $subEmpty = Get-EmptyDirectories -Path $dir.FullName
                $emptyDirs += $subEmpty
            }
        }
        
        return $emptyDirs
    }
    
    $emptyDirs = Get-EmptyDirectories -Path "."
    if ($emptyDirs.Count -gt 0) {
        Write-Log "Found $($emptyDirs.Count) empty directories"
        
        if (-not $Preview) {
            $cleaned = 0
            $emptyDirs = $emptyDirs | Sort-Object { $_.FullName.Length } -Descending
            foreach ($dir in $emptyDirs) {
                try {
                    Remove-Item -Path $dir.FullName -Force -Recurse -ErrorAction SilentlyContinue
                    $cleaned++
                } catch {
                    Write-Log "Failed to remove: $($dir.FullName)" -Level "WARN"
                }
            }
            Write-Log "Removed $cleaned empty directories"
        }
    } else {
        Write-Log "No empty directories found"
    }
    
    # Step 6: Generate maintenance report
    Write-Log "Step 6: Generating maintenance report..."
    $reportFile = Join-Path $ReportPath "maintenance-report-$timestamp.md"
    $reportContent = @"
# Monthly Maintenance Report
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Mode: $(if ($Preview) {'Preview'} else {'Execution'})

## Summary
- Disk drives checked: $($disks.Count)
- Temporary files found: $($tempFiles.Count)
- Old backups found: $(if (Test-Path $backupDir) {$oldBackups.Count} else {'N/A'})
- Empty directories found: $($emptyDirs.Count)

## Disk Space Status
$($disks | ForEach-Object { 
    "- $($_.DeviceID): $($_.UsedPercent)% used ($($_.FreeGB) GB free of $($_.SizeGB) GB)" 
} | Out-String)

## Actions Taken
1. Duplicate file cleanup: $(if (Test-Path $dupScript) {'Completed'} else {'Skipped'})
2. Temporary file cleanup: $(if ($tempFiles.Count -gt 0) {"$($tempFiles.Count) files processed"} else {'No files found'})
3. Old backup archiving: $(if (Test-Path $backupDir -and $oldBackups.Count -gt 0) {"$($oldBackups.Count) backups archived"} else {'No old backups'})
4. Empty directory cleanup: $(if ($emptyDirs.Count -gt 0) {"$($emptyDirs.Count) directories processed"} else {'No empty directories'})

## Recommendations
1. Review archived backups in: $(if (Test-Path $backupDir) {$archiveDir} else {'N/A'})
2. Monitor disk space regularly
3. Schedule next maintenance: $(Get-Date).AddMonths(1).ToString('yyyy-MM-dd')

## Log File
Complete log available at: $logFile
"@
    
    $reportContent | Set-Content $reportFile -Encoding UTF8
    Write-Log "Report generated: $reportFile"
    
    Write-Log "=== MONTHLY MAINTENANCE COMPLETED ==="
    
    return @{
        success = $true
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        report_file = $reportFile
        log_file = $logFile
        preview_mode = $Preview
    }
    
} catch {
    Write-Log "ERROR during maintenance: $_" -Level "ERROR"
    return @{
        success = $false
        error = $_.ToString()
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}
'@

$scriptPath = "tool-collections\powershell-scripts\monthly-maintenance.ps1"
$maintenanceScript | Set-Content $scriptPath -Encoding UTF8
Write-Host "   Monthly maintenance script created: $scriptPath" -ForegroundColor Green
Write-Host ""

# 2. Create batch file
Write-Host "2. CREATING BATCH FILE" -ForegroundColor Yellow
$batchContent = @'
@echo off
echo Monthly Maintenance - %DATE% %TIME%
echo.
echo Options:
echo   1. Preview mode (dry run)
echo   2. Execute maintenance
echo   3. Cancel
echo.
set /p choice="Enter choice (1-3): "

cd /d "%~dp0"

if "%choice%"=="1" (
    echo Running in preview mode...
    powershell -ExecutionPolicy Bypass -File "tool-collections\powershell-scripts\monthly-maintenance.ps1" -Preview
) else if "%choice%"=="2" (
    echo Executing monthly maintenance...
    powershell -ExecutionPolicy Bypass -File "tool-collections\powershell-scripts\monthly-maintenance.ps1"
) else (
    echo Maintenance cancelled.
)

pause
'@

$batchPath = "run-monthly-maintenance.bat"
$batchContent | Set-Content $batchPath -Encoding ASCII
Write-Host "   Batch file created: $batchPath" -ForegroundColor Green
Write-Host ""

# 3. Add to automation configuration
Write-Host "3. ADDING TO AUTOMATION CONFIGURATION" -ForegroundColor Yellow
$configPath = "system-core\configuration-files\automation-config-english.json"
if (Test-Path $configPath) {
    try {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
        
        # Check if monthly maintenance already exists
        $monthlyExists = $config.tasks | Where-Object { $_.id -eq "monthly-maintenance" }
        if (-not $monthlyExists) {
            $monthlyTask = @{
                id = "monthly-maintenance"
                name = "OpenClaw-MonthlyMaintenance"
                description = "Monthly complete system maintenance"
                script = "tool-collections\powershell-scripts\monthly-maintenance.ps1"
                schedule = @{
                    kind = "cron"
                    expr = "0 4 1 * *"  # 1st day of month at 04:00
                    tz = "Asia/Shanghai"
                }
                enabled = $true
                parameters = @()
                output = "data-storage\reports\maintenance\"
                notifications = @{
                    email = $true
                    on_completion = $true
                }
            }
            
            $config.tasks += $monthlyTask
            $config | ConvertTo-Json -Depth 10 | Set-Content $configPath -Encoding UTF8
            Write-Host "   Monthly maintenance added to automation configuration" -ForegroundColor Green
        } else {
            Write-Host "   Monthly maintenance already exists in automation configuration" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "   Error updating configuration: $_" -ForegroundColor Red
    }
}
Write-Host ""

# 4. Create maintenance schedule
Write-Host "4. CREATING MAINTENANCE SCHEDULE" -ForegroundColor Yellow
$schedule = @{
    monthly_maintenance = @{
        schedule = "First day of month at 04:00"
        tasks = @(
            "Disk space analysis",
            "Duplicate file cleanup",
            "Temporary file removal",
            "Old backup archiving",
            "Empty directory cleanup",
            "Report generation"
        )
        estimated_duration = "10-15 minutes"
        requires_attention = $false
        email_report = $true
    }
    weekly_cleanup = @{
        schedule = "Every Sunday at 03:00"
        task = "Duplicate file cleanup"
    }
    daily_monitoring = @{
        schedule = "Every hour"
        task = "Disk space monitoring"
    }
}

$schedulePath = "system-core\configuration-files\maintenance-schedule.json"
$schedule | ConvertTo-Json -Depth 5 | Set-Content $schedulePath -Encoding UTF8
Write-Host "   Maintenance schedule saved: $schedulePath" -ForegroundColor Green
Write-Host ""

# 5. Summary
Write-Host "=== MONTHLY MAINTENANCE SETUP SUMMARY ===" -ForegroundColor Cyan
Write-Host "Maintenance script: monthly-maintenance.ps1" -ForegroundColor Gray
Write-Host "Batch file: run-monthly-maintenance.bat" -ForegroundColor Gray
Write-Host "Schedule: First day of month at 04:00" -ForegroundColor Gray
Write-Host "Automation: Added to automation-config-english.json" -ForegroundColor Gray
Write-Host "Schedule file: maintenance-schedule.json" -ForegroundColor Gray
Write-Host ""
Write-Host "Maintenance tasks included:" -ForegroundColor Yellow
Write-Host "  1. Disk space analysis" -ForegroundColor Gray
Write-Host "  2. Duplicate file cleanup" -ForegroundColor Gray
Write-Host "  3. Temporary file removal" -ForegroundColor Gray
Write-Host "  4. Old backup archiving" -ForegroundColor Gray
Write-Host "  5. Empty directory cleanup" -ForegroundColor Gray
Write-Host "  6. Report generation" -ForegroundColor Gray
Write-Host ""
Write-Host "Usage:" -ForegroundColor Yellow
Write-Host "  .\run-monthly-maintenance.bat          # Interactive menu" -ForegroundColor Gray
Write-Host "  .\monthly-maintenance.ps1 -Preview     # Preview mode" -ForegroundColor Gray
Write-Host "  .\monthly-maintenance.ps1              # Execute maintenance" -ForegroundColor Gray
Write-Host ""
Write-Host "Setup completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray