# Simple Task Setup Script
# Works without admin privileges (will prompt if needed)

Write-Host "Simple Task Setup" -ForegroundColor Cyan
Write-Host "================="
Write-Host ""

# Main script path
$scriptPath = "C:\Users\luchaochao\.openclaw\workspace\auto-system-english.ps1"
if (-not (Test-Path $scriptPath)) {
    Write-Host "Error: Main script not found" -ForegroundColor Red
    Write-Host "Path: $scriptPath" -ForegroundColor Gray
    exit 1
}

Write-Host "Main script: $scriptPath" -ForegroundColor Gray
Write-Host ""

# Task definitions
$tasks = @(
    @{
        Name = "Workspace-Daily-Monitor"
        Description = "Daily workspace monitoring"
        Schedule = "DAILY"
        Time = "02:00"
        Command = "powershell -ExecutionPolicy Bypass -File `"$scriptPath`" monitor"
    },
    @{
        Name = "Workspace-Weekly-Cleanup"
        Description = "Weekly workspace cleanup"
        Schedule = "WEEKLY"
        Day = "MON"
        Time = "03:00"
        Command = "powershell -ExecutionPolicy Bypass -File `"$scriptPath`" clean"
    },
    @{
        Name = "Workspace-Monthly-Report"
        Description = "Monthly workspace report"
        Schedule = "MONTHLY"
        Day = "1"
        Time = "04:00"
        Command = "powershell -ExecutionPolicy Bypass -File `"$scriptPath`" report"
    }
)

# Function to create task
function Create-Task($task) {
    Write-Host "Creating: $($task.Name)" -ForegroundColor Yellow
    Write-Host "  Description: $($task.Description)" -ForegroundColor Gray
    
    # Build schtasks command
    $cmd = "schtasks /create /tn `"$($task.Name)`" /tr `"$($task.Command)`""
    $cmd += " /sc $($task.Schedule) /st $($task.Time) /ru SYSTEM /f"
    
    if ($task.Schedule -eq "WEEKLY") {
        $cmd += " /d $($task.Day)"
    } elseif ($task.Schedule -eq "MONTHLY") {
        $cmd += " /mo $($task.Day)"
    }
    
    # Execute command
    try {
        Write-Host "  Command: $cmd" -ForegroundColor DarkGray
        $output = cmd /c $cmd 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  Success" -ForegroundColor Green
            
            # Show schedule info
            $info = switch ($task.Schedule) {
                "DAILY" { "Daily at $($task.Time)" }
                "WEEKLY" { "Weekly on $($task.Day) at $($task.Time)" }
                "MONTHLY" { "Monthly on day $($task.Day) at $($task.Time)" }
            }
            Write-Host "  Schedule: $info" -ForegroundColor Gray
            
            return $true
        } else {
            Write-Host "  Failed (exit code: $LASTEXITCODE)" -ForegroundColor Red
            if ($output) {
                Write-Host "  Error: $output" -ForegroundColor DarkRed
            }
            return $false
        }
    } catch {
        Write-Host "  Exception: $_" -ForegroundColor Red
        return $false
    }
    
    Write-Host ""
}

# Check existing tasks
Write-Host "Checking existing tasks..." -ForegroundColor Gray
foreach ($task in $tasks) {
    $existing = schtasks /query /tn $task.Name 2>$null
    if ($existing) {
        Write-Host "  Found: $($task.Name)" -ForegroundColor Yellow
        Write-Host "  Deleting..." -ForegroundColor DarkGray
        schtasks /delete /tn $task.Name /f 2>$null
    }
}
Write-Host ""

# Create tasks
Write-Host "Creating scheduled tasks..." -ForegroundColor Cyan
Write-Host ""

$successCount = 0
foreach ($task in $tasks) {
    if (Create-Task $task) {
        $successCount++
    }
    Write-Host ""
}

# Show results
Write-Host "=== Results ===" -ForegroundColor Cyan
Write-Host "Successfully created: $successCount/$($tasks.Count) tasks" -ForegroundColor $(if ($successCount -eq $tasks.Count) {"Green"} elseif ($successCount -gt 0) {"Yellow"} else {"Red"})
Write-Host ""

# Verify tasks
Write-Host "Verifying tasks..." -ForegroundColor Gray
$verifiedTasks = @()
foreach ($task in $tasks) {
    $taskInfo = schtasks /query /tn $task.Name 2>$null
    if ($taskInfo) {
        $verifiedTasks += $task.Name
        Write-Host "  Verified: $($task.Name)" -ForegroundColor Green
    } else {
        Write-Host "  Missing: $($task.Name)" -ForegroundColor Red
    }
}
Write-Host ""

# Create test task
Write-Host "Creating test task..." -ForegroundColor Cyan
$testTaskName = "Workspace-Test-Run"
$testCmd = "schtasks /create /tn `"$testTaskName`" /tr `"powershell -ExecutionPolicy Bypass -File `"$scriptPath`" status`" /sc once /st $(Get-Date -Format 'HH:mm') /ru SYSTEM /f"

try {
    $testOutput = cmd /c $testCmd 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Test task created" -ForegroundColor Green
        
        # Run test task
        Start-Sleep -Seconds 2
        schtasks /run /tn $testTaskName 2>$null
        Write-Host "  Test task started" -ForegroundColor Gray
    }
} catch {
    Write-Host "  Test task failed" -ForegroundColor Yellow
}
Write-Host ""

# Summary
Write-Host "=== Summary ===" -ForegroundColor Green
Write-Host ""
Write-Host "Tasks created:" -ForegroundColor Yellow
Write-Host "1. Daily Monitor - 02:00 daily" -ForegroundColor Gray
Write-Host "2. Weekly Cleanup - 03:00 every Monday" -ForegroundColor Gray
Write-Host "3. Monthly Report - 04:00 on 1st of month" -ForegroundColor Gray
Write-Host ""

Write-Host "Management commands:" -ForegroundColor Cyan
Write-Host "  View tasks: schtasks /query /tn `"Workspace-*`"" -ForegroundColor Gray
Write-Host "  Run task: schtasks /run /tn `"Workspace-Daily-Monitor`"" -ForegroundColor Gray
Write-Host "  Delete task: schtasks /delete /tn `"Workspace-Daily-Monitor`" /f" -ForegroundColor Gray
Write-Host ""

Write-Host "System will now automatically:" -ForegroundColor Green
Write-Host "  • Monitor disk space daily" -ForegroundColor Gray
Write-Host "  • Clean workspace weekly" -ForegroundColor Gray
Write-Host "  • Generate reports monthly" -ForegroundColor Gray
Write-Host ""

Write-Host "Setup completed at: $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Gray