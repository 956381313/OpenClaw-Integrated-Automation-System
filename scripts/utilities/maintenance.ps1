# Workspace Maintenance Script
# Run weekly to keep workspace clean and organized

param(
    [switch]$Quick,
    [switch]$Full,
    [switch]$ReportOnly
)

if (-not ($Quick -or $Full -or $ReportOnly)) {
    Write-Host "Workspace Maintenance Tool"
    Write-Host "=========================="
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  .\maintenance.ps1 -Quick       # Quick cleanup (5 min)"
    Write-Host "  .\maintenance.ps1 -Full        # Full maintenance (15 min)"
    Write-Host "  .\maintenance.ps1 -ReportOnly  # Generate report only"
    Write-Host ""
    exit
}

Write-Host "Workspace Maintenance"
Write-Host "====================="
Write-Host "Start: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "Mode: $(if ($Quick) {'Quick'} elseif ($Full) {'Full'} else {'Report'})"
Write-Host ""

# Statistics
$stats = @{
    StartTime = Get-Date
    FilesDeleted = 0
    SpaceFreed = 0
    Errors = 0
}

# Generate report function
function Get-WorkspaceReport {
    $files = Get-ChildItem -Path "." -Recurse -File
    $dirs = Get-ChildItem -Path "." -Recurse -Directory
    
    return @{
        TotalFiles = $files.Count
        TotalDirs = $dirs.Count
        TotalSizeMB = [math]::Round(($files | Measure-Object Length -Sum).Sum / 1MB, 2)
        ByExtension = $files | Group-Object Extension | Sort-Object Count -Descending | Select-Object -First 10 Name, Count
        DiskSpace = Get-PSDrive C | Select-Object Used, Free, @{Name="UsedPercent";Expression={[math]::Round(($_.Used/($_.Used+$_.Free))*100,2)}}
    }
}

# Quick maintenance
if ($Quick -or $Full) {
    Write-Host "1. Cleaning temporary files..." -ForegroundColor Yellow
    
    # Zero-byte files
    $zeroFiles = Get-ChildItem -Path "." -Recurse -File | Where-Object {$_.Length -eq 0}
    if ($zeroFiles.Count -gt 0) {
        $zeroFiles | Remove-Item -Force
        $stats.FilesDeleted += $zeroFiles.Count
        Write-Host "   Deleted $($zeroFiles.Count) zero-byte files" -ForegroundColor Gray
    }
    
    # Temp files
    $tempFiles = Get-ChildItem -Path "." -Recurse -File -Include "*.tmp", "*.temp", "*.bak"
    if ($tempFiles.Count -gt 0) {
        $tempSize = ($tempFiles | Measure-Object Length -Sum).Sum
        $tempFiles | Remove-Item -Force
        $stats.FilesDeleted += $tempFiles.Count
        $stats.SpaceFreed += $tempSize
        Write-Host "   Deleted $($tempFiles.Count) temp files ($([math]::Round($tempSize/1MB,2)) MB)" -ForegroundColor Gray
    }
    
    # Log files (older than 7 days)
    if ($Full) {
        $oldLogs = Get-ChildItem -Path "." -Recurse -File -Include "*.log" | Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-7)}
        if ($oldLogs.Count -gt 0) {
            $logSize = ($oldLogs | Measure-Object Length -Sum).Sum
            $oldLogs | Remove-Item -Force
            $stats.FilesDeleted += $oldLogs.Count
            $stats.SpaceFreed += $logSize
            Write-Host "   Deleted $($oldLogs.Count) old log files ($([math]::Round($logSize/1MB,2)) MB)" -ForegroundColor Gray
        }
    }
    
    Write-Host "   ✅ Quick cleanup complete" -ForegroundColor Green
    Write-Host ""
}

# Full maintenance
if ($Full) {
    Write-Host "2. Organizing files..." -ForegroundColor Yellow
    
    # Auto classify new files in root
    $rootFiles = Get-ChildItem -Path "." -File -Depth 0
    if ($rootFiles.Count -gt 0) {
        Write-Host "   Found $($rootFiles.Count) unclassified files in root" -ForegroundColor Gray
        Write-Host "   Run auto-classify.ps1 to organize them" -ForegroundColor Gray
    }
    
    # Check for empty directories
    $emptyDirs = Get-ChildItem -Path "." -Recurse -Directory | Where-Object {
        -not (Get-ChildItem -Path $_.FullName -Recurse -Force)
    }
    if ($emptyDirs.Count -gt 0) {
        Write-Host "   Found $($emptyDirs.Count) empty directories" -ForegroundColor Gray
        if ($Full) {
            $emptyDirs | Sort-Object -Property {$_.FullName.Length} -Descending | Remove-Item -Force
            Write-Host "   Deleted empty directories" -ForegroundColor Gray
        }
    }
    
    Write-Host "   ✅ Organization complete" -ForegroundColor Green
    Write-Host ""
}

# Generate report
Write-Host "3. Generating report..." -ForegroundColor Yellow
$report = Get-WorkspaceReport

Write-Host ""
Write-Host "=== Workspace Report ===" -ForegroundColor Cyan
Write-Host "Files: $($report.TotalFiles)" -ForegroundColor Gray
Write-Host "Directories: $($report.TotalDirs)" -ForegroundColor Gray
Write-Host "Total Size: $($report.TotalSizeMB) MB" -ForegroundColor Gray
Write-Host ""

Write-Host "Top file types:" -ForegroundColor Yellow
$report.ByExtension | ForEach-Object {
    Write-Host "  $($_.Name): $($_.Count) files" -ForegroundColor Gray
}
Write-Host ""

Write-Host "Disk space (C:):" -ForegroundColor Yellow
Write-Host "  Used: $([math]::Round($report.DiskSpace.Used/1GB,2)) GB ($($report.DiskSpace.UsedPercent)%)" -ForegroundColor Gray
Write-Host "  Free: $([math]::Round($report.DiskSpace.Free/1GB,2)) GB" -ForegroundColor Gray

if ($Quick -or $Full) {
    Write-Host ""
    Write-Host "=== Maintenance Summary ===" -ForegroundColor Green
    Write-Host "Files deleted: $($stats.FilesDeleted)" -ForegroundColor Gray
    Write-Host "Space freed: $([math]::Round($stats.SpaceFreed/1MB,2)) MB" -ForegroundColor Gray
    
    $duration = (Get-Date) - $stats.StartTime
    Write-Host "Duration: $([math]::Round($duration.TotalMinutes,1)) minutes" -ForegroundColor Gray
}

Write-Host ""
Write-Host "End: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Recommendations
if ($report.DiskSpace.UsedPercent -gt 85) {
    Write-Host "⚠️  Warning: Disk usage above 85%" -ForegroundColor Red
    Write-Host "   Consider additional cleanup" -ForegroundColor Gray
}

if ($report.TotalFiles -gt 1000) {
    Write-Host "ℹ️  Info: Large number of files ($($report.TotalFiles))" -ForegroundColor Yellow
    Write-Host "   Consider archiving old files" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Next maintenance: $(Get-Date).AddDays(7).ToString('yyyy-MM-dd')" -ForegroundColor Gray