@echo off
title Setup Auto Delete on Startup
color 0A

echo ========================================
echo     Setup Auto Delete on Startup
echo ========================================
echo.

echo Step 1: Check target folder...
set "TARGET=C:\Users\luchaochao\.openclaw\workspace\pre-architecture-backup-20260306-172408"

if exist "%TARGET%" (
    echo   [EXISTS] pre-architecture-backup-20260306-172408
) else (
    echo   [NOT FOUND] Folder already deleted
    goto :cleanup
)

echo.
echo Step 2: Create startup entry...
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "SCRIPT=C:\Users\luchaochao\.openclaw\workspace\auto-delete-on-startup.ps1"
set "STARTUP_BAT=%STARTUP%\delete-on-login.bat"

echo Creating startup batch file...
(
echo @echo off
echo echo Running auto delete on startup...
echo timeout /t 10 /nobreak ^>nul
echo powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File "%SCRIPT%"
echo timeout /t 5 /nobreak ^>nul
echo del "%%~f0"
) > "%STARTUP_BAT%"

if exist "%STARTUP_BAT%" (
    echo   [SUCCESS] Startup entry created
) else (
    echo   [FAILED] Cannot create startup entry
)

echo.
echo Step 3: Create manual run script...
set "RUN_SCRIPT=C:\Users\luchaochao\.openclaw\workspace\run-auto-delete.bat"

(
echo @echo off
echo echo Running auto delete script...
echo echo.
echo powershell -ExecutionPolicy Bypass -File "%SCRIPT%"
echo echo.
echo pause
) > "%RUN_SCRIPT%"

echo   [SUCCESS] Manual run script created: run-auto-delete.bat

:cleanup
echo.
echo Step 4: Clean up old scripts...
del "C:\Users\luchaochao\.openclaw\workspace\delete-*.bat" 2>nul
del "C:\Users\luchaochao\.openclaw\workspace\fix-*.bat" 2>nul
del "C:\Users\luchaochao\.openclaw\workspace\run-*.bat" 2>nul
echo   Old scripts cleaned up

echo.
echo ========================================
echo     Setup Complete!
echo ========================================
echo.
echo Instructions:
echo 1. Restart your computer (recommended)
echo    - Script will run automatically after login
echo.
echo 2. Or run manually now:
echo    - Double click: run-auto-delete.bat
echo.
echo 3. Check results:
echo    - View log file: delete-log.txt
echo    - Check if folder is deleted
echo.
echo Note: Startup entry will delete itself after running.
echo.
pause