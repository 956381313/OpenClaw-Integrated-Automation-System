@echo off
echo ========================================
echo    OpenClaw 自动化配置 (管理员)
echo ========================================
echo 时间: %date% %time%
echo.

REM 检查管理员权限
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo 错误: 需要管理员权限运行此脚本
    echo 请以管理员身份运行
    pause
    exit /b 1
)

echo 正在配置自动化任务...
echo.

REM 1. 创建每小时备份任务
echo [1/4] 创建每小时备份任务...
schtasks /create /tn "OpenClaw-AutoBackup" ^
  /tr "powershell -ExecutionPolicy Bypass -File \"C:\Users\luchaochao\.openclaw\workspace\upload-simple.ps1\"" ^
  /sc hourly /st 00:00 ^
  /ru SYSTEM

if %errorLevel% equ 0 (
    echo   ✅ 任务创建成功
) else (
    echo   ⚠️  任务创建失败 (可能已存在)
)

REM 2. 创建每日安全检查任务
echo [2/4] 创建每日安全检查任务...
schtasks /create /tn "OpenClaw-SecurityCheck" ^
  /tr "powershell -ExecutionPolicy Bypass -File \"C:\Users\luchaochao\.openclaw\workspace\09-projects\security-tools\daily_security_check.ps1\"" ^
  /sc daily /st 09:00 ^
  /ru SYSTEM

if %errorLevel% equ 0 (
    echo   ✅ 任务创建成功
) else (
    echo   ⚠️  任务创建失败 (可能已存在)
)

REM 3. 创建每周审计任务
echo [3/4] 创建每周审计任务...
schtasks /create /tn "OpenClaw-WeeklyAudit" ^
  /tr "powershell -ExecutionPolicy Bypass -File \"C:\Users\luchaochao\.openclaw\workspace\09-projects\security-tools\weekly_security_audit.ps1\"" ^
  /sc weekly /d SUN /st 04:00 ^
  /ru SYSTEM

if %errorLevel% equ 0 (
    echo   ✅ 任务创建成功
) else (
    echo   ⚠️  任务创建失败 (可能已存在)
)

REM 4. 创建迭代系统任务
echo [4/4] 创建迭代系统任务...
schtasks /create /tn "OpenClaw-Iteration" ^
  /tr "powershell -ExecutionPolicy Bypass -File \"C:\Users\luchaochao\.openclaw\workspace\09-projects\iteration\迭代引擎.ps1\"" ^
  /sc daily /st 02:00 ^
  /ru SYSTEM

if %errorLevel% equ 0 (
    echo   ✅ 任务创建成功
) else (
    echo   ⚠️  任务创建失败 (可能已存在)
)

echo.
echo ========================================
echo 自动化配置完成!
echo ========================================
echo.
echo 已创建的任务:
echo   • OpenClaw-AutoBackup    - 每小时备份
echo   • OpenClaw-SecurityCheck - 每日安全检查 (09:00)
echo   • OpenClaw-WeeklyAudit   - 每周安全审计 (周日 04:00)
echo   • OpenClaw-Iteration     - 每日迭代改进 (02:00)
echo.
echo 管理命令:
echo   schtasks /query /tn "OpenClaw*"
echo   schtasks /run /tn "OpenClaw-AutoBackup"
echo   schtasks /delete /tn "OpenClaw-AutoBackup" /f
echo.
echo 立即测试备份:
echo   powershell -ExecutionPolicy Bypass -File "C:\Users\luchaochao\.openclaw\workspace\upload-simple.ps1"
echo.
pause