# 工作空间整理脚本

Write-Host "工作空间整理" -ForegroundColor Cyan
Write-Host "============"
Write-Host "开始时间: $(Get-Date -Format 'HH:mm:ss')"
Write-Host ""

# 当前目录
$workspace = Get-Location
Write-Host "工作空间: $workspace" -ForegroundColor Gray
Write-Host ""

# 1. 检查当前状态
Write-Host "1. 检查当前状态" -ForegroundColor Yellow
$allFiles = Get-ChildItem -File
$allDirs = Get-ChildItem -Directory
Write-Host "   文件总数: $($allFiles.Count)" -ForegroundColor Gray
Write-Host "   目录总数: $($allDirs.Count)" -ForegroundColor Gray
Write-Host ""

# 2. 标准目录结构
Write-Host "2. 确保标准目录结构" -ForegroundColor Yellow
$standardDirs = @(
    "docs",        # 文档文件
    "scripts",     # 脚本文件
    "config",      # 配置文件
    "data",        # 数据文件
    "temp",        # 临时文件
    "archive",     # 归档文件
    "logs",        # 日志文件
    "backup"       # 备份文件
)

$createdDirs = 0
foreach ($dir in $standardDirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Name $dir -Force | Out-Null
        Write-Host "   ✅ 创建: $dir/" -ForegroundColor Green
        $createdDirs++
    } else {
        Write-Host "   📁 已存在: $dir/" -ForegroundColor Gray
    }
}
Write-Host "   目录状态: $createdDirs 个新创建" -ForegroundColor Gray
Write-Host ""

# 3. 文件分类规则
Write-Host "3. 文件分类规则" -ForegroundColor Yellow
$classificationRules = @{
    # 文档文件
    "*.md" = "docs"
    "*.txt" = "docs"
    "*.docx" = "docs"
    "*.pdf" = "docs"
    "*.rtf" = "docs"
    
    # 脚本文件
    "*.ps1" = "scripts"
    "*.bat" = "scripts"
    "*.cmd" = "scripts"
    "*.sh" = "scripts"
    "*.py" = "scripts"
    "*.js" = "scripts"
    
    # 配置文件
    "*.json" = "config"
    "*.yaml" = "config"
    "*.yml" = "config"
    "*.xml" = "config"
    "*.ini" = "config"
    "*.cfg" = "config"
    
    # 数据文件
    "*.csv" = "data"
    "*.xlsx" = "data"
    "*.db" = "data"
    "*.sqlite" = "data"
    "*.dat" = "data"
    
    # 临时文件
    "*.tmp" = "temp"
    "*.temp" = "temp"
    "*.bak" = "temp"
    "*.log" = "temp"
    
    # 归档文件
    "*.zip" = "archive"
    "*.rar" = "archive"
    "*.7z" = "archive"
    "*.tar" = "archive"
    "*.gz" = "archive"
}

# 4. 分类文件
Write-Host "4. 分类文件" -ForegroundColor Yellow
$movedFiles = 0
$keptFiles = 0

foreach ($file in $allFiles) {
    $moved = $false
    
    foreach ($pattern in $classificationRules.Keys) {
        if ($file.Name -like $pattern) {
            $targetDir = $classificationRules[$pattern]
            $targetPath = Join-Path $targetDir $file.Name
            
            # 移动文件
            try {
                Move-Item -Path $file.FullName -Destination $targetPath -Force -ErrorAction Stop
                Write-Host "   📄 $($file.Name) → $targetDir/" -ForegroundColor DarkGray
                $movedFiles++
                $moved = $true
                break
            } catch {
                Write-Host "   ⚠️  $($file.Name) 移动失败: $_" -ForegroundColor Yellow
            }
        }
    }
    
    if (-not $moved) {
        # 未匹配的文件留在根目录
        Write-Host "   📄 $($file.Name) (保留在根目录)" -ForegroundColor Gray
        $keptFiles++
    }
}

Write-Host "   移动文件: $movedFiles 个" -ForegroundColor Gray
Write-Host "   保留文件: $keptFiles 个" -ForegroundColor Gray
Write-Host ""

# 5. 清理临时文件
Write-Host "5. 清理临时文件" -ForegroundColor Yellow
if (Test-Path "temp") {
    $tempFiles = Get-ChildItem -Path "temp" -File -ErrorAction SilentlyContinue
    if ($tempFiles.Count -gt 0) {
        $deletedCount = 0
        foreach ($tempFile in $tempFiles) {
            try {
                Remove-Item -Path $tempFile.FullName -Force -ErrorAction Stop
                $deletedCount++
            } catch {
                Write-Host "   ⚠️  无法删除: $($tempFile.Name)" -ForegroundColor Yellow
            }
        }
        Write-Host "   清理临时文件: $deletedCount 个" -ForegroundColor Green
    } else {
        Write-Host "   临时目录为空" -ForegroundColor Gray
    }
}
Write-Host ""

# 6. 显示整理结果
Write-Host "6. 整理结果" -ForegroundColor Yellow
Write-Host "   根目录文件:" -ForegroundColor Gray
Get-ChildItem -File | Select-Object Name, @{Name="大小(KB)";Expression={[math]::Round($_.Length/1KB,2)}} | Format-Table -AutoSize
Write-Host ""

Write-Host "   各目录文件统计:" -ForegroundColor Gray
foreach ($dir in $standardDirs) {
    if (Test-Path $dir) {
        $fileCount = (Get-ChildItem -Path $dir -File -ErrorAction SilentlyContinue).Count
        if ($fileCount -gt 0) {
            Write-Host "   $dir/: $fileCount 个文件" -ForegroundColor DarkGray
        }
    }
}
Write-Host ""

# 7. 生成整理报告
Write-Host "7. 整理报告" -ForegroundColor Yellow
$reportTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$totalClassified = 0

foreach ($dir in $standardDirs) {
    if (Test-Path $dir) {
        $fileCount = (Get-ChildItem -Path $dir -File -ErrorAction SilentlyContinue).Count
        $totalClassified += $fileCount
    }
}

$rootFiles = (Get-ChildItem -File).Count
$totalFiles = $rootFiles + $totalClassified

Write-Host "   整理时间: $reportTime" -ForegroundColor Gray
Write-Host "   文件总数: $totalFiles" -ForegroundColor Gray
Write-Host "   根目录文件: $rootFiles" -ForegroundColor Gray
Write-Host "   分类文件: $totalClassified" -ForegroundColor Gray
Write-Host "   整理比例: $([math]::Round(($totalClassified/$totalFiles)*100,1))%" -ForegroundColor Gray
Write-Host ""

Write-Host "=== 整理完成 ===" -ForegroundColor Green
Write-Host "完成时间: $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Gray
Write-Host "工作空间已整理完成！" -ForegroundColor Gray