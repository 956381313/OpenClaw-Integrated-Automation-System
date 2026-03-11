@echo off
echo ========================================
echo    OpenClaw Automation Setup
echo ========================================
echo.

REM Check if running as administrator
net session >nul 2>&1
if errorlevel 1 (
    echo ERROR: Please run as Administrator
    echo Right-click this file and select "Run as administrator"
    pause
    exit /b 1
)

echo Setting up OpenClaw automation tasks...
echo.

REM 1. Hourly backup task
echo [1/4] Creating hourly backup task...
schtasks /create /tn "OpenClaw-AutoBackup" /tr "powershell -ExecutionPolicy Bypass -File \"%~dp0upload-simple.ps1\"" /sc hourly /st 00:00 /ru SYSTEM
if errorlevel 1 echo   Note: Task may already exist

REM 2. Daily security check
echo [2/4] Creating daily security check...
if exist "%~dp009-projects\security-tools\security-check-fixed.ps1" (
    schtasks /create /tn "OpenClaw-SecurityCheck" /tr "powershell -ExecutionPolicy Bypass -File \"%~dp009-projects\security-tools\security-check-fixed.ps1\"" /sc daily /st 09:00 /ru SYSTEM
    if errorlevel 1 echo   Note: Task may already exist
) else (
    echo   Skipping: Security check script not found
)

REM 3. Weekly audit
echo [3/4] Creating weekly audit...
if exist "%~dp009-projects\security-tools\weekly_security_audit.ps1" (
    schtasks /create /tn "OpenClaw-WeeklyAudit" /tr "powershell -ExecutionPolicy Bypass -File \"%~dp009-projects\security-tools\weekly_security_audit.ps1\"" /sc weekly /d SUN /st 04:00 /ru SYSTEM
    if errorlevel 1 echo   Note: Task may already exist
) else (
    echo   Skipping: Audit script not found
)

REM 4. Daily iteration
echo [4/4] Creating daily iteration...
if exist "%~dp009-projects\iteration\迭代引擎.ps1" (
    schtasks /create /tn "OpenClaw-Iteration" /tr "powershell -ExecutionPolicy Bypass -File \"%~dp009-projects\iteration\迭代引擎.ps1\"" /sc daily /st 02:00 /ru SYSTEM
    if errorlevel 1 echo   Note: Task may already exist
) else (
    echo   Skipping: Iteration script not found
)

echo.
echo ========================================
echo Setup Complete!
echo ========================================
echo.
echo Created tasks:
echo   OpenClaw-AutoBackup    - Hourly backup
echo   OpenClaw-SecurityCheck - Daily security check (09:00)
echo   OpenClaw-WeeklyAudit   - Weekly audit (Sunday 04:00)
echo   OpenClaw-Iteration     - Daily iteration (02:00)
echo.
echo To test backup now:
echo   powershell -ExecutionPolicy Bypass -File upload-simple.ps1
echo.
pause