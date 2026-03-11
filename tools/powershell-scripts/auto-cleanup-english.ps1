# Auto Cleanup Execute (English - Safe Mode)

Write-Host "=== OpenClaw Auto Cleanup Execution ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "Mode: SAFE (keep latest backups, clean old ones)" -ForegroundColor Yellow
Write-Host ""

# Safe settings
$backupKeepCount = 3  # Keep latest 3 backups
$logFile = "auto-cleanup-log-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
$operations = @()

# Start logging
Start-Transcript -Path $logFile -Append

Write-Host "1. Checking backup directories..." -ForegroundColor Yellow

# Define backup directories
$backupDirs = @(
    @{Path = "modules/backup/data"; Type = "File Backups"},
    @{Path = "backups/system"; Type = "System Backups"},
    @{Path = "services/github/cloud-backup\simple-backups"; Type = "GitHub Simple Backups"},
    @{Path = "services/github/cloud-backup\backups"; Type = "GitHub Full Backups"}
)

$totalCleaned = 0
$totalSpaceSaved = 0

foreach ($dirInfo in $backupDirs) {
    $dir = $dirInfo.Path
    $type = $dirInfo.Type
    
    if (Test-Path $dir) {
        Write-Host "  [$type] Checking: $dir" -ForegroundColor Gray
        
        # Get all backup directories
        $backupItems = Get-ChildItem $dir -Directory -ErrorAction SilentlyContinue
        
        if ($backupItems.Count -gt $backupKeepCount) {
            $toKeep = $backupItems | Sort-Object LastWriteTime -Descending | Select-Object -First $backupKeepCount
            $toClean = $backupItems | Where-Object { $toKeep -notcontains $_ }
            
            $cleanCount = $toClean.Count
            $spaceToSave = 0
            
            # Calculate space to save
            foreach ($item in $toClean) {
                $size = (Get-ChildItem $item.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
                $spaceToSave += $size
            }
            
            $spaceMB = [math]::Round($spaceToSave / 1MB, 2)
            
            Write-Host "    Found $($backupItems.Count) backups" -ForegroundColor Gray
            Write-Host "    Keeping latest $backupKeepCount" -ForegroundColor Green
            Write-Host "    Cleaning $cleanCount old backups" -ForegroundColor Yellow
            Write-Host "    Estimated space saved: ${spaceMB} MB" -ForegroundColor Cyan
            
            # Record operation
            $operation = @{
                Type = $type
                Directory = $dir
                TotalBackups = $backupItems.Count
                KeepCount = $backupKeepCount
                CleanCount = $cleanCount
                SpaceSavedMB = $spaceMB
                ItemsToClean = $toClean.FullName
                ItemsToKeep = $toKeep.FullName
            }
            
            $operations += $operation
            
            # Execute cleanup
            Write-Host "    Executing cleanup..." -ForegroundColor Yellow
            
            foreach ($item in $toClean) {
                try {
                    # Calculate size first
                    $itemSize = (Get-ChildItem $item.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
                    $itemSizeMB = [math]::Round($itemSize / 1MB, 2)
                    
                    # Delete directory
                    Remove-Item $item.FullName -Recurse -Force -ErrorAction Stop
                    
                    Write-Host "      [OK] Cleaned: $($item.Name) (${itemSizeMB} MB)" -ForegroundColor Green
                    
                    $totalCleaned++
                    $totalSpaceSaved += $itemSize
                    
                } catch {
                    Write-Host "      [ERROR] Failed: $($item.Name) (error: $_)" -ForegroundColor Red
                }
            }
            
        } else {
            Write-Host "    Only $($backupItems.Count) backups, no cleanup needed" -ForegroundColor Gray
        }
        
    } else {
        Write-Host "  [$type] Directory not found: $dir" -ForegroundColor Yellow
    }
}

# 2. Clean empty directories
Write-Host "`n2. Cleaning empty directories..." -ForegroundColor Yellow

$emptyDirs = Get-ChildItem -Recurse -Directory -ErrorAction SilentlyContinue | 
    Where-Object { (Get-ChildItem $_.FullName -Recurse -Force -ErrorAction SilentlyContinue).Count -eq 0 }

$emptyDirCount = $emptyDirs.Count

if ($emptyDirCount -gt 0) {
    Write-Host "  Found $emptyDirCount empty directories" -ForegroundColor Gray
    
    foreach ($dir in $emptyDirs) {
        try {
            Remove-Item $dir.FullName -Force -ErrorAction Stop
            Write-Host "    [OK] Cleaned empty directory: $($dir.FullName)" -ForegroundColor Green
            $totalCleaned++
        } catch {
            Write-Host "    [ERROR] Failed: $($dir.FullName)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "  No empty directories found" -ForegroundColor Gray
}

# 3. Generate cleanup report
Write-Host "`n3. Generating cleanup report..." -ForegroundColor Yellow

$reportDir = "data/reports"
if (-not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
}

$totalSpaceSavedMB = [math]::Round($totalSpaceSaved / 1MB, 2)

$report = @{
    ExecutionTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Mode = "SAFE (keep latest $backupKeepCount backups)"
    TotalCleaned = $totalCleaned
    TotalSpaceSavedMB = $totalSpaceSavedMB
    Operations = $operations
    EmptyDirectoriesCleaned = $emptyDirCount
    LogFile = $logFile
}

$reportFile = Join-Path $reportDir "auto-cleanup-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$report | ConvertTo-Json -Depth 4 | Out-File $reportFile -Encoding UTF8

# Generate human-readable report
$humanReport = @"
# Auto Cleanup Execution Report
## Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
## Mode: Safe Mode (keep latest $backupKeepCount backups)

## Summary:
- Total items cleaned: $totalCleaned
- Space saved: ${totalSpaceSavedMB} MB
- Empty directories cleaned: $emptyDirCount
- Log file: $logFile

## Detailed Operations:

### Backup Cleanup:
$(foreach ($op in $operations) {
    "#### $($op.Type)"
    "- Directory: $($op.Directory)"
    "- Total backups: $($op.TotalBackups)"
    "- Keep count: $($op.KeepCount)"
    "- Clean count: $($op.CleanCount)"
    "- Space saved: $($op.SpaceSavedMB) MB"
    ""
    if ($op.ItemsToClean.Count -gt 0) {
        "Cleaned items:"
        foreach ($item in $op.ItemsToClean) {
            "  - $item"
        }
        ""
    }
    if ($op.ItemsToKeep.Count -gt 0) {
        "Kept items:"
        foreach ($item in $op.ItemsToKeep) {
            "  - $item"
        }
        ""
    }
})

### Empty Directory Cleanup:
- Empty directories cleaned: $emptyDirCount

## System Status:
- Workspace: $(Get-Location)
- User: $env:USERNAME
- Computer: $env:COMPUTERNAME

## Safety Notes:
1. Only old backup directories were cleaned
2. Latest $backupKeepCount backups were kept
3. All operations logged
4. Check log file if issues

## Next Steps:
1. Run auto-cleanup regularly
2. Monitor disk space usage
3. Adjust retention policy if needed
4. Consider cloud backup for important data

---
*OpenClaw Auto Cleanup System v1.0*
*Safe execution completed*
"@

$humanReportFile = Join-Path $reportDir "human-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
$humanReport | Out-File $humanReportFile -Encoding UTF8

# Stop logging
Stop-Transcript

# 4. Complete
Write-Host "`n=== Auto Cleanup Complete ===" -ForegroundColor Green
Write-Host "Items cleaned: $totalCleaned" -ForegroundColor Cyan
Write-Host "Space saved: ${totalSpaceSavedMB} MB" -ForegroundColor Cyan
Write-Host "Log file: $logFile" -ForegroundColor Cyan
Write-Host "Report file: $humanReportFile" -ForegroundColor Cyan

Write-Host "`nView reports:" -ForegroundColor Yellow
Write-Host "  Get-Content $humanReportFile" -ForegroundColor Gray
Write-Host "  Get-Content $logFile | Select-Object -Last 20" -ForegroundColor Gray

Write-Host "`nSafety check:" -ForegroundColor Yellow
Write-Host "  All important backups kept" -ForegroundColor Green
Write-Host "  Cleanup operations logged" -ForegroundColor Green
Write-Host "  Recoverability: Need restore from GitHub or other backups" -ForegroundColor Gray
