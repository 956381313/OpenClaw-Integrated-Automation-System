# Auto Cleanup Execute (Safe Mode)

Write-Host "=== OpenClaw Auto Cleanup Execution ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "Mode: SAFE (淇濈暀鏈€鏂板浠斤紝娓呯悊鏃х殑)" -ForegroundColor Yellow
Write-Host ""

# 瀹夊叏璁剧疆
$backupKeepCount = 3  # 淇濈暀鏈€鏂?涓浠?$logFile = "auto-cleanup-log-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
$operations = @()

# 寮€濮嬫棩蹇楄褰?Start-Transcript -Path $logFile -Append

Write-Host "1. 妫€鏌ュ浠界洰褰?.." -ForegroundColor Yellow

# 瀹氫箟澶囦唤鐩綍
$backupDirs = @(
    @{Path = "modules/backup/data"; Type = "鏂囦欢澶囦唤"},
    @{Path = "backups/system"; Type = "绯荤粺澶囦唤"},
    @{Path = "services/github/cloud-backup\simple-backups"; Type = "GitHub绠€鍗曞浠?},
    @{Path = "services/github/cloud-backup\backups"; Type = "GitHub瀹屾暣澶囦唤"}
)

$totalCleaned = 0
$totalSpaceSaved = 0

foreach ($dirInfo in $backupDirs) {
    $dir = $dirInfo.Path
    $type = $dirInfo.Type
    
    if (Test-Path $dir) {
        Write-Host "  [$type] 妫€鏌? $dir" -ForegroundColor Gray
        
        # 鑾峰彇鎵€鏈夊浠界洰褰?        $backupItems = Get-ChildItem $dir -Directory -ErrorAction SilentlyContinue
        
        if ($backupItems.Count -gt $backupKeepCount) {
            $toKeep = $backupItems | Sort-Object LastWriteTime -Descending | Select-Object -First $backupKeepCount
            $toClean = $backupItems | Where-Object { $toKeep -notcontains $_ }
            
            $cleanCount = $toClean.Count
            $spaceToSave = 0
            
            # 璁＄畻瑕佹竻鐞嗙殑绌洪棿
            foreach ($item in $toClean) {
                $size = (Get-ChildItem $item.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
                $spaceToSave += $size
            }
            
            $spaceMB = [math]::Round($spaceToSave / 1MB, 2)
            
            Write-Host "    鎵惧埌 $($backupItems.Count) 涓浠? -ForegroundColor Gray
            Write-Host "    淇濈暀鏈€鏂?$backupKeepCount 涓? -ForegroundColor Green
            Write-Host "    娓呯悊 $cleanCount 涓棫澶囦唤" -ForegroundColor Yellow
            Write-Host "    棰勮鑺傜渷绌洪棿: ${spaceMB} MB" -ForegroundColor Cyan
            
            # 璁板綍鎿嶄綔
            $operation = @{
                Type = $type
                Directory = $dir
                TotalBackups = $backupItems.Count
                KeepCount = $backupKeepCount
                CleanCount = $cleanCount
                SpaceSavedMB = $spaceMB
                ItemsToClean = $toClean.FullName
                ItemsToKeep = $toKeep.FullName
            }
            
            $operations += $operation
            
            # 鎵ц娓呯悊
            Write-Host "    鎵ц娓呯悊..." -ForegroundColor Yellow
            
            foreach ($item in $toClean) {
                try {
                    # 鍏堣绠楀ぇ灏?                    $itemSize = (Get-ChildItem $item.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
                    $itemSizeMB = [math]::Round($itemSize / 1MB, 2)
                    
                    # 鍒犻櫎鐩綍
                    Remove-Item $item.FullName -Recurse -Force -ErrorAction Stop
                    
                    Write-Host "      鉁?娓呯悊: $($item.Name) (${itemSizeMB} MB)" -ForegroundColor Green
                    
                    $totalCleaned++
                    $totalSpaceSaved += $itemSize
                    
                } catch {
                    Write-Host "      鉁?澶辫触: $($item.Name) (閿欒: $_)" -ForegroundColor Red
                }
            }
            
        } else {
            Write-Host "    鍙湁 $($backupItems.Count) 涓浠斤紝鏃犻渶娓呯悊" -ForegroundColor Gray
        }
        
    } else {
        Write-Host "  [$type] 鐩綍涓嶅瓨鍦? $dir" -ForegroundColor Yellow
    }
}

# 2. 娓呯悊绌虹洰褰?Write-Host "`n2. 娓呯悊绌虹洰褰?.." -ForegroundColor Yellow

$emptyDirs = Get-ChildItem -Recurse -Directory -ErrorAction SilentlyContinue | 
    Where-Object { (Get-ChildItem $_.FullName -Recurse -Force -ErrorAction SilentlyContinue).Count -eq 0 }

$emptyDirCount = $emptyDirs.Count

if ($emptyDirCount -gt 0) {
    Write-Host "  鎵惧埌 $emptyDirCount 涓┖鐩綍" -ForegroundColor Gray
    
    foreach ($dir in $emptyDirs) {
        try {
            Remove-Item $dir.FullName -Force -ErrorAction Stop
            Write-Host "    鉁?娓呯悊绌虹洰褰? $($dir.FullName)" -ForegroundColor Green
            $totalCleaned++
        } catch {
            Write-Host "    鉁?澶辫触: $($dir.FullName)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "  娌℃湁鎵惧埌绌虹洰褰? -ForegroundColor Gray
}

# 3. 鐢熸垚娓呯悊鎶ュ憡
Write-Host "`n3. 鐢熸垚娓呯悊鎶ュ憡..." -ForegroundColor Yellow

$reportDir = "data/reports"
if (-not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
}

$totalSpaceSavedMB = [math]::Round($totalSpaceSaved / 1MB, 2)

$report = @{
    ExecutionTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Mode = "SAFE (淇濈暀鏈€鏂?$backupKeepCount 涓浠?"
    TotalCleaned = $totalCleaned
    TotalSpaceSavedMB = $totalSpaceSavedMB
    Operations = $operations
    EmptyDirectoriesCleaned = $emptyDirCount
    LogFile = $logFile
}

$reportFile = Join-Path $reportDir "auto-cleanup-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$report | ConvertTo-Json -Depth 4 | Out-File $reportFile -Encoding UTF8

# 鐢熸垚浜虹被鍙鎶ュ憡
$humanReport = @"
# 鑷姩娓呯悊鎵ц鎶ュ憡
## 鏃堕棿: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
## 妯″紡: 瀹夊叏妯″紡 (淇濈暀鏈€鏂?$backupKeepCount 涓浠?

## 鎵ц鎽樿:
- 娓呯悊椤圭洰鎬绘暟: $totalCleaned
- 鑺傜渷绌洪棿: ${totalSpaceSavedMB} MB
- 娓呯悊鐨勭┖鐩綍: $emptyDirCount
- 鏃ュ織鏂囦欢: $logFile

## 璇︾粏鎿嶄綔:

### 澶囦唤娓呯悊:
$(foreach ($op in $operations) {
    "#### $($op.Type)"
    "- 鐩綍: $($op.Directory)"
    "- 鎬诲浠芥暟: $($op.TotalBackups)"
    "- 淇濈暀鏁? $($op.KeepCount)"
    "- 娓呯悊鏁? $($op.CleanCount)"
    "- 鑺傜渷绌洪棿: $($op.SpaceSavedMB) MB"
    ""
    if ($op.ItemsToClean.Count -gt 0) {
        "娓呯悊鐨勯」鐩?"
        foreach ($item in $op.ItemsToClean) {
            "  - $item"
        }
        ""
    }
    if ($op.ItemsToKeep.Count -gt 0) {
        "淇濈暀鐨勯」鐩?"
        foreach ($item in $op.ItemsToKeep) {
            "  - $item"
        }
        ""
    }
})

### 绌虹洰褰曟竻鐞?
- 娓呯悊鐨勭┖鐩綍鏁? $emptyDirCount

## 绯荤粺鐘舵€?
- 宸ヤ綔绌洪棿: $(Get-Location)
- 鎵ц鐢ㄦ埛: $env:USERNAME
- 璁＄畻鏈哄悕: $env:COMPUTERNAME

## 瀹夊叏璇存槑:
1. 鍙竻鐞嗕簡鏃х殑澶囦唤鐩綍
2. 淇濈暀浜嗘渶鏂扮殑 $backupKeepCount 涓浠?3. 鎵€鏈夋搷浣滃凡璁板綍鍒版棩蹇?4. 濡傛湁闂鍙煡鐪嬫棩蹇楁枃浠?
## 鍚庣画寤鸿:
1. 瀹氭湡杩愯鑷姩娓呯悊
2. 鐩戞帶纾佺洏绌洪棿浣跨敤
3. 璋冩暣淇濈暀绛栫暐濡傞渶瑕?4. 鑰冭檻浜戝浠介噸瑕佹暟鎹?
---
*OpenClaw 鑷姩娓呯悊绯荤粺 v1.0*
*瀹夊叏鎵ц瀹屾垚*
"@

$humanReportFile = Join-Path $reportDir "human-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
$humanReport | Out-File $humanReportFile -Encoding UTF8

# 鍋滄鏃ュ織璁板綍
Stop-Transcript

# 4. 瀹屾垚
Write-Host "`n=== 鑷姩娓呯悊瀹屾垚 ===" -ForegroundColor Green
Write-Host "娓呯悊椤圭洰: $totalCleaned" -ForegroundColor Cyan
Write-Host "鑺傜渷绌洪棿: ${totalSpaceSavedMB} MB" -ForegroundColor Cyan
Write-Host "鏃ュ織鏂囦欢: $logFile" -ForegroundColor Cyan
Write-Host "鎶ュ憡鏂囦欢: $humanReportFile" -ForegroundColor Cyan

Write-Host "`n鏌ョ湅鎶ュ憡:" -ForegroundColor Yellow
Write-Host "  Get-Content $humanReportFile" -ForegroundColor Gray
Write-Host "  Get-Content $logFile | Select-Object -Last 20" -ForegroundColor Gray

Write-Host "`n瀹夊叏妫€鏌?" -ForegroundColor Yellow
Write-Host "  鎵€鏈夐噸瑕佸浠藉凡淇濈暀" -ForegroundColor Green
Write-Host "  娓呯悊鎿嶄綔宸茶褰? -ForegroundColor Green
Write-Host "  鍙仮澶嶆€? 闇€瑕佷粠GitHub鎴栧叾浠栧浠芥仮澶? -ForegroundColor Gray
