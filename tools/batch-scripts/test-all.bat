@echo off
chcp 65001 >nul
echo ========================================
echo    OpenClaw Complete Test
echo ========================================
echo Time: %date% %time%
echo.

echo [TEST 1/4] Testing backup script...
echo.
call :runTest "upload-simple.ps1" "Backup Script"

echo.
echo [TEST 2/4] Testing security check...
echo.
call :runTest "09-projects\security-tools\security-check-fixed.ps1" "Security Check"

echo.
echo [TEST 3/4] Testing automation setup...
echo.
if exist "fix-automation.bat" (
    echo Found automation setup script
) else (
    echo ERROR: Automation setup script not found
)

echo.
echo [TEST 4/4] Testing GitHub repository...
echo.
if exist "github-cloud-backup" (
    echo Found GitHub repository
    cd github-cloud-backup
    git status --short
    cd ..
) else (
    echo WARNING: GitHub repository not found
)

echo.
echo ========================================
echo Test Complete!
echo ========================================
echo.
echo Next steps:
echo   1. Run backup: upload-simple.ps1
echo   2. Setup automation: fix-automation.bat (as Admin)
echo   3. Manage tasks: manage-automation.bat
echo.
pause
goto :eof

:runTest
echo Testing: %~2
if exist "%~1" (
    powershell -ExecutionPolicy Bypass -File "%~1"
    echo [OK] %~2 test completed
) else (
    echo [ERROR] Script not found: %~1
)
exit /b 0