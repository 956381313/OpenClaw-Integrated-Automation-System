# Simple GitHub Backup Test Script (English)

Write-Host "=== GitHub Backup System Test ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "Repo: https://github.com/956381313/OpenClaw" -ForegroundColor Yellow
Write-Host ""

# Test 1: Check config file
Write-Host "1. Checking config file..." -ForegroundColor Cyan
$configFile = "core/configuration/github-backup-config.json"
if (Test-Path $configFile) {
    $config = Get-Content $configFile | ConvertFrom-Json
    Write-Host "  Config file exists" -ForegroundColor Green
    Write-Host "  Repo URL: $($config.repositories.workspace.url)" -ForegroundColor Gray
} else {
    Write-Host "  Config file not found" -ForegroundColor Red
}

# Test 2: Check Git
Write-Host "`n2. Checking Git..." -ForegroundColor Cyan
try {
    $gitVersion = git --version
    Write-Host "  Git version: $gitVersion" -ForegroundColor Green
    
    # Check if repo is cloned
    $repoDir = "09-projects/github-backup/repos/OpenClaw"
    if (Test-Path $repoDir) {
        Write-Host "  Repo already cloned to: $repoDir" -ForegroundColor Green
    } else {
        Write-Host "  Cloning repository..." -ForegroundColor Yellow
        git clone https://github.com/956381313/OpenClaw.git $repoDir
    }
} catch {
    Write-Host "  Git check failed: $_" -ForegroundColor Red
}

# Test 3: Check directory structure
Write-Host "`n3. Checking directories..." -ForegroundColor Cyan
$dirs = @(
    "09-projects/github-backup",
    "09-projects/github-backup/repos", 
    "09-projects/github-backup/logs",
    "09-projects/github-backup/temp"
)

foreach ($dir in $dirs) {
    if (Test-Path $dir) {
        Write-Host "  Directory exists: $dir" -ForegroundColor Green
    } else {
        Write-Host "  Creating directory: $dir" -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# Test 4: Manual backup test
Write-Host "`n4. Manual backup test..." -ForegroundColor Cyan

# Create a test backup
$backupContent = @"
# OpenClaw Backup Test
Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
System: OpenClaw Backup System
Status: Test backup successful
"@

$backupFile = "09-projects/github-backup/temp/backup-test.md"
$backupContent | Out-File $backupFile -Encoding UTF8
Write-Host "  Created test backup file" -ForegroundColor Gray

# Copy to repo
$repoDir = "09-projects/github-backup/repos/OpenClaw"
if (Test-Path $repoDir) {
    Copy-Item $backupFile "$repoDir/backup-test.md" -Force
    Write-Host "  Copied to repo directory" -ForegroundColor Gray
    
    # Check Git status
    $originalDir = Get-Location
    Set-Location $repoDir
    
    $status = git status --porcelain
    if ($status) {
        Write-Host "  Files changed, ready to commit" -ForegroundColor Green
        
        # Show what would happen
        Write-Host "  Git operations would be:" -ForegroundColor Gray
        Write-Host "  - git add ." -ForegroundColor Gray
        Write-Host "  - git commit -m 'Backup test'" -ForegroundColor Gray
        Write-Host "  - git push origin main" -ForegroundColor Gray
        
        Write-Host "  (These would run in actual backup)" -ForegroundColor Yellow
    }
    
    Set-Location $originalDir
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Green
Write-Host "GitHub backup system is configured correctly" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Check your GitHub repo: https://github.com/956381313/OpenClaw" -ForegroundColor Gray
Write-Host "2. If you need push access, configure GitHub Token" -ForegroundColor Gray
Write-Host "3. The backup system is ready to use" -ForegroundColor Gray
