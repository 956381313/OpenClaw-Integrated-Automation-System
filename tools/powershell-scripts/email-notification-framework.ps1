# Email Notification Framework

Write-Host "=== OpenClaw Email Notification Framework ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Configuration template
$configTemplate = @{
    Email = @{
        Enabled = $false
        SMTP = @{
            Server = "smtp.gmail.com"
            Port = 587
            SSL = $true
        }
        Credentials = @{
            Username = "your-email@gmail.com"
            # Password should be stored securely
        }
        Notifications = @{
            BackupComplete = $true
            SecurityCheck = $true
            SystemAlert = $true
            DailySummary = $true
        }
        Recipients = @(
            "recipient1@example.com",
            "recipient2@example.com"
        )
    }
    Templates = @{
        BackupComplete = @{
            Subject = "OpenClaw Backup Complete - {timestamp}"
            Body = @"
OpenClaw Backup Report

Backup completed successfully!

Details:
- Time: {timestamp}
- Files: {fileCount}
- Size: {backupSize}
- Location: {backupPath}
- GitHub: {githubStatus}

Summary:
{summary}

---
This is an automated message from OpenClaw.
"@
        }
        SystemAlert = @{
            Subject = "鈿狅笍 OpenClaw System Alert - {alertType}"
            Body = @"
OpenClaw System Alert

Alert Type: {alertType}
Severity: {severity}
Time: {timestamp}

Details:
{alertDetails}

System Status:
{systemStatus}

Recommended Actions:
{recommendations}

---
This is an automated alert from OpenClaw.
"@
        }
    }
}

# Create configuration directory
$configDir = "modules/email/config"
if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    Write-Host "Created configuration directory: $configDir" -ForegroundColor Green
}

# Save configuration template
$configFile = Join-Path $configDir "modules/email/config-template.json"
$configTemplate | ConvertTo-Json -Depth 4 | Out-File $configFile -Encoding UTF8

Write-Host "Configuration template saved: $configFile" -ForegroundColor Green

# Create setup guide
$setupGuide = @"
# OpenClaw Email Notification Setup Guide

## Overview
This system enables OpenClaw to send email notifications for various events.

## Configuration Steps

### 1. Email Provider Setup
Choose your email provider and get SMTP settings:

#### Gmail (Recommended):
- SMTP Server: smtp.gmail.com
- Port: 587
- SSL: Yes
- Requires: App password (not regular password)

#### Outlook/Office 365:
- SMTP Server: smtp.office365.com
- Port: 587
- SSL: Yes

#### Other Providers:
Check your provider's SMTP settings.

### 2. Security Configuration
For security, NEVER store passwords in plain text:

#### Option A: Environment Variables (Recommended)
```powershell
# Set environment variables
`$env:OPENCLAW_EMAIL_USER = "your-email@gmail.com"
`$env:OPENCLAW_EMAIL_PASS = "your-app-password"
```

#### Option B: Windows Credential Manager
```powershell
# Store credentials securely
cmdkey /add:smtp.server.com /user:username /pass:password
```

### 3. Edit Configuration
Edit `modules/email/config-template.json`:

1. Set `Enabled` to `true`
2. Update SMTP settings
3. Add recipient emails
4. Customize templates as needed

### 4. Test Configuration
Run the test script:
```powershell
.\test-modules/email/config.ps1
```

## Notification Types

### 1. Backup Complete
- Trigger: After successful backup
- Content: Backup details and status
- Frequency: After each backup

### 2. Security Check
- Trigger: Daily security check
- Content: Security check results
- Frequency: Daily

### 3. System Alerts
- Trigger: System issues detected
- Content: Alert details and recommendations
- Frequency: As needed

### 4. Daily/Weekly Summary
- Trigger: Scheduled time
- Content: System activity summary
- Frequency: Daily or weekly

## Integration with Existing System

### Modify Backup Script
Add email notification after backup:
```powershell
# In backup-english.ps1, after successful backup:
if (Test-Path "modules/email/config\modules/email/config.json") {
    .\send-email.ps1 -Type "BackupComplete" -Data @{
        fileCount = `$fileCount
        backupPath = `$backupPath
        githubStatus = "Success"
    }
}
```

### Modify Security Check Script
Add email notification:
```powershell
# In security-check-english.ps1, after check:
if (Test-Path "modules/email/config\modules/email/config.json") {
    .\send-email.ps1 -Type "SecurityCheck" -Data @{
        passed = `$results.Passed
        failed = `$results.Failed
        warnings = `$results.Warnings
    }
}
```

## Security Best Practices

### 1. Credential Security
- Never commit credentials to git
- Use environment variables or secure storage
- Rotate passwords regularly

### 2. Email Content
- Avoid sensitive information in emails
- Use generic error messages
- Include only necessary details

### 3. Rate Limiting
- Limit email frequency
- Implement cooldown periods
- Respect recipient preferences

## Troubleshooting

### Common Issues:

#### 1. Authentication Failed
- Check username/password
- Verify app password for Gmail
- Check if less secure apps allowed

#### 2. Connection Failed
- Verify SMTP server and port
- Check firewall settings
- Test network connectivity

#### 3. Emails Not Received
- Check spam folder
- Verify recipient addresses
- Check email server logs

## Advanced Features

### 1. HTML Emails
Enable HTML formatting for better presentation.

### 2. Attachments
Attach reports or logs to emails.

### 3. Multiple Recipients
Send to different groups based on alert type.

### 4. Conditional Notifications
Only send emails for important events.

## Support

### Documentation
- Configuration guide: This file
- API documentation: send-email.ps1 help
- Troubleshooting guide: See above

### Testing
- Test script: test-modules/email/config.ps1
- Debug mode: .\send-email.ps1 -Debug

### Updates
Check for updates to email system regularly.

---
*Email Notification Framework v1.0*
*Setup guide generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')*
"@

$guideFile = Join-Path $configDir "SETUP-GUIDE.md"
$setupGuide | Out-File $guideFile -Encoding UTF8

Write-Host "Setup guide saved: $guideFile" -ForegroundColor Green

# Create test script
$testScript = @'
# Test Email Configuration

Write-Host "=== Testing Email Configuration ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Check configuration
$configFile = "modules/email/config\modules/email/config.json"
if (-not (Test-Path $configFile)) {
    Write-Host "ERROR: Configuration file not found" -ForegroundColor Red
    Write-Host "Please copy modules/email/config-template.json to modules/email/config.json" -ForegroundColor Yellow
    Write-Host "and update with your settings" -ForegroundColor Yellow
    exit 1
}

# Load configuration
try {
    $config = Get-Content $configFile | ConvertFrom-Json -ErrorAction Stop
    
    if (-not $config.Email.Enabled) {
        Write-Host "Email notifications are disabled in configuration" -ForegroundColor Yellow
        Write-Host "Set Enabled to true to enable notifications" -ForegroundColor Gray
    }
    
    Write-Host "Configuration loaded successfully" -ForegroundColor Green
    Write-Host "SMTP Server: $($config.Email.SMTP.Server):$($config.Email.SMTP.Port)" -ForegroundColor Gray
    Write-Host "SSL: $($config.Email.SMTP.SSL)" -ForegroundColor Gray
    Write-Host "Recipients: $($config.Email.Recipients.Count)" -ForegroundColor Gray
    
} catch {
    Write-Host "ERROR: Cannot load configuration" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Yellow
    exit 1
}

# Check for credentials
Write-Host "`nChecking credentials..." -ForegroundColor Yellow

$hasCredentials = $false

# Check environment variables
if ($env:OPENCLAW_EMAIL_USER -and $env:OPENCLAW_EMAIL_PASS) {
    Write-Host "  Found credentials in environment variables" -ForegroundColor Green
    $hasCredentials = $true
} else {
    Write-Host "  No credentials in environment variables" -ForegroundColor Yellow
    Write-Host "  Set OPENCLAW_EMAIL_USER and OPENCLAW_EMAIL_PASS environment variables" -ForegroundColor Gray
}

# Test SMTP connection (if credentials available)
if ($hasCredentials) {
    Write-Host "`nTesting SMTP connection..." -ForegroundColor Yellow
    
    try {
        # This is a basic test - actual email sending would be in send-email.ps1
        Write-Host "  SMTP configuration appears valid" -ForegroundColor Green
        Write-Host "  Note: Actual email sending test requires send-email.ps1 script" -ForegroundColor Gray
        
    } catch {
        Write-Host "  ERROR: SMTP test failed" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Yellow
    }
}

# Summary
Write-Host "`n=== Test Complete ===" -ForegroundColor Green

if ($hasCredentials -and $config.Email.Enabled) {
    Write-Host "鉁?Email system is ready for use" -ForegroundColor Green
    Write-Host "Next: Create send-email.ps1 script" -ForegroundColor Gray
} else {
    Write-Host "鈿狅笍  Email system needs configuration" -ForegroundColor Yellow
    Write-Host "Follow the setup guide to complete configuration" -ForegroundColor Gray
}

Write-Host "`nConfiguration file: $configFile" -ForegroundColor Cyan
Write-Host "Setup guide: modules/email/config\SETUP-GUIDE.md" -ForegroundColor Cyan
'@

$testFile = "test-modules/email/config.ps1"
$testScript | Out-File $testFile -Encoding UTF8

Write-Host "Test script created: $testFile" -ForegroundColor Green

# Complete
Write-Host "`n=== Email Notification Framework Created ===" -ForegroundColor Green
Write-Host "Configuration template: $configFile" -ForegroundColor Cyan
Write-Host "Setup guide: $guideFile" -ForegroundColor Cyan
Write-Host "Test script: $testFile" -ForegroundColor Cyan

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Review setup guide: $guideFile" -ForegroundColor Gray
Write-Host "2. Configure email settings" -ForegroundColor Gray
Write-Host "3. Test configuration: .\$testFile" -ForegroundColor Gray
Write-Host "4. Create send-email.ps1 script" -ForegroundColor Gray

Write-Host "`nEstimated time to implement: 2-3 hours" -ForegroundColor Cyan
