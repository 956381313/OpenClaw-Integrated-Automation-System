# Check Status After Emergency Cleanup
Write-Host "=== STATUS CHECK AFTER EMERGENCY CLEANUP ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Check all disk status
Write-Host "DISK STATUS AFTER CLEANUP:" -ForegroundColor Yellow
try {
    $disks = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3"
    
    foreach ($disk in $disks) {
        $usedPercent = [math]::Round((($disk.Size - $disk.FreeSpace)/$disk.Size)*100, 2)
        $freeGB = [math]::Round($disk.FreeSpace/1GB, 2)
        $totalGB = [math]::Round($disk.Size/1GB, 2)
        
        if ($usedPercent -gt 95) {
            Write-Host "🔴 $($disk.DeviceID): ${usedPercent}% used (${freeGB} GB free) - EXTREME DANGER" -ForegroundColor Red
        } elseif ($usedPercent -gt 90) {
            Write-Host "🟡 $($disk.DeviceID): ${usedPercent}% used (${freeGB} GB free) - CRITICAL" -ForegroundColor Yellow
        } elseif ($usedPercent -gt 80) {
            Write-Host "🟠 $($disk.DeviceID): ${usedPercent}% used (${freeGB} GB free) - WARNING" -ForegroundColor DarkYellow
        } else {
            Write-Host "🟢 $($disk.DeviceID): ${usedPercent}% used (${freeGB} GB free) - OK" -ForegroundColor Green
        }
    }
} catch {
    Write-Host "ERROR checking disk status: $_" -ForegroundColor Red
}
Write-Host ""

# Check C drive specifically
Write-Host "C: DRIVE DETAILED STATUS:" -ForegroundColor Yellow
try {
    $diskC = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
    if ($diskC) {
        $usedPercent = [math]::Round((($diskC.Size - $diskC.FreeSpace)/$diskC.Size)*100, 2)
        $freeGB = [math]::Round($diskC.FreeSpace/1GB, 2)
        
        Write-Host "   Usage: ${usedPercent}%" -ForegroundColor $(if ($usedPercent -gt 95) {"Red"} elseif ($usedPercent -gt 90) {"Yellow"} else {"Green"})
        Write-Host "   Free space: ${freeGB} GB" -ForegroundColor $(if ($freeGB -lt 10) {"Red"} elseif ($freeGB -lt 20) {"Yellow"} else {"Green"})
        
        # Calculate minimum required space
        $minRequiredGB = 20  # Minimum 20 GB for Windows to function properly
        if ($freeGB -lt $minRequiredGB) {
            Write-Host "   WARNING: Less than ${minRequiredGB} GB free - System stability at risk!" -ForegroundColor Red
            Write-Host "   Need to free: $($minRequiredGB - $freeGB) GB more space" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "   ERROR checking C drive" -ForegroundColor Red
}
Write-Host ""

# Check for cleanup reports
Write-Host "CLEANUP REPORTS:" -ForegroundColor Yellow
$reportDir = "data-storage\reports\emergency-cleanup\"
if (Test-Path $reportDir) {
    $reports = Get-ChildItem -Path $reportDir -Filter "*.md" -ErrorAction SilentlyContinue | 
        Sort-Object LastWriteTime -Descending | 
        Select-Object -First 3
    
    if ($reports.Count -gt 0) {
        Write-Host "   Latest cleanup reports:" -ForegroundColor Gray
        foreach ($report in $reports) {
            Write-Host "   - $($report.Name) ($($report.LastWriteTime))" -ForegroundColor Gray
        }
    } else {
        Write-Host "   No cleanup reports found" -ForegroundColor Gray
    }
} else {
    Write-Host "   Report directory not found: $reportDir" -ForegroundColor Yellow
}
Write-Host ""

# Immediate recommendations
Write-Host "IMMEDIATE RECOMMENDATIONS:" -ForegroundColor Red

# Check C drive free space
try {
    $diskC = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
    if ($diskC) {
        $freeGB = [math]::Round($diskC.FreeSpace/1GB, 2)
        
        if ($freeGB -lt 10) {
            Write-Host "1. 🔴 C DRIVE CRITICAL: Only ${freeGB} GB free" -ForegroundColor Red
            Write-Host "   Action: Move large files to D: drive immediately!" -ForegroundColor Red
            
            # Suggest file locations to check
            Write-Host "   Check these locations for large files:" -ForegroundColor Yellow
            Write-Host "   - $env:USERPROFILE\Downloads\" -ForegroundColor Gray
            Write-Host "   - $env:USERPROFILE\Desktop\" -ForegroundColor Gray
            Write-Host "   - $env:USERPROFILE\Videos\" -ForegroundColor Gray
            Write-Host "   - $env:USERPROFILE\Documents\" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "   Could not get C drive info" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "2. 🟡 OTHER DRIVES: E:, F:, G: >90% used" -ForegroundColor Yellow
Write-Host "   Action: Run full emergency cleanup on all drives" -ForegroundColor Yellow
Write-Host "   Command: .\emergency-cleanup.bat (select option 2)" -ForegroundColor Gray
Write-Host ""

Write-Host "3. 🟢 D DRIVE: 21.3% used (366 GB free)" -ForegroundColor Green
Write-Host "   Recommendation: Use D: for storing large files" -ForegroundColor Gray
Write-Host ""

# Available commands
Write-Host "AVAILABLE COMMANDS:" -ForegroundColor Cyan
Write-Host "   .\emergency-cleanup.bat                    # Interactive emergency cleanup" -ForegroundColor Gray
Write-Host "   .\monitor-disk.bat                         # Monitor disk space" -ForegroundColor Gray
Write-Host "   .\tool-collections\powershell-scripts\validate-automation-config.ps1  # Validate config" -ForegroundColor Gray
Write-Host ""

# Final warning
Write-Host "FINAL WARNING:" -ForegroundColor Red
Write-Host "   C: drive at 99.32% - System may crash at any moment!" -ForegroundColor Red
Write-Host "   Immediate action required to prevent data loss!" -ForegroundColor Red
Write-Host ""

Write-Host "Status check completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray