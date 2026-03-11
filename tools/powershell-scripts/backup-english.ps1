# OpenClaw Backup Script (English Version)

Write-Host "=== OpenClaw Backup System ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Configuration
$sourcePath = "C:\Users\luchaochao\.openclaw"
$backupName = "backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$backupPath = "modules/backup/data\$backupName"

# Create backup directory
if (-not (Test-Path "modules/backup/data")) {
    New-Item -ItemType Directory -Path "modules/backup/data" -Force | Out-Null
    Write-Host "Created backup directory: modules/backup/data" -ForegroundColor Green
}

New-Item -ItemType Directory -Path $backupPath -Force | Out-Null

# Check source directory
if (-not (Test-Path $sourcePath)) {
    Write-Host "ERROR: Source directory not found: $sourcePath" -ForegroundColor Red
    exit 1
}

Write-Host "Creating backup: $backupName" -ForegroundColor Yellow

# Copy core files
$coreFiles = @(
    "$sourcePath\openclaw.json",
    "$sourcePath\gateway.cmd", 
    "$sourcePath\update-check.json",
    "$sourcePath\workspace\AGENTS.md",
    "$sourcePath\workspace\SOUL.md",
    "$sourcePath\workspace\TOOLS.md",
    "$sourcePath\workspace\USER.md",
    "$sourcePath\workspace\IDENTITY.md"
)

$fileCount = 0
foreach ($file in $coreFiles) {
    if (Test-Path $file) {
        $fileName = Split-Path $file -Leaf
        Copy-Item $file "$backupPath\$fileName" -Force
        $fileCount++
        Write-Host "  Copied: $fileName" -ForegroundColor Gray
    }
}

# Create backup info
$backupInfo = @{
    BackupTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    FileCount = $fileCount
    Source = $sourcePath
    Backup = $backupPath
}

$backupInfo | ConvertTo-Json | Out-File "$backupPath\backup-info.json" -Encoding UTF8
$fileCount++

Write-Host "Backup created: $fileCount files" -ForegroundColor Green
Write-Host "Backup location: $backupPath" -ForegroundColor Cyan

# Try to upload to GitHub
Write-Host "`nUploading to GitHub..." -ForegroundColor Yellow

$gitRepo = "services/github/cloud-backup"
if (Test-Path $gitRepo) {
    try {
        Set-Location $gitRepo
        
        # Pull latest
        git pull origin main --rebase 2>$null
        
        # Copy backup
        $targetDir = "backups\$backupName"
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        Copy-Item "..\$backupPath\*" $targetDir -Recurse -Force
        
        # Commit
        git add $targetDir
        git commit -m "Backup: $backupName" -m "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -m "Files: $fileCount"
        
        # Push
        git push origin main
        
        Write-Host "GitHub upload successful!" -ForegroundColor Green
        
        # Get commit info
        $commitHash = git log --oneline -1
        Write-Host "Commit: $commitHash" -ForegroundColor Gray
        
        Set-Location ..
        
    } catch {
        Write-Host "GitHub upload failed: $_" -ForegroundColor Yellow
        Write-Host "Backup saved locally: $backupPath" -ForegroundColor Gray
    }
} else {
    Write-Host "GitHub repository not found, backup saved locally" -ForegroundColor Yellow
}

Write-Host "`n=== Backup Complete ===" -ForegroundColor Green
Write-Host "Backup name: $backupName" -ForegroundColor Cyan
Write-Host "File count: $fileCount" -ForegroundColor Cyan
Write-Host "Backup path: $backupPath" -ForegroundColor Cyan

if (Test-Path $gitRepo) {
    Write-Host "GitHub: https://github.com/956381313/OpenClaw" -ForegroundColor Yellow
}

# Send email notification if configured
if (Test-Path "modules/email/config\modules/email/config.json") {
    Write-Host "`nSending email notification..." -ForegroundColor Yellow
    
    $emailData = @{
        fileCount = $fileCount
        backupSize = "${backupSizeMB}MB"
        backupPath = $backupPath
        status = if (Test-Path $gitRepo) { "Success (GitHub + Local)" } else { "Success (Local Only)" }
        summary = "Backup completed with $fileCount files (${backupSizeMB}MB)"
    }
    
    $emailDataJson = $emailData | ConvertTo-Json -Compress
    
    try {
        powershell -ExecutionPolicy Bypass -File "send-email-fixed.ps1" -Type "BackupComplete" -DataJson $emailDataJson
        Write-Host "Email notification sent" -ForegroundColor Green
    } catch {
        Write-Host "Failed to send email notification: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "`nEmail notifications not configured" -ForegroundColor Gray
    Write-Host "To enable, configure modules/email/config\modules/email/config.json" -ForegroundColor Gray
}
