# OpenClaw 鑷姩鍖栧浠界郴缁?# 鑷姩妫€娴嬨€佸浠姐€佷笂浼犲埌GitHub

Write-Host "=== OpenClaw 鑷姩鍖栧浠界郴缁?===" -ForegroundColor Cyan
Write-Host "鐗堟湰: 1.0.0" -ForegroundColor Gray
Write-Host "鏃堕棿: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# 閰嶇疆
$Config = @{
    OpenClawPath = "C:\Users\luchaochao\.openclaw"
    GitHubRepo = "https://github.com/956381313/OpenClaw.git"
    BackupRoot = "D:\OpenClaw-AutoBackup"
    LogFile = "D:\OpenClaw-AutoBackup\backup-log.txt"
    MaxBackups = 30  # 淇濈暀30涓浠?}

# 鍒涘缓鐩綍
if (-not (Test-Path $Config.BackupRoot)) {
    New-Item -ItemType Directory -Path $Config.BackupRoot -Force | Out-Null
    Write-Host "鍒涘缓澶囦唤鏍圭洰褰? $($Config.BackupRoot)" -ForegroundColor Green
}

# 鏃ュ織鍑芥暟
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # 鎺у埗鍙拌緭鍑?    switch ($Level) {
        "INFO"    { Write-Host $logEntry -ForegroundColor Gray }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR"   { Write-Host $logEntry -ForegroundColor Red }
    }
    
    # 鏂囦欢鏃ュ織
    $logEntry | Out-File $Config.LogFile -Append -Encoding UTF8
}

# 1. 妫€鏌penClaw鐘舵€?Write-Log "姝ラ1: 妫€鏌penClaw鐘舵€?
if (Test-Path $Config.OpenClawPath) {
    $size = (Get-ChildItem $Config.OpenClawPath -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
    Write-Log "OpenClaw鐩綍瀛樺湪: $($Config.OpenClawPath)" -Level "SUCCESS"
    Write-Log "鐩綍澶у皬: $([math]::Round($size, 2)) MB" -Level "INFO"
} else {
    Write-Log "OpenClaw鐩綍涓嶅瓨鍦? $($Config.OpenClawPath)" -Level "ERROR"
    exit 1
}

# 2. 鍒涘缓澶囦唤
Write-Log "姝ラ2: 鍒涘缓澶囦唤"
$backupName = "openclaw-auto-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$backupPath = Join-Path $Config.BackupRoot $backupName

try {
    # 鍒涘缓澶囦唤鐩綍
    New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
    
    # 澶嶅埗鏍稿績鏂囦欢
    $coreFiles = @(
        "$($Config.OpenClawPath)\openclaw.json",
        "$($Config.OpenClawPath)\gateway.cmd",
        "$($Config.OpenClawPath)\update-check.json"
    )
    
    $workspaceFiles = Get-ChildItem "$($Config.OpenClawPath)\workspace\*.md" -File
    
    $fileCount = 0
    foreach ($file in $coreFiles) {
        if (Test-Path $file) {
            $fileName = Split-Path $file -Leaf
            Copy-Item $file "$backupPath\$fileName" -Force
            $fileCount++
            Write-Log "澶嶅埗鏍稿績鏂囦欢: $fileName" -Level "INFO"
        }
    }
    
    foreach ($file in $workspaceFiles) {
        Copy-Item $file.FullName "$backupPath\$($file.Name)" -Force
        $fileCount++
        Write-Log "澶嶅埗宸ヤ綔鍖烘枃浠? $($file.Name)" -Level "INFO"
    }
    
    # 鍒涘缓澶囦唤淇℃伅鏂囦欢
    $backupInfo = @{
        BackupName = $backupName
        BackupTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        FileCount = $fileCount
        SourcePath = $Config.OpenClawPath
        System = @{
            OS = (Get-WmiObject Win32_OperatingSystem).Caption
            Version = (Get-WmiObject Win32_OperatingSystem).Version
            Architecture = (Get-WmiObject Win32_OperatingSystem).OSArchitecture
        }
    }
    
    $backupInfo | ConvertTo-Json -Depth 3 | Out-File "$backupPath\backup-info.json" -Encoding UTF8
    $fileCount++
    
    Write-Log "澶囦唤鍒涘缓瀹屾垚: $backupName" -Level "SUCCESS"
    Write-Log "鏂囦欢鏁伴噺: $fileCount" -Level "INFO"
    
} catch {
    Write-Log "澶囦唤鍒涘缓澶辫触: $($_.Exception.Message)" -Level "ERROR"
    exit 1
}

# 3. 涓婁紶鍒癎itHub
Write-Log "姝ラ3: 涓婁紶鍒癎itHub"

$gitRepoPath = "services/github/cloud-backup"
if (-not (Test-Path $gitRepoPath)) {
    Write-Log "GitHub浠撳簱涓嶅瓨鍦紝姝ｅ湪鍏嬮殕..." -Level "WARNING"
    try {
        git clone $Config.GitHubRepo $gitRepoPath
        Write-Log "GitHub浠撳簱鍏嬮殕鎴愬姛" -Level "SUCCESS"
    } catch {
        Write-Log "GitHub浠撳簱鍏嬮殕澶辫触: $($_.Exception.Message)" -Level "ERROR"
        Write-Log "灏嗗湪鏈湴淇濆瓨澶囦唤: $backupPath" -Level "INFO"
        exit 0
    }
}

try {
    Set-Location $gitRepoPath
    
    # 鎷夊彇鏈€鏂?    git pull origin main
    
    # 澶嶅埗澶囦唤鍒颁粨搴?    $targetDir = "auto-backups\$backupName"
    $targetParent = Split-Path $targetDir -Parent
    
    if (-not (Test-Path $targetParent)) {
        New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
    }
    
    Copy-Item "..\$backupPath" $targetDir -Recurse -Force
    
    # 娣诲姞鍜屾彁浜?    git add $targetDir
    git commit -m "鑷姩澶囦唤: $backupName - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    
    # 鎺ㄩ€?    git push origin main
    
    Write-Log "GitHub涓婁紶鎴愬姛" -Level "SUCCESS"
    
    # 鑾峰彇鎻愪氦淇℃伅
    $commitHash = git log --oneline -1 | Select-String -Pattern "^(\w+)" | ForEach-Object { $_.Matches[0].Groups[1].Value }
    Write-Log "鎻愪氦鍝堝笇: $commitHash" -Level "INFO"
    
    Set-Location ..
    
} catch {
    Write-Log "GitHub涓婁紶澶辫触: $($_.Exception.Message)" -Level "ERROR"
    Write-Log "澶囦唤宸蹭繚瀛樺湪鏈湴: $backupPath" -Level "INFO"
}

# 4. 娓呯悊鏃у浠?Write-Log "姝ラ4: 娓呯悊鏃у浠?
try {
    $backupDirs = Get-ChildItem $Config.BackupRoot -Directory | Where-Object { $_.Name -match "openclaw-auto-" } | Sort-Object CreationTime -Descending
    
    if ($backupDirs.Count -gt $Config.MaxBackups) {
        $oldBackups = $backupDirs | Select-Object -Skip $Config.MaxBackups
        
        foreach ($oldBackup in $oldBackups) {
            Remove-Item $oldBackup.FullName -Recurse -Force
            Write-Log "鍒犻櫎鏃у浠? $($oldBackup.Name)" -Level "INFO"
        }
        
        Write-Log "娓呯悊瀹屾垚锛屼繚鐣?$($Config.MaxBackups) 涓渶鏂板浠? -Level "SUCCESS"
    } else {
        Write-Log "澶囦唤鏁伴噺鍦ㄩ檺鍒跺唴 ($($backupDirs.Count)/$($Config.MaxBackups))" -Level "INFO"
    }
    
} catch {
    Write-Log "澶囦唤娓呯悊澶辫触: $($_.Exception.Message)" -Level "WARNING"
}

# 5. 鐢熸垚鎶ュ憡
Write-Log "姝ラ5: 鐢熸垚鎶ュ憡"
$report = @"
# OpenClaw 鑷姩鍖栧浠芥姤鍛?## 澶囦唤鏃堕棿: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
## 澶囦唤鍚嶇О: $backupName
## 鏂囦欢鏁伴噺: $fileCount
## 澶囦唤璺緞: $backupPath
## GitHub鐘舵€? $(if ($commitHash) { "宸蹭笂浼?(鎻愪氦: $commitHash)" } else { "鏈湴淇濆瓨" })

## 绯荤粺淇℃伅:
- 鎿嶄綔绯荤粺: $($backupInfo.System.OS)
- 鐗堟湰: $($backupInfo.System.Version)
- 鏋舵瀯: $($backupInfo.System.Architecture)

## 鍖呭惈鐨勬牳蹇冩枃浠?
$(Get-ChildItem $backupPath -File | ForEach-Object { "- $($_.Name)" })

## 涓嬫澶囦唤璁″垝:
- 鏃堕棿: $(Get-Date).AddHours(1).ToString('yyyy-MM-dd HH:mm:ss')
- 淇濈暀绛栫暐: 鏈€澶?$($Config.MaxBackups) 涓浠?
---
*姝ゆ姤鍛婄敱 OpenClaw 鑷姩鍖栧浠界郴缁熺敓鎴?
"@

$report | Out-File "$backupPath\backup-report.md" -Encoding UTF8
Write-Log "鎶ュ憡鐢熸垚瀹屾垚" -Level "SUCCESS"

# 鏈€缁堟€荤粨
Write-Host "`n=== 鑷姩鍖栧浠藉畬鎴?===" -ForegroundColor Green
Write-Host "澶囦唤鍚嶇О: $backupName" -ForegroundColor Cyan
Write-Host "鏂囦欢鏁伴噺: $fileCount" -ForegroundColor Cyan
Write-Host "澶囦唤浣嶇疆: $backupPath" -ForegroundColor Cyan
if ($commitHash) {
    Write-Host "GitHub鎻愪氦: $commitHash" -ForegroundColor Green
    Write-Host "鍦ㄧ嚎鏌ョ湅: https://github.com/956381313/OpenClaw/tree/main/auto-backups/$backupName" -ForegroundColor Yellow
} else {
    Write-Host "鐘舵€? 鏈湴淇濆瓨 (GitHub涓婁紶澶辫触)" -ForegroundColor Yellow
}
Write-Host "鏃ュ織鏂囦欢: $($Config.LogFile)" -ForegroundColor Gray
Write-Host "涓嬫澶囦唤: $(Get-Date).AddHours(1).ToString('HH:mm:ss')" -ForegroundColor Gray
