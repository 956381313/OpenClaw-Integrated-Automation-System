# OpenClaw 绔嬪嵆鏁寸悊鑴氭湰

Write-Host "=== OpenClaw 浠撳簱鏁寸悊 ===" -ForegroundColor Cyan
Write-Host "鏃堕棿: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# 1. 鍒涘缓鐩綍
Write-Host "1. 鍒涘缓鏁寸悊鐩綍..." -ForegroundColor Yellow

$repoRoot = "modules/organization"
if (-not (Test-Path $repoRoot)) {
    New-Item -ItemType Directory -Path $repoRoot -Force | Out-Null
    Write-Host "  鍒涘缓: $repoRoot" -ForegroundColor Green
}

# 鍒涘缓瀛愮洰褰?$subDirs = @(
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

foreach ($dir in $subDirs) {
    $fullPath = Join-Path $repoRoot $dir
    if (-not (Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Host "  鍒涘缓: $dir" -ForegroundColor Green
    }
}

# 2. 鎵弿鏂囦欢
Write-Host "`n2. 鎵弿宸ヤ綔鍖烘枃浠?.." -ForegroundColor Yellow

$workspacePath = "C:\Users\luchaochao\.openclaw\workspace"
$files = Get-ChildItem $workspacePath -Recurse -File -ErrorAction SilentlyContinue | 
    Where-Object { $_.Extension -match '\.(md|ps1|bat|json|txt|log|yml|yaml|xml)$' } |
    Select-Object -First 100

$fileCount = $files.Count
Write-Host "  鎵惧埌 $fileCount 涓枃浠? -ForegroundColor Green

# 3. 绠€鍗曞垎绫?Write-Host "`n3. 绠€鍗曞垎绫?.." -ForegroundColor Yellow

$categories = @{
    "鏂囨。" = @()
    "鑴氭湰" = @()
    "閰嶇疆" = @()
    "鏃ュ織" = @()
    "鍏朵粬" = @()
}

foreach ($file in $files) {
    $ext = $file.Extension.ToLower()
    
    if ($ext -in @('.md', '.txt')) {
        $categories.鏂囨。 += $file
    }
    elseif ($ext -in @('.ps1', '.bat', '.sh')) {
        $categories.鑴氭湰 += $file
    }
    elseif ($ext -in @('.json', '.yml', '.yaml', '.xml', '.config')) {
        $categories.閰嶇疆 += $file
    }
    elseif ($ext -in @('.log')) {
        $categories.鏃ュ織 += $file
    }
    else {
        $categories.鍏朵粬 += $file
    }
}

# 鏄剧ず缁撴灉
Write-Host "`n鍒嗙被缁撴灉:" -ForegroundColor Cyan
foreach ($cat in $categories.Keys | Sort-Object) {
    $count = $categories[$cat].Count
    $pct = if ($fileCount -gt 0) { [math]::Round(($count / $fileCount) * 100, 1) } else { 0 }
    Write-Host "  $cat : $count 鏂囦欢 ($pct`%)" -ForegroundColor Gray
}

# 4. 淇濆瓨缁撴灉
Write-Host "`n4. 淇濆瓨鏁寸悊缁撴灉..." -ForegroundColor Yellow

# 淇濆瓨鍒嗙被缁撴灉
$classDir = Join-Path $repoRoot "03-classification"
$classFile = Join-Path $classDir "classification-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"

$classData = @{
    ScanTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    TotalFiles = $fileCount
    Categories = @{}
}

foreach ($cat in $categories.Keys) {
    $classData.Categories[$cat] = $categories[$cat].Count
}

$classData | ConvertTo-Json | Out-File $classFile -Encoding UTF8
Write-Host "  鍒嗙被缁撴灉: $classFile" -ForegroundColor Green

# 淇濆瓨鐭ヨ瘑搴?$kbDir = Join-Path $repoRoot "05-knowledge-base"
$kbFile = Join-Path $kbDir "knowledge-base-$(Get-Date -Format 'yyyyMMdd').json"

$kbData = @{
    Created = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    FileCount = $fileCount
    Categories = $classData.Categories
    Summary = "OpenClaw 宸ヤ綔鍖虹煡璇嗗簱"
}

$kbData | ConvertTo-Json | Out-File $kbFile -Encoding UTF8
Write-Host "  鐭ヨ瘑搴? $kbFile" -ForegroundColor Green

# 5. 鐢熸垚鎶ュ憡
Write-Host "`n5. 鐢熸垚鏁寸悊鎶ュ憡..." -ForegroundColor Yellow

$reportContent = @()
$reportContent += "# OpenClaw 浠撳簱鏁寸悊鎶ュ憡"
$reportContent += "## 鏁寸悊鏃堕棿: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$reportContent += "## 澶勭悊鏂囦欢: $fileCount 涓?
$reportContent += ""
$reportContent += "## 鍒嗙被缁熻"
foreach ($cat in $categories.Keys | Sort-Object) {
    $count = $categories[$cat].Count
    $pct = if ($fileCount -gt 0) { [math]::Round(($count / $fileCount) * 100, 1) } else { 0 }
    $reportContent += "- **$cat**: $count 鏂囦欢 ($pct%)"
}
$reportContent += ""
$reportContent += "## 鐢熸垚鐨勬枃浠?
$reportContent += "1. 鍒嗙被缁撴灉: $classFile"
$reportContent += "2. 鐭ヨ瘑搴? $kbFile"
$reportContent += ""
$reportContent += "## 绯荤粺淇℃伅"
$reportContent += "- 鏁寸悊绯荤粺鐗堟湰: 1.0.0"
$reportContent += "- 杩愯鐜: PowerShell"
$reportContent += "- 宸ヤ綔鐩綍: $(Get-Location)"
$reportContent += ""
$reportContent += "---"
$reportContent += "*鎶ュ憡鐢熸垚鏃堕棿: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')*"

$reportFile = "organization-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
$reportContent | Out-File $reportFile -Encoding UTF8
Write-Host "  鏁寸悊鎶ュ憡: $reportFile" -ForegroundColor Green

# 瀹屾垚
Write-Host "`n=== 鏁寸悊瀹屾垚 ===" -ForegroundColor Green
Write-Host "澶勭悊鏂囦欢: $fileCount 涓? -ForegroundColor Cyan
Write-Host "鍒嗙被鏁伴噺: $($categories.Keys.Count) 绫? -ForegroundColor Cyan
Write-Host "鐭ヨ瘑搴? $kbFile" -ForegroundColor Cyan
Write-Host "鏁寸悊鎶ュ憡: $reportFile" -ForegroundColor Cyan

Write-Host "`n鏌ョ湅缁撴灉:" -ForegroundColor Yellow
Write-Host "  Get-Content $reportFile" -ForegroundColor Gray
Write-Host "  Get-Content $classFile" -ForegroundColor Gray
Write-Host "  Get-Content $kbFile" -ForegroundColor Gray
