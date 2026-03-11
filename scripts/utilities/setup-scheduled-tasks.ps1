# 设置定期自动维护任务
# 版本: 1.0.0

Write-Host "设置定期自动维护任务" -ForegroundColor Cyan
Write-Host "========================"
Write-Host ""

# 检查管理员权限
function Test-Admin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
    Write-Host "警告: 需要管理员权限来创建计划任务" -ForegroundColor Yellow
    Write-Host "请以管理员身份运行此脚本" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "右键点击 PowerShell -> 以管理员身份运行" -ForegroundColor Gray
    exit 1
}

# 脚本路径
$scriptPath = "C:\Users\luchaochao\.openclaw\workspace\auto-system-english.ps1"
if (-not (Test-Path $scriptPath)) {
    Write-Host "错误: 主脚本不存在" -ForegroundColor Red
    Write-Host "路径: $scriptPath" -ForegroundColor Gray
    exit 1
}

Write-Host "主脚本位置: $scriptPath" -ForegroundColor Gray
Write-Host ""

# 任务定义
$tasks = @(
    @{
        Name = "Workspace-Daily-Monitor"
        Description = "每日工作空间监控"
        Trigger = @{
            Type = "Daily"
            At = "02:00"
        }
        Action = @{
            Command = "powershell.exe"
            Arguments = "-ExecutionPolicy Bypass -File `"$scriptPath`" monitor"
        }
    },
    @{
        Name = "Workspace-Weekly-Cleanup"
        Description = "每周工作空间清理"
        Trigger = @{
            Type = "Weekly"
            DaysOfWeek = "Monday"
            At = "03:00"
        }
        Action = @{
            Command = "powershell.exe"
            Arguments = "-ExecutionPolicy Bypass -File `"$scriptPath`" clean"
        }
    },
    @{
        Name = "Workspace-Monthly-Report"
        Description = "每月工作空间报告"
        Trigger = @{
            Type = "Monthly"
            DaysOfMonth = 1
            At = "04:00"
        }
        Action = @{
            Command = "powershell.exe"
            Arguments = "-ExecutionPolicy Bypass -File `"$scriptPath`" report"
        }
    }
)

# 创建任务函数
function Create-ScheduledTask {
    param(
        [string]$TaskName,
        [string]$Description,
        [hashtable]$Trigger,
        [hashtable]$Action
    )
    
    Write-Host "创建任务: $TaskName" -ForegroundColor Yellow
    Write-Host "  描述: $Description" -ForegroundColor Gray
    
    # 检查任务是否已存在
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-Host "  任务已存在，先删除..." -ForegroundColor Yellow
        try {
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop
            Write-Host "  旧任务已删除" -ForegroundColor Green
        } catch {
            Write-Host "  删除失败: $_" -ForegroundColor Red
            return $false
        }
    }
    
    # 创建触发器
    $taskTrigger = switch ($Trigger.Type) {
        "Daily" {
            New-ScheduledTaskTrigger -Daily -At $Trigger.At
        }
        "Weekly" {
            New-ScheduledTaskTrigger -Weekly -DaysOfWeek $Trigger.DaysOfWeek -At $Trigger.At
        }
        "Monthly" {
            New-ScheduledTaskTrigger -Monthly -DaysOfMonth $Trigger.DaysOfMonth -At $Trigger.At
        }
    }
    
    # 创建操作
    $taskAction = New-ScheduledTaskAction -Execute $Action.Command -Argument $Action.Arguments
    
    # 创建主体（使用SYSTEM账户）
    $taskPrincipal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    # 创建设置
    $taskSettings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -WakeToRun
    
    try {
        # 注册任务
        Register-ScheduledTask `
            -TaskName $TaskName `
            -Description $Description `
            -Trigger $taskTrigger `
            -Action $taskAction `
            -Principal $taskPrincipal `
            -Settings $taskSettings `
            -Force
        
        Write-Host "  ✅ 任务创建成功" -ForegroundColor Green
        
        # 显示触发时间
        $triggerTime = switch ($Trigger.Type) {
            "Daily" { "每天 $($Trigger.At)" }
            "Weekly" { "每周$($Trigger.DaysOfWeek) $($Trigger.At)" }
            "Monthly" { "每月$($Trigger.DaysOfMonth)号 $($Trigger.At)" }
        }
        Write-Host "  执行时间: $triggerTime" -ForegroundColor Gray
        
        return $true
    } catch {
        Write-Host "  ❌ 任务创建失败: $_" -ForegroundColor Red
        return $false
    }
    
    Write-Host ""
}

# 创建所有任务
Write-Host "开始创建计划任务..." -ForegroundColor Cyan
Write-Host ""

$successCount = 0
$totalCount = $tasks.Count

foreach ($task in $tasks) {
    $result = Create-ScheduledTask `
        -TaskName $task.Name `
        -Description $task.Description `
        -Trigger $task.Trigger `
        -Action $task.Action
    
    if ($result) {
        $successCount++
    }
    
    Write-Host ""
}

# 显示结果
Write-Host "=== 任务创建结果 ===" -ForegroundColor Cyan
Write-Host "成功: $successCount/$totalCount" -ForegroundColor $(if ($successCount -eq $totalCount) {"Green"} elseif ($successCount -gt 0) {"Yellow"} else {"Red"})
Write-Host ""

if ($successCount -gt 0) {
    Write-Host "已创建的任务列表:" -ForegroundColor Yellow
    foreach ($task in $tasks) {
        $taskExists = Get-ScheduledTask -TaskName $task.Name -ErrorAction SilentlyContinue
        if ($taskExists) {
            Write-Host "  ✅ $($task.Name)" -ForegroundColor Green
            Write-Host "     下次运行: $($taskExists.NextRunTime)" -ForegroundColor Gray
        } else {
            Write-Host "  ❌ $($task.Name)" -ForegroundColor Red
        }
    }
    Write-Host ""
}

# 验证任务
Write-Host "验证计划任务..." -ForegroundColor Cyan
$allTasks = Get-ScheduledTask -TaskName "Workspace-*" -ErrorAction SilentlyContinue

if ($allTasks.Count -gt 0) {
    Write-Host "找到 $($allTasks.Count) 个工作空间任务:" -ForegroundColor Green
    foreach ($task in $allTasks) {
        $state = $task.State
        $nextRun = if ($task.NextRunTime) { $task.NextRunTime.ToString("yyyy-MM-dd HH:mm") } else { "未计划" }
        Write-Host "  $($task.TaskName)" -ForegroundColor Gray
        Write-Host "    状态: $state" -ForegroundColor Gray
        Write-Host "    下次运行: $nextRun" -ForegroundColor Gray
        Write-Host ""
    }
} else {
    Write-Host "未找到工作空间任务" -ForegroundColor Yellow
}

# 创建测试任务（立即运行）
Write-Host "创建测试任务..." -ForegroundColor Cyan
$testTaskName = "Workspace-Test-Run"

try {
    # 删除已存在的测试任务
    $existingTest = Get-ScheduledTask -TaskName $testTaskName -ErrorAction SilentlyContinue
    if ($existingTest) {
        Unregister-ScheduledTask -TaskName $testTaskName -Confirm:$false -ErrorAction SilentlyContinue
    }
    
    # 创建立即运行的测试任务
    $testTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1)
    $testAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`" status"
    $testPrincipal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount
    $testSettings = New-ScheduledTaskSettingsSet -DeleteExpiredTaskAfter 00:00:01
    
    Register-ScheduledTask `
        -TaskName $testTaskName `
        -Description "工作空间系统测试任务" `
        -Trigger $testTrigger `
        -Action $testAction `
        -Principal $testPrincipal `
        -Settings $testSettings `
        -Force
    
    Write-Host "✅ 测试任务创建成功" -ForegroundColor Green
    Write-Host "   将在1分钟后运行状态检查" -ForegroundColor Gray
} catch {
    Write-Host "⚠️  测试任务创建失败: $_" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== 设置完成 ===" -ForegroundColor Green
Write-Host ""

Write-Host "已设置的维护计划:" -ForegroundColor Yellow
Write-Host "1. 每日监控 - 每天 02:00" -ForegroundColor Gray
Write-Host "2. 每周清理 - 每周一 03:00" -ForegroundColor Gray
Write-Host "3. 每月报告 - 每月1号 04:00" -ForegroundColor Gray
Write-Host ""

Write-Host "管理任务:" -ForegroundColor Cyan
Write-Host "• 查看任务: 任务计划程序 -> 任务计划程序库" -ForegroundColor Gray
Write-Host "• 手动运行: 右键任务 -> 运行" -ForegroundColor Gray
Write-Host "• 修改设置: 右键任务 -> 属性" -ForegroundColor Gray
Write-Host ""

Write-Host "系统将自动执行维护任务，无需人工干预。" -ForegroundColor Green
Write-Host ""

Write-Host "完成时间: $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Gray