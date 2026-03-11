# 跳过权限直接删除脚本
Write-Host "跳过权限直接删除" -ForegroundColor Red
Write-Host "==================" -ForegroundColor Gray
Write-Host "注意: 这可能会跳过一些权限检查" -ForegroundColor Yellow
Write-Host ""

$folders = @(
    "C:\Users\luchaochao\.openclaw\workspace\english-reorg-backup-20260306-234623",
    "C:\Users\luchaochao\.openclaw\workspace\pre-architecture-backup-20260306-172408"
)

foreach ($folder in $folders) {
    $name = Split-Path $folder -Leaf
    
    if (Test-Path $folder) {
        Write-Host "处理: $name" -ForegroundColor Cyan
        
        # 方法1: 直接使用robocopy镜像（最快）
        Write-Host "  使用robocopy镜像删除..." -ForegroundColor Gray
        try {
            # 创建空目录
            $emptyDir = "C:\temp_empty_$([guid]::NewGuid().ToString().Substring(0,8))"
            New-Item -ItemType Directory -Path $emptyDir -Force | Out-Null
            
            # 使用robocopy镜像（这会删除所有内容）
            robocopy $emptyDir $folder /MIR /NJH /NJS /NP /NDL /NS /NC 2>$null
            
            # 删除空文件夹
            Remove-Item -Path $folder -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $emptyDir -Force -ErrorAction SilentlyContinue
            
            if (-not (Test-Path $folder)) {
                Write-Host "  ✅ robocopy删除成功" -ForegroundColor Green
                continue
            }
        } catch {
            Write-Host "  ⚠️ robocopy失败" -ForegroundColor Yellow
        }
        
        # 方法2: 使用.NET强力删除
        Write-Host "  使用.NET强力删除..." -ForegroundColor Gray
        try {
            [System.IO.Directory]::Delete($folder, $true)
            if (-not (Test-Path $folder)) {
                Write-Host "  ✅ .NET删除成功" -ForegroundColor Green
                continue
            }
        } catch {
            Write-Host "  ⚠️ .NET删除失败" -ForegroundColor Yellow
        }
        
        # 方法3: 创建批处理延迟删除
        Write-Host "  创建批处理延迟删除..." -ForegroundColor Gray
        try {
            $batFile = "C:\temp_del_$([guid]::NewGuid().ToString().Substring(0,8)).bat"
            "@echo off`ntimeout /t 2 /nobreak >nul`necho Deleting $name...`nrd /s /q `"$folder`"`necho Done.`ndel `"%~f0`"" | Out-File -FilePath $batFile -Encoding ASCII
            
            Start-Process -FilePath $batFile -WindowStyle Hidden
            Start-Sleep -Seconds 5
            
            if (-not (Test-Path $folder)) {
                Write-Host "  ✅ 批处理删除成功" -ForegroundColor Green
                continue
            }
        } catch {
            Write-Host "  ⚠️ 批处理删除失败" -ForegroundColor Yellow
        }
        
        Write-Host "  ❌ 所有方法都失败" -ForegroundColor Red
        Write-Host "     这个文件夹可能需要重启后删除" -ForegroundColor Red
        
    } else {
        Write-Host "  ✅ 文件夹不存在: $name" -ForegroundColor Gray
    }
    
    Write-Host ""
}

Write-Host ""
Write-Host "检查结果..." -ForegroundColor Cyan
$deletedCount = 0

foreach ($folder in $folders) {
    if (-not (Test-Path $folder)) {
        $deletedCount++
        Write-Host "✅ $(Split-Path $folder -Leaf) 已删除" -ForegroundColor Green
    } else {
        Write-Host "❌ $(Split-Path $folder -Leaf) 仍然存在" -ForegroundColor Red
    }
}

Write-Host ""
if ($deletedCount -eq 2) {
    Write-Host "🎉 所有文件夹已删除！" -ForegroundColor Green
} elseif ($deletedCount -eq 1) {
    Write-Host "⚠️ 删除了1个，还有1个需要处理" -ForegroundColor Yellow
} else {
    Write-Host "❌ 两个文件夹都删除失败" -ForegroundColor Red
    Write-Host "   建议: 重启电脑，开机后立即运行此脚本" -ForegroundColor Red
}

Write-Host ""
Write-Host "按任意键退出..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")