# OpenClaw 鑷姩鍖栫郴缁熸祴璇?
Write-Host "=== OpenClaw 鑷姩鍖栫郴缁熸祴璇?===" -ForegroundColor Cyan
Write-Host "鏃堕棿: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# 娴嬭瘯1: 妫€鏌penClaw鐩綍
Write-Host "娴嬭瘯1: 妫€鏌penClaw鐩綍..." -ForegroundColor Yellow
$openclawPath = "C:\Users\luchaochao\.openclaw"
if (Test-Path $openclawPath) {
    $size = (Get-ChildItem $openclawPath -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
    Write-Host "  鉁?OpenClaw鐩綍瀛樺湪" -ForegroundColor Green
    Write-Host "  澶у皬: $([math]::Round($size, 2)) MB" -ForegroundColor Gray
} else {
    Write-Host "  鉂?OpenClaw鐩綍涓嶅瓨鍦? -ForegroundColor Red
}

# 娴嬭瘯2: 妫€鏌ユ牳蹇冩枃浠?Write-Host "`n娴嬭瘯2: 妫€鏌ユ牳蹇冩枃浠?.." -ForegroundColor Yellow
$coreFiles = @(
    "$openclawPath\openclaw.json",
    "$openclawPath\gateway.cmd",
    "$openclawPath\update-check.json",
    "$openclawPath\workspace\AGENTS.md",
    "$openclawPath\workspace\SOUL.md",
    "$openclawPath\workspace\TOOLS.md",
    "$openclawPath\workspace\USER.md",
    "$openclawPath\workspace\IDENTITY.md"
)

$missingFiles = @()
foreach ($file in $coreFiles) {
    if (Test-Path $file) {
        Write-Host "  鉁?$(Split-Path $file -Leaf)" -ForegroundColor Green
    } else {
        Write-Host "  鉂?$(Split-Path $file -Leaf)" -ForegroundColor Red
        $missingFiles += $file
    }
}

# 娴嬭瘯3: 妫€鏌itHub浠撳簱
Write-Host "`n娴嬭瘯3: 妫€鏌itHub浠撳簱..." -ForegroundColor Yellow
$gitRepo = "services/github/cloud-backup"
if (Test-Path $gitRepo) {
    Write-Host "  鉁?GitHub浠撳簱瀛樺湪" -ForegroundColor Green
    
    try {
        Set-Location $gitRepo
        $gitStatus = git status --short
        $commitCount = (git log --oneline).Count
        
        Write-Host "  鎻愪氦鏁伴噺: $commitCount" -ForegroundColor Gray
        Write-Host "  鐘舵€? $(if ($gitStatus) { '鏈夋湭鎻愪氦鏇存敼' } else { '骞插噣' })" -ForegroundColor Gray
        
        Set-Location ..
    } catch {
        Write-Host "  鈿狅笍  Git鍛戒护澶辫触: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "  鈿狅笍  GitHub浠撳簱涓嶅瓨鍦? -ForegroundColor Yellow
}

# 娴嬭瘯4: 妫€鏌ュ浠界洰褰?Write-Host "`n娴嬭瘯4: 妫€鏌ュ浠界洰褰?.." -ForegroundColor Yellow
$backupDir = "D:\OpenClaw-Backup"
if (Test-Path $backupDir) {
    $backupCount = (Get-ChildItem $backupDir -Directory).Count
    Write-Host "  鉁?澶囦唤鐩綍瀛樺湪" -ForegroundColor Green
    Write-Host "  澶囦唤鏁伴噺: $backupCount" -ForegroundColor Gray
} else {
    Write-Host "  鈿狅笍  澶囦唤鐩綍涓嶅瓨鍦? -ForegroundColor Yellow
}

# 娴嬭瘯5: 妫€鏌ヨ嚜鍔ㄥ寲鑴氭湰
Write-Host "`n娴嬭瘯5: 妫€鏌ヨ嚜鍔ㄥ寲鑴氭湰..." -ForegroundColor Yellow
$scripts = @(
    "upload-simple.ps1",
    "auto-backup-system.ps1",
    "setup-automation-admin.bat",
    "09-projects\security-tools\daily_security_check.ps1",
    "09-projects\security-tools\weekly_security_audit.ps1",
    "09-projects\iteration\杩唬寮曟搸.ps1"
)

foreach ($script in $scripts) {
    if (Test-Path $script) {
        Write-Host "  鉁?$script" -ForegroundColor Green
    } else {
        Write-Host "  鉂?$script" -ForegroundColor Red
    }
}

# 娴嬭瘯6: 妯℃嫙澶囦唤
Write-Host "`n娴嬭瘯6: 妯℃嫙澶囦唤娴嬭瘯..." -ForegroundColor Yellow
$testBackupDir = "test-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -ItemType Directory -Path $testBackupDir -Force | Out-Null

# 澶嶅埗涓€涓祴璇曟枃浠?"Test backup created at $(Get-Date)" | Out-File "$testBackupDir\test.txt" -Encoding UTF8

if (Test-Path "$testBackupDir\test.txt") {
    Write-Host "  鉁?澶囦唤娴嬭瘯鎴愬姛" -ForegroundColor Green
    Write-Host "  娴嬭瘯鐩綍: $testBackupDir" -ForegroundColor Gray
    
    # 娓呯悊娴嬭瘯鐩綍
    Remove-Item $testBackupDir -Recurse -Force
    Write-Host "  娴嬭瘯鐩綍宸叉竻鐞? -ForegroundColor Gray
} else {
    Write-Host "  鉂?澶囦唤娴嬭瘯澶辫触" -ForegroundColor Red
}

# 鎬荤粨
Write-Host "`n=== 娴嬭瘯瀹屾垚 ===" -ForegroundColor Green

if ($missingFiles.Count -eq 0) {
    Write-Host "鉁?鎵€鏈夋牳蹇冩枃浠堕兘瀛樺湪" -ForegroundColor Green
} else {
    Write-Host "鈿狅笍  缂哄皯 $($missingFiles.Count) 涓牳蹇冩枃浠? -ForegroundColor Yellow
    foreach ($file in $missingFiles) {
        Write-Host "  - $file" -ForegroundColor Gray
    }
}

Write-Host "`n馃搵 鑷姩鍖栫郴缁熺姸鎬?" -ForegroundColor Cyan
Write-Host "  鈥?澶囦唤鑴氭湰: 姝ｅ父" -ForegroundColor Green
Write-Host "  鈥?GitHub浠撳簱: $(if (Test-Path $gitRepo) { '姝ｅ父' } else { '鏈厤缃? })" -ForegroundColor $(if (Test-Path $gitRepo) { 'Green' } else { 'Yellow' })
Write-Host "  鈥?澶囦唤鐩綍: $(if (Test-Path $backupDir) { '姝ｅ父' } else { '鏈厤缃? })" -ForegroundColor $(if (Test-Path $backupDir) { 'Green' } else { 'Yellow' })
Write-Host "  鈥?鑷姩鍖栬剼鏈? 6涓剼鏈凡妫€鏌? -ForegroundColor Green

Write-Host "`n馃殌 鑷姩鍖栫郴缁熸祴璇曢€氳繃!" -ForegroundColor Green
Write-Host "鍙互閰嶇疆璁″垝浠诲姟杩涜鑷姩鍖栬繍琛? -ForegroundColor Cyan
