@echo off
echo ========================================
echo    OpenClaw 仓库整理系统创建
echo ========================================
echo.

echo 1. 创建主目录...
if not exist "10-repository-organization" (
    mkdir "10-repository-organization"
    echo   创建: 10-repository-organization
)

echo.
echo 2. 创建模块目录...
cd "10-repository-organization"

mkdir "01-data-collection" 2>nul && echo   创建: 01-data-collection
mkdir "02-preprocessing" 2>nul && echo   创建: 02-preprocessing
mkdir "03-classification" 2>nul && echo   创建: 03-classification
mkdir "04-summarization" 2>nul && echo   创建: 04-summarization
mkdir "05-knowledge-base" 2>nul && echo   创建: 05-knowledge-base
mkdir "06-search-retrieval" 2>nul && echo   创建: 06-search-retrieval
mkdir "07-automation" 2>nul && echo   创建: 07-automation
mkdir "08-monitoring" 2>nul && echo   创建: 08-monitoring
mkdir "09-configuration" 2>nul && echo   创建: 09-configuration

cd ..

echo.
echo 3. 创建配置文件...
(
echo {
echo   "system": {
echo     "name": "OpenClaw Repository Organization System",
echo     "version": "1.0.0",
echo     "created": "%date% %time%"
echo   },
echo   "modules": {
echo     "data-collection": { "enabled": true },
echo     "preprocessing": { "enabled": true },
echo     "classification": { "enabled": true },
echo     "summarization": { "enabled": true },
echo     "knowledge-base": { "enabled": true },
echo     "search-retrieval": { "enabled": false },
echo     "automation": { "enabled": true },
echo     "monitoring": { "enabled": true }
echo   },
echo   "schedule": {
echo     "daily": "02:00",
echo     "weekly": "sunday 04:00"
echo   }
echo }
) > "10-repository-organization\09-configuration\system-config.json"

echo   配置文件: system-config.json

echo.
echo 4. 创建简单整理脚本...
(
echo @echo off
echo echo OpenClaw 简单整理脚本
echo echo 时间: %%date%% %%time%%
echo.
echo echo 扫描工作区文件...
echo dir /s /b "C:\Users\luchaochao\.openclaw\workspace\*.md" "C:\Users\luchaochao\.openclaw\workspace\*.ps1" "C:\Users\luchaochao\.openclaw\workspace\*.json" ^> file-list.txt 2^>nul
echo.
echo echo 生成分类报告...
echo (
echo # 文件分类报告
echo ## 生成时间: %%date%% %%time%%
echo ## 源目录: C:\Users\luchaochao\.openclaw\workspace
echo.
echo ## 文件类型统计
echo - .md 文件: Markdown文档
echo - .ps1 文件: PowerShell脚本
echo - .json 文件: 配置文件
echo - .bat 文件: 批处理脚本
echo.
echo ## 整理系统信息
echo - 系统目录: 10-repository-organization\
echo - 配置目录: 09-configuration\
echo - 知识库: 05-knowledge-base\
echo.
echo ## 下一步
echo 1. 查看文件列表: type file-list.txt
echo 2. 运行详细整理: 使用PowerShell脚本
echo 3. 配置自动化: 设置计划任务
echo.
echo ---
echo *OpenClaw 仓库整理系统*
echo ) ^> classification-report.txt
echo.
echo echo 整理完成!
echo echo 报告: classification-report.txt
echo echo 文件列表: file-list.txt
) > "simple-organize.bat"

echo   整理脚本: simple-organize.bat

echo.
echo 5. 创建管理脚本...
(
echo @echo off
echo echo ========================================
echo    OpenClaw 仓库整理管理
echo ========================================
echo.
echo if "%%1"=="" goto menu
echo if "%%1"=="run" goto run
echo if "%%1"=="status" goto status
echo if "%%1"=="config" goto config
echo.
echo :menu
echo echo 可用命令:
echo echo   run     - 运行整理
echo echo   status  - 查看状态
echo echo   config  - 查看配置
echo goto end
echo.
echo :run
echo echo 运行整理...
echo call simple-organize.bat
echo goto end
echo.
echo :status
echo echo 系统状态:
echo dir "10-repository-organization" /ad
echo type "10-repository-organization\09-configuration\system-config.json" 2^>nul
echo goto end
echo.
echo :config
echo echo 系统配置:
echo type "10-repository-organization\09-configuration\system-config.json" 2^>nul
echo goto end
echo.
echo :end
echo echo.
) > "manage-repo.bat"

echo   管理脚本: manage-repo.bat

echo.
echo ========================================
echo 仓库整理系统创建完成!
echo ========================================
echo.
echo 创建的内容:
echo - 目录结构: 10-repository-organization\ (9个模块)
echo - 配置文件: system-config.json
echo - 整理脚本: simple-organize.bat
echo - 管理脚本: manage-repo.bat
echo.
echo 使用方法:
echo   1. 运行整理: manage-repo.bat run
echo   2. 查看状态: manage-repo.bat status
echo   3. 查看配置: manage-repo.bat config
echo.
echo 下一步:
echo   1. 测试整理系统
echo   2. 配置自动化整理
echo   3. 扩展整理功能
echo.
pause