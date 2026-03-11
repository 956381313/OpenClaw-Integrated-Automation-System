# OpenClaw 自动化备份简单配置

Write-Host "=== OpenClaw 自动化备份配置 ===" -ForegroundColor Cyan
Write-Host "创建每小时自动备份" -ForegroundColor Yellow
Write-Host ""

# 配置
$TaskName = "OpenClaw-AutoBackup"
$TaskDescription = "每小时自动备份OpenClaw系统"
$ScriptPath = Join-Path $PWD "auto-backup-system.ps1"

# 检查脚本
if (-not (Test-Path $ScriptPath)) {
    Write-Host "错误: 找不到备份脚本" -ForegroundColor Red
    exit 1
}

Write-Host "1. 检查现有任务..." -ForegroundColor Cyan
$existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if ($existingTask) {
    Write-Host "  删除现有任务..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "  ✅ 现有任务已删除" -ForegroundColor Green
}

# 创建触发器（每小时运行）
Write-Host "2. 创建触发器..." -ForegroundColor Cyan
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 1)

# 创建操作
Write-Host "3. 创建操作..." -ForegroundColor Cyan
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`""

# 创建设置
Write-Host "4. 创建设置..." -ForegroundColor Cyan
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

# 注册任务
Write-Host "5. 注册任务..." -ForegroundColor Cyan
try {
    Register-ScheduledTask -TaskName $TaskName -Description $TaskDescription -Trigger $trigger -Action $action -Settings $settings -Force
    Write-Host "  ✅ 计划任务创建成功!" -ForegroundColor Green
} catch {
    Write-Host "  ❌ 任务创建失败: $_" -ForegroundColor Red
    exit 1
}

# 显示信息
Write-Host "`n=== 配置完成 ===" -ForegroundColor Green
Write-Host "任务名称: $TaskName" -ForegroundColor Cyan
Write-Host "运行频率: 每小时一次" -ForegroundColor Cyan
Write-Host "备份脚本: $ScriptPath" -ForegroundColor Cyan
Write-Host "备份目录: D:\OpenClaw-AutoBackup\" -ForegroundColor Cyan

Write-Host "`n📋 管理命令:" -ForegroundColor Yellow
Write-Host "  # 查看状态" -ForegroundColor Gray
Write-Host "  Get-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Gray
Write-Host "  " -ForegroundColor Gray
Write-Host "  # 立即运行" -ForegroundColor Gray
Write-Host "  Start-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Gray
Write-Host "  " -ForegroundColor Gray
Write-Host "  # 停止任务" -ForegroundColor Gray
Write-Host "  Stop-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Gray

Write-Host "`n🚀 自动化备份系统已就绪!" -ForegroundColor Green