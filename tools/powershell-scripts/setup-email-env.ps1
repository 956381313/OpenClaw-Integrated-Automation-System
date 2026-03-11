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
