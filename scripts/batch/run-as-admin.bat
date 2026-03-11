@echo off
title 设置定期维护任务 - 请以管理员身份运行
color 0C

echo ========================================
echo     定期维护任务设置工具
echo ========================================
echo.
echo 重要: 请以管理员身份运行此批处理文件
echo.
echo 如果没有管理员权限，任务将无法创建。
echo.
echo 右键点击此文件 -> 以管理员身份运行
echo.
pause
cls

echo 检查管理员权限...
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo 错误: 需要管理员权限！
    echo 请右键点击此文件 -> 以管理员身份运行
    echo.
    pause
    exit /b 1
)

echo 管理员权限确认！
echo.

echo ========================================
echo     开始设置定期维护任务
echo ========================================
echo.

echo 步骤1: 删除现有任务（如果存在）
echo ----------------------------------------
schtasks /delete /tn "Workspace-Daily-Monitor" /f 2>nul
if %errorLevel% equ 0 (
    echo   已删除: Workspace-Daily-Monitor
) else (
    echo   未找到: Workspace-Daily-Monitor
)

schtasks /delete /tn "Workspace-Weekly-Cleanup" /f 2>nul
if %errorLevel% equ 0 (
    echo   已删除: Workspace-Weekly-Cleanup
) else (
    echo   未找到: Workspace-Weekly-Cleanup
)

schtasks /delete /tn "Workspace-Monthly-Report" /f 2>nul
if %errorLevel% equ 0 (
    echo   已删除: Workspace-Monthly-Report
) else (
    echo   未找到: Workspace-Monthly-Report
)

echo.

echo 步骤2: 创建每日监控任务
echo ----------------------------------------
echo 任务: 每天凌晨2点检查磁盘空间
schtasks /create /tn "Workspace-Daily-Monitor" ^
  /tr "powershell -ExecutionPolicy Bypass -File \"C:\Users\luchaochao\.openclaw\workspace\auto-system-english.ps1\" monitor" ^
  /sc daily /st 02:00 /ru SYSTEM /f

if %errorLevel% equ 0 (
    echo   ✅ 创建成功: Workspace-Daily-Monitor
) else (
    echo   ❌ 创建失败: Workspace-Daily-Monitor
)
echo.

echo 步骤3: 创建每周清理任务
echo ----------------------------------------
echo 任务: 每周一凌晨3点清理工作空间
schtasks /create /tn "Workspace-Weekly-Cleanup" ^
  /tr "powershell -ExecutionPolicy Bypass -File \"C:\Users\luchaochao\.openclaw\workspace\auto-system-english.ps1\" clean" ^
  /sc weekly /d MON /st 03:00 /ru SYSTEM /f

if %errorLevel% equ 0 (
    echo   ✅ 创建成功: Workspace-Weekly-Cleanup
) else (
    echo   ❌ 创建失败: Workspace-Weekly-Cleanup
)
echo.

echo 步骤4: 创建每月报告任务
echo ----------------------------------------
echo 任务: 每月1号凌晨4点生成报告
schtasks /create /tn "Workspace-Monthly-Report" ^
  /tr "powershell -ExecutionPolicy Bypass -File \"C:\Users\luchaochao\.openclaw\workspace\auto-system-english.ps1\" report" ^
  /sc monthly /mo 1 /st 04:00 /ru SYSTEM /f

if %errorLevel% equ 0 (
    echo   ✅ 创建成功: Workspace-Monthly-Report
) else (
    echo   ❌ 创建失败: Workspace-Monthly-Report
)
echo.

echo ========================================
echo     验证任务创建
echo ========================================
echo.

echo 检查已创建的任务:
schtasks /query /tn "Workspace-*" /fo list | findstr /i "任务名\|下次运行时间\|状态"

echo.
echo ========================================
echo     创建测试任务
echo ========================================
echo.

echo 创建立即运行的测试任务...
schtasks /create /tn "Workspace-Test-Run" ^
  /tr "powershell -ExecutionPolicy Bypass -File \"C:\Users\luchaochao\.openclaw\workspace\auto-system-english.ps1\" status" ^
  /sc once /st %time% /ru SYSTEM /f

if %errorLevel% equ 0 (
    echo   ✅ 测试任务创建成功
    echo   正在运行测试...
    timeout /t 2 /nobreak >nul
    schtasks /run /tn "Workspace-Test-Run" 2>nul
    echo   测试任务已启动
) else (
    echo   ❌ 测试任务创建失败
)

echo.
echo ========================================
echo     设置完成！
echo ========================================
echo.

echo 已设置的维护计划:
echo   1. 每日监控 - 每天 02:00
echo   2. 每周清理 - 每周一 03:00
echo   3. 每月报告 - 每月1号 04:00
echo.

echo 管理命令:
echo   • 查看任务: schtasks /query /tn "Workspace-*"
echo   • 运行任务: schtasks /run /tn "Workspace-Daily-Monitor"
echo   • 删除任务: schtasks /delete /tn "Workspace-Daily-Monitor" /f
echo.

echo 系统将自动执行维护，无需人工干预。
echo.

echo 完成时间: %date% %time%
echo.

pause