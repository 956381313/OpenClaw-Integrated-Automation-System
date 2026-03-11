# OpenClaw Email System Setup Script
# This script helps set up the email notification system

Write-Host "=== OpenClaw Email System Setup ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Check if email config directory exists
$configDir = "modules/email/config"
if (-not (Test-Path $configDir)) {
    Write-Host "Creating email configuration directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    Write-Host "Created: $configDir" -ForegroundColor Green
}

# Check for template
$templateFile = "$configDir\modules/email/config-template.json"
if (-not (Test-Path $templateFile)) {
    Write-Host "ERROR: Email configuration template not found" -ForegroundColor Red
    Write-Host "Please run email-notification-framework.ps1 first" -ForegroundColor Yellow
    exit 1
}

Write-Host "1. Configuration template found: $templateFile" -ForegroundColor Green

# Check if config already exists
$configFile = "$configDir\modules/email/config.json"
if (Test-Path $configFile) {
    Write-Host "2. Configuration file already exists: $configFile" -ForegroundColor Yellow
    
    $choice = Read-Host "Do you want to overwrite? (y/N)"
    if ($choice -ne "y" -and $choice -ne "Y") {
        Write-Host "Keeping existing configuration" -ForegroundColor Green
        Write-Host "Edit $configFile manually to update settings" -ForegroundColor Gray
        exit 0
    }
}

# Create configuration from template
Write-Host "`n2. Creating email configuration..." -ForegroundColor Yellow

try {
    $template = Get-Content $templateFile -Raw | ConvertFrom-Json
    
    # Interactive configuration
    Write-Host "`nPlease provide email configuration:" -ForegroundColor Cyan
    
    # SMTP Settings
    $smtpServer = Read-Host "SMTP Server (e.g., smtp.gmail.com)"
    $smtpPort = Read-Host "SMTP Port (e.g., 587)"
    $useSsl = Read-Host "Use SSL? (Y/n)"
    
    # Email credentials (will be stored in environment variables)
    $emailUser = Read-Host "Email address (e.g., your-email@gmail.com)"
    Write-Host "Note: Password should be set as environment variable OPENCLAW_EMAIL_PASS" -ForegroundColor Yellow
    
    # Recipients
    Write-Host "`nEnter recipient email addresses (one per line, blank line to finish):" -ForegroundColor Cyan
    $recipients = @()
    while ($true) {
        $recipient = Read-Host "Recipient email"
        if ([string]::IsNullOrWhiteSpace($recipient)) {
            break
        }
        if ($recipient -match '^[^@]+@[^@]+\.[^@]+$') {
            $recipients += $recipient
            Write-Host "  Added: $recipient" -ForegroundColor Gray
        } else {
            Write-Host "  Invalid email format, skipping" -ForegroundColor Yellow
        }
    }
    
    # Notification preferences
    Write-Host "`nEnable notifications for:" -ForegroundColor Cyan
    
    $backupNotify = Read-Host "Backup completion? (Y/n)"
    $securityNotify = Read-Host "Security check? (Y/n)"
    $systemNotify = Read-Host "System alerts? (Y/n)"
    $summaryNotify = Read-Host "Daily summary? (Y/n)"
    
    # Update configuration
    $template.Email.Enabled = $true
    $template.Email.SMTP.Server = $smtpServer
    $template.Email.SMTP.Port = [int]$smtpPort
    $template.Email.SMTP.SSL = ($useSsl -ne "n" -and $useSsl -ne "N")
    $template.Email.Credentials.Username = $emailUser
    $template.Email.Recipients = $recipients
    
    $template.Email.Notifications.BackupComplete = ($backupNotify -ne "n" -and $backupNotify -ne "N")
    $template.Email.Notifications.SecurityCheck = ($securityNotify -ne "n" -and $securityNotify -ne "N")
    $template.Email.Notifications.SystemAlert = ($systemNotify -ne "n" -and $systemNotify -ne "N")
    $template.Email.Notifications.DailySummary = ($summaryNotify -ne "n" -and $summaryNotify -ne "N")
    
    # Save configuration
    $template | ConvertTo-Json -Depth 4 | Out-File $configFile -Encoding UTF8
    
    Write-Host "`nConfiguration saved: $configFile" -ForegroundColor Green
    
} catch {
    Write-Host "ERROR: Failed to create configuration" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Yellow
    exit 1
}

# Set up environment variables
Write-Host "`n3. Setting up environment variables..." -ForegroundColor Yellow

Write-Host "`nIMPORTANT: For security, email password should be set as environment variable" -ForegroundColor Cyan
Write-Host "You need to set the following environment variables:" -ForegroundColor Gray
Write-Host ""
Write-Host "  OPENCLAW_EMAIL_USER = your email address" -ForegroundColor White
Write-Host "  OPENCLAW_EMAIL_PASS = your app password (not regular password)" -ForegroundColor White
Write-Host ""
Write-Host "To set environment variables:" -ForegroundColor Gray

Write-Host "`nOption 1: Temporary (current session only)" -ForegroundColor Yellow
Write-Host "  In PowerShell:" -ForegroundColor Gray
Write-Host "    `$env:OPENCLAW_EMAIL_USER = '$emailUser'" -ForegroundColor White
Write-Host "    `$env:OPENCLAW_EMAIL_PASS = 'your-app-password'" -ForegroundColor White

Write-Host "`nOption 2: Permanent (user level)" -ForegroundColor Yellow
Write-Host "  In PowerShell (as Administrator):" -ForegroundColor Gray
Write-Host "    [Environment]::SetEnvironmentVariable('OPENCLAW_EMAIL_USER', '$emailUser', 'User')" -ForegroundColor White
Write-Host "    [Environment]::SetEnvironmentVariable('OPENCLAW_EMAIL_PASS', 'your-app-password', 'User')" -ForegroundColor White

Write-Host "`nOption 3: System-wide (requires Administrator)" -ForegroundColor Yellow
Write-Host "  In PowerShell (as Administrator):" -ForegroundColor Gray
Write-Host "    [Environment]::SetEnvironmentVariable('OPENCLAW_EMAIL_USER', '$emailUser', 'Machine')" -ForegroundColor White
Write-Host "    [Environment]::SetEnvironmentVariable('OPENCLAW_EMAIL_PASS', 'your-app-password', 'Machine')" -ForegroundColor White

# Create test script
Write-Host "`n4. Creating test script..." -ForegroundColor Yellow

$testScript = @"
# Test Email Configuration

Write-Host "=== Testing OpenClaw Email System ===" -ForegroundColor Cyan
Write-Host "Time: `$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Check configuration
`$configFile = "$configFile"
if (-not (Test-Path `$configFile)) {
    Write-Host "ERROR: Configuration file not found" -ForegroundColor Red
    exit 1
}

# Load configuration
try {
    `$config = Get-Content `$configFile -Raw | ConvertFrom-Json -ErrorAction Stop
    
    Write-Host "Configuration loaded successfully" -ForegroundColor Green
    Write-Host "SMTP Server: `$(`$config.Email.SMTP.Server):`$(`$config.Email.SMTP.Port)" -ForegroundColor Gray
    Write-Host "SSL: `$(`$config.Email.SMTP.SSL)" -ForegroundColor Gray
    Write-Host "Enabled: `$(`$config.Email.Enabled)" -ForegroundColor Gray
    Write-Host "Recipients: `$(`$config.Email.Recipients.Count)" -ForegroundColor Gray
    
    # Check enabled notifications
    Write-Host "`nEnabled notifications:" -ForegroundColor Yellow
    foreach (`$notification in `$config.Email.Notifications.PSObject.Properties) {
        Write-Host "  `$(`$notification.Name): `$(`$notification.Value)" -ForegroundColor Gray
    }
    
} catch {
    Write-Host "ERROR: Cannot load configuration" -ForegroundColor Red
    Write-Host "Error: `$_" -ForegroundColor Yellow
    exit 1
}

# Check environment variables
Write-Host "`nChecking environment variables..." -ForegroundColor Yellow

if (`$env:OPENCLAW_EMAIL_USER -and `$env:OPENCLAW_EMAIL_PASS) {
    Write-Host "  Found credentials in environment variables" -ForegroundColor Green
    Write-Host "  User: `$env:OPENCLAW_EMAIL_USER" -ForegroundColor Gray
    
    # Test email sending
    Write-Host "`nTesting email sending (test mode)..." -ForegroundColor Yellow
    
    try {
        powershell -ExecutionPolicy Bypass -File "send-email.ps1" -Type "BackupComplete" -Test
        Write-Host "`nEmail test completed successfully!" -ForegroundColor Green
        Write-Host "Check modules/email/logs directory for test results" -ForegroundColor Gray
        
    } catch {
        Write-Host "ERROR: Email test failed" -ForegroundColor Red
        Write-Host "Error: `$_" -ForegroundColor Yellow
    }
    
} else {
    Write-Host "  No credentials found in environment variables" -ForegroundColor Yellow
    Write-Host "  Please set OPENCLAW_EMAIL_USER and OPENCLAW_EMAIL_PASS" -ForegroundColor Gray
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan
Write-Host "Configuration: `$configFile" -ForegroundColor Gray
Write-Host "Test script: .\test-email-system.ps1" -ForegroundColor Gray
Write-Host "Send test email: .\run-email-test.bat" -ForegroundColor Gray
"@

$testScript | Out-File "test-email-system.ps1" -Encoding UTF8
Write-Host "Test script created: test-email-system.ps1" -ForegroundColor Green

# Update automation configuration
Write-Host "`n5. Updating automation configuration..." -ForegroundColor Yellow

$automationConfig = "automation-config-english.json"
if (Test-Path $automationConfig) {
    try {
        $config = Get-Content $automationConfig -Raw | ConvertFrom-Json
        
        # Add email system to configuration
        $config.Scripts | Add-Member -NotePropertyName "EmailSystem" -NotePropertyValue @{
            Path = "send-email.ps1"
            Enabled = $true
            Description = "Email notification system"
            Schedule = "as needed"
        } -Force
        
        $config | ConvertTo-Json -Depth 4 | Out-File $automationConfig -Encoding UTF8
        Write-Host "Automation configuration updated" -ForegroundColor Green
        
    } catch {
        Write-Host "WARNING: Could not update automation configuration" -ForegroundColor Yellow
    }
}

# Summary
Write-Host "`n=== Email System Setup Complete ===" -ForegroundColor Green

Write-Host "`nCreated files:" -ForegroundColor Cyan
Write-Host "  Configuration: $configFile" -ForegroundColor Gray
Write-Host "  Test script: test-email-system.ps1" -ForegroundColor Gray
Write-Host "  Email script: send-email.ps1" -ForegroundColor Gray
Write-Host "  Batch test: run-email-test.bat" -ForegroundColor Gray

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Set environment variables (see above)" -ForegroundColor Gray
Write-Host "2. Test the system: .\test-email-system.ps1" -ForegroundColor Gray
Write-Host "3. Send test email: .\run-email-test.bat" -ForegroundColor Gray
Write-Host "4. Configure email provider app password (if using Gmail)" -ForegroundColor Gray

Write-Host "`nEmail system is now integrated with:" -ForegroundColor Cyan
Write-Host "  鈥?Backup system (backup-english.ps1)" -ForegroundColor Gray
Write-Host "  鈥?Security check (security-check-english.ps1)" -ForegroundColor Gray
Write-Host "  鈥?Automation configuration" -ForegroundColor Gray

Write-Host "`nSetup completed successfully!" -ForegroundColor Green
Write-Host "Press Enter to exit..." -ForegroundColor Gray
Read-Host
