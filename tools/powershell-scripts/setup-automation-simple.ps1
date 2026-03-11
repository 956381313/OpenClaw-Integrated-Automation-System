# Simple Automation Setup (No Admin Required)

Write-Host "=== OpenClaw Simple Automation Setup ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

Write-Host "This script creates automation configuration files" -ForegroundColor Yellow
Write-Host "that can be used with Windows Task Scheduler." -ForegroundColor Gray
Write-Host ""

# 1. Create automation configuration
Write-Host "1. Creating automation configuration..." -ForegroundColor Yellow

$config = @{
    System = @{
        Name = "OpenClaw Automation System"
        Version = "2.0.0"
        Created = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Description = "OpenClaw automation using English scripts"
    }
    Scripts = @{
        Backup = @{
            Path = "backup-english.ps1"
            Schedule = "hourly"
            Enabled = $true
            Description = "Hourly backup to GitHub"
        }
        SecurityCheck = @{
            Path = "security-check-english.ps1"
            Schedule = "daily 09:00"
            Enabled = $true
            Description = "Daily security check"
        }
        OrganizeAndCleanup = @{
            Path = "organize-and-cleanup.ps1"
            Schedule = "daily 02:00"
            Enabled = $true
            Description = "Daily repository organization and cleanup (combined)"
        }
        KnowledgeBase = @{
            Path = "kb-simple.ps1"
            Schedule = "weekly sunday 03:00"
            Enabled = $true
            Description = "Weekly knowledge base update"
        }
    }
    Monitoring = @{
        LogDirectory = "logs"
        KeepLogsDays = 30
        EmailAlerts = $false
    }
}

$configFile = "automation-config-english.json"
$config | ConvertTo-Json -Depth 4 | Out-File $configFile -Encoding UTF8

Write-Host "  Configuration saved: $configFile" -ForegroundColor Green

# 2. Create batch files for manual execution
Write-Host "`n2. Creating batch files for manual execution..." -ForegroundColor Yellow

# Backup batch file
$backupBatch = @'
@echo off
echo Running OpenClaw Backup...
echo Time: %date% %time%
echo.
powershell -ExecutionPolicy Bypass -File backup-english.ps1
echo.
echo Backup complete!
pause
'@

$backupBatch | Out-File "run-backup.bat" -Encoding ASCII
Write-Host "  Created: run-backup.bat" -ForegroundColor Green

# Security check batch file
$securityBatch = @'
@echo off
echo Running OpenClaw Security Check...
echo Time: %date% %time%
echo.
powershell -ExecutionPolicy Bypass -File security-check-english.ps1
echo.
echo Security check complete!
pause
'@

$securityBatch | Out-File "run-security.bat" -Encoding ASCII
Write-Host "  Created: run-security.bat" -ForegroundColor Green

# Repository organization and cleanup batch file
$orgBatch = @'
@echo off
echo Running OpenClaw Repository Organization and Cleanup...
echo Time: %date% %time%
echo.
powershell -ExecutionPolicy Bypass -File organize-and-cleanup.ps1
echo.
echo Repository organization and cleanup complete!
pause
'@

$orgBatch | Out-File "run-organize-cleanup.bat" -Encoding ASCII
Write-Host "  Created: run-organize-cleanup.bat" -ForegroundColor Green

# Knowledge base batch file
$kbBatch = @'
@echo off
echo Running OpenClaw Knowledge Base Update...
echo Time: %date% %time%
echo.
powershell -ExecutionPolicy Bypass -File kb-simple.ps1
echo.
echo Knowledge base update complete!
pause
'@

$kbBatch | Out-File "run-knowledge.bat" -Encoding ASCII
Write-Host "  Created: run-knowledge.bat" -ForegroundColor Green

# 3. Create monitoring script
Write-Host "`n3. Creating monitoring script..." -ForegroundColor Yellow

$monitorScript = @'
# OpenClaw Automation Monitor
Write-Host "=== OpenClaw Automation Status ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

Write-Host "Available scripts:" -ForegroundColor Yellow
Write-Host "1. Backup: run-backup.bat" -ForegroundColor Gray
Write-Host "2. Security Check: run-security.bat" -ForegroundColor Gray
Write-Host "3. Repository Organization & Cleanup: run-organize-cleanup.bat" -ForegroundColor Gray
Write-Host "4. Knowledge Base: run-knowledge.bat" -ForegroundColor Gray
Write-Host "5. Monitor: monitor-automation-english.ps1" -ForegroundColor Gray
Write-Host ""

Write-Host "Configuration:" -ForegroundColor Yellow
if (Test-Path "automation-config-english.json") {
    $config = Get-Content "automation-config-english.json" | ConvertFrom-Json
    Write-Host "  System: $($config.System.Name)" -ForegroundColor Gray
    Write-Host "  Version: $($config.System.Version)" -ForegroundColor Gray
    Write-Host "  Scripts: $($config.Scripts.Keys.Count)" -ForegroundColor Gray
} else {
    Write-Host "  Configuration file not found" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Quick commands:" -ForegroundColor Cyan
Write-Host "  .\run-backup.bat" -ForegroundColor Gray
Write-Host "  .\run-security.bat" -ForegroundColor Gray
Write-Host "  .\run-organize.bat" -ForegroundColor Gray
Write-Host "  .\run-knowledge.bat" -ForegroundColor Gray
Write-Host "  .\monitor-automation-english.ps1" -ForegroundColor Gray

Write-Host ""
Write-Host "Press Enter to exit..." -ForegroundColor Gray
Read-Host
'@

$monitorScript | Out-File "check-automation.ps1" -Encoding UTF8
Write-Host "  Created: check-automation.ps1" -ForegroundColor Green

# 4. Create setup instructions
Write-Host "`n4. Creating setup instructions..." -ForegroundColor Yellow

$instructions = @'
# OpenClaw Automation Setup Instructions

## Setup Complete!

Your OpenClaw automation system has been configured with English scripts.

## What was created:

### 1. Configuration Files
- `automation-config-english.json` - Main configuration
- Configuration for 4 automation scripts

### 2. Batch Files (Easy to run)
- `run-backup.bat` - Run backup manually
- `run-security.bat` - Run security check manually
- `run-organize.bat` - Run repository organization manually
- `run-knowledge.bat` - Run knowledge base update manually

### 3. Monitoring Tools
- `check-automation.ps1` - Check automation status
- `monitor-automation-english.ps1` - Detailed monitoring

## How to use:

### Manual Execution (No Admin needed):
1. Double-click any `.bat` file to run that automation
2. Or run PowerShell scripts directly

### Recommended daily routine:
1. Morning: Run `run-security.bat` (security check)
2. During day: Run `run-backup.bat` as needed
3. Evening: Run `run-organize.bat` (cleanup)
4. Weekly: Run `run-knowledge.bat` (knowledge update)

### Check status:
- Run `check-automation.ps1` for quick overview
- Run `monitor-automation-english.ps1` for details

## Next steps for full automation:

### Option 1: Windows Task Scheduler (Admin required)
1. Run PowerShell as Administrator
2. Run: `.\update-automation.ps1`
3. This will create scheduled tasks

### Option 2: Manual scheduling
1. Set reminders to run batch files
2. Or use third-party task schedulers

## System Information:
- All scripts are English-only (no encoding issues)
- Configuration is in JSON format
- Logs are saved automatically
- GitHub backup is integrated

## Support:
- Check logs in the `logs` directory
- View configuration in `automation-config-english.json`
- Run monitoring scripts for status

---
*Setup completed: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')*
*OpenClaw Automation System v2.0.0*
'@

$instructions | Out-File "AUTOMATION-SETUP-GUIDE.md" -Encoding UTF8
Write-Host "  Created: AUTOMATION-SETUP-GUIDE.md" -ForegroundColor Green

# Complete
Write-Host "`n=== Setup Complete ===" -ForegroundColor Green
Write-Host "Configuration: $configFile" -ForegroundColor Cyan
Write-Host "Batch files: 4 created" -ForegroundColor Cyan
Write-Host "Monitoring: check-automation.ps1" -ForegroundColor Cyan
Write-Host "Guide: AUTOMATION-SETUP-GUIDE.md" -ForegroundColor Cyan

Write-Host "`nTest the system:" -ForegroundColor Yellow
Write-Host "  .\run-backup.bat" -ForegroundColor Gray
Write-Host "  .\run-security.bat" -ForegroundColor Gray
Write-Host "  .\check-automation.ps1" -ForegroundColor Gray

Write-Host "`nFor full automation (Admin required):" -ForegroundColor Yellow
Write-Host "  .\update-automation.ps1" -ForegroundColor Gray