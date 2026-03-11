# Clean C Drive Now - Most Critical
Write-Host "=== CLEANING C: DRIVE - IMMEDIATE ACTION ===" -ForegroundColor Red
Write-Host "C: 99.32% used - SYSTEM AT RISK OF CRASHING!" -ForegroundColor Red
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Get current C drive status
try {
    $diskC = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
    $usedPercent = [math]::Round((($diskC.Size - $diskC.FreeSpace)/$diskC.Size)*100, 2)
    $freeGB = [math]::Round($diskC.FreeSpace/1GB, 2)
    $totalGB = [math]::Round($diskC.Size/1GB, 2)
    
    Write-Host "CURRENT STATUS:" -ForegroundColor Yellow
    Write-Host "Used: ${usedPercent}%" -ForegroundColor Red
    Write-Host "Free: ${freeGB} GB of ${totalGB} GB" -ForegroundColor Red
    Write-Host ""
} catch {
    Write-Host "ERROR: Cannot read disk status" -ForegroundColor Red
    exit 1
}

# Immediate action 1: Clean temp files
Write-Host "1. CLEANING TEMPORARY FILES..." -ForegroundColor Yellow
$tempFiles = @()
$tempPatterns = @("*.tmp", "*.temp", "*.bak", "*.log")

foreach ($pattern in $tempPatterns) {
    $files = Get-ChildItem -Path "C:\" -Filter $pattern -Recurse -ErrorAction SilentlyContinue -Force | 
        Where-Object { $_.FullName -notmatch "Windows\\" } | 
        Select-Object -First 100
    $tempFiles += $files
}

if ($tempFiles.Count -gt 0) {
    $totalSize = ($tempFiles | Measure-Object -Property Length -Sum).Sum
    $totalSizeMB = [math]::Round($totalSize / 1MB, 2)
    
    Write-Host "   Found $($tempFiles.Count) temp files (${totalSizeMB} MB)" -ForegroundColor Gray
    
    # Delete files
    $deletedCount = 0
    $deletedSize = 0
    
    foreach ($file in $tempFiles) {
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
    Write-Host "   No temp files found" -ForegroundColor Gray
}
Write-Host ""

# Immediate action 2: Clean Windows temp
Write-Host "2. CLEANING WINDOWS TEMP DIRECTORY..." -ForegroundColor Yellow
$tempDir = $env:TEMP
if (Test-Path $tempDir) {
    $tempFiles = Get-ChildItem -Path $tempDir -File -ErrorAction SilentlyContinue | 
        Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) }
    
    if ($tempFiles.Count -gt 0) {
        Write-Host "   Found $($tempFiles.Count) old temp files" -ForegroundColor Gray
        
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
Write-Host "3. EMPTYING RECYCLE BIN..." -ForegroundColor Yellow
try {
    $shell = New-Object -ComObject Shell.Application
    $recycleBin = $shell.NameSpace(0xA)
    $items = $recycleBin.Items()
    
    if ($items.Count -gt 0) {
        Write-Host "   Recycle bin has $($items.Count) items" -ForegroundColor Gray
        
        # Create list of items to delete
        $itemsToDelete = @()
        for ($i = 0; $i -lt $items.Count; $i++) {
            $itemsToDelete += $items.Item($i)
        }
        
        # Delete items
        foreach ($item in $itemsToDelete) {
            try {
                $recycleBin.ParseName($item.Name).InvokeVerb("Delete")
            } catch {
                # Skip items that can't be deleted
            }
        }
        
        Write-Host "   Recycle bin emptied" -ForegroundColor Green
    } else {
        Write-Host "   Recycle bin is empty" -ForegroundColor Gray
    }
} catch {
    Write-Host "   Could not empty recycle bin: $_" -ForegroundColor Yellow
}
Write-Host ""

# Check disk space after cleanup
Write-Host "4. CHECKING DISK SPACE AFTER CLEANUP..." -ForegroundColor Yellow
try {
    $diskCAfter = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
    if ($diskCAfter) {
        $usedPercentAfter = [math]::Round((($diskCAfter.Size - $diskCAfter.FreeSpace)/$diskCAfter.Size)*100, 2)
        $freeGBAfter = [math]::Round($diskCAfter.FreeSpace/1GB, 2)
        
        Write-Host "   NEW STATUS:" -ForegroundColor $(if ($usedPercentAfter -lt 99) {"Green"} else {"Red"})
        Write-Host "   Used: ${usedPercentAfter}%" -ForegroundColor $(if ($usedPercentAfter -lt 99) {"Green"} else {"Red"})
        Write-Host "   Free: ${freeGBAfter} GB" -ForegroundColor $(if ($freeGBAfter -gt 10) {"Green"} else {"Red"})
        
        if ($usedPercentAfter -lt $usedPercent) {
            $improvement = $usedPercent - $usedPercentAfter
            $spaceFreed = $freeGBAfter - $freeGB
            Write-Host "   Improvement: ${improvement}% reduction" -ForegroundColor Green
            Write-Host "   Space freed: ${spaceFreed} GB" -ForegroundColor Green
        }
    }
} catch {
    Write-Host "   Could not check disk status" -ForegroundColor Yellow
}
Write-Host ""

# Find large files for potential migration
Write-Host "5. FINDING LARGE FILES FOR POTENTIAL MIGRATION..." -ForegroundColor Yellow
try {
    # Look in user directories for large files
    $userDirs = @(
        "$env:USERPROFILE\Downloads",
        "$env:USERPROFILE\Desktop", 
        "$env:USERPROFILE\Documents",
        "$env:USERPROFILE\Videos",
        "$env:USERPROFILE\Music",
        "$env:USERPROFILE\Pictures"
    )
    
    $largeFiles = @()
    foreach ($dir in $userDirs) {
        if (Test-Path $dir) {
            $files = Get-ChildItem -Path $dir -File -Recurse -ErrorAction SilentlyContinue | 
                Where-Object { $_.Length -gt 100MB } | 
                Select-Object -First 5
            $largeFiles += $files
        }
    }
    
    if ($largeFiles.Count -gt 0) {
        Write-Host "   Found $($largeFiles.Count) large files (>100MB) in user directories:" -ForegroundColor Yellow
        
        foreach ($file in $largeFiles | Sort-Object Length -Descending | Select-Object -First 5) {
            $sizeGB = [math]::Round($file.Length / 1GB, 2)
            Write-Host "   ${sizeGB} GB - $($file.FullName)" -ForegroundColor Gray
        }
        
        Write-Host ""
        Write-Host "   RECOMMENDATION: Move these files to D: drive (366 GB free)" -ForegroundColor Red
    } else {
        Write-Host "   No large files found in user directories" -ForegroundColor Gray
    }
} catch {
    Write-Host "   Error finding large files: $_" -ForegroundColor Yellow
}
Write-Host ""

# Summary
Write-Host "=== C: DRIVE CLEANUP COMPLETED ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""
Write-Host "Actions performed:" -ForegroundColor Gray
Write-Host "   1. Temporary file cleanup" -ForegroundColor Gray
Write-Host "   2. Windows temp directory cleanup" -ForegroundColor Gray
Write-Host "   3. Recycle bin emptied" -ForegroundColor Gray
Write-Host ""
Write-Host "CRITICAL NEXT STEP:" -ForegroundColor Red
Write-Host "   Move large files from C: to D: drive to prevent system crash!" -ForegroundColor Red
Write-Host ""
Write-Host "To clean other drives (E:, F:, G:):" -ForegroundColor Yellow
Write-Host "   .\emergency-cleanup.bat" -ForegroundColor Gray
Write-Host ""
Write-Host "To monitor disk space:" -ForegroundColor Yellow
Write-Host "   .\monitor-disk.bat" -ForegroundColor Gray