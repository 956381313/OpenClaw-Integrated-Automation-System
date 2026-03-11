# System Performance Monitor

Write-Host "=== OpenClaw System Monitor ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Configuration
$logDir = "data/reports"
$maxLogs = 30  # Keep last 30 logs

# Create log directory
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    Write-Host "Created log directory: $logDir" -ForegroundColor Green
}

Write-Host "1. Collecting system metrics..." -ForegroundColor Yellow

# Collect metrics
$metrics = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # CPU Usage
    CPU = @{
        Usage = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
        Cores = (Get-WmiObject Win32_Processor).NumberOfCores
        Speed = (Get-WmiObject Win32_Processor).MaxClockSpeed
    }
    
    # Memory
    Memory = @{
        TotalGB = [math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
        FreeGB = [math]::Round((Get-WmiObject Win32_OperatingSystem).FreePhysicalMemory / 1MB, 2)
        UsagePercent = 100 - [math]::Round(((Get-WmiObject Win32_OperatingSystem).FreePhysicalMemory / (Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory) * 100, 2)
    }
    
    # Disk
    Disk = @{}
    
    # Network
    Network = @{
        Adapters = (Get-NetAdapter | Where-Object {$_.Status -eq "Up"}).Count
    }
    
    # Processes
    Processes = @{
        Total = (Get-Process).Count
        OpenClaw = (Get-Process | Where-Object {$_.ProcessName -like "*openclaw*"}).Count
    }
    
    # System Info
    System = @{
        OS = (Get-WmiObject Win32_OperatingSystem).Caption
        Uptime = (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
        User = $env:USERNAME
    }
}

# Get disk info
$disks = Get-WmiObject Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3}  # Fixed disks
foreach ($disk in $disks) {
    $diskInfo = @{
        Drive = $disk.DeviceID
        TotalGB = [math]::Round($disk.Size / 1GB, 2)
        FreeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
        UsedPercent = [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 2)
    }
    $metrics.Disk[$disk.DeviceID] = $diskInfo
}

# Save metrics to log file
$logFile = Join-Path $logDir "system-metrics-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$metrics | ConvertTo-Json -Depth 4 | Out-File $logFile -Encoding UTF8

Write-Host "  Metrics saved: $logFile" -ForegroundColor Green

# 2. Generate report
Write-Host "`n2. Generating system report..." -ForegroundColor Yellow

$report = @"
# System Performance Report
## Time: $($metrics.Timestamp)
## System: $($metrics.System.OS)
## User: $($metrics.System.User)

## CPU Usage:
- Usage: $([math]::Round($metrics.CPU.Usage, 2))%
- Cores: $($metrics.CPU.Cores)
- Speed: $($metrics.CPU.Speed) MHz

## Memory:
- Total: $($metrics.Memory.TotalGB) GB
- Free: $($metrics.Memory.FreeGB) GB
- Usage: $($metrics.Memory.UsagePercent)%

## Disk Usage:
$($metrics.Disk.Keys | ForEach-Object {
    $disk = $metrics.Disk[$_]
    "- $($disk.Drive): $($disk.UsedPercent)% used ($($disk.FreeGB) GB free of $($disk.TotalGB) GB)"
})

## Network:
- Active adapters: $($metrics.Network.Adapters)

## Processes:
- Total processes: $($metrics.Processes.Total)
- OpenClaw processes: $($metrics.Processes.OpenClaw)

## System Info:
- Uptime: $($metrics.System.Uptime.Days) days, $($metrics.System.Uptime.Hours) hours
- Last boot: $(Get-Date).Add(-$metrics.System.Uptime)

## Health Status:
$(if ($metrics.CPU.Usage -gt 90) { "鈿狅笍 CPU usage high (>90%)" } else { "鉁?CPU usage normal" })
$(if ($metrics.Memory.UsagePercent -gt 90) { "鈿狅笍 Memory usage high (>90%)" } else { "鉁?Memory usage normal" })
$(if ($metrics.Disk.Values | Where-Object {$_.UsedPercent -gt 90}) { "鈿狅笍 Disk usage high on some drives" } else { "鉁?Disk usage normal" })

## Recommendations:
$(if ($metrics.CPU.Usage -gt 90) { "- Check for CPU-intensive processes" })
$(if ($metrics.Memory.UsagePercent -gt 90) { "- Consider closing unused applications" })
$(if ($metrics.Disk.Values | Where-Object {$_.UsedPercent -gt 90}) { "- Clean up disk space on affected drives" })

## Log Files:
Latest log: $logFile
Total logs: $(Get-ChildItem $logDir -File).Count

## Next Monitoring:
Run this script regularly (e.g., hourly) to track system performance.

---
*OpenClaw System Monitor v1.0*
"@

$reportFile = Join-Path $logDir "system-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
$report | Out-File $reportFile -Encoding UTF8

Write-Host "  Report saved: $reportFile" -ForegroundColor Green

# 3. Clean up old logs
Write-Host "`n3. Cleaning up old logs..." -ForegroundColor Yellow

$logFiles = Get-ChildItem $logDir -File -Filter "*.json" | Sort-Object LastWriteTime -Descending
if ($logFiles.Count -gt $maxLogs) {
    $filesToDelete = $logFiles | Select-Object -Skip $maxLogs
    $deletedCount = 0
    
    foreach ($file in $filesToDelete) {
        Remove-Item $file.FullName -Force
        $deletedCount++
    }
    
    Write-Host "  Deleted $deletedCount old log files" -ForegroundColor Green
} else {
    Write-Host "  No cleanup needed (less than $maxLogs logs)" -ForegroundColor Gray
}

# 4. Show summary
Write-Host "`n=== System Monitor Complete ===" -ForegroundColor Green
Write-Host "CPU Usage: $([math]::Round($metrics.CPU.Usage, 2))%" -ForegroundColor Cyan
Write-Host "Memory Usage: $($metrics.Memory.UsagePercent)%" -ForegroundColor Cyan
Write-Host "Disk Usage: $($metrics.Disk.Count) drives monitored" -ForegroundColor Cyan
Write-Host "Log file: $logFile" -ForegroundColor Cyan
Write-Host "Report: $reportFile" -ForegroundColor Cyan

Write-Host "`nQuick commands:" -ForegroundColor Yellow
Write-Host "  # View latest report" -ForegroundColor Gray
Write-Host "  Get-Content $reportFile" -ForegroundColor Gray
Write-Host ""
Write-Host "  # View all logs" -ForegroundColor Gray
Write-Host "  Get-ChildItem $logDir -File | Sort-Object LastWriteTime -Descending" -ForegroundColor Gray

# Check if any alerts needed
if ($metrics.CPU.Usage -gt 90 -or $metrics.Memory.UsagePercent -gt 90 -or ($metrics.Disk.Values | Where-Object {$_.UsedPercent -gt 90})) {
    Write-Host "`n鈿狅笍  ALERT: System resources running high!" -ForegroundColor Red
}
