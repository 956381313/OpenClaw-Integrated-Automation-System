# Simple Local Backup for GitHub Desktop

Write-Host "=== Simple Local Backup ===" -ForegroundColor Cyan

# Configuration
$LocalRepoPath = "D:\GitBackups\OpenClaw"
$BackupName = "backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

Write-Host "Backup: $BackupName" -ForegroundColor Yellow
Write-Host "Repository: $LocalRepoPath" -ForegroundColor Gray
Write-Host ""

# Step 1: Create repository
Write-Host "1. Creating repository..." -ForegroundColor Cyan

if (-not (Test-Path $LocalRepoPath)) {
    New-Item -ItemType Directory -Path $LocalRepoPath -Force | Out-Null
    Set-Location $LocalRepoPath
    git init
    
    # Create README
    "OpenClaw Local Backup Repository" | Out-File "README.md" -Encoding UTF8
    git add README.md
    git commit -m "Initial commit"
    
    Set-Location $PSScriptRoot
    Write-Host "  Repository created" -ForegroundColor Green
} else {
    Write-Host "  Repository exists" -ForegroundColor Green
}

# Step 2: Create backup
Write-Host "`n2. Creating backup..." -ForegroundColor Cyan

$backupDir = "$LocalRepoPath\$BackupName"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

# Backup important files
$filesToBackup = @(
    "core/configuration\*.json",
    "06-documentation\guides\*.md",
    "09-projects\security-tools\*.ps1",
    "09-projects\cloud-backup\*.ps1",
    "09-projects\github-backup\*.ps1",
    "09-projects\iteration\*.md"
)

$fileCount = 0
foreach ($pattern in $filesToBackup) {
    $files = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue
    foreach ($file in $files) {
        $targetPath = "$backupDir\$($file.Name)"
        Copy-Item $file.FullName $targetPath -Force
        $fileCount++
    }
}

Write-Host "  Files backed up: $fileCount" -ForegroundColor Green

# Step 3: Create summary
Write-Host "`n3. Creating summary..." -ForegroundColor Cyan

$summary = @"
# OpenClaw Backup
Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Files: $fileCount
Backup: $BackupName
"@

$summary | Out-File "$backupDir\summary.txt" -Encoding UTF8

# Step 4: Commit to Git
Write-Host "`n4. Committing to Git..." -ForegroundColor Cyan

Set-Location $LocalRepoPath
git add .
git commit -m "Backup: $BackupName"
Set-Location $PSScriptRoot

Write-Host "  Changes committed" -ForegroundColor Green

Write-Host "`n=== Backup Complete ===" -ForegroundColor Green
Write-Host "Backup created: $BackupName" -ForegroundColor Gray
Write-Host "Files: $fileCount" -ForegroundColor Gray
Write-Host "Location: $backupDir" -ForegroundColor Gray
Write-Host "`nNext: Open GitHub Desktop and add repository: $LocalRepoPath" -ForegroundColor Cyan
