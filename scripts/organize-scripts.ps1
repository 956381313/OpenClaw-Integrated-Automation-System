# 脚本整理工具
Write-Host "=== 脚本整理工具 ===" -ForegroundColor Cyan
Write-Host "开始时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host ""

# 1. 创建归档目录
$archiveRoot = "C:\Users\luchaochao\.openclaw\workspace\scripts-archive"
if (-not (Test-Path $archiveRoot)) {
    New-Item -ItemType Directory -Path $archiveRoot -Force | Out-Null
    Write-Host "✅ 创建归档目录: $archiveRoot" -ForegroundColor Green
}

# 2. 创建分类目录
$categories = @{
    "cleanup" = "清理脚本"
    "monitoring" = "监控脚本" 
    "backup" = "备份脚本"
    "maintenance" = "维护脚本"
    "temporary" = "临时脚本"
    "testing" = "测试脚本"
}

foreach ($cat in $categories.Keys) {
    $dir = Join-Path $archiveRoot $cat
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "✅ 创建分类目录: $cat" -ForegroundColor Gray
    }
}

Write-Host ""

# 3. 获取所有脚本
$scripts = Get-ChildItem -Path "C:\Users\luchaochao\.openclaw\workspace" -Filter "*.ps1" -File
Write-Host "发现 $($scripts.Count) 个脚本文件" -ForegroundColor Yellow

# 4. 定义保留的核心脚本
$keepScripts = @(
    "final-comprehensive-test.ps1",
    "fix-automation-test.ps1", 
    "full-automation-test.ps1",
    "simple-automation-test.ps1",
    "system-test.ps1",
    "integrate-english-automation.ps1",
    "list-skills.ps1",
    "setup-monthly-maintenance.ps1",
    "setup-weekly-cleanup.ps1",
    "update-automation-config.ps1"
)

# 5. 分类关键词
$keywords = @{
    "cleanup" = @("cleanup", "clean", "delete", "remove", "purge")
    "monitoring" = @("monitor", "check", "status", "progress", "disk")
    "backup" = @("backup", "restore", "archive", "recovery")
    "maintenance" = @("maintenance", "organize", "optimize", "setup", "monthly", "weekly")
    "testing" = @("test", "verify", "validate")
    "temporary" = @("temp", "emergency", "quick", "simple", "immediate", "execute", "run", "demo")
}

# 6. 开始整理
$movedCount = 0
$keptCount = 0

foreach ($script in $scripts) {
    $scriptName = $script.Name
    
    # 检查是否保留
    if ($keepScripts -contains $scriptName) {
        Write-Host "🔒 保留: $scriptName" -ForegroundColor Blue
        $keptCount++
        continue
    }
    
    # 分类
    $moved = $false
    foreach ($cat in $keywords.Keys) {
        foreach ($keyword in $keywords[$cat]) {
            if ($scriptName -match $keyword) {
                $targetDir = Join-Path $archiveRoot $cat
                Move-Item -Path $script.FullName -Destination $targetDir -Force
                Write-Host "📦 归档到 $cat: $scriptName" -ForegroundColor Gray
                $movedCount++
                $moved = $true
                break
            }
        }
        if ($moved) { break }
    }
    
    # 未分类的放到临时
    if (-not $moved) {
        $targetDir = Join-Path $archiveRoot "temporary"
        Move-Item -Path $script.FullName -Destination $targetDir -Force
        Write-Host "📦 归档到临时: $scriptName" -ForegroundColor Gray
        $movedCount++
    }
}

Write-Host ""
Write-Host "=== 整理结果 ===" -ForegroundColor Green
Write-Host "📦 归档脚本: $movedCount 个" -ForegroundColor Cyan
Write-Host "🔒 保留脚本: $keptCount 个" -ForegroundColor Blue
Write-Host "📁 归档位置: $archiveRoot" -ForegroundColor Gray

# 7. 创建索引
Write-Host ""
Write-Host "创建索引文件..." -ForegroundColor Yellow

$indexContent = @"
# 脚本归档索引

## 基本信息
- 归档时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
- 总脚本数: $($scripts.Count)
- 归档脚本: $movedCount
- 保留脚本: $keptCount

## 目录结构
"@

foreach ($cat in $categories.Keys) {
    $dir = Join-Path $archiveRoot $cat
    $files = Get-ChildItem -Path $dir -File
    $fileCount = $files.Count
    $indexContent += "`n### $($categories[$cat]) ($fileCount 个文件)`n"
    
    if ($fileCount -eq 0) {
        $indexContent += "- (空)`n"
    } else {
        foreach ($file in $files | Sort-Object Name) {
            $sizeKB = [math]::Round($file.Length / 1KB, 2)
            $indexContent += "- `$file.Name` ($sizeKB KB)`n"
        }
    }
}

$indexContent += @"

## 保留的核心脚本
"@

foreach ($script in $keepScripts) {
    $path = "C:\Users\luchaochao\.openclaw\workspace\$script"
    if (Test-Path $path) {
        $size = (Get-Item $path).Length
        $sizeKB = [math]::Round($size / 1KB, 2)
        $indexContent += "- `$script` ($sizeKB KB)`n"
    }
}

$indexContent += @"

---
*自动生成于 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')*
"@

$indexContent | Out-File -FilePath "$archiveRoot\README.md" -Encoding UTF8
Write-Host "✅ 索引文件已创建: $archiveRoot\README.md" -ForegroundColor Green

Write-Host ""
Write-Host "=== 完成 ===" -ForegroundColor Green
Write-Host "脚本整理工作已完成！" -ForegroundColor Cyan