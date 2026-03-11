# English Architecture Automation Integration
# Integrates English workspace structure with automation system

param(
    [switch]$Setup,
    [switch]$Test,
    [switch]$Run,
    [switch]$Help
)

if ($Help) {
    Write-Host "English Architecture Automation Integration" -ForegroundColor Cyan
    Write-Host "Usage: .\integrate-english-automation.ps1 [options]" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Yellow
    Write-Host "  -Setup    Setup automation system with English architecture" -ForegroundColor Gray
    Write-Host "  -Test     Test integration without making changes" -ForegroundColor Gray
    Write-Host "  -Run      Run full integration process" -ForegroundColor Gray
    Write-Host "  -Help     Show this help message" -ForegroundColor Gray
    exit 0
}

# Configuration
$configPath = "system-core\configuration-files\automation-config-english.json"
$englishDirs = @{
    "system-core" = "Core system components"
    "functional-modules" = "Functional modules"
    "tool-collections" = "Tool scripts and utilities"
    "documentation" = "Documentation files"
    "data-storage" = "Data and logs"
    "backup-archive" = "Backup files"
}

function Test-EnglishStructure {
    Write-Host "Testing English structure..." -ForegroundColor Yellow
    $missing = @()
    
    foreach ($dir in $englishDirs.Keys) {
        if (Test-Path $dir) {
            Write-Host "  [OK] $dir - $($englishDirs[$dir])" -ForegroundColor Green
        } else {
            Write-Host "  [MISSING] $dir" -ForegroundColor Red
            $missing += $dir
        }
    }
    
    if ($missing.Count -eq 0) {
        Write-Host "English structure: COMPLETE" -ForegroundColor Green
        return $true
    } else {
        Write-Host "English structure: INCOMPLETE ($($missing.Count) missing)" -ForegroundColor Red
        return $false
    }
}

function Test-AutomationConfig {
    Write-Host "Testing automation configuration..." -ForegroundColor Yellow
    
    if (Test-Path $configPath) {
        try {
            $config = Get-Content $configPath -Raw | ConvertFrom-Json
            Write-Host "  [OK] Configuration loaded: $($config.tasks.Count) tasks" -ForegroundColor Green
            return $true
        } catch {
            Write-Host "  [ERROR] Invalid configuration: $_" -ForegroundColor Red
            return $false
        }
    } else {
        Write-Host "  [MISSING] Configuration file not found" -ForegroundColor Red
        return $false
    }
}

function Setup-Automation {
    Write-Host "Setting up automation system..." -ForegroundColor Cyan
    
    # Create required directories
    $dirs = @(
        "data-storage\logs",
        "data-storage\reports",
        "backup-archive\automated",
        "temporary-files\processing"
    )
    
    foreach ($dir in $dirs) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Host "  Created: $dir" -ForegroundColor Gray
        }
    }
    
    Write-Host "Automation setup completed" -ForegroundColor Green
}

function Run-Integration {
    Write-Host "Running full integration..." -ForegroundColor Cyan
    
    # Step 1: Verify structure
    if (-not (Test-EnglishStructure)) {
        Write-Host "Integration failed: English structure incomplete" -ForegroundColor Red
        return $false
    }
    
    # Step 2: Verify configuration
    if (-not (Test-AutomationConfig)) {
        Write-Host "Integration failed: Automation configuration invalid" -ForegroundColor Red
        return $false
    }
    
    # Step 3: Setup directories
    Setup-Automation
    
    # Step 4: Create integration report
    $report = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        status = "success"
        english_structure = $englishDirs.Keys | ForEach-Object { @{ directory = $_; exists = (Test-Path $_) } }
        config_path = $configPath
        config_exists = Test-Path $configPath
    }
    
    $reportPath = "data-storage\reports\integration-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $report | ConvertTo-Json -Depth 3 | Set-Content $reportPath -Encoding UTF8
    
    Write-Host "Integration completed successfully!" -ForegroundColor Green
    Write-Host "Report saved: $reportPath" -ForegroundColor Gray
    return $true
}

# Main execution
if ($Test) {
    Write-Host "=== TEST MODE ===" -ForegroundColor Cyan
    Test-EnglishStructure
    Test-AutomationConfig
    Write-Host "Test completed (no changes made)" -ForegroundColor Green
} elseif ($Setup) {
    Write-Host "=== SETUP MODE ===" -ForegroundColor Cyan
    Setup-Automation
} elseif ($Run) {
    Write-Host "=== RUN MODE ===" -ForegroundColor Cyan
    Run-Integration
} else {
    Write-Host "No mode specified. Use -Help for usage information." -ForegroundColor Yellow
}
