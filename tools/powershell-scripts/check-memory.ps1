# Memory Check Script
# Check current memory usage and identify issues

Write-Host "=== 系统内存检查 ===" -ForegroundColor Cyan
Write-Host "时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Get memory information
try {
    $os = Get-WmiObject Win32_OperatingSystem
    $totalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $freeGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $usedGB = $totalGB - $freeGB
    $usagePercent = [math]::Round(($usedGB / $totalGB) * 100, 2)
    
    Write-Host "内存使用情况:" -ForegroundColor Yellow
    Write-Host "  总内存: ${totalGB}GB" -ForegroundColor Gray
    Write-Host "  已使用: ${usedGB}GB" -ForegroundColor Gray
    Write-Host "  可用: ${freeGB}GB" -ForegroundColor Gray
    Write-Host "  使用率: ${usagePercent}%" -ForegroundColor $(if ($usagePercent -gt 90) { "Red" } elseif ($usagePercent -gt 70) { "Yellow" } else { "Green" })
    
    # Check disk space
    Write-Host "`n磁盘空间检查:" -ForegroundColor Yellow
    
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -gt 0 }
    foreach ($drive in $drives) {
        $freePercent = [math]::Round(($drive.Free / $drive.Used) * 100, 2)
        $usedPercent = [math]::Round(100 - $freePercent, 2)
        
        $color = if ($usedPercent -gt 90) { "Red" } elseif ($usedPercent -gt 70) { "Yellow" } else { "Green" }
        
        Write-Host "  $($drive.Name):" -ForegroundColor Gray
        Write-Host "    已用: $usedPercent%" -ForegroundColor $color
        Write-Host "    可用: $freePercent%" -ForegroundColor Gray
        Write-Host "    总空间: $([math]::Round($drive.Used/1GB,2))GB" -ForegroundColor Gray
    }
    
    # Check top memory-consuming processes
    Write-Host "`n内存占用最高的进程:" -ForegroundColor Yellow
    
    $processes = Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 5
    foreach ($process in $processes) {
        $memoryMB = [math]::Round($process.WorkingSet64 / 1MB, 2)
        Write-Host "  $($process.Name): ${memoryMB}MB (PID: $($process.Id))" -ForegroundColor Gray
    }
    
    # Recommendations
    Write-Host "`n=== 建议操作 ===" -ForegroundColor Cyan
    
    if ($usagePercent -gt 90) {
        Write-Host "⚠️ 内存使用率过高 ($usagePercent%)" -ForegroundColor Red
        Write-Host "  建议立即操作:" -ForegroundColor Yellow
        Write-Host "  1. 重启高内存占用的应用程序" -ForegroundColor Gray
        Write-Host "  2. 检查内存泄漏" -ForegroundColor Gray
        Write-Host "  3. 考虑增加物理内存" -ForegroundColor Gray
    }
    
    # Check for disk space issues
    $criticalDrives = $drives | Where-Object { 
        $usedPercent = [math]::Round(100 - ($_.Free / $_.Used * 100), 2)
        $usedPercent -gt 90
    }
    
    if ($criticalDrives) {
        Write-Host "`n⚠️ 磁盘空间严重不足:" -ForegroundColor Red
        foreach ($drive in $criticalDrives) {
            $usedPercent = [math]::Round(100 - ($drive.Free / $drive.Used * 100), 2)
            Write-Host "  $($drive.Name): $usedPercent% 已使用" -ForegroundColor Red
        }
        Write-Host "  建议立即清理磁盘空间" -ForegroundColor Yellow
    }
    
    # System uptime
    $uptime = (Get-Date) - $os.LastBootUpTime
    Write-Host "`n系统运行时间:" -ForegroundColor Yellow
    Write-Host "  $($uptime.Days)天 $($uptime.Hours)小时 $($uptime.Minutes)分钟" -ForegroundColor Gray
    
    if ($uptime.Days -gt 7) {
        Write-Host "  ⚠️ 建议重启系统以释放内存" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "错误: 无法获取系统信息" -ForegroundColor Red
    Write-Host "详细信息: $_" -ForegroundColor Yellow
}

Write-Host "`n=== 检查完成 ===" -ForegroundColor Green