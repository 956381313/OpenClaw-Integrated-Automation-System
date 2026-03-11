@echo off
chcp 65001 >nul
echo ========================================
echo    OpenClaw Automation Setup (Fixed)
echo ========================================
echo Time: %date% %time%
echo.

REM Check admin rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: Need Administrator rights
    echo Please run as Administrator
    pause
    exit /b 1
)

echo Setting up automation tasks...
echo.

REM 1. Create hourly backup task
echo [1/4] Creating hourly backup task...
schtasks /create /tn "OpenClaw-AutoBackup" /tr "powershell -ExecutionPolicy Bypass -File \"%~dp0upload-simple.ps1\"" /sc hourly /st 00:00 /ru SYSTEM

if %errorLevel% equ 0 (
    echo   [OK] Task created
) else (
    echo   [WARN] Task may already exist
)

REM 2. Create daily security check task
echo [2/4] Creating daily security check task...
if exist "%~dp009-projects\security-tools\daily_security_check.ps1" (
    schtasks /create /tn "OpenClaw-SecurityCheck" /tr "powershell -ExecutionPolicy Bypass -File \"%~dp009-projects\security-tools\daily_security_check.ps1\"" /sc daily /st 09:00 /ru SYSTEM
    if %errorLevel% equ 0 (
        echo   [OK] Task created
    ) else (
        echo   [WARN] Task may already exist
    )
) else (
    echo   [SKIP] Security check script not found
)

REM 3. Create weekly audit task
echo [3/4] Creating weekly audit task...
if exist "%~dp009-projects\security-tools\weekly_security_audit.ps1" (
    schtasks /create /tn "OpenClaw-WeeklyAudit" /tr "powershell -ExecutionPolicy Bypass -File \"%~dp009-projects\security-tools\weekly_security_audit.ps1\"" /sc weekly /d SUN /st 04:00 /ru SYSTEM
    if %errorLevel% equ 0 (
        echo   [OK] Task created
    ) else (
        echo   [WARN] Task may already exist
    )
) else (
    echo   [SKIP] Audit script not found
)

REM 4. Create iteration task
echo [4/4] Creating iteration task...
if exist "%~dp009-projects\iteration\迭代引擎.ps1" (
    schtasks /create /tn "OpenClaw-Iteration" /tr "powershell -ExecutionPolicy Bypass -File \"%~dp009-projects\iteration\迭代引擎.ps1\"" /sc daily /st 02:00 /ru SYSTEM
    if %errorLevel% equ 0 (
        echo   [OK] Task created
    ) else (
        echo   [WARN] Task may already exist
    )
) else (
    echo   [SKIP] Iteration script not found
)

echo.
echo ========================================
echo Automation Setup Complete!
echo ========================================
echo.
echo Created tasks:
echo   • OpenClaw-AutoBackup    - Hourly backup
echo   • OpenClaw-SecurityCheck - Daily security check (09:00)
echo   • OpenClaw-WeeklyAudit   - Weekly audit (Sunday 04:00)
echo   • OpenClaw-Iteration     - Daily iteration (02:00)
echo.
echo Management commands:
echo   schtasks /query /tn "OpenClaw*"
echo   schtasks /run /tn "OpenClaw-AutoBackup"
echo   schtasks /delete /tn "OpenClaw-AutoBackup" /f
echo.
echo Test backup now:
echo   powershell -ExecutionPolicy Bypass -File "%~dp0upload-simple.ps1"
echo.
pause