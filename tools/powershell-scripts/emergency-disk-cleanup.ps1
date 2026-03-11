# Emergency Disk Cleanup Script
# For critical disk space situations (>90% usage)

param(
    [string[]]$Drives = @("C:", "E:", "F:", "G:"),
    [switch]$Preview,
    [switch]$Force,
    [int]$Threshold = 90,
    [string]$ReportPath = "data-storage\reports\emergency-cleanup\"
)

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFile = Join-Path $ReportPath "emergency-cleanup-$timestamp.log"

# Create report directory if it doesn't exist
if (-not (Test-Path $ReportPath)) {
    New-Item -ItemType Directory -Path $ReportPath -Force | Out-Null
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    
    $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
    Add-Content -Path $logFile -Value $logEntry -Encoding UTF8
    
    switch ($Level) {
        "CRITICAL" { Write-Host $logEntry -ForegroundColor Red }
        "WARNING"  { Write-Host $logEntry -ForegroundColor Yellow }
        "INFO"     { Write-Host $logEntry -ForegroundColor Gray }
        "SUCCESS"  { Write-Host $logEntry -ForegroundColor Green }
    }
}

Write-Log "=== EMERGENCY DISK CLEANUP STARTED ===" -Level "CRITICAL"
Write-Log "Mode: $(if ($Preview) {'PREVIEW'} else {'EXECUTION'})" -Level "INFO"
Write-Log "Target drives: $($Drives -join ', ')" -Level "INFO"
Write-Log "Threshold: ${Threshold}%" -Level "INFO"
Write-Host ""

# Step 1: Check current disk status
Write-Log "Step 1: Checking disk space status..." -Level "INFO"
$criticalDisks = @()
$diskInfo = @()

foreach ($drive in $Drives) {
    try {
        $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='$drive'" -ErrorAction Stop
        if ($disk) {
            $usedPercent = [math]::Round((($disk.Size - $disk.FreeSpace)/$disk.Size)*100, 2)
            $freeGB = [math]::Round($disk.FreeSpace/1GB, 2)
            $totalGB = [math]::Round($disk.Size/1GB, 2)
            
            $diskInfo += [PSCustomObject]@{
                Drive = $drive
                UsedPercent = $usedPercent
                FreeGB = $freeGB
                TotalGB = $totalGB
                Status = if ($usedPercent -gt $Threshold) {"CRITICAL"} else {"OK"}
            }
            
            if ($usedPercent -gt $Threshold) {
                $criticalDisks += $drive
                Write-Log "CRITICAL: $drive - ${usedPercent}% used (${freeGB} GB free of ${totalGB} GB)" -Level "CRITICAL"
            } else {
                Write-Log "OK: $drive - ${usedPercent}% used" -Level "INFO"
            }
        }
    } catch {
        Write-Log "ERROR: Failed to check drive $drive - $_" -Level "WARNING"
    }
}

Write-Host ""

if ($criticalDisks.Count -eq 0) {
    Write-Log "No critical disks found. Exiting." -Level "INFO"
    exit 0
}

Write-Log "Found $($criticalDisks.Count) critical disks: $($criticalDisks -join ', ')" -Level "CRITICAL"
Write-Host ""

# Step 2: Clean temporary files
Write-Log "Step 2: Cleaning temporary files..." -Level "INFO"
$tempPatterns = @("*.tmp", "*.temp", "*.bak", "*.log", "Thumbs.db", ".DS_Store", "~*", "*.cache", "*.dmp")
$tempFiles = @()
$tempSize = 0

foreach ($drive in $criticalDisks) {
    foreach ($pattern in $tempPatterns) {
        $files = Get-ChildItem -Path "${drive}\" -Filter $pattern -Recurse -ErrorAction SilentlyContinue -Force
        $tempFiles += $files
        $tempSize += ($files | Measure-Object -Property Length -Sum).Sum
    }
}

if ($tempFiles.Count -gt 0) {
    $tempSizeMB = [math]::Round($tempSize / 1MB, 2)
    Write-Log "Found $($tempFiles.Count) temporary files (${tempSizeMB} MB)" -Level "INFO"
    
    if (-not $Preview) {
        $deletedCount = 0
        $deletedSize = 0
        
        foreach ($file in $tempFiles) {
            try {
                Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
                $deletedCount++
                $deletedSize += $file.Length
                Write-Log "Deleted: $($file.FullName)" -Level "INFO"
            } catch {
                Write-Log "Failed to delete: $($file.FullName)" -Level "WARNING"
            }
        }
        
        $deletedSizeMB = [math]::Round($deletedSize / 1MB, 2)
        Write-Log "Deleted $deletedCount temporary files (${deletedSizeMB} MB)" -Level "SUCCESS"
    } else {
        Write-Log "PREVIEW: Would delete $($tempFiles.Count) temporary files (${tempSizeMB} MB)" -Level "INFO"
    }
} else {
    Write-Log "No temporary files found" -Level "INFO"
}
Write-Host ""

# Step 3: Clean Windows temporary files
Write-Log "Step 3: Cleaning Windows temporary files..." -Level "INFO"
$windowsTempDirs = @(
    "${env:TEMP}",
    "${env:WINDIR}\Temp",
    "${env:WINDIR}\Prefetch",
    "${env:LOCALAPPDATA}\Temp"
)

$windowsTempFiles = @()
foreach ($dir in $windowsTempDirs) {
    if (Test-Path $dir) {
        $files = Get-ChildItem -Path $dir -File -Recurse -ErrorAction SilentlyContinue | 
            Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) }
        $windowsTempFiles += $files
    }
}

if ($windowsTempFiles.Count -gt 0) {
    $windowsTempSize = ($windowsTempFiles | Measure-Object -Property Length -Sum).Sum
    $windowsTempSizeMB = [math]::Round($windowsTempSize / 1MB, 2)
    Write-Log "Found $($windowsTempFiles.Count) old Windows temp files (${windowsTempSizeMB} MB)" -Level "INFO"
    
    if (-not $Preview) {
        $deletedCount = 0
        $deletedSize = 0
        
        foreach ($file in $windowsTempFiles) {
            try {
                Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
                $deletedCount++
                $deletedSize += $file.Length
            } catch {
                # Ignore errors for Windows temp files
            }
        }
        
        $deletedSizeMB = [math]::Round($deletedSize / 1MB, 2)
        Write-Log "Deleted $deletedCount Windows temp files (${deletedSizeMB} MB)" -Level "SUCCESS"
    } else {
        Write-Log "PREVIEW: Would delete $($windowsTempFiles.Count) Windows temp files (${windowsTempSizeMB} MB)" -Level "INFO"
    }
} else {
    Write-Log "No old Windows temp files found" -Level "INFO"
}
Write-Host ""

# Step 4: Clean recycle bin
Write-Log "Step 4: Cleaning recycle bin..." -Level "INFO"
if (-not $Preview) {
    try {
        $recycleBin = New-Object -ComObject Shell.Application
        $recycleBin.NameSpace(0xA).Items() | ForEach-Object { 
            $recycleBin.NameSpace(0xA).ParseName($_.Name).InvokeVerb("Delete")
        }
        Write-Log "Recycle bin emptied" -Level "SUCCESS"
    } catch {
        Write-Log "Failed to empty recycle bin: $_" -Level "WARNING"
    }
} else {
    Write-Log "PREVIEW: Would empty recycle bin" -Level "INFO"
}
Write-Host ""

# Step 5: Find large files (>100MB)
Write-Log "Step 5: Finding large files (>100MB)..." -Level "INFO"
$largeFiles = @()
foreach ($drive in $criticalDisks) {
    $files = Get-ChildItem -Path "${drive}\" -File -Recurse -ErrorAction SilentlyContinue | 
        Where-Object { $_.Length -gt 100MB } | 
        Sort-Object Length -Descending | 
        Select-Object -First 20
    
    $largeFiles += $files
}

if ($largeFiles.Count -gt 0) {
    $largeFilesSize = ($largeFiles | Measure-Object -Property Length -Sum).Sum
    $largeFilesSizeGB = [math]::Round($largeFilesSize / 1GB, 2)
    
    Write-Log "Found $($largeFiles.Count) large files (>100MB) totaling ${largeFilesSizeGB} GB" -Level "INFO"
    Write-Log "Top 10 largest files:" -Level "INFO"
    
    $largeFiles | Select-Object -First 10 | ForEach-Object {
        $sizeGB = [math]::Round($_.Length / 1GB, 2)
        Write-Log "  ${sizeGB} GB - $($_.FullName)" -Level "INFO"
    }
    
    Write-Log "RECOMMENDATION: Review these large files for possible deletion or archiving" -Level "WARNING"
} else {
    Write-Log "No large files (>100MB) found" -Level "INFO"
}
Write-Host ""

# Step 6: Check disk space after cleanup
Write-Log "Step 6: Checking disk space after cleanup..." -Level "INFO"
$afterCleanupInfo = @()
foreach ($drive in $criticalDisks) {
    try {
        $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='$drive'"
        $usedPercent = [math]::Round((($disk.Size - $disk.FreeSpace)/$disk.Size)*100, 2)
        $freeGB = [math]::Round($disk.FreeSpace/1GB, 2)
        
        $afterCleanupInfo += [PSCustomObject]@{
            Drive = $drive
            UsedPercent = $usedPercent
            FreeGB = $freeGB
            Improvement = if ($diskInfo | Where-Object { $_.Drive -eq $drive }) {
                $before = ($diskInfo | Where-Object { $_.Drive -eq $drive }).FreeGB
                [math]::Round($freeGB - $before, 2)
            } else { 0 }
        }
    } catch {
        Write-Log "Failed to check drive $drive after cleanup" -Level "WARNING"
    }
}

# Step 7: Generate report
Write-Log "Step 7: Generating cleanup report..." -Level "INFO"
$reportFile = Join-Path $ReportPath "emergency-cleanup-report-$timestamp.md"
$reportContent = @"
# Emergency Disk Cleanup Report
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Mode: $(if ($Preview) {'Preview'} else {'Execution'})

## Summary
- Critical drives processed: $($criticalDisks.Count)
- Temporary files found: $($tempFiles.Count)
- Windows temp files found: $($windowsTempFiles.Count)
- Large files found (>100MB): $($largeFiles.Count)
- Recycle bin: $(if (-not $Preview) {'Emptied'} else {'Would be emptied'})

## Disk Status Before Cleanup
$($diskInfo | ForEach-Object { 
    "- $($_.Drive): $($_.UsedPercent)% used ($($_.FreeGB) GB free of $($_.TotalGB) GB) [$($_.Status)]" 
} | Out-String)

## Disk Status After Cleanup
$($afterCleanupInfo | ForEach-Object { 
    "- $($_.Drive): $($_.UsedPercent)% used ($($_.FreeGB) GB free) [Improvement: $($_.Improvement) GB]" 
} | Out-String)

## Large Files Found (>100MB)
$(
if ($largeFiles.Count -gt 0) {
    $largeFiles | Select-Object -First 10 | ForEach-Object { 
        $sizeGB = [math]::Round($_.Length / 1GB, 2)
        "- ${sizeGB} GB - $($_.FullName)`n"
    }
} else {
    "No large files found"
}
)

## Recommendations
1. Review large files for possible deletion or archiving
2. Consider moving data to less full drives (D: has 21.3% usage)
3. Set up automated cleanup to prevent future issues
4. Monitor disk space regularly

## Next Steps
1. Run without --preview flag to execute cleanup
2. Review large files list
3. Consider data migration strategies
4. Set up regular maintenance

## Log File
Complete log available at: $logFile
"@

$reportContent | Set-Content $reportFile -Encoding UTF8
Write-Log "Report generated: $reportFile" -Level "SUCCESS"

# Step 8: Final summary
Write-Log "=== EMERGENCY DISK CLEANUP COMPLETED ===" -Level "INFO"
Write-Host ""
Write-Host "=== CLEANUP SUMMARY ===" -ForegroundColor Cyan
Write-Host "Mode: $(if ($Preview) {'PREVIEW (no files deleted)'} else {'EXECUTION'})" -ForegroundColor Gray
Write-Host "Critical drives: $($criticalDisks.Count)" -ForegroundColor $(if ($criticalDisks.Count -gt 0) {"Yellow"} else {"Green"})
Write-Host "Temporary files: $($tempFiles.Count)" -ForegroundColor Gray
Write-Host "Windows temp files: $($windowsTempFiles.Count)" -ForegroundColor Gray
Write-Host "Large files (>100MB): $($largeFiles.Count)" -ForegroundColor Gray
Write-Host "Report: $reportFile" -ForegroundColor Gray
Write-Host "Log: $logFile" -ForegroundColor Gray
Write-Host ""

if ($Preview) {
    Write-Host "=== NEXT STEPS ===" -ForegroundColor Yellow
    Write-Host "To execute cleanup, run:" -ForegroundColor Gray
    Write-Host "  .\$($MyInvocation.MyCommand.Name) -Force" -ForegroundColor Gray
    Write-Host "Or for specific drives:" -ForegroundColor Gray
    Write-Host "  .\$($MyInvocation.MyCommand.Name) -Drives C:,E: -Force" -ForegroundColor Gray
}

return @{
    success = $true
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    critical_disks = $criticalDisks
    temp_files_count = $tempFiles.Count
    windows_temp_count = $windowsTempFiles.Count
    large_files_count = $largeFiles.Count
    report_file = $reportFile
    log_file = $logFile
    preview_mode = $Preview
}