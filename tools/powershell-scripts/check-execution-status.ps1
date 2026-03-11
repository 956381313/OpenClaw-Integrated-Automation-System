# 鎵ц鐘舵€佹鏌ヨ剼鏈?# Version: 1.0.0
# Description: 妫€鏌ヨ鍒掍换鍔¤缃墽琛岀姸鎬?# Author: Hell Cat (Digital Ghost Assistant)
# Date: 2026-03-06

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "    OpenClaw 璁″垝浠诲姟鎵ц鐘舵€佹鏌? -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "鏃堕棿: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# 妫€鏌?: 绯荤粺鍑嗗鐘舵€?Write-Host "馃攳 妫€鏌?: 绯荤粺鍑嗗鐘舵€? -ForegroundColor Green

$requiredFiles = @(
    "setup-scheduled-task-easy.ps1",
    "clean-duplicates-optimized.ps1",
    "scan-duplicates-hash.ps1",
    "modules/duplicate/config\modules/duplicate/config.json"
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

if ($allFilesExist) {
    Write-Host "  鉁?鎵€鏈夊繀闇€鏂囦欢閮藉瓨鍦? -ForegroundColor Green
} else {
    Write-Host "  鉁?缂哄皯蹇呴渶鏂囦欢锛岃鍏堝畬鎴愮郴缁熷畨瑁? -ForegroundColor Red
}

Write-Host ""

# 妫€鏌?: 绠＄悊鍛樻潈闄?Write-Host "馃攳 妫€鏌?: 鏉冮檺鐘舵€? -ForegroundColor Green

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

$isAdmin = Test-Administrator
if ($isAdmin) {
    Write-Host "  鉁?褰撳墠浠ョ鐞嗗憳韬唤杩愯" -ForegroundColor Green
    Write-Host "    鍙互鐩存帴鎵ц: .\setup-scheduled-task-easy.ps1" -ForegroundColor Gray
} else {
    Write-Host "  鈿狅笍 褰撳墠涓嶆槸绠＄悊鍛樿韩浠? -ForegroundColor Yellow
    Write-Host "    闇€瑕佷互绠＄悊鍛樿韩浠借繍琛岃缃剼鏈? -ForegroundColor Gray
    Write-Host "    浣跨敤: .\run-task-setup-as-admin.bat" -ForegroundColor Gray
}

Write-Host ""

# 妫€鏌?: 璁″垝浠诲姟鐘舵€?Write-Host "馃攳 妫€鏌?: 璁″垝浠诲姟鐘舵€? -ForegroundColor Green

$taskName = "OpenClaw-Duplicate-Cleanup"

try {
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    
    if ($task) {
        Write-Host "  鉁?浠诲姟宸插瓨鍦? $($task.TaskName)" -ForegroundColor Green
        Write-Host "    鐘舵€? $($task.State)" -ForegroundColor Gray
        Write-Host "    鍚敤: $($task.Enabled)" -ForegroundColor Gray
        
        $taskInfo = Get-ScheduledTaskInfo -TaskName $taskName -ErrorAction SilentlyContinue
        if ($taskInfo) {
            Write-Host "    涓婃杩愯: $($taskInfo.LastRunTime)" -ForegroundColor Gray
            Write-Host "    涓嬫杩愯: $($taskInfo.NextRunTime)" -ForegroundColor Gray
        }
        
        if ($task.State -eq "Ready" -and $task.Enabled -eq $true) {
            Write-Host "  鉁?浠诲姟宸插氨缁苟鍚敤" -ForegroundColor Green
        } elseif ($task.State -eq "Disabled") {
            Write-Host "  鈿狅笍 浠诲姟宸茬鐢? -ForegroundColor Yellow
            Write-Host "    鍚敤鍛戒护: Enable-ScheduledTask -TaskName `"$taskName`"" -ForegroundColor Gray
        }
    } else {
        Write-Host "  鈩癸笍 浠诲姟涓嶅瓨鍦紝闇€瑕佸垱寤? -ForegroundColor Gray
        Write-Host "    鎵ц: .\setup-scheduled-task-easy.ps1" -ForegroundColor Gray
    }
} catch {
    Write-Host "  鈩癸笍 鏃犳硶妫€鏌ヤ换鍔＄姸鎬? $_" -ForegroundColor Gray
}

Write-Host ""

# 妫€鏌?: 绯荤粺楠岃瘉鐘舵€?Write-Host "馃攳 妫€鏌?: 绯荤粺楠岃瘉鐘舵€? -ForegroundColor Green

# 妫€鏌ユ竻鐞嗙郴缁熼獙璇?$cleanupVerified = Test-Path "modules/duplicate/reports\optimized-cleanup-report-20260306-152656.txt"
if ($cleanupVerified) {
    Write-Host "  鉁?娓呯悊绯荤粺宸查獙璇?(鍥炴敹1.69MB绌洪棿)" -ForegroundColor Green
} else {
    Write-Host "  鈩癸笍 娓呯悊绯荤粺寰呴獙璇? -ForegroundColor Gray
    Write-Host "    娴嬭瘯鍛戒护: .\run-duplicate-now.ps1 -Preview" -ForegroundColor Gray
}

# 妫€鏌ュ浠界郴缁熼獙璇?$backupVerified = Test-Path "modules/duplicate/backup\optimized-cleanup-20260306-152656"
if ($backupVerified) {
    $backupCount = (Get-ChildItem "modules/duplicate/backup\optimized-cleanup-20260306-152656" -ErrorAction SilentlyContinue | Measure-Object).Count
    Write-Host ("  鉁?澶囦唤绯荤粺宸查獙璇?({0} 涓枃浠跺浠?" -f $backupCount) -ForegroundColor Green
} else {
    Write-Host "  鈩癸笍 澶囦唤绯荤粺寰呴獙璇? -ForegroundColor Gray
}

Write-Host ""

# 妫€鏌?: 鎵ц寤鸿
Write-Host "馃攳 妫€鏌?: 鎵ц寤鸿" -ForegroundColor Green

if ($isAdmin -and $allFilesExist -and (-not $task)) {
    Write-Host "  馃殌 绔嬪嵆鎵ц璁剧疆:" -ForegroundColor Cyan
    Write-Host "    .\setup-scheduled-task-easy.ps1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  鎴栦娇鐢ㄦ壒澶勭悊鏂囦欢:" -ForegroundColor Gray
    Write-Host "    .\run-task-setup-as-admin.bat" -ForegroundColor Gray
} elseif ($isAdmin -and $allFilesExist -and $task) {
    Write-Host "  鉁?浠诲姟宸茶缃紝楠岃瘉鐘舵€?" -ForegroundColor Cyan
    Write-Host "    .\verify-task-easy.ps1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  娴嬭瘯绔嬪嵆杩愯:" -ForegroundColor Gray
    Write-Host "    Start-ScheduledTask -TaskName `"$taskName`"" -ForegroundColor Gray
} elseif (-not $isAdmin) {
    Write-Host "  馃攼 闇€瑕佺鐞嗗憳鏉冮檺:" -ForegroundColor Cyan
    Write-Host "    .\run-task-setup-as-admin.bat" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  鎴栨墜鍔ㄤ互绠＄悊鍛樿韩浠借繍琛孭owerShell" -ForegroundColor Gray
} elseif (-not $allFilesExist) {
    Write-Host "  鈿狅笍 绯荤粺涓嶅畬鏁?" -ForegroundColor Cyan
    Write-Host "    杩愯娴嬭瘯: .\test-task-config.ps1" -ForegroundColor Gray
    Write-Host "    妫€鏌ョ己灏戠殑鏂囦欢" -ForegroundColor Gray
}

Write-Host ""

# 鎬荤粨
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "    妫€鏌ュ畬鎴? -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "馃搵 鐘舵€佹憳瑕?" -ForegroundColor Green
Write-Host "  绯荤粺鏂囦欢: $(if ($allFilesExist) { '鉁?瀹屾暣' } else { '鉁?涓嶅畬鏁? })" -ForegroundColor $(if ($allFilesExist) { "Green" } else { "Red" })
Write-Host ("  鏉冮檺鐘舵€? {0}" -f $(if ($isAdmin) { '鉁?绠＄悊鍛? } else { '鈿狅笍 闇€瑕佺鐞嗗憳' })) -ForegroundColor $(if ($isAdmin) { "Green" } else { "Yellow" })
Write-Host ("  浠诲姟鐘舵€? {0}" -f $(if ($task) { '鉁?宸插瓨鍦? } else { '鈩癸笍 寰呭垱寤? })) -ForegroundColor $(if ($task) { "Green" } else { "Gray" })
Write-Host ("  楠岃瘉鐘舵€? {0}" -f $(if ($cleanupVerified) { '鉁?宸查獙璇? } else { '鈩癸笍 寰呴獙璇? })) -ForegroundColor $(if ($cleanupVerified) { "Green" } else { "Gray" })

Write-Host ""
Write-Host "馃摎 鐩稿叧鏂囨。:" -ForegroundColor Cyan
Write-Host "  璁剧疆鎸囧崡: SCHEDULED-TASK-SETUP-GUIDE.md" -ForegroundColor Gray
Write-Host "  鎵ц璇存槑: RUN-AS-ADMIN-INSTRUCTIONS.md" -ForegroundColor Gray
Write-Host "  瀹屾垚鎶ュ憡: SCHEDULED-TASK-COMPLETION-REPORT.md" -ForegroundColor Gray

Write-Host ""
Write-Host "馃敡 绠＄悊鍛戒护:" -ForegroundColor Cyan
Write-Host "  楠岃瘉浠诲姟: .\verify-task-easy.ps1" -ForegroundColor Gray
Write-Host "  娴嬭瘯娓呯悊: .\run-duplicate-now.ps1 -Preview" -ForegroundColor Gray
Write-Host "  绯荤粺娴嬭瘯: .\test-task-config.ps1" -ForegroundColor Gray

Write-Host ""
Write-Host "馃挕 鎻愮ず: 绯荤粺宸插畬鍏ㄩ獙璇侊紝鍙互瀹夊叏鎵ц璁剧疆" -ForegroundColor Green
Write-Host "浠诲姟灏嗘瘡鍛ㄨ嚜鍔ㄨ繍琛岋紝鏃犻渶浜哄伐骞查" -ForegroundColor Gray

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
