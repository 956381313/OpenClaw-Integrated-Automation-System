# OpenClaw 绠€鍗曚粨搴撴暣鐞嗚剼鏈?
Write-Host "=== OpenClaw 浠撳簱鏁寸悊绯荤粺 ===" -ForegroundColor Cyan
Write-Host "鏃堕棿: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# 閰嶇疆
$workspaceRoot = "C:\Users\luchaochao\.openclaw\workspace"
$repoOrgRoot = "modules/organization"
$logFile = "repo-organization.log"

# 1. 鍒涘缓鐩綍缁撴瀯
Write-Host "1. 鍒涘缓鐩綍缁撴瀯..." -ForegroundColor Yellow

$dirs = @(
    "01-data-collection",
    "02-preprocessing", 
    "03-classification",
    "04-summarization",
    "05-knowledge-base",
    "06-search-retrieval",
    "07-automation",
    "08-monitoring",
    "09-configuration"
)

foreach ($dir in $dirs) {
    $fullPath = Join-Path $repoOrgRoot $dir
    if (-not (Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Host "  鍒涘缓: $dir" -ForegroundColor Green
    } else {
        Write-Host "  宸插瓨鍦? $dir" -ForegroundColor Gray
    }
}

# 2. 鎵弿宸ヤ綔鍖烘枃浠?Write-Host "`n2. 鎵弿宸ヤ綔鍖烘枃浠?.." -ForegroundColor Yellow

$files = Get-ChildItem $workspaceRoot -Recurse -File | Where-Object {
    $_.Extension -in @('.md', '.ps1', '.bat', '.json', '.txt', '.log', '.yml', '.yaml', '.xml')
} | Select-Object -First 200

$fileCount = $files.Count
Write-Host "  鎵惧埌 $fileCount 涓枃浠? -ForegroundColor Green

# 3. 绠€鍗曞垎绫?Write-Host "`n3. 鏂囦欢鍒嗙被..." -ForegroundColor Yellow

$categories = @{
    "鏂囨。" = @()
    "鑴氭湰" = @() 
    "閰嶇疆" = @()
    "鏃ュ織" = @()
    "鍏朵粬" = @()
}

foreach ($file in $files) {
    switch -Wildcard ($file.Extension) {
        ".md" { $categories.鏂囨。 += $file }
        ".txt" { $categories.鏂囨。 += $file }
        ".ps1" { $categories.鑴氭湰 += $file }
        ".bat" { $categories.鑴氭湰 += $file }
        ".json" { $categories.閰嶇疆 += $file }
        ".yml" { $categories.閰嶇疆 += $file }
        ".yaml" { $categories.閰嶇疆 += $file }
        ".xml" { $categories.閰嶇疆 += $file }
        ".log" { $categories.鏃ュ織 += $file }
        default { $categories.鍏朵粬 += $file }
    }
}

# 鏄剧ず鍒嗙被缁撴灉
Write-Host "`n鍒嗙被缁撴灉:" -ForegroundColor Cyan
foreach ($category in $categories.Keys) {
    $count = $categories[$category].Count
    $percentage = if ($fileCount -gt 0) { [math]::Round(($count / $fileCount) * 100, 1) } else { 0 }
    Write-Host "  $category : $count 鏂囦欢 ($percentage%)" -ForegroundColor Gray
}

# 4. 淇濆瓨鍒嗙被缁撴灉
Write-Host "`n4. 淇濆瓨鍒嗙被缁撴灉..." -ForegroundColor Yellow

$classificationDir = Join-Path $repoOrgRoot "03-classification"
$resultFile = Join-Path $classificationDir "simple-classification-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"

$results = @{
    ScanTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    TotalFiles = $fileCount
    Source = $workspaceRoot
    Categories = @{}
}

foreach ($category in $categories.Keys) {
    $fileList = @()
    foreach ($file in $categories[$category]) {
        $fileList += @{
            Name = $file.Name
            Path = $file.FullName
            Size = "$([math]::Round($file.Length / 1KB, 2)) KB"
            Extension = $file.Extension
        }
    }
    $results.Categories[$category] = $fileList
}

$results | ConvertTo-Json -Depth 3 | Out-File $resultFile -Encoding UTF8
Write-Host "  缁撴灉淇濆瓨鍒? $resultFile" -ForegroundColor Green

# 5. 鐢熸垚鐭ヨ瘑搴?Write-Host "`n5. 鐢熸垚鐭ヨ瘑搴?.." -ForegroundColor Yellow

$knowledgeDir = Join-Path $repoOrgRoot "05-knowledge-base"
$kbFile = Join-Path $knowledgeDir "simple-knowledge-$(Get-Date -Format 'yyyyMMdd').json"

$knowledgeBase = @{
    Metadata = @{
        Created = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        TotalFiles = $fileCount
        Source = $workspaceRoot
    }
    Statistics = @{
        ByCategory = @{}
        ByExtension = @{}
    }
}

# 鎸夊垎绫荤粺璁?foreach ($category in $categories.Keys) {
    $knowledgeBase.Statistics.ByCategory[$category] = $categories[$category].Count
}

# 鎸夋墿灞曞悕缁熻
$extStats = @{}
foreach ($file in $files) {
    $ext = $file.Extension
    if (-not $extStats.ContainsKey($ext)) {
        $extStats[$ext] = 0
    }
    $extStats[$ext]++
}

$knowledgeBase.Statistics.ByExtension = $extStats

$knowledgeBase | ConvertTo-Json -Depth 3 | Out-File $kbFile -Encoding UTF8
Write-Host "  鐭ヨ瘑搴撲繚瀛樺埌: $kbFile" -ForegroundColor Green

# 6. 鐢熸垚鎶ュ憡
Write-Host "`n6. 鐢熸垚鏁寸悊鎶ュ憡..." -ForegroundColor Yellow

$report = @"
# OpenClaw 浠撳簱鏁寸悊鎶ュ憡
## 鏁寸悊鏃堕棿: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
## 鎵弿鐩綍: $workspaceRoot
## 澶勭悊鏂囦欢: $fileCount 涓?
## 鍒嗙被缁熻
$(foreach ($category in $categories.Keys | Sort-Object) {
    $count = $categories[$category].Count
    $percentage = if ($fileCount -gt 0) { [math]::Round(($count / $fileCount) * 100, 1) } else { 0 }
    "- **$category**: $count 鏂囦欢 ($percentage%)"
})

## 鏂囦欢绫诲瀷鍒嗗竷
$(foreach ($ext in $extStats.Keys | Sort-Object) {
    $count = $extStats[$ext]
    $percentage = if ($fileCount -gt 0) { [math]::Round(($count / $fileCount) * 100, 1) } else { 0 }
    "- $ext: $count 鏂囦欢 ($percentage%)"
})

## 鐢熸垚鐨勬枃浠?1. 鍒嗙被缁撴灉: $resultFile
2. 鐭ヨ瘑搴? $kbFile
3. 鏁寸悊鎶ュ憡: 褰撳墠鏂囦欢

## 绯荤粺淇℃伅
- 鏁寸悊绯荤粺鐗堟湰: 1.0.0
- 杩愯鐜: PowerShell $($PSVersionTable.PSVersion)
- 宸ヤ綔鐩綍: $(Get-Location)

## 涓嬩竴姝ュ缓璁?1. 鏌ョ湅鍒嗙被缁撴灉浜嗚В鏂囦欢鍒嗗竷
2. 鏍规嵁闇€瑕佽皟鏁村垎绫昏鍒?3. 璁剧疆瀹氭椂鑷姩鏁寸悊
4. 鎵╁睍鏁寸悊鍔熻兘

---
*鎶ュ憡鐢熸垚鏃堕棿: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')*
"@

$reportFile = "simple-organization-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
$report | Out-File $reportFile -Encoding UTF8
Write-Host "  鎶ュ憡淇濆瓨鍒? $reportFile" -ForegroundColor Green

# 瀹屾垚
Write-Host "`n=== 鏁寸悊瀹屾垚 ===" -ForegroundColor Green
Write-Host "澶勭悊鏂囦欢: $fileCount 涓? -ForegroundColor Cyan
Write-Host "鍒嗙被鏁伴噺: $($categories.Keys.Count) 绫? -ForegroundColor Cyan
Write-Host "鐭ヨ瘑搴撴枃浠? $kbFile" -ForegroundColor Cyan
Write-Host "鏁寸悊鎶ュ憡: $reportFile" -ForegroundColor Cyan

Write-Host "`n馃搵 鏌ョ湅缁撴灉:" -ForegroundColor Yellow
Write-Host "  Get-Content $reportFile" -ForegroundColor Gray
Write-Host "  Get-Content $resultFile | Select-Object -First 20" -ForegroundColor Gray
Write-Host "  Get-Content $kbFile | Select-Object -First 20" -ForegroundColor Gray

Write-Host "`n馃殌 鍐嶆杩愯:" -ForegroundColor Yellow
Write-Host "  .\simple-organize.ps1" -ForegroundColor Gray
