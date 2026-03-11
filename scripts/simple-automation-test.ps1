# Simple Automation Test - Works with current structure
Write-Host "=== SIMPLE AUTOMATION TEST ===" -ForegroundColor Cyan
Write-Host "Testing from: $(Get-Location)" -ForegroundColor Gray
Write-Host ""

# Test 1: Can we run backup?
Write-Host "1. Testing Backup System" -ForegroundColor Yellow
$backupScript = "tool-collections\powershell-scripts\backup-english.ps1"
if (Test-Path $backupScript) {
    Write-Host "   [OK] Backup script found" -ForegroundColor Green
    try {
        # Run with minimal output
        & $backupScript --silent --quick 2>&1 | Out-Null
        Write-Host "   [SUCCESS] Backup executed" -ForegroundColor Green
    } catch {
        Write-Host "   [ERROR] Backup failed: $_" -ForegroundColor Red
    }
} else {
    Write-Host "   [ERROR] Backup script not found" -ForegroundColor Red
}
Write-Host ""

# Test 2: Check configuration
Write-Host "2. Testing Configuration" -ForegroundColor Yellow
$configPath = "system-core\configuration-files\automation-config-english.json"
if (Test-Path $configPath) {
    try {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
        Write-Host "   [OK] Configuration loaded: $($config.tasks.Count) tasks" -ForegroundColor Green
    } catch {
        Write-Host "   [ERROR] Configuration invalid" -ForegroundColor Red
    }
} else {
    Write-Host "   [ERROR] Configuration not found" -ForegroundColor Red
}
Write-Host ""

# Test 3: Check integration script
Write-Host "3. Testing Integration" -ForegroundColor Yellow
if (Test-Path "integrate-english-automation.ps1") {
    Write-Host "   [OK] Integration script exists" -ForegroundColor Green
} else {
    Write-Host "   [ERROR] Integration script missing" -ForegroundColor Red
}
Write-Host ""

Write-Host "=== TEST COMPLETE ===" -ForegroundColor Cyan
Write-Host "Check the results above. If all [OK], system is ready." -ForegroundColor Gray
