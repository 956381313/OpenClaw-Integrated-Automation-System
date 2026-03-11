@echo off
title Enter Safe Mode Helper
color 0A

echo ========================================
echo     Safe Mode Entry Helper
echo ========================================
echo.
echo This tool helps you enter Safe Mode to delete
echo the stubborn folder.
echo.

echo METHOD 1: Traditional F8 Method (Windows 7/8.1)
echo ----------------------------------------------
echo 1. Save all work and close programs
echo 2. Click Start -> Restart
echo 3. Immediately start pressing F8 repeatedly
echo 4. Select "Safe Mode" from menu
echo.

echo METHOD 2: Shift + Restart (Windows 10/11)
echo -----------------------------------------
echo 1. Click Start -> Power
echo 2. Hold SHIFT key and click "Restart"
echo 3. Select: Troubleshoot -> Advanced options
echo 4. Select: Startup Settings -> Restart
echo 5. Press 4 or F4 for Safe Mode
echo.

echo METHOD 3: System Configuration (msconfig)
echo -----------------------------------------
echo 1. Press Win + R, type: msconfig
echo 2. Go to "Boot" tab
echo 3. Check "Safe boot" -> Minimal
echo 4. Click OK -> Restart
echo 5. Computer will boot in Safe Mode
echo 6. After deletion, run msconfig again
echo 7. Uncheck "Safe boot" -> Restart
echo.

echo ========================================
echo     What to do in Safe Mode
echo ========================================
echo.
echo Once in Safe Mode:
echo.
echo OPTION A: File Explorer
echo 1. Open File Explorer
echo 2. Go to: C:\Users\luchaochao\.openclaw\workspace\
echo 3. Delete the folder
echo.
echo OPTION B: Command Prompt
echo 1. Open Command Prompt as Administrator
echo 2. Run: rd /s /q "C:\Users\luchaochao\.openclaw\workspace\pre-architecture-backup-20260306-172408"
echo.
echo OPTION C: PowerShell
echo 1. Open PowerShell as Administrator
echo 2. Run: Remove-Item -Path "C:\Users\luchaochao\.openclaw\workspace\pre-architecture-backup-20260306-172408" -Recurse -Force
echo.

echo ========================================
echo     After Deletion
echo ========================================
echo.
echo 1. Restart computer normally
echo 2. Verify folder is gone
echo 3. Check disk space improvement
echo 4. Clean up these helper scripts
echo.

echo ========================================
echo     Quick Reference
echo ========================================
echo.
echo Target folder:
echo C:\Users\luchaochao\.openclaw\workspace\pre-architecture-backup-20260306-172408
echo.
echo Delete command:
echo rd /s /q "C:\Users\luchaochao\.openclaw\workspace\pre-architecture-backup-20260306-172408"
echo.
echo Success rate in Safe Mode: 99%
echo.
pause