# 工作空间分析脚本
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "    工作空间文件分析" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "工作目录: $PWD" -ForegroundColor Gray
Write-Host ""

# 统计文件总数和大小
$totalFiles = (Get-ChildItem -Recurse -File | Measure-Object).Count
$totalSize = (Get-ChildItem -Recurse -File | Measure-Object -Property Length -Sum).Sum
$totalSizeMB = [math]::Round($totalSize / 1MB, 2)

Write-Host "📁 文件总数: $totalFiles" -ForegroundColor Yellow
Write-Host "💾 总大小: $totalSizeMB MB" -ForegroundColor Yellow
Write-Host ""

# 按类型统计
Write-Host "📋 按文件类型统计:" -ForegroundColor Cyan
$fileTypes = Get-ChildItem -Recurse -File | Group-Object Extension | Sort-Object Count -Descending | Select-Object -First 15

foreach ($type in $fileTypes) {
    $typeSize = ($type.Group | Measure-Object -Property Length -Sum).Sum
    $typeSizeMB = [math]::Round($typeSize / 1MB, 2)
    Write-Host ("  {0,-10} {1,5} 个文件 ({2,8} MB)" -f $type.Name, $type.Count, $typeSizeMB) -ForegroundColor Gray
}

Write-Host ""

# 按目录统计
Write-Host "📁 按目录统计:" -ForegroundColor Cyan
$directories = Get-ChildItem -Directory | Sort-Object Name

foreach ($dir in $directories) {
    $dirFiles = (Get-ChildItem -Path $dir.FullName -Recurse -File | Measure-Object).Count
    $dirSize = (Get-ChildItem -Path $dir.FullName -Recurse -File | Measure-Object -Property Length -Sum).Sum
    $dirSizeMB = [math]::Round($dirSize / 1MB, 2)
    
    if ($dirFiles -gt 0) {
        Write-Host ("  {0,-30} {1,5} 个文件 ({2,8} MB)" -f $dir.Name, $dirFiles, $dirSizeMB) -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "    分析完成" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Cyan