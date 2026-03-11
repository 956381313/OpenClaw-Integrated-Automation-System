@echo off
echo ========================================
echo    OpenClaw GitHub 备份状态
echo ========================================
echo.

if exist "github-cloud-backup" (
    echo GitHub仓库存在
    echo.
    cd github-cloud-backup
    echo 最近提交:
    git log --oneline -5
    echo.
    echo 状态:
    git status --short
    cd ..
) else (
    echo GitHub仓库不存在
)

echo.
echo 在线查看: https://github.com/956381313/OpenClaw
echo 备份目录: simple-backups/
echo.
pause