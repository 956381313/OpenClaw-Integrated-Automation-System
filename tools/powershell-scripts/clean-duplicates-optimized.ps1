# OpenClaw Optimized Duplicate File Cleanup
# Version: 1.1.0
# Description: Advanced cleanup with hash verification and smart strategies
# Author: Hell Cat (Digital Ghost Assistant)
# Date: 2026-03-06

param(
    [string]$ReportPath,
    [switch]$Preview,
    [switch]$Test,
    [switch]$Help,
    [string]$Strategy = "KeepNewest"  # KeepNewest, KeepOldest, KeepFirstFound
)

Write-Host "=== OpenClaw Optimized Duplicate File Cleanup ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "Cleanup Strategy: $Strategy" -ForegroundColor Gray
Write-Host ""

if ($Help) {
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\clean-duplicates-optimized.ps1 [-ReportPath <path>] [-Preview] [-Test] [-Help] [-Strategy KeepNewest|KeepOldest|KeepFirstFound]" -ForegroundColor Gray
    exit 0
}

# Find latest hash report if not specified
if (-not $ReportPath) {
    $reportDir = "modules/duplicate/reports"
    if (Test-Path $reportDir) {
        $latestReport = Get-ChildItem $reportDir -Filter "scan-hash-report-*.json" | 
            Sort-Object LastWriteTime -Descending | 
            Select-Object -First 1
        
        if ($latestReport) {
            $ReportPath = $latestReport.FullName
            Write-Host "Using latest hash report: $ReportPath" -ForegroundColor Green
        } else {
            Write-Host "WARNING: No hash reports found, looking for text reports..." -ForegroundColor Yellow
            
            $latestTextReport = Get-ChildItem $reportDir -Filter "scan-report-*.txt" | 
                Sort-Object LastWriteTime -Descending | 
                Select-Object -First 1
            
            if ($latestTextReport) {
                $ReportPath = $latestTextReport.FullName
                Write-Host "Using text report: $ReportPath" -ForegroundColor Green
            } else {
                Write-Host "ERROR: No scan reports found" -ForegroundColor Red
                Write-Host "Run scan-duplicates-hash.ps1 first" -ForegroundColor Yellow
                exit 1
            }
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

# Determine report type and load accordingly
$reportExtension = [System.IO.Path]::GetExtension($ReportPath)

if ($reportExtension -eq ".json") {
    # Load JSON report
    try {
        $report = Get-Content $ReportPath -Raw | ConvertFrom-Json
        $duplicates = $report.Duplicates
        Write-Host "Loaded JSON report with $($duplicates.Count) duplicate groups" -ForegroundColor Green
    } catch {
        Write-Host "ERROR: Cannot parse JSON report" -ForegroundColor Red
        exit 1
    }
} else {
    # Load text report (simplified parsing)
    Write-Host "WARNING: Using text report - hash verification not available" -ForegroundColor Yellow
    $reportContent = Get-Content $ReportPath -Raw
    $lines = $reportContent -split "`n"
    
    $duplicates = @()
    $currentGroup = $null
    $inGroup = $false
    
    foreach ($line in $lines) {
        if ($line -match "Group.*Size: ([\d\.]+) MB.*Files: (\d+).*Waste: ([\d\.]+) MB") {
            if ($currentGroup) {
                $duplicates += $currentGroup
            }
            $currentGroup = @{
                SizeMB = [decimal]$matches[1]
                Count = [int]$matches[2]
                WastedMB = [decimal]$matches[3]
                Files = @()
                Hash = $null
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
            $inGroup = $false
        }
    }
    
    if ($currentGroup) {
        $duplicates += $currentGroup
    }
    
    Write-Host "Parsed $($duplicates.Count) duplicate groups from text report" -ForegroundColor Green
}

if ($duplicates.Count -eq 0) {
    Write-Host "No duplicates to clean up" -ForegroundColor Yellow
    exit 0
}

# Create backup directory
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupDir = "modules/duplicate/backup\optimized-cleanup-$timestamp"
if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    Write-Host "Created backup directory: $backupDir" -ForegroundColor Green
}

# Process each group with strategy
$filesToDelete = @()
$filesToKeep = @()
$totalSpace = 0
$skippedGroups = 0

Write-Host "`nProcessing duplicate groups with '$Strategy' strategy..." -ForegroundColor Yellow

foreach ($group in $duplicates) {
    # Skip small waste groups (optimization)
    if ($group.WastedMB -lt 0.1) {
        $skippedGroups++
        continue
    }
    
    Write-Host "`nGroup (Size: $($group.SizeMB) MB, Files: $($group.Count), Waste: $($group.WastedMB) MB):" -ForegroundColor Cyan
    
    # Apply strategy
    $files = $group.Files
    
    switch ($Strategy) {
        "KeepNewest" {
            # Sort by last write time, keep newest
            $filesWithTime = @()
            foreach ($file in $files) {
                if (Test-Path $file.Path) {
                    $lastWrite = (Get-Item $file.Path).LastWriteTime
                    $filesWithTime += @{
                        Path = $file.Path
                        Name = $file.Name
                        LastWrite = $lastWrite
                    }
                }
            }
            
            $sortedFiles = $filesWithTime | Sort-Object LastWrite -Descending
            if ($sortedFiles.Count -gt 0) {
                $keepFile = $sortedFiles[0]
                $deleteFiles = $sortedFiles | Select-Object -Skip 1
            }
        }
        "KeepOldest" {
            # Sort by last write time, keep oldest
            $filesWithTime = @()
            foreach ($file in $files) {
                if (Test-Path $file.Path) {
                    $lastWrite = (Get-Item $file.Path).LastWriteTime
                    $filesWithTime += @{
                        Path = $file.Path
                        Name = $file.Name
                        LastWrite = $lastWrite
                    }
                }
            }
            
            $sortedFiles = $filesWithTime | Sort-Object LastWrite
            if ($sortedFiles.Count -gt 0) {
                $keepFile = $sortedFiles[0]
                $deleteFiles = $sortedFiles | Select-Object -Skip 1
            }
        }
        default {  # KeepFirstFound
            # Keep first file in list
            $keepFile = $files[0]
            $deleteFiles = $files | Select-Object -Skip 1
        }
    }
    
    if ($keepFile) {
        Write-Host "  Keep: $($keepFile.Name)" -ForegroundColor Green
        Write-Host "    Path: $($keepFile.Path)" -ForegroundColor Gray
        
        $filesToKeep += @{
            Path = $keepFile.Path
            Name = $keepFile.Name
            Strategy = $Strategy
        }
        
        foreach ($deleteFile in $deleteFiles) {
            Write-Host "  Delete: $($deleteFile.Name)" -ForegroundColor $(if ($Preview) { "Yellow" } else { "Red" })
            Write-Host "    Path: $($deleteFile.Path)" -ForegroundColor Gray
            
            $filesToDelete += @{
                Path = $deleteFile.Path
                Name = $deleteFile.Name
                SizeMB = $group.SizeMB
                Group = $group
                Strategy = $Strategy
            }
        }
        
        $totalSpace += $group.WastedMB
    }
}

Write-Host "`n=== Cleanup Summary ===" -ForegroundColor Cyan
Write-Host "Total groups: $($duplicates.Count)" -ForegroundColor Gray
Write-Host "Skipped groups (waste < 0.1MB): $skippedGroups" -ForegroundColor Gray
Write-Host "Files to keep: $($filesToKeep.Count)" -ForegroundColor Green
Write-Host "Files to delete: $($filesToDelete.Count)" -ForegroundColor $(if ($Preview) { "Yellow" } else { "Red" })
Write-Host "Space to recover: $totalSpace MB" -ForegroundColor Green
Write-Host "Backup directory: $backupDir" -ForegroundColor Gray
Write-Host "Strategy: $Strategy" -ForegroundColor Gray
Write-Host "Mode: $(if ($Preview) { 'PREVIEW (no files will be deleted)' } else { 'LIVE (files will be deleted)' })" -ForegroundColor $(if ($Preview) { "Yellow" } else { "Red" })

if ($Test) {
    Write-Host "Test mode: Limited to first 10 files" -ForegroundColor Yellow
    $filesToDelete = $filesToDelete | Select-Object -First 10
}

# Auto-confirm for non-interactive execution
if (-not $Preview) {
    Write-Host "`n鈿狅笍 AUTO-CONFIRM: Deleting $($filesToDelete.Count) files..." -ForegroundColor Red
}

# Perform cleanup
$deletedCount = 0
$backupCount = 0
$errors = @()

foreach ($file in $filesToDelete) {
    try {
        if (Test-Path $file.Path) {
            # Backup before deletion
            $backupFileName = "$timestamp-$(Split-Path $file.Path -Leaf)"
            $backupPath = Join-Path $backupDir $backupFileName
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
OpenClaw Optimized Duplicate File Cleanup Report
================================================
Cleanup Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Mode: $(if ($Preview) { 'Preview' } else { 'Live' })
Strategy: $Strategy
Report: $ReportPath

Summary:
- Total duplicate groups: $($duplicates.Count)
- Skipped groups (waste < 0.1MB): $skippedGroups
- Files kept: $($filesToKeep.Count)
- Files deleted: $deletedCount
- Files backed up: $backupCount
- Space recovered: $totalSpace MB
- Backup directory: $backupDir

Files Kept (Strategy: $Strategy):
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
Report generated by OpenClaw Optimized Duplicate File Cleanup v1.1.0
"@

# Save cleanup report
$cleanupReportFile = "modules/duplicate/reports\optimized-cleanup-report-$timestamp.txt"
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
