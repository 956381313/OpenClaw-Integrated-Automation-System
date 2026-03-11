# 文件合并与重命名脚本

Write-Host "文件合并与重命名" -ForegroundColor Cyan
Write-Host "=================="
Write-Host "开始时间: $(Get-Date -Format 'HH:mm:ss')"
Write-Host ""

# 1. 分析当前文件
Write-Host "1. 分析当前文件..." -ForegroundColor Yellow
$allFiles = Get-ChildItem -File
Write-Host "   根目录文件数: $($allFiles.Count)" -ForegroundColor Gray
Write-Host ""

# 2. 识别需要合并的自动化系统文件
Write-Host "2. 识别自动化系统相关文件..." -ForegroundColor Yellow
$autoSystemFiles = $allFiles | Where-Object { 
    $_.Name -match "auto-system|automation-system|maintenance" -or 
    $_.Name -match "setup.*task|organize.*workspace"
}

if ($autoSystemFiles.Count -gt 0) {
    Write-Host "   找到 $($autoSystemFiles.Count) 个自动化系统文件:" -ForegroundColor Gray
    $autoSystemFiles | ForEach-Object {
        Write-Host "   📄 $($_.Name) ($([math]::Round($_.Length/1KB,2)) KB)" -ForegroundColor DarkGray
    }
} else {
    Write-Host "   未找到自动化系统文件" -ForegroundColor Gray
}
Write-Host ""

# 3. 合并自动化系统脚本
Write-Host "3. 合并自动化系统脚本..." -ForegroundColor Yellow
$ps1Files = $allFiles | Where-Object { $_.Extension -eq ".ps1" -and $_.Name -match "auto-system" }
if ($ps1Files.Count -gt 1) {
    Write-Host "   找到 $($ps1Files.Count) 个自动化系统PowerShell脚本:" -ForegroundColor Gray
    $ps1Files | ForEach-Object {
        Write-Host "   - $($_.Name)" -ForegroundColor DarkGray
    }
    
    # 确定主脚本（auto-system-english.ps1）
    $mainScript = $ps1Files | Where-Object { $_.Name -eq "auto-system-english.ps1" } | Select-Object -First 1
    if ($mainScript) {
        Write-Host "   主脚本: $($mainScript.Name)" -ForegroundColor Green
        
        # 备份其他脚本到archive目录
        $otherScripts = $ps1Files | Where-Object { $_.Name -ne "auto-system-english.ps1" }
        if ($otherScripts.Count -gt 0) {
            Write-Host "   备份 $($otherScripts.Count) 个其他脚本到archive目录..." -ForegroundColor Gray
            foreach ($script in $otherScripts) {
                $backupPath = Join-Path "archive" $script.Name
                Move-Item -Path $script.FullName -Destination $backupPath -Force -ErrorAction SilentlyContinue
                if ($?) {
                    Write-Host "   📦 $($script.Name) → archive/" -ForegroundColor DarkGray
                }
            }
        }
    }
} else {
    Write-Host "   自动化系统脚本已合并" -ForegroundColor Green
}
Write-Host ""

# 4. 重命名文件为更规范的名称
Write-Host "4. 重命名文件..." -ForegroundColor Yellow
$renameMap = @{
    # 简化长文件名
    "AUTOMATION-SYSTEM-FINAL-REPORT.md" = "automation-final-report.md"
    "AUTOMATION-SYSTEM-GUIDE.md" = "automation-guide.md"
    "FINAL-OPTIMIZATION-SUMMARY.md" = "optimization-summary.md"
    "FINAL-SETUP-GUIDE.md" = "setup-guide.md"
    "FINAL-STEP-GUIDE.txt" = "quick-setup.txt"
    "MAINTENANCE-EXECUTION-SUMMARY.md" = "maintenance-summary.md"
    "PROJECT-COMPLETION-REPORT.md" = "project-completion.md"
    "REPORT-SUMMARY-20260308.md" = "report-summary.md"
    "RUN-ME-AS-ADMIN.bat" = "run-as-admin.bat"
    
    # 统一命名风格（小写+连字符）
    "manual-task-setup.bat" = "manual-setup.bat"
    "setup-scheduled-tasks.ps1" = "setup-tasks.ps1"
    "setup-tasks-admin.ps1" = "admin-setup.ps1"
    "setup-tasks-simple.ps1" = "simple-setup.ps1"
    "organize-workspace.ps1" = "organize.ps1"
    "maintenance-schedule.ps1" = "schedule.ps1"
}

$renamedCount = 0
foreach ($oldName in $renameMap.Keys) {
    if (Test-Path $oldName) {
        $newName = $renameMap[$oldName]
        try {
            Rename-Item -Path $oldName -NewName $newName -Force -ErrorAction Stop
            Write-Host "   📝 $oldName → $newName" -ForegroundColor Gray
            $renamedCount++
        } catch {
            Write-Host "   ⚠️  重命名失败: $oldName" -ForegroundColor Yellow
        }
    }
}
Write-Host "   重命名了 $renamedCount 个文件" -ForegroundColor Green
Write-Host ""

# 5. 合并简短的配置文件
Write-Host "5. 合并简短的配置文件..." -ForegroundColor Yellow
$smallFiles = $allFiles | Where-Object { $_.Length -lt 100 }  # 小于100字节的文件
if ($smallFiles.Count -gt 0) {
    Write-Host "   找到 $($smallFiles.Count) 个小文件:" -ForegroundColor Gray
    
    # 创建合并文件
    $mergedContent = "# 合并的小文件 - 生成于 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`n"
    $mergedCount = 0
    
    foreach ($file in $smallFiles) {
        try {
            $content = Get-Content -Path $file.FullName -Raw -ErrorAction Stop
            $mergedContent += "=== $($file.Name) ===`n"
            $mergedContent += "$content`n`n"
            $mergedCount++
        } catch {
            Write-Host "   ⚠️  读取失败: $($file.Name)" -ForegroundColor Yellow
        }
    }
    
    if ($mergedCount -gt 0) {
        $mergedFilePath = "merged-small-files.txt"
        $mergedContent | Out-File -FilePath $mergedFilePath -Encoding UTF8
        Write-Host "   创建合并文件: $mergedFilePath ($mergedCount 个文件)" -ForegroundColor Green
        
        # 移动原文件到archive
        foreach ($file in $smallFiles) {
            $backupPath = Join-Path "archive" $file.Name
            Move-Item -Path $file.FullName -Destination $backupPath -Force -ErrorAction SilentlyContinue
        }
        Write-Host "   原文件已移动到archive目录" -ForegroundColor Gray
    }
} else {
    Write-Host "   没有需要合并的小文件" -ForegroundColor Gray
}
Write-Host ""

# 6. 显示整理后状态
Write-Host "6. 整理后状态:" -ForegroundColor Yellow
Write-Host "   根目录文件数: $((Get-ChildItem -File).Count)" -ForegroundColor Gray
Write-Host "   主要文件列表:" -ForegroundColor Gray
Get-ChildItem -File | Select-Object Name, @{Name="大小(KB)";Expression={[math]::Round($_.Length/1KB,2)}} | Format-Table -AutoSize
Write-Host ""

# 7. 生成整理报告
Write-Host "7. 整理报告:" -ForegroundColor Yellow
$reportTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$originalCount = $allFiles.Count
$currentCount = (Get-ChildItem -File).Count
$reduction = $originalCount - $currentCount

Write-Host "   整理时间: $reportTime" -ForegroundColor Gray
Write-Host "   原始文件数: $originalCount" -ForegroundColor Gray
Write-Host "   当前文件数: $currentCount" -ForegroundColor Gray
Write-Host "   减少文件数: $reduction" -ForegroundColor $(if ($reduction -gt 0) {"Green"} else {"Gray"})
Write-Host "   整理效果: $([math]::Round(($reduction/$originalCount)*100,1))% 减少" -ForegroundColor Gray
Write-Host ""

Write-Host "=== 合并与重命名完成 ===" -ForegroundColor Green
Write-Host "完成时间: $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Gray
Write-Host "工作空间文件已优化整理！" -ForegroundColor Gray