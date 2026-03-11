@echo off
chcp 65001 >nul
echo ========================================
echo OpenClaw Email Notification Test
echo ========================================
echo.
echo Testing email notification system...
echo.

echo Available notification types:
echo 1. BackupComplete - Backup completion notification
echo 2. SecurityCheck - Security check results
echo 3. SystemAlert - System alerts and warnings
echo 4. DailySummary - Daily activity summary
echo.

set /p choice="Enter notification type number (1-4) or name: "

if "%choice%"=="1" set type=BackupComplete
if "%choice%"=="2" set type=SecurityCheck
if "%choice%"=="3" set type=SystemAlert
if "%choice%"=="4" set type=DailySummary

if "%type%"=="" set type=%choice%

echo.
echo Testing email type: %type%
echo.

powershell -ExecutionPolicy Bypass -File "send-email.ps1" -Type "%type%" -Test

echo.
echo ========================================
echo Test completed
echo ========================================
echo.
pause