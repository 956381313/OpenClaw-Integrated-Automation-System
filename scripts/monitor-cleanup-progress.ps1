# Monitor Cleanup Progress in Real-time
Write-Host "=== REAL-TIME CLEANUP PROGRESS MONITOR ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Check if cleanup is running
Write-Host "1. CHECKING RUNNING CLEANUP PROCESSES" -ForegroundColor Yellow
$cleanupProcesses = Get-Process -Name powershell -ErrorAction SilentlyContinue | 
    Where-Object { $_.MainWindowTitle -match "cleanup|Cleanup|CLEANUP" -or $_.CommandLine -match "cleanup" }

if ($cleanupProcesses.Count -gt 0) {
    Write-Host "   Cleanup is running: $($cleanupProcesses.Count) process(es)" -ForegroundColor Green
    
    foreach ($process in $cleanupProcesses) {
        $runtime = (Get-Date) - $process.StartTime
        $runtimeMinutes = [math]::Round($runtime.TotalMinutes, 1)
        Write-Host "   - PID: $($process.Id), Running: ${runtimeMinutes} minutes" -ForegroundColor Gray
    }
} else {
    Write-Host "   No cleanup processes currently running" -ForegroundColor Yellow
}
Write-Host ""

# Check C drive space in real-time
Write-Host "2. REAL-TIME C: DRIVE STATUS" -ForegroundColor Yellow
try {
    $diskC = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
    if ($diskC) {
        $usedPercent = [math]::Round((($diskC.Size - $disk.FreeSpace)/$disk.Size)*100, 2)
        $freeGB = [math]::Round($disk.FreeSpace/1GB, 2)
        $totalGB = [math]::Round($disk.Size/1GB, 2)
        
        Write-Host "   Current usage: ${usedPercent}%" -ForegroundColor $(if ($usedPercent -gt 95) {"Red"} elseif ($usedPercent -gt 90) {"Yellow"} else {"Green"})
        Write-Host "   Free space: ${freeGB} GB of ${totalGB} GB" -ForegroundColor $(if ($freeGB -lt 10) {"Red"} elseif ($freeGB -lt 20) {"Yellow"} else {"Green"})
        
        # Historical comparison
        $previousFreeGB = 4.29  # From earlier check at 02:57
        if ($freeGB -gt $previousFreeGB) {
            $improvement = [math]::Round($freeGB - $previousFreeGB, 2)
            Write-Host "   Improvement since 02:57: +${improvement} GB" -ForegroundColor Green
        }
        
        if ($freeGB -lt 10) {
            Write-Host "   ⚠️  WARNING: Less than 10 GB free!" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "   Could not check C drive status" -ForegroundColor Red
}
Write-Host ""

# Check for cleanup logs
Write-Host "3. CLEANUP LOGS AND REPORTS" -ForegroundColor Yellow
$logDir = "data-storage\reports\emergency-cleanup\"
if (Test-Path $logDir) {
    $reports = Get-ChildItem -Path $logDir -File -ErrorAction SilentlyContinue | 
        Sort-Object LastWriteTime -Descending
    
    if ($reports.Count -gt 0) {
        Write-Host "   Found $($reports.Count) cleanup reports" -ForegroundColor Green
        
        $latestReport = $reports[0]
        $reportAge = (Get-Date) - $latestReport.LastWriteTime
        $reportAgeMinutes = [math]::Round($reportAge.TotalMinutes, 1)
        
        Write-Host "   Latest report: $($latestReport.Name)" -ForegroundColor Gray
        Write-Host "   Age: ${reportAgeMinutes} minutes ago" -ForegroundColor Gray
        
        # Show key info from report
        try {
            $reportLines = Get-Content $latestReport.FullName -First 15 -ErrorAction SilentlyContinue
            if ($reportLines) {
                Write-Host "   Key findings:" -ForegroundColor Gray
                foreach ($line in $reportLines) {
                    if ($line -match "freed|deleted|improvement|GB|MB") {
                        Write-Host "     $line" -ForegroundColor DarkGray
                    }
                }
            }
        } catch {
            # Skip if can't read
        }
    } else {
        Write-Host "   No cleanup reports found" -ForegroundColor Yellow
    }
} else {
    Write-Host "   Report directory not found" -ForegroundColor Yellow
}
Write-Host ""

# Check temporary file count
Write-Host "4. TEMPORARY FILE COUNT (C: DRIVE)" -ForegroundColor Yellow
try {
    $tempPatterns = @("*.tmp", "*.temp", "*.bak", "*.log")
    $tempFileCount = 0
    
    foreach ($pattern in $tempPatterns) {
        $files = Get-ChildItem -Path "C:\" -Filter $pattern -Recurse -ErrorAction SilentlyContinue | 
            Where-Object { $_.FullName -notmatch "Windows\\" } |
            Select-Object -First 100
        $tempFileCount += $files.Count
    }
    
    Write-Host "   Estimated temp files remaining: ${tempFileCount}" -ForegroundColor $(if ($tempFileCount -gt 0) {"Yellow"} else {"Green"})
    
    if ($tempFileCount -gt 0) {
        Write-Host "   More cleanup possible" -ForegroundColor Gray
    } else {
        Write-Host "   Temp files cleaned up" -ForegroundColor Green
    }
} catch {
    Write-Host "   Could not check temp files" -ForegroundColor Yellow
}
Write-Host ""

# Summary and recommendations
Write-Host "=== PROGRESS SUMMARY ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Determine overall progress
try {
    $diskC = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
    if ($diskC) {
        $freeGB = [math]::Round($disk.FreeSpace/1GB, 2)
        
        if ($freeGB -lt 5) {
            Write-Host "🔴 STATUS: EXTREME DANGER - ${freeGB} GB free" -ForegroundColor Red
            Write-Host "   System crash imminent!" -ForegroundColor Red
        } elseif ($freeGB -lt 10) {
            Write-Host "🟡 STATUS: CRITICAL - ${freeGB} GB free" -ForegroundColor Yellow
            Write-Host "   Immediate action required" -ForegroundColor Yellow
        } elseif ($freeGB -lt 20) {
            Write-Host "🟠 STATUS: WARNING - ${freeGB} GB free" -ForegroundColor DarkYellow
            Write-Host "   Monitor closely" -ForegroundColor DarkYellow
        } else {
            Write-Host "🟢 STATUS: OK - ${freeGB} GB free" -ForegroundColor Green
            Write-Host "   System stable" -ForegroundColor Green
        }
    }
} catch {
    Write-Host "⚠️  STATUS: UNKNOWN - Could not determine" -ForegroundColor Yellow
}
Write-Host ""

# Immediate actions
Write-Host "IMMEDIATE ACTIONS:" -ForegroundColor Red

if ($cleanupProcesses.Count -eq 0) {
    Write-Host "1. Start emergency cleanup if not running" -ForegroundColor Red
    Write-Host "   Command: .\simple-auto-cleanup.ps1" -ForegroundColor Gray
} else {
    Write-Host "1. Cleanup is running - monitor progress" -ForegroundColor Green
}

Write-Host "2. Check C drive free space every 5 minutes" -ForegroundColor Gray
Write-Host "3. Move large files to D: drive immediately" -ForegroundColor Red
Write-Host "4. Consider running Windows Disk Cleanup" -ForegroundColor Gray
Write-Host ""

# Next check reminder
Write-Host "NEXT PROGRESS CHECK:" -ForegroundColor Cyan
$nextCheckTime = (Get-Date).AddMinutes(2).ToString("HH:mm")
Write-Host "   Recommended: Check again at ${nextCheckTime}" -ForegroundColor Gray
Write-Host "   Command: .\monitor-cleanup-progress.ps1" -ForegroundColor Gray
Write-Host ""

Write-Host "Progress monitoring completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray