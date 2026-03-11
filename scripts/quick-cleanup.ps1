# Quick Cleanup and Duplicate Merge
Write-Host "=== QUICK CLEANUP OPERATION ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# 1. Check for existing cleanup scripts
Write-Host "1. CHECKING AVAILABLE CLEANUP SCRIPTS" -ForegroundColor Yellow
$cleanupScripts = @(
    "tool-collections\powershell-scripts\clean-duplicates-optimized.ps1",
    "tool-collections\powershell-scripts\scan-duplicates-hash.ps1",
    "tool-collections\powershell-scripts\organize-and-cleanup.ps1",
    "tool-collections\powershell-scripts\workspace-cleanup-english.ps1"
)

foreach ($script in $cleanupScripts) {
    if (Test-Path $script) {
        Write-Host "   [OK] $script" -ForegroundColor Green
    } else {
        Write-Host "   [MISSING] $script" -ForegroundColor Yellow
    }
}
Write-Host ""

# 2. Run optimized duplicate cleanup
Write-Host "2. RUNNING DUPLICATE CLEANUP" -ForegroundColor Yellow
$dupScript = "tool-collections\powershell-scripts\clean-duplicates-optimized.ps1"
if (Test-Path $dupScript) {
    Write-Host "   Running optimized duplicate cleanup..." -ForegroundColor Gray
    try {
        # Run with preview mode first to see what will be cleaned
        & $dupScript --preview --strategy KeepNewest 2>&1 | Out-Host
        Write-Host "   Preview completed" -ForegroundColor Green
        
        # Ask for confirmation before actual cleanup
        Write-Host ""
        Write-Host "   Do you want to proceed with actual cleanup? (Y/N)" -ForegroundColor Yellow
        $response = Read-Host "   "
        
        if ($response -eq "Y" -or $response -eq "y") {
            Write-Host "   Running actual cleanup..." -ForegroundColor Gray
            & $dupScript --strategy KeepNewest 2>&1 | Out-Host
            Write-Host "   Duplicate cleanup completed" -ForegroundColor Green
        } else {
            Write-Host "   Cleanup cancelled" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "   Error: $_" -ForegroundColor Red
    }
} else {
    Write-Host "   Duplicate cleanup script not found" -ForegroundColor Red
}
Write-Host ""

# 3. Run workspace cleanup
Write-Host "3. RUNNING WORKSPACE CLEANUP" -ForegroundColor Yellow
$workspaceScript = "tool-collections\powershell-scripts\workspace-cleanup-english.ps1"
if (Test-Path $workspaceScript) {
    Write-Host "   Running workspace cleanup..." -ForegroundColor Gray
    try {
        & $workspaceScript 2>&1 | Out-Host
        Write-Host "   Workspace cleanup completed" -ForegroundColor Green
    } catch {
        Write-Host "   Error: $_" -ForegroundColor Red
    }
} else {
    Write-Host "   Workspace cleanup script not found" -ForegroundColor Yellow
}
Write-Host ""

# 4. Clean temporary files
Write-Host "4. CLEANING TEMPORARY FILES" -ForegroundColor Yellow
$tempPatterns = @("*.tmp", "*.temp", "*.bak", "*.log", "Thumbs.db", ".DS_Store", "~*")
$tempFiles = @()

foreach ($pattern in $tempPatterns) {
    $files = Get-ChildItem -Path "." -Filter $pattern -Recurse -ErrorAction SilentlyContinue
    $tempFiles += $files
}

if ($tempFiles.Count -gt 0) {
    Write-Host "   Found $($tempFiles.Count) temporary files" -ForegroundColor Yellow
    
    # Create backup
    $tempBackupDir = "temp-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    New-Item -ItemType Directory -Path $tempBackupDir -Force | Out-Null
    
    $backupCount = 0
    foreach ($file in $tempFiles) {
        try {
            $backupPath = Join-Path $tempBackupDir $file.Name
            Copy-Item -Path $file.FullName -Destination $backupPath -Force -ErrorAction SilentlyContinue
            $backupCount++
        } catch {
            # Continue even if backup fails
        }
    }
    
    # Delete temporary files
    $deletedCount = 0
    foreach ($file in $tempFiles) {
        try {
            Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
            $deletedCount++
        } catch {
            Write-Host "   Failed to delete: $($file.Name)" -ForegroundColor Red
        }
    }
    
    Write-Host "   Temporary files deleted: $deletedCount" -ForegroundColor Green
    Write-Host "   Backup saved to: $tempBackupDir" -ForegroundColor Gray
} else {
    Write-Host "   No temporary files found" -ForegroundColor Green
}
Write-Host ""

# 5. Clean empty directories
Write-Host "5. CLEANING EMPTY DIRECTORIES" -ForegroundColor Yellow
function Get-EmptyDirectories {
    param([string]$Path = ".")
    
    $emptyDirs = @()
    $dirs = Get-ChildItem -Path $Path -Directory -Recurse -ErrorAction SilentlyContinue
    
    foreach ($dir in $dirs) {
        $items = Get-ChildItem -Path $dir.FullName -Recurse -ErrorAction SilentlyContinue
        if ($items.Count -eq 0) {
            $emptyDirs += $dir
        }
    }
    
    return $emptyDirs
}

$emptyDirs = Get-EmptyDirectories -Path "."
if ($emptyDirs.Count -gt 0) {
    Write-Host "   Found $($emptyDirs.Count) empty directories" -ForegroundColor Yellow
    
    $cleanedCount = 0
    foreach ($dir in $emptyDirs) {
        try {
            Remove-Item -Path $dir.FullName -Force -Recurse -ErrorAction SilentlyContinue
            $cleanedCount++
            Write-Host "     Removed: $($dir.FullName)" -ForegroundColor Gray
        } catch {
            Write-Host "     Failed to remove: $($dir.FullName)" -ForegroundColor Red
        }
    }
    
    Write-Host "   Empty directories removed: $cleanedCount" -ForegroundColor Green
} else {
    Write-Host "   No empty directories found" -ForegroundColor Green
}
Write-Host ""

# 6. Run organization and cleanup
Write-Host "6. RUNNING ORGANIZATION AND CLEANUP" -ForegroundColor Yellow
$organizeScript = "tool-collections\powershell-scripts\organize-and-cleanup.ps1"
if (Test-Path $organizeScript) {
    Write-Host "   Running organization and cleanup..." -ForegroundColor Gray
    try {
        & $organizeScript --quick 2>&1 | Out-Host
        Write-Host "   Organization completed" -ForegroundColor Green
    } catch {
        Write-Host "   Error: $_" -ForegroundColor Red
    }
} else {
    Write-Host "   Organization script not found" -ForegroundColor Yellow
}
Write-Host ""

# 7. Summary
Write-Host "=== CLEANUP SUMMARY ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""
Write-Host "Operations performed:" -ForegroundColor Yellow
Write-Host "   1. Duplicate file cleanup (preview/actual)" -ForegroundColor Gray
Write-Host "   2. Workspace cleanup" -ForegroundColor Gray
Write-Host "   3. Temporary file removal" -ForegroundColor Gray
Write-Host "   4. Empty directory cleanup" -ForegroundColor Gray
Write-Host "   5. File organization" -ForegroundColor Gray
Write-Host ""
Write-Host "Recommendations:" -ForegroundColor Yellow
Write-Host "   1. Review any backup directories created" -ForegroundColor Gray
Write-Host "   2. Run hash-based duplicate scan for thorough check" -ForegroundColor Gray
Write-Host "   3. Consider setting up automated cleanup schedule" -ForegroundColor Gray
Write-Host ""
Write-Host "Cleanup completed!" -ForegroundColor Green