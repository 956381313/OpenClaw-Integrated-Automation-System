# OpenClaw Automation Setup (PowerShell Version)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   OpenClaw Automation Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "ERROR: Please run as Administrator" -ForegroundColor Red
    Write-Host "Right-click this file and select 'Run with PowerShell'" -ForegroundColor Yellow
    Write-Host "or run PowerShell as Administrator first" -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "Setting up OpenClaw automation tasks..." -ForegroundColor Yellow
Write-Host ""

# Get script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# 1. Hourly backup task
Write-Host "[1/4] Creating hourly backup task..." -ForegroundColor Cyan
$backupScript = Join-Path $scriptDir "upload-simple.ps1"
if (Test-Path $backupScript) {
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$backupScript`""
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 1)
    
    try {
        Register-ScheduledTask -TaskName "OpenClaw-AutoBackup" -Action $action -Trigger $trigger -Description "Hourly OpenClaw backup to GitHub" -Force
        Write-Host "  [OK] Task created" -ForegroundColor Green
    } catch {
        Write-Host "  [NOTE] Task may already exist" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [ERROR] Backup script not found: $backupScript" -ForegroundColor Red
}

# 2. Daily security check
Write-Host "[2/4] Creating daily security check..." -ForegroundColor Cyan
$securityScript = Join-Path $scriptDir "09-projects\security-tools\security-check-fixed.ps1"
if (Test-Path $securityScript) {
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$securityScript`""
    $trigger = New-ScheduledTaskTrigger -Daily -At "09:00"
    
    try {
        Register-ScheduledTask -TaskName "OpenClaw-SecurityCheck" -Action $action -Trigger $trigger -Description "Daily OpenClaw security check" -Force
        Write-Host "  [OK] Task created" -ForegroundColor Green
    } catch {
        Write-Host "  [NOTE] Task may already exist" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [SKIP] Security check script not found" -ForegroundColor Yellow
}

# 3. Weekly audit
Write-Host "[3/4] Creating weekly audit..." -ForegroundColor Cyan
$auditScript = Join-Path $scriptDir "09-projects\security-tools\weekly_security_audit.ps1"
if (Test-Path $auditScript) {
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$auditScript`""
    $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At "04:00"
    
    try {
        Register-ScheduledTask -TaskName "OpenClaw-WeeklyAudit" -Action $action -Trigger $trigger -Description "Weekly OpenClaw security audit" -Force
        Write-Host "  [OK] Task created" -ForegroundColor Green
    } catch {
        Write-Host "  [NOTE] Task may already exist" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [SKIP] Audit script not found" -ForegroundColor Yellow
}

# 4. Daily iteration
Write-Host "[4/4] Creating daily iteration..." -ForegroundColor Cyan
$iterationScript = Join-Path $scriptDir "09-projects\iteration\迭代引擎.ps1"
if (Test-Path $iterationScript) {
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$iterationScript`""
    $trigger = New-ScheduledTaskTrigger -Daily -At "02:00"
    
    try {
        Register-ScheduledTask -TaskName "OpenClaw-Iteration" -Action $action -Trigger $trigger -Description "Daily OpenClaw iteration improvement" -Force
        Write-Host "  [OK] Task created" -ForegroundColor Green
    } catch {
        Write-Host "  [NOTE] Task may already exist" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [SKIP] Iteration script not found" -ForegroundColor Yellow
}

# Summary
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Created tasks:" -ForegroundColor Cyan
Write-Host "  • OpenClaw-AutoBackup    - Hourly backup" -ForegroundColor Gray
Write-Host "  • OpenClaw-SecurityCheck - Daily security check (09:00)" -ForegroundColor Gray
Write-Host "  • OpenClaw-WeeklyAudit   - Weekly audit (Sunday 04:00)" -ForegroundColor Gray
Write-Host "  • OpenClaw-Iteration     - Daily iteration (02:00)" -ForegroundColor Gray
Write-Host ""
Write-Host "To test backup now:" -ForegroundColor Yellow
Write-Host "  powershell -ExecutionPolicy Bypass -File upload-simple.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "To manage tasks:" -ForegroundColor Yellow
Write-Host "  # View all tasks" -ForegroundColor Gray
Write-Host "  Get-ScheduledTask | Where-Object {`$_.TaskName -like 'OpenClaw*'}" -ForegroundColor Gray
Write-Host ""
Write-Host "  # Run backup now" -ForegroundColor Gray
Write-Host "  Start-ScheduledTask -TaskName 'OpenClaw-AutoBackup'" -ForegroundColor Gray
Write-Host ""
pause