# 识别无用文件脚本
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "    无用文件识别" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# 定义无用文件模式
$unusedPatterns = @(
    "*.tmp",
    "*.temp",
    "*.bak",
    "*.backup",
    "*.old",
    "*.log",
    "~*",
    "*.cache",
    "*.swp",
    "Thumbs.db",
    ".DS_Store",
    "desktop.ini"
)

# 定义临时目录
$tempDirectories = @(
    "temp",
    "tmp",
    "cache",
    "logs",
    "backup",
    "backups"
)

Write-Host "🔍 搜索无用文件..." -ForegroundColor Cyan
Write-Host ""

$unusedFiles = @()
$totalUnusedSize = 0

foreach ($pattern in $unusedPatterns) {
    $files = Get-ChildItem -Recurse -Filter $pattern -ErrorAction SilentlyContinue
    foreach ($file in $files) {
        $unusedFiles += [PSCustomObject]@{
            Path = $file.FullName
            Name = $file.Name
            SizeMB = [math]::Round($file.Length / 1MB, 3)
            Type = "Pattern: $pattern"
            LastAccess = $file.LastAccessTime
        }
        $totalUnusedSize += $file.Length
    }
}

# 搜索大日志文件 (大于10MB)
Write-Host "📊 搜索大日志文件 (>10MB)..." -ForegroundColor Gray
$largeLogs = Get-ChildItem -Recurse -Filter "*.log" -ErrorAction SilentlyContinue | Where-Object { $_.Length -gt 10MB }
foreach ($log in $largeLogs) {
    $unusedFiles += [PSCustomObject]@{
        Path = $log.FullName
        Name = $log.Name
        SizeMB = [math]::Round($log.Length / 1MB, 2)
        Type = "Large Log (>10MB)"
        LastAccess = $log.LastAccessTime
    }
    $totalUnusedSize += $log.Length
}

# 搜索旧备份文件 (超过30天)
Write-Host "📅 搜索旧备份文件 (>30天)..." -ForegroundColor Gray
$oldBackups = Get-ChildItem -Recurse -Filter "*backup*" -ErrorAction SilentlyContinue | Where-Object { $_.LastAccessTime -lt (Get-Date).AddDays(-30) }
foreach ($backup in $oldBackups) {
    $unusedFiles += [PSCustomObject]@{
        Path = $backup.FullName
        Name = $backup.Name
        SizeMB = [math]::Round($backup.Length / 1MB, 3)
        Type = "Old Backup (>30 days)"
        LastAccess = $backup.LastAccessTime
    }
    $totalUnusedSize += $backup.Length
}

# 搜索空文件
Write-Host "📄 搜索空文件 (0字节)..." -ForegroundColor Gray
$emptyFiles = Get-ChildItem -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Length -eq 0 }
foreach ($empty in $emptyFiles) {
    $unusedFiles += [PSCustomObject]@{
        Path = $empty.FullName
        Name = $empty.Name
        SizeMB = 0
        Type = "Empty File"
        LastAccess = $empty.LastAccessTime
    }
}

# 显示结果
$totalUnusedSizeMB = [math]::Round($totalUnusedSize / 1MB, 2)
Write-Host ""
Write-Host "📊 无用文件统计:" -ForegroundColor Cyan
Write-Host "  文件总数: $($unusedFiles.Count)" -ForegroundColor Yellow
Write-Host "  总大小: $totalUnusedSizeMB MB" -ForegroundColor Yellow
Write-Host ""

if ($unusedFiles.Count -gt 0) {
    Write-Host "📋 无用文件列表 (前20个):" -ForegroundColor Cyan
    $unusedFiles | Sort-Object SizeMB -Descending | Select-Object -First 20 | ForEach-Object {
        Write-Host ("  {0,-40} {1,8} MB  {2}" -f $_.Name, $_.SizeMB, $_.Type) -ForegroundColor Gray
    }
    
    # 保存到文件
    $reportPath = "unused-files-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
    $unusedFiles | Sort-Object SizeMB -Descending | Select-Object Path, Name, SizeMB, Type, LastAccess | Export-Csv -Path $reportPath -NoTypeInformation -Encoding UTF8
    Write-Host ""
    Write-Host "📄 详细报告已保存: $reportPath" -ForegroundColor Green
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "    识别完成" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Cyan

# 建议
Write-Host ""
Write-Host "💡 建议清理操作:" -ForegroundColor Cyan
Write-Host "  1. 删除临时文件 (*.tmp, *.temp)" -ForegroundColor Gray
Write-Host "  2. 清理旧备份文件 (>30天)" -ForegroundColor Gray
Write-Host "  3. 压缩大日志文件" -ForegroundColor Gray
Write-Host "  4. 删除空文件" -ForegroundColor Gray
Write-Host "  5. 使用重复文件清理系统处理重复文件" -ForegroundColor Gray