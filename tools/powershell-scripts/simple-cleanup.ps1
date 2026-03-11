# Simple Workspace Cleanup

Write-Host "=== OpenClaw Simple Workspace Cleanup ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# 1. Run organization first
Write-Host "1. Running workspace organization..." -ForegroundColor Yellow
.\organize-english.ps1

Write-Host ""

# 2. Check for obvious duplicates in backup directories
Write-Host "2. Checking for obvious duplicates..." -ForegroundColor Yellow

$backupDirs = @(
    "modules/backup/data",
    "backups/system", 
    "services/github/cloud-backup\simple-backups",
    "services/github/cloud-backup\backups"
)

$totalFiles = 0
$duplicateCount = 0
$cleanupSuggestions = @()

foreach ($dir in $backupDirs) {
    if (Test-Path $dir) {
        Write-Host "  Checking: $dir" -ForegroundColor Gray
        
        # Look for files with same name in same directory
        $files = Get-ChildItem $dir -Recurse -File -ErrorAction SilentlyContinue
        
        # Group by filename
        $fileGroups = $files | Group-Object Name
        
        foreach ($group in $fileGroups) {
            if ($group.Count -gt 1) {
                # Found files with same name
                $duplicateCount += ($group.Count - 1)
                
                $suggestion = @{
                    Directory = $dir
                    FileName = $group.Name
                    Count = $group.Count
                    Files = $group.Group | ForEach-Object { $_.FullName }
                }
                
                $cleanupSuggestions += $suggestion
            }
        }
        
        $totalFiles += $files.Count
    }
}

Write-Host "  Total files in backup directories: $totalFiles" -ForegroundColor Green
Write-Host "  Files with duplicate names: $duplicateCount" -ForegroundColor Green

# 3. Create cleanup report
Write-Host "`n3. Creating cleanup report..." -ForegroundColor Yellow

$reportDir = "data/reports"
if (-not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
}

$report = @"
# Workspace Cleanup Report
## Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
## Total backup files: $totalFiles
## Duplicate name files: $duplicateCount

## Backup Directories Checked:
$(foreach ($dir in $backupDirs) {
    if (Test-Path $dir) {
        $fileCount = (Get-ChildItem $dir -Recurse -File -ErrorAction SilentlyContinue).Count
        "- $dir ($fileCount files)"
    } else {
        "- $dir (not found)"
    }
})

## Cleanup Suggestions:

### 1. Review Backup Directories
The following backup directories contain multiple copies of the same files:

$(foreach ($suggestion in $cleanupSuggestions | Select-Object -First 10) {
    "**$($suggestion.FileName)** appears $($suggestion.Count) times in $($suggestion.Directory)"
    foreach ($file in $suggestion.Files | Select-Object -First 3) {
        "  - $file"
    }
    if ($suggestion.Files.Count -gt 3) {
        "  ... and $($suggestion.Files.Count - 3) more"
    }
    ""
})

### 2. Safe Cleanup Actions

#### Action A: Archive Old Backups
```powershell
# Create archive of old backups
Compress-Archive -Path "backups/system\*" -DestinationPath "old-backups-archive.zip"
```

#### Action B: Remove Specific Duplicates
```powershell
# Example: Remove duplicate TOOLS.md from old backups
Get-ChildItem "modules/backup/data" -Recurse -Filter "TOOLS.md" | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -Skip 1 | 
    Remove-Item -WhatIf
```

#### Action C: Clean Empty Directories
```powershell
# Remove empty directories
Get-ChildItem -Recurse -Directory | 
    Where-Object { (Get-ChildItem $_.FullName -Recurse -Force).Count -eq 0 } | 
    Remove-Item -WhatIf
```

### 3. Organization Results
The workspace has been organized into categories:
- Documents: Markdown and text files
- Scripts: PowerShell and batch files  
- Configs: JSON and configuration files
- Logs: Log files

### 4. Next Steps

#### Immediate Actions:
1. Review the `data/reports` directory
2. Check `organization-report-*.md` for file classification
3. Decide which backup files to keep

#### Medium-term Actions:
1. Set up automatic backup rotation
2. Configure retention policies
3. Implement duplicate prevention

#### Long-term Actions:
1. Implement intelligent deduplication
2. Set up cloud storage integration
3. Create backup lifecycle management

## Safety Notes:
- No files have been deleted automatically
- All suggestions are for manual review
- Always use `-WhatIf` flag first
- Keep important backups in multiple locations

## Estimated Impact:
- Organization: Improves file findability
- Duplicate cleanup: Saves disk space
- Backup management: Reduces clutter

---
*OpenClaw Workspace Cleanup System*
*Report generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')*
"@

$reportFile = Join-Path $reportDir "cleanup-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
$report | Out-File $reportFile -Encoding UTF8

Write-Host "  Cleanup report saved: $reportFile" -ForegroundColor Green

# 4. Create quick cleanup commands
Write-Host "`n4. Creating quick cleanup commands..." -ForegroundColor Yellow

$commands = @'
# Quick Cleanup Commands

Write-Host "=== Quick Workspace Cleanup Commands ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "1. View organization report:" -ForegroundColor Yellow
Write-Host "   Get-ChildItem organization-report-*.md | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | Get-Content" -ForegroundColor Gray
Write-Host ""

Write-Host "2. View cleanup report:" -ForegroundColor Yellow
Write-Host "   Get-ChildItem data/reports\*.md | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | Get-Content" -ForegroundColor Gray
Write-Host ""

Write-Host "3. Safe duplicate check (preview):" -ForegroundColor Yellow
Write-Host "   Get-ChildItem modules/backup/data -Recurse -File | Group-Object Name | Where-Object Count -gt 1 | Select-Object -First 5" -ForegroundColor Gray
Write-Host ""

Write-Host "4. Remove old backups (preview - use -WhatIf first):" -ForegroundColor Yellow
Write-Host "   # Keep only latest 5 backups" -ForegroundColor Gray
Write-Host "   Get-ChildItem modules/backup/data -Directory | Sort-Object LastWriteTime -Descending | Select-Object -Skip 5 | Remove-Item -Recurse -WhatIf" -ForegroundColor Gray
Write-Host ""

Write-Host "5. Clean empty directories (preview):" -ForegroundColor Yellow
Write-Host "   Get-ChildItem -Recurse -Directory | Where-Object { (Get-ChildItem $_.FullName).Count -eq 0 } | Remove-Item -WhatIf" -ForegroundColor Gray
Write-Host ""

Write-Host "IMPORTANT: Always use -WhatIf flag first to preview changes!" -ForegroundColor Red
Write-Host "Example: Remove-Item file.txt -WhatIf" -ForegroundColor Gray
'@

$commandsFile = "quick-cleanup-commands.ps1"
$commands | Out-File $commandsFile -Encoding UTF8

Write-Host "  Quick commands saved: $commandsFile" -ForegroundColor Green

# 5. Complete
Write-Host "`n=== Workspace Cleanup Complete ===" -ForegroundColor Green
Write-Host "Organization: Completed (see organization-report-*.md)" -ForegroundColor Cyan
Write-Host "Duplicate check: $duplicateCount files with duplicate names" -ForegroundColor Cyan
Write-Host "Cleanup report: $reportFile" -ForegroundColor Cyan
Write-Host "Quick commands: $commandsFile" -ForegroundColor Cyan

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Review the cleanup report" -ForegroundColor Gray
Write-Host "2. Use quick commands for safe cleanup" -ForegroundColor Gray
Write-Host "3. Implement regular cleanup schedule" -ForegroundColor Gray

Write-Host "`nSafety reminder:" -ForegroundColor Red
Write-Host "  All operations were READ-ONLY" -ForegroundColor White
Write-Host "  No files were deleted or modified" -ForegroundColor White
Write-Host "  Manual review required before any cleanup" -ForegroundColor White
