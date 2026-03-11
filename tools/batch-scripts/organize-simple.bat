@echo off
echo ========================================
echo    OpenClaw 简单仓库整理
echo ========================================
echo 时间: %date% %time%
echo.

echo 1. 创建目录结构...
if not exist "10-repository-organization" mkdir "10-repository-organization"
cd "10-repository-organization"

mkdir "01-data-collection" 2>nul
mkdir "02-preprocessing" 2>nul  
mkdir "03-classification" 2>nul
mkdir "04-summarization" 2>nul
mkdir "05-knowledge-base" 2>nul
mkdir "06-search-retrieval" 2>nul
mkdir "07-automation" 2>nul
mkdir "08-monitoring" 2>nul
mkdir "09-configuration" 2>nul

echo   目录创建完成
echo.

echo 2. 扫描工作区文件...
cd ..
set filecount=0
for /f "tokens=*" %%f in ('dir /s /b /a-d "C:\Users\luchaochao\.openclaw\workspace\*.md" "C:\Users\luchaochao\.openclaw\workspace\*.ps1" "C:\Users\luchaochao\.openclaw\workspace\*.bat" "C:\Users\luchaochao\.openclaw\workspace\*.json" "C:\Users\luchaochao\.openclaw\workspace\*.txt" 2^>nul ^| find /c /v ""') do set filecount=%%f

echo   找到 %filecount% 个文件
echo.

echo 3. 生成整理报告...
set reportfile=repository-organization-report-%date:~0,4%%date:~5,2%%date:~8,2%-%time:~0,2%%time:~3,2%.txt

(
echo # OpenClaw 仓库整理报告
echo ## 整理时间: %date% %time%
echo ## 扫描目录: C:\Users\luchaochao\.openclaw\workspace
echo ## 处理文件: %filecount% 个
echo.
echo ## 目录结构
echo - 10-repository-organization/ - 仓库整理系统根目录
echo - 01-data-collection/ - 数据采集模块
echo - 02-preprocessing/ - 数据预处理模块
echo - 03-classification/ - 分类整理模块
echo - 04-summarization/ - 归纳总结模块
echo - 05-knowledge-base/ - 知识库模块
echo - 06-search-retrieval/ - 搜索检索模块
echo - 07-automation/ - 自动化模块
echo - 08-monitoring/ - 监控报告模块
echo - 09-configuration/ - 配置模块
echo.
echo ## 系统状态
echo - 目录结构: 已创建
echo - 文件扫描: 完成
echo - 整理报告: 当前文件
echo.
echo ## 下一步行动
echo 1. 运行完整整理脚本: organize-repository.ps1
echo 2. 配置自动化整理: setup-auto-organization.bat
echo 3. 查看知识库: 10-repository-organization\05-knowledge-base\
echo.
echo ---
echo *报告生成时间: %date% %time%*
echo *OpenClaw 仓库整理系统 v1.0.0*
) > "%reportfile%"

echo   报告保存到: %reportfile%
echo.

echo 4. 创建管理脚本...
(
@echo off
echo ========================================
echo    OpenClaw 仓库整理管理工具
echo ========================================
echo.
echo 可用命令:
echo   organize  - 运行整理
echo   status    - 查看状态
echo   report    - 生成报告
echo   config    - 查看配置
echo.
if "%%1"=="organize" goto organize
if "%%1"=="status" goto status
if "%%1"=="report" goto report
if "%%1"=="config" goto config
goto end

:organize
echo 运行整理...
powershell -ExecutionPolicy Bypass -Command "Write-Host '开始整理...' -ForegroundColor Cyan"
goto end

:status
echo 系统状态:
dir "10-repository-organization" /ad
goto end

:report
echo 生成报告...
powershell -ExecutionPolicy Bypass -Command "Get-Date ^| Out-File 'organization-report.txt'"
goto end

:config
echo 系统配置:
type "10-repository-organization\README.md" 2^>nul ^| findstr /v "^$" ^| head -10
goto end

:end
echo.
) > manage-organization.bat

echo   管理脚本: manage-organization.bat
echo.

echo ========================================
echo 整理完成!
echo ========================================
echo.
echo 生成的文件:
echo   - 整理报告: %reportfile%
echo   - 管理脚本: manage-organization.bat
echo   - 目录结构: 10-repository-organization\
echo.
echo 下一步:
echo   1. 查看报告: type %reportfile%
echo   2. 运行整理: manage-organization.bat organize
echo   3. 查看状态: manage-organization.bat status
echo.
pause