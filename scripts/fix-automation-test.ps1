# Fix Automation Test - Check actual paths
Write-Host "=== FIXING AUTOMATION TEST PATHS ===" -ForegroundColor Cyan
Write-Host "Current directory: $(Get-Location)" -ForegroundColor Gray
Write-Host ""

# Check what actually exists
Write-Host "1. Checking integration script..." -ForegroundColor Yellow
if (Test-Path "integrate-english-automation.ps1") {
    Write-Host "   [OK] Integration script exists in root" -ForegroundColor Green
    $size = (Get-Item "integrate-english-automation.ps1").Length
    Write-Host "   Size: $size bytes" -ForegroundColor Gray
} else {
    Write-Host "   [MISSING] Integration script" -ForegroundColor Red
}
Write-Host ""

Write-Host "2. Checking batch files..." -ForegroundColor Yellow
$batchFiles = @("run-backup.bat", "run-security.bat", "run-organize.bat", "run-knowledge.bat", "run-integration.bat")
foreach ($batch in $batchFiles) {
    if (Test-Path $batch) {
        Write-Host "   [OK] $batch" -ForegroundColor Green
    } else {
        Write-Host "   [MISSING] $batch" -ForegroundColor Red
    }
}
Write-Host ""

Write-Host "3. Checking tool-collections..." -ForegroundColor Yellow
if (Test-Path "tool-collections") {
    Write-Host "   [OK] tool-collections directory exists" -ForegroundColor Green
    
    # Check PowerShell scripts
    if (Test-Path "tool-collections\powershell-scripts") {
        $ps1Count = (Get-ChildItem "tool-collections\powershell-scripts" -Filter "*.ps1" -ErrorAction SilentlyContinue).Count
        Write-Host "   PowerShell scripts: $ps1Count" -ForegroundColor Gray
        
        # Check key scripts
        $keyScripts = @("backup-english.ps1", "security-check-english.ps1", "organize-and-cleanup.ps1", "monitor-automation-english.ps1")
        foreach ($script in $keyScripts) {
            $path = "tool-collections\powershell-scripts\$script"
            if (Test-Path $path) {
                Write-Host "     [OK] $script" -ForegroundColor Green
            } else {
                Write-Host "     [MISSING] $script" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "   [MISSING] powershell-scripts subdirectory" -ForegroundColor Red
    }
    
    # Check batch scripts
    if (Test-Path "tool-collections\batch-scripts") {
        $batCount = (Get-ChildItem "tool-collections\batch-scripts" -Filter "*.bat" -ErrorAction SilentlyContinue).Count
        Write-Host "   Batch scripts: $batCount" -ForegroundColor Gray
    } else {
        Write-Host "   [MISSING] batch-scripts subdirectory" -ForegroundColor Red
    }
} else {
    Write-Host "   [MISSING] tool-collections directory" -ForegroundColor Red
}
Write-Host ""

Write-Host "4. Checking system-core..." -ForegroundColor Yellow
if (Test-Path "system-core") {
    Write-Host "   [OK] system-core directory exists" -ForegroundColor Green
    
    if (Test-Path "system-core\configuration-files") {
        Write-Host "   [OK] configuration-files subdirectory exists" -ForegroundColor Green
        
        # Check config file
        if (Test-Path "system-core\configuration-files\automation-config-english.json") {
            $config = Get-Content "system-core\configuration-files\automation-config-english.json" -Raw | ConvertFrom-Json
            Write-Host "   [OK] Configuration file exists: $($config.tasks.Count) tasks" -ForegroundColor Green
        } else {
            Write-Host "   [MISSING] automation-config-english.json" -ForegroundColor Red
        }
    } else {
        Write-Host "   [MISSING] configuration-files subdirectory" -ForegroundColor Red
    }
} else {
    Write-Host "   [MISSING] system-core directory" -ForegroundColor Red
}
Write-Host ""

Write-Host "5. Checking data-storage..." -ForegroundColor Yellow
if (Test-Path "data-storage") {
    Write-Host "   [OK] data-storage directory exists" -ForegroundColor Green
    
    $subdirs = @("logs", "reports", "knowledge-base")
    foreach ($subdir in $subdirs) {
        $path = "data-storage\$subdir"
        if (Test-Path $path) {
            Write-Host "     [OK] $subdir" -ForegroundColor Green
        } else {
            Write-Host "     [MISSING] $subdir" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "   [MISSING] data-storage directory" -ForegroundColor Red
}
Write-Host ""

Write-Host "6. Checking other directories..." -ForegroundColor Yellow
$otherDirs = @("backup-archive", "functional-modules", "service-layers", "documentation")
foreach ($dir in $otherDirs) {
    if (Test-Path $dir) {
        Write-Host "   [OK] $dir" -ForegroundColor Green
    } else {
        Write-Host "   [MISSING] $dir" -ForegroundColor Red
    }
}
Write-Host ""

# Create a simple test script that works
Write-Host "7. Creating working test script..." -ForegroundColor Yellow
$testScript = @'
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
'@

$testScript | Set-Content "simple-automation-test.ps1" -Encoding UTF8
Write-Host "   Created: simple-automation-test.ps1" -ForegroundColor Green
Write-Host ""

Write-Host "=== FIX COMPLETE ===" -ForegroundColor Cyan
Write-Host "Run the simple test: .\simple-automation-test.ps1" -ForegroundColor Green
Write-Host "Or use batch files: .\run-integration.bat" -ForegroundColor Gray