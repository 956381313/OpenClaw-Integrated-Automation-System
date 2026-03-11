# 无效文件清理脚本
Write-Host "=== 无效文件清理 ===" -ForegroundColor Cyan
Write-Host "开始时间: $(Get-Date -Format 'HH:mm:ss')"
Write-Host ""

# 记录统计
$stats = @{
    ZeroByteFiles = 0
    TempFiles = 0
    BackupFiles = 0
    LogFiles = 0
    TotalDeleted = 0
    SpaceFreed = 0
}

# 1. 零字节文件
Write-Host "1. 清理零字节文件..." -ForegroundColor Yellow
$zeroByteFiles = Get-ChildItem -Path "." -Recurse -File | Where-Object {$_.Length -eq 0}
$stats.ZeroByteFiles = $zeroByteFiles.Count

if ($zeroByteFiles.Count -gt 0) {
    Write-Host "   发现 $($zeroByteFiles.Count) 个零字节文件" -ForegroundColor Gray
    $zeroByteFiles | Remove-Item -Force
    Write-Host "   ✅ 已删除" -ForegroundColor Green
} else {
    Write-Host "   ✅ 无零字节文件" -ForegroundColor Gray
}
Write-Host ""

# 2. 临时文件
Write-Host "2. 清理临时文件..." -ForegroundColor Yellow
$tempFiles = Get-ChildItem -Path "." -Recurse -File -Include "*.tmp", "*.temp", "*.bak"
$stats.TempFiles = $tempFiles.Count

if ($tempFiles.Count -gt 0) {
    Write-Host "   发现 $($tempFiles.Count) 个临时文件" -ForegroundColor Gray
    $tempSize = ($tempFiles | Measure-Object Length -Sum).Sum
    $stats.SpaceFreed += $tempSize
    $tempFiles | Remove-Item -Force
    Write-Host "   ✅ 已删除 (释放 $([math]::Round($tempSize/1MB,2)) MB)" -ForegroundColor Green
} else {
    Write-Host "   ✅ 无临时文件" -ForegroundColor Gray
}
Write-Host ""

# 3. 日志文件
Write-Host "3. 清理日志文件..." -ForegroundColor Yellow
$logFiles = Get-ChildItem -Path "." -Recurse -File -Include "*.log"
$stats.LogFiles = $logFiles.Count

if ($logFiles.Count -gt 0) {
    Write-Host "   发现 $($logFiles.Count) 个日志文件" -ForegroundColor Gray
    $logSize = ($logFiles | Measure-Object Length -Sum).Sum
    $stats.SpaceFreed += $logSize
    $logFiles | Remove-Item -Force
    Write-Host "   ✅ 已删除 (释放 $([math]::Round($logSize/1MB,2)) MB)" -ForegroundColor Green
} else {
    Write-Host "   ✅ 无日志文件" -ForegroundColor Gray
}
Write-Host ""

# 4. 备份文件（~开头）
Write-Host "4. 清理备份文件..." -ForegroundColor Yellow
$backupFiles = Get-ChildItem -Path "." -Recurse -File | Where-Object {$_.Name -match '^~'}
$stats.BackupFiles = $backupFiles.Count

if ($backupFiles.Count -gt 0) {
    Write-Host "   发现 $($backupFiles.Count) 个备份文件" -ForegroundColor Gray
    $backupSize = ($backupFiles | Measure-Object Length -Sum).Sum
    $stats.SpaceFreed += $backupSize
    $backupFiles | Remove-Item -Force
    Write-Host "   ✅ 已删除 (释放 $([math]::Round($backupSize/1MB,2)) MB)" -ForegroundColor Green
} else {
    Write-Host "   ✅ 无备份文件" -ForegroundColor Gray
}
Write-Host ""

# 统计汇总
$stats.TotalDeleted = $stats.ZeroByteFiles + $stats.TempFiles + $stats.LogFiles + $stats.BackupFiles

Write-Host "=== 清理结果汇总 ===" -ForegroundColor Green
Write-Host "零字节文件: $($stats.ZeroByteFiles) 个" -ForegroundColor Gray
Write-Host "临时文件: $($stats.TempFiles) 个" -ForegroundColor Gray
Write-Host "日志文件: $($stats.LogFiles) 个" -ForegroundColor Gray
Write-Host "备份文件: $($stats.BackupFiles) 个" -ForegroundColor Gray
Write-Host "总计删除: $($stats.TotalDeleted) 个文件" -ForegroundColor Cyan
Write-Host "释放空间: $([math]::Round($stats.SpaceFreed/1MB,2)) MB" -ForegroundColor Green
Write-Host ""

# 5. 清理空目录
Write-Host "5. 清理空目录..." -ForegroundColor Yellow
$emptyDirs = Get-ChildItem -Path "." -Recurse -Directory | Where-Object {
    -not (Get-ChildItem -Path $_.FullName -Recurse -Force)
}
$emptyDirCount = $emptyDirs.Count

if ($emptyDirCount -gt 0) {
    Write-Host "   发现 $emptyDirCount 个空目录" -ForegroundColor Gray
    # 从最深目录开始删除
    $emptyDirs | Sort-Object -Property {$_.FullName.Length} -Descending | Remove-Item -Force
    Write-Host "   ✅ 已清理空目录" -ForegroundColor Green
} else {
    Write-Host "   ✅ 无空目录" -ForegroundColor Gray
}

Write-Host ""
Write-Host "完成时间: $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Gray