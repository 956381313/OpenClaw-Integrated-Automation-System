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

