# Check Emergency Cleanup Progress
Write-Host "=== EMERGENCY CLEANUP PROGRESS CHECK ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Check 1: Current disk status
Write-Host "1. CURRENT DISK STATUS" -ForegroundColor Yellow
try {
    $disks = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3"
    
    foreach ($disk in $disks) {
        $usedPercent = [math]::Round((($disk.Size - $disk.FreeSpace)/$disk.Size)*100, 2)
        $freeGB = [math]::Round($disk.FreeSpace/1GB, 2)
        
        if ($usedPercent -gt 95) {
            Write-Host "   🔴 $($disk.DeviceID): ${usedPercent}% used (${freeGB} GB free) - EXTREME DANGER" -ForegroundColor Red
        } elseif ($usedPercent -gt 90) {
            Write-Host "   🟡 $($disk.DeviceID): ${usedPercent}% used (${freeGB} GB free) - CRITICAL" -ForegroundColor Yellow
        } elseif ($usedPercent -gt 80) {
            Write-Host "   🟠 $($disk.DeviceID): ${usedPercent}% used (${freeGB} GB free) - WARNING" -ForegroundColor DarkYellow
        } else {
            Write-Host "   🟢 $($disk.DeviceID): ${usedPercent}% used (${freeGB} GB free) - OK" -ForegroundColor Green
        }
    }
} catch {
    Write-Host "   ERROR: Could not check disk status" -ForegroundColor Red
}
Write-Host ""

# Check 2: Look for cleanup reports
Write-Host "2. CLEANUP REPORTS" -ForegroundColor Yellow
$reportDir = "data-storage\reports\emergency-cleanup\"
if (Test-Path $reportDir) {
    $reports = Get-ChildItem -Path $reportDir -File -ErrorAction SilentlyContinue | 
        Sort-Object LastWriteTime -Descending
    
    if ($reports.Count -gt 0) {
        Write-Host "   Found $($reports.Count) cleanup reports:" -ForegroundColor Green
        
        $latestReport = $reports[0]
        Write-Host "   Latest report: $($latestReport.Name)" -ForegroundColor Gray
        Write-Host "   Created: $($latestReport.LastWriteTime)" -ForegroundColor Gray
        
        # Show report summary
        try {
            $reportContent = Get-Content $latestReport.FullName -First 20 -ErrorAction SilentlyContinue
            if ($reportContent) {
                Write-Host "   Preview:" -ForegroundColor Gray
                foreach ($line in $reportContent) {
                    if ($line -match "Summary|improvement|deleted|freed") {
                        Write-Host "     $line" -ForegroundColor Gray
                    }
                }
            }
        } catch {
            Write-Host "   Could not read report" -ForegroundColor Yellow
        }
    } else {
        Write-Host "   No cleanup reports found" -ForegroundColor Yellow
    }
} else {
    Write-Host "   Report directory not created yet" -ForegroundColor Yellow
}
Write-Host ""

# Check 3: Look for running cleanup processes
Write-Host "3. RUNNING PROCESSES" -ForegroundColor Yellow
try {
    $cleanupProcesses = Get-Process -Name powershell -ErrorAction SilentlyContinue | 
        Where-Object { $_.MainWindowTitle -match "cleanup|Cleanup|CLEANUP" }
    
    if ($cleanupProcesses.Count -gt 0) {
        Write-Host "   Found $($cleanupProcesses.Count) running cleanup processes:" -ForegroundColor Green
        
        foreach ($process in $cleanupProcesses) {
            Write-Host "   - PID: $($process.Id), Started: $($process.StartTime)" -ForegroundColor Gray
        }
    } else {
        Write-Host "   No cleanup processes currently running" -ForegroundColor Gray
    }
} catch {
    Write-Host "   Could not check running processes" -ForegroundColor Yellow
}
Write-Host ""

# Check 4: Check for cleanup logs
Write-Host "4. CLEANUP LOGS" -ForegroundColor Yellow
$logFiles = @()
$logPatterns = @("*cleanup*.log", "*emergency*.log", "*cleanup*.txt")

foreach ($pattern in $logPatterns) {
    $files = Get-ChildItem -Path . -Filter $pattern -Recurse -ErrorAction SilentlyContinue | 
        Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-1) }
    $logFiles += $files
}

if ($logFiles.Count -gt 0) {
    Write-Host "   Found $($logFiles.Count) recent cleanup logs:" -ForegroundColor Green
    
    foreach ($log in $logFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 3) {
        Write-Host "   - $($log.Name) ($($log.LastWriteTime))" -ForegroundColor Gray
        
        # Show last few lines
        try {
            $logLines = Get-Content $log.FullName -Tail 3 -ErrorAction SilentlyContinue
            if ($logLines) {
                foreach ($line in $logLines) {
                    Write-Host "     $line" -ForegroundColor DarkGray
                }
            }
        } catch {
            # Skip if can't read
        }
    }
} else {
    Write-Host "   No recent cleanup logs found" -ForegroundColor Gray
}
Write-Host ""

# Check 5: Check C drive specifically
Write-Host "5. C: DRIVE DETAILED STATUS" -ForegroundColor Yellow
try {
    $diskC = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
    if ($diskC) {
        $usedPercent = [math]::Round((($diskC.Size - $diskC.FreeSpace)/$diskC.Size)*100, 2)
        $freeGB = [math]::Round($diskC.FreeSpace/1GB, 2)
        
        Write-Host "   Current usage: ${usedPercent}%" -ForegroundColor $(if ($usedPercent -gt 95) {"Red"} elseif ($usedPercent -gt 90) {"Yellow"} else {"Green"})
        Write-Host "   Free space: ${freeGB} GB" -ForegroundColor $(if ($freeGB -lt 10) {"Red"} elseif ($freeGB -lt 20) {"Yellow"} else {"Green"})
        
        # Historical comparison (if we had previous data)
        $previousUsage = 99.32  # From earlier check
        if ($usedPercent -lt $previousUsage) {
            $improvement = $previousUsage - $usedPercent
            Write-Host "   Improvement: ${improvement}% reduction since last check" -ForegroundColor Green
        }
        
        # Check if cleanup is needed
        if ($freeGB -lt 10) {
            Write-Host "   ⚠️  WARNING: Less than 10 GB free - System stability at risk!" -ForegroundColor Red
            Write-Host "   Immediate action required!" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "   Could not check C drive status" -ForegroundColor Red
}
Write-Host ""

# Check 6: Check cleanup script status
Write-Host "6. CLEANUP SCRIPTS STATUS" -ForegroundColor Yellow
$scripts = @(
    @{Name="Emergency Cleanup Script"; Path="tool-collections\powershell-scripts\emergency-disk-cleanup.ps1"},
    @{Name="C Drive Cleanup Script"; Path="clean-c-drive-now.ps1"},
    @{Name="Immediate Execute Script"; Path="execute-now.ps1"},
    @{Name="Emergency Batch File"; Path="emergency-cleanup.bat"}
)

$allExist = $true
foreach ($script in $scripts) {
    if (Test-Path $script.Path) {
        Write-Host "   ✅ $($script.Name): Available" -ForegroundColor Green
    } else {
        Write-Host "   ❌ $($script.Name): Missing" -ForegroundColor Red
        $allExist = $false
    }
}

if ($allExist) {
    Write-Host "   All cleanup scripts are available" -ForegroundColor Green
} else {
    Write-Host "   Some cleanup scripts are missing" -ForegroundColor Red
}
Write-Host ""

# Summary
Write-Host "=== PROGRESS SUMMARY ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Determine overall status
try {
    $diskC = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
    if ($diskC) {
        $usedPercent = [math]::Round((($diskC.Size - $diskC.FreeSpace)/$diskC.Size)*100, 2)
        
        if ($usedPercent -ge 99) {
            Write-Host "🔴 STATUS: CRITICAL - C drive at ${usedPercent}%" -ForegroundColor Red
            Write-Host "   Emergency cleanup may have failed or not completed" -ForegroundColor Red
        } elseif ($usedPercent -ge 95) {
            Write-Host "🟡 STATUS: CRITICAL - C drive at ${usedPercent}%" -ForegroundColor Yellow
            Write-Host "   Cleanup may be in progress or partial" -ForegroundColor Yellow
        } else {
            Write-Host "🟢 STATUS: IMPROVING - C drive at ${usedPercent}%" -ForegroundColor Green
            Write-Host "   Cleanup appears to be working" -ForegroundColor Green
        }
    }
} catch {
    Write-Host "⚠️  STATUS: UNKNOWN - Could not determine disk status" -ForegroundColor Yellow
}
Write-Host ""

# Recommendations
Write-Host "RECOMMENDATIONS:" -ForegroundColor Yellow

if (Test-Path $reportDir) {
    $reports = Get-ChildItem -Path $reportDir -File -ErrorAction SilentlyContinue
    if ($reports.Count -eq 0) {
        Write-Host "1. Run emergency cleanup to generate reports" -ForegroundColor Red
        Write-Host "   Command: .\emergency-cleanup.bat" -ForegroundColor Gray
    }
} else {
    Write-Host "1. Emergency cleanup system not yet fully initialized" -ForegroundColor Yellow
    Write-Host "   Run: .\clean-c-drive-now.ps1" -ForegroundColor Gray
}

Write-Host "2. Check C drive free space regularly" -ForegroundColor Gray
Write-Host "   Command: .\check-status-after-cleanup.ps1" -ForegroundColor Gray
Write-Host ""

Write-Host "3. If cleanup appears stuck, restart and run:" -ForegroundColor Gray
Write-Host "   .\run-emergency-now.bat" -ForegroundColor Gray
Write-Host ""

Write-Host "Progress check completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray