@echo off
echo ========================================
echo    OpenClaw 自动化系统测试
echo ========================================
echo 时间: %date% %time%
echo.

echo 1. 检查OpenClaw目录...
if exist "C:\Users\luchaochao\.openclaw" (
    echo   [OK] 目录存在
) else (
    echo   [ERROR] 目录不存在
)

echo.
echo 2. 检查核心文件...
if exist "C:\Users\luchaochao\.openclaw\openclaw.json" (
    echo   [OK] openclaw.json
) else (
    echo   [ERROR] openclaw.json
)

if exist "C:\Users\luchaochao\.openclaw\gateway.cmd" (
    echo   [OK] gateway.cmd
) else (
    echo   [ERROR] gateway.cmd
)

if exist "C:\Users\luchaochao\.openclaw\update-check.json" (
    echo   [OK] update-check.json
) else (
    echo   [ERROR] update-check.json
)

echo.
echo 3. 检查工作区文件...
if exist "C:\Users\luchaochao\.openclaw\workspace\AGENTS.md" (
    echo   [OK] AGENTS.md
) else (
    echo   [ERROR] AGENTS.md
)

if exist "C:\Users\luchaochao\.openclaw\workspace\SOUL.md" (
    echo   [OK] SOUL.md
) else (
    echo   [ERROR] SOUL.md
)

echo.
echo 4. 检查GitHub仓库...
if exist "github-cloud-backup" (
    echo   [OK] GitHub仓库存在
) else (
    echo   [WARNING] GitHub仓库不存在
)

echo.
echo 5. 检查备份脚本...
if exist "upload-simple.ps1" (
    echo   [OK] upload-simple.ps1
) else (
    echo   [ERROR] upload-simple.ps1
)

if exist "setup-automation-admin.bat" (
    echo   [OK] setup-automation-admin.bat
) else (
    echo   [ERROR] setup-automation-admin.bat
)

echo.
echo ========================================
echo 测试完成!
echo ========================================
echo.
echo 下一步:
echo   1. 运行备份测试: upload-simple.ps1
echo   2. 配置自动化: setup-automation-admin.bat (需要管理员)
echo   3. 检查GitHub: https://github.com/956381313/OpenClaw
echo.
pause