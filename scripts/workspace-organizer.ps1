# 工作空间整理工具
param(
    [switch]$Cleanup,
    [switch]$Analyze,
    [switch]$Organize,
    [switch]$All
)

if ($All) {
    $Cleanup = $true
    $Analyze = $true
    $Organize = $true
}

if (-not ($Cleanup -or $Analyze -or $Organize)) {
    Write-Host "使用方法:"
    Write-Host "  .\workspace-organizer.ps1 -Cleanup    # 清理无效文件"
    Write-Host "  .\workspace-organizer.ps1 -Analyze    # 分析工作空间"
    Write-Host "  .\workspace-organizer.ps1 -Organize   # 整理目录结构"
    Write-Host "  .\workspace-organizer.ps1 -All        # 执行所有操作"
    exit
}

Write-Host "工作空间整理工具" -ForegroundColor Cyan
Write-Host "=================="
Write-Host "开始时间: $(Get-Date -Format 'HH:mm:ss')"
Write-Host ""

# 阶段1: 清理
if ($Cleanup) {
    Write-Host "=== 阶段1: 清理无效文件 ===" -ForegroundColor Yellow
    Write-Host ""
    
    # 零字节文件
    $zeroFiles = Get-ChildItem -Path "." -Recurse -File | Where-Object {$_.Length -eq 0}
    if ($zeroFiles.Count -gt 0) {
        Write-Host "删除零字节文件: $($zeroFiles.Count) 个"
        $zeroFiles | Remove-Item -Force
    }
    
    # 临时文件
    $tempFiles = Get-ChildItem -Path "." -Recurse -File -Include "*.tmp", "*.temp", "*.bak"
    if ($tempFiles.Count -gt 0) {
        $tempSize = ($tempFiles | Measure-Object Length -Sum).Sum
        Write-Host "删除临时文件: $($tempFiles.Count) 个 ($([math]::Round($tempSize/1MB,2)) MB)"
        $tempFiles | Remove-Item -Force
    }
    
    # 日志文件
    $logFiles = Get-ChildItem -Path "." -Recurse -File -Include "*.log"
    if ($logFiles.Count -gt 0) {
        $logSize = ($logFiles | Measure-Object Length -Sum).Sum
        Write-Host "删除日志文件: $($logFiles.Count) 个 ($([math]::Round($logSize/1MB,2)) MB)"
        $logFiles | Remove-Item -Force
    }
    
    # 空目录
    $emptyDirs = Get-ChildItem -Path "." -Recurse -Directory | Where-Object {
        -not (Get-ChildItem -Path $_.FullName -Recurse -Force)
    }
    if ($emptyDirs.Count -gt 0) {
        Write-Host "删除空目录: $($emptyDirs.Count) 个"
        $emptyDirs | Sort-Object -Property {$_.FullName.Length} -Descending | Remove-Item -Force
    }
    
    Write-Host "✅ 清理完成"
    Write-Host ""
}

# 阶段2: 分析
if ($Analyze) {
    Write-Host "=== 阶段2: 工作空间分析 ===" -ForegroundColor Yellow
    Write-Host ""
    
    $files = Get-ChildItem -Path "." -Recurse -File
    $dirs = Get-ChildItem -Path "." -Recurse -Directory
    
    Write-Host "基本统计:"
    Write-Host "  文件总数: $($files.Count)"
    Write-Host "  目录总数: $($dirs.Count)"
    $totalSize = ($files | Measure-Object Length -Sum).Sum
    Write-Host "  总大小: $([math]::Round($totalSize/1MB,2)) MB"
    Write-Host ""
    
    # 重复文件
    $duplicates = $files | Group-Object Name | Where-Object {$_.Count -gt 1}
    if ($duplicates.Count -gt 0) {
        Write-Host "重复文件: $($duplicates.Count) 组"
        $duplicates | Select-Object -First 5 Name, Count | ForEach-Object {
            Write-Host "  - $($_.Name): $($_.Count) 个副本"
        }
    } else {
        Write-Host "重复文件: 无"
    }
    Write-Host ""
    
    # 目录深度
    $maxDepth = ($dirs | ForEach-Object {($_.FullName -split '\\').Count} | Measure-Object -Maximum).Maximum
    Write-Host "目录深度: 最大 $maxDepth 层"
    if ($maxDepth -gt 5) {
        Write-Host "  建议: 优化目录结构"
    }
    Write-Host ""
    
    Write-Host "✅ 分析完成"
    Write-Host ""
}

# 阶段3: 整理
if ($Organize) {
    Write-Host "=== 阶段3: 目录整理 ===" -ForegroundColor Yellow
    Write-Host ""
    
    # 创建标准目录
    $standardDirs = @("docs", "scripts", "data", "config", "temp", "archive", "projects", "logs", "backups", "media")
    
    foreach ($dir in $standardDirs) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Host "创建目录: $dir"
        }
    }
    
    Write-Host "✅ 目录结构创建完成"
    Write-Host ""
    
    # 文件分类建议
    Write-Host "文件分类建议:"
    $files = Get-ChildItem -Path "." -Recurse -File -Depth 1
    
    $extensionMap = @{
        ".md" = "docs"; ".txt" = "docs"; ".pdf" = "docs"
        ".ps1" = "scripts"; ".bat" = "scripts"
        ".json" = "config"; ".yaml" = "config"; ".yml" = "config"
        ".log" = "logs"
        ".tmp" = "temp"; ".temp" = "temp"
        ".bak" = "backups"
    }
    
    $files | Group-Object Extension | Sort-Object Count -Descending | Select-Object -First 10 Name, Count | ForEach-Object {
        $target = if ($extensionMap.ContainsKey($_.Name)) { $extensionMap[$_.Name] } else { "其他" }
        Write-Host "  $($_.Name): $($_.Count) 个文件 -> 建议移动到: $target"
    }
    
    Write-Host ""
    Write-Host "✅ 整理建议生成完成"
    Write-Host ""
}

Write-Host "=== 整理工作完成 ===" -ForegroundColor Green
Write-Host "完成时间: $(Get-Date -Format 'HH:mm:ss')"
Write-Host ""
Write-Host "建议下一步:"
Write-Host "1. 根据分类建议手动移动文件"
Write-Host "2. 考虑建立定期整理机制"
Write-Host "3. 监控磁盘空间使用情况"
Write-Host ""