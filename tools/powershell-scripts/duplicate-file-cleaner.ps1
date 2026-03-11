# OpenClaw Duplicate File Cleaner

Write-Host "=== OpenClaw Duplicate File Cleaner ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Configuration
$workspacePath = "C:\Users\luchaochao\.openclaw\workspace"
$backupDir = "modules/duplicate/backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$reportDir = "modules/duplicate/reports"
$maxFileSizeMB = 50  # Skip files larger than 50MB for performance

# Safety first - create backup directory
if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    Write-Host "Created backup directory: $backupDir" -ForegroundColor Green
    Write-Host "  (Files will be moved here instead of deleted)" -ForegroundColor Gray
}

if (-not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
}

Write-Host "1. Scanning workspace for duplicate files..." -ForegroundColor Yellow

# Get all files (excluding very large files for performance)
$allFiles = Get-ChildItem $workspacePath -Recurse -File -ErrorAction SilentlyContinue | 
    Where-Object { $_.Length -lt ($maxFileSizeMB * 1MB) } |
    Where-Object { $_.Extension -match '\.(md|txt|ps1|bat|json|log|yml|yaml|xml)$' }

$totalFiles = $allFiles.Count
Write-Host "  Found $totalFiles files to analyze (excluding files > ${maxFileSizeMB}MB)" -ForegroundColor Green

if ($totalFiles -eq 0) {
    Write-Host "No files found to analyze" -ForegroundColor Yellow
    exit 0
}

# 2. Calculate file hashes (for exact duplicates)
Write-Host "`n2. Calculating file hashes..." -ForegroundColor Yellow

$fileHashes = @{}
$hashGroups = @{}
$processedCount = 0

foreach ($file in $allFiles) {
    try {
        # Calculate MD5 hash
        $hash = Get-FileHash $file.FullName -Algorithm MD5 -ErrorAction Stop
        
        if (-not $fileHashes.ContainsKey($hash.Hash)) {
            $fileHashes[$hash.Hash] = @()
        }
        
        $fileHashes[$hash.Hash] += @{
            Path = $file.FullName
            Name = $file.Name
            Size = "$([math]::Round($file.Length / 1KB, 2)) KB"
            Modified = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
            Extension = $file.Extension
        }
        
        $processedCount++
        
        if ($processedCount % 20 -eq 0) {
            Write-Host "  Processed $processedCount/$totalFiles files" -ForegroundColor Gray
        }
        
    } catch {
        Write-Host "  Skipped: $($file.Name) (error: $_)" -ForegroundColor Yellow
    }
}

Write-Host "  Hash calculation complete: $processedCount files processed" -ForegroundColor Green

# 3. Identify duplicate groups
Write-Host "`n3. Identifying duplicate files..." -ForegroundColor Yellow

$duplicateGroups = $fileHashes.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }
$duplicateGroupCount = $duplicateGroups.Count
$totalDuplicates = 0

foreach ($group in $duplicateGroups) {
    $totalDuplicates += ($group.Value.Count - 1)  # Count duplicates (excluding first as original)
}

Write-Host "  Found $duplicateGroupCount duplicate groups" -ForegroundColor Green
Write-Host "  Total duplicate files: $totalDuplicates" -ForegroundColor Green

if ($duplicateGroupCount -eq 0) {
    Write-Host "  No duplicate files found!" -ForegroundColor Green
    exit 0
}

# 4. Create cleaning plan
Write-Host "`n4. Creating cleaning plan..." -ForegroundColor Yellow

$cleaningPlan = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Source = $workspacePath
    TotalFiles = $totalFiles
    DuplicateGroups = $duplicateGroupCount
    TotalDuplicates = $totalDuplicates
    BackupDirectory = $backupDir
    Groups = @()
    Actions = @()
}

$actionCount = 0
foreach ($group in $duplicateGroups) {
    $files = $group.Value
    $original = $files[0]  # Keep the first file as original
    
    $groupInfo = @{
        Hash = $group.Key
        FileCount = $files.Count
        FileSize = $files[0].Size
        Original = $original
        Duplicates = $files[1..($files.Count-1)]
    }
    
    $cleaningPlan.Groups += $groupInfo
    
    # Plan to move duplicates to backup
    foreach ($duplicate in $groupInfo.Duplicates) {
        $relativePath = $duplicate.Path.Replace($workspacePath, "").TrimStart("\")
        $backupPath = Join-Path $backupDir $relativePath
        
        # Create directory structure in backup
        $backupDirPath = Split-Path $backupPath -Parent
        if (-not (Test-Path $backupDirPath)) {
            New-Item -ItemType Directory -Path $backupDirPath -Force | Out-Null
        }
        
        $action = @{
            Type = "Move"
            Source = $duplicate.Path
            Destination = $backupPath
            Reason = "Duplicate of $($original.Path)"
            FileSize = $duplicate.Size
        }
        
        $cleaningPlan.Actions += $action
        $actionCount++
    }
}

Write-Host "  Cleaning plan created: $actionCount actions" -ForegroundColor Green

# 5. Save cleaning plan
Write-Host "`n5. Saving cleaning plan..." -ForegroundColor Yellow

$planFile = Join-Path $reportDir "cleaning-plan-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$cleaningPlan | ConvertTo-Json -Depth 4 | Out-File $planFile -Encoding UTF8

Write-Host "  Cleaning plan saved: $planFile" -ForegroundColor Green

# 6. Preview actions (dry run)
Write-Host "`n6. Preview of cleaning actions (DRY RUN):" -ForegroundColor Yellow
Write-Host "   (No files will be moved in preview mode)" -ForegroundColor Gray
Write-Host ""

$previewCount = [math]::Min(5, $cleaningPlan.Actions.Count)
for ($i = 0; $i -lt $previewCount; $i++) {
    $action = $cleaningPlan.Actions[$i]
    Write-Host "  [$($i+1)] Move: $($action.Source)" -ForegroundColor Gray
    Write-Host "       To: $($action.Destination)" -ForegroundColor Gray
    Write-Host "       Size: $($action.FileSize)" -ForegroundColor Gray
    Write-Host ""
}

if ($cleaningPlan.Actions.Count -gt $previewCount) {
    Write-Host "  ... and $($cleaningPlan.Actions.Count - $previewCount) more actions" -ForegroundColor Gray
}

# 7. Ask for confirmation
Write-Host "`n7. Confirmation required:" -ForegroundColor Cyan
Write-Host "   Total actions: $actionCount" -ForegroundColor White
Write-Host "   Backup directory: $backupDir" -ForegroundColor White
Write-Host "   Report directory: $reportDir" -ForegroundColor White
Write-Host ""
Write-Host "   Type 'YES' to proceed with moving duplicate files to backup." -ForegroundColor Yellow
Write-Host "   Type anything else to cancel." -ForegroundColor Gray
Write-Host ""

$confirmation = Read-Host "Your choice"

if ($confirmation -ne "YES") {
    Write-Host "`nOperation cancelled. No files were moved." -ForegroundColor Yellow
    Write-Host "Cleaning plan saved at: $planFile" -ForegroundColor Gray
    exit 0
}

# 8. Execute cleaning
Write-Host "`n8. Executing cleaning actions..." -ForegroundColor Yellow

$executedCount = 0
$failedCount = 0
$skippedCount = 0

foreach ($action in $cleaningPlan.Actions) {
    try {
        # Check if source file still exists
        if (Test-Path $action.Source) {
            # Move file to backup
            Move-Item $action.Source $action.Destination -Force -ErrorAction Stop
            $executedCount++
            
            if ($executedCount % 10 -eq 0) {
                Write-Host "  Moved $executedCount/$actionCount files" -ForegroundColor Gray
            }
        } else {
            Write-Host "  Skipped: $($action.Source) (file not found)" -ForegroundColor Yellow
            $skippedCount++
        }
    } catch {
        Write-Host "  Failed: $($action.Source) (error: $_)" -ForegroundColor Red
        $failedCount++
    }
}

# 9. Generate final report
Write-Host "`n9. Generating final report..." -ForegroundColor Yellow

$finalReport = @{
    ExecutionTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    TotalActions = $actionCount
    Executed = $executedCount
    Failed = $failedCount
    Skipped = $skippedCount
    SpaceSaved = "0 KB"  # Would need to calculate actual space
    BackupLocation = $backupDir
    PlanFile = $planFile
}

$reportFile = Join-Path $reportDir "cleaning-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$finalReport | ConvertTo-Json -Depth 3 | Out-File $reportFile -Encoding UTF8

# Create human-readable report
$humanReport = @"
# Duplicate File Cleaning Report
## Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
## Source: $workspacePath

## Summary:
- Total duplicate files found: $totalDuplicates
- Duplicate groups: $duplicateGroupCount
- Cleaning actions planned: $actionCount
- Actions executed: $executedCount
- Actions failed: $failedCount
- Actions skipped: $skippedCount

## Details:
- Backup directory: $backupDir
- Cleaning plan: $planFile
- Execution report: $reportFile

## Files Processed:
$(if ($executedCount -gt 0) {
    "$executedCount files moved to backup"
} else {
    "No files were moved (dry run or cancelled)"
})

## Next Steps:
1. Review files in backup directory: $backupDir
2. Check cleaning plan for details: $planFile
3. If satisfied, you can delete the backup directory
4. If issues, restore files from backup

## Safety Notes:
- Files were MOVED (not deleted) to backup
- Original directory structure preserved in backup
- Review backup before deleting anything

---
*OpenClaw Duplicate File Cleaner v1.0*
*Safety first - no permanent deletion*
"@

$humanReportFile = Join-Path $reportDir "human-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
$humanReport | Out-File $humanReportFile -Encoding UTF8

Write-Host "  Final report saved: $humanReportFile" -ForegroundColor Green

# 10. Complete
Write-Host "`n=== Cleaning Complete ===" -ForegroundColor Green

if ($executedCount -gt 0) {
    Write-Host "鉁?Successfully moved $executedCount duplicate files to backup" -ForegroundColor Green
    Write-Host "馃搧 Backup location: $backupDir" -ForegroundColor Cyan
} else {
    Write-Host "鈩癸笍  No files were moved (dry run or no duplicates)" -ForegroundColor Cyan
}

Write-Host "馃搳 Reports generated:" -ForegroundColor Cyan
Write-Host "  - Cleaning plan: $planFile" -ForegroundColor Gray
Write-Host "  - Execution report: $reportFile" -ForegroundColor Gray
Write-Host "  - Human-readable: $humanReportFile" -ForegroundColor Gray

Write-Host "`nSafety check:" -ForegroundColor Yellow
Write-Host "  Review backup directory before deleting: $backupDir" -ForegroundColor Gray
Write-Host "  All files are safely backed up, not permanently deleted" -ForegroundColor Gray

Write-Host "`nView reports:" -ForegroundColor Yellow
Write-Host "  Get-Content $humanReportFile" -ForegroundColor Gray
Write-Host "  Get-ChildItem $backupDir -Recurse -File | Select-Object -First 10" -ForegroundColor Gray
