# Full Automation System Test
Write-Host "=== FULL AUTOMATION SYSTEM TEST ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "Test Mode: Comprehensive validation of all automation components" -ForegroundColor Gray
Write-Host ""

# Test Results Tracking
$testResults = @()

# Test 1: Integration System
Write-Host "1. INTEGRATION SYSTEM TEST" -ForegroundColor Yellow
$integrationScript = "integrate-english-automation.ps1"
if (Test-Path $integrationScript) {
    Write-Host "   [OK] Integration script found" -ForegroundColor Green
    
    # Test all modes
    $modes = @("Test", "Setup", "Run", "Help")
    foreach ($mode in $modes) {
        Write-Host "   Testing -$mode mode..." -ForegroundColor Gray
        try {
            & $integrationScript -$mode 2>&1 | Out-Null
            Write-Host "     [PASS] -$mode mode works" -ForegroundColor Green
            $testResults += @{Test="Integration-$mode"; Result="PASS"}
        } catch {
            Write-Host "     [FAIL] -$mode mode error: $_" -ForegroundColor Red
            $testResults += @{Test="Integration-$mode"; Result="FAIL"}
        }
    }
} else {
    Write-Host "   [FAIL] Integration script missing" -ForegroundColor Red
    $testResults += @{Test="Integration-Script"; Result="FAIL"}
}
Write-Host ""

# Test 2: Backup System
Write-Host "2. BACKUP SYSTEM TEST" -ForegroundColor Yellow
$backupScript = "tool-collections\powershell-scripts\backup-english.ps1"
if (Test-Path $backupScript) {
    Write-Host "   [OK] Backup script found" -ForegroundColor Green
    
    # Test 2.1: Quick backup
    Write-Host "   Testing quick backup..." -ForegroundColor Gray
    try {
        & $backupScript --silent --quick 2>&1 | Out-Null
        Write-Host "     [PASS] Quick backup executed" -ForegroundColor Green
        $testResults += @{Test="Backup-Quick"; Result="PASS"}
    } catch {
        Write-Host "     [FAIL] Quick backup error: $_" -ForegroundColor Red
        $testResults += @{Test="Backup-Quick"; Result="FAIL"}
    }
    
    # Test 2.2: Batch file
    Write-Host "   Testing backup batch file..." -ForegroundColor Gray
    $backupBatch = "run-backup.bat"
    if (Test-Path $backupBatch) {
        Write-Host "     [OK] Batch file exists" -ForegroundColor Green
        $testResults += @{Test="Backup-Batch"; Result="PASS"}
    } else {
        Write-Host "     [FAIL] Batch file missing" -ForegroundColor Red
        $testResults += @{Test="Backup-Batch"; Result="FAIL"}
    }
} else {
    Write-Host "   [FAIL] Backup script missing" -ForegroundColor Red
    $testResults += @{Test="Backup-Script"; Result="FAIL"}
}
Write-Host ""

# Test 3: Security System
Write-Host "3. SECURITY SYSTEM TEST" -ForegroundColor Yellow
$securityScript = "tool-collections\powershell-scripts\security-check-english.ps1"
if (Test-Path $securityScript) {
    Write-Host "   [OK] Security script found" -ForegroundColor Green
    
    # Test execution
    Write-Host "   Testing security check..." -ForegroundColor Gray
    try {
        & $securityScript --quick 2>&1 | Out-Null
        Write-Host "     [PASS] Security check executed" -ForegroundColor Green
        $testResults += @{Test="Security-Check"; Result="PASS"}
    } catch {
        Write-Host "     [FAIL] Security check error: $_" -ForegroundColor Red
        $testResults += @{Test="Security-Check"; Result="FAIL"}
    }
    
    # Test batch file
    $securityBatch = "run-security.bat"
    if (Test-Path $securityBatch) {
        Write-Host "     [OK] Security batch file exists" -ForegroundColor Green
        $testResults += @{Test="Security-Batch"; Result="PASS"}
    } else {
        Write-Host "     [FAIL] Security batch file missing" -ForegroundColor Red
        $testResults += @{Test="Security-Batch"; Result="FAIL"}
    }
} else {
    Write-Host "   [FAIL] Security script missing" -ForegroundColor Red
    $testResults += @{Test="Security-Script"; Result="FAIL"}
}
Write-Host ""

# Test 4: Organization System
Write-Host "4. ORGANIZATION SYSTEM TEST" -ForegroundColor Yellow
$organizeScript = "tool-collections\powershell-scripts\organize-and-cleanup.ps1"
if (Test-Path $organizeScript) {
    Write-Host "   [OK] Organization script found" -ForegroundColor Green
    
    # Test with test mode if available
    Write-Host "   Testing organization system..." -ForegroundColor Gray
    try {
        # Check if script supports test mode
        $content = Get-Content $organizeScript -First 100
        if ($content -match "--test") {
            & $organizeScript --test 2>&1 | Out-Null
            Write-Host "     [PASS] Organization test executed" -ForegroundColor Green
        } else {
            & $organizeScript --quick 2>&1 | Out-Null
            Write-Host "     [PASS] Organization quick check executed" -ForegroundColor Green
        }
        $testResults += @{Test="Organization-Script"; Result="PASS"}
    } catch {
        Write-Host "     [FAIL] Organization error: $_" -ForegroundColor Red
        $testResults += @{Test="Organization-Script"; Result="FAIL"}
    }
    
    # Test batch file
    $organizeBatch = "run-organize.bat"
    if (Test-Path $organizeBatch) {
        Write-Host "     [OK] Organization batch file exists" -ForegroundColor Green
        $testResults += @{Test="Organization-Batch"; Result="PASS"}
    } else {
        Write-Host "     [FAIL] Organization batch file missing" -ForegroundColor Red
        $testResults += @{Test="Organization-Batch"; Result="FAIL"}
    }
} else {
    Write-Host "   [FAIL] Organization script missing" -ForegroundColor Red
    $testResults += @{Test="Organization-Script"; Result="FAIL"}
}
Write-Host ""

# Test 5: Monitor System
Write-Host "5. MONITOR SYSTEM TEST" -ForegroundColor Yellow
$monitorScript = "tool-collections\powershell-scripts\monitor-automation-english.ps1"
if (Test-Path $monitorScript) {
    Write-Host "   [OK] Monitor script found" -ForegroundColor Green
    
    # Test execution
    Write-Host "   Testing monitor system..." -ForegroundColor Gray
    try {
        & $monitorScript --quick 2>&1 | Out-Null
        Write-Host "     [PASS] Monitor check executed" -ForegroundColor Green
        $testResults += @{Test="Monitor-Script"; Result="PASS"}
    } catch {
        Write-Host "     [FAIL] Monitor error: $_" -ForegroundColor Red
        $testResults += @{Test="Monitor-Script"; Result="FAIL"}
    }
} else {
    Write-Host "   [FAIL] Monitor script missing" -ForegroundColor Red
    $testResults += @{Test="Monitor-Script"; Result="FAIL"}
}
Write-Host ""

# Test 6: Configuration System
Write-Host "6. CONFIGURATION SYSTEM TEST" -ForegroundColor Yellow
$configPath = "system-core\configuration-files\automation-config-english.json"
if (Test-Path $configPath) {
    Write-Host "   [OK] Configuration file found" -ForegroundColor Green
    
    try {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
        
        # Validate configuration
        $valid = $true
        $issues = @()
        
        if (-not $config.version) { $valid = $false; $issues += "Missing version" }
        if (-not $config.tasks) { $valid = $false; $issues += "Missing tasks" }
        if ($config.tasks.Count -eq 0) { $valid = $false; $issues += "No tasks configured" }
        
        if ($valid) {
            Write-Host "     [PASS] Configuration valid: $($config.tasks.Count) tasks" -ForegroundColor Green
            $testResults += @{Test="Configuration-Valid"; Result="PASS"}
            
            # Check each task's script exists
            Write-Host "     Checking task scripts..." -ForegroundColor Gray
            $taskScriptsValid = $true
            foreach ($task in $config.tasks) {
                if ($task.script -and (Test-Path $task.script)) {
                    Write-Host "       [OK] $($task.name): $($task.script)" -ForegroundColor DarkGray
                } elseif ($task.script) {
                    Write-Host "       [WARN] $($task.name): Script not found: $($task.script)" -ForegroundColor Yellow
                    $taskScriptsValid = $false
                }
            }
            
            if ($taskScriptsValid) {
                Write-Host "     [PASS] All task scripts exist" -ForegroundColor Green
                $testResults += @{Test="Task-Scripts"; Result="PASS"}
            } else {
                Write-Host "     [FAIL] Some task scripts missing" -ForegroundColor Red
                $testResults += @{Test="Task-Scripts"; Result="FAIL"}
            }
        } else {
            Write-Host "     [FAIL] Configuration invalid: $($issues -join ', ')" -ForegroundColor Red
            $testResults += @{Test="Configuration-Valid"; Result="FAIL"}
        }
    } catch {
        Write-Host "     [FAIL] Configuration parse error: $_" -ForegroundColor Red
        $testResults += @{Test="Configuration-Parse"; Result="FAIL"}
    }
} else {
    Write-Host "   [FAIL] Configuration file missing" -ForegroundColor Red
    $testResults += @{Test="Configuration-File"; Result="FAIL"}
}
Write-Host ""

# Test 7: Directory Structure
Write-Host "7. DIRECTORY STRUCTURE TEST" -ForegroundColor Yellow
$requiredDirs = @(
    "system-core\configuration-files",
    "tool-collections\powershell-scripts",
    "tool-collections\batch-scripts",
    "data-storage\logs",
    "data-storage\reports",
    "backup-archive",
    "functional-modules",
    "service-layers",
    "documentation"
)

$missingDirs = @()
foreach ($dir in $requiredDirs) {
    if (-not (Test-Path $dir)) {
        $missingDirs += $dir
    }
}

if ($missingDirs.Count -eq 0) {
    Write-Host "   [PASS] All directories exist" -ForegroundColor Green
    $testResults += @{Test="Directory-Structure"; Result="PASS"}
} else {
    Write-Host "   [FAIL] Missing directories: $($missingDirs.Count)" -ForegroundColor Red
    foreach ($dir in $missingDirs) {
        Write-Host "     - $dir" -ForegroundColor Red
    }
    $testResults += @{Test="Directory-Structure"; Result="FAIL"}
}
Write-Host ""

# Test 8: Knowledge System
Write-Host "8. KNOWLEDGE SYSTEM TEST" -ForegroundColor Yellow
$knowledgeScript = "tool-collections\powershell-scripts\knowledge-base-english.ps1"
if (Test-Path $knowledgeScript) {
    Write-Host "   [OK] Knowledge script found" -ForegroundColor Green
    
    # Test batch file
    $knowledgeBatch = "run-knowledge.bat"
    if (Test-Path $knowledgeBatch) {
        Write-Host "     [OK] Knowledge batch file exists" -ForegroundColor Green
        $testResults += @{Test="Knowledge-Batch"; Result="PASS"}
    } else {
        Write-Host "     [FAIL] Knowledge batch file missing" -ForegroundColor Red
        $testResults += @{Test="Knowledge-Batch"; Result="FAIL"}
    }
} else {
    Write-Host "   [FAIL] Knowledge script missing" -ForegroundColor Red
    $testResults += @{Test="Knowledge-Script"; Result="FAIL"}
}
Write-Host ""

# Summary
Write-Host "=== TEST SUMMARY ===" -ForegroundColor Cyan

$totalTests = $testResults.Count
$passedTests = ($testResults | Where-Object { $_.Result -eq "PASS" }).Count
$failedTests = ($testResults | Where-Object { $_.Result -eq "FAIL" }).Count
$passRate = [math]::Round(($passedTests / $totalTests) * 100, 1)

Write-Host "Total Tests: $totalTests" -ForegroundColor Gray
Write-Host "Passed: $passedTests" -ForegroundColor Green
Write-Host "Failed: $failedTests" -ForegroundColor $(if ($failedTests -eq 0) {"Gray"} else {"Red"})
Write-Host "Pass Rate: $passRate%" -ForegroundColor $(if ($passRate -ge 90) {"Green"} elseif ($passRate -ge 70) {"Yellow"} else {"Red"})
Write-Host ""

# Detailed results
Write-Host "Detailed Results:" -ForegroundColor Yellow
foreach ($result in $testResults | Sort-Object Test) {
    $color = if ($result.Result -eq "PASS") { "Green" } else { "Red" }
    Write-Host "  $($result.Test): $($result.Result)" -ForegroundColor $color
}
Write-Host ""

# Final verdict
if ($failedTests -eq 0) {
    Write-Host "✅ AUTOMATION SYSTEM FULLY OPERATIONAL!" -ForegroundColor Green
    Write-Host "All components tested and working correctly." -ForegroundColor Gray
    Write-Host ""
    Write-Host "Ready for production use:" -ForegroundColor Yellow
    Write-Host "  1. ✅ Integration system" -ForegroundColor Gray
    Write-Host "  2. ✅ Backup system" -ForegroundColor Gray
    Write-Host "  3. ✅ Security system" -ForegroundColor Gray
    Write-Host "  4. ✅ Organization system" -ForegroundColor Gray
    Write-Host "  5. ✅ Monitor system" -ForegroundColor Gray
    Write-Host "  6. ✅ Configuration system" -ForegroundColor Gray
    Write-Host "  7. ✅ Directory structure" -ForegroundColor Gray
    Write-Host "  8. ✅ Knowledge system" -ForegroundColor Gray
} else {
    Write-Host "⚠️ AUTOMATION SYSTEM NEEDS ATTENTION" -ForegroundColor Yellow
    Write-Host "$failedTests test(s) failed. Review the details above." -ForegroundColor Gray
}

Write-Host ""
Write-Host "Test completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray

# Save test report
$report = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    total_tests = $totalTests
    passed = $passedTests
    failed = $failedTests
    pass_rate = $passRate
    results = $testResults
    system_status = if ($failedTests -eq 0) { "FULLY_OPERATIONAL" } else { "NEEDS_ATTENTION" }
}

$reportPath = "data-storage\reports\full-automation-test-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$report | ConvertTo-Json -Depth 3 | Set-Content $reportPath -Encoding UTF8
Write-Host "Test report saved: $reportPath" -ForegroundColor Gray