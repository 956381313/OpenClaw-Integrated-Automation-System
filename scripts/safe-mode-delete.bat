@echo off
title Safe Mode Delete Instructions
color 0E

echo ========================================
echo     Safe Mode Delete Instructions
echo ========================================
echo.
echo TARGET FOLDER:
echo C:\Users\luchaochao\.openclaw\workspace\pre-architecture-backup-20260306-172408
echo.
echo This folder is extremely stubborn and requires
echo Safe Mode for deletion.
echo.

echo STEP 1: Enter Safe Mode
echo -----------------------
echo 1. Restart your computer
echo 2. Press F8 repeatedly during boot
echo 3. Select "Safe Mode"
echo.

echo STEP 2: Delete in Safe Mode
echo ---------------------------
echo In Safe Mode:
echo 1. Open File Explorer
echo 2. Navigate to:
echo    C:\Users\luchaochao\.openclaw\workspace\
echo 3. Right-click the folder:
echo    pre-architecture-backup-20260306-172408
echo 4. Select "Delete"
echo.

echo STEP 3: Alternative Command Line
echo --------------------------------
echo If File Explorer doesn't work:
echo 1. In Safe Mode, open Command Prompt
echo 2. Run:
echo    rd /s /q "C:\Users\luchaochao\.openclaw\workspace\pre-architecture-backup-20260306-172408"
echo.

echo STEP 4: Restart Normally
echo ------------------------
echo After deletion:
echo 1. Restart computer normally
echo 2. Verify folder is gone
echo.

echo ========================================
echo     Why Safe Mode Works
echo ========================================
echo.
echo Safe Mode loads minimal drivers and services.
echo This prevents:
echo - File locking by other processes
echo - Permission conflicts
echo - System protection mechanisms
echo.

echo ========================================
echo     Notes
echo ========================================
echo.
echo - Safe Mode is 99% effective for stubborn folders
echo - If still fails, use Unlocker tool
echo - This is the final solution
echo.
pause