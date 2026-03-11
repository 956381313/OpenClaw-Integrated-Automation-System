# 重复文件分析工具
Write-Host "重复文件分析工具" -ForegroundColor Cyan
Write-Host "=================="
Write-Host ""

# 1. 按文件名分析重复
Write-Host "1. 按文件名分析重复文件..." -ForegroundColor Yellow
$files = Get-ChildItem -Path "." -Recurse -File
$duplicatesByName = $files | Group-Object Name | Where-Object {$_.Count -gt 1} | Sort-Object Count -Descending

if ($duplicatesByName.Count -gt 0) {
    Write-Host "   发现 $($duplicatesByName.Count) 组文件名重复文件" -ForegroundColor Gray
    Write-Host "   前10组重复文件:" -ForegroundColor Gray
    $duplicatesByName | Select-Object -First 10 Name, Count, @{Name="TotalSizeMB";Expression={[math]::Round(($_.Group | Measure-Object Length -Sum).Sum/1MB,2)}} | Format-Table -AutoSize
} else {
    Write-Host "   ✅ 无文件名重复文件" -ForegroundColor Green
}
Write-Host ""

# 2. 按文件大小分析（快速筛选）
Write-Host "2. 按文件大小分析潜在重复..." -ForegroundColor Yellow
$duplicatesBySize = $files | Group-Object Length | Where-Object {$_.Count -gt 1 -and $_.Name -gt 1024} | Sort-Object Count -Descending

if ($duplicatesBySize.Count -gt 0) {
    Write-Host "   发现 $($duplicatesBySize.Count) 组大小相同的文件" -ForegroundColor Gray
    $totalPotentialSize = ($duplicatesBySize | ForEach-Object {($_.Count-1)*[int64]$_.Name} | Measure-Object -Sum).Sum
    Write-Host "   潜在可节省空间: $([math]::Round($totalPotentialSize/1MB,2)) MB" -ForegroundColor Gray
} else {
    Write-Host "   ✅ 无大小重复文件" -ForegroundColor Green
}
Write-Host ""

# 3. 按扩展名分析
Write-Host "3. 文件类型分布..." -ForegroundColor Yellow
$filesByExt = $files | Group-Object Extension | Sort-Object Count -Descending | Select-Object -First 10 Name, Count, @{Name="TotalSizeMB";Expression={[math]::Round(($_.Group | Measure-Object Length -Sum).Sum/1MB,2)}}

if ($filesByExt.Count -gt 0) {
    Write-Host "   前10种文件类型:" -ForegroundColor Gray
    $filesByExt | Format-Table -AutoSize
}
Write-Host ""

# 4. 大文件分析
Write-Host "4. 大文件分析（>10MB）..." -ForegroundColor Yellow
$largeFiles = $files | Where-Object {$_.Length -gt 10MB} | Sort-Object Length -Descending | Select-Object -First 10 Name, @{Name="SizeMB";Expression={[math]::Round($_.Length/1MB,2)}}, Directory

if ($largeFiles.Count -gt 0) {
    Write-Host "   前10个大文件:" -ForegroundColor Gray
    $largeFiles | Format-Table -AutoSize
    $totalLargeSize = ($largeFiles | Measure-Object -Property @{Expression={$_.Length}} -Sum).Sum
    Write-Host "   大文件总计: $([math]::Round($totalLargeSize/1MB,2)) MB" -ForegroundColor Gray
} else {
    Write-Host "   ✅ 无大文件（>10MB）" -ForegroundColor Green
}
Write-Host ""

# 5. 目录深度分析
Write-Host "5. 目录结构分析..." -ForegroundColor Yellow
$dirs = Get-ChildItem -Path "." -Recurse -Directory
$maxDepth = ($dirs | ForEach-Object {($_.FullName -split '\\').Count} | Measure-Object -Maximum).Maximum
$avgDepth = [math]::Round(($dirs | ForEach-Object {($_.FullName -split '\\').Count} | Measure-Object -Average).Average, 2)

Write-Host "   总目录数: $($dirs.Count)" -ForegroundColor Gray
Write-Host "   最大深度: $maxDepth 层" -ForegroundColor Gray
Write-Host "   平均深度: $avgDepth 层" -ForegroundColor Gray

if ($maxDepth -gt 5) {
    Write-Host "   ⚠️ 目录嵌套过深，建议优化" -ForegroundColor Yellow
}
Write-Host ""

# 总结
Write-Host "=== 分析总结 ===" -ForegroundColor Green
Write-Host "总文件数: $($files.Count)" -ForegroundColor Gray
Write-Host "总目录数: $($dirs.Count)" -ForegroundColor Gray
Write-Host "文件名重复组: $($duplicatesByName.Count)" -ForegroundColor Gray
Write-Host "大小重复组: $($duplicatesBySize.Count)" -ForegroundColor Gray

if ($duplicatesByName.Count -gt 0 -or $duplicatesBySize.Count -gt 0) {
    Write-Host "建议: 运行重复文件合并工具" -ForegroundColor Yellow
} else {
    Write-Host "✅ 文件组织良好" -ForegroundColor Green
}

Write-Host ""
Write-Host "分析完成" -ForegroundColor Gray