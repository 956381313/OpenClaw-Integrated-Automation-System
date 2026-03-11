@echo off
echo ================================================
echo     OpenClaw Task Setup (Fixed)
echo ================================================
echo.
echo This will create a scheduled task for duplicate file cleanup.
echo.
echo Task will run every Sunday at 03:00 automatically.
echo.
echo Press any key to start setup...
pause >nul

echo.
echo Starting PowerShell as Administrator...
echo.

REM Run PowerShell as Administrator to create scheduled task
PowerShell -Command "Start-Process PowerShell -Verb RunAs -ArgumentList '-ExecutionPolicy Bypass -Command \"cd C:\Users\luchaochao\.openclaw\workspace; $TaskName = \'OpenClaw-Duplicate-Cleanup\'; $Action = New-ScheduledTaskAction -Execute \'powershell.exe\' -Argument \'-ExecutionPolicy Bypass -File \"clean-duplicates-optimized.ps1\" -Strategy KeepNewest\' -WorkingDirectory \'C:\Users\luchaochao\.openclaw\workspace\'; $Trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At \'03:00\'; $Principal = New-ScheduledTaskPrincipal -UserId \'SYSTEM\' -LogonType ServiceAccount -RunLevel Highest; $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable; Register-ScheduledTask -TaskName $TaskName -Description \'OpenClaw Duplicate File Cleanup - Weekly automatic cleanup\' -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Force; Enable-ScheduledTask -TaskName $TaskName; Write-Host \'Task created successfully!\' -ForegroundColor Green; Write-Host \'Task name: \' $TaskName; Write-Host \'Schedule: Every Sunday at 03:00\'; Write-Host \'Script: clean-duplicates-optimized.ps1 -Strategy KeepNewest\'; Write-Host \'Run as: SYSTEM (Highest privileges)\'; Write-Host \'\'; Write-Host \'Press any key to exit...\'; pause\"'"

echo.
echo Setup command sent to Administrator PowerShell.
echo Please check the new window for setup results.
echo.
echo Press any key to exit this window...
pause >nul