@echo off
echo ========================================
echo    OpenClaw 一键自动化配置
echo ========================================
echo.

echo 正在检查管理员权限...
net session >nul 2>&1
if errorlevel 1 (
    echo.
    echo 错误: 需要管理员权限
    echo.
    echo 请按以下步骤操作:
    echo 1. 右键点击此文件
    echo 2. 选择"以管理员身份运行"
    echo.
    pause
    exit /b 1
)

echo 管理员权限确认!
echo.

echo 选项:
echo 1. 配置自动化任务 (推荐)
echo 2. 仅测试备份脚本
echo 3. 查看现有任务
echo 4. 退出
echo.
set /p choice=请选择 (1-4): 

if "%choice%"=="1" goto setup
if "%choice%"=="2" goto test
if "%choice%"=="3" goto view
if "%choice%"=="4" goto exit

:setup
echo.
echo 正在配置自动化任务...
echo.
powershell -ExecutionPolicy Bypass -File "setup-auto.ps1"
goto exit

:test
echo.
echo 测试备份脚本...
echo.
powershell -ExecutionPolicy Bypass -File "upload-simple.ps1"
goto exit

:view
echo.
echo 现有OpenClaw任务:
echo.
schtasks /query /tn "OpenClaw*" /fo list
echo.
pause
goto exit

:exit
echo.
echo 完成!
echo.
echo 查看详细指南: AUTO-SETUP-GUIDE.txt
echo.
pause