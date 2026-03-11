@echo off
title 设置重启后自动删除工具
color 0A

echo ========================================
echo     重启后自动删除工具设置
echo ========================================
echo.

echo 步骤1: 检查文件夹状态...
if exist "C:\Users\luchaochao\.openclaw\workspace\english-reorg-backup-20260306-234623" (
    echo   [存在] english-reorg-backup-20260306-234623
) else (
    echo   [不存在] english-reorg-backup-20260306-234623
)

if exist "C:\Users\luchaochao\.openclaw\workspace\pre-architecture-backup-20260306-172408" (
    echo   [存在] pre-architecture-backup-20260306-172408
) else (
    echo   [不存在] pre-architecture-backup-20260306-172408
)

echo.
echo 步骤2: 创建启动项...
set "STARTUP_FOLDER=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "SCRIPT_PATH=C:\Users\luchaochao\.openclaw\workspace\delete-after-reboot.ps1"
set "BATCH_FILE=%STARTUP_FOLDER%\delete-backups-on-startup.bat"

echo 创建启动批处理文件...
(
echo @echo off
echo echo 正在删除顽固备份文件夹...
echo timeout /t 5 /nobreak ^>nul
echo powershell -ExecutionPolicy Bypass -File "%SCRIPT_PATH%"
echo timeout /t 10 /nobreak ^>nul
echo del "%%~f0"
) > "%BATCH_FILE%"

if exist "%BATCH_FILE%" (
    echo   [成功] 启动项已创建
    echo   位置: %BATCH_FILE%
) else (
    echo   [失败] 无法创建启动项
)

echo.
echo 步骤3: 创建桌面快捷方式（可选）...
set "DESKTOP=%USERPROFILE%\Desktop"
set "SHORTCUT=%DESKTOP%\删除顽固文件夹.lnk"

(
echo Set oWS = WScript.CreateObject("WScript.Shell")
echo sLinkFile = "%SHORTCUT%"
echo Set oLink = oWS.CreateShortcut(sLinkFile)
echo oLink.TargetPath = "powershell.exe"
echo oLink.Arguments = "-ExecutionPolicy Bypass -File ""%SCRIPT_PATH%"""
echo oLink.Description = "删除顽固备份文件夹"
echo oLink.Save
) > "%TEMP%\create_shortcut.vbs"

cscript //nologo "%TEMP%\create_shortcut.vbs"
del "%TEMP%\create_shortcut.vbs"

if exist "%SHORTCUT%" (
    echo   [成功] 桌面快捷方式已创建
) else (
    echo   [可选] 桌面快捷方式创建失败（不影响主要功能）
)

echo.
echo 步骤4: 创建手动运行脚本...
set "MANUAL_SCRIPT=C:\Users\luchaochao\.openclaw\workspace\run-delete-now.bat"

(
echo @echo off
echo echo 立即运行删除脚本...
echo echo.
echo powershell -ExecutionPolicy Bypass -File "%SCRIPT_PATH%"
echo pause
) > "%MANUAL_SCRIPT%"

echo   [成功] 手动运行脚本已创建: run-delete-now.bat

echo.
echo ========================================
echo     设置完成！
echo ========================================
echo.
echo 使用方法:
echo 1. 重启电脑（推荐）
echo     - 登录后会自动运行删除脚本
echo.
echo 2. 立即运行
echo     - 双击运行: run-delete-now.bat
echo     - 或双击桌面快捷方式
echo.
echo 3. 检查结果
echo     - 查看脚本输出
echo     - 检查文件夹是否被删除
echo.
echo 注意:
echo - 重启后立即运行效果最好
echo - 如果仍然失败，可能需要进入安全模式
echo.
pause