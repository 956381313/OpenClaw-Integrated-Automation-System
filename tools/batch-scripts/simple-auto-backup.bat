@echo off
echo ========================================
echo    OpenClaw 自动化备份系统
echo ========================================
echo 时间: %date% %time%
echo.

REM 配置
set SOURCE=C:\Users\luchaochao\.openclaw
set BACKUP_ROOT=D:\OpenClaw-Backup
set BACKUP_NAME=backup-%date:~0,4%%date:~5,2%%date:~8,2%-%time:~0,2%%time:~3,2%
set BACKUP_PATH=%BACKUP_ROOT%\%BACKUP_NAME%

REM 创建目录
if not exist "%BACKUP_ROOT%" mkdir "%BACKUP_ROOT%"
if not exist "%BACKUP_PATH%" mkdir "%BACKUP_PATH%"

REM 检查源目录
if not exist "%SOURCE%" (
    echo 错误: OpenClaw目录不存在: %SOURCE%
    pause
    exit /b 1
)

echo 正在创建备份: %BACKUP_NAME%
echo.

REM 复制核心文件
set FILE_COUNT=0

if exist "%SOURCE%\openclaw.json" (
    copy "%SOURCE%\openclaw.json" "%BACKUP_PATH%\"
    set /a FILE_COUNT+=1
    echo   复制: openclaw.json
)

if exist "%SOURCE%\gateway.cmd" (
    copy "%SOURCE%\gateway.cmd" "%BACKUP_PATH%\"
    set /a FILE_COUNT+=1
    echo   复制: gateway.cmd
)

if exist "%SOURCE%\update-check.json" (
    copy "%SOURCE%\update-check.json" "%BACKUP_PATH%\"
    set /a FILE_COUNT+=1
    echo   复制: update-check.json
)

if exist "%SOURCE%\workspace\AGENTS.md" (
    copy "%SOURCE%\workspace\AGENTS.md" "%BACKUP_PATH%\"
    set /a FILE_COUNT+=1
    echo   复制: AGENTS.md
)

if exist "%SOURCE%\workspace\SOUL.md" (
    copy "%SOURCE%\workspace\SOUL.md" "%BACKUP_PATH%\"
    set /a FILE_COUNT+=1
    echo   复制: SOUL.md
)

if exist "%SOURCE%\workspace\TOOLS.md" (
    copy "%SOURCE%\workspace\TOOLS.md" "%BACKUP_PATH%\"
    set /a FILE_COUNT+=1
    echo   复制: TOOLS.md
)

if exist "%SOURCE%\workspace\USER.md" (
    copy "%SOURCE%\workspace\USER.md" "%BACKUP_PATH%\"
    set /a FILE_COUNT+=1
    echo   复制: USER.md
)

if exist "%SOURCE%\workspace\IDENTITY.md" (
    copy "%SOURCE%\workspace\IDENTITY.md" "%BACKUP_PATH%\"
    set /a FILE_COUNT+=1
    echo   复制: IDENTITY.md
)

REM 创建备份信息
echo { > "%BACKUP_PATH%\backup-info.json"
echo   "BackupTime": "%date% %time%", >> "%BACKUP_PATH%\backup-info.json"
echo   "FileCount": %FILE_COUNT%, >> "%BACKUP_PATH%\backup-info.json"
echo   "Source": "%SOURCE%", >> "%BACKUP_PATH%\backup-info.json"
echo   "Backup": "%BACKUP_PATH%" >> "%BACKUP_PATH%\backup-info.json"
echo } >> "%BACKUP_PATH%\backup-info.json"

set /a FILE_COUNT+=1

echo.
echo ========================================
echo 备份完成!
echo 备份名称: %BACKUP_NAME%
echo 文件数量: %FILE_COUNT%
echo 备份位置: %BACKUP_PATH%
echo ========================================

REM 创建计划任务
echo.
echo 要创建每小时自动备份任务，请运行:
echo schtasks /create /tn "OpenClaw-Backup" ^
echo   /tr "%~dp0simple-auto-backup.bat" ^
echo   /sc hourly /st 00:00

pause