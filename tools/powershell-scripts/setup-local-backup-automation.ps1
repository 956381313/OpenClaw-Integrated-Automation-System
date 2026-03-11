# Setup Local Backup Automation for GitHub Desktop

Write-Host "=== Setting up Local Backup Automation ===" -ForegroundColor Cyan
Write-Host "Target: GitHub Desktop Local Repository" -ForegroundColor Yellow
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Configuration
$config = @{
    LocalRepoPath = "D:\GitBackups\OpenClaw"
    BackupScript = "local-github-backup.ps1"
    LogsDir = "09-projects\github-backup\logs"
    Schedules = @(
        @{ Name = "DailyBackup"; Time = "03:00"; Type = "daily" },
        @{ Name = "WeeklyFullBackup"; Time = "04:00"; Days = "Sunday"; Type = "weekly" },
        @{ Name = "MonthlyArchive"; Time = "05:00"; Days = "1"; Type = "monthly" }
    )
}

# Step 1: Create repository if needed
Write-Host "1. Setting up local repository..." -ForegroundColor Cyan

if (-not (Test-Path $config.LocalRepoPath)) {
    Write-Host "  Creating repository at: $($config.LocalRepoPath)" -ForegroundColor Gray
    New-Item -ItemType Directory -Path $config.LocalRepoPath -Force | Out-Null
    
    # Initialize with the backup script
    powershell -ExecutionPolicy Bypass -File $config.BackupScript -CreateRepo -BackupName "initial-setup"
    Write-Host "  ✅ Repository created and initialized" -ForegroundColor Green
} else {
    Write-Host "  ✅ Repository already exists: $($config.LocalRepoPath)" -ForegroundColor Green
}

# Step 2: Create backup schedules
Write-Host "`n2. Creating backup schedules..." -ForegroundColor Cyan

foreach ($schedule in $config.Schedules) {
    $taskName = "OpenClaw-$($schedule.Name)"
    $taskCommand = "powershell -ExecutionPolicy Bypass -File `"$PWD\$($config.BackupScript)`" -AutoCommit"
    
    # Add schedule-specific parameters
    switch ($schedule.Type) {
        "daily" {
            $taskCommand += " -BackupName `"daily-$(Get-Date -Format 'yyyyMMdd')`""
        }
        "weekly" {
            $taskCommand += " -BackupName `"weekly-$(Get-Date -Format 'yyyyMMdd')`""
        }
        "monthly" {
            $taskCommand += " -BackupName `"monthly-$(Get-Date -Format 'yyyyMM')`""
        }
    }
    
    Write-Host "  Creating task: $taskName" -ForegroundColor Gray
    Write-Host "    Time: $($schedule.Time)" -ForegroundColor DarkGray
    Write-Host "    Command: $taskCommand" -ForegroundColor DarkGray
    
    # Create scheduled task
    $taskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$PWD\$($config.BackupScript)`" -AutoCommit"
    
    $taskTrigger = switch ($schedule.Type) {
        "daily" {
            New-ScheduledTaskTrigger -Daily -At $schedule.Time
        }
        "weekly" {
            New-ScheduledTaskTrigger -Weekly -DaysOfWeek $schedule.Days -At $schedule.Time
        }
        "monthly" {
            New-ScheduledTaskTrigger -Monthly -DaysOfMonth $schedule.Days -At $schedule.Time
        }
    }
    
    $taskPrincipal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    try {
        Register-ScheduledTask -TaskName $taskName -Action $taskAction -Trigger $taskTrigger -Principal $taskPrincipal -Description "OpenClaw Local Backup: $($schedule.Type) backup" -Force
        Write-Host "    ✅ Scheduled task created" -ForegroundColor Green
    } catch {
        Write-Host "    ⚠️ Could not create task: $_" -ForegroundColor Yellow
    }
}

# Step 3: Create monitoring script
Write-Host "`n3. Creating monitoring system..." -ForegroundColor Cyan

$monitorScript = @"
# OpenClaw Local Backup Monitor

param(
    [switch]$CheckStatus,
    [switch]$GenerateReport,
    [switch]$FixIssues
)

Write-Host "=== OpenClaw Local Backup Monitor ===" -ForegroundColor Cyan
Write-Host "Time: `$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Configuration
`$LocalRepoPath = "$($config.LocalRepoPath)"
`$LogsDir = "$($config.LogsDir)"

if (-not (Test-Path `$LogsDir)) {
    New-Item -ItemType Directory -Path `$LogsDir -Force | Out-Null
}

if (`$CheckStatus) {
    Write-Host "1. Checking backup status..." -ForegroundColor Cyan
    
    # Check repository
    if (Test-Path `$LocalRepoPath) {
        Write-Host "  ✅ Repository exists: `$LocalRepoPath" -ForegroundColor Green
        
        # Check Git status
        Set-Location `$LocalRepoPath
        `$commitCount = git log --oneline | Measure-Object | Select-Object -ExpandProperty Count
        Set-Location `$PSScriptRoot
        
        Write-Host "  📊 Commits in repository: `$commitCount" -ForegroundColor Gray
        
        # Check last backup
        `$backupDirs = Get-ChildItem -Path "`$LocalRepoPath\backups" -Directory -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
        if (`$backupDirs) {
            `$lastBackup = `$backupDirs[0]
            `$lastBackupTime = `$lastBackup.LastWriteTime
            `$hoursSince = [math]::Round(((Get-Date) - `$lastBackupTime).TotalHours, 1)
            
            Write-Host "  ⏰ Last backup: `$lastBackupTime (`$hoursSince hours ago)" -ForegroundColor Gray
            
            if (`$hoursSince -gt 24) {
                Write-Host "  ⚠️ Last backup was more than 24 hours ago" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "  ❌ Repository not found: `$LocalRepoPath" -ForegroundColor Red
    }
    
    # Check scheduled tasks
    Write-Host "`n2. Checking scheduled tasks..." -ForegroundColor Cyan
    
    `$tasks = @("OpenClaw-DailyBackup", "OpenClaw-WeeklyFullBackup", "OpenClaw-MonthlyArchive")
    
    foreach (`$task in `$tasks) {
        `$taskInfo = Get-ScheduledTask -TaskName `$task -ErrorAction SilentlyContinue
        if (`$taskInfo) {
            Write-Host "  ✅ Task exists: `$task" -ForegroundColor Green
            Write-Host "    State: `$(`$taskInfo.State)" -ForegroundColor DarkGray
        } else {
            Write-Host "  ❌ Task missing: `$task" -ForegroundColor Red
        }
    }
}

if (`$GenerateReport) {
    Write-Host "`n3. Generating report..." -ForegroundColor Cyan
    
    `$report = @"
# 📊 OpenClaw Local Backup Status Report

## Report Time
- **Generated**: `$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
- **System**: Local GitHub Desktop Backup

## Repository Status
- **Path**: `$LocalRepoPath
- **Exists**: `$(if (Test-Path `$LocalRepoPath) { "Yes" } else { "No" })
- **Size**: `$(if (Test-Path `$LocalRepoPath) { [math]::Round((Get-ChildItem -Path `$LocalRepoPath -Recurse | Measure-Object Length -Sum).Sum / 1MB, 2) } else { 0 }) MB

## Backup History
`$(if (Test-Path "`$LocalRepoPath\backups") {
    `$backups = Get-ChildItem -Path "`$LocalRepoPath\backups" -Directory | Sort-Object Name -Descending | Select-Object -First 10
    "| Backup Name | Date | Files | Size |`n|---|---|---|---|"
    foreach (`$backup in `$backups) {
        `$files = Get-ChildItem -Path `$backup.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object
        `$size = [math]::Round((Get-ChildItem -Path `$backup.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum / 1KB, 2)
        "| `$(`$backup.Name) | `$(`$backup.CreationTime) | `$(`$files.Count) | `$size KB |"
    }
} else {
    "No backups found"
})

## Scheduled Tasks
`$(`$tasks = @("OpenClaw-DailyBackup", "OpenClaw-WeeklyFullBackup", "OpenClaw-MonthlyArchive")
`$taskReport = ""
foreach (`$task in `$tasks) {
    `$taskInfo = Get-ScheduledTask -TaskName `$task -ErrorAction SilentlyContinue
    if (`$taskInfo) {
        `$taskReport += "- **`$task**: `$(`$taskInfo.State)`n"
    } else {
        `$taskReport += "- **`$task**: ❌ Missing`n"
    }
}
`$taskReport)

## Recommendations
1. Ensure GitHub Desktop has the repository added
2. Check backup logs for any errors
3. Verify automated tasks are running
4. Test restore process periodically

---
*Report generated by OpenClaw Backup Monitor*
"@
    
    `$reportFile = "`$LogsDir\backup-status-`$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
    `$report | Out-File `$reportFile -Encoding UTF8
    Write-Host "  ✅ Report saved: `$reportFile" -ForegroundColor Green
}

if (`$FixIssues) {
    Write-Host "`n4. Fixing common issues..." -ForegroundColor Cyan
    
    # Fix repository if missing
    if (-not (Test-Path `$LocalRepoPath)) {
        Write-Host "  Creating missing repository..." -ForegroundColor Gray
        New-Item -ItemType Directory -Path `$LocalRepoPath -Force | Out-Null
        powershell -ExecutionPolicy Bypass -File "$PWD\$($config.BackupScript)" -CreateRepo
    }
    
    # Recreate missing tasks
    `$missingTasks = @()
    `$allTasks = @("OpenClaw-DailyBackup", "OpenClaw-WeeklyFullBackup", "OpenClaw-MonthlyArchive")
    
    foreach (`$task in `$allTasks) {
        if (-not (Get-ScheduledTask -TaskName `$task -ErrorAction SilentlyContinue)) {
            `$missingTasks += `$task
        }
    }
    
    if (`$missingTasks) {
        Write-Host "  Recreating missing tasks..." -ForegroundColor Gray
        powershell -ExecutionPolicy Bypass -File "`$PSScriptRoot\setup-local-backup-automation.ps1"
    }
}

Write-Host "`n=== Monitor Complete ===" -ForegroundColor Green
Write-Host "Use -CheckStatus to check backup status" -ForegroundColor Gray
Write-Host "Use -GenerateReport to create detailed report" -ForegroundColor Gray
Write-Host "Use -FixIssues to fix common problems" -ForegroundColor Gray
"@

$monitorScript | Out-File "monitor-local-backup.ps1" -Encoding UTF8
Write-Host "  ✅ Monitor script created: monitor-local-backup.ps1" -ForegroundColor Green

# Step 4: Create quick start guide
Write-Host "`n4. Creating documentation..." -ForegroundColor Cyan

$guide = @"
# 🚀 OpenClaw Local GitHub Desktop Backup Guide

## Overview
This system provides automated local backups using GitHub Desktop as the management interface. All backups are stored in a local Git repository that you can open in GitHub Desktop.

## Quick Start

### 1. First Time Setup
```powershell
# Run the setup script
powershell -ExecutionPolicy Bypass -File setup-local-backup-automation.ps1

# Create initial backup
powershell -ExecutionPolicy Bypass -File local-github-backup.ps1 -CreateRepo -AutoCommit
```

### 2. Open in GitHub Desktop
1. Open GitHub Desktop
2. Click "File" → "Add Local Repository"
3. Browse to: $($config.LocalRepoPath)
4. Click "Add Repository"

### 3. Manual Backup
```powershell
# Quick backup
powershell -File local-github-backup.ps1 -AutoCommit

# Custom backup name
powershell -File local-github-backup.ps1 -BackupName "my-backup" -AutoCommit
```

### 4. Monitor System
```powershell
# Check status
powershell -File monitor-local-backup.ps1 -CheckStatus

# Generate report
powershell -File monitor-local-backup.ps1 -GenerateReport

# Fix issues
powershell -File monitor-local-backup.ps1 -FixIssues
```

## Backup Schedule
- **Daily**: 3:00 AM (incremental)
- **Weekly**: Sunday 4:00 AM (full backup)
- **Monthly**: 1st day 5:00 AM (archive)

## File Structure
```
$($config.LocalRepoPath)/
├── backups/
│   ├── daily-20260305/
│   ├── weekly-20260305/
│   └── monthly-202603/
├── README.md
└── backup-manifest.json
```

## Restoring Backups
1. In GitHub Desktop, checkout the desired commit
2. Copy files from the backup directory
3. Or use Git commands directly

## Troubleshooting

### Problem: Backups not running
```powershell
# Check scheduled tasks
Get-ScheduledTask -TaskName "OpenClaw-*"

# Run manual backup
powershell -File local-github-backup.ps1 -AutoCommit
```

### Problem: GitHub Desktop doesn't show history
```powershell
# Check Git status
cd $($config.LocalRepoPath)
git log --oneline

# Force refresh in GitHub Desktop
# Close and reopen the repository
```

### Problem: Repository corrupted
```powershell
# Recreate repository
Remove-Item $($config.LocalRepoPath) -Recurse -Force
powershell -File local-github-backup.ps1 -CreateRepo -AutoCommit
```

## Advanced Usage

### Custom Backup Location
```powershell
powershell -File local-github-backup.ps1 -LocalRepoPath "E:\MyBackups\OpenClaw" -CreateRepo
```

### Backup Specific Categories
Modify the `local-github-backup.ps1` script to change what gets backed up.

### Integration with Cloud Backup
Use the local repository as source for cloud backup systems.

## Support
- Check logs: $($config.LogsDir)
- Monitor: Run the monitor script regularly
- GitHub Desktop: Use for visual history browsing

---
*System configured: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')*
"@

$guide | Out-File "LOCAL-BACKUP-GUIDE.md" -Encoding UTF8
Write-Host "  ✅ Guide created: LOCAL-BACKUP-GUIDE.md" -ForegroundColor Green

Write-Host "`n=== Setup Complete ===" -ForegroundColor Green
Write-Host "✅ Local GitHub Desktop backup system configured!" -ForegroundColor Green
Write-Host "`n📋 What was set up:" -ForegroundColor Cyan
Write-Host "1. Local repository at: $($config.LocalRepoPath)" -ForegroundColor Gray
Write-Host "2. Backup script: local-github-backup.ps1" -ForegroundColor Gray
Write-Host "3. Monitor script: monitor-local-backup.ps1" -ForegroundColor Gray
Write-Host "4. Scheduled tasks for automation" -ForegroundColor Gray
Write-Host "5. Complete documentation" -ForegroundColor Gray
Write-Host "`n🚀 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Run initial backup: powershell -File local-github-backup.ps1 -CreateRepo -AutoCommit" -ForegroundColor Gray
Write-Host "2. Open GitHub Desktop and add the repository" -ForegroundColor Gray
Write-Host "3. Test the monitor: powershell -File monitor-local-backup.ps1 -CheckStatus" -ForegroundColor Gray
Write-Host "`n📚 Read the guide: LOCAL-BACKUP-GUIDE.md" -ForegroundColor Magenta