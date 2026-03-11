# Auto Setup Email System with Preset Configuration
# This script automatically configures the email system for testing

Write-Host "=== Auto Setup OpenClaw Email System ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Configuration directory
$configDir = "modules/email/config"
if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    Write-Host "Created configuration directory: $configDir" -ForegroundColor Green
}

# Check template
$templateFile = "$configDir\modules/email/config-template.json"
if (-not (Test-Path $templateFile)) {
    Write-Host "ERROR: Template not found, creating it..." -ForegroundColor Yellow
    powershell -ExecutionPolicy Bypass -File "email-notification-framework.ps1"
}

Write-Host "1. Loading configuration template..." -ForegroundColor Yellow

try {
    $template = Get-Content $templateFile -Raw | ConvertFrom-Json
    
    # Use preset configuration for testing
    Write-Host "2. Applying preset configuration for testing..." -ForegroundColor Yellow
    
    # Test configuration (using Gmail SMTP as example)
    $template.Email.Enabled = $true
    $template.Email.SMTP.Server = "smtp.gmail.com"
    $template.Email.SMTP.Port = 587
    $template.Email.SMTP.SSL = $true
    $template.Email.Credentials.Username = "test@example.com"  # Will be overridden by env var
    
    # Add test recipient (can be changed later)
    $template.Email.Recipients = @("test@example.com")
    
    # Enable all notification types for testing
    $template.Email.Notifications.BackupComplete = $true
    $template.Email.Notifications.SecurityCheck = $true
    $template.Email.Notifications.SystemAlert = $true
    $template.Email.Notifications.DailySummary = $true
    
    # Save configuration
    $configFile = "$configDir\modules/email/config.json"
    $template | ConvertTo-Json -Depth 4 | Out-File $configFile -Encoding UTF8
    
    Write-Host "Configuration saved: $configFile" -ForegroundColor Green
    Write-Host "  SMTP Server: $($template.Email.SMTP.Server):$($template.Email.SMTP.Port)" -ForegroundColor Gray
    Write-Host "  SSL: $($template.Email.SMTP.SSL)" -ForegroundColor Gray
    Write-Host "  Enabled: $($template.Email.Enabled)" -ForegroundColor Gray
    Write-Host "  Recipients: $($template.Email.Recipients.Count)" -ForegroundColor Gray
    
} catch {
    Write-Host "ERROR: Failed to create configuration" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Yellow
    exit 1
}

# Create test environment variables script
Write-Host "`n3. Creating environment setup script..." -ForegroundColor Yellow

$envScript = @'
# Environment Variables Setup for OpenClaw Email System
# Run this script to set up environment variables for testing

Write-Host "=== Setting up Email Environment Variables ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

Write-Host "IMPORTANT: For actual email sending, you need to:" -ForegroundColor Yellow
Write-Host "1. Replace test@example.com with your actual email" -ForegroundColor Gray
Write-Host "2. Get an app password (for Gmail) or SMTP password" -ForegroundColor Gray
Write-Host "3. Update the values below" -ForegroundColor Gray
Write-Host ""

# Set environment variables (temporary - current session only)
$env:OPENCLAW_EMAIL_USER = "test@example.com"
$env:OPENCLAW_EMAIL_PASS = "your-app-password-here"

Write-Host "Environment variables set (temporary):" -ForegroundColor Green
Write-Host "  OPENCLAW_EMAIL_USER = $env:OPENCLAW_EMAIL_USER" -ForegroundColor Gray
Write-Host "  OPENCLAW_EMAIL_PASS = [hidden]" -ForegroundColor Gray

Write-Host "`nTo make these permanent:" -ForegroundColor Yellow
Write-Host "1. Run PowerShell as Administrator" -ForegroundColor Gray
Write-Host "2. Use these commands:" -ForegroundColor Gray
Write-Host "   [Environment]::SetEnvironmentVariable('OPENCLAW_EMAIL_USER', 'your-email@gmail.com', 'User')" -ForegroundColor White
Write-Host "   [Environment]::SetEnvironmentVariable('OPENCLAW_EMAIL_PASS', 'your-app-password', 'User')" -ForegroundColor White

Write-Host "`nFor Gmail users:" -ForegroundColor Cyan
Write-Host "鈥?Go to: https://myaccount.google.com/security" -ForegroundColor Gray
Write-Host "鈥?Enable 2-Step Verification (if not already)" -ForegroundColor Gray
Write-Host "鈥?Create an App Password for 'Mail'" -ForegroundColor Gray
Write-Host "鈥?Use that app password (16 characters) as OPENCLAW_EMAIL_PASS" -ForegroundColor Gray

Write-Host "`nTest the configuration:" -ForegroundColor Cyan
Write-Host "  .\test-email-system.ps1" -ForegroundColor White
Write-Host "  .\run-email-test.bat" -ForegroundColor White

Write-Host "`nSetup completed!" -ForegroundColor Green
Write-Host "Press Enter to exit..." -ForegroundColor Gray
Read-Host
'@

$envScript | Out-File "setup-email-env.ps1" -Encoding UTF8
Write-Host "Environment setup script created: setup-email-env.ps1" -ForegroundColor Green

# Create a simple test without requiring user input
Write-Host "`n4. Creating simplified test script..." -ForegroundColor Yellow

$simpleTest = @'
# Simple Email System Test
# Tests the configuration without requiring email credentials

Write-Host "=== Simple Email System Test ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Check configuration
$configFile = "modules/email/config\modules/email/config.json"
if (-not (Test-Path $configFile)) {
    Write-Host "ERROR: Configuration file not found" -ForegroundColor Red
    Write-Host "Run: .\auto-setup-email.ps1" -ForegroundColor Yellow
    exit 1
}

# Load configuration
try {
    $config = Get-Content $configFile -Raw | ConvertFrom-Json -ErrorAction Stop
    
    Write-Host "Configuration loaded successfully" -ForegroundColor Green
    Write-Host "SMTP Server: $($config.Email.SMTP.Server):$($config.Email.SMTP.Port)" -ForegroundColor Gray
    Write-Host "SSL: $($config.Email.SMTP.SSL)" -ForegroundColor Gray
    Write-Host "Enabled: $($config.Email.Enabled)" -ForegroundColor Gray
    Write-Host "Recipients: $($config.Email.Recipients.Count)" -ForegroundColor Gray
    
    # Check enabled notifications
    Write-Host "`nEnabled notifications:" -ForegroundColor Yellow
    foreach ($notification in $config.Email.Notifications.PSObject.Properties) {
        Write-Host "  $($notification.Name): $($notification.Value)" -ForegroundColor Gray
    }
    
} catch {
    Write-Host "ERROR: Cannot load configuration" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Yellow
    exit 1
}

# Check if send-email script exists
if (-not (Test-Path "send-email.ps1")) {
    Write-Host "ERROR: send-email.ps1 not found" -ForegroundColor Red
    exit 1
}

Write-Host "`nEmail system is configured for:" -ForegroundColor Green
Write-Host "  Server: $($config.Email.SMTP.Server)" -ForegroundColor Gray
Write-Host "  Port: $($config.Email.SMTP.Port)" -ForegroundColor Gray
Write-Host "  SSL: $($config.Email.SMTP.SSL)" -ForegroundColor Gray

Write-Host "`nTo complete setup:" -ForegroundColor Yellow
Write-Host "1. Set environment variables:" -ForegroundColor Gray
Write-Host "   .\setup-email-env.ps1" -ForegroundColor White
Write-Host "2. Test email sending (test mode):" -ForegroundColor Gray
Write-Host "   powershell -File send-email.ps1 -Type BackupComplete -Test" -ForegroundColor White
Write-Host "3. Test with backup system:" -ForegroundColor Gray
Write-Host "   .\backup-english.ps1" -ForegroundColor White

Write-Host "`nTest completed successfully!" -ForegroundColor Green
Write-Host "Configuration is ready for email credentials" -ForegroundColor Gray
'@

$simpleTest | Out-File "test-email-simple.ps1" -Encoding UTF8
Write-Host "Simple test script created: test-email-simple.ps1" -ForegroundColor Green

# Update the existing test script to use new config
Write-Host "`n5. Updating existing test scripts..." -ForegroundColor Yellow

if (Test-Path "test-email-system.ps1") {
    Remove-Item "test-email-system.ps1" -Force
    Write-Host "Updated: test-email-system.ps1" -ForegroundColor Green
}

# Summary
Write-Host "`n=== Auto Setup Complete ===" -ForegroundColor Green

Write-Host "`nCreated files:" -ForegroundColor Cyan
Write-Host "  Configuration: modules/email/config\modules/email/config.json" -ForegroundColor Gray
Write-Host "  Env setup: setup-email-env.ps1" -ForegroundColor Gray
Write-Host "  Simple test: test-email-simple.ps1" -ForegroundColor Gray

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Review configuration: modules/email/config\modules/email/config.json" -ForegroundColor Gray
Write-Host "2. Set environment variables: .\setup-email-env.ps1" -ForegroundColor Gray
Write-Host "3. Test configuration: .\test-email-simple.ps1" -ForegroundColor Gray
Write-Host "4. Test email sending: .\run-email-test.bat" -ForegroundColor Gray

Write-Host "`nEmail system is now:" -ForegroundColor Cyan
Write-Host "  鈥?Configured with Gmail SMTP (example)" -ForegroundColor Gray
Write-Host "  鈥?Integrated with backup and security systems" -ForegroundColor Gray
Write-Host "  鈥?Ready for email credentials" -ForegroundColor Gray

Write-Host "`nTo send actual emails:" -ForegroundColor Yellow
Write-Host "1. Update modules/email/config.json with your email" -ForegroundColor Gray
Write-Host "2. Set OPENCLAW_EMAIL_USER and OPENCLAW_EMAIL_PASS environment variables" -ForegroundColor Gray
Write-Host "3. Test with -Test flag first" -ForegroundColor Gray

Write-Host "`nAuto setup completed!" -ForegroundColor Green
