# OpenClaw Duplicate File Cleanup Framework
# Version: 1.0.0
# Description: Framework for duplicate file detection and cleanup
# Author: Hell Cat (Digital Ghost Assistant)
# Date: 2026-03-06

Write-Host "=== OpenClaw Duplicate File Cleanup Framework ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Create directory structure
$directories = @(
    "modules/duplicate/config",
    "duplicate-scans",
    "modules/duplicate/reports",
    "modules/duplicate/logs",
    "modules/duplicate/backup"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "Created directory: $dir" -ForegroundColor Green
    }
}

# Create configuration template
$configTemplate = @{
    Version = "1.0.0"
    Settings = @{
        ScanDirectories = @(
            "C:\Users\luchaochao\Downloads",
            "C:\Users\luchaochao\Desktop",
            "C:\Users\luchaochao\Documents"
        )
        ExcludeDirectories = @(
            "C:\Windows",
            "C:\Program Files",
            "C:\Program Files (x86)"
        )
        FileTypes = @(
            "*.jpg", "*.jpeg", "*.png", "*.gif", "*.bmp",
            "*.mp4", "*.avi", "*.mov", "*.mkv",
            "*.mp3", "*.wav", "*.flac",
            "*.pdf", "*.doc", "*.docx", "*.xls", "*.xlsx",
            "*.zip", "*.rar", "*.7z"
        )
        MinFileSizeKB = 100  # Skip files smaller than 100KB
        MaxFileSizeMB = 1024 # Skip files larger than 1GB
        CompareMethod = "HashAndSize"  # Options: SizeOnly, HashAndSize, Content
        HashAlgorithm = "MD5"
        AutoCleanup = $false  # Safety first - manual review
        BackupBeforeDelete = $true
        MaxScanDepth = 5
    }
    Actions = @{
        OnDuplicateFound = "LogAndReport"  # Options: LogAndReport, MoveToFolder, DeleteOldest, DeleteSmallest
        DuplicateFolder = "modules/duplicate/backup\duplicates"
        ReportFormat = "HTML"  # Options: HTML, JSON, CSV, Markdown
        EmailNotification = $true
        LogLevel = "Detailed"  # Options: Minimal, Normal, Detailed
    }
    Schedule = @{
        Enabled = $true
        Frequency = "Weekly"  # Options: Daily, Weekly, Monthly
        DayOfWeek = "Sunday"  # For weekly schedule
        Time = "02:00"
        LastRun = $null
        NextRun = $null
    }
}

# Save configuration template
$configTemplate | ConvertTo-Json -Depth 4 | Out-File "modules/duplicate/config\modules/duplicate/config-template.json" -Encoding UTF8
Write-Host "Configuration template saved: modules/duplicate/config\modules/duplicate/config-template.json" -ForegroundColor Green

# Create setup guide
$setupGuide = @'
# OpenClaw 閲嶅鏂囦欢娓呯悊绯荤粺 - 璁剧疆鎸囧崡

## 姒傝堪
閲嶅鏂囦欢娓呯悊绯荤粺甯姪鎮ㄦ娴嬪拰娓呯悊绯荤粺涓殑閲嶅鏂囦欢锛岄噴鏀剧鐩樼┖闂淬€?
## 鐩綍缁撴瀯
```
modules/duplicate/config/      # 閰嶇疆鏂囦欢
duplicate-scans/       # 鎵弿缁撴灉
modules/duplicate/reports/     # 娓呯悊鎶ュ憡
modules/duplicate/logs/        # 绯荤粺鏃ュ織
modules/duplicate/backup/      # 澶囦唤鏂囦欢锛堝垹闄ゅ墠锛?```

## 蹇€熷紑濮?
### 1. 閰嶇疆绯荤粺
1. 澶嶅埗妯℃澘鏂囦欢锛?   ```powershell
   Copy-Item modules/duplicate/config\modules/duplicate/config-template.json modules/duplicate/config\modules/duplicate/config.json
   ```
2. 缂栬緫閰嶇疆鏂囦欢锛?   - 璁剧疆瑕佹壂鎻忕殑鐩綍
   - 閰嶇疆鎺掗櫎鐩綍
   - 閫夋嫨鏂囦欢绫诲瀷
   - 璁剧疆娓呯悊閫夐」

### 2. 杩愯鎵弿
```powershell
# 娴嬭瘯鎵弿锛堜笉鎵ц娓呯悊锛?.\scan-duplicates.ps1 -Test

# 瀹屾暣鎵弿
.\scan-duplicates.ps1

# 鎵弿鐗瑰畾鐩綍
.\scan-duplicates.ps1 -Path "C:\Your\Directory"
```

### 3. 鏌ョ湅鎶ュ憡
鎵弿瀹屾垚鍚庯紝鏌ョ湅鎶ュ憡锛?- `modules/duplicate/reports\` - HTML/JSON鎶ュ憡
- `modules/duplicate/data/logs/` - 璇︾粏鏃ュ織

### 4. 鎵ц娓呯悊
```powershell
# 棰勮娓呯悊锛堜笉瀹為檯鍒犻櫎锛?.\clean-duplicates.ps1 -Preview

# 鎵ц娓呯悊锛堝浠藉悗鍒犻櫎锛?.\clean-duplicates.ps1

# 娓呯悊鐗瑰畾绫诲瀷鐨勯噸澶嶆枃浠?.\clean-duplicates.ps1 -FileType "*.jpg,*.png"
```

## 閰嶇疆閫夐」

### 鎵弿璁剧疆
- **ScanDirectories**: 瑕佹壂鎻忕殑鐩綍鍒楄〃
- **ExcludeDirectories**: 鎺掗櫎鐨勭洰褰曞垪琛?- **FileTypes**: 瑕佹鏌ョ殑鏂囦欢绫诲瀷
- **MinFileSizeKB**: 鏈€灏忔枃浠跺ぇ灏忥紙璺宠繃灏忔枃浠讹級
- **MaxFileSizeMB**: 鏈€澶ф枃浠跺ぇ灏忥紙璺宠繃澶ф枃浠讹級
- **CompareMethod**: 姣旇緝鏂规硶锛圫izeOnly, HashAndSize, Content锛?
### 娓呯悊璁剧疆
- **AutoCleanup**: 鑷姩娓呯悊锛堝缓璁涓篺alse锛屾墜鍔ㄥ鏍革級
- **BackupBeforeDelete**: 鍒犻櫎鍓嶅浠?- **OnDuplicateFound**: 鍙戠幇閲嶅鏃剁殑鎿嶄綔

### 璁″垝浠诲姟
- **Enabled**: 鍚敤瀹氭湡鎵弿
- **Frequency**: 鎵弿棰戠巼锛圖aily, Weekly, Monthly锛?- **Time**: 鎵ц鏃堕棿

## 瀹夊叏鐗规€?
1. **澶囦唤鏈哄埗**: 鍒犻櫎鍓嶈嚜鍔ㄥ浠藉埌modules/duplicate/backup
2. **棰勮妯″紡**: 鎵€鏈夋搷浣滃彲鍏堥瑙?3. **璇︾粏鏃ュ織**: 鎵€鏈夋搷浣滈兘鏈夋棩蹇楄褰?4. **鎵嬪姩瀹℃牳**: 榛樿闇€瑕佹墜鍔ㄧ‘璁?
## 闆嗘垚鍔熻兘

1. **閭欢閫氱煡**: 鎵弿瀹屾垚鍚庡彂閫佹姤鍛?2. **绯荤粺鐩戞帶**: 闆嗘垚鍒癘penClaw鐩戞帶绯荤粺
3. **鑷姩鍖?*: 鍙厤缃负璁″垝浠诲姟
4. **鎶ュ憡绯荤粺**: 澶氱鏍煎紡鐨勬姤鍛婅緭鍑?
## 鏁呴殰鎺掗櫎

### 甯歌闂
1. **鎵弿閫熷害鎱?*: 璋冩暣MaxScanDepth鎴栭檺鍒舵枃浠剁被鍨?2. **鍐呭瓨浣跨敤楂?*: 鍑忓皯鍚屾椂鎵弿鐨勬枃浠舵暟閲?3. **鏉冮檺闂**: 浠ョ鐞嗗憳韬唤杩愯

### 鏃ュ織浣嶇疆
- 鎵弿鏃ュ織: `modules/duplicate/data/logs/scan-*.log`
- 娓呯悊鏃ュ織: `modules/duplicate/data/logs/clean-*.log`
- 閿欒鏃ュ織: `modules/duplicate/data/logs/error-*.log`

## 鏀寔鐨勬枃浠剁被鍨?- 鍥剧墖: jpg, jpeg, png, gif, bmp
- 瑙嗛: mp4, avi, mov, mkv
- 闊抽: mp3, wav, flac
- 鏂囨。: pdf, doc, docx, xls, xlsx
- 鍘嬬缉鏂囦欢: zip, rar, 7z

## 娉ㄦ剰浜嬮」
1. 棣栨杩愯寤鸿浣跨敤-Test鍙傛暟
2. 娓呯悊鍓嶅姟蹇呮鏌ユ姤鍛?3. 閲嶈鏂囦欢寤鸿鎵嬪姩澶囦唤
4. 绯荤粺鏂囦欢涓嶈娓呯悊

---
*OpenClaw 閲嶅鏂囦欢娓呯悊绯荤粺 v1.0.0*
'@

$setupGuide | Out-File "modules/duplicate/config\SETUP-GUIDE.md" -Encoding UTF8
Write-Host "Setup guide saved: modules/duplicate/config\SETUP-GUIDE.md" -ForegroundColor Green

# Create test script
$testScript = @'
# Test Duplicate File System Configuration

Write-Host "=== Testing Duplicate File System ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Check directories
$directories = @(
    "modules/duplicate/config",
    "duplicate-scans",
    "modules/duplicate/reports", 
    "modules/duplicate/logs",
    "modules/duplicate/backup"
)

Write-Host "Checking directory structure..." -ForegroundColor Yellow
foreach ($dir in $directories) {
    if (Test-Path $dir) {
        Write-Host "  $dir: PASS" -ForegroundColor Green
    } else {
        Write-Host "  $dir: FAIL" -ForegroundColor Red
    }
}

# Check configuration files
Write-Host "`nChecking configuration files..." -ForegroundColor Yellow

$configFiles = @(
    "modules/duplicate/config\modules/duplicate/config-template.json",
    "modules/duplicate/config\SETUP-GUIDE.md"
)

foreach ($file in $configFiles) {
    if (Test-Path $file) {
        $size = (Get-Item $file).Length
        Write-Host "  $file: PASS ($size bytes)" -ForegroundColor Green
    } else {
        Write-Host "  $file: FAIL" -ForegroundColor Red
    }
}

# Test configuration loading
Write-Host "`nTesting configuration loading..." -ForegroundColor Yellow

$configFile = "modules/duplicate/config\modules/duplicate/config-template.json"
if (Test-Path $configFile) {
    try {
        $config = Get-Content $configFile -Raw | ConvertFrom-Json -ErrorAction Stop
        Write-Host "  Configuration loaded successfully" -ForegroundColor Green
        Write-Host "  Version: $($config.Version)" -ForegroundColor Gray
        Write-Host "  Scan directories: $($config.Settings.ScanDirectories.Count)" -ForegroundColor Gray
        Write-Host "  File types: $($config.Settings.FileTypes.Count)" -ForegroundColor Gray
    } catch {
        Write-Host "  ERROR: Cannot load configuration" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "  Configuration file not found" -ForegroundColor Red
}

# Summary
Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Copy configuration template:" -ForegroundColor Gray
Write-Host "   Copy-Item modules/duplicate/config\modules/duplicate/config-template.json modules/duplicate/config\modules/duplicate/config.json" -ForegroundColor White
Write-Host "2. Edit configuration:" -ForegroundColor Gray
Write-Host "   Edit modules/duplicate/config\modules/duplicate/config.json with your settings" -ForegroundColor White
Write-Host "3. Create scan script:" -ForegroundColor Gray
Write-Host "   Create scan-duplicates.ps1 script" -ForegroundColor White
Write-Host "4. Create cleanup script:" -ForegroundColor Gray
Write-Host "   Create clean-duplicates.ps1 script" -ForegroundColor White

Write-Host "`nFramework setup completed!" -ForegroundColor Green
Write-Host "Ready for script development" -ForegroundColor Gray
'@

$testScript | Out-File "test-modules/duplicate/config.ps1" -Encoding UTF8
Write-Host "Test script created: test-modules/duplicate/config.ps1" -ForegroundColor Green

# Summary
Write-Host "`n=== Duplicate File Cleanup Framework Created ===" -ForegroundColor Green

Write-Host "`nCreated files:" -ForegroundColor Cyan
Write-Host "  Configuration template: modules/duplicate/config\modules/duplicate/config-template.json" -ForegroundColor Gray
Write-Host "  Setup guide: modules/duplicate/config\SETUP-GUIDE.md" -ForegroundColor Gray
Write-Host "  Test script: test-modules/duplicate/config.ps1" -ForegroundColor Gray

Write-Host "`nDirectory structure:" -ForegroundColor Cyan
Write-Host "  modules/duplicate/config/      # Configuration files" -ForegroundColor Gray
Write-Host "  duplicate-scans/       # Scan results" -ForegroundColor Gray
Write-Host "  modules/duplicate/reports/     # Cleanup reports" -ForegroundColor Gray
Write-Host "  modules/duplicate/logs/        # System logs" -ForegroundColor Gray
Write-Host "  modules/duplicate/backup/      # Backup before deletion" -ForegroundColor Gray

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Review setup guide: modules/duplicate/config\SETUP-GUIDE.md" -ForegroundColor Gray
Write-Host "2. Configure duplicate file settings" -ForegroundColor Gray
Write-Host "3. Create scan-duplicates.ps1 script" -ForegroundColor Gray
Write-Host "4. Create clean-duplicates.ps1 script" -ForegroundColor Gray

Write-Host "`nEstimated time to implement: 3-4 hours" -ForegroundColor Gray

Write-Host "`nFramework creation completed!" -ForegroundColor Green
