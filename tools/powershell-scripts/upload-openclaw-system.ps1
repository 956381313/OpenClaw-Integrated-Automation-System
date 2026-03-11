# Upload Complete OpenClaw System to GitHub

param(
    [string]$CommitMessage = "OpenClaw System Backup: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    [switch]$DryRun,
    [switch]$ExcludeLargeFiles,
    [int]$MaxFileSizeMB = 10
)

Write-Host "=== Upload Complete OpenClaw System ===" -ForegroundColor Cyan
Write-Host "Source: C:\Users\luchaochao\.openclaw" -ForegroundColor Yellow
Write-Host "Target: https://github.com/956381313/OpenClaw.git" -ForegroundColor Yellow
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Configuration
$SourcePath = "C:\Users\luchaochao\.openclaw"
$GitHubRepo = "https://github.com/956381313/OpenClaw.git"
$UploadDir = "openclaw-system-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$MaxFileSizeBytes = $MaxFileSizeMB * 1024 * 1024

# Step 1: Verify source directory
Write-Host "1. Checking source directory..." -ForegroundColor Cyan

if (-not (Test-Path $SourcePath)) {
    Write-Host "  鉂?Source directory not found: $SourcePath" -ForegroundColor Red
    exit 1
}

$sourceInfo = Get-Item $SourcePath
Write-Host "  鉁?Source directory: $SourcePath" -ForegroundColor Green
Write-Host "  Last modified: $($sourceInfo.LastWriteTime)" -ForegroundColor Gray

# Step 2: Prepare upload directory
Write-Host "`n2. Preparing upload directory..." -ForegroundColor Cyan

New-Item -ItemType Directory -Path $UploadDir -Force | Out-Null
Write-Host "  Upload directory: $UploadDir" -ForegroundColor Gray

# Step 3: Copy OpenClaw system files
Write-Host "`n3. Copying OpenClaw system files..." -ForegroundColor Cyan

# Get all files and directories
$items = Get-ChildItem -Path $SourcePath -Recurse

$totalFiles = 0
$totalSize = 0
$skippedFiles = 0
$skippedSize = 0

foreach ($item in $items) {
    $relativePath = $item.FullName.Replace("$SourcePath\", "")
    
    # Skip Git repository directory to avoid recursion
    if ($relativePath -match "^services/github/cloud-backup" -or $relativePath -match "\\.git") {
        continue
    }
    
    $targetPath = "$UploadDir\$relativePath"
    
    if ($item.PSIsContainer) {
        # Create directory
        if (-not (Test-Path $targetPath)) {
            New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
        }
    } else {
        # Check file size
        if ($ExcludeLargeFiles -and $item.Length -gt $MaxFileSizeBytes) {
            Write-Host "  鈿狅笍 Skipping large file: $relativePath ($([math]::Round($item.Length/1MB,2)) MB)" -ForegroundColor Yellow
            $skippedFiles++
            $skippedSize += $item.Length
            continue
        }
        
        # Create parent directory if needed
        $parentDir = Split-Path $targetPath -Parent
        if (-not (Test-Path $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }
        
        # Copy file
        Copy-Item $item.FullName $targetPath -Force
        $totalFiles++
        $totalSize += $item.Length
        
        # Show progress every 10 files
        if ($totalFiles % 10 -eq 0) {
            Write-Host "  Copied $totalFiles files..." -ForegroundColor Gray
        }
    }
}

Write-Host "  鉁?Copied $totalFiles files ($([math]::Round($totalSize/1MB,2)) MB)" -ForegroundColor Green
if ($skippedFiles -gt 0) {
    Write-Host "  鈿狅笍 Skipped $skippedFiles large files ($([math]::Round($skippedSize/1MB,2)) MB)" -ForegroundColor Yellow
}

# Step 4: Create system manifest
Write-Host "`n4. Creating system manifest..." -ForegroundColor Cyan

$manifest = @{
    system = @{
        name = "OpenClaw System"
        source = $SourcePath
        timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'
        total_files = $totalFiles
        total_size_bytes = $totalSize
        total_size_mb = [math]::Round($totalSize / 1MB, 2)
        skipped_files = $skippedFiles
        skipped_size_mb = [math]::Round($skippedSize / 1MB, 2)
    }
    directories = @()
    statistics = @{}
}

# Analyze directory structure
$directories = Get-ChildItem -Path $SourcePath -Directory
foreach ($dir in $directories) {
    $dirFiles = Get-ChildItem -Path $dir.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object
    $dirSize = Get-ChildItem -Path $dir.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum | Select-Object -ExpandProperty Sum
    
    $manifest.directories += @{
        name = $dir.Name
        file_count = $dirFiles.Count
        size_mb = [math]::Round($dirSize / 1MB, 2)
    }
    
    $manifest.statistics[$dir.Name] = @{
        files = $dirFiles.Count
        size_mb = [math]::Round($dirSize / 1MB, 2)
    }
}

$manifest | ConvertTo-Json -Depth 5 | Out-File "$UploadDir\system-manifest.json" -Encoding UTF8
Write-Host "  System manifest created" -ForegroundColor Green

# Step 5: Move to GitHub repository
Write-Host "`n5. Preparing for GitHub upload..." -ForegroundColor Cyan

# Check if we're in the git repository
$originalLocation = Get-Location
$isInGitRepo = Test-Path ".git"

if ($isInGitRepo) {
    Write-Host "  Already in Git repository" -ForegroundColor Green
    
    # Move upload directory to current location
    $targetDir = "backups/system\$UploadDir"
    $targetParent = Split-Path $targetDir -Parent
    
    if (-not (Test-Path $targetParent)) {
        New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
    }
    
    if (Test-Path $targetDir) {
        Remove-Item $targetDir -Recurse -Force
    }
    
    Move-Item $UploadDir $targetDir -Force
    $UploadDir = $targetDir
    
    Write-Host "  Moved to: $UploadDir" -ForegroundColor Gray
} else {
    Write-Host "  Not in Git repository, switching to GitHub repo..." -ForegroundColor Yellow
    
    # Switch to GitHub repository directory
    if (Test-Path "services/github/cloud-backup") {
        Set-Location "services/github/cloud-backup"
        $isInGitRepo = Test-Path ".git"
        
        if ($isInGitRepo) {
            Write-Host "  Switched to GitHub repository" -ForegroundColor Green
            
            # Move upload directory
            $targetDir = "backups/system\$UploadDir"
            $targetParent = Split-Path $targetDir -Parent
            
            if (-not (Test-Path $targetParent)) {
                New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
            }
            
            Move-Item "$originalLocation\$UploadDir" $targetDir -Force
            $UploadDir = $targetDir
        }
    }
}

# Step 6: Upload to GitHub
Write-Host "`n6. Uploading to GitHub..." -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "  DRY RUN: Would upload $totalFiles files ($([math]::Round($totalSize/1MB,2)) MB)" -ForegroundColor Yellow
    Write-Host "  Upload directory: $UploadDir" -ForegroundColor Gray
    Write-Host "  Commit message: $CommitMessage" -ForegroundColor Gray
} else {
    if ($isInGitRepo) {
        # Add files to Git
        Write-Host "  Adding files to Git..." -ForegroundColor Gray
        git add $UploadDir
        
        # Check for changes
        $status = git status --porcelain
        if ($status) {
            Write-Host "  Committing changes..." -ForegroundColor Gray
            git commit -m $CommitMessage
            
            Write-Host "  Pushing to GitHub..." -ForegroundColor Gray
            git push origin main
            
            Write-Host "  鉁?OpenClaw system uploaded to GitHub!" -ForegroundColor Green
            
            # Get commit hash
            $commitHash = git log --oneline -1 | Select-String -Pattern "^(\w+)" | ForEach-Object { $_.Matches[0].Groups[1].Value }
            Write-Host "  Commit: $commitHash" -ForegroundColor Gray
        } else {
            Write-Host "  鈿狅笍 No changes to upload" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  鈿狅笍 Not in Git repository, manual upload required:" -ForegroundColor Yellow
        Write-Host "  1. Copy directory: $UploadDir" -ForegroundColor Gray
        Write-Host "  2. Add to your GitHub repository" -ForegroundColor Gray
        Write-Host "  3. Commit and push changes" -ForegroundColor Gray
    }
}

# Return to original location
if ($originalLocation -ne (Get-Location).Path) {
    Set-Location $originalLocation
}

# Step 7: Create upload report
Write-Host "`n7. Creating upload report..." -ForegroundColor Cyan

$report = @"
# 馃彈锔?OpenClaw Complete System Backup Report

## Backup Summary
- **Time**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
- **Source Directory**: $SourcePath
- **Target Repository**: $GitHubRepo
- **Total Files**: $totalFiles
- **Total Size**: $([math]::Round($totalSize/1MB,2)) MB
- **Mode**: $(if ($DryRun) { "DRY RUN" } else { "ACTUAL UPLOAD" })
- **Status**: $(if ($DryRun) { "Ready for upload" } else { if ($isInGitRepo) { "Uploaded" } else { "Ready for manual upload" } })

## Directory Structure
| Directory | Files | Size (MB) |
|-----------|-------|-----------|
$(foreach ($dir in $manifest.directories) {
    "| $($dir.name) | $($dir.file_count) | $($dir.size_mb) |"
})

## System Statistics
- **Workspace**: $($manifest.statistics.workspace.files) files ($($manifest.statistics.workspace.size_mb) MB)
- **Agents**: $($manifest.statistics.agents.files) files ($($manifest.statistics.agents.size_mb) MB)
- **Memory**: $($manifest.statistics.memory.files) files ($($manifest.statistics.memory.size_mb) MB)
- **Identity**: $($manifest.statistics.identity.files) files ($($manifest.statistics.identity.size_mb) MB)

## Upload Details
$(if (-not $DryRun -and $isInGitRepo -and $commitHash) {
    "- **Commit Hash**: $commitHash"
    "- **Commit Message**: $CommitMessage"
    "- **View on GitHub**: https://github.com/956381313/OpenClaw/commit/$commitHash"
})

## File Structure
\`\`\`
$UploadDir
$(Get-ChildItem -Path $UploadDir -Depth 1 | ForEach-Object {
    if ($_.PSIsContainer) {
        "馃搧 $($_.Name)/"
    } else {
        "馃搫 $($_.Name)"
    }
} | Out-String)
\`\`\`

## Next Steps
1. Verify upload on GitHub: https://github.com/956381313/OpenClaw
2. Check system integrity
3. Test restoration process

## Quick Links
- GitHub Repository: $GitHubRepo
- Web View: https://github.com/956381313/OpenClaw
$(if (-not $DryRun -and $commitHash) { "- Commit: https://github.com/956381313/OpenClaw/commit/$commitHash" })

## Important Notes
- This is a complete system backup of OpenClaw
- Includes configuration, agents, memory, and workspace
- Can be used for full system restoration
- Excludes large files: $(if ($ExcludeLargeFiles) { "Yes (>${MaxFileSizeMB}MB)" } else { "No" })

---
*Report generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')*
"@

$reportFile = "openclaw-system-upload-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
$report | Out-File $reportFile -Encoding UTF8
Write-Host "  Report saved: $reportFile" -ForegroundColor Green

Write-Host "`n=== Upload Complete ===" -ForegroundColor Green

if ($DryRun) {
    Write-Host "鉁?DRY RUN completed - ready to upload $totalFiles files ($([math]::Round($totalSize/1MB,2)) MB)" -ForegroundColor Yellow
    Write-Host "Remove -DryRun flag to actually upload" -ForegroundColor Gray
} elseif ($isInGitRepo) {
    Write-Host "鉁?OpenClaw system successfully uploaded to GitHub!" -ForegroundColor Green
    Write-Host "`n馃搳 Summary:" -ForegroundColor Cyan
    Write-Host "  Files: $totalFiles" -ForegroundColor Gray
    Write-Host "  Size: $([math]::Round($totalSize/1MB,2)) MB" -ForegroundColor Gray
    Write-Host "  Repository: $GitHubRepo" -ForegroundColor Gray
    Write-Host "  Commit: $commitHash" -ForegroundColor Gray
} else {
    Write-Host "鉁?System backup prepared for manual upload" -ForegroundColor Green
    Write-Host "`n馃搧 Upload directory: $UploadDir" -ForegroundColor Cyan
    Write-Host "馃搫 Files: $totalFiles" -ForegroundColor Gray
    Write-Host "馃捑 Size: $([math]::Round($totalSize/1MB,2)) MB" -ForegroundColor Gray
    Write-Host "馃搵 Report: $reportFile" -ForegroundColor Gray
}

Write-Host "`n馃寪 View on GitHub: https://github.com/956381313/OpenClaw" -ForegroundColor Cyan
Write-Host "馃搫 System report: $reportFile" -ForegroundColor Gray
