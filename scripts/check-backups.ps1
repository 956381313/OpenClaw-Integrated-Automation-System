# Check Backups - Confirm No Important Files Deleted
Write-Host "=== BACKUP CHECK AND VERIFICATION ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Find all backup directories
Write-Host "1. LOCATING BACKUP DIRECTORIES" -ForegroundColor Yellow
$backupDirs = Get-ChildItem -Path "." -Directory -ErrorAction SilentlyContinue | 
    Where-Object { $_.Name -match 'backup|duplicate-backup|temp-backup|cleanup-backup' } |
    Sort-Object LastWriteTime -Descending

if ($backupDirs.Count -eq 0) {
    Write-Host "   No backup directories found" -ForegroundColor Yellow
} else {
    Write-Host "   Found $($backupDirs.Count) backup directories:" -ForegroundColor Green
    foreach ($dir in $backupDirs) {
        $fileCount = (Get-ChildItem -Path $dir.FullName -Recurse -File -ErrorAction SilentlyContinue).Count
        $sizeMB = [math]::Round((Get-ChildItem -Path $dir.FullName -Recurse -File -ErrorAction SilentlyContinue | 
            Measure-Object -Property Length -Sum).Sum / 1MB, 2)
        Write-Host "   - $($dir.Name): $fileCount files, $sizeMB MB" -ForegroundColor Gray
    }
}
Write-Host ""

# Check specific backup directories
Write-Host "2. CHECKING KEY BACKUP DIRECTORIES" -ForegroundColor Yellow
$keyBackups = @(
    "duplicate-backup-20260307",
    "cleanup-backup-20260307-021338",
    "temp-backup-20260307-0215*",
    "workspace-cleanup-backup-20260306-165319"
)

foreach ($pattern in $keyBackups) {
    $dirs = Get-ChildItem -Path "." -Directory -Filter $pattern -ErrorAction SilentlyContinue
    foreach ($dir in $dirs) {
        Write-Host "   Checking: $($dir.Name)" -ForegroundColor Gray
        
        # Get file list
        $files = Get-ChildItem -Path $dir.FullName -Recurse -File -ErrorAction SilentlyContinue | 
            Select-Object -First 10 Name, @{Name="SizeKB";Expression={[math]::Round($_.Length/1KB,2)}}, LastWriteTime
        
        if ($files.Count -gt 0) {
            Write-Host "     Files in backup:" -ForegroundColor Gray
            foreach ($file in $files) {
                Write-Host "     - $($file.Name) ($($file.SizeKB) KB, $($file.LastWriteTime))" -ForegroundColor DarkGray
            }
            
            if ((Get-ChildItem -Path $dir.FullName -Recurse -File -ErrorAction SilentlyContinue).Count -gt 10) {
                Write-Host "     ... and more files" -ForegroundColor DarkGray
            }
        } else {
            Write-Host "     No files in backup" -ForegroundColor DarkGray
        }
        Write-Host ""
    }
}

# Check for important file types in backups
Write-Host "3. CHECKING FOR IMPORTANT FILE TYPES" -ForegroundColor Yellow
$importantExtensions = @(".ps1", ".md", ".json", ".txt", ".bat", ".config", ".yml", ".yaml", ".xml")
$importantFilesFound = @()

foreach ($dir in $backupDirs) {
    foreach ($ext in $importantExtensions) {
        $files = Get-ChildItem -Path $dir.FullName -Recurse -Filter "*$ext" -ErrorAction SilentlyContinue
        if ($files.Count -gt 0) {
            $importantFilesFound += $files | Select-Object -First 5 @{Name="Path";Expression={$_.FullName}}, Name, Length, LastWriteTime
        }
    }
}

if ($importantFilesFound.Count -gt 0) {
    Write-Host "   Found $($importantFilesFound.Count) important files in backups:" -ForegroundColor Yellow
    foreach ($file in $importantFilesFound | Select-Object -First 10) {
        $relativePath = $file.Path.Substring((Get-Location).Path.Length + 1)
        Write-Host "   - $relativePath ($([math]::Round($file.Length/1KB,2)) KB)" -ForegroundColor Gray
    }
    
    if ($importantFilesFound.Count -gt 10) {
        Write-Host "   ... and $($importantFilesFound.Count - 10) more important files" -ForegroundColor DarkGray
    }
    
    Write-Host ""
    Write-Host "   RECOMMENDATION: Review these files to ensure they are not needed" -ForegroundColor Yellow
} else {
    Write-Host "   No important files found in backups" -ForegroundColor Green
}
Write-Host ""

# Verify backup integrity
Write-Host "4. VERIFYING BACKUP INTEGRITY" -ForegroundColor Yellow
$backupReport = @()
foreach ($dir in $backupDirs) {
    $files = Get-ChildItem -Path $dir.FullName -Recurse -File -ErrorAction SilentlyContinue
    $totalSize = ($files | Measure-Object -Property Length -Sum).Sum
    $avgSize = if ($files.Count -gt 0) { $totalSize / $files.Count } else { 0 }
    
    $backupReport += [PSCustomObject]@{
        Name = $dir.Name
        FileCount = $files.Count
        TotalSizeMB = [math]::Round($totalSize / 1MB, 2)
        AvgSizeKB = [math]::Round($avgSize / 1KB, 2)
        Created = $dir.CreationTime
        Modified = $dir.LastWriteTime
    }
}

if ($backupReport.Count -gt 0) {
    Write-Host "   Backup integrity check:" -ForegroundColor Gray
    $backupReport | Format-Table -AutoSize | Out-Host
} else {
    Write-Host "   No backups to verify" -ForegroundColor Gray
}
Write-Host ""

# Check if any backups contain recent files (last 7 days)
Write-Host "5. CHECKING FOR RECENT FILES IN BACKUPS" -ForegroundColor Yellow
$sevenDaysAgo = (Get-Date).AddDays(-7)
$recentFiles = @()

foreach ($dir in $backupDirs) {
    $files = Get-ChildItem -Path $dir.FullName -Recurse -File -ErrorAction SilentlyContinue | 
        Where-Object { $_.LastWriteTime -gt $sevenDaysAgo }
    $recentFiles += $files
}

if ($recentFiles.Count -gt 0) {
    Write-Host "   Found $($recentFiles.Count) recent files (last 7 days) in backups:" -ForegroundColor Yellow
    foreach ($file in $recentFiles | Select-Object -First 5) {
        Write-Host "   - $($file.Name) (Modified: $($file.LastWriteTime))" -ForegroundColor Gray
    }
    
    if ($recentFiles.Count -gt 5) {
        Write-Host "   ... and $($recentFiles.Count - 5) more recent files" -ForegroundColor DarkGray
    }
    
    Write-Host ""
    Write-Host "   WARNING: Recent files found in backups. Please verify if these should be restored." -ForegroundColor Red
} else {
    Write-Host "   No recent files found in backups" -ForegroundColor Green
}
Write-Host ""

# Summary and recommendations
Write-Host "=== BACKUP CHECK SUMMARY ===" -ForegroundColor Cyan
Write-Host "Total backup directories: $($backupDirs.Count)" -ForegroundColor Gray
Write-Host "Total backup files: $(($backupDirs | ForEach-Object { (Get-ChildItem -Path $_.FullName -Recurse -File -ErrorAction SilentlyContinue).Count } | Measure-Object -Sum).Sum)" -ForegroundColor Gray
Write-Host "Important files found: $($importantFilesFound.Count)" -ForegroundColor $(if ($importantFilesFound.Count -eq 0) {"Green"} else {"Yellow"})
Write-Host "Recent files found: $($recentFiles.Count)" -ForegroundColor $(if ($recentFiles.Count -eq 0) {"Green"} else {"Red"})
Write-Host ""
Write-Host "=== RECOMMENDATIONS ===" -ForegroundColor Cyan
Write-Host "1. Review important files found in backups" -ForegroundColor Gray
Write-Host "2. Check recent files to ensure they are not needed" -ForegroundColor Gray
Write-Host "3. Consider archiving old backups (>30 days)" -ForegroundColor Gray
Write-Host "4. Verify backup restoration process works" -ForegroundColor Gray
Write-Host "5. Document backup retention policy" -ForegroundColor Gray
Write-Host ""
Write-Host "Backup check completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray