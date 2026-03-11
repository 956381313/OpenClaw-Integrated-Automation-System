# 简单磁盘检查脚本
# 兼容 Windows PowerShell 编码

param(
    [string]$Action = "check"
)

# 工作空间路径
$workspace = "C:\Users\luchaochao\.openclaw\workspace"
$threshold = 85  # 告警阈值

function Get-DiskInfo {
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

function Clean-WorkspaceTemp {
    Write-Host "清理工作空间临时文件..." -ForegroundColor Yellow
    
    $tempItems = @(
        "$workspace\temp\*",
        "$workspace\*.tmp",
        "$workspace\*.temp",
        "$workspace\*.log"  # 除了重要的日志文件
    )
    
    $totalFreedMB = 0
    foreach ($pattern in $tempItems) {
        if (Test-Path $pattern) {
            $files = Get-ChildItem -Path $pattern -File -ErrorAction SilentlyContinue
            foreach ($file in $files) {
                try {
                    $sizeMB = [math]::Round($file.Length / 1MB, 2)
                    Remove-Item $file.FullName -Force -ErrorAction Stop
                    $totalFreedMB += $sizeMB
                    Write-Host "  删除: $($file.Name) ($sizeMB MB)" -ForegroundColor Gray
                } catch {
                    Write-Host "  跳过: $($file.Name) (无法删除)" -ForegroundColor DarkYellow
                }
            }
        }
    }
    
    return $totalFreedMB
}

function Show-DiskStatus {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  磁盘状态检查" -ForegroundColor White
    Write-Host "========================================" -ForegroundColor Cyan
    
    $diskInfo = Get-DiskInfo
    
    Write-Host "磁盘 C: 信息:" -ForegroundColor Yellow
    Write-Host "  总容量: $($diskInfo.TotalGB) GB" -ForegroundColor Cyan
    Write-Host "  已使用: $($diskInfo.UsedGB) GB" -ForegroundColor Cyan
    Write-Host "  可用空间: $($diskInfo.FreeGB) GB" -ForegroundColor Cyan
    Write-Host "  使用率: $($diskInfo.UsagePercent)%" -ForegroundColor Cyan
    
    if ($diskInfo.UsagePercent -gt $threshold) {
        Write-Host "`n⚠️ 警告: 磁盘使用率超过 $threshold%!" -ForegroundColor Red
        Write-Host "   建议执行清理操作" -ForegroundColor Yellow
        return $true
    } else {
        Write-Host "`n✅ 状态正常: 磁盘使用率在安全范围内" -ForegroundColor Green
        return $false
    }
}

function Run-Cleanup {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  执行磁盘清理" -ForegroundColor White
    Write-Host "========================================" -ForegroundColor Cyan
    
    # 清理前状态
    $before = Get-DiskInfo
    Write-Host "清理前使用率: $($before.UsagePercent)%" -ForegroundColor Yellow
    
    # 执行清理
    $freedMB = Clean-WorkspaceTemp
    
    # 清理后状态
    Start-Sleep -Seconds 2  # 等待文件系统更新
    $after = Get-DiskInfo
    
    Write-Host "`n清理结果:" -ForegroundColor Yellow
    Write-Host "  释放空间: $([math]::Round($freedMB, 2)) MB" -ForegroundColor Cyan
    Write-Host "  使用率变化: $($before.UsagePercent)% → $($after.UsagePercent)%" -ForegroundColor Cyan
    Write-Host "  改善: $([math]::Round($before.UsagePercent - $after.UsagePercent, 2))%" -ForegroundColor Cyan
    
    if ($freedMB -gt 0) {
        Write-Host "`n✅ 清理完成!" -ForegroundColor Green
    } else {
        Write-Host "`nℹ️ 没有需要清理的临时文件" -ForegroundColor Blue
    }
}

# 主程序
switch ($Action.ToLower()) {
    "check" {
        $needsCleanup = Show-DiskStatus
        if ($needsCleanup) {
            Write-Host "`n运行 .\simple-disk-check.ps1 cleanup 执行清理" -ForegroundColor Yellow
        }
    }
    "cleanup" {
        Run-Cleanup
    }
    "status" {
        $diskInfo = Get-DiskInfo
        Write-Host "磁盘使用率: $($diskInfo.UsagePercent)%" -ForegroundColor Cyan
        Write-Host "可用空间: $($diskInfo.FreeGB) GB" -ForegroundColor Cyan
    }
    default {
        Write-Host "可用命令:" -ForegroundColor Yellow
        Write-Host "  check    - 检查磁盘状态" -ForegroundColor Cyan
        Write-Host "  cleanup  - 执行清理" -ForegroundColor Cyan
        Write-Host "  status   - 快速查看状态" -ForegroundColor Cyan
        Write-Host "`n示例: .\simple-disk-check.ps1 check" -ForegroundColor Green
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan