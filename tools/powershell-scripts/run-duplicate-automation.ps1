# Run Duplicate Cleanup Automation
# Usage: .\run-duplicate-automation.ps1

Write-Host "=== Running Duplicate Cleanup Automation ===" -ForegroundColor Cyan
Write-Host "Time: 2026-03-06 15:11:41" -ForegroundColor Gray

# Step 1: Scan for duplicates
Write-Host "
Step 1: Scanning for duplicates..." -ForegroundColor Yellow
.\scan-duplicates-hash.ps1

# Step 2: Run optimized cleanup
Write-Host "
Step 2: Running optimized cleanup..." -ForegroundColor Yellow
.\clean-duplicates-optimized.ps1 -Strategy KeepNewest

# Step 3: Send email notification
Write-Host "
Step 3: Sending email notification..." -ForegroundColor Yellow
if (Test-Path "send-email-fixed.ps1") {
    .\send-email-fixed.ps1 -Subject "OpenClaw Duplicate Cleanup Completed" -Body "Weekly duplicate file cleanup completed. Check modules/duplicate/reports\ directory for details."
} else {
    Write-Host "Email script not found, skipping notification" -ForegroundColor Yellow
}

Write-Host "
=== Automation Complete ===" -ForegroundColor Green

