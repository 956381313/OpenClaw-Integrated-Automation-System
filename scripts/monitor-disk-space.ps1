# Monitor Disk Space - Track Usage Improvements
Write-Host "=== DISK SPACE MONITORING ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Get current disk usage
Write-Host "1. CURRENT DISK USAGE" -ForegroundColor Yellow
try {
    $disks = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3" | Select-Object DeviceID, 
        @{Name="SizeGB";Expression={[math]::Round($_.Size/1GB,2)}},
        @{Name="FreeGB";Expression={[math]::Round($_.FreeSpace/1GB,2)}},
        @{Name="UsedGB";Expression={[math]::Round(($_.Size - $_.FreeSpace)/1GB,2)}},
        @{Name="Used%";Expression={[math]::Round((($_.Size - $_.FreeSpace)/$_.Size)*100,2)}}
    
    $disks | Format-Table -AutoSize | Out-Host
    
    # Check critical disks
    $criticalDisks = $disks | Where-Object { $_."Used%" -gt 90 }
    if ($criticalDisks.Count -gt 0) {
        Write-Host "   WARNING: Critical disk usage (>90%):" -ForegroundColor Red
        $criticalDisks | ForEach-Object {
            Write-Host "   - $($_.DeviceID): $($_.Used%)% used ($($_.FreeGB) GB free)" -ForegroundColor Red
        }
    }
    
    # Check warning disks
    $warningDisks = $disks | Where-Object { $_."Used%" -gt 80 -and $_."Used%" -le 90 }
    if ($warningDisks.Count -gt 0) {
        Write-Host "   WARNING: High disk usage (>80%):" -ForegroundColor Yellow
        $warningDisks | ForEach-Object {
            Write-Host "   - $($_.DeviceID): $($_.Used%)% used ($($_.FreeGB) GB free)" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "   Error getting disk info: $_" -ForegroundColor Red
}
Write-Host ""

# Compare with previous cleanup results
Write-Host "2. CLEANUP IMPACT ANALYSIS" -ForegroundColor Yellow
Write-Host "   Previous cleanup results:" -ForegroundColor Gray
Write-Host "   - Duplicate files cleaned: 112 files" -ForegroundColor Gray
Write-Host "   - Space reclaimed: 1.69 MB" -ForegroundColor Gray
Write-Host "   - Backup files created: 33 files" -ForegroundColor Gray
Write-Host ""
Write-Host "   Note: For significant disk space improvement, consider:" -ForegroundColor Gray
Write-Host "   - Large file identification" -ForegroundColor Gray
Write-Host "   - Archive old backups" -ForegroundColor Gray
Write-Host "   - Clean temporary directories" -ForegroundColor Gray
Write-Host ""

# Create disk monitoring configuration
Write-Host "3. CREATING DISK MONITORING CONFIGURATION" -ForegroundColor Yellow
$monitorConfig = @{
    version = "1.0"
    description = "Disk Space Monitoring Configuration"
    created = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    thresholds = @{
        critical = 90
        warning = 80
        normal = 70
    }
    monitoring = @{
        interval_minutes = 60
        report_days = 7
        alert_email = $true
        log_directory = "data-storage\logs\disk-monitor\"
    }
    cleanup_suggestions = @(
        "Delete temporary files (*.tmp, *.bak, *.log)",
        "Clean duplicate files",
        "Archive old backups (>30 days)",
        "Compress log files",
        "Move large files to external storage"
    )
}

$configPath = "system-core\configuration-files\disk-monitor-config.json"
$monitorConfig | ConvertTo-Json -Depth 5 | Set-Content $configPath -Encoding UTF8
Write-Host "   Monitoring configuration saved: $configPath" -ForegroundColor Green
Write-Host ""

# Create disk monitoring script
Write-Host "4. CREATING DISK MONITORING SCRIPT" -ForegroundColor Yellow
$monitorScript = @'
# Disk Space Monitoring Script
param(
    [switch]$AlertOnly,
    [switch]$GenerateReport,
    [string]$LogPath = "data-storage\logs\disk-monitor\"
)

# Create log directory if it doesn't exist
if (-not (Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFile = Join-Path $LogPath "disk-monitor-$timestamp.log"

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

Write-Log "=== DISK SPACE MONITORING STARTED ==="

try {
    # Get disk information
    $disks = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3" | Select-Object DeviceID,
        @{Name="SizeGB";Expression={[math]::Round($_.Size/1GB,2)}},
        @{Name="FreeGB";Expression={[math]::Round($_.FreeSpace/1GB,2)}},
        @{Name="UsedGB";Expression={[math]::Round(($_.Size - $_.FreeSpace)/1GB,2)}},
        @{Name="Used%";Expression={[math]::Round((($_.Size - $_.FreeSpace)/$_.Size)*100,2)}}
    
    Write-Log "Disk information retrieved for $($disks.Count) drives"
    
    # Check thresholds
    $criticalDisks = @()
    $warningDisks = @()
    $normalDisks = @()
    
    foreach ($disk in $disks) {
        if ($disk.'Used%' -gt 90) {
            $criticalDisks += $disk
            Write-Log "CRITICAL: $($disk.DeviceID) - $($disk.'Used%')% used ($($disk.FreeGB) GB free)" -Level "ERROR"
        } elseif ($disk.'Used%' -gt 80) {
            $warningDisks += $disk
            Write-Log "WARNING: $($disk.DeviceID) - $($disk.'Used%')% used ($($disk.FreeGB) GB free)" -Level "WARN"
        } else {
            $normalDisks += $disk
            Write-Log "NORMAL: $($disk.DeviceID) - $($disk.'Used%')% used ($($disk.FreeGB) GB free)" -Level "INFO"
        }
    }
    
    # Generate report if requested
    if ($GenerateReport) {
        $reportFile = Join-Path $LogPath "disk-report-$timestamp.md"
        $reportContent = @"
# Disk Space Monitoring Report
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Summary
- Total drives monitored: $($disks.Count)
- Critical drives (>90%): $($criticalDisks.Count)
- Warning drives (80-90%): $($warningDisks.Count)
- Normal drives (<80%): $($normalDisks.Count)

## Critical Drives
$(
if ($criticalDisks.Count -gt 0) {
    $criticalDisks | ForEach-Object { 
        "- $($_.DeviceID): $($_.'Used%')% used ($($_.FreeGB) GB free of $($_.SizeGB) GB)" 
    }
} else {
    "No critical drives"
}
)

## Warning Drives
$(
if ($warningDisks.Count -gt 0) {
    $warningDisks | ForEach-Object { 
        "- $($_.DeviceID): $($_.'Used%')% used ($($_.FreeGB) GB free of $($_.SizeGB) GB)" 
    }
} else {
    "No warning drives"
}
)

## Recommendations
1. Clean temporary files
2. Archive old backups
3. Run duplicate file cleanup
4. Consider disk cleanup automation

## Next Check
Recommended next check: $(Get-Date).AddHours(1).ToString('yyyy-MM-dd HH:mm:ss')
"@
        
        $reportContent | Set-Content $reportFile -Encoding UTF8
        Write-Log "Report generated: $reportFile"
    }
    
    # Return status
    $status = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        total_drives = $disks.Count
        critical = $criticalDisks.Count
        warning = $warningDisks.Count
        normal = $normalDisks.Count
        log_file = $logFile
    }
    
    return $status
    
} catch {
    Write-Log "Error monitoring disk space: $_" -Level "ERROR"
    throw $_
}

Write-Log "=== DISK SPACE MONITORING COMPLETED ==="
'@

$monitorScriptPath = "tool-collections\powershell-scripts\monitor-disk-space.ps1"
$monitorScript | Set-Content $monitorScriptPath -Encoding UTF8
Write-Host "   Monitoring script created: $monitorScriptPath" -ForegroundColor Green
Write-Host ""

# Create batch file for easy execution
Write-Host "5. CREATING MONITORING BATCH FILE" -ForegroundColor Yellow
$batchContent = @'
@echo off
echo Disk Space Monitor - %DATE% %TIME%
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "tool-collections\powershell-scripts\monitor-disk-space.ps1" -GenerateReport
echo Monitoring completed. Check logs in data-storage\logs\disk-monitor\
pause
'@

$batchPath = "monitor-disk.bat"
$batchContent | Set-Content $batchPath -Encoding ASCII
Write-Host "   Batch file created: $batchPath" -ForegroundColor Green
Write-Host ""

# Add to automation configuration
Write-Host "6. ADDING TO AUTOMATION CONFIGURATION" -ForegroundColor Yellow
$automationConfig = Get-Content "system-core\configuration-files\automation-config-english.json" -Raw | ConvertFrom-Json

# Check if disk monitor already exists
$diskMonitorExists = $automationConfig.tasks | Where-Object { $_.id -eq "disk-monitor" }
if (-not $diskMonitorExists) {
    $diskMonitorTask = @{
        id = "disk-monitor"
        name = "OpenClaw-DiskMonitor"
        description = "Disk space monitoring and alerting"
        script = "tool-collections\powershell-scripts\monitor-disk-space.ps1"
        schedule = @{
            kind = "every"
            everyMs = 3600000  # Every hour
        }
        enabled = $true
        parameters = @("--GenerateReport")
        output = "data-storage\logs\disk-monitor\"
        alerts = @{
            email = $true
            threshold_critical = 90
            threshold_warning = 80
        }
    }
    
    $automationConfig.tasks += $diskMonitorTask
    $automationConfig | ConvertTo-Json -Depth 10 | Set-Content "system-core\configuration-files\automation-config-english.json" -Encoding UTF8
    Write-Host "   Disk monitor added to automation configuration" -ForegroundColor Green
} else {
    Write-Host "   Disk monitor already exists in automation configuration" -ForegroundColor Yellow
}
Write-Host ""

# Summary
Write-Host "=== DISK MONITORING SETUP SUMMARY ===" -ForegroundColor Cyan
Write-Host "Monitoring script: monitor-disk-space.ps1" -ForegroundColor Gray
Write-Host "Batch file: monitor-disk.bat" -ForegroundColor Gray
Write-Host "Configuration: disk-monitor-config.json" -ForegroundColor Gray
Write-Host "Log directory: data-storage\logs\disk-monitor\" -ForegroundColor Gray
Write-Host "Automation: Added to automation-config-english.json" -ForegroundColor Gray
Write-Host ""
Write-Host "Usage:" -ForegroundColor Yellow
Write-Host "  .\monitor-disk.bat                    # Run once with report" -ForegroundColor Gray
Write-Host "  .\monitor-disk-space.ps1 -GenerateReport  # PowerShell version" -ForegroundColor Gray
Write-Host ""
Write-Host "Setup completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray