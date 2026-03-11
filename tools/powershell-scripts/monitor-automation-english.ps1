# OpenClaw Automation Monitor (English Version)

Write-Host "=== OpenClaw Automation Monitor ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if ($isAdmin) {
    Write-Host "Running as Administrator" -ForegroundColor Green
} else {
    Write-Host "Running as Standard User" -ForegroundColor Yellow
    Write-Host "Some functions may be limited" -ForegroundColor Gray
}

Write-Host ""

# 1. Check automation tasks
Write-Host "1. Checking automation tasks..." -ForegroundColor Yellow

try {
    $tasks = Get-ScheduledTask | Where-Object {$_.TaskName -like 'OpenClaw*'} | Sort-Object TaskName
    
    if ($tasks.Count -eq 0) {
        Write-Host "  No OpenClaw automation tasks found" -ForegroundColor Yellow
    } else {
        Write-Host "  Found $($tasks.Count) OpenClaw tasks" -ForegroundColor Green
        
        foreach ($task in $tasks) {
            $statusColor = switch ($task.State) {
                "Ready"     { "Green" }
                "Running"   { "Cyan" }
                "Disabled"  { "Red" }
                default     { "Yellow" }
            }
            
            Write-Host "  - $($task.TaskName)" -ForegroundColor $statusColor -NoNewline
            Write-Host " ($($task.State))" -ForegroundColor Gray
            
            if ($task.NextRunTime) {
                Write-Host "    Next run: $($task.NextRunTime)" -ForegroundColor Gray
            }
        }
    }
} catch {
    Write-Host "  ERROR: Cannot access scheduled tasks" -ForegroundColor Red
    Write-Host "  Need Administrator rights to view tasks" -ForegroundColor Yellow
}

# 2. Check script status
Write-Host "`n2. Checking script status..." -ForegroundColor Yellow

$scripts = @(
    @{Name="Backup Script"; Path="backup-english.ps1"},
    @{Name="Security Check"; Path="security-check-english.ps1"},
    @{Name="Repository Org"; Path="organize-english.ps1"},
    @{Name="Update Automation"; Path="update-automation.ps1"}
)

foreach ($script in $scripts) {
    if (Test-Path $script.Path) {
        $size = (Get-Item $script.Path).Length / 1KB
        Write-Host "  [OK] $($script.Name)" -ForegroundColor Green -NoNewline
        Write-Host " ($([math]::Round($size, 2)) KB)" -ForegroundColor Gray
    } else {
        Write-Host "  [MISSING] $($script.Name)" -ForegroundColor Red
    }
}

# 3. Check backup status
Write-Host "`n3. Checking backup status..." -ForegroundColor Yellow

$backupDir = "modules/backup/data"
if (Test-Path $backupDir) {
    $backups = Get-ChildItem $backupDir -Directory
    $backupCount = $backups.Count
    
    if ($backupCount -gt 0) {
        $latest = $backups | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        $latestTime = $latest.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
        
        Write-Host "  Found $backupCount backups" -ForegroundColor Green
        Write-Host "  Latest: $($latest.Name) ($latestTime)" -ForegroundColor Gray
    } else {
        Write-Host "  Backup directory exists but empty" -ForegroundColor Yellow
    }
} else {
    Write-Host "  Backup directory not found" -ForegroundColor Yellow
}

# 4. Check GitHub repository
Write-Host "`n4. Checking GitHub repository..." -ForegroundColor Yellow

$gitRepo = "services/github/cloud-backup"
if (Test-Path $gitRepo) {
    Write-Host "  GitHub repository found" -ForegroundColor Green
    
    try {
        Set-Location $gitRepo -ErrorAction Stop
        
        # Get latest commit
        $commitInfo = git log --oneline -1 2>$null
        if ($commitInfo) {
            Write-Host "  Latest commit: $commitInfo" -ForegroundColor Gray
        }
        
        # Check remote
        $remoteUrl = git config --get remote.origin.url 2>$null
        if ($remoteUrl) {
            Write-Host "  Remote: $remoteUrl" -ForegroundColor Gray
        }
        
        Set-Location ..
    } catch {
        Write-Host "  Cannot access git repository" -ForegroundColor Yellow
    }
} else {
    Write-Host "  GitHub repository not found" -ForegroundColor Yellow
}

# 5. Check repository organization system
Write-Host "`n5. Checking repository organization..." -ForegroundColor Yellow

$repoOrgDir = "modules/organization"
if (Test-Path $repoOrgDir) {
    $modules = Get-ChildItem $repoOrgDir -Directory
    Write-Host "  Found $($modules.Count) modules" -ForegroundColor Green
    
    # Check knowledge base
    $kbDir = Join-Path $repoOrgDir "05-knowledge-base"
    if (Test-Path $kbDir) {
        $kbFiles = Get-ChildItem $kbDir -File -Filter "*.json"
        Write-Host "  Knowledge base: $($kbFiles.Count) files" -ForegroundColor Gray
    }
} else {
    Write-Host "  Repository organization system not found" -ForegroundColor Yellow
}

# Summary
Write-Host "`n=== Automation Status Summary ===" -ForegroundColor Cyan

$summary = @{
    "Admin Rights" = if ($isAdmin) { "Yes" } else { "No" }
    "OpenClaw Tasks" = if ($tasks) { $tasks.Count } else { "Unknown" }
    "English Scripts" = ($scripts | Where-Object { Test-Path $_.Path }).Count
    "Backups" = if (Test-Path $backupDir) { (Get-ChildItem $backupDir -Directory).Count } else { 0 }
    "GitHub Repo" = if (Test-Path $gitRepo) { "Found" } else { "Not found" }
    "Repo Org System" = if (Test-Path $repoOrgDir) { "Ready" } else { "Not ready" }
}

foreach ($key in $summary.Keys) {
    $value = $summary[$key]
    $color = if ($value -match "Yes|Ready|Found" -or $value -gt 0) { "Green" } else { "Yellow" }
    
    Write-Host "  $key : $value" -ForegroundColor $color
}

# Recommendations
Write-Host "`n=== Recommendations ===" -ForegroundColor Yellow

if (-not $isAdmin) {
    Write-Host "1. Run as Administrator to update automation tasks" -ForegroundColor Red
    Write-Host "   Right-click PowerShell -> Run as Administrator" -ForegroundColor Gray
    Write-Host "   Then run: .\update-automation.ps1" -ForegroundColor Gray
}

if ($summary."English Scripts" -lt 4) {
    Write-Host "2. Some English scripts are missing" -ForegroundColor Yellow
}

if ($summary."Backups" -eq 0) {
    Write-Host "3. No backups found, run backup script" -ForegroundColor Yellow
    Write-Host "   .\backup-english.ps1" -ForegroundColor Gray
}

Write-Host "`n=== Quick Commands ===" -ForegroundColor Cyan
Write-Host "Run backup: .\backup-english.ps1" -ForegroundColor Gray
Write-Host "Security check: .\security-check-english.ps1" -ForegroundColor Gray
Write-Host "Organize & cleanup: .\organize-and-cleanup.ps1" -ForegroundColor Gray
Write-Host "Update automation (Admin): .\update-automation.ps1" -ForegroundColor Gray

Write-Host "`nPress Enter to exit..." -ForegroundColor Gray
Read-Host
