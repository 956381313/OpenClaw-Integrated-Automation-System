# Complete Workspace Cleanup Script
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "    Complete Workspace Cleanup" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "Working Directory: $PWD" -ForegroundColor Gray
Write-Host ""

# Step 1: Create necessary directories
Write-Host "Step 1: Create necessary directories" -ForegroundColor Cyan

$directoriesToCreate = @(
    "tools/batch",
    "reports",
    "logs",
    "templates",
    "system-files"
)

foreach ($dir in $directoriesToCreate) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "  Created directory: $dir" -ForegroundColor Green
    }
}

Write-Host ""

# Step 2: Move batch files to tools/batch directory
Write-Host "Step 2: Organize batch files (.bat)" -ForegroundColor Cyan

$batchFiles = Get-ChildItem -Filter "*.bat" -ErrorAction SilentlyContinue
$movedBatchFiles = 0

foreach ($file in $batchFiles) {
    # Skip special batch files that should stay in root
    $skipFiles = @("run-backup.bat", "run-security.bat", "run-organize.bat", "run-knowledge.bat")
    
    if ($skipFiles -contains $file.Name) {
        Write-Host "  Keep in root: $($file.Name)" -ForegroundColor Gray
        continue
    }
    
    try {
        Move-Item -Path $file.FullName -Destination "batch-tools/scripts/" -Force -ErrorAction Stop
        $movedBatchFiles++
        Write-Host "  Moved: $($file.Name) -> batch-tools/scripts/" -ForegroundColor Gray
    } catch {
        Write-Host "  Move failed: $($file.Name)" -ForegroundColor Red
    }
}

Write-Host "  Batch files organized: $movedBatchFiles files moved" -ForegroundColor Green
Write-Host ""

# Step 3: Move special markdown files to docs directory
Write-Host "Step 3: Organize markdown files (.md)" -ForegroundColor Cyan

$mdFiles = Get-ChildItem -Filter "*.md" -ErrorAction SilentlyContinue
$movedMdFiles = 0

foreach ($file in $mdFiles) {
    # Skip workspace cleanup report (should stay in root)
    if ($file.Name -like "*workspace-cleanup-report*") {
        Write-Host "  Keep in root: $($file.Name)" -ForegroundColor Gray
        continue
    }
    
    try {
        Move-Item -Path $file.FullName -Destination "docs\" -Force -ErrorAction Stop
        $movedMdFiles++
        Write-Host "  Moved: $($file.Name) -> docs\" -ForegroundColor Gray
    } catch {
        Write-Host "  Move failed: $($file.Name)" -ForegroundColor Red
    }
}

Write-Host "  Markdown files organized: $movedMdFiles files moved" -ForegroundColor Green
Write-Host ""

# Step 4: Move log files to logs directory
Write-Host "Step 4: Organize log files" -ForegroundColor Cyan

$logFiles = Get-ChildItem -Filter "*.log" -ErrorAction SilentlyContinue
$movedLogFiles = 0

foreach ($file in $logFiles) {
    try {
        Move-Item -Path $file.FullName -Destination "data/logs/" -Force -ErrorAction Stop
        $movedLogFiles++
        Write-Host "  Moved: $($file.Name) -> data/logs/" -ForegroundColor Gray
    } catch {
        Write-Host "  Move failed: $($file.Name)" -ForegroundColor Red
    }
}

# Move text log files
$txtLogFiles = Get-ChildItem -Filter "*.txt" -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*log*" -or $_.Name -like "*report*" }
foreach ($file in $txtLogFiles) {
    try {
        Move-Item -Path $file.FullName -Destination "data/logs/" -Force -ErrorAction Stop
        $movedLogFiles++
        Write-Host "  Moved: $($file.Name) -> data/logs/" -ForegroundColor Gray
    } catch {
        Write-Host "  Move failed: $($file.Name)" -ForegroundColor Red
    }
}

Write-Host "  Log files organized: $movedLogFiles files moved" -ForegroundColor Green
Write-Host ""

# Step 5: Move template files to templates directory
Write-Host "Step 5: Organize template files" -ForegroundColor Cyan

$templateFiles = Get-ChildItem -Filter "*.template" -ErrorAction SilentlyContinue
$movedTemplateFiles = 0

foreach ($file in $templateFiles) {
    try {
        Move-Item -Path $file.FullName -Destination "templates\" -Force -ErrorAction Stop
        $movedTemplateFiles++
        Write-Host "  Moved: $($file.Name) -> templates\" -ForegroundColor Gray
    } catch {
        Write-Host "  Move failed: $($file.Name)" -ForegroundColor Red
    }
}

Write-Host "  Template files organized: $movedTemplateFiles files moved" -ForegroundColor Green
Write-Host ""

# Step 6: Move system files to system-files directory
Write-Host "Step 6: Organize system files" -ForegroundColor Cyan

$systemFiles = @()
$systemFiles += Get-ChildItem -Filter ".gitignore" -ErrorAction SilentlyContinue
$systemFiles += Get-ChildItem -Filter ".env*" -ErrorAction SilentlyContinue
$systemFiles += Get-ChildItem -Filter "*.gguf" -ErrorAction SilentlyContinue

$movedSystemFiles = 0
foreach ($file in $systemFiles) {
    try {
        Move-Item -Path $file.FullName -Destination "system-files\" -Force -ErrorAction Stop
        $movedSystemFiles++
        Write-Host "  Moved: $($file.Name) -> system-files\" -ForegroundColor Gray
    } catch {
        Write-Host "  Move failed: $($file.Name)" -ForegroundColor Red
    }
}

Write-Host "  System files organized: $movedSystemFiles files moved" -ForegroundColor Green
Write-Host ""

# Step 7: Move PowerShell scripts to scripts directory
Write-Host "Step 7: Organize PowerShell scripts" -ForegroundColor Cyan

$ps1Files = Get-ChildItem -Filter "*.ps1" -ErrorAction SilentlyContinue | Where-Object { $_.Directory.Name -ne "scripts" }
$movedPs1Files = 0

foreach ($file in $ps1Files) {
    try {
        Move-Item -Path $file.FullName -Destination "tools/scripts/" -Force -ErrorAction Stop
        $movedPs1Files++
        Write-Host "  Moved: $($file.Name) -> tools/scripts/" -ForegroundColor Gray
    } catch {
        Write-Host "  Move failed: $($file.Name)" -ForegroundColor Red
    }
}

Write-Host "  PowerShell scripts organized: $movedPs1Files files moved" -ForegroundColor Green
Write-Host ""

# Step 8: Clean up empty directories (again)
Write-Host "Step 8: Clean empty directories" -ForegroundColor Cyan

$emptyDirs = Get-ChildItem -Directory -ErrorAction SilentlyContinue | Where-Object { 
    (Get-ChildItem -Path $_.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0 
}

$removedDirs = 0
foreach ($dir in $emptyDirs) {
    try {
        Remove-Item -Path $dir.FullName -Force -Recurse -ErrorAction Stop
        $removedDirs++
        Write-Host "  Deleted empty directory: $($dir.Name)" -ForegroundColor Gray
    } catch {
        Write-Host "  Delete failed: $($dir.Name)" -ForegroundColor Red
    }
}

Write-Host "  Empty directories cleaned: $removedDirs directories" -ForegroundColor Green
Write-Host ""

# Step 9: Update essential batch files to work from new locations
Write-Host "Step 9: Update essential batch files" -ForegroundColor Cyan

# Update run-backup.bat to find scripts in scripts directory
$backupBatPath = "run-backup.bat"
if (Test-Path $backupBatPath) {
    $content = Get-Content $backupBatPath -Raw
    $updatedContent = $content -replace 'backup-english\.ps1', 'tools/scripts/backup-english.ps1'
    $updatedContent | Set-Content $backupBatPath -Encoding UTF8
    Write-Host "  Updated: run-backup.bat" -ForegroundColor Gray
}

# Update run-security.bat
$securityBatPath = "run-security.bat"
if (Test-Path $securityBatPath) {
    $content = Get-Content $securityBatPath -Raw
    $updatedContent = $content -replace 'security-check-english\.ps1', 'tools/scripts/security-check-english.ps1'
    $updatedContent | Set-Content $securityBatPath -Encoding UTF8
    Write-Host "  Updated: run-security.bat" -ForegroundColor Gray
}

# Update run-organize.bat
$organizeBatPath = "run-organize.bat"
if (Test-Path $organizeBatPath) {
    $content = Get-Content $organizeBatPath -Raw
    $updatedContent = $content -replace 'organize-and-cleanup\.ps1', 'tools/scripts/organize-and-cleanup.ps1'
    $updatedContent | Set-Content $organizeBatPath -Encoding UTF8
    Write-Host "  Updated: run-organize.bat" -ForegroundColor Gray
}

Write-Host "  Essential batch files updated" -ForegroundColor Green
Write-Host ""

# Step 10: Generate final report
Write-Host "Step 10: Generate final cleanup report" -ForegroundColor Cyan

$reportContent = @"
# Complete Workspace Cleanup Report
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Working Directory: $PWD

## Cleanup Summary
- Batch files organized: $movedBatchFiles files -> batch-tools/scripts/
- Markdown files organized: $movedMdFiles files -> docs\
- Log files organized: $movedLogFiles files -> data/logs/
- Template files organized: $movedTemplateFiles files -> templates\
- System files organized: $movedSystemFiles files -> system-files\
- PowerShell scripts organized: $movedPs1Files files -> tools/scripts/
- Empty directories cleaned: $removedDirs directories

## Current Directory Structure
$(Get-ChildItem -Directory | Sort-Object Name | ForEach-Object { "- $($_.Name)" }) | Out-String

## Files in Root Directory (After Cleanup)
$(Get-ChildItem -File | Sort-Object Name | ForEach-Object { 
    $sizeKB = [math]::Round($_.Length/1KB, 1)
    "- $($_.Name) ($sizeKB KB)"
}) | Out-String

## Essential Files in Root
These files are kept in root for easy access:
1. run-backup.bat - Main backup script
2. run-security.bat - Security check script
3. run-organize.bat - Organization script
4. run-knowledge.bat - Knowledge base script
5. workspace-cleanup-report-*.md - Cleanup reports

## Recommendations
1. Use batch-tools/scripts/ for all batch files
2. Use tools/scripts/ for all PowerShell scripts
3. Use docs\ for all documentation
4. Use data/logs/ for all log files
5. Keep only essential scripts in root
"@

$reportPath = "complete-workspace-cleanup-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
$reportContent | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host "  Final cleanup report saved: $reportPath" -ForegroundColor Green
Write-Host ""

# Final summary
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "    Complete Cleanup Finished" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total files organized: $(($movedBatchFiles + $movedMdFiles + $movedLogFiles + $movedTemplateFiles + $movedSystemFiles + $movedPs1Files))" -ForegroundColor Green
Write-Host "Empty directories removed: $removedDirs" -ForegroundColor Green
Write-Host ""
Write-Host "Clean directory structure created:" -ForegroundColor Cyan
Write-Host "  batch-tools/scripts/  - All batch files" -ForegroundColor Gray
Write-Host "  tools/scripts/        - All PowerShell scripts" -ForegroundColor Gray
Write-Host "  docs\           - All documentation" -ForegroundColor Gray
Write-Host "  data/logs/           - All log files" -ForegroundColor Gray
Write-Host "  templates\      - Template files" -ForegroundColor Gray
Write-Host "  system-files\   - System configuration files" -ForegroundColor Gray
Write-Host "  configs\        - Configuration files" -ForegroundColor Gray
Write-Host ""
Write-Host "Root directory now contains only essential files." -ForegroundColor Green
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
