# OpenClaw 自动化备份计划任务配置

Write-Host "=== OpenClaw 自动化备份计划任务 ===" -ForegroundColor Cyan
Write-Host "将创建每小时自动备份任务" -ForegroundColor Yellow
Write-Host ""

# 配置
$TaskName = "OpenClaw-AutoBackup"
$TaskDescription = "每小时自动备份OpenClaw系统到GitHub"
$ScriptPath = Join-Path $PWD "auto-backup-system.ps1"
$LogPath = "D:\OpenClaw-AutoBackup\task-log.txt"

# 检查脚本是否存在
if (-not (Test-Path $ScriptPath)) {
    Write-Host "错误: 找不到备份脚本: $ScriptPath" -ForegroundColor Red
    exit 1
}

# 创建日志目录
$logDir = Split-Path $LogPath -Parent
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    Write-Host "创建日志目录: $logDir" -ForegroundColor Green
}

# 1. 检查是否已存在任务
Write-Host "1. 检查现有任务..." -ForegroundColor Cyan
$existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if ($existingTask) {
    Write-Host "  发现现有任务，正在删除..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "  现有任务已删除" -ForegroundColor Green
}

# 2. 创建触发器（每小时运行一次）
Write-Host "2. 创建触发器..." -ForegroundColor Cyan
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 1) -RepetitionDuration (New-TimeSpan -Days 3650)

# 3. 创建操作（运行PowerShell脚本）
Write-Host "3. 创建操作..." -ForegroundColor Cyan
$action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`"" `
    -WorkingDirectory $PWD

# 4. 创建设置
Write-Host "4. 创建任务设置..." -ForegroundColor Cyan
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -WakeToRun `
    -MultipleInstances IgnoreNew `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 5)

# 5. 注册任务
Write-Host "5. 注册计划任务..." -ForegroundColor Cyan
try {
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    Register-ScheduledTask `
        -TaskName $TaskName `
        -Description $TaskDescription `
        -Trigger $trigger `
        -Action $action `
        -Settings $settings `
        -Principal $principal `
        -Force
    
    Write-Host "  ✅ 计划任务创建成功!" -ForegroundColor Green
    
    # 立即启动一次测试
    Write-Host "6. 立即启动测试运行..." -ForegroundColor Cyan
    Start-ScheduledTask -TaskName $TaskName
    Write-Host "  ✅ 测试运行已启动" -ForegroundColor Green
    
} catch {
    Write-Host "  ❌ 计划任务创建失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 6. 显示任务信息
Write-Host "`n=== 计划任务信息 ===" -ForegroundColor Green
$taskInfo = Get-ScheduledTask -TaskName $TaskName
Write-Host "任务名称: $($taskInfo.TaskName)" -ForegroundColor Cyan
Write-Host "任务描述: $($taskInfo.Description)" -ForegroundColor Cyan
Write-Host "任务状态: $($taskInfo.State)" -ForegroundColor Cyan
Write-Host "下次运行: $($taskInfo.NextRunTime)" -ForegroundColor Cyan
Write-Host "触发器: 每小时运行一次" -ForegroundColor Cyan

# 7. 创建管理脚本
Write-Host "`n7. 创建管理脚本..." -ForegroundColor Cyan

# 创建任务管理脚本
$manageScript = @'
# OpenClaw 备份任务管理器

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("status", "start", "stop", "run", "delete", "log")]
    [string]$Action = "status"
)

$TaskName = "OpenClaw-AutoBackup"

switch ($Action) {
    "status" {
        Write-Host "=== OpenClaw 备份任务状态 ===" -ForegroundColor Cyan
        try {
            $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop
            Write-Host "任务名称: $($task.TaskName)" -ForegroundColor Green
            Write-Host "任务状态: $($task.State)" -ForegroundColor Green
            Write-Host "下次运行: $($task.NextRunTime)" -ForegroundColor Green
            Write-Host "最后运行: $($task.LastRunTime)" -ForegroundColor Green
            Write-Host "最后结果: $($task.LastTaskResult)" -ForegroundColor Green
        } catch {
            Write-Host "任务不存在或无法访问" -ForegroundColor Red
        }
    }
    
    "start" {
        Write-Host "启动备份任务..." -ForegroundColor Yellow
        Start-ScheduledTask -TaskName $TaskName
        Write-Host "✅ 任务已启动" -ForegroundColor Green
    }
    
    "stop" {
        Write-Host "停止备份任务..." -ForegroundColor Yellow
        Stop-ScheduledTask -TaskName $TaskName
        Write-Host "✅ 任务已停止" -ForegroundColor Green
    }
    
    "run" {
        Write-Host "立即运行备份任务..." -ForegroundColor Yellow
        Start-ScheduledTask -TaskName $TaskName
        Write-Host "✅ 任务已启动" -ForegroundColor Green
    }
    
    "delete" {
        Write-Host "删除备份任务..." -ForegroundColor Red
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-Host "✅ 任务已删除" -ForegroundColor Green
    }
    
    "log" {
        $logPath = "D:\OpenClaw-AutoBackup\task-log.txt"
        if (Test-Path $logPath) {
            Write-Host "=== 任务日志 ===" -ForegroundColor Cyan
            Get-Content $logPath -Tail 20
        } else {
            Write-Host "日志文件不存在: $logPath" -ForegroundColor Yellow
        }
    }
}
'@

$manageScript | Out-File "manage-backup-task.ps1" -Encoding UTF8
Write-Host "  ✅ 管理脚本创建完成: manage-backup-task.ps1" -ForegroundColor Green

# 8. 创建使用说明
Write-Host "`n8. 创建使用说明..." -ForegroundColor Cyan

$usageGuide = @'
# OpenClaw 自动化备份系统使用指南

## 🚀 已配置的功能

### 1. 自动化备份任务
- **任务名称**: OpenClaw-AutoBackup
- **运行频率**: 每小时一次
- **运行账户**: SYSTEM (最高权限)
- **备份位置**: D:\OpenClaw-AutoBackup\
- **GitHub同步**: 自动上传到 https://github.com/956381313/OpenClaw

### 2. 管理命令

```powershell
# 查看任务状态
.\manage-backup-task.ps1 status

# 立即运行备份
.\manage-backup-task.ps1 run

# 停止任务
.\manage-backup-task.ps1 stop

# 启动任务
.\manage-backup-task.ps1 start

# 查看日志
.\manage-backup-task.ps1 log

# 删除任务
.\manage-backup-task.ps1 delete
```

### 3. 手动运行备份
```powershell
# 手动运行完整备份
.\auto-backup-system.ps1
```

## 📁 备份目录结构
```
D:\OpenClaw-AutoBackup\
├── openclaw-auto-20260305-223000\  # 每次备份一个目录
│   ├── openclaw.json
│   ├── gateway.cmd
│   ├── AGENTS.md
│   ├── SOUL.md
│   ├── backup-info.json
│   └── backup-report.md
├── backup-log.txt                  # 系统日志
└── task-log.txt                    # 任务日志
```

## 🔄 GitHub同步
- 每次备份自动提交到GitHub
- 备份目录: `auto-backups/`
- 在线查看: https://github.com/956381313/OpenClaw/tree/main/auto-backups

## ⚙️ 配置选项
编辑 `auto-backup-system.ps1` 修改:
- `MaxBackups`: 保留的备份数量 (默认: 30)
- `BackupRoot`: 备份根目录
- `GitHubRepo`: GitHub仓库地址

## 📊 监控和故障排除

### 查看任务状态:
1. 打开"任务计划程序"
2. 导航到: 任务计划程序库 → OpenClaw-AutoBackup
3. 查看"历史记录"标签页

### 常见问题:
1. **任务不运行**: 检查系统时间，确保不是休眠状态
2. **GitHub上传失败**: 检查网络连接，备份会保存在本地
3. **权限问题**: 以管理员身份运行管理脚本

## 🆘 紧急恢复
如果自动化系统失效，手动运行:
```powershell
# 停止所有任务
.\manage-backup-task.ps1 stop

# 删除任务
.\manage-backup-task.ps1 delete

# 重新安装
.\setup-auto-backup-task.ps1
```

## 📞 支持
- 日志文件: D:\OpenClaw-AutoBackup\backup-log.txt
- GitHub仓库: https://github.com/956381313/OpenClaw
- 备份报告: 每次备份生成 backup-report.md
'@

$usageGuide | Out-File "自动化备份使用指南.md" -Encoding UTF8
Write-Host "  ✅ 使用指南创建完成: 自动化备份使用指南.md" -ForegroundColor Green

# 最终总结
Write-Host "`n=== 自动化备份系统配置完成 ===" -ForegroundColor Green
Write-Host "✅ 计划任务已创建: OpenClaw-AutoBackup" -ForegroundColor Cyan
Write-Host "✅ 管理脚本已创建: manage-backup-task.ps1" -ForegroundColor Cyan
Write-Host "✅ 使用指南已创建: 自动化备份使用指南.md" -ForegroundColor Cyan
Write-Host "✅ 备份目录: D:\OpenClaw-AutoBackup\" -ForegroundColor Cyan
Write-Host "✅ 运行频率: 每小时一次" -ForegroundColor Cyan
Write-Host "✅ GitHub同步: 自动上传" -ForegroundColor Cyan

Write-Host "`n📋 立即测试:" -ForegroundColor Yellow
Write-Host "  .\manage-backup-task.ps1 status    # 查看状态" -ForegroundColor Gray
Write-Host "  .\manage-backup-task.ps1 run      # 立即运行" -ForegroundColor Gray
Write-Host "  .\manage-backup-task.ps1 log      # 查看日志" -ForegroundColor Gray

Write-Host "`n💡 提示: 任务将在每小时的第0分钟运行" -ForegroundColor Magenta
Write-Host "   例如: 23:00, 00:00, 01:00, ..." -ForegroundColor Magenta