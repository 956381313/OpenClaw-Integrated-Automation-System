@echo off
title ULTIMATE FOLDER DELETE TOOL
color 0C
echo ========================================
echo    ULTIMATE FOLDER DELETE TOOL
echo ========================================
echo.
echo This tool will forcefully delete stubborn folders.
echo.

set "FOLDER1=C:\Users\luchaochao\.openclaw\workspace\english-reorg-backup-20260306-234623"
set "FOLDER2=C:\Users\luchaochao\.openclaw\workspace\pre-architecture-backup-20260306-172408"

echo Step 1: Taking ownership of folders...
takeown /f "%FOLDER1%" /r /d y >nul 2>&1
takeown /f "%FOLDER2%" /r /d y >nul 2>&1
echo   Ownership taken.

echo.
echo Step 2: Granting full permissions...
icacls "%FOLDER1%" /grant administrators:F /t /c /q >nul 2>&1
icacls "%FOLDER2%" /grant administrators:F /t /c /q >nul 2>&1
echo   Permissions granted.

echo.
echo Step 3: Using robocopy to empty folders...
echo   Creating empty directory...
md "C:\temp_empty_%random%" >nul 2>&1

echo   Emptying folder 1...
robocopy "C:\temp_empty_%random%" "%FOLDER1%" /MIR /NJH /NJS /NP /NDL /NS /NC >nul 2>&1

echo   Emptying folder 2...
robocopy "C:\temp_empty_%random%" "%FOLDER2%" /MIR /NJH /NJS /NP /NDL /NS /NC >nul 2>&1

echo   Cleaning up empty directory...
rd /s /q "C:\temp_empty_%random%" >nul 2>&1

echo.
echo Step 4: Force deleting folders...
echo   Deleting folder 1...
rd /s /q "%FOLDER1%" >nul 2>&1
if exist "%FOLDER1%" (
    echo   [WARNING] Folder 1 still exists, trying alternative method...
    del /f /q /s "%FOLDER1%\*" >nul 2>&1
    rd /s /q "%FOLDER1%" >nul 2>&1
)

echo   Deleting folder 2...
rd /s /q "%FOLDER2%" >nul 2>&1
if exist "%FOLDER2%" (
    echo   [WARNING] Folder 2 still exists, trying alternative method...
    del /f /q /s "%FOLDER2%\*" >nul 2>&1
    rd /s /q "%FOLDER2%" >nul 2>&1
)

echo.
echo Step 5: Verifying deletion...
if not exist "%FOLDER1%" (
    echo   [SUCCESS] english-reorg-backup-20260306-234623 DELETED
) else (
    echo   [FAILED] english-reorg-backup-20260306-234623 STILL EXISTS
)

if not exist "%FOLDER2%" (
    echo   [SUCCESS] pre-architecture-backup-20260306-172408 DELETED
) else (
    echo   [FAILED] pre-architecture-backup-20260306-172408 STILL EXISTS
)

echo.
echo ========================================
echo    PROCESS COMPLETE
echo ========================================
echo.
echo If folders still exist, you may need to:
echo 1. Restart your computer and try again
echo 2. Use Unlocker tool (third-party)
echo 3. Boot from USB and delete from another OS
echo.
pause