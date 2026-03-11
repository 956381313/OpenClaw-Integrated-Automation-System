# Update Windows Task Scheduler for combined organize and cleanup task
# This script updates the scheduled task to use the new combined script

Write-Host "=== Update Organize and Cleanup Task ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "ERROR: This script requires Administrator rights" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Right-click PowerShell -> Run as Administrator" -ForegroundColor Gray
    Write-Host "Then run: .\update-organize-task.ps1" -ForegroundColor Gray
    exit 1
}

Write-Host "Running as Administrator" -ForegroundColor Green
Write-Host ""

# Check if old task exists
$oldTaskName = "OpenClaw-RepositoryOrg"
$newTaskName = "OpenClaw-OrganizeAndCleanup"

Write-Host "1. Checking existing tasks..." -ForegroundColor Yellow

try {
    $oldTask = Get-ScheduledTask -TaskName $oldTaskName -ErrorAction SilentlyContinue
    $newTask = Get-ScheduledTask -TaskName $newTaskName -ErrorAction SilentlyContinue
    
    if ($oldTask) {
        Write-Host "   Found old task: $oldTaskName" -ForegroundColor Yellow
        Write-Host "   State: $($oldTask.State)" -ForegroundColor Gray
    } else {
        Write-Host "   Old task not found: $oldTaskName" -ForegroundColor Gray
    }
    
    if ($newTask) {
        Write-Host "   Found new task: $newTaskName" -ForegroundColor Green
        Write-Host "   State: $($newTask.State)" -ForegroundColor Gray
    } else {
        Write-Host "   New task not found: $newTaskName" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "   ERROR: Cannot access scheduled tasks" -ForegroundColor Red
    Write-Host "   $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Get workspace path
$workspacePath = "C:\Users\luchaochao\.openclaw\workspace"
if (-not (Test-Path $workspacePath)) {
    Write-Host "ERROR: Workspace not found: $workspacePath" -ForegroundColor Red
    exit 1
}

Write-Host "`n2. Checking script files..." -ForegroundColor Yellow

$scriptPath = Join-Path $workspacePath "organize-and-cleanup.ps1"
$batchPath = Join-Path $workspacePath "run-organize-cleanup.bat"

if (-not (Test-Path $scriptPath)) {
    Write-Host "   ERROR: Main script not found: $scriptPath" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $batchPath)) {
    Write-Host "   WARNING: Batch file not found: $batchPath" -ForegroundColor Yellow
    Write-Host "   Creating batch file..." -ForegroundColor Gray
    
    $batchContent = @'
@echo off
chcp 65001 >nul
echo ========================================
echo OpenClaw Organize and Cleanup System
echo ========================================
echo.
echo Starting combined repository organization and cleanup...
echo.

powershell -ExecutionPolicy Bypass -File "organize-and-cleanup.ps1"

echo.
echo ========================================
echo Execution completed
echo ========================================
echo.
pause
'@
    
    $batchContent | Out-File -FilePath $batchPath -Encoding ASCII
    Write-Host "   Created: $batchPath" -ForegroundColor Green
}

Write-Host "   Main script: $scriptPath" -ForegroundColor Green
Write-Host "   Batch file: $batchPath" -ForegroundColor Green

# Create or update the task
Write-Host "`n3. Creating/updating scheduled task..." -ForegroundColor Yellow

$action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`""

$trigger = New-ScheduledTaskTrigger -Daily -At "02:00"

$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -WakeToRun

$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

try {
    # Register the new task
    Register-ScheduledTask -TaskName $newTaskName `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -Principal $principal `
        -Description "OpenClaw daily repository organization and cleanup (combined task)" `
        -Force
    
    Write-Host "   Task created/updated: $newTaskName" -ForegroundColor Green
    
    # Disable old task if it exists
    if ($oldTask) {
        Disable-ScheduledTask -TaskName $oldTaskName
        Write-Host "   Old task disabled: $oldTaskName" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "   ERROR: Failed to create/update task" -ForegroundColor Red
    Write-Host "   $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Verify the task
Write-Host "`n4. Verifying task configuration..." -ForegroundColor Yellow

try {
    $task = Get-ScheduledTask -TaskName $newTaskName -ErrorAction Stop
    
    Write-Host "   Task name: $($task.TaskName)" -ForegroundColor Gray
    Write-Host "   State: $($task.State)" -ForegroundColor Gray
    Write-Host "   Description: $($task.Description)" -ForegroundColor Gray
    
    if ($task.Triggers) {
        $trigger = $task.Triggers[0]
        Write-Host "   Schedule: Daily at $($trigger.StartBoundary)" -ForegroundColor Gray
    }
    
    Write-Host "   Task verified successfully" -ForegroundColor Green
    
} catch {
    Write-Host "   ERROR: Cannot verify task" -ForegroundColor Red
    Write-Host "   $($_.Exception.Message)" -ForegroundColor Red
}

# Summary
Write-Host "`n=== Update Summary ===" -ForegroundColor Cyan

$summary = @{
    "Admin Rights" = "Yes"
    "Workspace" = if (Test-Path $workspacePath) { "Found" } else { "Not found" }
    "Main Script" = if (Test-Path $scriptPath) { "Found" } else { "Not found" }
    "Batch File" = if (Test-Path $batchPath) { "Found" } else { "Created" }
    "New Task" = if (Get-ScheduledTask -TaskName $newTaskName -ErrorAction SilentlyContinue) { "Created" } else { "Failed" }
    "Old Task" = if ($oldTask) { "Disabled" } else { "Not found" }
}

foreach ($key in $summary.Keys) {
    $value = $summary[$key]
    $color = if ($value -match "Yes|Found|Created|Disabled") { "Green" } else { "Red" }
    
    Write-Host "  $key : $value" -ForegroundColor $color
}

Write-Host "`n=== Next Steps ===" -ForegroundColor Cyan
Write-Host "1. Test the new task manually:" -ForegroundColor Gray
Write-Host "   .\run-organize-cleanup.bat" -ForegroundColor White
Write-Host "2. Remove old scripts (after verification):" -ForegroundColor Gray
Write-Host "   organize-english.ps1" -ForegroundColor White
Write-Host "   auto-cleanup-english.ps1" -ForegroundColor White
Write-Host "   run-organize.bat" -ForegroundColor White
Write-Host "3. Check task execution tomorrow at 02:00" -ForegroundColor Gray

Write-Host "`nUpdate completed!" -ForegroundColor Green
Write-Host "Press Enter to exit..." -ForegroundColor Gray
Read-Host