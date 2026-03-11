# GitHub Cloud Backup - Push to 956381313/OpenClaw

param(
    [string]$CommitMessage = "OpenClaw Backup: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    [switch]$DryRun,
    [switch]$Force,
    [string]$Branch = "main"
)

Write-Host "=== GitHub Cloud Backup ===" -ForegroundColor Cyan
Write-Host "Repository: https://github.com/956381313/OpenClaw.git" -ForegroundColor Yellow
Write-Host "Branch: $Branch" -ForegroundColor Gray
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Configuration
$GitHubRepo = "https://github.com/956381313/OpenClaw.git"
$LocalRepoPath = "services/github/cloud-backup"
$BackupDir = "$LocalRepoPath\backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

# Step 1: Clone or update repository
Write-Host "1. Preparing repository..." -ForegroundColor Cyan

if (Test-Path $LocalRepoPath) {
    Write-Host "  Updating existing repository..." -ForegroundColor Gray
    Set-Location $LocalRepoPath
    
    # Check if we're on the right remote
    $currentRemote = git remote get-url origin 2>$null
    if ($currentRemote -ne $GitHubRepo) {
        Write-Host "  Updating remote URL..." -ForegroundColor Yellow
        git remote set-url origin $GitHubRepo
    }
    
    # Pull latest changes
    if (-not $Force) {
        Write-Host "  Pulling latest changes..." -ForegroundColor Gray
        git pull origin $Branch
    }
    
    Set-Location ..
} else {
    Write-Host "  Cloning repository..." -ForegroundColor Gray
    git clone $GitHubRepo $LocalRepoPath
}

# Step 2: Create backup
Write-Host "`n2. Creating backup..." -ForegroundColor Cyan

New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null

# Backup important files
$backupFiles = @{
    "config" = @(
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
        "*.md"
    )
    "system" = @(
        "AGENTS.md",
        "SOUL.md", 
        "TOOLS.md",
        "USER.md",
        "IDENTITY.md"
    )
}

$totalFiles = 0
foreach ($category in $backupFiles.Keys) {
    $fileCount = 0
    foreach ($pattern in $backupFiles[$category]) {
        $files = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue
        foreach ($file in $files) {
            # Skip if file is too large (>10MB)
            if ($file.Length -gt 10MB) {
                Write-Host "  Skipping large file: $($file.Name) ($([math]::Round($file.Length/1MB,2)) MB)" -ForegroundColor Yellow
                continue
            }
            
            $targetPath = "$BackupDir\$category\$($file.Name)"
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
        Write-Host "  $category : $fileCount files" -ForegroundColor Green
    }
}

Write-Host "  Total files: $totalFiles" -ForegroundColor Green

# Step 3: Create backup manifest
Write-Host "`n3. Creating backup manifest..." -ForegroundColor Cyan

$manifest = @{
    backup = @{
        timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'
        total_files = $totalFiles
        repository = $GitHubRepo
        branch = $Branch
    }
    categories = @($backupFiles.Keys)
    system = @{
        openclaw_version = "1.0"
        backup_script = "github-push-backup.ps1"
    }
}

$manifest | ConvertTo-Json -Depth 5 | Out-File "$BackupDir\backup-manifest.json" -Encoding UTF8

# Step 4: Move backup to repository
Write-Host "`n4. Moving backup to repository..." -ForegroundColor Cyan

$repoBackupDir = "$LocalRepoPath\backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
if (Test-Path $repoBackupDir) {
    Remove-Item $repoBackupDir -Recurse -Force
}

Move-Item $BackupDir $repoBackupDir -Force
Write-Host "  Backup moved to: $repoBackupDir" -ForegroundColor Gray

# Step 5: Commit and push
Write-Host "`n5. Committing to Git..." -ForegroundColor Cyan

Set-Location $LocalRepoPath

# Add all files
git add .

# Check for changes
$status = git status --porcelain
if ($status) {
    if ($DryRun) {
        Write-Host "  DRY RUN: Would commit with message: $CommitMessage" -ForegroundColor Yellow
        Write-Host "  Changes to commit:" -ForegroundColor Gray
        $status | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
    } else {
        Write-Host "  Committing changes..." -ForegroundColor Gray
        git commit -m $CommitMessage
        
        Write-Host "  Pushing to GitHub..." -ForegroundColor Gray
        git push origin $Branch
        
        Write-Host "  鉁?Backup pushed to GitHub!" -ForegroundColor Green
        
        # Get commit hash
        $commitHash = git log --oneline -1 | Select-String -Pattern "^(\w+)" | ForEach-Object { $_.Matches[0].Groups[1].Value }
        Write-Host "  Commit: $commitHash" -ForegroundColor Gray
    }
} else {
    Write-Host "  鈿狅笍 No changes to commit" -ForegroundColor Yellow
}

Set-Location ..

# Step 6: Create report
Write-Host "`n6. Creating backup report..." -ForegroundColor Cyan

$report = @"
# 馃搳 GitHub Cloud Backup Report

## Status: $(if ($DryRun) { "DRY RUN" } else { if ($status) { "鉁?SUCCESS" } else { "鈿狅笍 NO CHANGES" } })

## Backup Details
- **Time**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
- **Repository**: $GitHubRepo
- **Branch**: $Branch
- **Total Files**: $totalFiles
- **Commit Message**: $CommitMessage
$(if (-not $DryRun -and $status) { "- **Commit Hash**: $commitHash" })

## Categories
$(foreach ($category in $backupFiles.Keys) {
    $catDir = "$repoBackupDir\$category"
    if (Test-Path $catDir) {
        $catFiles = Get-ChildItem -Path "$catDir\*" -File -ErrorAction SilentlyContinue | Measure-Object | Select-Object -ExpandProperty Count
        "- **$category**: $catFiles files"
    }
})

## Next Steps
1. View backup on GitHub: https://github.com/956381313/OpenClaw
2. Verify files are correctly uploaded
3. Set up automated backups

## Quick Links
- Repository: $GitHubRepo
- Web View: https://github.com/956381313/OpenClaw
$(if (-not $DryRun -and $status -and $commitHash) { "- Commit: https://github.com/956381313/OpenClaw/commit/$commitHash" })

## File Structure
\`\`\`
$repoBackupDir
$(Get-ChildItem -Path $repoBackupDir -Recurse -Depth 2 | ForEach-Object {
    $indent = "  " * ($_.FullName.Replace($repoBackupDir, "").Split("\").Length - 1)
    if ($_.PSIsContainer) {
        "$indent馃搧 $($_.Name)/"
    } else {
        "$indent馃搫 $($_.Name)"
    }
} | Select-Object -First 15)
\`\`\`

---
*Report generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')*
"@

$reportFile = "services/github/backup-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
$report | Out-File $reportFile -Encoding UTF8
Write-Host "  Report saved: $reportFile" -ForegroundColor Green

Write-Host "`n=== Backup Complete ===" -ForegroundColor Green

if ($DryRun) {
    Write-Host "鉁?DRY RUN completed - no changes made" -ForegroundColor Yellow
    Write-Host "Remove -DryRun flag to actually push to GitHub" -ForegroundColor Gray
} elseif ($status) {
    Write-Host "鉁?Backup successfully pushed to GitHub!" -ForegroundColor Green
    Write-Host "`n馃搳 Summary:" -ForegroundColor Cyan
    Write-Host "  Files: $totalFiles" -ForegroundColor Gray
    Write-Host "  Repository: $GitHubRepo" -ForegroundColor Gray
    Write-Host "  Branch: $Branch" -ForegroundColor Gray
    Write-Host "  Commit: $CommitMessage" -ForegroundColor Gray
} else {
    Write-Host "鈿狅笍 No changes detected - backup not needed" -ForegroundColor Yellow
}

Write-Host "`n馃寪 View on GitHub: https://github.com/956381313/OpenClaw" -ForegroundColor Cyan
Write-Host "馃搫 Report: $reportFile" -ForegroundColor Gray
