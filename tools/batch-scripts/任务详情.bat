@echo off
echo ========================================
echo    OpenClaw 任务详细信息
echo ========================================
echo.

echo 所有OpenClaw任务:
echo.
powershell -Command "Get-ScheduledTask | Where-Object {`$_.TaskName -like 'OpenClaw*'} | Format-List TaskName, State, Description, LastRunTime, NextRunTime, LastTaskResult"

echo.
echo 详细查看命令:
echo   schtasks /query /tn "OpenClaw*" /fo list
echo   Get-ScheduledTask -TaskName "OpenClaw-AutoBackup" | Format-List
echo.
pause