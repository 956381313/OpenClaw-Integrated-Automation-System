# Easy Scheduled Task Setup for Duplicate Cleanup
# Version: 1.0.0
# Description: User-friendly setup script with step-by-step guidance
# Author: Hell Cat (Digital Ghost Assistant)
# Date: 2026-03-06

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "    OpenClaw Duplicate Cleanup Task Setup" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "馃搵 姒傝堪" -ForegroundColor Green
Write-Host "鏈剼鏈皢甯姪鎮ㄨ缃甒indows璁″垝浠诲姟锛屽疄鐜伴噸澶嶆枃浠惰嚜鍔ㄦ竻鐞嗐€? -ForegroundColor Gray
Write-Host "浠诲姟灏嗘瘡鍛ㄦ棩03:00鑷姩杩愯锛屾竻鐞嗛噸澶嶆枃浠跺苟鍥炴敹纾佺洏绌洪棿銆? -ForegroundColor Gray
Write-Host ""

Write-Host "馃幆 璁剧疆鐩爣" -ForegroundColor Green
Write-Host "- 浠诲姟鍚嶇О: OpenClaw-Duplicate-Cleanup" -ForegroundColor Gray
Write-Host "- 璁″垝: 姣忓懆鏃?03:00 鑷姩杩愯" -ForegroundColor Gray
Write-Host "- 娓呯悊绛栫暐: KeepNewest (淇濈暀鏈€鏂版枃浠?" -ForegroundColor Gray
Write-Host "- 杩愯璐︽埛: SYSTEM (鏈€楂樻潈闄?" -ForegroundColor Gray
Write-Host ""

Write-Host "馃攳 姝ラ1: 妫€鏌ョ郴缁熷噯澶囨儏鍐? -ForegroundColor Yellow

# Check if running as Administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

$isAdmin = Test-Administrator
if ($isAdmin) {
    Write-Host "  鉁?姝ｅ湪浠ョ鐞嗗憳韬唤杩愯" -ForegroundColor Green
} else {
    Write-Host "  鉁?闇€瑕佺鐞嗗憳鏉冮檺" -ForegroundColor Red
    Write-Host ""
    Write-Host "璇锋寜鐓т互涓嬫楠ゆ搷浣?" -ForegroundColor Yellow
    Write-Host "  1. 鍏抽棴褰撳墠绐楀彛" -ForegroundColor Gray
    Write-Host "  2. 鐐瑰嚮Windows寮€濮嬭彍鍗? -ForegroundColor Gray
    Write-Host "  3. 鎼滅储'PowerShell'" -ForegroundColor Gray
    Write-Host "  4. 鍙抽敭鐐瑰嚮'Windows PowerShell'" -ForegroundColor Gray
    Write-Host "  5. 閫夋嫨'浠ョ鐞嗗憳韬唤杩愯'" -ForegroundColor Gray
    Write-Host "  6. 瀵艰埅鍒板伐浣滅洰褰? cd C:\Users\luchaochao\.openclaw\workspace" -ForegroundColor Gray
    Write-Host "  7. 閲嶆柊杩愯姝よ剼鏈? .\setup-scheduled-task-easy.ps1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "鎴栬€呬娇鐢ㄤ互涓嬪懡浠?" -ForegroundColor Cyan
    Write-Host "  powershell -Command \"Start-Process PowerShell -Verb RunAs -ArgumentList '-ExecutionPolicy Bypass -File `\"$PSScriptRoot\setup-scheduled-task-easy.ps1`\"'\"" -ForegroundColor Gray
    exit 1
}

Write-Host ""

# Check required files
Write-Host "馃攳 姝ラ2: 妫€鏌ュ繀闇€鏂囦欢" -ForegroundColor Yellow
$requiredFiles = @(
    "clean-duplicates-optimized.ps1",
    "scan-duplicates-hash.ps1",
    "modules/duplicate/config\modules/duplicate/config.json",
    "automation-config-english.json"
)

$allFilesExist = $true
foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "  鉁?$file" -ForegroundColor Green
    } else {
        Write-Host "  鉁?$file" -ForegroundColor Red
        $allFilesExist = $false
    }
}

if (-not $allFilesExist) {
    Write-Host ""
    Write-Host "鈿狅笍 缂哄皯蹇呴渶鏂囦欢锛岃鍏堝畬鎴愮郴缁熷畨瑁? -ForegroundColor Red
    Write-Host "杩愯娴嬭瘯鑴氭湰妫€鏌ラ棶棰? .\test-task-config.ps1" -ForegroundColor Yellow
    exit 1
}

Write-Host "  鉁?鎵€鏈夊繀闇€鏂囦欢閮藉瓨鍦? -ForegroundColor Green
Write-Host ""

# Check if task already exists
Write-Host "馃攳 姝ラ3: 妫€鏌ョ幇鏈変换鍔? -ForegroundColor Yellow
$taskName = "OpenClaw-Duplicate-Cleanup"

try {
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-Host "  鈿狅笍 浠诲姟宸插瓨鍦?" -ForegroundColor Yellow
        Write-Host "    鍚嶇О: $($existingTask.TaskName)" -ForegroundColor Gray
        Write-Host "    鐘舵€? $($existingTask.State)" -ForegroundColor Gray
        Write-Host "    鍚敤: $($existingTask.Enabled)" -ForegroundColor Gray
        
        if ($existingTask.State -eq "Ready") {
            Write-Host "  鉁?浠诲姟宸插氨缁? -ForegroundColor Green
        }
        
        Write-Host ""
        Write-Host "閫夐」:" -ForegroundColor Cyan
        Write-Host "  [U] 鏇存柊鐜版湁浠诲姟" -ForegroundColor Gray
        Write-Host "  [R] 閲嶆柊鍒涘缓浠诲姟" -ForegroundColor Gray
        Write-Host "  [C] 鍙栨秷" -ForegroundColor Gray
        
        $choice = Read-Host "璇烽€夋嫨 (U/R/C)"
        
        switch ($choice.ToUpper()) {
            "U" {
                Write-Host "鏇存柊鐜版湁浠诲姟..." -ForegroundColor Yellow
                # Continue with setup
            }
            "R" {
                Write-Host "鍒犻櫎鐜版湁浠诲姟..." -ForegroundColor Yellow
                try {
                    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
                    Write-Host "  鉁?浠诲姟宸插垹闄? -ForegroundColor Green
                } catch {
                    Write-Host "  鉁?鍒犻櫎澶辫触: $_" -ForegroundColor Red
                    exit 1
                }
            }
            default {
                Write-Host "鎿嶄綔鍙栨秷" -ForegroundColor Yellow
                exit 0
            }
        }
    } else {
        Write-Host "  鉁?浠诲姟涓嶅瓨鍦紝灏嗗垱寤烘柊浠诲姟" -ForegroundColor Green
    }
} catch {
    Write-Host "  鈩癸笍 鏃犳硶妫€鏌ョ幇鏈変换鍔? $_" -ForegroundColor Gray
}

Write-Host ""

# Confirm setup
Write-Host "馃攳 姝ラ4: 纭璁剧疆" -ForegroundColor Yellow
Write-Host "灏嗗垱寤轰互涓嬭鍒掍换鍔?" -ForegroundColor Gray
Write-Host "  鍚嶇О: $taskName" -ForegroundColor Gray
Write-Host "  鎻忚堪: OpenClaw Duplicate File Cleanup - Weekly automatic cleanup" -ForegroundColor Gray
Write-Host "  璁″垝: 姣忓懆鏃?03:00" -ForegroundColor Gray
Write-Host "  鑴氭湰: clean-duplicates-optimized.ps1 -Strategy KeepNewest" -ForegroundColor Gray
Write-Host "  杩愯璐︽埛: SYSTEM (鏈€楂樻潈闄?" -ForegroundColor Gray
Write-Host ""

$confirm = Read-Host "鏄惁缁х画? (Y/N)"
if ($confirm -ne "Y" -and $confirm -ne "y") {
    Write-Host "鎿嶄綔鍙栨秷" -ForegroundColor Yellow
    exit 0
}

Write-Host ""

# Create scheduled task
Write-Host "馃殌 姝ラ5: 鍒涘缓璁″垝浠诲姟" -ForegroundColor Green

try {
    Write-Host "  姝ｅ湪閰嶇疆浠诲姟鎿嶄綔..." -ForegroundColor Gray
    $action = New-ScheduledTaskAction `
        -Execute "powershell.exe" `
        -Argument "-ExecutionPolicy Bypass -File `"$PWD\clean-duplicates-optimized.ps1`" -Strategy KeepNewest" `
        -WorkingDirectory $PWD
    
    Write-Host "  姝ｅ湪閰嶇疆瑙﹀彂鍣?.." -ForegroundColor Gray
    $trigger = New-ScheduledTaskTrigger `
        -Weekly `
        -DaysOfWeek Sunday `
        -At "03:00"
    
    Write-Host "  姝ｅ湪閰嶇疆瀹夊叏璁剧疆..." -ForegroundColor Gray
    $principal = New-ScheduledTaskPrincipal `
        -UserId "SYSTEM" `
        -LogonType ServiceAccount `
        -RunLevel Highest
    
    Write-Host "  姝ｅ湪閰嶇疆浠诲姟璁剧疆..." -ForegroundColor Gray
    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -RunOnlyIfNetworkAvailable `
        -RestartCount 3 `
        -RestartInterval (New-TimeSpan -Minutes 5)
    
    Write-Host "  姝ｅ湪娉ㄥ唽浠诲姟..." -ForegroundColor Gray
    Register-ScheduledTask `
        -TaskName $taskName `
        -Description "OpenClaw Duplicate File Cleanup - Weekly automatic cleanup" `
        -Action $action `
        -Trigger $trigger `
        -Principal $principal `
        -Settings $settings `
        -Force
    
    Write-Host "  鉁?璁″垝浠诲姟鍒涘缓鎴愬姛!" -ForegroundColor Green
    
    # Enable the task
    Enable-ScheduledTask -TaskName $taskName
    Write-Host "  鉁?浠诲姟宸插惎鐢? -ForegroundColor Green
    
} catch {
    Write-Host "  鉁?鍒涘缓澶辫触: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Verify task creation
Write-Host "鉁?姝ラ6: 楠岃瘉浠诲姟鍒涘缓" -ForegroundColor Green

try {
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction Stop
    
    Write-Host "  鉁?浠诲姟楠岃瘉鎴愬姛:" -ForegroundColor Green
    Write-Host "    鍚嶇О: $($task.TaskName)" -ForegroundColor Gray
    Write-Host "    鐘舵€? $($task.State)" -ForegroundColor Gray
    Write-Host "    鍚敤: $($task.Enabled)" -ForegroundColor Gray
    
    # Get trigger info
    if ($task.Triggers.Count -gt 0) {
        $triggerInfo = $task.Triggers[0]
        Write-Host "    璁″垝: 姣忓懆鏃?03:00" -ForegroundColor Gray
    }
    
    # Get next run time
    $taskInfo = Get-ScheduledTaskInfo -TaskName $taskName
    if ($taskInfo.NextRunTime) {
        Write-Host "    涓嬫杩愯: $($taskInfo.NextRunTime)" -ForegroundColor Gray
    }
    
} catch {
    Write-Host "  鈿狅笍 浠诲姟楠岃瘉澶辫触: $_" -ForegroundColor Yellow
}

Write-Host ""

# Create verification script
Write-Host "馃摑 姝ラ7: 鍒涘缓楠岃瘉鑴氭湰" -ForegroundColor Green
$verificationScript = @"
# Task Verification Script
# Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

Write-Host "=== OpenClaw Duplicate Cleanup Task Verification ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray

`$TaskName = "$taskName"

try {
    `$task = Get-ScheduledTask -TaskName `$TaskName -ErrorAction Stop
    
    Write-Host "鉁?Task found: `$(`$task.TaskName)" -ForegroundColor Green
    Write-Host "  State: `$(`$task.State)" -ForegroundColor Gray
    Write-Host "  Enabled: `$(`$task.Enabled)" -ForegroundColor Gray
    
    `$taskInfo = Get-ScheduledTaskInfo -TaskName `$TaskName
    Write-Host "  Last Run: `$(`$taskInfo.LastRunTime)" -ForegroundColor Gray
    Write-Host "  Next Run: `$(`$taskInfo.NextRunTime)" -ForegroundColor Gray
    
    Write-Host "`n鉁?Task is properly configured and ready" -ForegroundColor Green
    
} catch {
    Write-Host "鉁?Task not found or error: `$_" -ForegroundColor Red
}

Write-Host "`nVerification completed" -ForegroundColor Gray
"@

$verificationScript | Out-File "verify-task-easy.ps1" -Encoding UTF8
Write-Host "  鉁?楠岃瘉鑴氭湰宸插垱寤? verify-task-easy.ps1" -ForegroundColor Green

Write-Host ""

# Create setup log
Write-Host "馃搵 姝ラ8: 鍒涘缓璁剧疆鏃ュ織" -ForegroundColor Green
$setupLog = @"
OpenClaw Duplicate Cleanup Task Setup Log
==========================================
Setup Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Setup Script: setup-scheduled-task-easy.ps1
Administrator: $isAdmin

Task Configuration:
- Name: $taskName
- Description: OpenClaw Duplicate File Cleanup - Weekly automatic cleanup
- Schedule: Weekly on Sunday at 03:00
- Script: clean-duplicates-optimized.ps1 -Strategy KeepNewest
- Working Directory: $PWD
- Run As: SYSTEM (Highest Privileges)

Setup Result: SUCCESS
Task State: $(if ($task) { $task.State } else { "Unknown" })
Task Enabled: $(if ($task) { $task.Enabled } else { "Unknown" })

Files Created:
- verify-task-easy.ps1 (Task verification)

Verification Command:
  .\verify-task-easy.ps1

Management Commands:
  # Start task immediately
  Start-ScheduledTask -TaskName "$taskName"
  
  # View task details
  Get-ScheduledTask -TaskName "$taskName"
  
  # Disable task
  Disable-ScheduledTask -TaskName "$taskName"
  
  # Remove task
  Unregister-ScheduledTask -TaskName "$taskName" -Confirm:`$false

---
Setup completed by OpenClaw Duplicate Cleanup System
"@

$setupLogPath = "modules/duplicate/data/logs/scheduled\task-setup-easy-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$setupLog | Out-File $setupLogPath -Encoding UTF8
Write-Host "  鉁?璁剧疆鏃ュ織宸蹭繚瀛? $setupLogPath" -ForegroundColor Green

Write-Host ""

# Final summary
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "    馃帀 璁剧疆瀹屾垚!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "鉁?璁″垝浠诲姟宸叉垚鍔熷垱寤? -ForegroundColor Green
Write-Host "  鍚嶇О: $taskName" -ForegroundColor Gray
Write-Host "  璁″垝: 姣忓懆鏃?03:00 鑷姩杩愯" -ForegroundColor Gray
Write-Host "  鐘舵€? 宸插惎鐢? -ForegroundColor Gray
Write-Host ""

Write-Host "馃搳 鐩戞帶淇℃伅" -ForegroundColor Yellow
Write-Host "  鏃ュ織鐩綍: modules/duplicate/data/logs/scheduled\" -ForegroundColor Gray
Write-Host "  鎶ュ憡鐩綍: modules/duplicate/reports\scheduled\" -ForegroundColor Gray
Write-Host "  澶囦唤鐩綍: modules/duplicate/backup\automated-{timestamp}\" -ForegroundColor Gray
Write-Host ""

Write-Host "馃敡 绠＄悊鍛戒护" -ForegroundColor Yellow
Write-Host "  楠岃瘉浠诲姟: .\verify-task-easy.ps1" -ForegroundColor Gray
Write-Host "  绔嬪嵆杩愯: Start-ScheduledTask -TaskName `"$taskName`"" -ForegroundColor Gray
Write-Host "  鏌ョ湅璇︽儏: Get-ScheduledTask -TaskName `"$taskName`"" -ForegroundColor Gray
Write-Host ""

Write-Host "馃搮 涓嬫杩愯" -ForegroundColor Cyan
if ($taskInfo -and $taskInfo.NextRunTime) {
    Write-Host "  鏃堕棿: $($taskInfo.NextRunTime)" -ForegroundColor Gray
} else {
    Write-Host "  鏃堕棿: 涓嬪懆鏃?03:00" -ForegroundColor Gray
}

Write-Host ""
Write-Host "馃挕 鎻愮ず: 浠诲姟灏嗚嚜鍔ㄨ繍琛岋紝鏃犻渶浜哄伐骞查" -ForegroundColor Green
Write-Host "瀹氭湡妫€鏌?modules/duplicate/reports\ 鐩綍鏌ョ湅娓呯悊鎶ュ憡" -ForegroundColor Gray

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
