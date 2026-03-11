# 定期维护计划脚本
# 版本: 1.0.0

param(
    [string]$Schedule = "weekly",
    [switch]$Setup,
    [switch]$Remove,
    [switch]$List
)

# 显示标题
function Show-Title {
    Write-Host "定期维护计划管理" -ForegroundColor Cyan
    Write-Host "=================="
    Write-Host ""
}

# 显示帮助
function Show-Help {
    Write-Host "使用方法: .\maintenance-schedule.ps1 [选项]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "选项:" -ForegroundColor Cyan
    Write-Host "  -Schedule <计划>  维护计划: daily(每日), weekly(每周), monthly(每月)"
    Write-Host "  -Setup            设置计划任务"
    Write-Host "  -Remove           移除计划任务"
    Write-Host "  -List             列出计划任务"
    Write-Host "  -Help             显示帮助"
    Write-Host ""
    Write-Host "示例:" -ForegroundColor Gray
    Write-Host "  .\maintenance-schedule.ps1 -Schedule weekly -Setup"
    Write-Host "  .\maintenance-schedule.ps1 -List"
    Write-Host "  .\maintenance-schedule.ps1 -Remove"
    Write-Host ""
}

# 列出计划任务
function List-ScheduledTasks {
    Write-Host "当前计划任务:" -ForegroundColor Yellow
    Write-Host "=============="
    Write-Host ""
    
    $tasks = @(
        @{Name="AutoWorkspace-Daily"; Description="每日快速检查"},
        @{Name="AutoWorkspace-Weekly"; Description="每周完整清理"},
        @{Name="AutoWorkspace-Monthly"; Description="每月报告生成"}
    )
    
    foreach ($task in $tasks) {
        $taskExists = Get-ScheduledTask -TaskName $task.Name -ErrorAction SilentlyContinue
        if ($taskExists) {
            $state = $taskExists.State
            Write-Host "  ✅ $($task.Name)" -ForegroundColor Green
            Write-Host "     描述: $($task.Description)" -ForegroundColor Gray
            Write-Host "     状态: $state" -ForegroundColor Gray
        } else {
            Write-Host "  ❌ $($task.Name)" -ForegroundColor Red
            Write-Host "     描述: $($task.Description)" -ForegroundColor Gray
            Write-Host "     状态: 未安装" -ForegroundColor Gray
        }
        Write-Host ""
    }
}

# 设置计划任务
function Setup-ScheduledTask {
    param($scheduleType)
    
    Write-Host "设置 $scheduleType 维护计划..." -ForegroundColor Yellow
    Write-Host ""
    
    $scriptPath = "C:\Users\luchaochao\.openclaw\workspace\auto-system-final.ps1"
    
    if (-not (Test-Path $scriptPath)) {
        Write-Host "错误: 主脚本不存在: $scriptPath" -ForegroundColor Red
        return
    }
    
    switch ($scheduleType.ToLower()) {
        "daily" {
            $taskName = "AutoWorkspace-Daily"
            $taskDescription = "每日工作空间快速检查"
            $trigger = New-ScheduledTaskTrigger -Daily -At "02:00"
            $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`" monitor"
        }
        "weekly" {
            $taskName = "AutoWorkspace-Weekly"
            $taskDescription = "每周工作空间完整清理"
            $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At "03:00"
            $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`" clean -Mode full"
        }
        "monthly" {
            $taskName = "AutoWorkspace-Monthly"
            $taskDescription = "每月工作空间报告生成"
            $trigger = New-ScheduledTaskTrigger -Monthly -DaysOfMonth 1 -At "04:00"
            $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`" report"
        }
        default {
            Write-Host "错误: 未知的计划类型 '$scheduleType'" -ForegroundColor Red
            return
        }
    }
    
    # 检查任务是否已存在
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-Host "任务已存在，先删除..." -ForegroundColor Yellow
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    }
    
    try {
        # 创建任务
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        
        Register-ScheduledTask -TaskName $taskName `
            -Description $taskDescription `
            -Trigger $trigger `
            -Action $action `
            -Principal $principal `
            -Settings $settings `
            -Force
        
        Write-Host "✅ $scheduleType 维护计划设置成功" -ForegroundColor Green
        Write-Host "   任务名称: $taskName" -ForegroundColor Gray
        Write-Host "   描述: $taskDescription" -ForegroundColor Gray
        
        # 显示触发器信息
        $triggerInfo = switch ($scheduleType.ToLower()) {
            "daily" { "每天 02:00" }
            "weekly" { "每周一 03:00" }
            "monthly" { "每月1号 04:00" }
        }
        Write-Host "   执行时间: $triggerInfo" -ForegroundColor Gray
        
    } catch {
        Write-Host "❌ 设置失败: $_" -ForegroundColor Red
    }
    
    Write-Host ""
}

# 移除计划任务
function Remove-ScheduledTasks {
    Write-Host "移除计划任务..." -ForegroundColor Yellow
    Write-Host ""
    
    $tasks = @("AutoWorkspace-Daily", "AutoWorkspace-Weekly", "AutoWorkspace-Monthly")
    $removedCount = 0
    
    foreach ($taskName in $tasks) {
        $taskExists = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        if ($taskExists) {
            try {
                Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
                Write-Host "  已移除: $taskName" -ForegroundColor Green
                $removedCount++
            } catch {
                Write-Host "  移除失败: $taskName" -ForegroundColor Red
            }
        } else {
            Write-Host "  不存在: $taskName" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    Write-Host "移除完成: $removedCount 个任务" -ForegroundColor $(if ($removedCount -gt 0) {"Green"} else {"Gray"})
    Write-Host ""
}

# 主程序
Show-Title

if ($Help -or ($PSBoundParameters.Count -eq 0)) {
    Show-Help
    exit
}

if ($List) {
    List-ScheduledTasks
    exit
}

if ($Remove) {
    Remove-ScheduledTasks
    exit
}

if ($Setup) {
    if (-not $Schedule) {
        Write-Host "错误: 需要指定 -Schedule 参数" -ForegroundColor Red
        Show-Help
        exit 1
    }
    
    Setup-ScheduledTask -scheduleType $Schedule
    exit
}

# 默认显示帮助
Show-Help