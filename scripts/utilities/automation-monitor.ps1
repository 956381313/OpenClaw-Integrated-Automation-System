# 自动化系统监控脚本
# 每日运行，监控磁盘使用率并执行清理

param(
    [string]$Mode = "monitor"
)

# 配置
$workspacePath = "C:\Users\luchaochao\.openclaw\workspace"
$logFile = "automation-system\logs\monitor-$(Get-Date -Format 'yyyyMMdd').log"
$threshold = 85  # 磁盘使用率告警阈值

# 确保日志目录存在
$logDir = Split-Path $logFile -Parent
if (!(Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $logFile -Value $logEntry
    Write-Host $logEntry
}

function Get-DiskUsage {
    $disk = Get-PSDrive -Name C
    $usedGB = [math]::Round($disk.Used / 1GB, 2)
    $freeGB = [math]::Round($disk.Free / 1GB, 2)
    $totalGB = [math]::Round(($disk.Used + $disk.Free) / 1GB, 2)
    $usagePercent = [math]::Round(($disk.Used / ($disk.Used + $disk.Free)) * 100, 2)
    
    return @{
        UsedGB = $usedGB
        FreeGB = $freeGB
        TotalGB = $totalGB
        UsagePercent = $usagePercent
    }
}

function Clean-TempFiles {
    Write-Log "开始清理临时文件..." "INFO"
    
    $tempFolders = @(
        "$env:TEMP\*",
        "$workspacePath\temp\*",
        "$workspacePath\logs\*.log",
        "$workspacePath\*.tmp",
        "$workspacePath\*.temp"
    )
    
    $totalFreed = 0
    foreach ($folder in $tempFolders) {
        if (Test-Path $folder) {
            $files = Get-ChildItem -Path $folder -File -Recurse -ErrorAction SilentlyContinue
            foreach ($file in $files) {
                try {
                    $sizeMB = [math]::Round($file.Length / 1MB, 2)
                    Remove-Item $file.FullName -Force -ErrorAction Stop
                    $totalFreed += $sizeMB
                    Write-Log "删除: $($file.Name) ($sizeMB MB)" "DEBUG"
                } catch {
                    Write-Log "无法删除: $($file.Name) - $_" "WARN"
                }
            }
        }
    }
    
    Write-Log "临时文件清理完成，释放: $([math]::Round($totalFreed, 2)) MB" "INFO"
    return $totalFreed
}

function Monitor-Disk {
    Write-Log "开始磁盘监控..." "INFO"
    
    $diskInfo = Get-DiskUsage
    Write-Log "磁盘使用情况:" "INFO"
    Write-Log "  总计: $($diskInfo.TotalGB) GB" "INFO"
    Write-Log "  已用: $($diskInfo.UsedGB) GB ($($diskInfo.UsagePercent)%)" "INFO"
    Write-Log "  可用: $($diskInfo.FreeGB) GB" "INFO"
    
    # 检查是否需要清理
    if ($diskInfo.UsagePercent -gt $threshold) {
        Write-Log "⚠️ 磁盘使用率超过阈值 ($threshold%)，执行清理..." "WARN"
        $freedMB = Clean-TempFiles
        
        # 清理后重新检查
        $diskInfoAfter = Get-DiskUsage
        $improvement = $diskInfo.UsagePercent - $diskInfoAfter.UsagePercent
        
        Write-Log "清理后磁盘使用情况:" "INFO"
        Write-Log "  已用: $($diskInfoAfter.UsedGB) GB ($($diskInfoAfter.UsagePercent)%)" "INFO"
        Write-Log "  可用: $($diskInfoAfter.FreeGB) GB" "INFO"
        Write-Log "  改善: $improvement%" "INFO"
        
        if ($improvement -gt 0) {
            Write-Log "✅ 清理成功，释放 $([math]::Round($freedMB, 2)) MB，使用率降低 $improvement%" "SUCCESS"
        } else {
            Write-Log "⚠️ 清理效果不明显，可能需要其他优化措施" "WARN"
        }
    } else {
        Write-Log "✅ 磁盘使用率正常 ($($diskInfo.UsagePercent)%)" "SUCCESS"
    }
    
    return $diskInfo
}

function Run-FullCleanup {
    Write-Log "执行完整清理..." "INFO"
    
    # 1. 监控磁盘
    $diskInfo = Monitor-Disk
    
    # 2. 清理临时文件
    $tempFreed = Clean-TempFiles
    
    # 3. 整理工作空间
    Write-Log "整理工作空间文件..." "INFO"
    
    # 创建归档目录
    $archiveDir = "$workspacePath\archive\$(Get-Date -Format 'yyyy-MM')"
    if (!(Test-Path $archiveDir)) {
        New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
    }
    
    # 移动旧日志文件到归档
    $oldLogs = Get-ChildItem -Path "$workspacePath\logs" -Filter "*.log" -File | 
               Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) }
    
    foreach ($log in $oldLogs) {
        try {
            Move-Item $log.FullName "$archiveDir\$($log.Name)" -Force
            Write-Log "归档旧日志: $($log.Name)" "INFO"
        } catch {
            Write-Log "无法归档: $($log.Name)" "WARN"
        }
    }
    
    # 4. 生成报告
    $report = @"
========================================
自动化系统清理报告
时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
========================================

磁盘使用情况:
  清理前: $($diskInfo.UsedGB) GB ($($diskInfo.UsagePercent)%)
  清理后: $(Get-DiskUsage).UsedGB GB ($(Get-DiskUsage).UsagePercent%)

清理成果:
  释放临时文件: $([math]::Round($tempFreed, 2)) MB
  归档旧日志: $($oldLogs.Count) 个文件

建议:
  $(if ((Get-DiskUsage).UsagePercent -gt $threshold) { "⚠️ 磁盘使用率仍较高，建议进一步清理" } else { "✅ 磁盘使用率正常" })

========================================
"@
    
    Write-Log $report "INFO"
    $report | Out-File "$workspacePath\automation-system\reports\cleanup-$(Get-Date -Format 'yyyyMMdd').txt" -Force
    
    Write-Log "完整清理完成！" "SUCCESS"
}

# 主程序
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  自动化系统监控 v1.0" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

switch ($Mode.ToLower()) {
    "monitor" {
        Write-Log "运行监控模式..." "INFO"
        Monitor-Disk
    }
    "cleanup" {
        Write-Log "运行清理模式..." "INFO"
        Run-FullCleanup
    }
    "test" {
        Write-Log "运行测试模式..." "INFO"
        Write-Host "磁盘信息测试:" -ForegroundColor Yellow
        $diskInfo = Get-DiskUsage
        Write-Host "  总计: $($diskInfo.TotalGB) GB" -ForegroundColor Cyan
        Write-Host "  已用: $($diskInfo.UsedGB) GB" -ForegroundColor Cyan
        Write-Host "  可用: $($diskInfo.FreeGB) GB" -ForegroundColor Cyan
        Write-Host "  使用率: $($diskInfo.UsagePercent)%" -ForegroundColor Cyan
        
        if ($diskInfo.UsagePercent -gt $threshold) {
            Write-Host "⚠️ 超过阈值 ($threshold%)" -ForegroundColor Red
        } else {
            Write-Host "✅ 正常范围内" -ForegroundColor Green
        }
    }
    default {
        Write-Host "可用模式:" -ForegroundColor Yellow
        Write-Host "  monitor  - 监控磁盘使用率" -ForegroundColor Cyan
        Write-Host "  cleanup  - 执行完整清理" -ForegroundColor Cyan
        Write-Host "  test     - 测试磁盘信息" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "示例: .\automation-monitor.ps1 monitor" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "日志文件: $logFile" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan