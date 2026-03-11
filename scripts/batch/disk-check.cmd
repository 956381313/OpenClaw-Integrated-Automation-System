@echo off
chcp 65001 >nul
echo ========================================
echo   磁盘状态检查工具
echo ========================================
echo.

REM 获取磁盘信息
for /f "tokens=3" %%a in ('wmic logicaldisk where "DeviceID='C:'" get Size /value ^| find "="') do set totalBytes=%%a
for /f "tokens=3" %%a in ('wmic logicaldisk where "DeviceID='C:'" get FreeSpace /value ^| find "="') do set freeBytes=%%a

REM 计算GB
set /a totalGB=%totalBytes%/1073741824
set /a freeGB=%freeBytes%/1073741824
set /a usedGB=%totalGB%-%freeGB%

REM 计算百分比
set /a usagePercent=%usedGB%*100/%totalGB%

echo 磁盘 C: 信息:
echo   总容量: %totalGB% GB
echo   已使用: %usedGB% GB
echo   可用空间: %freeGB% GB
echo   使用率: %usagePercent%%%
echo.

if %usagePercent% GTR 85 (
    echo ⚠️ 警告: 磁盘使用率超过 85%!
    echo   建议清理临时文件
    echo.
    echo 运行清理命令:
    echo   del /q "C:\Users\luchaochao\.openclaw\workspace\*.tmp"
    echo   del /q "C:\Users\luchaochao\.openclaw\workspace\*.temp"
    echo   del /q "C:\Users\luchaochao\.openclaw\workspace\temp\*"
) else (
    echo ✅ 状态正常: 磁盘使用率在安全范围内
)

echo.
echo ========================================
pause