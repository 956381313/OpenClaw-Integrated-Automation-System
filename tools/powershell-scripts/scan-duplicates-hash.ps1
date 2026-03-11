# OpenClaw Duplicate File Scanner with Hash Calculation
# Version: 1.1.0
# Description: Advanced duplicate detection with MD5/SHA256 hash
# Author: Hell Cat (Digital Ghost Assistant)
# Date: 2026-03-06

param(
    [string]$ConfigPath = "modules/duplicate/config\modules/duplicate/config.json",
    [switch]$Test,
    [switch]$Help,
    [string]$Algorithm = "MD5"
)

Write-Host "=== OpenClaw Duplicate File Scanner (Hash Mode) ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "Hash Algorithm: $Algorithm" -ForegroundColor Gray
Write-Host ""

if ($Help) {
    Write-Host "Usage: .\scan-duplicates-hash.ps1 [-ConfigPath <path>] [-Test] [-Help] [-Algorithm MD5|SHA256]" -ForegroundColor Yellow
    exit 0
}

# Load configuration
function Load-Config {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        Write-Host "ERROR: Configuration file not found: $Path" -ForegroundColor Red
        return $null
    }
    
    try {
        $config = Get-Content $Path -Raw | ConvertFrom-Json
        Write-Host "Configuration loaded" -ForegroundColor Green
        Write-Host "  Version: $($config.Version)" -ForegroundColor Gray
        Write-Host "  Scan directories: $($config.Settings.ScanDirectories.Count)" -ForegroundColor Gray
        return $config
    } catch {
        Write-Host "ERROR: Cannot load configuration: $_" -ForegroundColor Red
        return $null
    }
}

# Calculate file hash
function Get-FileHashAdvanced {
    param(
        [string]$FilePath,
        [string]$Algorithm = "MD5"
    )
    
    try {
        $stream = [System.IO.File]::OpenRead($FilePath)
        $hashAlgorithm = [System.Security.Cryptography.HashAlgorithm]::Create($Algorithm)
        $hashBytes = $hashAlgorithm.ComputeHash($stream)
        $stream.Close()
        
        $hashString = [System.BitConverter]::ToString($hashBytes) -replace '-', ''
        return $hashString
    } catch {
        Write-Host "  Hash error for $FilePath : $_" -ForegroundColor Yellow
        return $null
    }
}

# Main execution
$config = Load-Config -Path $ConfigPath
if (-not $config) {
    exit 1
}

# Scan directories
$allFiles = @()
$scanPaths = $config.Settings.ScanDirectories

Write-Host "Scanning directories..." -ForegroundColor Yellow
foreach ($dir in $scanPaths) {
    if (Test-Path $dir) {
        Write-Host "  $dir" -ForegroundColor Cyan
        
        foreach ($fileType in $config.Settings.FileTypes) {
            try {
                $files = Get-ChildItem -Path $dir -Recurse -Include $fileType -ErrorAction SilentlyContinue | 
                    Where-Object { 
                        $sizeKB = $_.Length / 1KB
                        $sizeMB = $_.Length / 1MB
                        $sizeKB -ge $config.Settings.MinFileSizeKB -and 
                        $sizeMB -le $config.Settings.MaxFileSizeMB
                    }
                
                $allFiles += $files
                Write-Host "    Found $($files.Count) $fileType files" -ForegroundColor Gray
                
                # Test mode limit
                if ($Test -and $allFiles.Count -gt 100) {
                    Write-Host "    Test mode: Limiting to 100 files" -ForegroundColor Yellow
                    $allFiles = $allFiles | Select-Object -First 100
                    break
                }
            } catch {
                Write-Host "    Error: $_" -ForegroundColor Red
            }
        }
    }
}

Write-Host "`nTotal files to scan: $($allFiles.Count)" -ForegroundColor Green

if ($allFiles.Count -eq 0) {
    Write-Host "No files to scan" -ForegroundColor Yellow
    exit 0
}

# Calculate hashes and find duplicates
Write-Host "`nCalculating file hashes ($Algorithm)..." -ForegroundColor Yellow

$hashGroups = @{}
$processed = 0
$totalFiles = $allFiles.Count

foreach ($file in $allFiles) {
    $processed++
    if ($processed % 10 -eq 0) {
        $percent = [math]::Round(($processed / $totalFiles) * 100, 1)
        Write-Progress -Activity "Calculating Hashes" -Status "$processed of $totalFiles files ($percent%)" -PercentComplete $percent
    }
    
    $hash = Get-FileHashAdvanced -FilePath $file.FullName -Algorithm $Algorithm
    if ($hash) {
        if (-not $hashGroups.ContainsKey($hash)) {
            $hashGroups[$hash] = @()
        }
        $hashGroups[$hash] += @{
            Path = $file.FullName
            Name = $file.Name
            Size = $file.Length
            SizeMB = [math]::Round($file.Length / 1MB, 2)
        }
    }
}

Write-Progress -Activity "Calculating Hashes" -Completed

# Find duplicates (groups with more than 1 file)
$duplicates = @()
foreach ($hash in $hashGroups.Keys) {
    if ($hashGroups[$hash].Count -gt 1) {
        $group = $hashGroups[$hash]
        $sizeMB = $group[0].SizeMB
        $wastedMB = [math]::Round($group[0].Size * ($group.Count - 1) / 1MB, 2)
        
        $duplicates += @{
            Hash = $hash
            SizeMB = $sizeMB
            Count = $group.Count
            WastedMB = $wastedMB
            Files = $group
        }
    }
}

Write-Host "Found $($duplicates.Count) duplicate groups (by hash)" -ForegroundColor Green

# Generate report
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$reportDir = "modules/duplicate/reports"
if (-not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
}

# JSON report
$reportFile = "$reportDir\scan-hash-report-$timestamp.json"
$report = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Algorithm = $Algorithm
    TestMode = $Test
    Summary = @{
        TotalFilesScanned = $allFiles.Count
        DuplicateGroups = $duplicates.Count
        DuplicateFiles = ($duplicates | Measure-Object -Property Count -Sum).Sum
        SpaceWastedMB = ($duplicates | Measure-Object -Property WastedMB -Sum).Sum
    }
    Duplicates = $duplicates
}

$report | ConvertTo-Json -Depth 4 | Out-File $reportFile -Encoding UTF8
Write-Host "JSON report saved: $reportFile" -ForegroundColor Green

# Text report
$textReport = @"
OpenClaw Duplicate File Scan Report (Hash Mode)
===============================================
Scan Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Algorithm: $Algorithm
Test Mode: $Test

Configuration:
- Directories scanned: $($scanPaths.Count)
- File types: $($config.Settings.FileTypes.Count)
- Min file size: $($config.Settings.MinFileSizeKB) KB
- Max file size: $($config.Settings.MaxFileSizeMB) MB

Scan Results:
- Total files scanned: $($allFiles.Count)
- Duplicate groups found: $($duplicates.Count)
- Total duplicate files: $(($duplicates | Measure-Object -Property Count -Sum).Sum)
- Space wasted: $(($duplicates | Measure-Object -Property WastedMB -Sum).Sum) MB

Duplicate Groups (first 10 shown):
"@

$shownGroups = 0
foreach ($group in $duplicates | Sort-Object WastedMB -Descending) {
    $shownGroups++
    if ($shownGroups -gt 10) { break }
    
    $textReport += "`n`nGroup $shownGroups (Hash: $($group.Hash.Substring(0, 16))..., Size: $($group.SizeMB) MB, Files: $($group.Count), Waste: $($group.WastedMB) MB):`n"
    foreach ($file in $group.Files) {
        $textReport += "  - $($file.Name)`n    $($file.Path)`n"
    }
}

if ($duplicates.Count -gt 10) {
    $textReport += "`n... and $($duplicates.Count - 10) more groups"
}

$textReport += @"

Recommendations:
1. Review duplicate files above
2. Run cleanup: .\clean-duplicates.ps1 -Preview
3. Backup important files
4. Execute cleanup: .\clean-duplicates.ps1

---
Report generated by OpenClaw Duplicate File Scanner v1.1.0 (Hash Mode)
"@

$textReportFile = "$reportDir\scan-hash-report-$timestamp.txt"
$textReport | Out-File $textReportFile -Encoding UTF8
Write-Host "Text report saved: $textReportFile" -ForegroundColor Green

# Summary
Write-Host "`n=== Scan Complete ===" -ForegroundColor Cyan
Write-Host "Files scanned: $($allFiles.Count)" -ForegroundColor Gray
Write-Host "Duplicate groups: $($duplicates.Count)" -ForegroundColor Gray
Write-Host "Duplicate files: $(($duplicates | Measure-Object -Property Count -Sum).Sum)" -ForegroundColor Gray
Write-Host "Space wasted: $(($duplicates | Measure-Object -Property WastedMB -Sum).Sum) MB" -ForegroundColor Gray
Write-Host ""
Write-Host "Reports:" -ForegroundColor Yellow
Write-Host "  JSON: $reportFile" -ForegroundColor Gray
Write-Host "  Text: $textReportFile" -ForegroundColor Gray
Write-Host ""
Write-Host "Next: Run cleanup with hash verification" -ForegroundColor Green
