# OpenClaw 浠撳簱鏁寸悊绯荤粺涓昏剼鏈?
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   OpenClaw 鑷姩鍖栨暣鐞嗗綊绾充粨搴撶郴缁? -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "鏃堕棿: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "鐗堟湰: 1.0.0" -ForegroundColor Gray
Write-Host ""

# 閰嶇疆
$Config = @{
    WorkspaceRoot = "C:\Users\luchaochao\.openclaw\workspace"
    RepoOrgRoot = "modules/organization"
    LogFile = "repository-organization.log"
    MaxFiles = 1000  # 姣忔澶勭悊鐨勬渶澶ф枃浠舵暟
}

# 鍒涘缓鏃ュ織鐩綍
$logDir = Split-Path $Config.LogFile -Parent
if ($logDir -and -not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
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

# 1. 鏁版嵁閲囬泦
Write-Log "姝ラ1: 鏁版嵁閲囬泦" -Level "INFO"
function Collect-Data {
    Write-Log "寮€濮嬫暟鎹噰闆?.." -Level "INFO"
    
    $collectionDir = Join-Path $Config.RepoOrgRoot "01-data-collection"
    if (-not (Test-Path $collectionDir)) {
        New-Item -ItemType Directory -Path $collectionDir -Force | Out-Null
        Write-Log "鍒涘缓鏁版嵁閲囬泦鐩綍: $collectionDir" -Level "INFO"
    }
    
    # 鏀堕泦宸ヤ綔鍖烘枃浠?    $workspaceFiles = Get-ChildItem $Config.WorkspaceRoot -Recurse -File | 
        Select-Object -First $Config.MaxFiles
    
    $fileCount = $workspaceFiles.Count
    Write-Log "鎵惧埌 $fileCount 涓枃浠堕渶瑕佸鐞? -Level "INFO"
    
    # 鍒涘缓閲囬泦鎶ュ憡
    $collectionReport = @{
        CollectionTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Source = $Config.WorkspaceRoot
        FileCount = $fileCount
        Files = @()
    }
    
    $processedCount = 0
    foreach ($file in $workspaceFiles) {
        $fileInfo = @{
            Name = $file.Name
            Path = $file.FullName
            Size = "$([math]::Round($file.Length / 1KB, 2)) KB"
            LastModified = $file.LastWriteTime
            Extension = $file.Extension
        }
        
        $collectionReport.Files += $fileInfo
        $processedCount++
        
        if ($processedCount % 100 -eq 0) {
            Write-Log "宸插鐞?$processedCount/$fileCount 涓枃浠? -Level "INFO"
        }
    }
    
    # 淇濆瓨閲囬泦鎶ュ憡
    $reportFile = Join-Path $collectionDir "collection-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $collectionReport | ConvertTo-Json -Depth 3 | Out-File $reportFile -Encoding UTF8
    
    Write-Log "鏁版嵁閲囬泦瀹屾垚锛屾姤鍛婁繚瀛樺埌: $reportFile" -Level "SUCCESS"
    
    return @{
        FileCount = $fileCount
        ReportFile = $reportFile
        Files = $workspaceFiles
    }
}

# 2. 绠€鍗曞垎绫?Write-Log "姝ラ2: 鏂囦欢鍒嗙被" -Level "INFO"
function Classify-Files {
    param($Files)
    
    Write-Log "寮€濮嬫枃浠跺垎绫?.." -Level "INFO"
    
    $classificationDir = Join-Path $Config.RepoOrgRoot "03-classification"
    if (-not (Test-Path $classificationDir)) {
        New-Item -ItemType Directory -Path $classificationDir -Force | Out-Null
        Write-Log "鍒涘缓鍒嗙被鐩綍: $classificationDir" -Level "INFO"
    }
    
    # 鍒嗙被瑙勫垯
    $classificationRules = @{
        "鏂囨。" = @(".md", ".txt", ".doc", ".docx")
        "鑴氭湰" = @(".ps1", ".bat", ".sh", ".py")
        "閰嶇疆" = @(".json", ".yml", ".yaml", ".xml", ".config")
        "鏁版嵁" = @(".csv", ".log", ".db", ".sql")
        "澶囦唤" = @(".bak", ".backup", ".old")
        "鍏朵粬" = @()  # 榛樿鍒嗙被
    }
    
    $classificationResults = @{
        TotalFiles = $Files.Count
        Categories = @{}
        Summary = @{}
    }
    
    # 鍒濆鍖栧垎绫荤粺璁?    foreach ($category in $classificationRules.Keys) {
        $classificationResults.Categories[$category] = @()
        $classificationResults.Summary[$category] = 0
    }
    
    # 鍒嗙被澶勭悊
    $processedCount = 0
    foreach ($file in $Files) {
        $classified = $false
        
        foreach ($category in $classificationRules.Keys) {
            $extensions = $classificationRules[$category]
            foreach ($ext in $extensions) {
                if ($file.Extension -eq $ext) {
                    $classificationResults.Categories[$category] += @{
                        Name = $file.Name
                        Path = $file.FullName
                        Size = "$([math]::Round($file.Length / 1KB, 2)) KB"
                        Extension = $file.Extension
                    }
                    $classificationResults.Summary[$category]++
                    $classified = $true
                    break
                }
            }
            if ($classified) { break }
        }
        
        # 鏈垎绫荤殑鏂囦欢褰掑埌"鍏朵粬"
        if (-not $classified) {
            $classificationResults.Categories["鍏朵粬"] += @{
                Name = $file.Name
                Path = $file.FullName
                Size = "$([math]::Round($file.Length / 1KB, 2)) KB"
                Extension = $file.Extension
            }
            $classificationResults.Summary["鍏朵粬"]++
        }
        
        $processedCount++
        if ($processedCount % 100 -eq 0) {
            Write-Log "宸插垎绫?$processedCount/$($Files.Count) 涓枃浠? -Level "INFO"
        }
    }
    
    # 淇濆瓨鍒嗙被缁撴灉
    $resultFile = Join-Path $classificationDir "classification-results-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $classificationResults | ConvertTo-Json -Depth 3 | Out-File $resultFile -Encoding UTF8
    
    # 鐢熸垚鍒嗙被鎶ュ憡
    $report = @"
# 鏂囦欢鍒嗙被鎶ュ憡
## 鏃堕棿: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
## 鎬绘枃浠舵暟: $($classificationResults.TotalFiles)

## 鍒嗙被缁熻:
$(foreach ($category in $classificationResults.Summary.Keys | Sort-Object) {
    $count = $classificationResults.Summary[$category]
    $percentage = [math]::Round(($count / $classificationResults.TotalFiles) * 100, 2)
    "- **$category**: $count 涓枃浠?($percentage%)"
})

## 璇︾粏鍒嗙被:
$(foreach ($category in $classificationResults.Categories.Keys | Sort-Object) {
    $files = $classificationResults.Categories[$category]
    if ($files.Count -gt 0) {
        "### $category ($($files.Count) 涓枃浠?"
        foreach ($file in $files) {
            "  - $($file.Name) ($($file.Size))"
        }
        ""
    }
})
"@
    
    $reportFile = Join-Path $classificationDir "classification-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
    $report | Out-File $reportFile -Encoding UTF8
    
    Write-Log "鏂囦欢鍒嗙被瀹屾垚锛岀粨鏋滀繚瀛樺埌: $resultFile" -Level "SUCCESS"
    Write-Log "鍒嗙被鎶ュ憡: $reportFile" -Level "INFO"
    
    return $classificationResults
}

# 3. 鐢熸垚鐭ヨ瘑搴?Write-Log "姝ラ3: 鐢熸垚鐭ヨ瘑搴? -Level "INFO"
function Build-KnowledgeBase {
    param($ClassificationResults)
    
    Write-Log "寮€濮嬫瀯寤虹煡璇嗗簱..." -Level "INFO"
    
    $knowledgeDir = Join-Path $Config.RepoOrgRoot "05-knowledge-base"
    if (-not (Test-Path $knowledgeDir)) {
        New-Item -ItemType Directory -Path $knowledgeDir -Force | Out-Null
        Write-Log "鍒涘缓鐭ヨ瘑搴撶洰褰? $knowledgeDir" -Level "INFO"
    }
    
    # 鍒涘缓鐭ヨ瘑搴撶粨鏋?    $knowledgeBase = @{
        Metadata = @{
            Created = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            TotalFiles = $ClassificationResults.TotalFiles
            Source = $Config.WorkspaceRoot
        }
        Categories = @{}
        Statistics = @{
            FileTypes = @{}
            FileSizes = @{
                TotalKB = 0
                AverageKB = 0
            }
            Timeline = @{
                LastUpdated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                FirstFile = $null
                LastFile = $null
            }
        }
    }
    
    # 澶勭悊姣忎釜鍒嗙被
    foreach ($category in $ClassificationResults.Categories.Keys) {
        $files = $ClassificationResults.Categories[$category]
        if ($files.Count -gt 0) {
            $knowledgeBase.Categories[$category] = @{
                Count = $files.Count
                Files = $files
                Summary = "鍖呭惈 $($files.Count) 涓?category 鏂囦欢"
            }
        }
    }
    
    # 淇濆瓨鐭ヨ瘑搴?    $kbFile = Join-Path $knowledgeDir "knowledge-base-$(Get-Date -Format 'yyyyMMdd').json"
    $knowledgeBase | ConvertTo-Json -Depth 4 | Out-File $kbFile -Encoding UTF8
    
    # 鐢熸垚鐭ヨ瘑搴撴憳瑕?    $summary = @"
# OpenClaw 鐭ヨ瘑搴撴憳瑕?## 鐢熸垚鏃堕棿: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
## 鏁版嵁婧? $($Config.WorkspaceRoot)
## 鎬绘枃浠舵暟: $($ClassificationResults.TotalFiles)

## 鐭ヨ瘑鍒嗙被:
$(foreach ($category in $knowledgeBase.Categories.Keys | Sort-Object) {
    $catInfo = $knowledgeBase.Categories[$category]
    "- **$category**: $($catInfo.Count) 涓枃浠?
})

## 鐭ヨ瘑搴撲俊鎭?
- 鐭ヨ瘑搴撴枃浠? $kbFile
- 鏈€鍚庢洿鏂? $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
- 鍖呭惈鍒嗙被: $($knowledgeBase.Categories.Keys.Count) 涓?
## 浣跨敤璇存槑:
1. 鏌ョ湅瀹屾暣鐭ヨ瘑搴? $kbFile
2. 鎼滅储鐗瑰畾鏂囦欢: 浣跨敤鍒嗙被淇℃伅
3. 鍒嗘瀽鏂囦欢鍒嗗竷: 鍙傝€冨垎绫荤粺璁?
---
*姝ょ煡璇嗗簱鐢?OpenClaw 鑷姩鍖栨暣鐞嗙郴缁熺敓鎴?
"@
    
    $summaryFile = Join-Path $knowledgeDir "knowledge-summary-$(Get-Date -Format 'yyyyMMdd').md"
    $summary | Out-File $summaryFile -Encoding UTF8
    
    Write-Log "鐭ヨ瘑搴撴瀯寤哄畬鎴愶紝淇濆瓨鍒? $kbFile" -Level "SUCCESS"
    Write-Log "鐭ヨ瘑搴撴憳瑕? $summaryFile" -Level "INFO"
    
    return @{
        KnowledgeBaseFile = $kbFile
        SummaryFile = $summaryFile
        TotalCategories = $knowledgeBase.Categories.Keys.Count
    }
}

# 涓绘祦绋?try {
    Write-Log "寮€濮嬩粨搴撴暣鐞嗘祦绋?.." -Level "INFO"
    
    # 1. 鏁版嵁閲囬泦
    $collectionResult = Collect-Data
    
    # 2. 鏂囦欢鍒嗙被
    $classificationResult = Classify-Files -Files $collectionResult.Files
    
    # 3. 鏋勫缓鐭ヨ瘑搴?    $knowledgeResult = Build-KnowledgeBase -ClassificationResults $classificationResult
    
    # 鐢熸垚鏈€缁堟姤鍛?    Write-Log "鐢熸垚鏈€缁堟暣鐞嗘姤鍛?.." -Level "INFO"
    
    $finalReport = @"
# OpenClaw 浠撳簱鏁寸悊鎶ュ憡
## 鏁寸悊鏃堕棿: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
## 鏁寸悊缁撴灉鎽樿

### 馃搳 鏁寸悊缁熻
- **鎬诲鐞嗘枃浠?*: $($collectionResult.FileCount) 涓?- **鍒嗙被鏁伴噺**: $($knowledgeResult.TotalCategories) 涓垎绫?- **鐭ヨ瘑搴撴枃浠?*: $($knowledgeResult.KnowledgeBaseFile)
- **鏁寸悊鎶ュ憡**: $($knowledgeResult.SummaryFile)

### 馃梻锔?鏂囦欢鍒嗙被鍒嗗竷
$(foreach ($category in $classificationResult.Summary.Keys | Sort-Object) {
    $count = $classificationResult.Summary[$category]
    $percentage = [math]::Round(($count / $classificationResult.TotalFiles) * 100, 2)
    "- $category: $count 鏂囦欢 ($percentage%)"
})

### 馃搧 鐢熸垚鐨勬枃浠?1. **鏁版嵁閲囬泦鎶ュ憡**: $($collectionResult.ReportFile)
2. **鍒嗙被缁撴灉鏂囦欢**: 鍦?03-classification/ 鐩綍
3. **鐭ヨ瘑搴撴枃浠?*: $($knowledgeResult.KnowledgeBaseFile)
4. **鐭ヨ瘑搴撴憳瑕?*: $($knowledgeResult.SummaryFile)
5. **杩愯鏃ュ織**: $($Config.LogFile)

### 馃殌 涓嬩竴姝ュ缓璁?1. 鏌ョ湅鐭ヨ瘑搴撴憳瑕佷簡瑙ｆ枃浠跺垎甯?2. 鏍规嵁闇€瑕佽皟鏁村垎绫昏鍒?3. 璁剧疆鑷姩鍖栧畾鏃舵暣鐞?4. 鎵╁睍鏁寸悊鍔熻兘锛堝鍐呭鍒嗘瀽锛?
### 馃摓 鏀寔淇℃伅
- 鏃ュ織鏂囦欢: $($Config.LogFile)
- 閰嶇疆鐩綍: $($Config.RepoOrgRoot)/09-configuration/
- 鑴氭湰浣嶇疆: organize-repository.ps1

---
*鎶ュ憡鐢熸垚鏃堕棿: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')*
*OpenClaw 鑷姩鍖栨暣鐞嗙郴缁?v1.0.0*
"@
    
    $finalReportFile = "repository-organization-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
    $finalReport | Out-File $finalReportFile -Encoding UTF8
    
    Write-Log "========================================" -ForegroundColor Green
    Write-Log "浠撳簱鏁寸悊瀹屾垚!" -Level "SUCCESS"
    Write-Log "鎬诲鐞嗘枃浠? $($collectionResult.FileCount)" -Level "INFO"
    Write-Log "鍒嗙被鏁伴噺: $($knowledgeResult.TotalCategories)" -Level "INFO"
    Write-Log "鐭ヨ瘑搴撴枃浠? $($knowledgeResult.KnowledgeBaseFile)" -Level "INFO"
    Write-Log "鏁寸悊鎶ュ憡: $finalReportFile" -Level "INFO"
    Write-Log "鏃ュ織鏂囦欢: $($Config.LogFile)" -Level "INFO"
    
} catch {
    Write-Log "鏁寸悊杩囩▼鍑洪敊: $($_.Exception.Message)" -Level "ERROR"
    Write-Log "閿欒璇︽儏: $($_.ScriptStackTrace)" -Level "ERROR"
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "OpenClaw 浠撳簱鏁寸悊绯荤粺杩愯瀹屾垚!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "馃搵 鐢熸垚鐨勬枃浠?" -ForegroundColor Cyan
Write-Host "  鈥?鏁寸悊鎶ュ憡: repository-organization-report-*.md" -ForegroundColor Gray
Write-Host "  鈥?鐭ヨ瘑搴撴枃浠? modules/organization/05-knowledge-base/" -ForegroundColor Gray
Write-Host "  鈥?鍒嗙被缁撴灉: modules/organization/03-classification/" -ForegroundColor Gray
Write-Host "  鈥?杩愯鏃ュ織: $($Config.LogFile)" -ForegroundColor Gray
Write-Host ""
Write-Host "馃殌 蹇€熷懡浠?" -ForegroundColor Yellow
Write-Host "  # 鍐嶆杩愯鏁寸悊" -ForegroundColor Gray
Write-Host "  .\organize-repository.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "  # 鏌ョ湅鐭ヨ瘑搴? -ForegroundColor Gray
Write-Host "  Get-Content modules/organization\05-knowledge-base\knowledge-summary-*.md" -ForegroundColor Gray
Write-Host ""
Write-Host "  # 鏌ョ湅鍒嗙被缁熻" -ForegroundColor Gray
Write-Host "  Get-Content modules/organization\03-classification\classification-report-*.md" -ForegroundColor Gray
