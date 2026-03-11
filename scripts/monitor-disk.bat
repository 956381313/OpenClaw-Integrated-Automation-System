@echo off
echo Disk Space Monitor - %DATE% %TIME%
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "tool-collections\powershell-scripts\monitor-disk-space.ps1"
pause
