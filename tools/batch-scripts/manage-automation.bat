@echo off
chcp 65001 >nul
echo ========================================
echo    OpenClaw Automation Manager
echo ========================================
echo.

if "%1"=="" goto menu

if "%1"=="status" goto status
if "%1"=="start" goto start
if "%1"=="stop" goto stop
if "%1"=="run" goto run
if "%1"=="delete" goto delete
if "%1"=="log" goto log

echo Unknown command: %1
goto end

:menu
echo Available commands:
echo   status  - Show task status
echo   start   - Start all tasks
echo   stop    - Stop all tasks
echo   run     - Run backup now
echo   delete  - Delete all tasks
echo   log     - Show recent logs
echo.
echo Example: %~n0 status
goto end

:status
echo Checking OpenClaw automation tasks...
echo.
schtasks /query /tn "OpenClaw*" /fo list
goto end

:start
echo Starting OpenClaw automation tasks...
schtasks /run /tn "OpenClaw-AutoBackup"
schtasks /run /tn "OpenClaw-SecurityCheck"
schtasks /run /tn "OpenClaw-WeeklyAudit"
schtasks /run /tn "OpenClaw-Iteration"
echo Tasks started.
goto end

:stop
echo Stopping OpenClaw automation tasks...
schtasks /end /tn "OpenClaw-AutoBackup"
schtasks /end /tn "OpenClaw-SecurityCheck"
schtasks /end /tn "OpenClaw-WeeklyAudit"
schtasks /end /tn "OpenClaw-Iteration"
echo Tasks stopped.
goto end

:run
echo Running backup now...
powershell -ExecutionPolicy Bypass -File "%~dp0upload-simple.ps1"
goto end

:delete
echo Deleting OpenClaw automation tasks...
schtasks /delete /tn "OpenClaw-AutoBackup" /f
schtasks /delete /tn "OpenClaw-SecurityCheck" /f
schtasks /delete /tn "OpenClaw-WeeklyAudit" /f
schtasks /delete /tn "OpenClaw-Iteration" /f
echo Tasks deleted.
goto end

:log
echo Recent backup logs:
echo.
if exist "backup-log.txt" (
    type "backup-log.txt" | tail -20
) else (
    echo No log file found.
)
goto end

:end
echo.
pause