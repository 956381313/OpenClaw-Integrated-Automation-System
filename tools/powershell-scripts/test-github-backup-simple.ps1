# 绠€鍖栫殑GitHub澶囦唤娴嬭瘯鑴氭湰

Write-Host "=== GitHub澶囦唤绯荤粺绠€鍗曟祴璇?===" -ForegroundColor Cyan
Write-Host "鏃堕棿: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "浠撳簱: https://github.com/956381313/OpenClaw" -ForegroundColor Yellow
Write-Host ""

# 娴嬭瘯1: 妫€鏌ラ厤缃枃浠?Write-Host "1. 妫€鏌ラ厤缃枃浠?.." -ForegroundColor Cyan
$configFile = "core/configuration/github-backup-config.json"
if (Test-Path $configFile) {
    $config = Get-Content $configFile | ConvertFrom-Json
    Write-Host "  閰嶇疆鏂囦欢瀛樺湪" -ForegroundColor Green
    Write-Host "  浠撳簱URL: $($config.repositories.workspace.url)" -ForegroundColor Gray
} else {
    Write-Host "  閰嶇疆鏂囦欢涓嶅瓨鍦? -ForegroundColor Red
}

# 娴嬭瘯2: 妫€鏌it閰嶇疆
Write-Host "`n2. 妫€鏌it閰嶇疆..." -ForegroundColor Cyan
try {
    $gitVersion = git --version
    Write-Host "  Git鐗堟湰: $gitVersion" -ForegroundColor Green
    
    # 妫€鏌ユ槸鍚﹀凡鍏嬮殕浠撳簱
    $repoDir = "09-projects/github-backup/repos/OpenClaw"
    if (Test-Path $repoDir) {
        Write-Host "  浠撳簱宸插厠闅嗗埌: $repoDir" -ForegroundColor Green
    } else {
        Write-Host "  浠撳簱鏈厠闅嗭紝姝ｅ湪鍏嬮殕..." -ForegroundColor Yellow
        git clone https://github.com/956381313/OpenClaw.git $repoDir
    }
} catch {
    Write-Host "  Git妫€鏌ュけ璐? $_" -ForegroundColor Red
}

# 娴嬭瘯3: 妫€鏌ュ浠界洰褰曠粨鏋?Write-Host "`n3. 妫€鏌ョ洰褰曠粨鏋?.." -ForegroundColor Cyan
$dirs = @(
    "09-projects/github-backup",
    "09-projects/github-backup/repos", 
    "09-projects/github-backup/logs",
    "09-projects/github-backup/temp"
)

foreach ($dir in $dirs) {
    if (Test-Path $dir) {
        Write-Host "  鐩綍瀛樺湪: $dir" -ForegroundColor Green
    } else {
        Write-Host "  鍒涘缓鐩綍: $dir" -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# 娴嬭瘯4: 妯℃嫙澶囦唤杩囩▼
Write-Host "`n4. 妯℃嫙澶囦唤杩囩▼..." -ForegroundColor Cyan

# 鍒涘缓娴嬭瘯鏂囦欢
$testFile = "09-projects/github-backup/temp/test-backup.txt"
"娴嬭瘯澶囦唤鍐呭 - $(Get-Date)" | Out-File $testFile -Encoding UTF8
Write-Host "  鍒涘缓娴嬭瘯鏂囦欢: $testFile" -ForegroundColor Gray

# 澶嶅埗鍒颁粨搴撶洰褰?$repoDir = "09-projects/github-backup/repos/OpenClaw"
if (Test-Path $repoDir) {
    Copy-Item $testFile "$repoDir/test-backup.txt" -Force
    Write-Host "  澶嶅埗鏂囦欢鍒颁粨搴撶洰褰? -ForegroundColor Gray
    
    # 鍒囨崲鍒颁粨搴撶洰褰?    $originalDir = Get-Location
    Set-Location $repoDir
    
    # 妫€鏌it鐘舵€?    $status = git status --porcelain
    if ($status) {
        Write-Host "  妫€娴嬪埌鏂囦欢鍙樻洿锛屽彲浠ユ彁浜? -ForegroundColor Green
        
        # 妯℃嫙鎻愪氦
        Write-Host "  妯℃嫙Git鎿嶄綔:" -ForegroundColor Gray
        Write-Host "  - git add ." -ForegroundColor Gray
        Write-Host "  - git commit -m '娴嬭瘯澶囦唤'" -ForegroundColor Gray
        Write-Host "  - git push origin main" -ForegroundColor Gray
        
        Write-Host "  (瀹為檯杩愯鏃朵細鎵ц杩欎簺鎿嶄綔)" -ForegroundColor Yellow
    } else {
        Write-Host "  鏃犳枃浠跺彉鏇? -ForegroundColor Yellow
    }
    
    Set-Location $originalDir
}

Write-Host "`n=== 娴嬭瘯瀹屾垚 ===" -ForegroundColor Green
Write-Host "GitHub澶囦唤绯荤粺鍩烘湰閰嶇疆姝ｅ父" -ForegroundColor Green
Write-Host "`n涓嬩竴姝?" -ForegroundColor Cyan
Write-Host "1. 濡傛灉闇€瑕佺鏈変粨搴撴垨鎺ㄩ€佹潈闄愶紝閰嶇疆GitHub Token" -ForegroundColor Gray
Write-Host "2. 杩愯瀹屾暣澶囦唤: 闇€瑕佷慨澶嶄富鑴氭湰鐨勭紪鐮侀棶棰? -ForegroundColor Gray
Write-Host "3. 鏌ョ湅浣犵殑GitHub浠撳簱: https://github.com/956381313/OpenClaw" -ForegroundColor Gray
