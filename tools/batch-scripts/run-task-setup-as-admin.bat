@echo off
chcp 65001 >nul
echo ================================================
echo     OpenClaw 计划任务设置脚本
echo ================================================
echo.
echo 正在准备以管理员身份运行计划任务设置脚本...
echo.
echo 脚本: setup-scheduled-task-easy.ps1
echo 目标: 创建每周自动清理重复文件的计划任务
echo 权限: 需要管理员权限
echo.
echo 请按照以下步骤操作:
echo 1. 用户账户控制 (UAC) 提示出现时，点击"是"
echo 2. 在PowerShell窗口中按照提示操作
echo 3. 设置完成后验证任务状态
echo.
echo 按任意键开始执行，或按 Ctrl+C 取消...
pause >nul

echo.
echo 正在启动管理员PowerShell...
echo.

REM 获取当前目录
set "WORKDIR=%~dp0"
set "SCRIPT=%WORKDIR%setup-scheduled-task-easy.ps1"

REM 检查脚本是否存在
if not exist "%SCRIPT%" (
    echo 错误: 找不到设置脚本
    echo 请确保在正确的工作目录中运行
    echo 工作目录: %WORKDIR%
    pause
    exit /b 1
)

REM 以管理员身份运行PowerShell
PowerShell -Command "Start-Process PowerShell -Verb RunAs -ArgumentList '-ExecutionPolicy Bypass -NoExit -Command \"cd ''%WORKDIR%''; .\setup-scheduled-task-easy.ps1\"'"

echo.
echo ================================================
echo     管理员PowerShell已启动
echo ================================================
echo.
echo 请在新打开的PowerShell窗口中:
echo 1. 按照交互式提示完成设置
echo 2. 设置完成后关闭窗口
echo 3. 返回此窗口继续验证
echo.
echo 按任意键继续验证设置结果...
pause >nul

echo.
echo ================================================
echo     验证计划任务设置
echo ================================================
echo.
echo 正在验证任务设置...
echo.

PowerShell -ExecutionPolicy Bypass -Command "& {
    Write-Host '=== 任务验证 ===' -ForegroundColor Cyan
    Write-Host '时间: ' (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') -ForegroundColor Gray
    
    $TaskName = 'OpenClaw-Duplicate-Cleanup'
    
    try {
        $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop
        
        Write-Host '✓ 任务找到: ' $task.TaskName -ForegroundColor Green
        Write-Host '  状态: ' $task.State -ForegroundColor Gray
        Write-Host '  启用: ' $task.Enabled -ForegroundColor Gray
        
        $taskInfo = Get-ScheduledTaskInfo -TaskName $TaskName
        Write-Host '  上次运行: ' $taskInfo.LastRunTime -ForegroundColor Gray
        Write-Host '  下次运行: ' $taskInfo.NextRunTime -ForegroundColor Gray
        
        Write-Host '' 
        Write-Host '✓ 任务已正确配置并准备就绪' -ForegroundColor Green
        
    } catch {
        Write-Host '✗ 任务未找到或错误: ' $_ -ForegroundColor Red
        Write-Host ''
        Write-Host '建议:' -ForegroundColor Yellow
        Write-Host '  1. 检查是否已完成设置' -ForegroundColor Gray
        Write-Host '  2. 重新运行设置脚本' -ForegroundColor Gray
        Write-Host '  3. 查看设置日志: duplicate-logs\scheduled\' -ForegroundColor Gray
    }
    
    Write-Host ''
    Write-Host '验证完成' -ForegroundColor Gray
}"

echo.
echo ================================================
echo     设置完成
echo ================================================
echo.
echo 下一步操作:
echo 1. 查看详细设置指南: SCHEDULED-TASK-SETUP-GUIDE.md
echo 2. 查看完成报告: SCHEDULED-TASK-COMPLETION-REPORT.md
echo 3. 验证任务: .\verify-task-easy.ps1
echo 4. 立即测试运行: Start-ScheduledTask -TaskName "OpenClaw-Duplicate-Cleanup"
echo.
echo 任务将每周日03:00自动运行，清理重复文件并回收磁盘空间。
echo.
echo 按任意键退出...
pause >nul