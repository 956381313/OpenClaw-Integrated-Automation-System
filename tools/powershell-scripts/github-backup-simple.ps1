# Simple GitHub Backup Script

param(
    [string]$Message = "Backup: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
)

Write-Host "=== GitHub Backup ===" -ForegroundColor Cyan
Write-Host "Repo: https://github.com/956381313/OpenClaw" -ForegroundColor Yellow
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Load config
$configFile = "core/configuration/github-backup-simple.json"
if (-not (Test-Path $configFile)) {
    Write-Host "Config file not found: $configFile" -ForegroundColor Red
    exit 1
}

$config = Get-Content $configFile | ConvertFrom-Json
$repoUrl = $config.repository.url
$repoDir = "services/github/backup-repo"

Write-Host "1. Preparing repository..." -ForegroundColor Cyan

# Clone or update repository
if (Test-Path $repoDir) {
    Write-Host "  Updating existing repository..." -ForegroundColor Gray
    Set-Location $repoDir
    git pull origin main
    Set-Location ..
} else {
    Write-Host "  Cloning repository..." -ForegroundColor Gray
    git clone $repoUrl $repoDir
}

# Create backup directory structure
$backupDir = "$repoDir/backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

Write-Host "`n2. Collecting files..." -ForegroundColor Cyan

# Copy important files
$filesToBackup = @(
    "core/configuration/*.json",
    "06-documentation/guides/*.md",
    "09-projects/security-tools/*.ps1",
    "09-projects/cloud-backup/*.ps1",
    "09-projects/github-backup/*.ps1",
    "09-projects/iteration/*.md"
)

$fileCount = 0
foreach ($pattern in $filesToBackup) {
    $files = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue
    foreach ($file in $files) {
        $relativePath = $file.FullName.Replace("$PWD\", "")
        $targetPath = "$backupDir/$relativePath"
        $targetDir = Split-Path $targetPath -Parent
        
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        
        Copy-Item $file.FullName $targetPath -Force
        $fileCount++
    }
}

Write-Host "  Copied $fileCount files" -ForegroundColor Green

Write-Host "`n3. Creating backup summary..." -ForegroundColor Cyan

# Create summary file
$summary = @"
# OpenClaw Backup Summary

## Backup Information
- **Time**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
- **Repository**: https://github.com/956381313/OpenClaw
- **Files**: $fileCount
- **Backup ID**: backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')

## Included Content
- Configuration files
- Documentation and guides
- Security tools and scripts
- Cloud backup scripts
- GitHub backup scripts
- Iteration framework

## System Status
- OpenClaw backup system: Ready
- GitHub integration: Active
- Automation: Enabled

---
*Backup created by OpenClaw Backup System*
"@

$summary | Out-File "$backupDir/BACKUP-SUMMARY.md" -Encoding UTF8

Write-Host "`n4. Committing to Git..." -ForegroundColor Cyan

Set-Location $repoDir

# Add all files
git add .

# Check if there are changes
$status = git status --porcelain
if ($status) {
    Write-Host "  Committing changes..." -ForegroundColor Gray
    git commit -m $Message
    
    Write-Host "  Pushing to GitHub..." -ForegroundColor Gray
    git push origin main
    
    Write-Host "  Backup committed and pushed!" -ForegroundColor Green
} else {
    Write-Host "  No changes to commit" -ForegroundColor Yellow
}

Set-Location ..

Write-Host "`n=== Backup Complete ===" -ForegroundColor Green
Write-Host "Files backed up: $fileCount" -ForegroundColor Gray
Write-Host "Backup directory: $backupDir" -ForegroundColor Gray
Write-Host "Git commit: $Message" -ForegroundColor Gray
Write-Host "`nView your backup: https://github.com/956381313/OpenClaw" -ForegroundColor Cyan
