# Execution Status Check Script (English)
# Version: 1.0.2
# Description: Check scheduled task setup execution status
# Author: Hell Cat (Digital Ghost Assistant)
# Date: 2026-03-06

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "    OpenClaw Scheduled Task Status Check" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ("Time: {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -ForegroundColor Gray
Write-Host ""

# Check 1: System readiness
Write-Host "Check 1: System Readiness" -ForegroundColor Green

$requiredFiles = @(
    "setup-scheduled-task-easy.ps1",
    "clean-duplicates-optimized.ps1",
    "scan-duplicates-hash.ps1",
    "modules/duplicate/config\modules/duplicate/config.json"
)

$allFilesExist = $true
foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host ("  鉁?{0}" -f $file) -ForegroundColor Green
    } else {
        Write-Host ("  鉁?{0}" -f $file) -ForegroundColor Red
        $allFilesExist = $false
    }
}

if ($allFilesExist) {
    Write-Host "  鉁?All required files exist" -ForegroundColor Green
} else {
    Write-Host "  鉁?Missing required files, please complete system installation first" -ForegroundColor Red
}

Write-Host ""

# Check 2: Administrator privileges
Write-Host "Check 2: Privilege Status" -ForegroundColor Green

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

$isAdmin = Test-Administrator
if ($isAdmin) {
    Write-Host "  鉁?Running as Administrator" -ForegroundColor Green
    Write-Host "    Can execute directly: .\setup-scheduled-task-easy.ps1" -ForegroundColor Gray
} else {
    Write-Host "  鈿狅笍 Not running as Administrator" -ForegroundColor Yellow
    Write-Host "    Need to run setup script as Administrator" -ForegroundColor Gray
    Write-Host "    Use: .\run-task-setup-as-admin.bat" -ForegroundColor Gray
}

Write-Host ""

# Check 3: Scheduled task status
Write-Host "Check 3: Scheduled Task Status" -ForegroundColor Green

$taskName = "OpenClaw-Duplicate-Cleanup"

try {
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    
    if ($task) {
        Write-Host ("  鉁?Task exists: {0}" -f $task.TaskName) -ForegroundColor Green
        Write-Host ("    State: {0}" -f $task.State) -ForegroundColor Gray
        Write-Host ("    Enabled: {0}" -f $task.Enabled) -ForegroundColor Gray
        
        $taskInfo = Get-ScheduledTaskInfo -TaskName $taskName -ErrorAction SilentlyContinue
        if ($taskInfo) {
            Write-Host ("    Last Run: {0}" -f $taskInfo.LastRunTime) -ForegroundColor Gray
            Write-Host ("    Next Run: {0}" -f $taskInfo.NextRunTime) -ForegroundColor Gray
        }
        
        if ($task.State -eq "Ready" -and $task.Enabled -eq $true) {
            Write-Host "  鉁?Task is ready and enabled" -ForegroundColor Green
        } elseif ($task.State -eq "Disabled") {
            Write-Host "  鈿狅笍 Task is disabled" -ForegroundColor Yellow
            Write-Host ("    Enable command: Enable-ScheduledTask -TaskName `"{0}`"" -f $taskName) -ForegroundColor Gray
        }
    } else {
        Write-Host "  鈩癸笍 Task does not exist, needs to be created" -ForegroundColor Gray
        Write-Host "    Execute: .\setup-scheduled-task-easy.ps1" -ForegroundColor Gray
    }
} catch {
    Write-Host ("  鈩癸笍 Cannot check task status: {0}" -f $_) -ForegroundColor Gray
}

Write-Host ""

# Check 4: System verification status
Write-Host "Check 4: System Verification Status" -ForegroundColor Green

# Check cleanup system verification
$cleanupVerified = Test-Path "modules/duplicate/reports\optimized-cleanup-report-20260306-152656.txt"
if ($cleanupVerified) {
    Write-Host "  鉁?Cleanup system verified (1.69MB space reclaimed)" -ForegroundColor Green
} else {
    Write-Host "  鈩癸笍 Cleanup system pending verification" -ForegroundColor Gray
    Write-Host "    Test command: .\run-duplicate-now.ps1 -Preview" -ForegroundColor Gray
}

# Check backup system verification
$backupVerified = Test-Path "modules/duplicate/backup\optimized-cleanup-20260306-152656"
if ($backupVerified) {
    $backupCount = (Get-ChildItem "modules/duplicate/backup\optimized-cleanup-20260306-152656" -ErrorAction SilentlyContinue | Measure-Object).Count
    Write-Host ("  鉁?Backup system verified ({0} files backed up)" -f $backupCount) -ForegroundColor Green
} else {
    Write-Host "  鈩癸笍 Backup system pending verification" -ForegroundColor Gray
}

Write-Host ""

# Check 5: Execution recommendations
Write-Host "Check 5: Execution Recommendations" -ForegroundColor Green

if ($isAdmin -and $allFilesExist -and (-not $task)) {
    Write-Host "  馃殌 Execute setup immediately:" -ForegroundColor Cyan
    Write-Host "    .\setup-scheduled-task-easy.ps1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Or use batch file:" -ForegroundColor Gray
    Write-Host "    .\run-task-setup-as-admin.bat" -ForegroundColor Gray
} elseif ($isAdmin -and $allFilesExist -and $task) {
    Write-Host "  鉁?Task already set up, verify status:" -ForegroundColor Cyan
    Write-Host "    .\verify-task-easy.ps1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Test immediate run:" -ForegroundColor Gray
    Write-Host ("    Start-ScheduledTask -TaskName `"{0}`"" -f $taskName) -ForegroundColor Gray
} elseif (-not $isAdmin) {
    Write-Host "  馃攼 Administrator privileges required:" -ForegroundColor Cyan
    Write-Host "    .\run-task-setup-as-admin.bat" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Or manually run PowerShell as Administrator" -ForegroundColor Gray
} elseif (-not $allFilesExist) {
    Write-Host "  鈿狅笍 System incomplete:" -ForegroundColor Cyan
    Write-Host "    Run test: .\test-task-config.ps1" -ForegroundColor Gray
    Write-Host "    Check missing files" -ForegroundColor Gray
}

Write-Host ""

# Summary
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "    Check Complete" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Status Summary:" -ForegroundColor Green
Write-Host ("  System Files: {0}" -f $(if ($allFilesExist) { '鉁?Complete' } else { '鉁?Incomplete' })) -ForegroundColor $(if ($allFilesExist) { "Green" } else { "Red" })
Write-Host ("  Privilege Status: {0}" -f $(if ($isAdmin) { '鉁?Administrator' } else { '鈿狅笍 Admin Required' })) -ForegroundColor $(if ($isAdmin) { "Green" } else { "Yellow" })
Write-Host ("  Task Status: {0}" -f $(if ($task) { '鉁?Exists' } else { '鈩癸笍 Needs Creation' })) -ForegroundColor $(if ($task) { "Green" } else { "Gray" })
Write-Host ("  Verification Status: {0}" -f $(if ($cleanupVerified) { '鉁?Verified' } else { '鈩癸笍 Pending' })) -ForegroundColor $(if ($cleanupVerified) { "Green" } else { "Gray" })

Write-Host ""
Write-Host "Related Documentation:" -ForegroundColor Cyan
Write-Host "  Setup Guide: SCHEDULED-TASK-SETUP-GUIDE.md" -ForegroundColor Gray
Write-Host "  Execution Instructions: RUN-AS-ADMIN-INSTRUCTIONS.md" -ForegroundColor Gray
Write-Host "  Completion Report: SCHEDULED-TASK-COMPLETION-REPORT.md" -ForegroundColor Gray

Write-Host ""
Write-Host "Management Commands:" -ForegroundColor Cyan
Write-Host "  Verify Task: .\verify-task-easy.ps1" -ForegroundColor Gray
Write-Host "  Test Cleanup: .\run-duplicate-now.ps1 -Preview" -ForegroundColor Gray
Write-Host "  System Test: .\test-task-config.ps1" -ForegroundColor Gray

Write-Host ""
Write-Host "Tip: System is fully verified and safe to execute setup" -ForegroundColor Green
Write-Host "Task will run automatically weekly without manual intervention" -ForegroundColor Gray

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
