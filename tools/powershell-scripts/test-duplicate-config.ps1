# Test Duplicate File System Configuration

Write-Host "=== Testing Duplicate File System ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Check directories
$directories = @(
    "modules/duplicate/config",
    "duplicate-scans",
    "modules/duplicate/reports", 
    "modules/duplicate/logs",
    "modules/duplicate/backup"
)

Write-Host "Checking directory structure..." -ForegroundColor Yellow
foreach ($dir in $directories) {
    if (Test-Path $dir) {
        Write-Host "  $dir: PASS" -ForegroundColor Green
    } else {
        Write-Host "  $dir: FAIL" -ForegroundColor Red
    }
}

# Check configuration files
Write-Host "`nChecking configuration files..." -ForegroundColor Yellow

$configFiles = @(
    "modules/duplicate/config\modules/duplicate/config-template.json",
    "modules/duplicate/config\SETUP-GUIDE.md"
)

foreach ($file in $configFiles) {
    if (Test-Path $file) {
        $size = (Get-Item $file).Length
        Write-Host "  $file: PASS ($size bytes)" -ForegroundColor Green
    } else {
        Write-Host "  $file: FAIL" -ForegroundColor Red
    }
}

# Test configuration loading
Write-Host "`nTesting configuration loading..." -ForegroundColor Yellow

$configFile = "modules/duplicate/config\modules/duplicate/config-template.json"
if (Test-Path $configFile) {
    try {
        $config = Get-Content $configFile -Raw | ConvertFrom-Json -ErrorAction Stop
        Write-Host "  Configuration loaded successfully" -ForegroundColor Green
        Write-Host "  Version: $($config.Version)" -ForegroundColor Gray
        Write-Host "  Scan directories: $($config.Settings.ScanDirectories.Count)" -ForegroundColor Gray
        Write-Host "  File types: $($config.Settings.FileTypes.Count)" -ForegroundColor Gray
    } catch {
        Write-Host "  ERROR: Cannot load configuration" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "  Configuration file not found" -ForegroundColor Red
}

# Summary
Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Copy configuration template:" -ForegroundColor Gray
Write-Host "   Copy-Item modules/duplicate/config\modules/duplicate/config-template.json modules/duplicate/config\modules/duplicate/config.json" -ForegroundColor White
Write-Host "2. Edit configuration:" -ForegroundColor Gray
Write-Host "   Edit modules/duplicate/config\modules/duplicate/config.json with your settings" -ForegroundColor White
Write-Host "3. Create scan script:" -ForegroundColor Gray
Write-Host "   Create scan-duplicates.ps1 script" -ForegroundColor White
Write-Host "4. Create cleanup script:" -ForegroundColor Gray
Write-Host "   Create clean-duplicates.ps1 script" -ForegroundColor White

Write-Host "`nFramework setup completed!" -ForegroundColor Green
Write-Host "Ready for script development" -ForegroundColor Gray

