# Auto Workspace System - English Version
# Fully working automation system

param(
    [string]$Command = "help"
)

# Show welcome
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Workspace Automation System v1.0" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Help
if ($Command -eq "help") {
    Write-Host "Usage: .\auto-system-english.ps1 [command]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Commands:" -ForegroundColor Cyan
    Write-Host "  help     Show this help"
    Write-Host "  status   Show system status"
    Write-Host "  clean    Clean workspace"
    Write-Host "  monitor  Monitor disk space"
    Write-Host "  report   Generate report"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Gray
    Write-Host "  .\auto-system-english.ps1 status"
    Write-Host "  .\auto-system-english.ps1 clean"
    Write-Host "  .\auto-system-english.ps1 monitor"
    Write-Host ""
    exit
}

# Status
if ($Command -eq "status") {
    Write-Host "System Status Report" -ForegroundColor Yellow
    Write-Host "===================="
    Write-Host ""
    
    # Disk space
    Write-Host "Disk Space:" -ForegroundColor Cyan
    $disk = Get-PSDrive C
    if ($disk) {
        $freeGB = [math]::Round($disk.Free / 1GB, 2)
        $totalGB = [math]::Round(($disk.Used + $disk.Free) / 1GB, 2)
        $usedPercent = [math]::Round(($disk.Used / ($disk.Used + $disk.Free)) * 100, 2)
        
        Write-Host "  C: Drive: ${freeGB} GB free / ${totalGB} GB total" -ForegroundColor Gray
        Write-Host "  Usage: ${usedPercent}%" -ForegroundColor $(if ($usedPercent -lt 80) {"Green"} elseif ($usedPercent -lt 90) {"Yellow"} else {"Red"})
    }
    Write-Host ""
    
    # Workspace
    Write-Host "Workspace Status:" -ForegroundColor Cyan
    $workspacePath = "C:\Users\luchaochao\.openclaw\workspace"
    if (Test-Path $workspacePath) {
        $files = Get-ChildItem -Path $workspacePath -File -Depth 0
        $dirs = Get-ChildItem -Path $workspacePath -Directory -Depth 0
        
        Write-Host "  Files: $($files.Count)" -ForegroundColor Gray
        Write-Host "  Directories: $($dirs.Count)" -ForegroundColor Gray
        
        # Check organized directories
        $orgDirs = @("docs", "scripts", "config", "data")
        $orgCount = 0
        foreach ($dir in $orgDirs) {
            $dirPath = Join-Path $workspacePath $dir
            if (Test-Path $dirPath) {
                $fileCount = (Get-ChildItem -Path $dirPath -File -ErrorAction SilentlyContinue).Count
                Write-Host "    $dir/: $fileCount files" -ForegroundColor DarkGray
                $orgCount++
            }
        }
        
        if ($orgCount -eq $orgDirs.Count) {
            Write-Host "  Organization: Good" -ForegroundColor Green
        } else {
            Write-Host "  Organization: Partial ($orgCount/$($orgDirs.Count))" -ForegroundColor Yellow
        }
    }
    Write-Host ""
    exit
}

# Clean workspace
if ($Command -eq "clean") {
    Write-Host "Cleaning Workspace" -ForegroundColor Yellow
    Write-Host "=================="
    Write-Host ""
    
    Write-Host "Scanning for temporary files..." -ForegroundColor Gray
    
    # Temp files
    $tempFiles = Get-ChildItem -Path "C:\Users\luchaochao\.openclaw\workspace" -Recurse -File -Include "*.tmp", "*.temp", "*.bak" -ErrorAction SilentlyContinue
    if ($tempFiles.Count -gt 0) {
        Write-Host "Found $($tempFiles.Count) temporary files" -ForegroundColor Gray
        $tempSize = ($tempFiles | Measure-Object Length -Sum).Sum
        
        $tempFiles | Remove-Item -Force -ErrorAction SilentlyContinue
        Write-Host "Deleted ($([math]::Round($tempSize/1MB,2)) MB)" -ForegroundColor Green
    } else {
        Write-Host "No temporary files found" -ForegroundColor Gray
    }
    Write-Host ""
    
    # Zero-byte files
    Write-Host "Scanning for zero-byte files..." -ForegroundColor Gray
    $zeroFiles = Get-ChildItem -Path "C:\Users\luchaochao\.openclaw\workspace" -Recurse -File -ErrorAction SilentlyContinue | Where-Object {$_.Length -eq 0}
    if ($zeroFiles.Count -gt 0) {
        Write-Host "Found $($zeroFiles.Count) zero-byte files" -ForegroundColor Gray
        $zeroFiles | Remove-Item -Force -ErrorAction SilentlyContinue
        Write-Host "Deleted" -ForegroundColor Green
    } else {
        Write-Host "No zero-byte files found" -ForegroundColor Gray
    }
    Write-Host ""
    
    Write-Host "Cleanup completed" -ForegroundColor Green
    Write-Host ""
    exit
}

# Monitor disk space
if ($Command -eq "monitor") {
    Write-Host "Disk Space Monitor" -ForegroundColor Yellow
    Write-Host "=================="
    Write-Host ""
    
    $disk = Get-PSDrive C
    if ($disk) {
        $freeGB = [math]::Round($disk.Free / 1GB, 2)
        $totalGB = [math]::Round(($disk.Used + $disk.Free) / 1GB, 2)
        $usedPercent = [math]::Round(($disk.Used / ($disk.Used + $disk.Free)) * 100, 2)
        
        Write-Host "Current Status:" -ForegroundColor Cyan
        Write-Host "  Free space: ${freeGB} GB" -ForegroundColor Gray
        Write-Host "  Total: ${totalGB} GB" -ForegroundColor Gray
        Write-Host "  Usage: ${usedPercent}%" -ForegroundColor $(if ($usedPercent -lt 80) {"Green"} elseif ($usedPercent -lt 90) {"Yellow"} else {"Red"})
        Write-Host ""
        
        # Recommendations
        Write-Host "Recommendations:" -ForegroundColor Cyan
        if ($usedPercent -lt 70) {
            Write-Host "  Space is sufficient, no cleanup needed" -ForegroundColor Green
        } elseif ($usedPercent -lt 80) {
            Write-Host "  Space is normal, recommend regular cleanup" -ForegroundColor Yellow
        } elseif ($usedPercent -lt 90) {
            Write-Host "  Space is tight, recommend immediate cleanup" -ForegroundColor Yellow
            Write-Host "  Run: .\auto-system-english.ps1 clean" -ForegroundColor Gray
        } else {
            Write-Host "  Space is critically low, urgent cleanup needed" -ForegroundColor Red
            Write-Host "  Run: .\auto-system-english.ps1 clean" -ForegroundColor Gray
        }
    }
    Write-Host ""
    exit
}

# Generate report
if ($Command -eq "report") {
    Write-Host "System Report" -ForegroundColor Yellow
    Write-Host "============="
    Write-Host ""
    
    $reportTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "Report time: $reportTime" -ForegroundColor Gray
    Write-Host ""
    
    # Call status function
    & $PSCommandPath "status"
    
    Write-Host "Report generated" -ForegroundColor Green
    Write-Host "Recommend regular cleanup and maintenance" -ForegroundColor Gray
    Write-Host ""
    exit
}

# Unknown command
Write-Host "Error: Unknown command '$Command'" -ForegroundColor Red
Write-Host ""
Write-Host "Use .\auto-system-english.ps1 help for help" -ForegroundColor Yellow
Write-Host ""