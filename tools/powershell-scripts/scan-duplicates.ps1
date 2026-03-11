# OpenClaw Duplicate File Scanner
# Version: 1.0.0
# Description: Scan for duplicate files based on size and hash
# Author: Hell Cat (Digital Ghost Assistant)
# Date: 2026-03-06

param(
    [string]$ConfigPath = "modules/duplicate/config\modules/duplicate/config.json",
    [string]$ScanPath,
    [switch]$Test,
    [switch]$Help
)

# Log setup
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$LogDir = "modules/duplicate/logs"
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}
$LogFile = "$LogDir\scan-$Timestamp.log"

# Start logging
Start-Transcript -Path $LogFile -Append
Write-Host "=== OpenClaw Duplicate File Scanner ===" -ForegroundColor Cyan
Write-Host "Start Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "Log file: $LogFile" -ForegroundColor Gray
Write-Host ""

if ($Help) {
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\scan-duplicates.ps1 [-ConfigPath <path>] [-ScanPath <path>] [-Test] [-Help]" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Parameters:" -ForegroundColor Yellow
    Write-Host "  -ConfigPath  Configuration file path (default: modules/duplicate/config\modules/duplicate/config.json)" -ForegroundColor Gray
    Write-Host "  -ScanPath    Specific path to scan (overrides config)" -ForegroundColor Gray
    Write-Host "  -Test        Test mode - scan small sample only" -ForegroundColor Gray
    Write-Host "  -Help        Show this help" -ForegroundColor Gray
    Stop-Transcript
    exit 0
}

# Function: Load configuration
function Load-Config {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        Write-Host "ERROR: Configuration file not found: $Path" -ForegroundColor Red
        Write-Host "Please copy modules/duplicate/config-template.json to modules/duplicate/config.json" -ForegroundColor Yellow
        Write-Host "and update with your settings" -ForegroundColor Yellow
        return $null
    }
    
    try {
        $config = Get-Content $Path -Raw | ConvertFrom-Json -ErrorAction Stop
        Write-Host "Configuration loaded successfully" -ForegroundColor Green
        Write-Host "  Version: $($config.Version)" -ForegroundColor Gray
        Write-Host "  Scan directories: $($config.Settings.ScanDirectories.Count)" -ForegroundColor Gray
        Write-Host "  File types: $($config.Settings.FileTypes.Count)" -ForegroundColor Gray
        return $config
    } catch {
        Write-Host "ERROR: Cannot load configuration" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Yellow
        return $null
    }
}

# Function: Get files to scan
function Get-FilesToScan {
    param(
        [object]$Config,
        [string]$SpecificPath,
        [bool]$TestMode
    )
    
    $files = @()
    
    # If specific path provided, use it
    if ($SpecificPath) {
        Write-Host "Scanning specific path: $SpecificPath" -ForegroundColor Yellow
        $scanPaths = @($SpecificPath)
    } else {
        # Use configured paths
        $scanPaths = $Config.Settings.ScanDirectories
        Write-Host "Scanning configured directories:" -ForegroundColor Yellow
        foreach ($path in $scanPaths) {
            Write-Host "  $path" -ForegroundColor Gray
        }
    }
    
    # Get all files
    foreach ($path in $scanPaths) {
        if (-not (Test-Path $path)) {
            Write-Host "WARNING: Path not found: $path" -ForegroundColor Yellow
            continue
        }
        
        Write-Host "`nScanning: $path" -ForegroundColor Cyan
        
        try {
            # Get files based on file types
            foreach ($fileType in $Config.Settings.FileTypes) {
                $foundFiles = Get-ChildItem -Path $path -Recurse -Include $fileType -ErrorAction SilentlyContinue | 
                    Where-Object { 
                        # Apply size filters
                        $sizeKB = $_.Length / 1KB
                        $sizeMB = $_.Length / 1MB
                        $sizeKB -ge $Config.Settings.MinFileSizeKB -and 
                        $sizeMB -le $Config.Settings.MaxFileSizeMB
                    }
                
                $files += $foundFiles
                Write-Host "  Found $($foundFiles.Count) files of type $fileType" -ForegroundColor Gray
                
                # Limit for test mode
                if ($TestMode -and $files.Count -gt 100) {
                    Write-Host "  Test mode: Limiting to 100 files" -ForegroundColor Yellow
                    $files = $files | Select-Object -First 100
                    break
                }
            }
        } catch {
            Write-Host "ERROR scanning $path : $_" -ForegroundColor Red
        }
    }
    
    Write-Host "`nTotal files to scan: $($files.Count)" -ForegroundColor Green
    return $files
}

# Function: Calculate file hash
function Get-FileHash {
    param([string]$FilePath, [string]$Algorithm = "MD5")
    
    try {
        $hash = Get-FileHash -Path $FilePath -Algorithm $Algorithm -ErrorAction Stop
        return $hash.Hash
    } catch {
        Write-Host "WARNING: Cannot hash $FilePath : $_" -ForegroundColor Yellow
        return $null
    }
}

# Function: Find duplicates
function Find-Duplicates {
    param([array]$Files, [object]$Config)
    
    Write-Host "`nAnalyzing files for duplicates..." -ForegroundColor Yellow
    
    # Group by size first (fastest method)
    $sizeGroups = $Files | Group-Object Length | Where-Object Count -gt 1
    
    Write-Host "Files with potential duplicates (by size): $($sizeGroups.Count) groups" -ForegroundColor Gray
    
    $duplicates = @()
    $processed = 0
    $totalGroups = $sizeGroups.Count
    
    foreach ($group in $sizeGroups) {
        $processed++
        if ($processed % 10 -eq 0) {
            Write-Progress -Activity "Checking duplicates" -Status "Processing group $processed of $totalGroups" -PercentComplete (($processed / $totalGroups) * 100)
        }
        
        # If only size comparison
        if ($Config.Settings.CompareMethod -eq "SizeOnly") {
            if ($group.Count -gt 1) {
                $duplicateGroup = @{
                    Size = $group.Name
                    Count = $group.Count
                    Files = $group.Group.FullName
                    Hash = $null
                }
                $duplicates += $duplicateGroup
            }
            continue
        }
        
        # For hash comparison, group by hash
        $hashGroups = @{}
        foreach ($file in $group.Group) {
            $hash = Get-FileHash -FilePath $file.FullName -Algorithm $Config.Settings.HashAlgorithm
            if ($hash) {
                if (-not $hashGroups.ContainsKey($hash)) {
                    $hashGroups[$hash] = @()
                }
                $hashGroups[$hash] += $file.FullName
            }
        }
        
        # Add groups with duplicates
        foreach ($hash in $hashGroups.Keys) {
            if ($hashGroups[$hash].Count -gt 1) {
                $duplicateGroup = @{
                    Size = $group.Name
                    Hash = $hash
                    Count = $hashGroups[$hash].Count
                    Files = $hashGroups[$hash]
                }
                $duplicates += $duplicateGroup
            }
        }
    }
    
    Write-Progress -Activity "Checking duplicates" -Completed
    
    Write-Host "Found $($duplicates.Count) duplicate groups" -ForegroundColor Green
    return $duplicates
}

# Function: Generate report
function Generate-Report {
    param(
        [array]$Duplicates,
        [object]$Config,
        [bool]$TestMode
    )
    
    $reportDir = "modules/duplicate/reports"
    if (-not (Test-Path $reportDir)) {
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    }
    
    $reportFile = "$reportDir\scan-report-$Timestamp.json"
    $htmlFile = "$reportDir\scan-report-$Timestamp.html"
    
    # JSON report
    $report = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Config = $Config
        TestMode = $TestMode
        Summary = @{
            TotalDuplicateGroups = $Duplicates.Count
            TotalDuplicateFiles = ($Duplicates | Measure-Object -Property Count -Sum).Sum
            TotalSpaceWastedMB = [math]::Round(($Duplicates | ForEach-Object { [int64]$_.Size * ($_.Count - 1) } | Measure-Object -Sum).Sum / 1MB, 2)
        }
        Duplicates = $Duplicates
    }
    
    $report | ConvertTo-Json -Depth 6 | Out-File $reportFile -Encoding UTF8
    Write-Host "JSON report saved: $reportFile" -ForegroundColor Green
    
    # HTML report
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>OpenClaw Duplicate File Scan Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        .summary { background: #f5f5f5; padding: 15px; border-radius: 5px; margin-bottom: 20px; }
        .stat { display: inline-block; margin-right: 30px; }
        .stat-value { font-size: 24px; font-weight: bold; color: #0078d4; }
        .stat-label { font-size: 14px; color: #666; }
        .duplicate-group { border: 1px solid #ddd; margin-bottom: 15px; padding: 15px; border-radius: 5px; }
        .group-header { background: #e8f4fd; padding: 10px; margin: -15px -15px 15px -15px; border-radius: 5px 5px 0 0; }
        .file-list { margin-left: 20px; }
        .file-item { margin: 5px 0; }
        .size { color: #666; font-style: italic; }
        .test-mode { background: #fff3cd; border: 1px solid #ffeaa7; padding: 10px; margin-bottom: 20px; }
    </style>
</head>
<body>
    <h1>馃搧 OpenClaw Duplicate File Scan Report</h1>
    
    $(if ($TestMode) {
        "<div class='test-mode'><strong>鈿狅笍 TEST MODE:</strong> This is a test scan with limited files.</div>"
    })
    
    <div class='summary'>
        <h2>馃搳 Scan Summary</h2>
        <div class='stat'>
            <div class='stat-value'>$($report.Summary.TotalDuplicateGroups)</div>
            <div class='stat-label'>Duplicate Groups</div>
        </div>
        <div class='stat'>
            <div class='stat-value'>$($report.Summary.TotalDuplicateFiles)</div>
            <div class='stat-label'>Duplicate Files</div>
        </div>
        <div class='stat'>
            <div class='stat-value'>$($report.Summary.TotalSpaceWastedMB) MB</div>
            <div class='stat-label'>Space Wasted</div>
        </div>
        <div style='clear: both;'></div>
        <p><strong>Scan Time:</strong> $($report.Timestamp)</p>
        <p><strong>Compare Method:</strong> $($Config.Settings.CompareMethod)</p>
    </div>
    
    <h2>馃攳 Duplicate Groups</h2>
    
    $(if ($Duplicates.Count -eq 0) {
        "<p>No duplicates found! 馃帀</p>"
    } else {
        $htmlGroups = ""
        foreach ($group in $Duplicates) {
            $sizeMB = [math]::Round([int64]$group.Size / 1MB, 2)
            $wastedMB = [math]::Round([int64]$group.Size * ($group.Count - 1) / 1MB, 2)
            
            $htmlGroups += @"
            <div class='duplicate-group'>
                <div class='group-header'>
                    <strong>Group Size:</strong> $sizeMB MB | 
                    <strong>Files:</strong> $($group.Count) | 
                    <strong>Wasted Space:</strong> $wastedMB MB
                    $(if ($group.Hash) { "| <strong>Hash:</strong> $($group.Hash.Substring(0, 16))..." })
                </div>
                <div class='file-list'>
            "@
            
            foreach ($file in $group.Files) {
                $fileName = Split-Path $file -Leaf
                $htmlGroups += "<div class='file-item'>馃搫 $fileName <span class='size'>($file)</span></div>"
            }
            
            $htmlGroups += "</div></div>"
        }
        $htmlGroups
    })
    
    <hr>
    <p><em>Report generated by OpenClaw Duplicate File Scanner v1.0.0</em></p>
    <p><em>Next step: Review duplicates and run clean-duplicates.ps1 to remove them</em></p>
</body>
</html>
"@
    
    $html | Out-File $htmlFile -Encoding UTF8
    Write-Host "HTML report saved: $htmlFile" -ForegroundColor Green
    
    return @{
        JsonReport = $reportFile
        HtmlReport = $htmlFile
        Summary = $report.Summary
    }
}

# Main execution
Write-Host "Starting duplicate file scan..." -ForegroundColor Cyan

# Load configuration
$config = Load-Config -Path $ConfigPath
if (-not $config) {
    Stop-Transcript
    exit 1
}

# Get files to scan
$files = Get-FilesToScan -Config $config -SpecificPath $ScanPath -TestMode $Test

if ($files.Count -eq 0) {
    Write-Host "No files found to scan" -ForegroundColor Yellow
    Stop-Transcript
    exit 0
}

# Find duplicates
$duplicates = Find-Duplicates -Files $files -Config $config

# Generate report
$report = Generate-Report -Duplicates $duplicates -Config $config -TestMode $Test

# Summary
Write-Host "`n=== Scan Complete ===" -ForegroundColor Green
Write-Host "Scanned files: $($files.Count)" -ForegroundColor Gray
Write-Host "Duplicate groups: $($report.Summary.TotalDuplicateGroups)" -ForegroundColor Gray
Write-Host "Duplicate files: $($report.Summary.TotalDuplicateFiles)" -ForegroundColor Gray
Write-Host "Space wasted: $($report.Summary.TotalSpaceWastedMB) MB" -ForegroundColor Gray
Write-Host ""
Write-Host "Reports:" -ForegroundColor Yellow
Write-Host "  JSON: $($report.JsonReport)" -ForegroundColor Gray
Write-Host "  HTML: $($report.HtmlReport)" -ForegroundColor Gray
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Review HTML report: $($report.HtmlReport)" -ForegroundColor Gray
Write-Host "  2. Run cleanup: .\clean-duplicates.ps1 -Preview" -ForegroundColor Gray
Write-Host "  3. Execute cleanup: .\clean-duplicates.ps1" -ForegroundColor Gray

Stop-Transcript
