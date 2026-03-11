# Upload Backup Files to GitHub

param(
    [string]$CommitMessage = "Upload backup files: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    [switch]$DryRun,
    [switch]$AllFiles,
    [string]$Category = "backup-system"
)

Write-Host "=== Upload Backup Files to GitHub ===" -ForegroundColor Cyan
Write-Host "Repository: https://github.com/956381313/OpenClaw" -ForegroundColor Yellow
WriteHost "Category: $Category" -ForegroundColor Gray
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Configuration
$GitHubRepo = "https://github.com/956381313/OpenClaw.git"
$UploadDir = "upload-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

# Step 1: Prepare upload directory
Write-Host "1. Preparing upload directory..." -ForegroundColor Cyan

New-Item -ItemType Directory -Path $UploadDir -Force | Out-Null
Write-Host "  Upload directory: $UploadDir" -ForegroundColor Gray

# Step 2: Collect files to upload
Write-Host "`n2. Collecting backup files..." -ForegroundColor Cyan

$filesToUpload = @{
    "scripts" = @(
        "github-push-backup.ps1",
        "simple-local-backup.ps1", 
        "local-github-backup.ps1",
        "instant-github-backup.ps1",
        "setup-local-backup-automation.ps1",
        "github-backup-simple.ps1"
    )
    "reports" = @(
        "services/github/backup-report-20260305-215421.md",
        "services/github/backup-report-20260305-215435.md",
        "backup-report-20260305-213140.md"
    )
    "configs" = @(
        "core/configuration/github-backup-config.json",
        "core/configuration/github-backup-simple.json",
        "core/configuration/cloud-backup-config.json",
        "core/configuration/security-monitoring.json"
    )
    "docs" = @(
        "OpenClaw鎵嬫満杩愮淮鎵嬪唽.md",
        "LOCAL-BACKUP-GUIDE.md",
        "瀹夊叏鎶€鑳介厤缃寚鍗?md",
        "瀹夊叏鎶€鑳介厤缃畬鎴愭€荤粨.md"
    )
}

if ($AllFiles) {
    # Add all backup-related directories
    $filesToUpload["projects"] = @(
        "09-projects/cloud-backup/*",
        "09-projects/github-backup/*",
        "09-projects/security-tools/*",
        "09-projects/iteration/*"
    )
    
    $filesToUpload["workspace"] = @(
        "AGENTS.md",
        "SOUL.md",
        "TOOLS.md",
        "USER.md",
        "IDENTITY.md",
        "HEARTBEAT.md"
    )
}

$totalFiles = 0
foreach ($category in $filesToUpload.Keys) {
    $categoryDir = "$UploadDir\$category"
    New-Item -ItemType Directory -Path $categoryDir -Force | Out-Null
    
    $fileCount = 0
    foreach ($pattern in $filesToUpload[$category]) {
        if ($pattern -match "\*$") {
            # Pattern with wildcard
            $files = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue
            foreach ($file in $files) {
                $targetPath = "$categoryDir\$($file.Name)"
                Copy-Item $file.FullName $targetPath -Force
                $fileCount++
                $totalFiles++
            }
        } else {
            # Specific file
            if (Test-Path $pattern) {
                $file = Get-Item $pattern
                $targetPath = "$categoryDir\$($file.Name)"
                Copy-Item $file.FullName $targetPath -Force
                $fileCount++
                $totalFiles++
            }
        }
    }
    
    if ($fileCount -gt 0) {
        Write-Host "  $category : $fileCount files" -ForegroundColor Green
    }
}

Write-Host "  Total files to upload: $totalFiles" -ForegroundColor Green

# Step 3: Create upload manifest
Write-Host "`n3. Creating upload manifest..." -ForegroundColor Cyan

$manifest = @{
    upload = @{
        timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'
        total_files = $totalFiles
        repository = $GitHubRepo
        category = $Category
        dry_run = $DryRun
    }
    categories = @($filesToUpload.Keys)
    files = @()
}

# Add file details
foreach ($category in $filesToUpload.Keys) {
    $categoryDir = "$UploadDir\$category"
    if (Test-Path $categoryDir) {
        $files = Get-ChildItem -Path "$categoryDir\*" -Recurse -File -ErrorAction SilentlyContinue
        
        foreach ($file in $files) {
            $relativePath = $file.FullName.Replace("$UploadDir\", "")
            $manifest.files += @{
                path = $relativePath
                size = $file.Length
                modified = $file.LastWriteTime.ToString('yyyy-MM-ddTHH:mm:ss')
                category = $category
            }
        }
    }
}

$manifest | ConvertTo-Json -Depth 5 | Out-File "$UploadDir\upload-manifest.json" -Encoding UTF8
Write-Host "  Upload manifest created" -ForegroundColor Green

# Step 4: Move to GitHub repository
Write-Host "`n4. Preparing for GitHub upload..." -ForegroundColor Cyan

# Check if we're in the git repository
if (Test-Path ".git") {
    Write-Host "  Already in Git repository" -ForegroundColor Green
    
    # Move upload directory to current location
    $targetDir = "backup-uploads\$UploadDir"
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
    Write-Host "  Not in Git repository, files ready for manual upload" -ForegroundColor Yellow
}

# Step 5: Upload to GitHub
Write-Host "`n5. Uploading to GitHub..." -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "  DRY RUN: Would upload $totalFiles files" -ForegroundColor Yellow
    Write-Host "  Upload directory: $UploadDir" -ForegroundColor Gray
    Write-Host "  Commit message: $CommitMessage" -ForegroundColor Gray
} else {
    if (Test-Path ".git") {
        # Add files to Git
        git add $UploadDir
        
        # Check for changes
        $status = git status --porcelain
        if ($status) {
            Write-Host "  Committing changes..." -ForegroundColor Gray
            git commit -m $CommitMessage
            
            Write-Host "  Pushing to GitHub..." -ForegroundColor Gray
            git push origin main
            
            Write-Host "  鉁?Files uploaded to GitHub!" -ForegroundColor Green
            
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

# Step 6: Create upload report
Write-Host "`n6. Creating upload report..." -ForegroundColor Cyan

$report = @"
# 馃摛 Backup Files Upload Report

## Upload Summary
- **Time**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
- **Repository**: $GitHubRepo
- **Category**: $Category
- **Total Files**: $totalFiles
- **Mode**: $(if ($DryRun) { "DRY RUN" } else { "ACTUAL UPLOAD" })
- **Status**: $(if ($DryRun) { "Ready for upload" } else { if (Test-Path ".git") { "Uploaded" } else { "Ready for manual upload" } })

## File Categories
$(foreach ($category in $filesToUpload.Keys) {
    $catDir = "$UploadDir\$category"
    if (Test-Path $catDir) {
        $catFiles = Get-ChildItem -Path "$catDir\*" -File -ErrorAction SilentlyContinue | Measure-Object | Select-Object -ExpandProperty Count
        "- **$category**: $catFiles files"
    }
})

## Upload Details
$(if (-not $DryRun -and (Test-Path ".git")) {
    "- **Commit Hash**: $commitHash"
    "- **Commit Message**: $CommitMessage"
    "- **View on GitHub**: https://github.com/956381313/OpenClaw/commit/$commitHash"
})

## File List
\`\`\`
$UploadDir
$(Get-ChildItem -Path $UploadDir -Recurse -Depth 2 | ForEach-Object {
    $indent = "  " * ($_.FullName.Replace($UploadDir, "").Split("\").Length - 1)
    if ($_.PSIsContainer) {
        "$indent馃搧 $($_.Name)/"
    } else {
        "$indent馃搫 $($_.Name)"
    }
} | Select-Object -First 30)
\`\`\`

## Next Steps
1. Verify upload on GitHub: https://github.com/956381313/OpenClaw
2. Check file integrity
3. Test backup scripts functionality

## Quick Links
- GitHub Repository: $GitHubRepo
- Web View: https://github.com/956381313/OpenClaw
$(if (-not $DryRun -and $commitHash) { "- Commit: https://github.com/956381313/OpenClaw/commit/$commitHash" })

---
*Report generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')*
"@

$reportFile = "upload-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
$report | Out-File $reportFile -Encoding UTF8
Write-Host "  Report saved: $reportFile" -ForegroundColor Green

Write-Host "`n=== Upload Complete ===" -ForegroundColor Green

if ($DryRun) {
    Write-Host "鉁?DRY RUN completed - ready to upload $totalFiles files" -ForegroundColor Yellow
    Write-Host "Remove -DryRun flag to actually upload" -ForegroundColor Gray
} elseif (Test-Path ".git") {
    Write-Host "鉁?Files successfully uploaded to GitHub!" -ForegroundColor Green
    Write-Host "`n馃搳 Summary:" -ForegroundColor Cyan
    Write-Host "  Files: $totalFiles" -ForegroundColor Gray
    Write-Host "  Repository: $GitHubRepo" -ForegroundColor Gray
    Write-Host "  Commit: $commitHash" -ForegroundColor Gray
} else {
    Write-Host "鉁?Files prepared for manual upload" -ForegroundColor Green
    Write-Host "`n馃搧 Upload directory: $UploadDir" -ForegroundColor Cyan
    Write-Host "馃搫 Files: $totalFiles" -ForegroundColor Gray
    Write-Host "馃搵 Report: $reportFile" -ForegroundColor Gray
}

Write-Host "`n馃寪 View on GitHub: https://github.com/956381313/OpenClaw" -ForegroundColor Cyan
Write-Host "馃搫 Upload report: $reportFile" -ForegroundColor Gray
