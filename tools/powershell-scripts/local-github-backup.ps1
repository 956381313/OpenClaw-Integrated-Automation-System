# Local GitHub Desktop Backup System

param(
    [string]$BackupName = "openclaw-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')",
    [switch]$AutoCommit,
    [switch]$CreateRepo,
    [string]$LocalRepoPath = "D:\GitBackups\OpenClaw"
)

Write-Host "=== Local GitHub Desktop Backup ===" -ForegroundColor Cyan
Write-Host "Backup Name: $BackupName" -ForegroundColor Yellow
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Step 1: Prepare local repository
Write-Host "1. Preparing local repository..." -ForegroundColor Cyan

if ($CreateRepo -or -not (Test-Path $LocalRepoPath)) {
    Write-Host "  Creating local repository at: $LocalRepoPath" -ForegroundColor Gray
    
    # Create directory
    if (-not (Test-Path $LocalRepoPath)) {
        New-Item -ItemType Directory -Path $LocalRepoPath -Force | Out-Null
    }
    
    # Initialize Git repository
    Set-Location $LocalRepoPath
    git init
    Write-Host "  鉁?Local Git repository created" -ForegroundColor Green
    
    # Create README
    $readme = @"
# OpenClaw Local Backup Repository

This repository contains automated backups of the OpenClaw workspace.

## Repository Information
- **Created**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
- **Purpose**: Local backup storage for OpenClaw system
- **Location**: $LocalRepoPath
- **Managed by**: GitHub Desktop + OpenClaw Backup System

## Backup Strategy
- Daily incremental backups
- Weekly full snapshots  
- Monthly archives
- All backups are version controlled

## How to Use
1. Open in GitHub Desktop to view history
2. Use Git commands to restore specific versions
3. Backup files are organized by date

## File Structure
- /backups/ - Individual backup snapshots
- /configs/ - System configurations
- /logs/ - Backup logs and reports
- /docs/ - Documentation backups

---
*Managed by OpenClaw Backup System*
"@
    
    $readme | Out-File "README.md" -Encoding UTF8
    git add README.md
    git commit -m "Initial commit: OpenClaw Local Backup Repository"
    
    Set-Location $PSScriptRoot
} else {
    Write-Host "  Using existing repository: $LocalRepoPath" -ForegroundColor Green
}

# Step 2: Create backup directory
Write-Host "`n2. Creating backup structure..." -ForegroundColor Cyan

$backupDir = "$LocalRepoPath\backups\$BackupName"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

Write-Host "  Backup directory: $backupDir" -ForegroundColor Gray

# Step 3: Backup critical files
Write-Host "`n3. Backing up files..." -ForegroundColor Cyan

$backupCategories = @{
    "configs" = @(
        "core/configuration\*.json",
        "core/configuration\*.yml",
        "core/configuration\*.yaml"
    )
    "scripts" = @(
        "09-projects\security-tools\*.ps1",
        "09-projects\cloud-backup\*.ps1",
        "09-projects\github-backup\*.ps1",
        "09-projects\iteration\*.ps1"
    )
    "docs" = @(
        "06-documentation\guides\*.md",
        "06-documentation\security\*.md",
        "*.md"
    )
    "data" = @(
        "core/memory\*.md",
        "09-projects\iteration\01-data\*.json"
    )
}

$totalFiles = 0

foreach ($category in $backupCategories.Keys) {
    $categoryDir = "$backupDir\$category"
    New-Item -ItemType Directory -Path $categoryDir -Force | Out-Null
    
    $fileCount = 0
    foreach ($pattern in $backupCategories[$category]) {
        $files = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue
        foreach ($file in $files) {
            $relativePath = $file.FullName.Replace("$PWD\", "")
            $targetPath = "$categoryDir\$relativePath"
            $targetDir = Split-Path $targetPath -Parent
            
            if (-not (Test-Path $targetDir)) {
                New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
            }
            
            Copy-Item $file.FullName $targetPath -Force
            $fileCount++
            $totalFiles++
        }
    }
    
    if ($fileCount -gt 0) {
        Write-Host "  馃搧 $category: $fileCount files" -ForegroundColor Green
    }
}

Write-Host "  Total files backed up: $totalFiles" -ForegroundColor Green

# Step 4: Create backup manifest
Write-Host "`n4. Creating backup manifest..." -ForegroundColor Cyan

$manifest = @{
    backup = @{
        name = $BackupName
        timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'
        total_files = $totalFiles
        categories = @($backupCategories.Keys)
    }
    system = @{
        openclaw_version = "1.0"
        workspace = $PWD
        backup_system = "Local GitHub Desktop"
    }
    files = @()
}

# Add file details
foreach ($category in $backupCategories.Keys) {
    $categoryDir = "$backupDir\$category"
    $files = Get-ChildItem -Path "$categoryDir\*" -Recurse -File -ErrorAction SilentlyContinue
    
    foreach ($file in $files) {
        $relativePath = $file.FullName.Replace("$backupDir\", "")
        $manifest.files += @{
            path = $relativePath
            size = $file.Length
            modified = $file.LastWriteTime.ToString('yyyy-MM-ddTHH:mm:ss')
            category = $category
        }
    }
}

$manifest | ConvertTo-Json -Depth 10 | Out-File "$backupDir\backup-manifest.json" -Encoding UTF8
Write-Host "  鉁?Backup manifest created" -ForegroundColor Green

# Step 5: Create summary report
Write-Host "`n5. Creating summary report..." -ForegroundColor Cyan

$summary = @"
# 馃搳 OpenClaw Local Backup Report

## Backup Summary
- **Backup Name**: $BackupName
- **Time**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
- **Total Files**: $totalFiles
- **Location**: $backupDir

## Categories
$(foreach ($category in $backupCategories.Keys) {
    $catDir = "$backupDir\$category"
    $catFiles = Get-ChildItem -Path "$catDir\*" -Recurse -File -ErrorAction SilentlyContinue | Measure-Object | Select-Object -ExpandProperty Count
    "- **$category**: $catFiles files"
})

## System Information
- **OpenClaw Workspace**: $PWD
- **Backup System**: Local GitHub Desktop
- **Repository**: $LocalRepoPath
- **Git Status**: $(if (Test-Path "$LocalRepoPath\.git") { "Initialized" } else { "Not initialized" })

## Next Steps
1. Open GitHub Desktop and add repository: $LocalRepoPath
2. Commit changes to track backup history
3. Set up automated backups using Windows Task Scheduler

## Quick Commands
```bash
# Navigate to repository
cd $LocalRepoPath

# Check Git status
git status

# Commit all changes
git add .
git commit -m "Backup: $BackupName"

# View commit history
git log --oneline
```

## File Structure
\`\`\`
$backupDir
$(Get-ChildItem -Path $backupDir -Recurse -Depth 2 | ForEach-Object {
    $indent = "  " * ($_.FullName.Replace($backupDir, "").Split("\").Length - 1)
    if ($_.PSIsContainer) {
        "$indent馃搧 $($_.Name)/"
    } else {
        "$indent馃搫 $($_.Name)"
    }
} | Select-Object -First 20)
\`\`\`

---
*Report generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')*
"@

$summary | Out-File "$backupDir\BACKUP-SUMMARY.md" -Encoding UTF8
Write-Host "  鉁?Summary report created" -ForegroundColor Green

# Step 6: Commit to Git (if enabled)
if ($AutoCommit) {
    Write-Host "`n6. Committing to Git..." -ForegroundColor Cyan
    
    Set-Location $LocalRepoPath
    
    # Add all files
    git add .
    
    # Check for changes
    $status = git status --porcelain
    if ($status) {
        $commitMessage = "Backup: $BackupName - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        git commit -m $commitMessage
        Write-Host "  鉁?Changes committed: $commitMessage" -ForegroundColor Green
    } else {
        Write-Host "  鈿狅笍 No changes to commit" -ForegroundColor Yellow
    }
    
    Set-Location $PSScriptRoot
}

Write-Host "`n=== Local Backup Complete ===" -ForegroundColor Green
Write-Host "鉁?Backup created successfully!" -ForegroundColor Green
Write-Host "`n馃搳 Backup Details:" -ForegroundColor Cyan
Write-Host "  Name: $BackupName" -ForegroundColor Gray
Write-Host "  Files: $totalFiles" -ForegroundColor Gray
Write-Host "  Location: $backupDir" -ForegroundColor Gray
Write-Host "  Repository: $LocalRepoPath" -ForegroundColor Gray
Write-Host "`n馃殌 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Open GitHub Desktop" -ForegroundColor Gray
Write-Host "2. Add repository: $LocalRepoPath" -ForegroundColor Gray
Write-Host "3. View and manage backups" -ForegroundColor Gray
Write-Host "`n馃挕 Tip: Run with -AutoCommit to automatically commit changes" -ForegroundColor Magenta
