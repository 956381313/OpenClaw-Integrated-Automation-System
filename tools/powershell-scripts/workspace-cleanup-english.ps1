# Workspace Cleanup Script (English)
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "    Workspace Cleanup and Organization" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "Working Directory: $PWD" -ForegroundColor Gray
Write-Host ""

# Create backup directory
$backupDir = "workspace-cleanup-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
Write-Host "Created backup directory: $backupDir" -ForegroundColor Green
Write-Host ""

# Step 1: Clean duplicate files
Write-Host "Step 1: Clean duplicate files" -ForegroundColor Cyan
Write-Host "  Running duplicate file cleanup system..." -ForegroundColor Gray

# Use our developed cleanup system
try {
    $cleanupResult = .\clean-duplicates-optimized.ps1 -Strategy KeepNewest -Preview $false -Backup $true
    Write-Host "  Duplicate file cleanup completed" -ForegroundColor Green
} catch {
    Write-Host "  Duplicate file cleanup may have issues" -ForegroundColor Yellow
}

Write-Host ""

# Step 2: Clean unused files
Write-Host "Step 2: Clean unused files" -ForegroundColor Cyan

# Define cleanup patterns
$cleanupPatterns = @(
    "*.tmp",
    "*.temp",
    "*.bak",
    "~*",
    "Thumbs.db",
    ".DS_Store",
    "desktop.ini"
)

$cleanedFiles = 0
$cleanedSize = 0

foreach ($pattern in $cleanupPatterns) {
    $files = Get-ChildItem -Recurse -Filter $pattern -ErrorAction SilentlyContinue
    foreach ($file in $files) {
        try {
            # Backup file
            $backupPath = Join-Path $backupDir $file.FullName.Substring($PWD.Path.Length + 1)
            $backupFolder = Split-Path $backupPath -Parent
            if (-not (Test-Path $backupFolder)) {
                New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
            }
            Copy-Item -Path $file.FullName -Destination $backupPath -Force
            
            # Delete file
            Remove-Item -Path $file.FullName -Force -ErrorAction Stop
            $cleanedFiles++
            $cleanedSize += $file.Length
            Write-Host ("   Deleted: {0}" -f $file.Name) -ForegroundColor Gray
        } catch {
            Write-Host ("   Delete failed: {0} ({1})" -f $file.Name, $_.Exception.Message) -ForegroundColor Red
        }
    }
}

# Clean empty log files
$emptyLogs = Get-ChildItem -Recurse -Filter "*.log" -ErrorAction SilentlyContinue | Where-Object { $_.Length -eq 0 }
foreach ($log in $emptyLogs) {
    try {
        $backupPath = Join-Path $backupDir $log.FullName.Substring($PWD.Path.Length + 1)
        $backupFolder = Split-Path $backupPath -Parent
        if (-not (Test-Path $backupFolder)) {
            New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
        }
        Copy-Item -Path $log.FullName -Destination $backupPath -Force
        Remove-Item -Path $log.FullName -Force -ErrorAction Stop
        $cleanedFiles++
        Write-Host ("   Deleted empty log: {0}" -f $log.Name) -ForegroundColor Gray
    } catch {
        Write-Host ("   Delete failed: {0}" -f $log.Name) -ForegroundColor Red
    }
}

$cleanedSizeMB = [math]::Round($cleanedSize / 1MB, 2)
Write-Host "  Cleanup completed: $cleanedFiles files ($cleanedSizeMB MB)" -ForegroundColor Green
Write-Host ""

# Step 3: Organize directory structure
Write-Host "Step 3: Organize directory structure" -ForegroundColor Cyan

# Create standard directory structure
$standardDirs = @(
    "scripts",
    "configs",
    "docs",
    "logs",
    "backups",
    "temp",
    "reports"
)

foreach ($dir in $standardDirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host ("   Created directory: {0}" -f $dir) -ForegroundColor Gray
    }
}

Write-Host "  Directory structure organized" -ForegroundColor Green
Write-Host ""

# Step 4: Organize files
Write-Host "Step 4: Organize files" -ForegroundColor Cyan

# Move script files to scripts directory
$scriptFiles = Get-ChildItem -Filter "*.ps1" -ErrorAction SilentlyContinue | Where-Object { $_.Directory.Name -ne "scripts" }
foreach ($script in $scriptFiles) {
    try {
        Move-Item -Path $script.FullName -Destination "tools/scripts/" -Force -ErrorAction Stop
        Write-Host ("   Moved script: {0} -> tools/scripts/" -f $script.Name) -ForegroundColor Gray
    } catch {
        Write-Host ("   Move failed: {0}" -f $script.Name) -ForegroundColor Red
    }
}

# Move config files to configs directory
$configFiles = Get-ChildItem -Filter "*.json" -ErrorAction SilentlyContinue | Where-Object { $_.Directory.Name -ne "configs" -and $_.Directory.Name -ne "modules/duplicate/config" -and $_.Directory.Name -ne "modules/email/config" }
foreach ($config in $configFiles) {
    try {
        Move-Item -Path $config.FullName -Destination "configs\" -Force -ErrorAction Stop
        Write-Host ("   Moved config: {0} -> configs\" -f $config.Name) -ForegroundColor Gray
    } catch {
        Write-Host ("   Move failed: {0}" -f $config.Name) -ForegroundColor Red
    }
}

# Move document files to docs directory
$docFiles = Get-ChildItem -Filter "*.md" -ErrorAction SilentlyContinue | Where-Object { $_.Directory.Name -ne "docs" -and $_.Directory.Name -ne "core/memory" }
foreach ($doc in $docFiles) {
    try {
        Move-Item -Path $doc.FullName -Destination "docs\" -Force -ErrorAction Stop
        Write-Host ("   Moved document: {0} -> docs\" -f $doc.Name) -ForegroundColor Gray
    } catch {
        Write-Host ("   Move failed: {0}" -f $doc.Name) -ForegroundColor Red
    }
}

Write-Host "  Files organized" -ForegroundColor Green
Write-Host ""

# Step 5: Clean empty directories
Write-Host "Step 5: Clean empty directories" -ForegroundColor Cyan

$emptyDirs = Get-ChildItem -Directory -Recurse -ErrorAction SilentlyContinue | Where-Object { 
    (Get-ChildItem -Path $_.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0 
}

$removedDirs = 0
foreach ($dir in $emptyDirs) {
    try {
        Remove-Item -Path $dir.FullName -Force -Recurse -ErrorAction Stop
        $removedDirs++
        Write-Host ("   Deleted empty directory: {0}" -f $dir.Name) -ForegroundColor Gray
    } catch {
        Write-Host ("   Delete failed: {0}" -f $dir.Name) -ForegroundColor Red
    }
}

Write-Host "  Empty directories cleaned: $removedDirs directories" -ForegroundColor Green
Write-Host ""

# Step 6: Generate cleanup report
Write-Host "Step 6: Generate cleanup report" -ForegroundColor Cyan

$reportContent = @"
# Workspace Cleanup Report
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Working Directory: $PWD

## Summary
- Backup directory: $backupDir
- Unused files cleaned: $cleanedFiles files ($cleanedSizeMB MB)
- Empty directories cleaned: $removedDirs
- Duplicate file cleanup: Executed

## Directory Structure
$(Get-ChildItem -Directory | Sort-Object Name | ForEach-Object { "- $($_.Name)" }) | Out-String

## File Statistics
$(Get-ChildItem -Recurse -File | Group-Object Extension | Sort-Object Count -Descending | ForEach-Object { 
    $size = ($_.Group | Measure-Object -Property Length -Sum).Sum
    $sizeMB = [math]::Round($size / 1MB, 2)
    "- $($_.Name): $($_.Count) files ($sizeMB MB)"
}) | Out-String

## Recommendations
1. Run duplicate file cleanup system regularly
2. Clean old backup files (>30 days)
3. Compress large log files
4. Maintain clean directory structure
"@

$reportPath = "workspace-cleanup-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
$reportContent | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host "  Cleanup report saved: $reportPath" -ForegroundColor Green
Write-Host ""

# Final summary
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "    Cleanup Complete Summary" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Completed tasks:" -ForegroundColor Green
Write-Host "  1. Clean duplicate files (using system)" -ForegroundColor Gray
Write-Host "  2. Clean unused files: $cleanedFiles files ($cleanedSizeMB MB)" -ForegroundColor Gray
Write-Host "  3. Organize directory structure" -ForegroundColor Gray
Write-Host "  4. Organize files to standard directories" -ForegroundColor Gray
Write-Host "  5. Clean empty directories: $removedDirs directories" -ForegroundColor Gray
Write-Host "  6. Generate detailed report" -ForegroundColor Gray
Write-Host ""
Write-Host "Backup location: $backupDir" -ForegroundColor Cyan
Write-Host "Report file: $reportPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "Recommendations:" -ForegroundColor Yellow
Write-Host "  - Run duplicate file cleanup system regularly" -ForegroundColor Gray
Write-Host "  - Perform workspace cleanup monthly" -ForegroundColor Gray
Write-Host "  - Maintain clean directory structure" -ForegroundColor Gray
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
