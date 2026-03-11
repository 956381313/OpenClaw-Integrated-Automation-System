# Test script for organize-and-cleanup.ps1
# This script tests the combined repository organization and cleanup functionality

Write-Host "=== Testing Organize and Cleanup Script ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Check if the main script exists
$scriptPath = "organize-and-cleanup.ps1"
if (-not (Test-Path $scriptPath)) {
    Write-Host "ERROR: Main script not found: $scriptPath" -ForegroundColor Red
    exit 1
}

Write-Host "1. Main script found: $scriptPath" -ForegroundColor Green

# Check if batch file exists
$batchPath = "run-organize-cleanup.bat"
if (-not (Test-Path $batchPath)) {
    Write-Host "WARNING: Batch file not found: $batchPath" -ForegroundColor Yellow
} else {
    Write-Host "2. Batch file found: $batchPath" -ForegroundColor Green
}

# Check configuration
$configPath = "automation-config-english.json"
if (Test-Path $configPath) {
    try {
        $config = Get-Content $configPath | ConvertFrom-Json
        $hasOrganizeCleanup = $config.Scripts.PSObject.Properties.Name -contains "OrganizeAndCleanup"
        
        if ($hasOrganizeCleanup) {
            Write-Host "3. Configuration updated: OrganizeAndCleanup found" -ForegroundColor Green
            Write-Host "   Path: $($config.Scripts.OrganizeAndCleanup.Path)" -ForegroundColor Gray
            Write-Host "   Schedule: $($config.Scripts.OrganizeAndCleanup.Schedule)" -ForegroundColor Gray
        } else {
            Write-Host "3. WARNING: OrganizeAndCleanup not in configuration" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "3. ERROR: Cannot read configuration: $_" -ForegroundColor Red
    }
} else {
    Write-Host "3. WARNING: Configuration file not found" -ForegroundColor Yellow
}

# Check if old scripts still exist (should be replaced)
$oldScripts = @("organize-english.ps1", "auto-cleanup-english.ps1", "run-organize.bat")
$oldScriptsFound = @()

foreach ($oldScript in $oldScripts) {
    if (Test-Path $oldScript) {
        $oldScriptsFound += $oldScript
    }
}

if ($oldScriptsFound.Count -gt 0) {
    Write-Host "4. WARNING: Old scripts still exist:" -ForegroundColor Yellow
    foreach ($oldScript in $oldScriptsFound) {
        Write-Host "   - $oldScript" -ForegroundColor Gray
    }
    Write-Host "   Consider removing these after verifying new script works" -ForegroundColor Gray
} else {
    Write-Host "4. Good: Old scripts have been replaced" -ForegroundColor Green
}

# Test script syntax
Write-Host "`n5. Testing script syntax..." -ForegroundColor Yellow
try {
    $scriptContent = Get-Content $scriptPath -Raw
    $errors = $null
    $tokens = [System.Management.Automation.PSParser]::Tokenize($scriptContent, [ref]$errors)
    
    if ($errors.Count -eq 0) {
        Write-Host "   Syntax check: PASSED" -ForegroundColor Green
        Write-Host "   Tokens: $($tokens.Count)" -ForegroundColor Gray
    } else {
        Write-Host "   Syntax check: FAILED" -ForegroundColor Red
        foreach ($error in $errors) {
            Write-Host "   Error: $($error.Message) at line $($error.Token.StartLine)" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "   Syntax check: ERROR - $_" -ForegroundColor Red
}

# Check required functions
Write-Host "`n6. Checking required functions..." -ForegroundColor Yellow
$requiredFunctions = @("Get-FileStatistics", "Clean-OldBackups", "Clean-EmptyDirectories", "Generate-KnowledgeBase")
$missingFunctions = @()

foreach ($function in $requiredFunctions) {
    if ($scriptContent -match "function $function") {
        Write-Host "   ${function}: Found" -ForegroundColor Green
    } else {
        $missingFunctions += $function
        Write-Host "   ${function}: NOT FOUND" -ForegroundColor Red
    }
}

if ($missingFunctions.Count -gt 0) {
    Write-Host "   WARNING: $($missingFunctions.Count) functions missing" -ForegroundColor Yellow
} else {
    Write-Host "   All required functions found" -ForegroundColor Green
}

# Check report directories
Write-Host "`n7. Checking report directories..." -ForegroundColor Yellow
$reportDirs = @("organize-data/reports", "organize-cleanup-logs")
foreach ($dir in $reportDirs) {
    if (Test-Path $dir) {
        Write-Host "   ${dir}: Exists" -ForegroundColor Green
        $fileCount = (Get-ChildItem $dir -File -ErrorAction SilentlyContinue).Count
        Write-Host "     Files: $fileCount" -ForegroundColor Gray
    } else {
        Write-Host "   ${dir}: Will be created by script" -ForegroundColor Gray
    }
}

# Summary
Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan

$testResults = @{
    "Main Script" = if (Test-Path $scriptPath) { "PASS" } else { "FAIL" }
    "Batch File" = if (Test-Path $batchPath) { "PASS" } else { "WARN" }
    "Configuration" = if ($hasOrganizeCleanup) { "PASS" } else { "WARN" }
    "Syntax Check" = if ($errors.Count -eq 0) { "PASS" } else { "FAIL" }
    "Functions" = if ($missingFunctions.Count -eq 0) { "PASS" } else { "FAIL" }
}

$passCount = ($testResults.Values | Where-Object { $_ -eq "PASS" }).Count
$warnCount = ($testResults.Values | Where-Object { $_ -eq "WARN" }).Count
$failCount = ($testResults.Values | Where-Object { $_ -eq "FAIL" }).Count

foreach ($test in $testResults.Keys) {
    $result = $testResults[$test]
    $color = switch ($result) {
        "PASS" { "Green" }
        "WARN" { "Yellow" }
        "FAIL" { "Red" }
        default { "Gray" }
    }
    
    Write-Host "  $test : $result" -ForegroundColor $color
}

Write-Host "`nResults: $passCount PASS, $warnCount WARN, $failCount FAIL" -ForegroundColor Cyan

if ($failCount -eq 0) {
    Write-Host "`n鉁?All tests passed! The script is ready to use." -ForegroundColor Green
    Write-Host "   You can run: .\run-organize-cleanup.bat" -ForegroundColor Gray
    
    if ($warnCount -gt 0) {
        Write-Host "`n鈿狅笍  Some warnings:" -ForegroundColor Yellow
        Write-Host "   - Check configuration updates" -ForegroundColor Gray
        Write-Host "   - Consider removing old scripts" -ForegroundColor Gray
    }
} else {
    Write-Host "`n鉂?Some tests failed. Please fix the issues before using." -ForegroundColor Red
}

Write-Host "`n=== Next Steps ===" -ForegroundColor Cyan
Write-Host "1. Run the script manually to test:" -ForegroundColor Gray
Write-Host "   .\run-organize-cleanup.bat" -ForegroundColor White
Write-Host "2. Update Windows Task Scheduler:" -ForegroundColor Gray
Write-Host "   .\update-automation.ps1 (as Administrator)" -ForegroundColor White
Write-Host "3. Remove old scripts after verification:" -ForegroundColor Gray
Write-Host "   organize-english.ps1, auto-cleanup-english.ps1, run-organize.bat" -ForegroundColor White

Write-Host "`nPress Enter to exit..." -ForegroundColor Gray
Read-Host
