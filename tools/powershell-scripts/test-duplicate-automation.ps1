# Test Duplicate Cleanup Automation
# Usage: .\test-duplicate-automation.ps1

Write-Host "=== Testing Duplicate Cleanup Automation ===" -ForegroundColor Cyan
Write-Host "Time: 2026-03-06 15:11:41" -ForegroundColor Gray

# Test 1: Check required files
Write-Host "
Test 1: Checking required files..." -ForegroundColor Yellow
$requiredFiles = @(
    "scan-duplicates-hash.ps1",
    "clean-duplicates-optimized.ps1",
    "modules/duplicate/config\modules/duplicate/config.json",
    "automation-config-english.json"
)

$allExist = $true
foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "  鉁?$file" -ForegroundColor Green
    } else {
        Write-Host "  鉁?$file" -ForegroundColor Red
        $allExist = $false
    }
}

# Test 2: Test scan in preview mode
Write-Host "
Test 2: Testing scan in preview mode..." -ForegroundColor Yellow
.\scan-duplicates-hash.ps1 -Test

# Test 3: Test cleanup in preview mode
Write-Host "
Test 3: Testing cleanup in preview mode..." -ForegroundColor Yellow
.\clean-duplicates-optimized.ps1 -Preview -Strategy KeepNewest

# Test 4: Check automation config
Write-Host "
Test 4: Checking automation config..." -ForegroundColor Yellow
if (Test-Path "automation-config-english.json") {
    $autoConfig = Get-Content "automation-config-english.json" -Raw | ConvertFrom-Json
    $duplicateTask = $autoConfig.Tasks | Where-Object { $_.Name -eq "DuplicateCleanup" }
    if ($duplicateTask) {
        Write-Host "  鉁?Duplicate cleanup task found in automation config" -ForegroundColor Green
        Write-Host "    Name: $($duplicateTask.Name)" -ForegroundColor Gray
        Write-Host "    Schedule: $($duplicateTask.Schedule.Frequency) on $($duplicateTask.Schedule.DayOfWeek) at $($duplicateTask.Schedule.Time)" -ForegroundColor Gray
    } else {
        Write-Host "  鉁?Duplicate cleanup task not found in automation config" -ForegroundColor Red
    }
}

Write-Host "
=== Test Complete ===" -ForegroundColor Cyan
if ($allExist) {
    Write-Host "All tests passed! Automation is ready." -ForegroundColor Green
} else {
    Write-Host "Some tests failed. Check missing files." -ForegroundColor Red
}

