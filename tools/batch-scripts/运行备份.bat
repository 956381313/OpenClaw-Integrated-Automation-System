@echo off
echo ========================================
echo    OpenClaw 立即运行备份
echo ========================================
echo 时间: %date% %time%
echo.

echo 正在启动备份任务...
powershell -Command "Start-ScheduledTask -TaskName 'OpenClaw-AutoBackup'; Write-Host '备份任务已启动!' -ForegroundColor Green"

echo.
echo 备份进程已开始，请等待完成...
echo 查看GitHub: https://github.com/956381313/OpenClaw
echo.
pause