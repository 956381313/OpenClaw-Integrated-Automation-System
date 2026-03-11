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

