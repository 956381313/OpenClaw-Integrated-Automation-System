# Simple merge and rename script

Write-Host "File Merge and Rename" -ForegroundColor Cyan
Write-Host "====================="
Write-Host "Start: $(Get-Date -Format 'HH:mm:ss')"
Write-Host ""

# 1. Show current files
Write-Host "1. Current files:" -ForegroundColor Yellow
$files = Get-ChildItem -File
Write-Host "   Count: $($files.Count)" -ForegroundColor Gray
$files | Format-Table Name, @{Label="Size(KB)";Expression={[math]::Round($_.Length/1KB,2)}} -AutoSize
Write-Host ""

# 2. Rename long filenames
Write-Host "2. Renaming files..." -ForegroundColor Yellow
$renameOperations = @(
    @{Old="AUTOMATION-SYSTEM-FINAL-REPORT.md"; New="automation-final-report.md"},
    @{Old="AUTOMATION-SYSTEM-GUIDE.md"; New="automation-guide.md"},
    @{Old="FINAL-OPTIMIZATION-SUMMARY.md"; New="optimization-summary.md"},
    @{Old="FINAL-SETUP-GUIDE.md"; New="setup-guide.md"},
    @{Old="FINAL-STEP-GUIDE.txt"; New="quick-setup.txt"},
    @{Old="MAINTENANCE-EXECUTION-SUMMARY.md"; New="maintenance-summary.md"},
    @{Old="PROJECT-COMPLETION-REPORT.md"; New="project-completion.md"},
    @{Old="REPORT-SUMMARY-20260308.md"; New="report-summary.md"},
    @{Old="RUN-ME-AS-ADMIN.bat"; New="run-as-admin.bat"}
)

$renamed = 0
foreach ($op in $renameOperations) {
    if (Test-Path $op.Old) {
        try {
            Rename-Item -Path $op.Old -NewName $op.New -Force -ErrorAction Stop
            Write-Host "   $($op.Old) -> $($op.New)" -ForegroundColor Gray
            $renamed++
        } catch {
            Write-Host "   Failed: $($op.Old)" -ForegroundColor Yellow
        }
    }
}
Write-Host "   Renamed: $renamed files" -ForegroundColor Green
Write-Host ""

# 3. Move duplicate auto-system scripts to archive
Write-Host "3. Managing auto-system scripts..." -ForegroundColor Yellow
$autoScripts = Get-ChildItem -File -Filter "*auto-system*.ps1"
if ($autoScripts.Count -gt 1) {
    Write-Host "   Found $($autoScripts.Count) auto-system scripts" -ForegroundColor Gray
    
    # Keep auto-system-english.ps1 as main
    $mainScript = $autoScripts | Where-Object { $_.Name -eq "auto-system-english.ps1" }
    if ($mainScript) {
        Write-Host "   Main script: $($mainScript.Name)" -ForegroundColor Green
        
        # Move others to archive
        $others = $autoScripts | Where-Object { $_.Name -ne "auto-system-english.ps1" }
        foreach ($script in $others) {
            $archivePath = Join-Path "archive" $script.Name
            Move-Item -Path $script.FullName -Destination $archivePath -Force -ErrorAction SilentlyContinue
            if ($?) {
                Write-Host "   Moved to archive: $($script.Name)" -ForegroundColor DarkGray
            }
        }
    }
} else {
    Write-Host "   Auto-system scripts already consolidated" -ForegroundColor Green
}
Write-Host ""

# 4. Merge very small files
Write-Host "4. Merging small files..." -ForegroundColor Yellow
$smallFiles = Get-ChildItem -File | Where-Object { $_.Length -lt 50 }  # Less than 50 bytes
if ($smallFiles.Count -gt 0) {
    Write-Host "   Found $($smallFiles.Count) small files" -ForegroundColor Gray
    
    # Create merged file
    $mergedContent = "# Merged Small Files - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`n"
    foreach ($file in $smallFiles) {
        try {
            $content = Get-Content -Path $file.FullName -Raw -ErrorAction Stop
            $mergedContent += "=== $($file.Name) ===`n$content`n`n"
        } catch {
            Write-Host "   Skip: $($file.Name)" -ForegroundColor DarkGray
        }
    }
    
    # Save merged file
    $mergedFile = "merged-small-files.txt"
    $mergedContent | Out-File -FilePath $mergedFile -Encoding UTF8
    Write-Host "   Created: $mergedFile" -ForegroundColor Green
    
    # Move original files to archive
    foreach ($file in $smallFiles) {
        $archivePath = Join-Path "archive" $file.Name
        Move-Item -Path $file.FullName -Destination $archivePath -Force -ErrorAction SilentlyContinue
    }
    Write-Host "   Original files moved to archive" -ForegroundColor Gray
} else {
    Write-Host "   No small files to merge" -ForegroundColor Gray
}
Write-Host ""

# 5. Show final state
Write-Host "5. Final state:" -ForegroundColor Yellow
$finalFiles = Get-ChildItem -File
Write-Host "   File count: $($finalFiles.Count)" -ForegroundColor Gray
$finalFiles | Select-Object Name, @{Label="Size(KB)";Expression={[math]::Round($_.Length/1KB,2)}} | Format-Table -AutoSize
Write-Host ""

Write-Host "=== Merge and Rename Complete ===" -ForegroundColor Green
Write-Host "End: $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Gray
Write-Host "Workspace files optimized!" -ForegroundColor Gray