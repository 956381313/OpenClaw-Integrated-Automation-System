# Immediate Execute - Emergency Disk Cleanup
Write-Host "=== IMMEDIATE EXECUTION - EMERGENCY CLEANUP ===" -ForegroundColor Red
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Show critical disk status
Write-Host "CRITICAL DISK STATUS:" -ForegroundColor Red
Write-Host "C: 99.32% used (6.34 GB free) - SYSTEM DISK - EXTREME DANGER" -ForegroundColor Red
Write-Host "E: 93.91% used (226.87 GB free)" -ForegroundColor Red
Write-Host "F: 94.84% used (95.98 GB free)" -ForegroundColor Red
Write-Host "G: 95.22% used (89.2 GB free)" -ForegroundColor Red
Write-Host "D: 21.3% used (366.57 GB free) - OK" -ForegroundColor Green
Write-Host ""

# Immediate action 1: Clean C drive temporary files
Write-Host "1. CLEANING C: DRIVE TEMPORARY FILES" -ForegroundColor Yellow
$tempFilesC = Get-ChildItem -Path "C:\" -Include "*.tmp", "*.temp", "*.bak", "*.log" -Recurse -ErrorAction SilentlyContinue -Force | 
    Where-Object { $_.FullName -notmatch "Windows" } | 
    Select-Object -First 50

if ($tempFilesC.Count -gt 0) {
    Write-Host "   Found $($tempFilesC.Count) temporary files on C:" -ForegroundColor Yellow
    
    # Calculate total size
    $totalSize = ($tempFilesC | Measure-Object -Property Length -Sum).Sum
    $totalSizeMB = [math]::Round($totalSize / 1MB, 2)
    Write-Host "   Total size: ${totalSizeMB} MB" -ForegroundColor Gray
    
    # Delete files
    $deletedCount = 0
    $deletedSize = 0
    
    foreach ($file in $tempFilesC) {
        try {
            Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
            $deletedCount++
            $deletedSize += $file.Length
        } catch {
            # Skip files that can't be deleted
        }
    }
    
    $deletedSizeMB = [math]::Round($deletedSize / 1MB, 2)
    Write-Host "   Deleted $deletedCount files (${deletedSizeMB} MB)" -ForegroundColor Green
} else {
    Write-Host "   No temporary files found on C:" -ForegroundColor Gray
}
Write-Host ""

# Immediate action 2: Clean Windows temp directory
Write-Host "2. CLEANING WINDOWS TEMP DIRECTORY" -ForegroundColor Yellow
$tempDir = $env:TEMP
if (Test-Path $tempDir) {
    $tempFiles = Get-ChildItem -Path $tempDir -File -ErrorAction SilentlyContinue | 
        Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) }
    
    if ($tempFiles.Count -gt 0) {
        Write-Host "   Found $($tempFiles.Count) old temp files" -ForegroundColor Yellow
        
        $deletedCount = 0
        foreach ($file in $tempFiles) {
            try {
                Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
                $deletedCount++
            } catch {
                # Skip files that can't be deleted
            }
        }
        
        Write-Host "   Deleted $deletedCount old temp files" -ForegroundColor Green
    } else {
        Write-Host "   No old temp files found" -ForegroundColor Gray
    }
} else {
    Write-Host "   Temp directory not found" -ForegroundColor Gray
}
Write-Host ""

# Immediate action 3: Empty recycle bin
Write-Host "3. EMPTYING RECYCLE BIN" -ForegroundColor Yellow
try {
    $recycleBin = New-Object -ComObject Shell.Application
    $items = $recycleBin.NameSpace(0xA).Items()
    if ($items.Count -gt 0) {
        Write-Host "   Recycle bin has $($items.Count) items" -ForegroundColor Yellow
        
        # Empty recycle bin
        $recycleBin.NameSpace(0xA).Items() | ForEach-Object { 
            $recycleBin.NameSpace(0xA).ParseName($_.Name).InvokeVerb("Delete")
        }
        
        Write-Host "   Recycle bin emptied" -ForegroundColor Green
    } else {
        Write-Host "   Recycle bin is already empty" -ForegroundColor Gray
    }
} catch {
    Write-Host "   Failed to empty recycle bin: $_" -ForegroundColor Red
}
Write-Host ""

# Immediate action 4: Check disk space after cleanup
Write-Host "4. CHECKING DISK SPACE AFTER CLEANUP" -ForegroundColor Yellow
try {
    $diskC = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
    if ($diskC) {
        $usedPercent = [math]::Round((($diskC.Size - $diskC.FreeSpace)/$diskC.Size)*100, 2)
        $freeGB = [math]::Round($diskC.FreeSpace/1GB, 2)
        
        Write-Host "   C: drive status:" -ForegroundColor Gray
        Write-Host "   Used: ${usedPercent}%" -ForegroundColor $(if ($usedPercent -gt 95) {"Red"} elseif ($usedPercent -gt 90) {"Yellow"} else {"Green"})
        Write-Host "   Free: ${freeGB} GB" -ForegroundColor $(if ($freeGB -lt 10) {"Red"} elseif ($freeGB -lt 20) {"Yellow"} else {"Green"})
        
        if ($usedPercent -lt 99.32) {
            $improvement = 99.32 - $usedPercent
            Write-Host "   Improvement: ${improvement}% reduction" -ForegroundColor Green
        }
    }
} catch {
    Write-Host "   Failed to check disk space: $_" -ForegroundColor Red
}
Write-Host ""

# Immediate action 5: Find largest files on C drive
Write-Host "5. FINDING LARGEST FILES ON C: DRIVE" -ForegroundColor Yellow
try {
    # Look for files larger than 500MB
    $largeFiles = Get-ChildItem -Path "C:\" -File -Recurse -ErrorAction SilentlyContinue | 
        Where-Object { $_.Length -gt 500MB } | 
        Sort-Object Length -Descending | 
        Select-Object -First 10
    
    if ($largeFiles.Count -gt 0) {
        Write-Host "   Found $($largeFiles.Count) files >500MB:" -ForegroundColor Yellow
        
        foreach ($file in $largeFiles) {
            $sizeGB = [math]::Round($file.Length / 1GB, 2)
            Write-Host "   ${sizeGB} GB - $($file.FullName)" -ForegroundColor Gray
        }
        
        Write-Host ""
        Write-Host "   RECOMMENDATION: Consider moving these large files to D: drive" -ForegroundColor Red
    } else {
        Write-Host "   No files >500MB found" -ForegroundColor Gray
    }
} catch {
    Write-Host "   Error finding large files: $_" -ForegroundColor Red
}
Write-Host ""

# Summary
Write-Host "=== IMMEDIATE EXECUTION SUMMARY ===" -ForegroundColor Cyan
Write-Host "Actions performed:" -ForegroundColor Gray
Write-Host "   1. Cleaned C: drive temporary files" -ForegroundColor Gray
Write-Host "   2. Cleaned Windows temp directory" -ForegroundColor Gray
Write-Host "   3. Emptied recycle bin" -ForegroundColor Gray
Write-Host "   4. Checked disk space improvement" -ForegroundColor Gray
Write-Host "   5. Identified large files for potential migration" -ForegroundColor Gray
Write-Host ""
Write-Host "CRITICAL NEXT STEPS:" -ForegroundColor Red
Write-Host "   1. Move large files from C: to D: drive" -ForegroundColor Red
Write-Host "   2. Run full emergency cleanup on all critical drives" -ForegroundColor Red
Write-Host "   3. Monitor C: drive space continuously" -ForegroundColor Red
Write-Host ""
Write-Host "To run full emergency cleanup:" -ForegroundColor Yellow
Write-Host "   .\emergency-cleanup.bat" -ForegroundColor Gray
Write-Host "   Select option 2 and type YES to confirm" -ForegroundColor Gray
Write-Host ""
Write-Host "Immediate execution completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray