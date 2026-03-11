@echo off
title 设置定期维护任务 - 手动指南
color 0A

echo ========================================
echo     定期维护任务设置指南
echo ========================================
echo.
echo 请按照以下步骤设置Windows计划任务
echo.

echo 步骤1: 打开任务计划程序
echo -----------------------
echo 1. 按 Win + R
echo 2. 输入: taskschd.msc
echo 3. 按 Enter
echo.

echo 步骤2: 创建基本任务
echo -------------------
echo 1. 右侧点击"创建基本任务"
echo 2. 输入名称: Workspace-Daily-Monitor
echo 3. 描述: 每日工作空间监控
echo.

echo 步骤3: 设置触发器
echo ----------------
echo 选择"每天"
echo 开始时间: 02:00:00
echo.

echo 步骤4: 设置操作
echo ----------------
echo 选择"启动程序"
echo 程序/脚本: powershell.exe
echo 参数: -ExecutionPolicy Bypass -File "C:\Users\luchaochao\.openclaw\workspace\auto-system-english.ps1" monitor
echo.

echo 步骤5: 完成设置
echo ----------------
echo 点击"完成"
echo.

echo ========================================
echo     需要创建的三个任务
echo ========================================
echo.

echo 任务1: 每日监控
echo ---------------
echo 名称: Workspace-Daily-Monitor
echo 时间: 每天 02:00
echo 命令: .\auto-system-english.ps1 monitor
echo.

echo 任务2: 每周清理
echo ---------------
echo 名称: Workspace-Weekly-Cleanup
echo 时间: 每周一 03:00
echo 命令: .\auto-system-english.ps1 clean
echo.

echo 任务3: 每月报告
echo ---------------
echo 名称: Workspace-Monthly-Report
echo 时间: 每月1号 04:00
echo 命令: .\auto-system-english.ps1 report
echo.

echo ========================================
echo     快速设置命令（管理员运行）
echo ========================================
echo.
echo 以管理员身份打开PowerShell，运行以下命令:
echo.
echo :: 每日监控任务
echo schtasks /create /tn "Workspace-Daily-Monitor" ^
echo   /tr "powershell -ExecutionPolicy Bypass -File \"C:\Users\luchaochao\.openclaw\workspace\auto-system-english.ps1\" monitor" ^
echo   /sc daily /st 02:00 /ru SYSTEM
echo.
echo :: 每周清理任务
echo schtasks /create /tn "Workspace-Weekly-Cleanup" ^
echo   /tr "powershell -ExecutionPolicy Bypass -File \"C:\Users\luchaochao\.openclaw\workspace\auto-system-english.ps1\" clean" ^
echo   /sc weekly /d MON /st 03:00 /ru SYSTEM
echo.
echo :: 每月报告任务
echo schtasks /create /tn "Workspace-Monthly-Report" ^
echo   /tr "powershell -ExecutionPolicy Bypass -File \"C:\Users\luchaochao\.openclaw\workspace\auto-system-english.ps1\" report" ^
echo   /sc monthly /mo 1 /st 04:00 /ru SYSTEM
echo.

echo ========================================
echo     验证任务
echo ========================================
echo.
echo 验证命令:
echo schtasks /query /tn "Workspace-*"
echo.
echo 手动运行测试:
echo schtasks /run /tn "Workspace-Daily-Monitor"
echo.

echo ========================================
echo     注意事项
echo ========================================
echo.
echo 1. 需要管理员权限
echo 2. 系统会自动在后台运行
echo 3. 可以随时修改或删除任务
echo 4. 查看日志: 任务计划程序 -> 任务历史记录
echo.

pause