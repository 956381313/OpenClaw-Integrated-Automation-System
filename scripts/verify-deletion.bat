@echo off
title Verify Deletion Results
color 0F

echo ========================================
echo     Verify Deletion Results
echo ========================================
echo.
echo Checking if stubborn folder was deleted...
echo.

set "FOLDER=C:\Users\luchaochao\.openclaw\workspace\pre-architecture-backup-20260306-172408"

if exist "%FOLDER%" (
    echo ❌ FAILED: Folder still exists
    echo.
    echo Location: %FOLDER%
    echo.
    echo Recommendations:
    echo 1. Enter Safe Mode and delete
    echo 2. Use Unlocker tool
    echo 3. Try 7-Zip file manager
) else (
    echo ✅ SUCCESS: Folder deleted!
    echo.
    echo All backup folders have been removed!
    echo.
    echo Disk space should be improved.
)

echo.
echo ========================================
echo     Current Workspace Status
echo ========================================
echo.
echo Checking workspace for backup folders...
dir "C:\Users\luchaochao\.openclaw\workspace\*backup*" /ad

echo.
echo ========================================
echo     Disk Space Status
echo ========================================
echo.
for /f "tokens=3" %%a in ('wmic logicaldisk where "DeviceID='C:'" get FreeSpace /value') do set "free=%%a"
set /a freeGB=%free%/1073741824
echo C: Drive Free Space: %freeGB% GB

echo.
echo ========================================
echo     Cleanup Recommendations
echo ========================================
echo.
echo After successful deletion:
echo 1. Delete these helper scripts
echo 2. Check workspace organization
echo 3. Consider regular maintenance
echo.
pause