@echo off
echo ========================================
echo   EMERGENCY DISK CLEANUP
echo ========================================
echo.
echo Current disk status:
echo   C: 99.3%% (CRITICAL)
echo   E: 93.91%% (CRITICAL) 
echo   F: 94.84%% (CRITICAL)
echo   G: 95.22%% (CRITICAL)
echo   D: 21.3%% (OK)
echo.
echo Options:
echo   1. Preview cleanup (safe, no deletion)
echo   2. Execute emergency cleanup
echo   3. Custom drives cleanup
echo   4. Exit
echo.

set /p choice="Enter choice (1-4): "

cd /d "%~dp0"

if "%choice%"=="1" (
    echo Running in PREVIEW mode...
    powershell -ExecutionPolicy Bypass -File "tool-collections\powershell-scripts\emergency-disk-cleanup.ps1" -Preview
) else if "%choice%"=="2" (
    echo WARNING: This will delete temporary files!
    set /p confirm="Type 'YES' to confirm: "
    if "%confirm%"=="YES" (
        echo Executing emergency cleanup...
        powershell -ExecutionPolicy Bypass -File "tool-collections\powershell-scripts\emergency-disk-cleanup.ps1" -Force
    ) else (
        echo Cleanup cancelled.
    )
) else if "%choice%"=="3" (
    echo Enter drives to clean (e.g., C:,E:)
    set /p drives="Drives: "
    echo.
    echo Options for drives %drives%:
    echo   1. Preview
    echo   2. Execute
    set /p subchoice="Choice: "
    
    if "%subchoice%"=="1" (
        powershell -ExecutionPolicy Bypass -File "tool-collections\powershell-scripts\emergency-disk-cleanup.ps1" -Drives %drives% -Preview
    ) else if "%subchoice%"=="2" (
        echo WARNING: This will delete temporary files on %drives%!
        set /p confirm="Type 'YES' to confirm: "
        if "%confirm%"=="YES" (
            powershell -ExecutionPolicy Bypass -File "tool-collections\powershell-scripts\emergency-disk-cleanup.ps1" -Drives %drives% -Force
        ) else (
            echo Cleanup cancelled.
        )
    )
) else (
    echo Exiting.
)

echo.
pause