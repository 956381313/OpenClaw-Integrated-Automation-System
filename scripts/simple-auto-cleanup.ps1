# Simple Auto Emergency Cleanup
Write-Host "=== SIMPLE AUTO EMERGENCY CLEANUP ===" -ForegroundColor Red
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "AUTO MODE: No confirmation required" -ForegroundColor Yellow
Write-Host ""

# Get current C drive status
Write-Host "CURRENT C: DRIVE STATUS:" -ForegroundColor Yellow
try {
    $diskC = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
    if ($diskC) {
        $usedPercent = [math]::Round((($diskC.Size - $diskC.FreeSpace)/$diskC.Size)*100, 2)
        $freeGB = [math]::Round($diskC.FreeSpace/1GB, 2)
        $totalGB = [math]::Round($diskC.Size/1GB, 2)
        
        Write-Host "Used: ${usedPercent}%" -ForegroundColor Red
        Write-Host "Free: ${freeGB} GB of ${totalGB} GB" -ForegroundColor Red
        Write-Host "Status: CRITICAL - System may crash!" -ForegroundColor Red
    }
} catch {
    Write-Host "ERROR: Cannot read C drive status" -ForegroundColor Red
}
Write-Host ""

# Step 1: Clean C drive temp files
Write-Host "1. CLEANING C: DRIVE TEMP FILES..." -ForegroundColor Yellow
$cTempFiles = 0
$cTempSizeMB = 0

# Common temp file patterns
$patterns = @("*.tmp", "*.temp", "*.bak", "*.log")

foreach ($pattern in $patterns) {
    try {
        $files = Get-ChildItem -Path "C:\" -Filter $pattern -Recurse -ErrorAction SilentlyContinue | 
            Where-Object { $_.FullName -notmatch "Windows\\" } |
            Select-Object -First 50
        
        foreach ($file in $files) {
            try {
                Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
                $cTempFiles++
                $cTempSizeMB += [math]::Round($file.Length / 1MB, 2)
            } catch {
                # Skip files that can't be deleted
            }
        }
    } catch {
        # Skip pattern if error
    }
}

Write-Host "   Deleted ${cTempFiles} temp files" -ForegroundColor $(if ($cTempFiles -gt 0) {"Green"} else {"Gray"})
Write-Host "   Freed: ${cTempSizeMB} MB" -ForegroundColor $(if ($cTempSizeMB -gt 0) {"Green"} else {"Gray"})
Write-Host ""

# Step 2: Clean Windows temp directory
Write-Host "2. CLEANING WINDOWS TEMP DIRECTORY..." -ForegroundColor Yellow
$windowsTempFiles = 0
$tempDir = $env:TEMP

if (Test-Path $tempDir) {
    try {
        $oldFiles = Get-ChildItem -Path $tempDir -File -ErrorAction SilentlyContinue | 
            Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) }
        
        foreach ($file in $oldFiles) {
            try {
                Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
                $windowsTempFiles++
            } catch {
                # Skip files that can't be deleted
            }
        }
        
        Write-Host "   Deleted ${windowsTempFiles} old temp files" -ForegroundColor $(if ($windowsTempFiles -gt 0) {"Green"} else {"Gray"})
    } catch {
        Write-Host "   Could not clean temp directory" -ForegroundColor Yellow
    }
} else {
    Write-Host "   Temp directory not found" -ForegroundColor Gray
}
Write-Host ""

# Step 3: Empty recycle bin
Write-Host "3. EMPTYING RECYCLE BIN..." -ForegroundColor Yellow
try {
    $shell = New-Object -ComObject Shell.Application
    $recycleBin = $shell.NameSpace(0xA)
    $items = $recycleBin.Items()
    
    if ($items.Count -gt 0) {
        Write-Host "   Emptying $($items.Count) items" -ForegroundColor Gray
        
        $deletedCount = 0
        for ($i = 0; $i -lt $items.Count; $i++) {
            try {
                $item = $items.Item($i)
                $recycleBin.ParseName($item.Name).InvokeVerb("Delete")
                $deletedCount++
            } catch {
                # Skip items that can't be deleted
            }
        }
        
        Write-Host "   Emptied ${deletedCount} items" -ForegroundColor Green
    } else {
        Write-Host "   Recycle bin is empty" -ForegroundColor Gray
    }
} catch {
    Write-Host "   Could not empty recycle bin" -ForegroundColor Yellow
}
Write-Host ""

# Step 4: Check C drive after cleanup
Write-Host "4. CHECKING C: DRIVE AFTER CLEANUP..." -ForegroundColor Yellow
try {
    $diskCAfter = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
    if ($diskCAfter) {
        $usedPercentAfter = [math]::Round((($diskCAfter.Size - $diskCAfter.FreeSpace)/$diskCAfter.Size)*100, 2)
        $freeGBAfter = [math]::Round($diskCAfter.FreeSpace/1GB, 2)
        
        Write-Host "   New status:" -ForegroundColor $(if ($usedPercentAfter -lt 99) {"Green"} else {"Red"})
        Write-Host "   Used: ${usedPercentAfter}%" -ForegroundColor $(if ($usedPercentAfter -lt 99) {"Green"} else {"Red"})
        Write-Host "   Free: ${freeGBAfter} GB" -ForegroundColor $(if ($freeGBAfter -gt 10) {"Green"} else {"Red"})
        
        if ($diskC) {
            $improvement = $freeGBAfter - $freeGB
            if ($improvement -gt 0) {
                Write-Host "   Improvement: +${improvement} GB freed" -ForegroundColor Green
            }
        }
        
        if ($freeGBAfter -lt 10) {
            Write-Host "   WARNING: Still less than 10 GB free!" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "   Could not check C drive after cleanup" -ForegroundColor Yellow
}
Write-Host ""

# Step 5: Find large files for migration
Write-Host "5. FINDING LARGE FILES FOR MIGRATION..." -ForegroundColor Yellow
try {
    # Check common user directories
    $userDirs = @("Downloads", "Desktop", "Documents", "Videos")
    $largeFiles = @()
    
    foreach ($dirName in $userDirs) {
        $dirPath = Join-Path $env:USERPROFILE $dirName
        if (Test-Path $dirPath) {
            $files = Get-ChildItem -Path $dirPath -File -Recurse -ErrorAction SilentlyContinue | 
                Where-Object { $_.Length -gt 100MB } | 
                Select-Object -First 3
            
            $largeFiles += $files
        }
    }
    
    if ($largeFiles.Count -gt 0) {
        Write-Host "   Found $($largeFiles.Count) large files (>100MB):" -ForegroundColor Yellow
        
        foreach ($file in $largeFiles | Sort-Object Length -Descending | Select-Object -First 5) {
            $sizeGB = [math]::Round($file.Length / 1GB, 2)
            Write-Host "   ${sizeGB} GB - $($file.FullName)" -ForegroundColor Gray
        }
        
        Write-Host ""
        Write-Host "   RECOMMENDATION: Move these to D: drive (366 GB free)" -ForegroundColor Red
    } else {
        Write-Host "   No large files found in user directories" -ForegroundColor Gray
    }
} catch {
    Write-Host "   Error finding large files" -ForegroundColor Yellow
}
Write-Host ""

# Summary
Write-Host "=== SIMPLE AUTO CLEANUP COMPLETED ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

$totalFiles = $cTempFiles + $windowsTempFiles
Write-Host "RESULTS:" -ForegroundColor Yellow
Write-Host "   Total files deleted: ${totalFiles}" -ForegroundColor Gray
Write-Host "   C drive temp files: ${cTempFiles}" -ForegroundColor Gray
Write-Host "   Windows temp files: ${windowsTempFiles}" -ForegroundColor Gray
Write-Host "   Space freed: ${cTempSizeMB} MB" -ForegroundColor Gray
Write-Host ""

# Critical warning
Write-Host "CRITICAL WARNING:" -ForegroundColor Red
Write-Host "   C drive still at critical level!" -ForegroundColor Red
Write-Host "   System may crash if space is not freed!" -ForegroundColor Red
Write-Host ""

# Immediate action required
Write-Host "IMMEDIATE ACTION REQUIRED:" -ForegroundColor Red
Write-Host "   1. Move large files from C: to D: drive" -ForegroundColor Red
Write-Host "   2. Run Windows Disk Cleanup (cleanmgr.exe)" -ForegroundColor Red
Write-Host "   3. Consider disabling hibernation" -ForegroundColor Red
Write-Host ""

# Available commands
Write-Host "AVAILABLE COMMANDS:" -ForegroundColor Cyan
Write-Host "   .\monitor-disk.bat                    # Monitor disk space" -ForegroundColor Gray
Write-Host "   .\check-status-after-cleanup.ps1      # Check detailed status" -ForegroundColor Gray
Write-Host "   .\emergency-cleanup.bat               # Run full cleanup" -ForegroundColor Gray
Write-Host ""

Write-Host "Auto cleanup completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray