@echo off
chcp 65001 >nul
echo ========================================
echo OpenClaw Organize and Cleanup System
echo ========================================
echo.
echo Starting combined repository organization and cleanup...
echo.

powershell -ExecutionPolicy Bypass -File "organize-and-cleanup.ps1"

echo.
echo ========================================
echo Execution completed
echo ========================================
echo.
pause