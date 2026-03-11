# 快速删除脚本 - 无需管理员权限
Write-Host "快速删除顽固文件夹" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Gray
Write-Host ""

$folders = @(
    "C:\Users\luchaochao\.openclaw\workspace\english-reorg-backup-20260306-234623",
    "C:\Users\luchaochao\.openclaw\workspace\pre-architecture-backup-20260306-172408"
)

foreach ($folder in $folders) {
    $name = Split-Path $folder -Leaf
    
    if (Test-Path $folder) {
        Write-Host "处理: $name" -ForegroundColor Yellow
        
        # 方法1: 尝试普通删除
        try {
            Remove-Item -Path $folder -Recurse -Force -ErrorAction Stop
            Write-Host "  ✅ 普通删除成功" -ForegroundColor Green
            continue
        } catch {
            Write-Host "  ⚠️ 普通删除失败" -ForegroundColor Yellow
        }
        
        # 方法2: 使用robocopy清空
        try {
            Write-Host "  尝试robocopy清空..." -ForegroundColor Gray
            $emptyDir = "C:\temp_empty_$([guid]::NewGuid().ToString().Substring(0,8))"
            New-Item -ItemType Directory -Path $emptyDir -Force | Out-Null
            robocopy $emptyDir $folder /MIR /NJH /NJS /NP /NDL /NS /NC 2>$null
            Remove-Item -Path $folder -Force -Recurse -ErrorAction SilentlyContinue
            Remove-Item -Path $emptyDir -Force -Recurse -ErrorAction SilentlyContinue
            
            if (-not (Test-Path $folder)) {
                Write-Host "  ✅ robocopy方法成功" -ForegroundColor Green
                continue
            }
        } catch {
            Write-Host "  ⚠️ robocopy方法失败" -ForegroundColor Yellow
        }
        
        # 方法3: 逐层删除
        try {
            Write-Host "  尝试逐层删除..." -ForegroundColor Gray
            Get-ChildItem -Path $folder -Recurse -Force | Sort-Object -Property FullName -Descending | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            Remove-Item -Path $folder -Force -Recurse -ErrorAction SilentlyContinue
            
            if (-not (Test-Path $folder)) {
                Write-Host "  ✅ 逐层删除成功" -ForegroundColor Green
                continue
            }
        } catch {
            Write-Host "  ⚠️ 逐层删除失败" -ForegroundColor Yellow
        }
        
        Write-Host "  ❌ 所有方法都失败" -ForegroundColor Red
        Write-Host "     建议: 重启电脑后立即删除此文件夹" -ForegroundColor Red
        
    } else {
        Write-Host "  ✅ 文件夹不存在: $name" -ForegroundColor Gray
    }
    
    Write-Host ""
}

Write-Host ""
Write-Host "最终检查..." -ForegroundColor Cyan
$remaining = 0

foreach ($folder in $folders) {
    if (Test-Path $folder) {
        $remaining++
        Write-Host "❌ 仍然存在: $(Split-Path $folder -Leaf)" -ForegroundColor Red
    } else {
        Write-Host "✅ 已删除: $(Split-Path $folder -Leaf)" -ForegroundColor Green
    }
}

Write-Host ""
if ($remaining -eq 0) {
    Write-Host "🎉 所有文件夹已成功删除！" -ForegroundColor Green
} else {
    Write-Host "⚠️ 仍有 $remaining 个文件夹需要处理" -ForegroundColor Yellow
    Write-Host "   建议重启电脑后运行此脚本再次尝试" -ForegroundColor Gray
}

Write-Host ""
Write-Host "按任意键退出..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")