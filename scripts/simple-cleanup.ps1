# Simple Cleanup - Remove Invalid Files and Merge Duplicates
Write-Host "=== SIMPLE FILE CLEANUP ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# 1. Remove temporary files
Write-Host "1. REMOVING TEMPORARY FILES" -ForegroundColor Yellow
$tempFiles = Get-ChildItem -Path "." -Include "*.tmp", "*.temp", "*.bak", "*.log", "Thumbs.db", ".DS_Store", "~*" -Recurse -ErrorAction SilentlyContinue
if ($tempFiles.Count -gt 0) {
    Write-Host "   Found $($tempFiles.Count) temporary files" -ForegroundColor Yellow
    $deleted = 0
    foreach ($file in $tempFiles) {
        try {
            Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
            $deleted++
            Write-Host "     Deleted: $($file.Name)" -ForegroundColor Gray
        } catch {
            Write-Host "     Failed: $($file.Name)" -ForegroundColor DarkGray
        }
    }
    Write-Host "   Deleted: $deleted files" -ForegroundColor Green
} else {
    Write-Host "   No temporary files found" -ForegroundColor Green
}
Write-Host ""

# 2. Remove 0-byte files
Write-Host "2. REMOVING 0-BYTE FILES" -ForegroundColor Yellow
$zeroFiles = Get-ChildItem -Path "." -File -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Length -eq 0 }
if ($zeroFiles.Count -gt 0) {
    Write-Host "   Found $($zeroFiles.Count) zero-byte files" -ForegroundColor Yellow
    $deleted = 0
    foreach ($file in $zeroFiles) {
        try {
            Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
            $deleted++
            Write-Host "     Deleted: $($file.Name)" -ForegroundColor Gray
        } catch {
            Write-Host "     Failed: $($file.Name)" -ForegroundColor DarkGray
        }
    }
    Write-Host "   Deleted: $deleted files" -ForegroundColor Green
} else {
    Write-Host "   No zero-byte files found" -ForegroundColor Green
}
Write-Host ""

# 3. Find duplicate files by name
Write-Host "3. FINDING DUPLICATE FILES BY NAME" -ForegroundColor Yellow
$allFiles = Get-ChildItem -Path "." -File -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Length -gt 0 }
$filesByName = $allFiles | Group-Object Name

$duplicateGroups = $filesByName | Where-Object { $_.Count -gt 1 }
if ($duplicateGroups.Count -gt 0) {
    Write-Host "   Found $($duplicateGroups.Count) files with duplicate names" -ForegroundColor Yellow
    
    foreach ($group in $duplicateGroups) {
        Write-Host "     $($group.Name): $($group.Count) copies" -ForegroundColor Gray
        
        # Show file paths
        $group.Group | ForEach-Object {
            Write-Host "       - $($_.Directory.Name)\$($_.Name) ($($_.Length) bytes, $($_.LastWriteTime))" -ForegroundColor DarkGray
        }
        
        # Keep the newest file, delete older ones
        $newestFile = $group.Group | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        $olderFiles = $group.Group | Where-Object { $_.FullName -ne $newestFile.FullName }
        
        if ($olderFiles.Count -gt 0) {
            Write-Host "       Keeping newest: $($newestFile.LastWriteTime)" -ForegroundColor Green
            
            # Create backup directory
            $backupDir = "duplicate-backup-$(Get-Date -Format 'yyyyMMdd')"
            if (-not (Test-Path $backupDir)) {
                New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
            }
            
            # Backup and delete older files
            foreach ($oldFile in $olderFiles) {
                try {
                    # Backup
                    $backupPath = Join-Path $backupDir "$($oldFile.Name).backup"
                    Copy-Item -Path $oldFile.FullName -Destination $backupPath -Force -ErrorAction SilentlyContinue
                    
                    # Delete
                    Remove-Item -Path $oldFile.FullName -Force -ErrorAction SilentlyContinue
                    Write-Host "       Deleted (backed up): $($oldFile.Directory.Name)\$($oldFile.Name)" -ForegroundColor DarkGray
                } catch {
                    Write-Host "       Failed to delete: $($oldFile.Name)" -ForegroundColor Red
                }
            }
        }
        Write-Host ""
    }
    
    Write-Host "   Duplicate files processed" -ForegroundColor Green
} else {
    Write-Host "   No duplicate files found by name" -ForegroundColor Green
}
Write-Host ""

# 4. Clean empty directories
Write-Host "4. CLEANING EMPTY DIRECTORIES" -ForegroundColor Yellow
function Get-EmptyDirectoriesRecursive {
    param([string]$Path)
    
    $emptyDirs = @()
    $dirs = Get-ChildItem -Path $Path -Directory -ErrorAction SilentlyContinue
    
    foreach ($dir in $dirs) {
        # Check if directory is empty
        $items = Get-ChildItem -Path $dir.FullName -Recurse -ErrorAction SilentlyContinue
        if ($items.Count -eq 0) {
            $emptyDirs += $dir
        } else {
            # Recursively check subdirectories
            $subEmpty = Get-EmptyDirectoriesRecursive -Path $dir.FullName
            $emptyDirs += $subEmpty
        }
    }
    
    return $emptyDirs
}

$emptyDirs = Get-EmptyDirectoriesRecursive -Path "."
if ($emptyDirs.Count -gt 0) {
    Write-Host "   Found $($emptyDirs.Count) empty directories" -ForegroundColor Yellow
    
    # Sort by path length (deepest first) to avoid issues
    $emptyDirs = $emptyDirs | Sort-Object { $_.FullName.Length } -Descending
    
    $cleaned = 0
    foreach ($dir in $emptyDirs) {
        try {
            Remove-Item -Path $dir.FullName -Force -Recurse -ErrorAction SilentlyContinue
            $cleaned++
            Write-Host "     Removed: $($dir.FullName)" -ForegroundColor Gray
        } catch {
            Write-Host "     Failed: $($dir.FullName)" -ForegroundColor DarkGray
        }
    }
    
    Write-Host "   Removed: $cleaned empty directories" -ForegroundColor Green
} else {
    Write-Host "   No empty directories found" -ForegroundColor Green
}
Write-Host ""

# 5. Summary
Write-Host "=== CLEANUP SUMMARY ===" -ForegroundColor Cyan
Write-Host "Temporary files removed: $(if ($tempFiles.Count -gt 0) {$deleted} else {'0'})" -ForegroundColor Gray
Write-Host "Zero-byte files removed: $(if ($zeroFiles.Count -gt 0) {$deleted} else {'0'})" -ForegroundColor Gray
Write-Host "Duplicate files processed: $(if ($duplicateGroups.Count -gt 0) {$duplicateGroups.Count} else {'0'})" -ForegroundColor Gray
Write-Host "Empty directories removed: $(if ($emptyDirs.Count -gt 0) {$cleaned} else {'0'})" -ForegroundColor Gray
Write-Host ""
Write-Host "Backup created in: duplicate-backup-$(Get-Date -Format 'yyyyMMdd')" -ForegroundColor Gray
Write-Host ""
Write-Host "Cleanup completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""
Write-Host "For advanced duplicate detection (hash-based), run:" -ForegroundColor Yellow
Write-Host "  tool-collections\powershell-scripts\scan-duplicates-hash.ps1" -ForegroundColor Gray