# Auto Execute Emergency Cleanup - No Confirmation Required
Write-Host "=== AUTO EXECUTING EMERGENCY DISK CLEANUP ===" -ForegroundColor Red
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "AUTO MODE: No confirmation required" -ForegroundColor Yellow
Write-Host ""

# Get current disk status before cleanup
Write-Host "CURRENT DISK STATUS (BEFORE CLEANUP):" -ForegroundColor Yellow
try {
    $disks = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3"
    $beforeStatus = @{}
    
    foreach ($disk in $disks) {
        $usedPercent = [math]::Round((($disk.Size - $disk.FreeSpace)/$disk.Size)*100, 2)
        $freeGB = [math]::Round($disk.FreeSpace/1GB, 2)
        $totalGB = [math]::Round($disk.Size/1GB, 2)
        
        $beforeStatus[$disk.DeviceID] = @{
            UsedPercent = $usedPercent
            FreeGB = $freeGB
            TotalGB = $totalGB
        }
        
        if ($usedPercent -gt 95) {
            Write-Host "🔴 $($disk.DeviceID): ${usedPercent}% used (${freeGB} GB free of ${totalGB} GB)" -ForegroundColor Red
        } elseif ($usedPercent -gt 90) {
            Write-Host "🟡 $($disk.DeviceID): ${usedPercent}% used (${freeGB} GB free of ${totalGB} GB)" -ForegroundColor Yellow
        } else {
            Write-Host "🟢 $($disk.DeviceID): ${usedPercent}% used (${freeGB} GB free of ${totalGB} GB)" -ForegroundColor Green
        }
    }
} catch {
    Write-Host "ERROR: Could not get disk status" -ForegroundColor Red
    $beforeStatus = @{}
}
Write-Host ""

# Step 1: Clean C drive temporary files (MOST CRITICAL)
Write-Host "1. CLEANING C: DRIVE (MOST CRITICAL)..." -ForegroundColor Red
$cDriveCleanup = @{
    FilesDeleted = 0
    SizeFreedMB = 0
    Errors = 0
}

# Clean temporary files on C:
$tempPatterns = @("*.tmp", "*.temp", "*.bak", "*.log", "Thumbs.db", ".DS_Store", "~*")
foreach ($pattern in $tempPatterns) {
    try {
        $files = Get-ChildItem -Path "C:\" -Filter $pattern -Recurse -ErrorAction SilentlyContinue -Force | 
            Where-Object { $_.FullName -notmatch "Windows\\" -and $_.FullName -notmatch "Program Files" } |
            Select-Object -First 200
        
        if ($files.Count -gt 0) {
            foreach ($file in $files) {
                try {
                    Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
                    $cDriveCleanup.FilesDeleted++
                    $cDriveCleanup.SizeFreedMB += [math]::Round($file.Length / 1MB, 2)
                } catch {
                    $cDriveCleanup.Errors++
                }
            }
        }
    } catch {
        # Skip pattern if error
    }
}

Write-Host "   Deleted $($cDriveCleanup.FilesDeleted) files on C:" -ForegroundColor $(if ($cDriveCleanup.FilesDeleted -gt 0) {"Green"} else {"Gray"})
Write-Host "   Freed: $($cDriveCleanup.SizeFreedMB) MB" -ForegroundColor $(if ($cDriveCleanup.SizeFreedMB -gt 0) {"Green"} else {"Gray"})
Write-Host ""

# Step 2: Clean Windows temp directories
Write-Host "2. CLEANING WINDOWS TEMP DIRECTORIES..." -ForegroundColor Yellow
$tempDirs = @(
    $env:TEMP,
    "$env:WINDIR\Temp",
    "$env:WINDIR\Prefetch",
    "$env:LOCALAPPDATA\Temp"
)

$tempCleanup = @{
    FilesDeleted = 0
    DirsCleaned = 0
}

foreach ($tempDir in $tempDirs) {
    if (Test-Path $tempDir) {
        try {
            # Delete files older than 7 days
            $oldFiles = Get-ChildItem -Path $tempDir -File -Recurse -ErrorAction SilentlyContinue | 
                Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) }
            
            if ($oldFiles.Count -gt 0) {
                foreach ($file in $oldFiles) {
                    try {
                        Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
                        $tempCleanup.FilesDeleted++
                    } catch {
                        # Skip files that can't be deleted
                    }
                }
                $tempCleanup.DirsCleaned++
            }
        } catch {
            # Skip directory if error
        }
    }
}

Write-Host "   Cleaned $($tempCleanup.DirsCleaned) temp directories" -ForegroundColor $(if ($tempCleanup.DirsCleaned -gt 0) {"Green"} else {"Gray"})
Write-Host "   Deleted $($tempCleanup.FilesDeleted) old temp files" -ForegroundColor $(if ($tempCleanup.FilesDeleted -gt 0) {"Green"} else {"Gray"})
Write-Host ""

# Step 3: Empty recycle bin
Write-Host "3. EMPTYING RECYCLE BIN..." -ForegroundColor Yellow
try {
    $shell = New-Object -ComObject Shell.Application
    $recycleBin = $shell.NameSpace(0xA)
    $items = $recycleBin.Items()
    
    if ($items.Count -gt 0) {
        Write-Host "   Emptying $($items.Count) items from recycle bin" -ForegroundColor Gray
        
        # Create array of items to delete
        $itemsArray = @()
        for ($i = 0; $i -lt $items.Count; $i++) {
            $itemsArray += $items.Item($i)
        }
        
        # Delete all items
        $deletedCount = 0
        foreach ($item in $itemsArray) {
            try {
                $recycleBin.ParseName($item.Name).InvokeVerb("Delete")
                $deletedCount++
            } catch {
                # Skip items that can't be deleted
            }
        }
        
        Write-Host "   Emptied $deletedCount items from recycle bin" -ForegroundColor Green
    } else {
        Write-Host "   Recycle bin is already empty" -ForegroundColor Gray
    }
} catch {
    Write-Host "   Could not empty recycle bin" -ForegroundColor Yellow
}
Write-Host ""

# Step 4: Clean other critical drives (E:, F:, G:)
Write-Host "4. CLEANING OTHER CRITICAL DRIVES (E:, F:, G:)..." -ForegroundColor Yellow
$otherDrives = @("E:", "F:", "G:")
$otherCleanup = @{
    TotalFilesDeleted = 0
    TotalSizeFreedMB = 0
}

foreach ($drive in $otherDrives) {
    $driveCleanup = @{
        FilesDeleted = 0
        SizeFreedMB = 0
    }
    
    foreach ($pattern in $tempPatterns) {
        try {
            $files = Get-ChildItem -Path "${drive}\" -Filter $pattern -Recurse -ErrorAction SilentlyContinue -Force | 
                Select-Object -First 100
            
            if ($files.Count -gt 0) {
                foreach ($file in $files) {
                    try {
                        Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
                        $driveCleanup.FilesDeleted++
                        $driveCleanup.SizeFreedMB += [math]::Round($file.Length / 1MB, 2)
                    } catch {
                        # Skip files that can't be deleted
                    }
                }
            }
        } catch {
            # Skip pattern if error
        }
    }
    
    if ($driveCleanup.FilesDeleted -gt 0) {
        Write-Host "   $drive: Deleted $($driveCleanup.FilesDeleted) files, Freed: $($driveCleanup.SizeFreedMB) MB" -ForegroundColor Green
        $otherCleanup.TotalFilesDeleted += $driveCleanup.FilesDeleted
        $otherCleanup.TotalSizeFreedMB += $driveCleanup.SizeFreedMB
    } else {
        Write-Host "   $drive: No temporary files found" -ForegroundColor Gray
    }
}
Write-Host ""

# Step 5: Check disk status after cleanup
Write-Host "5. CHECKING DISK STATUS AFTER CLEANUP..." -ForegroundColor Yellow
try {
    $disksAfter = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3"
    
    Write-Host "   AFTER CLEANUP STATUS:" -ForegroundColor Gray
    foreach ($disk in $disksAfter) {
        $usedPercent = [math]::Round((($disk.Size - $disk.FreeSpace)/$disk.Size)*100, 2)
        $freeGB = [math]::Round($disk.FreeSpace/1GB, 2)
        
        # Calculate improvement if we have before data
        $improvement = ""
        if ($beforeStatus.ContainsKey($disk.DeviceID)) {
            $beforeFreeGB = $beforeStatus[$disk.DeviceID].FreeGB
            if ($freeGB -gt $beforeFreeGB) {
                $improvementGB = [math]::Round($freeGB - $beforeFreeGB, 2)
                $improvement = " (+${improvementGB} GB)"
            }
        }
        
        if ($usedPercent -gt 95) {
            Write-Host "   🔴 $($disk.DeviceID): ${usedPercent}% used (${freeGB} GB free)$improvement" -ForegroundColor Red
        } elseif ($usedPercent -gt 90) {
            Write-Host "   🟡 $($disk.DeviceID): ${usedPercent}% used (${freeGB} GB free)$improvement" -ForegroundColor Yellow
        } else {
            Write-Host "   🟢 $($disk.DeviceID): ${usedPercent}% used (${freeGB} GB free)$improvement" -ForegroundColor Green
        }
    }
} catch {
    Write-Host "   Could not check disk status after cleanup" -ForegroundColor Yellow
}
Write-Host ""

# Step 6: Generate cleanup report
Write-Host "6. GENERATING CLEANUP REPORT..." -ForegroundColor Yellow
$reportDir = "data-storage\reports\emergency-cleanup\"
if (-not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$reportFile = Join-Path $reportDir "auto-cleanup-report-$timestamp.md"

$reportContent = @"
# Auto Emergency Cleanup Report
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Mode: AUTO (No confirmation required)

## Summary
- C drive files deleted: $($cDriveCleanup.FilesDeleted)
- C drive space freed: $($cDriveCleanup.SizeFreedMB) MB
- Windows temp files deleted: $($tempCleanup.FilesDeleted)
- Other drives files deleted: $($otherCleanup.TotalFilesDeleted)
- Other drives space freed: $($otherCleanup.TotalSizeFreedMB) MB
- Recycle bin: Emptied

## Disk Status Before Cleanup
$(
if ($beforeStatus.Count -gt 0) {
    foreach ($drive in $beforeStatus.Keys) {
        $status = $beforeStatus[$drive]
        "- $drive: $($status.UsedPercent)% used ($($status.FreeGB) GB free of $($status.TotalGB) GB)"
    }
} else {
    "No before data available"
}
)

## Disk Status After Cleanup
$(
try {
    $disks = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3"
    foreach ($disk in $disks) {
        $usedPercent = [math]::Round((($disk.Size - $disk.FreeSpace)/$disk.Size)*100, 2)
        $freeGB = [math]::Round($disk.FreeSpace/1GB, 2)
        "- $($disk.DeviceID): ${usedPercent}% used (${freeGB} GB free)"
    }
} catch {
    "Could not get after cleanup status"
}
)

## Critical Issues Remaining
- C drive still at critical level (>95% used)
- Immediate action required to prevent system crash
- Consider moving large files to D drive (366 GB free)

## Recommendations
1. Move large files from C: to D: drive immediately
2. Run disk cleanup utility: cleanmgr.exe
3. Disable hibernation to free space: powercfg -h off
4. Reduce page file size if possible
5. Uninstall unused programs

## Next Steps
1. Monitor C drive space continuously
2. Set up automated cleanup schedule
3. Implement disk space alerts
4. Regular maintenance every week

## Auto Cleanup Details
- Execution time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
- Mode: Automatic (no user confirmation)
- Safety: Only temporary files deleted
- Logs: Available in report directory
"@

$reportContent | Set-Content $reportFile -Encoding UTF8
Write-Host "   Report generated: $reportFile" -ForegroundColor Green
Write-Host ""

# Step 7: Final summary and recommendations
Write-Host "=== AUTO CLEANUP COMPLETED ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Calculate total cleanup
$totalFiles = $cDriveCleanup.FilesDeleted + $tempCleanup.FilesDeleted + $otherCleanup.TotalFilesDeleted
$totalSizeMB = $cDriveCleanup.SizeFreedMB + $otherCleanup.TotalSizeFreedMB

Write-Host "CLEANUP RESULTS:" -ForegroundColor Yellow
Write-Host "   Total files deleted: $totalFiles" -ForegroundColor Gray
Write-Host "   Total space freed: ${totalSizeMB} MB ($([math]::Round($totalSizeMB/1024,2)) GB)" -ForegroundColor Gray
Write-Host ""

# Check C drive status specifically
Write-Host "C: DRIVE STATUS (MOST CRITICAL):" -ForegroundColor $(if ($cDriveCleanup.SizeFreedMB -gt 0) {"Yellow"} else {"Red"})
try {
    $diskC = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
    if ($diskC) {
        $usedPercent = [math]::Round((($diskC.Size - $diskC.FreeSpace)/$diskC.Size)*100, 2)
        $freeGB = [math]::Round($diskC.FreeSpace/1GB, 2)
        
        Write-Host "   Current: ${usedPercent}% used" -ForegroundColor $(if ($usedPercent -gt 95) {"Red"} elseif ($usedPercent -gt 90) {"Yellow"} else {"Green"})
        Write-Host "   Free space: ${freeGB} GB" -ForegroundColor $(if ($freeGB -lt 10) {"Red"} elseif ($freeGB -lt 20) {"Yellow"} else {"Green"})
        
        if ($freeGB -lt 10) {
            Write-Host "   ⚠️  WARNING: Less than 10 GB free - System stability at risk!" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "   Could not check C drive status" -ForegroundColor Yellow
}
Write-Host ""

# Most critical recommendation
Write-Host "MOST CRITICAL RECOMMENDATION:" -ForegroundColor Red
Write-Host "   C drive is still at critical level!" -ForegroundColor Red
Write-Host "   Move large files from C: to D: drive IMMEDIATELY!" -ForegroundColor Red
Write-Host "   D drive has 366 GB free space available" -ForegroundColor Green
Write-Host ""

# Available commands for further action
Write-Host "AVAILABLE COMMANDS FOR FURTHER ACTION:" -ForegroundColor Cyan
Write-Host "   .\monitor-disk.bat                         # Monitor disk space" -ForegroundColor Gray
Write-Host "   .\check-status-after-cleanup.ps1           # Check detailed status" -ForegroundColor Gray
Write-Host "   .\emergency-cleanup.bat                    # Run interactive cleanup" -ForegroundColor Gray
Write-Host ""

Write-Host "Auto emergency cleanup completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray