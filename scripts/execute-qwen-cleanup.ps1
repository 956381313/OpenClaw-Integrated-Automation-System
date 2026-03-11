# Execute Qwen Duplicate Cleanup Immediately
Write-Host "=== EXECUTING QWEN DUPLICATE CLEANUP ===" -ForegroundColor Red
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "Deleting duplicate Qwen3.5-35B-A3B-Q4_0 files..." -ForegroundColor Yellow
Write-Host ""

# Create backup directory
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupDir = "qwen-backup-$timestamp"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
Write-Host "Backup directory created: $backupDir" -ForegroundColor Green
Write-Host ""

# Find all Qwen files
$searchTerm = "Qwen3.5-35B-A3B-Q4_0"
Write-Host "Searching for files containing: $searchTerm" -ForegroundColor Gray

$allFiles = Get-ChildItem -Path . -Filter "*$searchTerm*" -Recurse -ErrorAction SilentlyContinue -Force

if ($allFiles.Count -eq 0) {
    Write-Host "No Qwen files found. Nothing to clean up." -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($allFiles.Count) files total" -ForegroundColor Green

# Group by filename
$fileGroups = $allFiles | Group-Object Name

# Process each group
$totalDeleted = 0
$totalFreedMB = 0
$groupsProcessed = 0

foreach ($group in $fileGroups) {
    if ($group.Count -eq 1) {
        # Single file, keep it
        continue
    }
    
    $groupsProcessed++
    Write-Host ""
    Write-Host "Processing: $($group.Name)" -ForegroundColor Yellow
    Write-Host "   Files in group: $($group.Count)" -ForegroundColor Gray
    
    # Sort by last write time (newest first)
    $sortedFiles = $group.Group | Sort-Object LastWriteTime -Descending
    
    # Keep the newest file
    $fileToKeep = $sortedFiles[0]
    Write-Host "   Keeping (newest): $($fileToKeep.FullName)" -ForegroundColor Green
    Write-Host "   Modified: $($fileToKeep.LastWriteTime)" -ForegroundColor DarkGray
    
    # Files to delete (all except the newest)
    $filesToDelete = $sortedFiles | Select-Object -Skip 1
    
    Write-Host "   Files to delete: $($filesToDelete.Count)" -ForegroundColor $(if ($filesToDelete.Count -gt 0) {"Red"} else {"Gray"})
    
    foreach ($file in $filesToDelete) {
        $fileSizeMB = [math]::Round($file.Length / 1MB, 2)
        
        # Backup before deletion
        $backupPath = Join-Path $backupDir $file.Name
        try {
            Copy-Item -Path $file.FullName -Destination $backupPath -Force -ErrorAction SilentlyContinue
        } catch {
            Write-Host "   [WARNING] Could not backup: $($file.Name)" -ForegroundColor Yellow
        }
        
        # Delete file
        try {
            Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
            Write-Host "   [DELETED] $($file.FullName)" -ForegroundColor Green
            Write-Host "            Size: ${fileSizeMB} MB" -ForegroundColor DarkGray
            $totalDeleted++
            $totalFreedMB += $fileSizeMB
        } catch {
            Write-Host "   [ERROR] Could not delete: $($file.FullName)" -ForegroundColor Red
        }
    }
}

# Summary
Write-Host ""
Write-Host "=== CLEANUP SUMMARY ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

if ($groupsProcessed -eq 0) {
    Write-Host "No duplicate files found. All files are unique." -ForegroundColor Green
} else {
    Write-Host "Groups processed: $groupsProcessed" -ForegroundColor Gray
    Write-Host "Files deleted: $totalDeleted" -ForegroundColor $(if ($totalDeleted -gt 0) {"Green"} else {"Gray"})
    Write-Host "Space freed: ${totalFreedMB} MB" -ForegroundColor $(if ($totalFreedMB -gt 0) {"Green"} else {"Gray"})
    
    $totalFreedGB = [math]::Round($totalFreedMB / 1024, 2)
    if ($totalFreedGB -gt 0) {
        Write-Host "Space freed: ${totalFreedGB} GB" -ForegroundColor Green
    }
    
    Write-Host "Backup directory: $backupDir" -ForegroundColor Gray
}

# Show remaining files
Write-Host ""
Write-Host "REMAINING FILES:" -ForegroundColor Yellow
$remainingFiles = Get-ChildItem -Path . -Filter "*$searchTerm*" -Recurse -ErrorAction SilentlyContinue -Force

if ($remainingFiles.Count -gt 0) {
    Write-Host "   $($remainingFiles.Count) files remaining (one copy of each):" -ForegroundColor Green
    
    foreach ($file in $remainingFiles | Sort-Object LastWriteTime -Descending) {
        $fileSizeMB = [math]::Round($file.Length / 1MB, 2)
        $relativePath = $file.FullName.Replace((Get-Location).Path + "\", "")
        
        Write-Host "   - ${fileSizeMB} MB - $relativePath" -ForegroundColor Gray
    }
} else {
    Write-Host "   No Qwen files remaining" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Cleanup completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray

# Final check
Write-Host ""
Write-Host "VERIFICATION:" -ForegroundColor Cyan
Write-Host "Check backup directory to ensure no important files were deleted:" -ForegroundColor Gray
Write-Host "   $backupDir" -ForegroundColor Gray
Write-Host ""
Write-Host "If everything looks good, you can delete the backup directory after verification." -ForegroundColor Gray