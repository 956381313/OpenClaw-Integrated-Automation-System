# 一键设置定期维护任务
# 需要管理员权限运行

# 检查管理员权限
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "错误: 需要管理员权限运行此脚本" -ForegroundColor Red
    Write-Host "请右键点击 PowerShell -> 以管理员身份运行" -ForegroundColor Yellow
    Write-Host ""
    pause
    exit 1
}

Write-Host "设置定期维护任务" -ForegroundColor Cyan
Write-Host "=================="
Write-Host ""

# 脚本路径
$scriptPath = "C:\Users\luchaochao\.openclaw\workspace\auto-system-english.ps1"
if (-not (Test-Path $scriptPath)) {
    Write-Host "错误: 找不到主脚本" -ForegroundColor Red
    Write-Host "路径: $scriptPath" -ForegroundColor Gray
    pause
    exit 1
}

Write-Host "主脚本: $scriptPath" -ForegroundColor Gray
Write-Host ""

# 任务定义
$tasks = @(
    @{
        Name = "Workspace-Daily-Monitor"
        Description = "每日工作空间监控"
        Schedule = "DAILY"
        Time = "02:00"
        Command = "`"$scriptPath`" monitor"
    },
    @{
        Name = "Workspace-Weekly-Cleanup"
        Description = "每周工作空间清理"
        Schedule = "WEEKLY"
        Day = "MON"
        Time = "03:00"
        Command = "`"$scriptPath`" clean"
    },
    @{
        Name = "Workspace-Monthly-Report"
        Description = "每月工作空间报告"
        Schedule = "MONTHLY"
        Day = "1"
        Time = "04:00"
        Command = "`"$scriptPath`" report"
    }
)

# 创建任务函数
function Create-Task {
    param($task)
    
    Write-Host "创建任务: $($task.Name)" -ForegroundColor Yellow
    Write-Host "  描述: $($task.Description)" -ForegroundColor Gray
    
    # 构建schtasks命令
    $cmd = "schtasks /create /tn `"$($task.Name)`" /tr `"powershell -ExecutionPolicy Bypass -File $($task.Command)`""
    $cmd += " /sc $($task.Schedule) /st $($task.Time) /ru SYSTEM /f"
    
    if ($task.Schedule -eq "WEEKLY") {
        $cmd += " /d $($task.Day)"
    } elseif ($task.Schedule -eq "MONTHLY") {
        $cmd += " /mo $($task.Day)"
    }
    
    # 执行命令
    try {
        $output = cmd /c $cmd 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ 创建成功" -ForegroundColor Green
            
            # 显示执行时间
            $scheduleInfo = switch ($task.Schedule) {
                "DAILY" { "每天 $($task.Time)" }
                "WEEKLY" { "每周$($task.Day) $($task.Time)" }
                "MONTHLY" { "每月$($task.Day)号 $($task.Time)" }
            }
            Write-Host "  执行时间: $scheduleInfo" -ForegroundColor Gray
            
            return $true
        } else {
            Write-Host "  ❌ 创建失败" -ForegroundColor Red
            Write-Host "  错误: $output" -ForegroundColor DarkRed
            return $false
        }
    } catch {
        Write-Host "  ❌ 执行错误: $_" -ForegroundColor Red
        return $false
    }
    
    Write-Host ""
}

# 删除现有任务
Write-Host "清理现有任务..." -ForegroundColor Gray
foreach ($task in $tasks) {
    $existing = schtasks /query /tn $task.Name 2>$null
    if ($existing) {
        Write-Host "  删除: $($task.Name)" -ForegroundColor DarkGray
        schtasks /delete /tn $task.Name /f 2>$null
    }
}
Write-Host ""

# 创建新任务
Write-Host "创建新任务..." -ForegroundColor Cyan
Write-Host ""

$successCount = 0
foreach ($task in $tasks) {
    if (Create-Task $task) {
        $successCount++
    }
    Write-Host ""
}

# 显示结果
Write-Host "=== 任务创建结果 ===" -ForegroundColor Cyan
Write-Host "成功创建: $successCount/$($tasks.Count) 个任务" -ForegroundColor $(if ($successCount -eq $tasks.Count) {"Green"} elseif ($successCount -gt 0) {"Yellow"} else {"Red"})
Write-Host ""

# 验证任务
Write-Host "验证任务状态..." -ForegroundColor Cyan
$allTasks = schtasks /query /fo list | Select-String "Workspace-" | ForEach-Object { ($_ -split ":")[1].Trim() } | Get-Unique

if ($allTasks.Count -gt 0) {
    Write-Host "找到 $($allTasks.Count) 个任务:" -ForegroundColor Green
    foreach ($taskName in $allTasks) {
        $taskInfo = schtasks /query /tn $taskName /fo list 2>$null
        $nextRun = ($taskInfo | Select-String "下次运行时间") -replace "下次运行时间:", "" | ForEach-Object { $_.Trim() }
        $status = ($taskInfo | Select-String "状态") -replace "状态:", "" | ForEach-Object { $_.Trim() }
        
        Write-Host "  $taskName" -ForegroundColor Gray
        if ($nextRun) {
            Write-Host "    下次运行: $nextRun" -ForegroundColor DarkGray
        }
        if ($status) {
            Write-Host "    状态: $status" -ForegroundColor DarkGray
        }
        Write-Host ""
    }
} else {
    Write-Host "未找到任务" -ForegroundColor Yellow
}

# 创建测试任务
Write-Host "创建测试任务..." -ForegroundColor Cyan
$testTaskName = "Workspace-Test-Run"
$testCmd = "schtasks /create /tn `"$testTaskName`" /tr `"powershell -ExecutionPolicy Bypass -File `"$scriptPath`" status`" /sc once /st $(Get-Date -Format 'HH:mm') /ru SYSTEM /f"

try {
    $testOutput = cmd /c $testCmd 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ 测试任务创建成功" -ForegroundColor Green
        Write-Host "   将立即运行状态检查" -ForegroundColor Gray
        
        # 立即运行测试
        Start-Sleep -Seconds 2
        schtasks /run /tn $testTaskName 2>$null
        Write-Host "   测试任务已启动" -ForegroundColor Gray
    }
} catch {
    Write-Host "⚠️  测试任务创建失败" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== 设置完成 ===" -ForegroundColor Green
Write-Host ""

Write-Host "已设置的维护计划:" -ForegroundColor Yellow
Write-Host "1. 每日监控 - 每天 02:00" -ForegroundColor Gray
Write-Host "   命令: .\auto-system-english.ps1 monitor" -ForegroundColor DarkGray
Write-Host ""
Write-Host "2. 每周清理 - 每周一 03:00" -ForegroundColor Gray
Write-Host "   命令: .\auto-system-english.ps1 clean" -ForegroundColor DarkGray
Write-Host ""
Write-Host "3. 每月报告 - 每月1号 04:00" -ForegroundColor Gray
Write-Host "   命令: .\auto-system-english.ps1 report" -ForegroundColor DarkGray
Write-Host ""

Write-Host "管理命令:" -ForegroundColor Cyan
Write-Host "• 查看所有任务: schtasks /query /tn `"Workspace-*`"" -ForegroundColor Gray
Write-Host "• 手动运行任务: schtasks /run /tn `"任务名称`"" -ForegroundColor Gray
Write-Host "• 删除任务: schtasks /delete /tn `"任务名称`" /f" -ForegroundColor Gray
Write-Host ""

Write-Host "系统将自动执行维护，无需人工干预。" -ForegroundColor Green
Write-Host ""

Write-Host "完成时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

pause