# OpenClaw Email Notification System
# Version: 1.0.0
# Description: Send email notifications for OpenClaw automation events
# Author: Hell Cat (Digital Ghost Assistant)
# Date: 2026-03-06

# Configuration
$ConfigPath = "modules/email/config\modules/email/config.json"
$LogDir = "modules/email/logs"
$TemplateDir = "email-templates"

# Create directories if they don't exist
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}
if (-not (Test-Path $TemplateDir)) {
    New-Item -ItemType Directory -Path $TemplateDir -Force | Out-Null
}

# Timestamp for this run
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$LogFile = "$LogDir\email-send-$Timestamp.log"

# Start logging
Start-Transcript -Path $LogFile -Append
Write-Host "=== OpenClaw Email Notification System ===" -ForegroundColor Cyan
Write-Host "Start Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Function: Load configuration
function Load-EmailConfig {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        Write-Host "ERROR: Configuration file not found: $Path" -ForegroundColor Red
        Write-Host "Please copy modules/email/config-template.json to modules/email/config.json" -ForegroundColor Yellow
        Write-Host "and update with your email settings" -ForegroundColor Yellow
        return $null
    }
    
    try {
        $config = Get-Content $Path -Raw | ConvertFrom-Json -ErrorAction Stop
        
        if (-not $config.Email.Enabled) {
            Write-Host "WARNING: Email notifications are disabled in configuration" -ForegroundColor Yellow
            return $null
        }
        
        Write-Host "Configuration loaded successfully" -ForegroundColor Green
        return $config
        
    } catch {
        Write-Host "ERROR: Cannot load configuration" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Yellow
        return $null
    }
}

# Function: Get email credentials
function Get-EmailCredentials {
    param([object]$Config)
    
    $credentials = @{
        Username = $null
        Password = $null
    }
    
    # Try environment variables first (most secure)
    if ($env:OPENCLAW_EMAIL_USER -and $env:OPENCLAW_EMAIL_PASS) {
        Write-Host "Using credentials from environment variables" -ForegroundColor Green
        $credentials.Username = $env:OPENCLAW_EMAIL_USER
        $credentials.Password = $env:OPENCLAW_EMAIL_PASS
        return $credentials
    }
    
    # Check if credentials are in config (not recommended for production)
    if ($Config.Email.Credentials.Username -and $Config.Email.Credentials.Password) {
        Write-Host "WARNING: Using credentials from config file (not secure)" -ForegroundColor Yellow
        $credentials.Username = $Config.Email.Credentials.Username
        $credentials.Password = $Config.Email.Credentials.Password
        return $credentials
    }
    
    Write-Host "ERROR: No email credentials found" -ForegroundColor Red
    Write-Host "Set environment variables:" -ForegroundColor Yellow
    Write-Host "  OPENCLAW_EMAIL_USER = your-email@gmail.com" -ForegroundColor Gray
    Write-Host "  OPENCLAW_EMAIL_PASS = your-app-password" -ForegroundColor Gray
    return $null
}

# Function: Get email template
function Get-EmailTemplate {
    param(
        [string]$Type,
        [object]$Config,
        [hashtable]$Data
    )
    
    # Check if template exists in config
    if ($Config.Email.Templates.$Type) {
        $template = $Config.Email.Templates.$Type
        
        # Replace placeholders in subject
        $subject = $template.Subject
        foreach ($key in $Data.Keys) {
            $subject = $subject -replace "\{$key\}", $Data[$key]
        }
        
        # Replace placeholders in body
        $body = $template.Body
        foreach ($key in $Data.Keys) {
            $body = $body -replace "\{$key\}", $Data[$key]
        }
        
        # Add timestamp if not already in data
        if ($subject -notmatch "\{timestamp\}") {
            $subject = $subject -replace "\{timestamp\}", (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        }
        if ($body -notmatch "\{timestamp\}") {
            $body = $body -replace "\{timestamp\}", (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        }
        
        return @{
            Subject = $subject
            Body = $body
        }
    }
    
    # Default templates if not in config
    $defaultTemplates = @{
        BackupComplete = @{
            Subject = "OpenClaw Backup Complete - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
            Body = @"
OpenClaw Backup Report

Backup completed successfully!

Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Files: $($Data.fileCount)
Size: $($Data.backupSize)
Location: $($Data.backupPath)
Status: $($Data.status)

Summary:
$($Data.summary)

---
This is an automated message from OpenClaw.
"@
        }
        SecurityCheck = @{
            Subject = "OpenClaw Security Check - $(Get-Date -Format 'yyyy-MM-dd')"
            Body = @"
OpenClaw Security Check Report

Security check completed!

Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Passed: $($Data.passed)
Failed: $($Data.failed)
Warnings: $($Data.warnings)

Details:
$($Data.details)

---
This is an automated message from OpenClaw.
"@
        }
        SystemAlert = @{
            Subject = "鈿狅笍 OpenClaw System Alert - $($Data.alertType)"
            Body = @"
OpenClaw System Alert

Alert Type: $($Data.alertType)
Severity: $($Data.severity)
Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

Details:
$($Data.alertDetails)

System Status:
$($Data.systemStatus)

Recommended Actions:
$($Data.recommendations)

---
This is an automated alert from OpenClaw.
"@
        }
        DailySummary = @{
            Subject = "OpenClaw Daily Summary - $(Get-Date -Format 'yyyy-MM-dd')"
            Body = @"
OpenClaw Daily Activity Summary

Date: $(Get-Date -Format 'yyyy-MM-dd')
Period: $($Data.period)

Activities:
$($Data.activities)

Statistics:
$($Data.statistics)

Issues:
$($Data.issues)

Next Actions:
$($Data.nextActions)

---
This is an automated summary from OpenClaw.
"@
        }
    }
    
    if ($defaultTemplates[$Type]) {
        return $defaultTemplates[$Type]
    }
    
    # Fallback template
    return @{
        Subject = "OpenClaw Notification - $Type"
        Body = @"
OpenClaw Notification

Type: $Type
Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

Data:
$(($Data | ConvertTo-Json -Depth 2))

---
This is an automated message from OpenClaw.
"@
    }
}

# Function: Send email
function Send-Email {
    param(
        [string]$Type,
        [hashtable]$Data = @{},
        [switch]$Test = $false
    )
    
    Write-Host "Preparing to send email: $Type" -ForegroundColor Yellow
    
    # Load configuration
    $config = Load-EmailConfig -Path $ConfigPath
    if (-not $config) {
        Write-Host "Cannot send email: Configuration not loaded" -ForegroundColor Red
        return $false
    }
    
    # Check if this notification type is enabled
    if (-not $config.Email.Notifications.$Type) {
        Write-Host "Notification type '$Type' is disabled in configuration" -ForegroundColor Yellow
        return $false
    }
    
    # Get credentials
    $credentials = Get-EmailCredentials -Config $config
    if (-not $credentials) {
        Write-Host "Cannot send email: No credentials" -ForegroundColor Red
        return $false
    }
    
    # Get recipients
    $recipients = $config.Email.Recipients
    if ($recipients.Count -eq 0) {
        Write-Host "WARNING: No recipients configured" -ForegroundColor Yellow
        return $false
    }
    
    # Get template
    $template = Get-EmailTemplate -Type $Type -Config $config -Data $Data
    
    # Prepare email parameters
    $emailParams = @{
        From = $credentials.Username
        To = $recipients -join ", "
        Subject = $template.Subject
        Body = $template.Body
        SmtpServer = $config.Email.SMTP.Server
        Port = $config.Email.SMTP.Port
        UseSsl = $config.Email.SMTP.SSL
        Credential = New-Object System.Management.Automation.PSCredential (
            $credentials.Username,
            (ConvertTo-SecureString $credentials.Password -AsPlainText -Force)
        )
    }
    
    # Test mode - don't actually send
    if ($Test) {
        Write-Host "TEST MODE: Would send email with parameters:" -ForegroundColor Cyan
        Write-Host "  From: $($emailParams.From)" -ForegroundColor Gray
        Write-Host "  To: $($emailParams.To)" -ForegroundColor Gray
        Write-Host "  Subject: $($emailParams.Subject)" -ForegroundColor Gray
        Write-Host "  Body length: $($emailParams.Body.Length) characters" -ForegroundColor Gray
        Write-Host "  SMTP: $($emailParams.SmtpServer):$($emailParams.Port)" -ForegroundColor Gray
        Write-Host "  SSL: $($emailParams.UseSsl)" -ForegroundColor Gray
        
        # Save test email to file
        $testFile = "$LogDir\test-email-$Timestamp.txt"
        $testContent = @"
From: $($emailParams.From)
To: $($emailParams.To)
Subject: $($emailParams.Subject)
Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

$($emailParams.Body)
"@
        $testContent | Out-File -FilePath $testFile -Encoding UTF8
        Write-Host "Test email saved to: $testFile" -ForegroundColor Green
        
        return $true
    }
    
    # Actually send the email
    try {
        Write-Host "Sending email to $($recipients.Count) recipients..." -ForegroundColor Yellow
        
        Send-MailMessage @emailParams -ErrorAction Stop
        
        Write-Host "Email sent successfully!" -ForegroundColor Green
        Write-Host "  Type: $Type" -ForegroundColor Gray
        Write-Host "  Recipients: $($recipients.Count)" -ForegroundColor Gray
        Write-Host "  Subject: $($template.Subject)" -ForegroundColor Gray
        
        # Log successful send
        $logEntry = @{
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Type = $Type
            Status = "Success"
            Recipients = $recipients
            Subject = $template.Subject
        }
        
        $logFile = "$LogDir\email-history.json"
        $history = @()
        if (Test-Path $logFile) {
            $history = Get-Content $logFile -Raw | ConvertFrom-Json
        }
        $history += $logEntry
        $history | Select-Object -Last 100 | ConvertTo-Json -Depth 3 | Out-File $logFile -Encoding UTF8
        
        return $true
        
    } catch {
        Write-Host "ERROR: Failed to send email" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Yellow
        
        # Log failure
        $logEntry = @{
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Type = $Type
            Status = "Failed"
            Error = $_.Exception.Message
        }
        
        $logFile = "$LogDir\email-errors.json"
        $errors = @()
        if (Test-Path $logFile) {
            $errors = Get-Content $logFile -Raw | ConvertFrom-Json
        }
        $errors += $logEntry
        $errors | Select-Object -Last 100 | ConvertTo-Json -Depth 3 | Out-File $logFile -Encoding UTF8
        
        return $false
    }
}

# Main execution - handle command line parameters
param(
    [string]$Type,
    [string]$DataJson,
    [switch]$Test,
    [switch]$Help
)

if ($Help) {
    Write-Host "OpenClaw Email Notification System Help" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\send-email.ps1 -Type <type> [-DataJson <json>] [-Test] [-Help]" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Parameters:" -ForegroundColor Yellow
    Write-Host "  -Type        Notification type (BackupComplete, SecurityCheck, SystemAlert, DailySummary)" -ForegroundColor Gray
    Write-Host "  -DataJson    JSON string with template data (optional)" -ForegroundColor Gray
    Write-Host "  -Test        Test mode - don't actually send email" -ForegroundColor Gray
    Write-Host "  -Help        Show this help message" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  .\send-email.ps1 -Type BackupComplete -Test" -ForegroundColor Gray
    Write-Host "  .\send-email.ps1 -Type SecurityCheck -DataJson '{\"passed\":11,\"failed\":0}'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Configuration:" -ForegroundColor Yellow
    Write-Host "  Edit modules/email/config\modules/email/config.json to configure email settings" -ForegroundColor Gray
    Write-Host "  Set environment variables OPENCLAW_EMAIL_USER and OPENCLAW_EMAIL_PASS" -ForegroundColor Gray
    exit 0
}

if (-not $Type) {
    Write-Host "ERROR: Notification type is required" -ForegroundColor Red
    Write-Host "Use -Help for usage information" -ForegroundColor Yellow
    exit 1
}

# Parse data JSON if provided
$data = @{}
if ($DataJson) {
    try {
        $data = $DataJson | ConvertFrom-Json -AsHashtable
    } catch {
        Write-Host "WARNING: Cannot parse DataJson, using empty data" -ForegroundColor Yellow
    }
}

# Send the email
$result = Send-Email -Type $Type -Data $data -Test:$Test

if ($result) {
    Write-Host "`nEmail operation completed successfully" -ForegroundColor Green
} else {
    Write-Host "`nEmail operation failed" -ForegroundColor Red
}

Write-Host "`nLog file: $LogFile" -ForegroundColor Gray
Stop-Transcript

exit $(if ($result) { 0 } else { 1 })
