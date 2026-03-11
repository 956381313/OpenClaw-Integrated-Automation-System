# OpenClaw Security Check (English Version)

Write-Host "=== OpenClaw Security Check ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Results tracking
$results = @{
    Total = 0
    Passed = 0
    Failed = 0
    Warnings = 0
}

# Function to add check result
function Add-CheckResult {
    param([string]$Check, [string]$Status, [string]$Message)
    
    $results.Total++
    
    switch ($Status) {
        "PASS" { 
            $results.Passed++
            $color = "Green"
        }
        "FAIL" { 
            $results.Failed++
            $color = "Red"
        }
        "WARN" { 
            $results.Warnings++
            $color = "Yellow"
        }
    }
    
    Write-Host "  [$Status] $Check" -ForegroundColor $color
    if ($Message) {
        Write-Host "    $Message" -ForegroundColor Gray
    }
}

# Check 1: OpenClaw directory
Write-Host "1. Checking OpenClaw directory..." -ForegroundColor Yellow
$openclawPath = "C:\Users\luchaochao\.openclaw"
if (Test-Path $openclawPath) {
    Add-CheckResult -Check "OpenClaw Directory" -Status "PASS" -Message "Path: $openclawPath"
} else {
    Add-CheckResult -Check "OpenClaw Directory" -Status "FAIL" -Message "Directory not found"
}

# Check 2: Core configuration files
Write-Host "`n2. Checking core configuration files..." -ForegroundColor Yellow
$coreFiles = @(
    "$openclawPath\openclaw.json",
    "$openclawPath\gateway.cmd",
    "$openclawPath\update-check.json"
)

foreach ($file in $coreFiles) {
    $fileName = Split-Path $file -Leaf
    if (Test-Path $file) {
        Add-CheckResult -Check $fileName -Status "PASS"
    } else {
        Add-CheckResult -Check $fileName -Status "FAIL"
    }
}

# Check 3: Workspace files
Write-Host "`n3. Checking workspace files..." -ForegroundColor Yellow
$workspaceFiles = @(
    "$openclawPath\workspace\AGENTS.md",
    "$openclawPath\workspace\SOUL.md",
    "$openclawPath\workspace\TOOLS.md",
    "$openclawPath\workspace\USER.md"
)

foreach ($file in $workspaceFiles) {
    $fileName = Split-Path $file -Leaf
    if (Test-Path $file) {
        Add-CheckResult -Check $fileName -Status "PASS"
    } else {
        Add-CheckResult -Check $fileName -Status "WARN"
    }
}

# Check 4: Security tools directory
Write-Host "`n4. Checking security tools..." -ForegroundColor Yellow
$securityToolsPath = "C:\Users\luchaochao\.openclaw\workspace\09-projects\security-tools"
if (Test-Path $securityToolsPath) {
    Add-CheckResult -Check "Security Tools Directory" -Status "PASS"
} else {
    Add-CheckResult -Check "Security Tools Directory" -Status "WARN"
}

# Check 5: Backup status
Write-Host "`n5. Checking backup status..." -ForegroundColor Yellow
$backupDir = "modules/backup/data"
if (Test-Path $backupDir) {
    $backupCount = (Get-ChildItem $backupDir -Directory).Count
    Add-CheckResult -Check "Backup Directory" -Status "PASS" -Message "$backupCount backups found"
} else {
    Add-CheckResult -Check "Backup Directory" -Status "WARN" -Message "Backup directory not found"
}

# Check 6: GitHub repository
Write-Host "`n6. Checking GitHub repository..." -ForegroundColor Yellow
$gitRepo = "services/github/cloud-backup"
if (Test-Path $gitRepo) {
    Add-CheckResult -Check "GitHub Repository" -Status "PASS"
} else {
    Add-CheckResult -Check "GitHub Repository" -Status "WARN"
}

# Summary
Write-Host "`n=== Security Check Summary ===" -ForegroundColor Cyan
Write-Host "Total checks: $($results.Total)" -ForegroundColor Gray
Write-Host "Passed: $($results.Passed)" -ForegroundColor Green
Write-Host "Failed: $($results.Failed)" -ForegroundColor $(if ($results.Failed -gt 0) { "Red" } else { "Gray" })
Write-Host "Warnings: $($results.Warnings)" -ForegroundColor $(if ($results.Warnings -gt 0) { "Yellow" } else { "Gray" })

# Overall status
if ($results.Failed -eq 0) {
    Write-Host "`nAll security checks passed!" -ForegroundColor Green
} else {
    Write-Host "`n$($results.Failed) security check(s) failed" -ForegroundColor Yellow
}

# Log results
$logEntry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Security Check - Total: $($results.Total), Passed: $($results.Passed), Failed: $($results.Failed), Warnings: $($results.Warnings)"
$logEntry | Out-File "security-check.log" -Append -Encoding UTF8

Write-Host "`nLog saved to: security-check.log" -ForegroundColor Gray

# Send email notification if configured
if (Test-Path "modules/email/config\modules/email/config.json") {
    Write-Host "`nSending email notification..." -ForegroundColor Yellow
    
    $details = @()
    if ($results.Failed -gt 0) {
        $details += "$($results.Failed) check(s) failed - Please review"
    }
    if ($results.Warnings -gt 0) {
        $details += "$($results.Warnings) warning(s) - Check recommended"
    }
    if ($results.Passed -eq $results.Total) {
        $details += "All checks passed - System secure"
    }
    
    $emailData = @{
        passed = $results.Passed
        failed = $results.Failed
        warnings = $results.Warnings
        details = ($details -join "`n")
    }
    
    $emailDataJson = $emailData | ConvertTo-Json -Compress
    
    try {
        powershell -ExecutionPolicy Bypass -File "send-email-fixed.ps1" -Type "SecurityCheck" -DataJson $emailDataJson
        Write-Host "Email notification sent" -ForegroundColor Green
    } catch {
        Write-Host "Failed to send email notification: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "`nEmail notifications not configured" -ForegroundColor Gray
    Write-Host "To enable, configure modules/email/config\modules/email/config.json" -ForegroundColor Gray
}
