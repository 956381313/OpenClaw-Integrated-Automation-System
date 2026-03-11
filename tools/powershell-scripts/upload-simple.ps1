# Simple OpenClaw System Upload

Write-Host "=== Simple OpenClaw System Upload ===" -ForegroundColor Cyan
Write-Host "Source: C:\Users\luchaochao\.openclaw" -ForegroundColor Yellow
Write-Host "Target: https://github.com/956381313/OpenClaw.git" -ForegroundColor Yellow
Write-Host "Time: $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Step 1: Create simple backup
Write-Host "1. Creating simple backup..." -ForegroundColor Cyan

$backupDir = "openclaw-simple-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

# Copy only essential files (avoid deep nesting)
$essentialFiles = @(
    "C:\Users\luchaochao\.openclaw\openclaw.json",
    "C:\Users\luchaochao\.openclaw\gateway.cmd",
    "C:\Users\luchaochao\.openclaw\update-check.json"
)

$workspaceFiles = @(
    "C:\Users\luchaochao\.openclaw\workspace\AGENTS.md",
    "C:\Users\luchaochao\.openclaw\workspace\SOUL.md",
    "C:\Users\luchaochao\.openclaw\workspace\TOOLS.md",
    "C:\Users\luchaochao\.openclaw\workspace\USER.md",
    "C:\Users\luchaochao\.openclaw\workspace\IDENTITY.md"
)

$fileCount = 0

# Copy essential files
foreach ($file in $essentialFiles) {
    if (Test-Path $file) {
        $fileName = Split-Path $file -Leaf
        Copy-Item $file "$backupDir\$fileName" -Force
        $fileCount++
        Write-Host "  Copied: $fileName" -ForegroundColor Gray
    }
}

# Copy workspace files
foreach ($file in $workspaceFiles) {
    if (Test-Path $file) {
        $fileName = Split-Path $file -Leaf
        Copy-Item $file "$backupDir\$fileName" -Force
        $fileCount++
        Write-Host "  Copied: $fileName" -ForegroundColor Gray
    }
}

# Create summary
$summary = @"
# OpenClaw Simple Backup
Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Files: $fileCount
Source: C:\Users\luchaochao\.openclaw
Target: https://github.com/956381313/OpenClaw.git

## Included Files:
$(Get-ChildItem $backupDir | ForEach-Object { "- $($_.Name)" })

## Notes:
- This is a simplified backup
- Contains essential configuration files
- Full backup available in other commits
"@

$summary | Out-File "$backupDir\README.md" -Encoding UTF8
$fileCount++

Write-Host "  Total files: $fileCount" -ForegroundColor Green

# Step 2: Upload to GitHub
Write-Host "`n2. Uploading to GitHub..." -ForegroundColor Cyan

# Check if we're in the git repo
if (Test-Path "services/github/cloud-backup\.git") {
    Set-Location "services/github/cloud-backup"
    
    # Move backup to repo
    $targetDir = "simple-backups\$backupDir"
    $targetParent = Split-Path $targetDir -Parent
    
    if (-not (Test-Path $targetParent)) {
        New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
    }
    
    Move-Item "..\$backupDir" $targetDir -Force
    
    # Add and commit
    git add $targetDir
    git commit -m "OpenClaw Simple Backup: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    
    # Push
    git push origin main
    
    Write-Host "  鉁?Simple backup uploaded to GitHub!" -ForegroundColor Green
    
    # Get commit hash
    $commitHash = git log --oneline -1 | Select-String -Pattern "^(\w+)" | ForEach-Object { $_.Matches[0].Groups[1].Value }
    Write-Host "  Commit: $commitHash" -ForegroundColor Gray
    
    Set-Location ..
} else {
    Write-Host "  鈿狅笍 Not in Git repository" -ForegroundColor Yellow
    Write-Host "  Backup directory: $backupDir" -ForegroundColor Gray
}

Write-Host "`n=== Upload Complete ===" -ForegroundColor Green
Write-Host "Files uploaded: $fileCount" -ForegroundColor Gray
Write-Host "Backup directory: $backupDir" -ForegroundColor Gray
Write-Host "GitHub: https://github.com/956381313/OpenClaw" -ForegroundColor Cyan
