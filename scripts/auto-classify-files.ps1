# 自动文件分类脚本
Write-Host "自动文件分类整理"
Write-Host "=================="
Write-Host "开始时间: $(Get-Date -Format 'HH:mm:ss')"
Write-Host ""

# 确保目标目录存在
$targetDirs = @{
    "scripts" = @(".ps1", ".bat", ".sh", ".py", ".js")
    "docs" = @(".md", ".txt", ".pdf", ".doc", ".docx", ".rtf")
    "config" = @(".json", ".yaml", ".yml", ".xml", ".ini", ".cfg")
    "data" = @(".csv", ".xlsx", ".xls", ".db", ".sqlite")
    "media" = @(".jpg", ".png", ".gif", ".mp4", ".mp3", ".wav")
    "archive" = @(".zip", ".rar", ".7z", ".tar", ".gz")
    "logs" = @(".log")
    "temp" = @(".tmp", ".temp", ".bak")
}

foreach ($dir in $targetDirs.Keys) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "创建目录: $dir"
    }
}
Write-Host ""

# 统计变量
$stats = @{
    Moved = 0
    Skipped = 0
    Errors = 0
}

# 获取根目录文件（不包含子目录）
$files = Get-ChildItem -Path "." -File -Depth 0

Write-Host "发现 $($files.Count) 个文件需要分类"
Write-Host ""

foreach ($file in $files) {
    $moved = $false
    
    foreach ($dir in $targetDirs.Keys) {
        $extensions = $targetDirs[$dir]
        
        foreach ($ext in $extensions) {
            if ($file.Extension -eq $ext) {
                try {
                    Move-Item -Path $file.FullName -Destination $dir -Force -ErrorAction Stop
                    Write-Host "移动: $($file.Name) -> $dir/"
                    $stats.Moved++
                    $moved = $true
                    break
                } catch {
                    Write-Host "错误: 无法移动 $($file.Name)" -ForegroundColor Red
                    $stats.Errors++
                    $moved = $true
                }
            }
            if ($moved) { break }
        }
        if ($moved) { break }
    }
    
    if (-not $moved) {
        # 未分类的文件
        $stats.Skipped++
    }
}

Write-Host ""
Write-Host "=== 分类结果 ===" -ForegroundColor Green
Write-Host "移动文件: $($stats.Moved) 个" -ForegroundColor Cyan
Write-Host "跳过文件: $($stats.Skipped) 个" -ForegroundColor Gray
Write-Host "错误文件: $($stats.Errors) 个" -ForegroundColor $(if ($stats.Errors -gt 0) {"Red"} else {"Gray"})
Write-Host ""

# 显示各目录文件数
Write-Host "各目录文件统计:" -ForegroundColor Yellow
foreach ($dir in $targetDirs.Keys) {
    $fileCount = (Get-ChildItem -Path $dir -File -ErrorAction SilentlyContinue).Count
    if ($fileCount -gt 0) {
        Write-Host "  $dir/: $fileCount 个文件" -ForegroundColor Gray
    }
}
Write-Host ""

# 显示未分类的文件
$remainingFiles = Get-ChildItem -Path "." -File -Depth 0
if ($remainingFiles.Count -gt 0) {
    Write-Host "未分类的文件 ($($remainingFiles.Count) 个):" -ForegroundColor Yellow
    $remainingFiles | Select-Object -First 10 Name, Extension | ForEach-Object {
        Write-Host "  - $($_.Name)" -ForegroundColor Gray
    }
    if ($remainingFiles.Count -gt 10) {
        Write-Host "  ... 还有 $($remainingFiles.Count - 10) 个" -ForegroundColor Gray
    }
} else {
    Write-Host "✅ 所有文件已分类" -ForegroundColor Green
}

Write-Host ""
Write-Host "完成时间: $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Gray