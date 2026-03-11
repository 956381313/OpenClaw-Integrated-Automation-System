# OpenClaw 绠€鍗曡嚜鍔ㄥ寲澶囦唤

Write-Host "=== OpenClaw 鑷姩鍖栧浠?===" -ForegroundColor Cyan
Write-Host "鏃堕棿: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# 閰嶇疆
$sourcePath = "C:\Users\luchaochao\.openclaw"
$backupRoot = "D:\OpenClaw-Backup"
$backupName = "backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$backupPath = Join-Path $backupRoot $backupName

# 鍒涘缓鐩綍
if (-not (Test-Path $backupRoot)) {
    New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
    Write-Host "鍒涘缓澶囦唤鐩綍: $backupRoot" -ForegroundColor Green
}

# 妫€鏌ユ簮鐩綍
if (-not (Test-Path $sourcePath)) {
    Write-Host "閿欒: OpenClaw鐩綍涓嶅瓨鍦? $sourcePath" -ForegroundColor Red
    exit 1
}

# 鍒涘缓澶囦唤
Write-Host "鍒涘缓澶囦唤: $backupName" -ForegroundColor Cyan
New-Item -ItemType Directory -Path $backupPath -Force | Out-Null

# 澶嶅埗鏍稿績鏂囦欢
$files = @(
    "$sourcePath\openclaw.json",
    "$sourcePath\gateway.cmd", 
    "$sourcePath\update-check.json",
    "$sourcePath\workspace\AGENTS.md",
    "$sourcePath\workspace\SOUL.md",
    "$sourcePath\workspace\TOOLS.md",
    "$sourcePath\workspace\USER.md",
    "$sourcePath\workspace\IDENTITY.md"
)

$fileCount = 0
foreach ($file in $files) {
    if (Test-Path $file) {
        $fileName = Split-Path $file -Leaf
        Copy-Item $file "$backupPath\$fileName" -Force
        $fileCount++
        Write-Host "  澶嶅埗: $fileName" -ForegroundColor Gray
    }
}

# 鍒涘缓澶囦唤淇℃伅
$info = @{
    BackupTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    FileCount = $fileCount
    Source = $sourcePath
    Backup = $backupPath
}

$infoJson = $info | ConvertTo-Json
$infoJson | Out-File "$backupPath\backup-info.json" -Encoding UTF8
$fileCount++

Write-Host "澶囦唤瀹屾垚! 鏂囦欢鏁伴噺: $fileCount" -ForegroundColor Green
Write-Host "澶囦唤浣嶇疆: $backupPath" -ForegroundColor Cyan

# 灏濊瘯涓婁紶鍒癎itHub
Write-Host "`n灏濊瘯涓婁紶鍒癎itHub..." -ForegroundColor Cyan

$gitRepo = "services/github/cloud-backup"
if (Test-Path $gitRepo) {
    try {
        Set-Location $gitRepo
        
        # 鎷夊彇鏈€鏂?        git pull origin main 2>$null
        
        # 澶嶅埗澶囦唤
        $targetDir = "auto-backups\$backupName"
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        Copy-Item "..\$backupPath\*" $targetDir -Recurse -Force
        
        # 鎻愪氦
        git add $targetDir
        git commit -m "鑷姩澶囦唤: $backupName" -m "鏃堕棿: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -m "鏂囦欢: $fileCount"
        
        # 鎺ㄩ€?        git push origin main
        
        Write-Host "GitHub涓婁紶鎴愬姛!" -ForegroundColor Green
        
        # 鑾峰彇鎻愪氦淇℃伅
        $commitHash = git log --oneline -1
        Write-Host "鎻愪氦: $commitHash" -ForegroundColor Gray
        
        Set-Location ..
        
    } catch {
        Write-Host "GitHub涓婁紶澶辫触: $_" -ForegroundColor Yellow
        Write-Host "澶囦唤宸蹭繚瀛樺湪鏈湴: $backupPath" -ForegroundColor Gray
    }
} else {
    Write-Host "GitHub浠撳簱涓嶅瓨鍦紝澶囦唤淇濆瓨鍦ㄦ湰鍦? -ForegroundColor Yellow
}

Write-Host "`n=== 澶囦唤瀹屾垚 ===" -ForegroundColor Green
Write-Host "澶囦唤鍚嶇О: $backupName" -ForegroundColor Cyan
Write-Host "鏂囦欢鏁伴噺: $fileCount" -ForegroundColor Cyan
Write-Host "澶囦唤浣嶇疆: $backupPath" -ForegroundColor Cyan

# 鍒涘缓璁″垝浠诲姟鍛戒护
Write-Host "`n馃搵 鍒涘缓璁″垝浠诲姟鍛戒护:" -ForegroundColor Yellow
Write-Host "schtasks /create /tn `"OpenClaw-Backup`" /tr `"powershell -ExecutionPolicy Bypass -File '$PWD\auto-backup.ps1'`" /sc hourly /st 00:00" -ForegroundColor Gray
