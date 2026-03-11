# 宸ヤ綔绌洪棿缁煎悎鏁寸悊鑴氭湰
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "    宸ヤ綔绌洪棿缁煎悎鏁寸悊" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "鏃堕棿: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "宸ヤ綔鐩綍: $PWD" -ForegroundColor Gray
Write-Host ""

# 鍒涘缓澶囦唤鐩綍
$backupDir = "workspace-cleanup-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
Write-Host "馃搧 鍒涘缓澶囦唤鐩綍: $backupDir" -ForegroundColor Green
Write-Host ""

# 姝ラ1: 娓呯悊閲嶅鏂囦欢
Write-Host "馃攳 姝ラ1: 娓呯悊閲嶅鏂囦欢" -ForegroundColor Cyan
Write-Host "  杩愯閲嶅鏂囦欢娓呯悊绯荤粺..." -ForegroundColor Gray

# 浣跨敤鎴戜滑寮€鍙戠殑娓呯悊绯荤粺
$cleanupResult = .\clean-duplicates-optimized.ps1 -Strategy KeepNewest -Preview $false -Backup $true

if ($cleanupResult -like "*SUCCESS*") {
    Write-Host "  鉁?閲嶅鏂囦欢娓呯悊瀹屾垚" -ForegroundColor Green
} else {
    Write-Host "  鈿狅笍  閲嶅鏂囦欢娓呯悊鍙兘鏈夐棶棰? -ForegroundColor Yellow
}

Write-Host ""

# 姝ラ2: 娓呯悊鏃犵敤鏂囦欢
Write-Host "馃棏锔? 姝ラ2: 娓呯悊鏃犵敤鏂囦欢" -ForegroundColor Cyan

# 瀹氫箟瑕佹竻鐞嗙殑鏂囦欢妯″紡
$cleanupPatterns = @(
    "*.tmp",
    "*.temp",
    "*.bak",
    "~*",
    "Thumbs.db",
    ".DS_Store",
    "desktop.ini"
)

$cleanedFiles = 0
$cleanedSize = 0

foreach ($pattern in $cleanupPatterns) {
    $files = Get-ChildItem -Recurse -Filter $pattern -ErrorAction SilentlyContinue
    foreach ($file in $files) {
        try {
            # 澶囦唤鏂囦欢
            $backupPath = Join-Path $backupDir $file.FullName.Substring($PWD.Path.Length + 1)
            $backupFolder = Split-Path $backupPath -Parent
            if (-not (Test-Path $backupFolder)) {
                New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
            }
            Copy-Item -Path $file.FullName -Destination $backupPath -Force
            
            # 鍒犻櫎鏂囦欢
            Remove-Item -Path $file.FullName -Force -ErrorAction Stop
            $cleanedFiles++
            $cleanedSize += $file.Length
            Write-Host ("   鍒犻櫎: {0}" -f $file.Name) -ForegroundColor Gray
        } catch {
            Write-Host ("   鍒犻櫎澶辫触: {0} ({1})" -f $file.Name, $_.Exception.Message) -ForegroundColor Red
        }
    }
}

# 娓呯悊绌烘棩蹇楁枃浠?$emptyLogs = Get-ChildItem -Recurse -Filter "*.log" -ErrorAction SilentlyContinue | Where-Object { $_.Length -eq 0 }
foreach ($log in $emptyLogs) {
    try {
        $backupPath = Join-Path $backupDir $log.FullName.Substring($PWD.Path.Length + 1)
        $backupFolder = Split-Path $backupPath -Parent
        if (-not (Test-Path $backupFolder)) {
            New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
        }
        Copy-Item -Path $log.FullName -Destination $backupPath -Force
        Remove-Item -Path $log.FullName -Force -ErrorAction Stop
        $cleanedFiles++
        Write-Host ("   鍒犻櫎绌烘棩蹇? {0}" -f $log.Name) -ForegroundColor Gray
    } catch {
        Write-Host ("   鍒犻櫎澶辫触: {0}" -f $log.Name) -ForegroundColor Red
    }
}

$cleanedSizeMB = [math]::Round($cleanedSize / 1MB, 2)
Write-Host "  鉁?娓呯悊瀹屾垚: $cleanedFiles 涓枃浠?($cleanedSizeMB MB)" -ForegroundColor Green
Write-Host ""

# 姝ラ3: 鏁寸悊鐩綍缁撴瀯
Write-Host "馃搧 姝ラ3: 鏁寸悊鐩綍缁撴瀯" -ForegroundColor Cyan

# 鍒涘缓鏍囧噯鐩綍缁撴瀯
$standardDirs = @(
    "scripts",
    "configs",
    "docs",
    "logs",
    "backups",
    "temp",
    "reports"
)

foreach ($dir in $standardDirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host ("   鍒涘缓鐩綍: {0}" -f $dir) -ForegroundColor Gray
    }
}

Write-Host "  鉁?鐩綍缁撴瀯鏁寸悊瀹屾垚" -ForegroundColor Green
Write-Host ""

# 姝ラ4: 绉诲姩鏂囦欢鍒板悎閫傜洰褰?Write-Host "馃搫 姝ラ4: 鏁寸悊鏂囦欢" -ForegroundColor Cyan

# 绉诲姩鑴氭湰鏂囦欢鍒?scripts 鐩綍
$scriptFiles = Get-ChildItem -Filter "*.ps1" -ErrorAction SilentlyContinue | Where-Object { $_.Directory.Name -ne "scripts" }
foreach ($script in $scriptFiles) {
    try {
        Move-Item -Path $script.FullName -Destination "tools/scripts/" -Force -ErrorAction Stop
        Write-Host ("   绉诲姩鑴氭湰: {0} -> tools/scripts/" -f $script.Name) -ForegroundColor Gray
    } catch {
        Write-Host ("   绉诲姩澶辫触: {0}" -f $script.Name) -ForegroundColor Red
    }
}

# 绉诲姩閰嶇疆鏂囦欢鍒?configs 鐩綍
$configFiles = Get-ChildItem -Filter "*.json" -ErrorAction SilentlyContinue | Where-Object { $_.Directory.Name -ne "configs" -and $_.Directory.Name -ne "modules/duplicate/config" -and $_.Directory.Name -ne "modules/email/config" }
foreach ($config in $configFiles) {
    try {
        Move-Item -Path $config.FullName -Destination "configs\" -Force -ErrorAction Stop
        Write-Host ("   绉诲姩閰嶇疆: {0} -> configs\" -f $config.Name) -ForegroundColor Gray
    } catch {
        Write-Host ("   绉诲姩澶辫触: {0}" -f $config.Name) -ForegroundColor Red
    }
}

# 绉诲姩鏂囨。鏂囦欢鍒?docs 鐩綍
$docFiles = Get-ChildItem -Filter "*.md" -ErrorAction SilentlyContinue | Where-Object { $_.Directory.Name -ne "docs" -and $_.Directory.Name -ne "core/memory" }
foreach ($doc in $docFiles) {
    try {
        Move-Item -Path $doc.FullName -Destination "docs\" -Force -ErrorAction Stop
        Write-Host ("   绉诲姩鏂囨。: {0} -> docs\" -f $doc.Name) -ForegroundColor Gray
    } catch {
        Write-Host ("   绉诲姩澶辫触: {0}" -f $doc.Name) -ForegroundColor Red
    }
}

Write-Host "  鉁?鏂囦欢鏁寸悊瀹屾垚" -ForegroundColor Green
Write-Host ""

# 姝ラ5: 娓呯悊绌虹洰褰?Write-Host "馃搨 姝ラ5: 娓呯悊绌虹洰褰? -ForegroundColor Cyan

$emptyDirs = Get-ChildItem -Directory -Recurse -ErrorAction SilentlyContinue | Where-Object { 
    (Get-ChildItem -Path $_.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0 
}

$removedDirs = 0
foreach ($dir in $emptyDirs) {
    try {
        Remove-Item -Path $dir.FullName -Force -Recurse -ErrorAction Stop
        $removedDirs++
        Write-Host ("   鍒犻櫎绌虹洰褰? {0}" -f $dir.Name) -ForegroundColor Gray
    } catch {
        Write-Host ("   鍒犻櫎澶辫触: {0}" -f $dir.Name) -ForegroundColor Red
    }
}

Write-Host "  鉁?娓呯悊绌虹洰褰曞畬鎴? $removedDirs 涓洰褰? -ForegroundColor Green
Write-Host ""

# 姝ラ6: 鐢熸垚鏁寸悊鎶ュ憡
Write-Host "馃搳 姝ラ6: 鐢熸垚鏁寸悊鎶ュ憡" -ForegroundColor Cyan

$reportContent = @"
# 宸ヤ綔绌洪棿鏁寸悊鎶ュ憡
鐢熸垚鏃堕棿: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
宸ヤ綔鐩綍: $PWD

## 鏁寸悊鎽樿
- 澶囦唤鐩綍: $backupDir
- 娓呯悊鏃犵敤鏂囦欢: $cleanedFiles 涓?($cleanedSizeMB MB)
- 娓呯悊绌虹洰褰? $removedDirs 涓?- 閲嶅鏂囦欢娓呯悊: 宸叉墽琛?
## 鐩綍缁撴瀯
$(Get-ChildItem -Directory | Sort-Object Name | ForEach-Object { "- $($_.Name)" }) | Out-String

## 鏂囦欢缁熻
$(Get-ChildItem -Recurse -File | Group-Object Extension | Sort-Object Count -Descending | ForEach-Object { 
    $size = ($_.Group | Measure-Object -Property Length -Sum).Sum
    $sizeMB = [math]::Round($size / 1MB, 2)
    "- $($_.Name): $($_.Count) 涓枃浠?($sizeMB MB)"
}) | Out-String

## 寤鸿
1. 瀹氭湡杩愯閲嶅鏂囦欢娓呯悊绯荤粺
2. 娓呯悊鏃у浠芥枃浠?(>30澶?
3. 鍘嬬缉澶ф棩蹇楁枃浠?4. 淇濇寔鐩綍缁撴瀯鏁存磥
"@

$reportPath = "workspace-cleanup-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
$reportContent | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host "  馃搫 鏁寸悊鎶ュ憡宸蹭繚瀛? $reportPath" -ForegroundColor Green
Write-Host ""

# 鏈€缁堢粺璁?Write-Host "================================================" -ForegroundColor Cyan
Write-Host "    鏁寸悊瀹屾垚鎬荤粨" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "鉁?瀹屾垚鐨勫伐浣?" -ForegroundColor Green
Write-Host "  1. 娓呯悊閲嶅鏂囦欢 (浣跨敤绯荤粺)" -ForegroundColor Gray
Write-Host "  2. 娓呯悊鏃犵敤鏂囦欢: $cleanedFiles 涓?($cleanedSizeMB MB)" -ForegroundColor Gray
Write-Host "  3. 鏁寸悊鐩綍缁撴瀯" -ForegroundColor Gray
Write-Host "  4. 鏁寸悊鏂囦欢鍒版爣鍑嗙洰褰? -ForegroundColor Gray
Write-Host "  5. 娓呯悊绌虹洰褰? $removedDirs 涓? -ForegroundColor Gray
Write-Host "  6. 鐢熸垚璇︾粏鎶ュ憡" -ForegroundColor Gray
Write-Host ""
Write-Host "馃搧 澶囦唤浣嶇疆: $backupDir" -ForegroundColor Cyan
Write-Host "馃搫 鎶ュ憡鏂囦欢: $reportPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "馃挕 鍚庣画寤鸿:" -ForegroundColor Yellow
Write-Host "  - 瀹氭湡杩愯閲嶅鏂囦欢娓呯悊绯荤粺" -ForegroundColor Gray
Write-Host "  - 姣忔湀杩涜涓€娆″伐浣滅┖闂存暣鐞? -ForegroundColor Gray
Write-Host "  - 淇濇寔鐩綍缁撴瀯鏁存磥" -ForegroundColor Gray
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
