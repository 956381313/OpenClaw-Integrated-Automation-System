@echo off
echo ========================================
echo 重启 OpenClaw 服务
echo ========================================
echo.

echo 1. 停止 OpenClaw 服务...
openclaw gateway stop
timeout /t 3 /nobreak >nul

echo.
echo 2. 启动 OpenClaw 服务...
openclaw gateway start
timeout /t 5 /nobreak >nul

echo.
echo 3. 检查服务状态...
openclaw gateway status

echo.
echo ========================================
echo 重启完成！
echo 现在可以测试 NVIDIA 模型了
echo ========================================
pause