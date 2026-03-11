# 目录优化工具
Write-Host "目录优化工具"
Write-Host "============"
Write-Host ""

# 标准目录结构
$standardStructure = @{
    "docs" = "文档文件"
    "scripts" = "脚本文件"
    "data" = "数据文件"
    "config" = "配置文件"
    "temp" = "临时文件"
    "archive" = "归档文件"
    "projects" = "项目文件"
    "logs" = "日志文件"
    "backups" = "备份文件"
    "media" = "媒体文件"
}

Write-Host "创建标准目录结构..."
foreach ($dir in $standardStructure.Keys) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "  创建: $dir ($($standardStructure[$dir]))"
    } else {
        Write-Host "  已存在: $dir"
    }
}
Write-Host ""

# 分析当前文件分布
Write-Host "分析文件分布..."
$files = Get-ChildItem -Path "." -Recurse -File -Depth 2

# 按扩展名分类建议
$extensionMapping = @{
    ".md" = "docs"
    ".txt" = "docs"
    ".pdf" = "docs"
    ".doc" = "docs"
    ".docx" = "docs"
    
    ".ps1" = "scripts"
    ".bat" = "scripts"
    ".sh" = "scripts"
    ".py" = "scripts"
    
    ".json" = "config"
    ".yaml" = "config"
    ".yml" = "config"
    ".xml" = "config"
    ".ini" = "config"
    
    ".log" = "logs"
    ".tmp" = "temp"
    ".temp" = "temp"
    ".bak" = "backups"
    
    ".jpg" = "media"
    ".png" = "media"
    ".gif" = "media"
    ".mp4" = "media"
    ".mp3" = "media"
}

# 统计文件类型
Write-Host "文件类型统计:"
$files | Group-Object Extension | Sort-Object Count -Descending | Select-Object -First 10 Name, Count | ForEach-Object {
    $targetDir = if ($extensionMapping.ContainsKey($_.Name)) { $extensionMapping[$_.Name] } else { "其他" }
    Write-Host "  $($_.Name): $($_.Count) 个文件 -> 建议: $targetDir"
}
Write-Host ""

# 检查过深目录
Write-Host "检查目录深度..."
$deepDirs = Get-ChildItem -Path "." -Recurse -Directory | Where-Object {
    ($_.FullName -split '\\').Count -gt 6
}

if ($deepDirs.Count -gt 0) {
    Write-Host "  发现 $($deepDirs.Count) 个过深目录（>6层）"
    $deepDirs | Select-Object -First 5 FullName | ForEach-Object {
        $depth = ($_.FullName -split '\\').Count
        Write-Host "    - $($_.FullName) ($depth 层)"
    }
    Write-Host "  建议: 考虑扁平化这些目录"
} else {
    Write-Host "  ✅ 目录深度正常"
}
Write-Host ""

# 空目录检查
Write-Host "检查空目录..."
$emptyDirs = Get-ChildItem -Path "." -Recurse -Directory | Where-Object {
    -not (Get-ChildItem -Path $_.FullName -Recurse -Force)
}

if ($emptyDirs.Count -gt 0) {
    Write-Host "  发现 $($emptyDirs.Count) 个空目录"
    Write-Host "  建议: 可以安全删除这些空目录"
} else {
    Write-Host "  ✅ 无空目录"
}
Write-Host ""

Write-Host "优化建议:"
Write-Host "1. 将文件按类型移动到对应目录"
Write-Host "2. 考虑扁平化过深目录"
WriteHost "3. 删除空目录"
Write-Host "4. 建立定期整理机制"
Write-Host ""
Write-Host "完成"