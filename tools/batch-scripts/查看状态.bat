@echo off
echo ========================================
echo    OpenClaw 自动化系统状态查看
echo ========================================
echo 时间: %date% %time%
echo.

echo 正在检查自动化任务状态...
echo.
powershell -ExecutionPolicy Bypass -File monitor-automation.ps1

echo.
echo 快速命令:
echo   1. 立即运行备份: 运行备份.bat
echo   2. 查看任务详情: 任务详情.bat
echo   3. 查看GitHub状态: GitHub状态.bat
echo.
pause