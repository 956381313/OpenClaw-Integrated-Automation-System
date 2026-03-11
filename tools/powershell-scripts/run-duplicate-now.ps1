# Run Duplicate Cleanup Now
# Version: 1.0.0
# Description: Run duplicate cleanup immediately without waiting for schedule
# Author: Hell Cat (Digital Ghost Assistant)
# Date: 2026-03-06

param(
    [switch]$Preview,
    [switch]$Test,
    [switch]$Help,
    [string]$Strategy = "KeepNewest"
)

Write-Host "=== Run Duplicate Cleanup Now ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "Strategy: $Strategy" -ForegroundColor Gray
Write-Host "Mode: $(if ($Preview) { 'Preview (no files deleted)' } else { 'Live (files will be deleted)' })" -ForegroundColor $(if ($Preview) { "Yellow" } else { "Green" })
Write-Host ""

if ($Help) {
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\run-duplicate-now.ps1                    # Run cleanup immediately" -ForegroundColor Gray
    Write-Host "  .\run-duplicate-now.ps1 -Preview          # Preview mode (no deletion)" -ForegroundColor Gray
    Write-Host "  .\run-duplicate-now.ps1 -Test             # Test mode (limited files)" -ForegroundColor Gray
    Write-Host "  .\run-duplicate-now.ps1 -Strategy KeepOldest  # Use different strategy" -ForegroundColor Gray
    exit 0
}

# Configuration
$config = @{
    ScanScript = "scan-duplicates-hash.ps1"
    CleanupScript = "clean-duplicates-optimized.ps1"
    EmailScript = "send-email-fixed.ps1"
    LogDirectory = "modules/duplicate/data/logs/manual"
    ReportDirectory = "modules/duplicate/reports\manual"
    BackupDirectory = "modules/duplicate/backup\manual-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
}

# Create directories
$directories = @($config.LogDirectory, $config.ReportDirectory)
foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "Created directory: $dir" -ForegroundColor Green
    }
}

# Start log
$logFile = "$($config.LogDirectory)\run-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$startTime = Get-Date

Write-Host "Starting duplicate cleanup process..." -ForegroundColor Yellow
Write-Host "Log file: $logFile" -ForegroundColor Gray
Write-Host ""

# Step 1: Scan for duplicates
Write-Host "Step 1: Scanning for duplicates..." -ForegroundColor Cyan

$scanArgs = @()
if ($Test) {
    $scanArgs += "-Test"
}

try {
    $scanResult = powershell -ExecutionPolicy Bypass -File $config.ScanScript @scanArgs 2>&1
    $scanResult | Out-File $logFile -Append -Encoding UTF8
    
    # Check if scan was successful
    if ($LASTEXITCODE -eq 0) {
        Write-Host "鉁?Scan completed successfully" -ForegroundColor Green
        
        # Find the latest scan report
        $latestReport = Get-ChildItem "modules/duplicate/reports" -Filter "scan-hash-report-*.json" | 
            Sort-Object LastWriteTime -Descending | 
            Select-Object -First 1
        
        if ($latestReport) {
            Write-Host "  Report: $($latestReport.Name)" -ForegroundColor Gray
        }
    } else {
        Write-Host "鉁?Scan failed with exit code: $LASTEXITCODE" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "鉁?Scan error: $_" -ForegroundColor Red
    exit 1
}

# Step 2: Run cleanup
Write-Host "`nStep 2: Running cleanup..." -ForegroundColor Cyan

$cleanupArgs = @("-Strategy", $Strategy)
if ($Preview) {
    $cleanupArgs += "-Preview"
}
if ($Test) {
    $cleanupArgs += "-Test"
}

try {
    $cleanupResult = powershell -ExecutionPolicy Bypass -File $config.CleanupScript @cleanupArgs 2>&1
    $cleanupResult | Out-File $logFile -Append -Encoding UTF8
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "鉁?Cleanup completed successfully" -ForegroundColor Green
        
        # Find the latest cleanup report
        $latestCleanupReport = Get-ChildItem "modules/duplicate/reports" -Filter "optimized-cleanup-report-*.txt" | 
            Sort-Object LastWriteTime -Descending | 
            Select-Object -First 1
        
        if ($latestCleanupReport) {
            Write-Host "  Report: $($latestCleanupReport.Name)" -ForegroundColor Gray
            
            # Show summary from report
            $reportContent = Get-Content $latestCleanupReport.FullName -TotalCount 20
            Write-Host "`nCleanup Summary:" -ForegroundColor Yellow
            foreach ($line in $reportContent) {
                if ($line -match "Files to delete:|Space to recover:|Files deleted:|Space recovered:") {
                    Write-Host "  $line" -ForegroundColor Gray
                }
            }
        }
    } else {
        Write-Host "鉁?Cleanup failed with exit code: $LASTEXITCODE" -ForegroundColor Red
    }
} catch {
    Write-Host "鉁?Cleanup error: $_" -ForegroundColor Red
}

# Step 3: Send email notification (optional)
Write-Host "`nStep 3: Sending notification..." -ForegroundColor Cyan

if (Test-Path $config.EmailScript) {
    try {
        $subject = "OpenClaw Duplicate Cleanup $(if ($Preview) { 'Preview' } else { 'Completed' })"
        $body = @"
Duplicate file cleanup $(if ($Preview) { 'preview' } else { 'execution' }) completed.

Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Strategy: $Strategy
Mode: $(if ($Preview) { 'Preview' } else { 'Live' })
Test Mode: $(if ($Test) { 'Yes' } else { 'No' })

Check modules/duplicate/reports\ directory for detailed reports.
"@
        
        powershell -ExecutionPolicy Bypass -File $config.EmailScript -Subject $subject -Body $body -Test:$Test
        Write-Host "鉁?Notification sent" -ForegroundColor Green
    } catch {
        Write-Host "鈿狅笍 Notification failed: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "鈩癸笍 Email script not found, skipping notification" -ForegroundColor Gray
}

# Calculate execution time
$endTime = Get-Date
$duration = $endTime - $startTime

# Final summary
Write-Host "`n=== Process Complete ===" -ForegroundColor Green
Write-Host "Start Time: $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
Write-Host "End Time: $($endTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
Write-Host "Duration: $($duration.TotalMinutes.ToString('F1')) minutes" -ForegroundColor Gray
Write-Host "Log File: $logFile" -ForegroundColor Gray

if ($Preview) {
    Write-Host "Mode: PREVIEW - No files were actually deleted" -ForegroundColor Yellow
    Write-Host "To run actual cleanup, remove -Preview flag" -ForegroundColor Cyan
} else {
    Write-Host "Mode: LIVE - Cleanup executed" -ForegroundColor Green
}

Write-Host "`nReports:" -ForegroundColor Yellow
$reports = Get-ChildItem "modules/duplicate/reports" -Filter "*$(Get-Date -Format 'yyyyMMdd')*" | Sort-Object LastWriteTime -Descending
foreach ($report in $reports | Select-Object -First 3) {
    Write-Host "  - $($report.Name)" -ForegroundColor Gray
}

Write-Host "`nNext scheduled run: Weekly on Sunday at 03:00" -ForegroundColor Cyan
Write-Host "To run again: .\run-duplicate-now.ps1" -ForegroundColor Gray
