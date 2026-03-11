# 强力删除备份文件夹脚本
Write-Host "=== 强力删除备份文件夹 ===" -ForegroundColor Red
Write-Host "开始时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host ""

$backupFolders = @(
    "english-reorg-backup-20260306-234623",
    "pre-architecture-backup-20260306-172408"
)

foreach ($folderName in $backupFolders) {
    $fullPath = "C:\Users\luchaochao\.openclaw\workspace\$folderName"
    
    if (Test-Path $fullPath) {
        Write-Host "处理文件夹: $folderName" -ForegroundColor Yellow
        
        # 方法1: 使用.NET方法
        try {
            Write-Host "  尝试方法1: .NET Directory.Delete..." -ForegroundColor Gray
            [System.IO.Directory]::Delete($fullPath, $true)
            Write-Host "  ✅ .NET方法成功" -ForegroundColor Green
            continue
        } catch {
            Write-Host "  ⚠️ .NET方法失败" -ForegroundColor Yellow
        }
        
        # 方法2: 使用cmd rd命令
        try {
            Write-Host "  尝试方法2: cmd rd命令..." -ForegroundColor Gray
            $cmdOutput = cmd /c "rd /s /q `"$fullPath`" 2>&1"
            Start-Sleep -Seconds 3
            if (-not (Test-Path $fullPath)) {
                Write-Host "  ✅ cmd命令成功" -ForegroundColor Green
                continue
            }
        } catch {
            Write-Host "  ⚠️ cmd命令失败" -ForegroundColor Yellow
        }
        
        # 方法3: 使用robocopy镜像空目录
        try {
            Write-Host "  尝试方法3: robocopy镜像..." -ForegroundColor Gray
            $emptyDir = "C:\temp_empty_$(Get-Random)"
            New-Item -ItemType Directory -Path $emptyDir -Force | Out-Null
            robocopy $emptyDir $fullPath /MIR /NJH /NJS /NP /NDL /NS /NC > $null
            Remove-Item -Path $fullPath -Force -Recurse -ErrorAction SilentlyContinue
            Remove-Item -Path $emptyDir -Force -Recurse -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            if (-not (Test-Path $fullPath)) {
                Write-Host "  ✅ robocopy方法成功" -ForegroundColor Green
                continue
            }
        } catch {
            Write-Host "  ⚠️ robocopy方法失败" -ForegroundColor Yellow
        }
        
        # 方法4: 终极方法 - 使用进程结束和重试
        Write-Host "  尝试方法4: 终极方法..." -ForegroundColor Red
        try {
            # 结束可能占用文件的进程
            Get-Process | Where-Object { $_.Path -like "*$folderName*" } | Stop-Process -Force -ErrorAction SilentlyContinue
            
            # 使用延迟删除
            $tempBat = "C:\temp_delete_$(Get-Random).bat"
            "@echo off`ntimeout /t 2 /nobreak >nul`nrd /s /q `"$fullPath`"`ndel `"%~f0`"" | Out-File -FilePath $tempBat -Encoding ASCII
            Start-Process -FilePath $tempBat -WindowStyle Hidden
            
            Start-Sleep -Seconds 5
            if (-not (Test-Path $fullPath)) {
                Write-Host "  ✅ 终极方法成功" -ForegroundColor Green
            } else {
                Write-Host "  ❌ 所有方法都失败" -ForegroundColor Red
            }
        } catch {
            Write-Host "  ❌ 终极方法失败" -ForegroundColor Red
        }
    } else {
        Write-Host "  文件夹不存在: $folderName" -ForegroundColor Gray
    }
    
    Write-Host ""
}

Write-Host ""
Write-Host "=== 最终检查 ===" -ForegroundColor Cyan
$remaining = Get-ChildItem -Path "C:\Users\luchaochao\.openclaw\workspace" -Directory -Force | Where-Object {$_.Name -match "backup"}

if ($remaining.Count -eq 0) {
    Write-Host "✅ 所有备份文件夹已成功删除" -ForegroundColor Green
} else {
    Write-Host "⚠️ 仍有 $($remaining.Count) 个文件夹无法删除:" -ForegroundColor Yellow
    $remaining | ForEach-Object {
        Write-Host "  - $($_.Name)" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "完成时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"