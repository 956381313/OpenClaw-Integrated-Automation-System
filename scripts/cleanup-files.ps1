# Cleanup Invalid Files and Merge Duplicates
Write-Host "=== FILE CLEANUP AND DUPLICATE MERGING ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Step 1: Create backup directory
Write-Host "1. CREATING BACKUP DIRECTORY" -ForegroundColor Yellow
$backupDir = "cleanup-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
Write-Host "   Backup directory: $backupDir" -ForegroundColor Green
Write-Host ""

# Step 2: Identify invalid files
Write-Host "2. IDENTIFYING INVALID FILES" -ForegroundColor Yellow
$invalidFiles = @()

# Check for 0-byte files
Write-Host "   Checking for 0-byte files..." -ForegroundColor Gray
$zeroByteFiles = Get-ChildItem -Path "." -File -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Length -eq 0 }
if ($zeroByteFiles.Count -gt 0) {
    Write-Host "   Found $($zeroByteFiles.Count) zero-byte files" -ForegroundColor Yellow
    $invalidFiles += $zeroByteFiles
} else {
    Write-Host "   No zero-byte files found" -ForegroundColor Green
}

# Check for temporary files
Write-Host "   Checking for temporary files..." -ForegroundColor Gray
$tempFiles = Get-ChildItem -Path "." -File -Recurse -ErrorAction SilentlyContinue | Where-Object { 
    $_.Name -match '\.tmp$|\.temp$|~$|\.bak$|\.log$' -or 
    $_.Name -match '^~' -or
    $_.Name -match 'Thumbs\.db$|\.DS_Store$'
}
if ($tempFiles.Count -gt 0) {
    Write-Host "   Found $($tempFiles.Count) temporary files" -ForegroundColor Yellow
    $invalidFiles += $tempFiles
} else {
    Write-Host "   No temporary files found" -ForegroundColor Green
}

# Check for invalid extensions
Write-Host "   Checking for files with invalid extensions..." -ForegroundColor Gray
$invalidExtFiles = Get-ChildItem -Path "." -File -Recurse -ErrorAction SilentlyContinue | Where-Object { 
    $_.Extension -match '\.(tmp|temp|bak|log|old|backup)$' -or
    $_.Extension -eq "" -and $_.Name -notmatch '^\..*'  # No extension but not hidden
}
if ($invalidExtFiles.Count -gt 0) {
    Write-Host "   Found $($invalidExtFiles.Count) files with suspicious extensions" -ForegroundColor Yellow
    $invalidFiles += $invalidExtFiles
} else {
    Write-Host "   No suspicious extension files found" -ForegroundColor Green
}

# Remove duplicates from invalid files list
$invalidFiles = $invalidFiles | Sort-Object FullName -Unique

Write-Host "   Total invalid files identified: $($invalidFiles.Count)" -ForegroundColor $(if ($invalidFiles.Count -eq 0) {"Green"} else {"Yellow"})
Write-Host ""

# Step 3: Backup invalid files before deletion
if ($invalidFiles.Count -gt 0) {
    Write-Host "3. BACKING UP INVALID FILES" -ForegroundColor Yellow
    $backupCount = 0
    
    foreach ($file in $invalidFiles) {
        try {
            $relativePath = $file.FullName.Substring((Get-Location).Path.Length + 1)
            $backupPath = Join-Path $backupDir $relativePath
            $backupDirPath = Split-Path $backupPath -Parent
            
            # Create directory structure in backup
            if (-not (Test-Path $backupDirPath)) {
                New-Item -ItemType Directory -Path $backupDirPath -Force | Out-Null
            }
            
            # Copy file to backup
            Copy-Item -Path $file.FullName -Destination $backupPath -Force -ErrorAction Stop
            $backupCount++
            Write-Host "   Backed up: $relativePath" -ForegroundColor Gray
        } catch {
            Write-Host "   Failed to backup: $($file.Name)" -ForegroundColor Red
        }
    }
    
    Write-Host "   Files backed up: $backupCount" -ForegroundColor Green
    Write-Host ""
}

# Step 4: Delete invalid files
if ($invalidFiles.Count -gt 0) {
    Write-Host "4. DELETING INVALID FILES" -ForegroundColor Yellow
    $deletedCount = 0
    
    foreach ($file in $invalidFiles) {
        try {
            Remove-Item -Path $file.FullName -Force -ErrorAction Stop
            $deletedCount++
            Write-Host "   Deleted: $($file.Name)" -ForegroundColor Gray
        } catch {
            Write-Host "   Failed to delete: $($file.Name)" -ForegroundColor Red
        }
    }
    
    Write-Host "   Files deleted: $deletedCount" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "4. NO INVALID FILES TO DELETE" -ForegroundColor Green
    Write-Host "   Skipping deletion step" -ForegroundColor Gray
    Write-Host ""
}

# Step 5: Identify duplicate files
Write-Host "5. IDENTIFYING DUPLICATE FILES" -ForegroundColor Yellow

# Group files by size first (quick check)
Write-Host "   Scanning for potential duplicates by size..." -ForegroundColor Gray
$filesBySize = Get-ChildItem -Path "." -File -Recurse -ErrorAction SilentlyContinue | 
    Where-Object { $_.Length -gt 0 } | 
    Group-Object Length

$potentialDuplicates = @()
foreach ($group in $filesBySize) {
    if ($group.Count -gt 1) {
        # Files with same size are potential duplicates
        $potentialDuplicates += $group.Group
    }
}

Write-Host "   Found $($potentialDuplicates.Count) files with matching sizes" -ForegroundColor $(if ($potentialDuplicates.Count -eq 0) {"Green"} else {"Yellow"})

# For actual duplicate detection, we would need to compare content
# For now, let's check for obvious duplicates (same name in different locations)
Write-Host "   Checking for files with same name in different locations..." -ForegroundColor Gray
$filesByName = Get-ChildItem -Path "." -File -Recurse -ErrorAction SilentlyContinue | 
    Where-Object { $_.Length -gt 0 } | 
    Group-Object Name

$nameDuplicates = @()
foreach ($group in $filesByName) {
    if ($group.Count -gt 1) {
        $nameDuplicates += $group.Group
        Write-Host "     Duplicate name: $($group.Name) ($($group.Count) copies)" -ForegroundColor Yellow
    }
}

Write-Host "   Found $($nameDuplicates.Count) files with duplicate names" -ForegroundColor $(if ($nameDuplicates.Count -eq 0) {"Green"} else {"Yellow"})
Write-Host ""

# Step 6: Create duplicate analysis report
Write-Host "6. CREATING DUPLICATE ANALYSIS REPORT" -ForegroundColor Yellow
$reportContent = @"
# Duplicate File Analysis Report
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Location: $(Get-Location)

## Summary
- Invalid files identified: $($invalidFiles.Count)
- Invalid files deleted: $(if ($invalidFiles.Count -gt 0) {$deletedCount} else {"0"})
- Files backed up: $(if ($invalidFiles.Count -gt 0) {$backupCount} else {"0"})
- Potential duplicates by size: $($potentialDuplicates.Count)
- Files with duplicate names: $($nameDuplicates.Count)

## Invalid Files Removed
$(
if ($invalidFiles.Count -gt 0) {
    $invalidFiles | ForEach-Object { "- $($_.FullName) ($($_.Length) bytes)" }
} else {
    "No invalid files found"
}
)

## Files with Duplicate Names
$(
if ($nameDuplicates.Count -gt 0) {
    $filesByName | Where-Object { $_.Count -gt 1 } | ForEach-Object { 
        "### $($_.Name)`n"
        $_.Group | ForEach-Object { "  - $($_.FullName) ($($_.Length) bytes, $($_.LastWriteTime))`n" }
    }
} else {
    "No duplicate names found"
}
)

## Recommendations
1. Review the backup directory: $backupDir
2. For true duplicate detection, use hash-based comparison
3. Consider running: tool-collections\powershell-scripts\scan-duplicates-hash.ps1
4. Manual review of duplicate name files recommended

## Backup Location
All deleted files are backed up in: $backupDir
"@

$reportPath = "cleanup-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
$reportContent | Set-Content $reportPath -Encoding UTF8
Write-Host "   Report created: $reportPath" -ForegroundColor Green
Write-Host ""

# Step 7: Clean empty directories
Write-Host "7. CLEANING EMPTY DIRECTORIES" -ForegroundColor Yellow
$emptyDirs = Get-ChildItem -Path "." -Directory -Recurse -ErrorAction SilentlyContinue | 
    Where-Object { (Get-ChildItem -Path $_.FullName -Recurse -ErrorAction SilentlyContinue).Count -eq 0 }

if ($emptyDirs.Count -gt 0) {
    $cleanedCount = 0
    foreach ($dir in $emptyDirs) {
        try {
            Remove-Item -Path $dir.FullName -Force -Recurse -ErrorAction Stop
            $cleanedCount++
            Write-Host "   Removed empty directory: $($dir.FullName)" -ForegroundColor Gray
        } catch {
            Write-Host "   Failed to remove: $($dir.FullName)" -ForegroundColor Red
        }
    }
    Write-Host "   Empty directories removed: $cleanedCount" -ForegroundColor Green
} else {
    Write-Host "   No empty directories found" -ForegroundColor Green
}
Write-Host ""

# Step 8: Run hash-based duplicate scan if available
Write-Host "8. RUNNING ADVANCED DUPLICATE SCAN" -ForegroundColor Yellow
$duplicateScript = "tool-collections\powershell-scripts\scan-duplicates-hash.ps1"
if (Test-Path $duplicateScript) {
    Write-Host "   Running hash-based duplicate scan..." -ForegroundColor Gray
    try {
        & $duplicateScript --quick 2>&1 | Out-Null
        Write-Host "   Duplicate scan completed" -ForegroundColor Green
    } catch {
        Write-Host "   Duplicate scan error: $_" -ForegroundColor Red
    }
} else {
    Write-Host "   Advanced duplicate script not found" -ForegroundColor Yellow
    Write-Host "   Available at: tool-collections\powershell-scripts\scan-duplicates-hash.ps1" -ForegroundColor Gray
}
Write-Host ""

# Step 9: Summary
Write-Host "=== CLEANUP SUMMARY ===" -ForegroundColor Cyan
Write-Host "Invalid files identified: $($invalidFiles.Count)" -ForegroundColor $(if ($invalidFiles.Count -eq 0) {"Green"} else {"Yellow"})
Write-Host "Invalid files deleted: $(if ($invalidFiles.Count -gt 0) {$deletedCount} else {"0"})" -ForegroundColor $(if ($deletedCount -eq 0) {"Gray"} else {"Green"})
Write-Host "Files backed up: $(if ($invalidFiles.Count -gt 0) {$backupCount} else {"0"})" -ForegroundColor Green
Write-Host "Potential duplicates: $($potentialDuplicates.Count)" -ForegroundColor $(if ($potentialDuplicates.Count -eq 0) {"Green"} else {"Yellow"})
Write-Host "Duplicate names: $($nameDuplicates.Count)" -ForegroundColor $(if ($nameDuplicates.Count -eq 0) {"Green"} else {"Yellow"})
Write-Host "Empty directories cleaned: $(if ($emptyDirs.Count -gt 0) {$cleanedCount} else {"0"})" -ForegroundColor $(if ($cleanedCount -eq 0) {"Gray"} else {"Green"})
Write-Host ""
Write-Host "Backup directory: $backupDir" -ForegroundColor Gray
Write-Host "Report file: $reportPath" -ForegroundColor Gray
Write-Host ""
Write-Host "Cleanup completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray

# Step 10: Recommendations
Write-Host "=== RECOMMENDATIONS ===" -ForegroundColor Cyan
Write-Host "1. Review the cleanup report: $reportPath" -ForegroundColor Gray
Write-Host "2. Check backup directory for any important files: $backupDir" -ForegroundColor Gray
Write-Host "3. For thorough duplicate detection, run:" -ForegroundColor Gray
Write-Host "   tool-collections\powershell-scripts\scan-duplicates-hash.ps1" -ForegroundColor Gray
Write-Host "4. Consider setting up automated cleanup with:" -ForegroundColor Gray
Write-Host "   tool-collections\powershell-scripts\clean-duplicates-optimized.ps1" -ForegroundColor Gray
Write-Host "5. Regular maintenance schedule recommended" -ForegroundColor Gray