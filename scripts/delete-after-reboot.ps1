# 重启后自动删除脚本
# 这个脚本会在系统启动时自动运行，删除顽固的备份文件夹

Write-Host "重启后自动删除工具" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Gray
Write-Host "运行时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host ""

# 要删除的文件夹列表
$foldersToDelete = @(
    "C:\Users\luchaochao\.openclaw\workspace\english-reorg-backup-20260306-234623",
    "C:\Users\luchaochao\.openclaw\workspace\pre-architecture-backup-20260306-172408"
)

Write-Host "目标文件夹:" -ForegroundColor Yellow
foreach ($folder in $foldersToDelete) {
    $name = Split-Path $folder -Leaf
    Write-Host "  - $name" -ForegroundColor Gray
}
Write-Host ""

$successCount = 0
$totalCount = $foldersToDelete.Count

foreach ($folder in $foldersToDelete) {
    $folderName = Split-Path $folder -Leaf
    
    if (Test-Path $folder) {
        Write-Host "正在删除: $folderName" -ForegroundColor Cyan
        
        # 方法1: 使用robocopy镜像（最可靠）
        try {
            Write-Host "  尝试robocopy镜像删除..." -ForegroundColor Gray
            $emptyDir = "C:\temp_empty_$([guid]::NewGuid().ToString().Substring(0,8))"
            New-Item -ItemType Directory -Path $emptyDir -Force | Out-Null
            
            # 使用robocopy清空文件夹
            robocopy $emptyDir $folder /MIR /NJH /NJS /NP /NDL /NS /NC 2>$null
            
            # 删除空文件夹
            Remove-Item -Path $folder -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $emptyDir -Force -ErrorAction SilentlyContinue
            
            if (-not (Test-Path $folder)) {
                Write-Host "  ✅ 删除成功" -ForegroundColor Green
                $successCount++
                continue
            }
        } catch {
            Write-Host "  ⚠️ robocopy失败" -ForegroundColor Yellow
        }
        
        # 方法2: 使用.NET方法
        try {
            Write-Host "  尝试.NET强力删除..." -ForegroundColor Gray
            [System.IO.Directory]::Delete($folder, $true)
            
            if (-not (Test-Path $folder)) {
                Write-Host "  ✅ 删除成功" -ForegroundColor Green
                $successCount++
                continue
            }
        } catch {
            Write-Host "  ⚠️ .NET删除失败" -ForegroundColor Yellow
        }
        
        # 方法3: 使用cmd rd命令
        try {
            Write-Host "  尝试cmd rd命令..." -ForegroundColor Gray
            cmd /c "rd /s /q `"$folder`"" 2>$null
            Start-Sleep -Seconds 2
            
            if (-not (Test-Path $folder)) {
                Write-Host "  ✅ 删除成功" -ForegroundColor Green
                $successCount++
                continue
            }
        } catch {
            Write-Host "  ⚠️ cmd命令失败" -ForegroundColor Yellow
        }
        
        Write-Host "  ❌ 删除失败" -ForegroundColor Red
        
    } else {
        Write-Host "  ✅ 文件夹不存在: $folderName" -ForegroundColor Green
        $successCount++
    }
    
    Write-Host ""
}

Write-Host ""
Write-Host "=== 删除结果 ===" -ForegroundColor Cyan
Write-Host "成功删除: $successCount/$totalCount 个文件夹" -ForegroundColor $(if ($successCount -eq $totalCount) {"Green"} else {"Yellow"})

if ($successCount -eq $totalCount) {
    Write-Host "🎉 所有文件夹已成功删除！" -ForegroundColor Green
} else {
    Write-Host "⚠️ 仍有 $($totalCount - $successCount) 个文件夹需要处理" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "磁盘空间状态:" -ForegroundColor Cyan
$diskC = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
if ($diskC) {
    $usedPercent = [math]::Round((($diskC.Size - $diskC.FreeSpace)/$diskC.Size)*100, 2)
    $freeGB = [math]::Round($diskC.FreeSpace/1GB, 2)
    Write-Host "  C盘使用率: ${usedPercent}%" -ForegroundColor $(if ($usedPercent -lt 80) {"Green"} else {"Yellow"})
    Write-Host "  可用空间: ${freeGB} GB" -ForegroundColor Green
}

Write-Host ""
Write-Host "脚本执行完成" -ForegroundColor Gray
Write-Host "按任意键退出..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")