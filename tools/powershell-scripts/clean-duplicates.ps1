# OpenClaw Duplicate File Cleanup
# Version: 1.0.0
# Description: Clean up duplicate files found by scanner
# Author: Hell Cat (Digital Ghost Assistant)
# Date: 2026-03-06

param(
    [string]$ReportPath,
    [switch]$Preview,
    [switch]$Test,
    [switch]$Help
)

Write-Host "=== OpenClaw Duplicate File Cleanup ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

if ($Help) {
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\clean-duplicates.ps1 [-ReportPath <path>] [-Preview] [-Test] [-Help]" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Parameters:" -ForegroundColor Yellow
    Write-Host "  -ReportPath  Path to scan report (default: latest report)" -ForegroundColor Gray
    Write-Host "  -Preview     Preview mode - show what would be deleted" -ForegroundColor Gray
    Write-Host "  -Test        Test mode - limited cleanup" -ForegroundColor Gray
    Write-Host "  -Help        Show this help" -ForegroundColor Gray
    exit 0
}

# Find latest report if not specified
if (-not $ReportPath) {
    $reportDir = "modules/duplicate/reports"
    if (Test-Path $reportDir) {
        $latestReport = Get-ChildItem $reportDir -Filter "scan-report-*.txt" | 
            Sort-Object LastWriteTime -Descending | 
            Select-Object -First 1
        
        if ($latestReport) {
            $ReportPath = $latestReport.FullName
            Write-Host "Using latest report: $ReportPath" -ForegroundColor Green
        } else {
            Write-Host "ERROR: No scan reports found" -ForegroundColor Red
            Write-Host "Run scan-duplicates-simple.ps1 first" -ForegroundColor Yellow
            exit 1
        }
    } else {
        Write-Host "ERROR: Report directory not found" -ForegroundColor Red
        exit 1
    }
}

# Check if report exists
if (-not (Test-Path $ReportPath)) {
    Write-Host "ERROR: Report file not found: $ReportPath" -ForegroundColor Red
    exit 1
}

Write-Host "Loading report: $ReportPath" -ForegroundColor Yellow

# Parse report file (simple text parsing)
$reportContent = Get-Content $ReportPath -Raw
$lines = $reportContent -split "`n"

# Extract duplicate groups
$duplicateGroups = @()
$currentGroup = $null
$inGroup = $false

foreach ($line in $lines) {
    if ($line -match "Group \(Size: ([\d\.]+) MB, Files: (\d+), Waste: ([\d\.]+) MB\):") {
        # Start new group
        if ($currentGroup) {
            $duplicateGroups += $currentGroup
        }
        $currentGroup = @{
            SizeMB = [decimal]$matches[1]
            FileCount = [int]$matches[2]
            WasteMB = [decimal]$matches[3]
            Files = @()
        }
        $inGroup = $true
    } elseif ($inGroup -and $line -match "^\s+-\s+(.+)$") {
        $fileName = $matches[1].Trim()
        $nextLine = $lines[[array]::IndexOf($lines, $line) + 1]
        if ($nextLine -match "^\s{4}(.+)$") {
            $filePath = $matches[1].Trim()
            $currentGroup.Files += @{
                Name = $fileName
                Path = $filePath
            }
        }
    } elseif ($line -match "^\s*$" -and $inGroup) {
        # End of group
        $inGroup = $false
    }
}

# Add last group
if ($currentGroup) {
    $duplicateGroups += $currentGroup
}

Write-Host "Found $($duplicateGroups.Count) duplicate groups in report" -ForegroundColor Green

if ($duplicateGroups.Count -eq 0) {
    Write-Host "No duplicates to clean up" -ForegroundColor Yellow
    exit 0
}

# Create backup directory
$backupDir = "modules/duplicate/backup\cleanup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    Write-Host "Created backup directory: $backupDir" -ForegroundColor Green
}

# Process each group
$filesToDelete = @()
$filesToKeep = @()
$totalSpace = 0

Write-Host "`nProcessing duplicate groups..." -ForegroundColor Yellow

foreach ($group in $duplicateGroups) {
    Write-Host "`nGroup (Size: $($group.SizeMB) MB, Files: $($group.FileCount), Waste: $($group.WasteMB) MB):" -ForegroundColor Cyan
    
    # Strategy: Keep the first file, delete the rest
    $keepFile = $group.Files[0]
    $deleteFiles = $group.Files | Select-Object -Skip 1
    
    Write-Host "  Keep: $($keepFile.Name)" -ForegroundColor Green
    Write-Host "    Path: $($keepFile.Path)" -ForegroundColor Gray
    
    foreach ($deleteFile in $deleteFiles) {
        Write-Host "  Delete: $($deleteFile.Name)" -ForegroundColor $(if ($Preview) { "Yellow" } else { "Red" })
        Write-Host "    Path: $($deleteFile.Path)" -ForegroundColor Gray
        
        $filesToDelete += @{
            Path = $deleteFile.Path
            Name = $deleteFile.Name
            SizeMB = $group.SizeMB
            Group = $group
        }
    }
    
    $filesToKeep += $keepFile
    $totalSpace += $group.WasteMB
}

Write-Host "`n=== Cleanup Summary ===" -ForegroundColor Cyan
Write-Host "Files to keep: $($filesToKeep.Count)" -ForegroundColor Green
Write-Host "Files to delete: $($filesToDelete.Count)" -ForegroundColor $(if ($Preview) { "Yellow" } else { "Red" })
Write-Host "Space to recover: $totalSpace MB" -ForegroundColor Green
Write-Host "Backup directory: $backupDir" -ForegroundColor Gray
Write-Host "Mode: $(if ($Preview) { 'PREVIEW (no files will be deleted)' } else { 'LIVE (files will be deleted)' })" -ForegroundColor $(if ($Preview) { "Yellow" } else { "Red" })

if ($Test) {
    Write-Host "Test mode: Limited to first 5 files" -ForegroundColor Yellow
    $filesToDelete = $filesToDelete | Select-Object -First 5
}

# Ask for confirmation (unless in preview mode)
if (-not $Preview) {
    Write-Host "`n鈿狅笍 WARNING: This will DELETE $($filesToDelete.Count) files!" -ForegroundColor Red
    $confirmation = Read-Host "Type 'YES' to confirm deletion"
    
    if ($confirmation -ne "YES") {
        Write-Host "Cleanup cancelled" -ForegroundColor Yellow
        exit 0
    }
}

# Perform cleanup
$deletedCount = 0
$backupCount = 0
$errors = @()

foreach ($file in $filesToDelete) {
    try {
        if (Test-Path $file.Path) {
            # Backup before deletion
            $backupPath = Join-Path $backupDir (Split-Path $file.Path -Leaf)
            Copy-Item -Path $file.Path -Destination $backupPath -Force
            $backupCount++
            
            if (-not $Preview) {
                # Actually delete the file
                Remove-Item -Path $file.Path -Force
                $deletedCount++
                Write-Host "鉁?Deleted: $($file.Name)" -ForegroundColor Green
            } else {
                Write-Host "鉁?Would delete: $($file.Name)" -ForegroundColor Yellow
            }
        } else {
            Write-Host "鈿狅笍 File not found: $($file.Path)" -ForegroundColor Yellow
        }
    } catch {
        $errorMsg = "Failed to process $($file.Path): $_"
        $errors += $errorMsg
        Write-Host "鉁?$errorMsg" -ForegroundColor Red
    }
}

# Generate cleanup report
$cleanupReport = @"
OpenClaw Duplicate File Cleanup Report
=======================================
Cleanup Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Mode: $(if ($Preview) { 'Preview' } else { 'Live' })
Report: $ReportPath

Summary:
- Files kept: $($filesToKeep.Count)
- Files deleted: $deletedCount
- Files backed up: $backupCount
- Space recovered: $totalSpace MB
- Backup directory: $backupDir

Files Kept:
"@

foreach ($file in $filesToKeep) {
    $cleanupReport += "  - $($file.Name)`n    $($file.Path)`n"
}

$cleanupReport += @"
`nFiles Deleted:
"@

foreach ($file in $filesToDelete) {
    $cleanupReport += "  - $($file.Name)`n    $($file.Path)`n"
}

if ($errors.Count -gt 0) {
    $cleanupReport += @"
`nErrors:
"@
    foreach ($error in $errors) {
        $cleanupReport += "  - $error`n"
    }
}

$cleanupReport += @"
`nRecommendations:
1. Verify important files were not deleted
2. Check backup directory for any needed files
3. Empty backup directory after verification
4. Run scan again to verify cleanup

---
Report generated by OpenClaw Duplicate File Cleanup v1.0.0
"@

# Save cleanup report
$cleanupReportFile = "modules/duplicate/reports\cleanup-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
$cleanupReport | Out-File $cleanupReportFile -Encoding UTF8
Write-Host "`nCleanup report saved: $cleanupReportFile" -ForegroundColor Green

# Final summary
Write-Host "`n=== Cleanup Complete ===" -ForegroundColor Green
if ($Preview) {
    Write-Host "PREVIEW MODE: No files were actually deleted" -ForegroundColor Yellow
} else {
    Write-Host "Files deleted: $deletedCount" -ForegroundColor Green
    Write-Host "Files backed up: $backupCount" -ForegroundColor Gray
    Write-Host "Space recovered: $totalSpace MB" -ForegroundColor Green
}
Write-Host "Backup directory: $backupDir" -ForegroundColor Gray
Write-Host "Cleanup report: $cleanupReportFile" -ForegroundColor Gray

if ($errors.Count -gt 0) {
    Write-Host "`n鈿狅笍 Errors occurred: $($errors.Count)" -ForegroundColor Red
    foreach ($error in $errors) {
        Write-Host "  - $error" -ForegroundColor Yellow
    }
}

Write-Host "`nNext: Run scan again to verify cleanup" -ForegroundColor Cyan
