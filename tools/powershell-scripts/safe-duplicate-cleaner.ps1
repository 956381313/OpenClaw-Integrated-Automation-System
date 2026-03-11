# Safe Duplicate File Cleaner (Conservative Approach)

Write-Host "=== OpenClaw Safe Duplicate File Cleaner ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

Write-Host "This cleaner uses a conservative approach:" -ForegroundColor Yellow
Write-Host "鈥?Only cleans exact duplicates (same hash)" -ForegroundColor Gray
Write-Host "鈥?Only cleans backup directories" -ForegroundColor Gray
Write-Host "鈥?Preserves original files" -ForegroundColor Gray
Write-Host "鈥?Creates detailed reports" -ForegroundColor Gray
Write-Host ""

# Configuration
$workspacePath = "C:\Users\luchaochao\.openclaw\workspace"
$backupDirs = @(
    "modules/backup/data",
    "backups/system",
    "services/github/cloud-backup\simple-backups",
    "services/github/cloud-backup\backups"
)

$reportDir = "duplicate-cleaning-reports"
$maxFileSizeMB = 10  # Smaller limit for safety

# Create report directory
if (-not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    Write-Host "Created report directory: $reportDir" -ForegroundColor Green
}

Write-Host "1. Scanning backup directories for duplicates..." -ForegroundColor Yellow

# Collect files from backup directories only
$filesToCheck = @()
foreach ($backupDir in $backupDirs) {
    $fullPath = Join-Path $workspacePath $backupDir
    if (Test-Path $fullPath) {
        $files = Get-ChildItem $fullPath -Recurse -File -ErrorAction SilentlyContinue | 
            Where-Object { $_.Length -lt ($maxFileSizeMB * 1MB) } |
            Where-Object { $_.Extension -match '\.(md|txt|ps1|bat|json|log|yml|yaml|xml)$' }
        
        $filesToCheck += $files
        Write-Host "  Found $($files.Count) files in $backupDir" -ForegroundColor Gray
    }
}

$totalFiles = $filesToCheck.Count
Write-Host "  Total files to analyze: $totalFiles" -ForegroundColor Green

if ($totalFiles -eq 0) {
    Write-Host "No files found in backup directories" -ForegroundColor Yellow
    exit 0
}

# 2. Calculate hashes for backup files only
Write-Host "`n2. Calculating file hashes (backup files only)..." -ForegroundColor Yellow

$fileHashes = @{}
$processedCount = 0

foreach ($file in $filesToCheck) {
    try {
        $hash = Get-FileHash $file.FullName -Algorithm MD5 -ErrorAction Stop
        
        if (-not $fileHashes.ContainsKey($hash.Hash)) {
            $fileHashes[$hash.Hash] = @()
        }
        
        $fileHashes[$hash.Hash] += @{
            Path = $file.FullName
            Name = $file.Name
            Size = "$([math]::Round($file.Length / 1KB, 2)) KB"
            Directory = Split-Path $file.FullName -Parent
            IsBackup = $true
        }
        
        $processedCount++
        
        if ($processedCount % 50 -eq 0) {
            Write-Host "  Processed $processedCount/$totalFiles files" -ForegroundColor Gray
        }
        
    } catch {
        Write-Host "  Skipped: $($file.Name)" -ForegroundColor Yellow
    }
}

Write-Host "  Hash calculation complete" -ForegroundColor Green

# 3. Identify duplicates in backup directories
Write-Host "`n3. Identifying duplicates in backup directories..." -ForegroundColor Yellow

$duplicateGroups = $fileHashes.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }
$duplicateGroupCount = $duplicateGroups.Count
$totalDuplicates = 0

foreach ($group in $duplicateGroups) {
    $totalDuplicates += ($group.Value.Count - 1)
}

Write-Host "  Found $duplicateGroupCount duplicate groups in backup directories" -ForegroundColor Green
Write-Host "  Total duplicate backup files: $totalDuplicates" -ForegroundColor Green

if ($duplicateGroupCount -eq 0) {
    Write-Host "  No duplicate files found in backup directories!" -ForegroundColor Green
    
    # Create report anyway
    $report = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Source = $workspacePath
        ScannedDirectories = $backupDirs
        TotalFiles = $totalFiles
        DuplicateGroups = 0
        TotalDuplicates = 0
        Status = "No duplicates found"
    }
    
    $reportFile = Join-Path $reportDir "no-duplicates-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $report | ConvertTo-Json -Depth 3 | Out-File $reportFile -Encoding UTF8
    
    Write-Host "  Report saved: $reportFile" -ForegroundColor Green
    exit 0
}

# 4. Analyze duplicates and create cleaning suggestions
Write-Host "`n4. Analyzing duplicates and creating suggestions..." -ForegroundColor Yellow

$cleaningSuggestions = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Source = $workspacePath
    ScannedDirectories = $backupDirs
    TotalFiles = $totalFiles
    DuplicateGroups = $duplicateGroupCount
    TotalDuplicates = $totalDuplicates
    Suggestions = @()
    Statistics = @{
        ByDirectory = @{}
        ByExtension = @{}
        BySize = @{
            Small = 0    # < 1KB
            Medium = 0   # 1KB - 10KB
            Large = 0    # > 10KB
        }
    }
}

$suggestionCount = 0
foreach ($group in $duplicateGroups) {
    $files = $group.Value
    
    # Sort by directory depth (prefer to keep files in shallower directories)
    $sortedFiles = $files | Sort-Object { ($_.Path -split '\\').Count }
    
    # Keep the first file (in shallowest directory)
    $keepFile = $sortedFiles[0]
    
    # Suggest removing the rest
    foreach ($file in $sortedFiles[1..($sortedFiles.Count-1)]) {
        $suggestion = @{
            Action = "Consider removing"
            File = $file.Path
            Reason = "Duplicate of $($keepFile.Path)"
            Size = $file.Size
            Hash = $group.Key
            KeepOriginal = $keepFile.Path
        }
        
        $cleaningSuggestions.Suggestions += $suggestion
        $suggestionCount++
        
        # Update statistics
        $dir = Split-Path $file.Path -Parent
        if (-not $cleaningSuggestions.Statistics.ByDirectory.ContainsKey($dir)) {
            $cleaningSuggestions.Statistics.ByDirectory[$dir] = 0
        }
        $cleaningSuggestions.Statistics.ByDirectory[$dir]++
        
        $ext = [System.IO.Path]::GetExtension($file.Path)
        if (-not $cleaningSuggestions.Statistics.ByExtension.ContainsKey($ext)) {
            $cleaningSuggestions.Statistics.ByExtension[$ext] = 0
        }
        $cleaningSuggestions.Statistics.ByExtension[$ext]++
        
        # Size classification
        $sizeKB = [double]($file.Size -replace ' KB', '')
        if ($sizeKB -lt 1) {
            $cleaningSuggestions.Statistics.BySize.Small++
        } elseif ($sizeKB -le 10) {
            $cleaningSuggestions.Statistics.BySize.Medium++
        } else {
            $cleaningSuggestions.Statistics.BySize.Large++
        }
    }
}

Write-Host "  Created $suggestionCount cleaning suggestions" -ForegroundColor Green

# 5. Save suggestions report
Write-Host "`n5. Saving suggestions report..." -ForegroundColor Yellow

$suggestionsFile = Join-Path $reportDir "cleaning-suggestions-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$cleaningSuggestions | ConvertTo-Json -Depth 4 | Out-File $suggestionsFile -Encoding UTF8

Write-Host "  Suggestions saved: $suggestionsFile" -ForegroundColor Green

# 6. Generate human-readable report
Write-Host "`n6. Generating human-readable report..." -ForegroundColor Yellow

$humanReport = @"
# Duplicate File Cleaning Report
## Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
## Source: $workspacePath

## Summary:
- Files scanned: $totalFiles
- Duplicate groups found: $duplicateGroupCount
- Duplicate files: $totalDuplicates
- Cleaning suggestions: $suggestionCount

## Scanned Directories:
$(foreach ($dir in $backupDirs) { "- $dir" })

## Statistics:

### By Directory (top 10):
$(foreach ($dir in ($cleaningSuggestions.Statistics.ByDirectory.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 10)) {
    "- $($dir.Key): $($dir.Value) duplicates"
})

### By File Type:
$(foreach ($ext in ($cleaningSuggestions.Statistics.ByExtension.GetEnumerator() | Sort-Object Value -Descending)) {
    "- $ext: $($ext.Value) duplicates"
})

### By Size:
- Small files (< 1KB): $($cleaningSuggestions.Statistics.BySize.Small)
- Medium files (1KB-10KB): $($cleaningSuggestions.Statistics.BySize.Medium)
- Large files (> 10KB): $($cleaningSuggestions.Statistics.BySize.Large)

## Top Duplicate Files (sample):
$(foreach ($suggestion in $cleaningSuggestions.Suggestions | Select-Object -First 5) {
    "- **$([System.IO.Path]::GetFileName($suggestion.File))** ($($suggestion.Size))"
    "  Duplicate of: $([System.IO.Path]::GetFileName($suggestion.KeepOriginal))"
    "  Location: $($suggestion.File)"
    ""
})

## Recommendations:

### Safe to Remove:
1. **Small configuration files** (< 1KB) - Often exact copies
2. **Backup directory duplicates** - Multiple backup copies
3. **Temporary/log files** - Old log files with same content

### Review Before Removing:
1. **Medium files** (1KB-10KB) - Check if actually needed
2. **Script files** - Ensure not different versions
3. **Documentation files** - Check for updates

### Keep:
1. **Large files** (> 10KB) - May have important differences
2. **Non-backup directory files** - Could be working copies
3. **Recently modified files** - May be actively used

## Next Steps:

### Option 1: Manual Review
1. Review suggestions in: $suggestionsFile
2. Manually delete confirmed duplicates
3. Use Windows Explorer or command line

### Option 2: Automated Cleaning (SAFE)
1. Run conservative cleaner script
2. Only remove small, exact duplicates
3. Keep backup of removed files

### Option 3: Do Nothing
1. Keep all files as-is
2. Monitor disk space
3. Run cleaner periodically

## Safety Notes:
- This is a SUGGESTION report only
- No files have been deleted
- Always review before deleting
- Consider backing up before cleaning

## Estimated Space Savings:
Based on average file sizes:
- Small files: ~$($cleaningSuggestions.Statistics.BySize.Small * 0.5) KB
- Medium files: ~$($cleaningSuggestions.Statistics.BySize.Medium * 5) KB
- Large files: ~$($cleaningSuggestions.Statistics.BySize.Large * 20) KB
**Total: ~$([math]::Round(($cleaningSuggestions.Statistics.BySize.Small * 0.5 + $cleaningSuggestions.Statistics.BySize.Medium * 5 + $cleaningSuggestions.Statistics.BySize.Large * 20) / 1024, 2)) MB**

---
*OpenClaw Safe Duplicate File Cleaner v1.0*
*Safety first - suggestions only, no automatic deletion*
"@

$humanReportFile = Join-Path $reportDir "human-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
$humanReport | Out-File $humanReportFile -Encoding UTF8

Write-Host "  Human-readable report: $humanReportFile" -ForegroundColor Green

# 7. Create quick action script
Write-Host "`n7. Creating quick action script..." -ForegroundColor Yellow

$quickScript = @'
# Quick Duplicate Cleaner Actions

Write-Host "=== Quick Duplicate Cleaner Actions ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

Write-Host "Based on the duplicate analysis, here are quick actions:" -ForegroundColor Yellow
Write-Host ""

# Read suggestions
$suggestionsFile = Get-ChildItem "duplicate-cleaning-reports" -Filter "*suggestions*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if ($suggestionsFile) {
    $suggestions = Get-Content $suggestionsFile.FullName | ConvertFrom-Json
    
    Write-Host "Found $($suggestions.TotalDuplicates) duplicate files" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "Quick actions:" -ForegroundColor Cyan
    Write-Host "1. Review small files (< 1KB)" -ForegroundColor Gray
    Write-Host "   Count: $($suggestions.Statistics.BySize.Small)" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "2. Clean backup directories:" -ForegroundColor Gray
    foreach ($dir in $suggestions.ScannedDirectories) {
        Write-Host "   - $dir" -ForegroundColor Gray
    }
    Write-Host ""
    
    Write-Host "3. View full report:" -ForegroundColor Gray
    Write-Host "   Get-Content $($suggestionsFile.FullName) | ConvertFrom-Json | Select-Object -First 5" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "4. Manual cleaning command (example):" -ForegroundColor Gray
    Write-Host "   # Remove one duplicate file" -ForegroundColor Gray
    Write-Host "   Remove-Item 'C:\path\to\duplicate.txt' -WhatIf" -ForegroundColor Gray
    
} else {
    Write-Host "No suggestions file found" -ForegroundColor Yellow
    Write-Host "Run the safe duplicate cleaner first" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Remember: Always use -WhatIf flag first to preview deletions" -ForegroundColor Yellow
Write-Host "Example: Remove-Item file.txt -WhatIf" -ForegroundColor Gray
'@

$quickScriptFile = "quick-duplicate-actions.ps1"
$quickScript | Out-File $quickScriptFile -Encoding UTF8

Write-Host "  Quick action script: $quickScriptFile" -ForegroundColor Green

# 8. Complete
Write-Host "`n=== Safe Duplicate Analysis Complete ===" -ForegroundColor Green
Write-Host "Files scanned: $totalFiles" -ForegroundColor Cyan
Write-Host "Duplicate files found: $totalDuplicates" -ForegroundColor Cyan
Write-Host "Cleaning suggestions: $suggestionCount" -ForegroundColor Cyan

Write-Host "`nGenerated reports:" -ForegroundColor Yellow
Write-Host "  鈥?Suggestions: $suggestionsFile" -ForegroundColor Gray
Write-Host "  鈥?Human report: $humanReportFile" -ForegroundColor Gray
Write-Host "  鈥?Quick actions: $quickScriptFile" -ForegroundColor Gray

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Review the human report: $humanReportFile" -ForegroundColor Gray
Write-Host "2. Check suggestions file for details" -ForegroundColor Gray
Write-Host "3. Use quick action script for guidance" -ForegroundColor Gray
Write-Host "4. Manually clean confirmed duplicates" -ForegroundColor Gray

Write-Host "`nSafety reminder:" -ForegroundColor Red
Write-Host "  NO files were deleted in this analysis" -ForegroundColor White
Write-Host "  Review all suggestions before taking action" -ForegroundColor White
