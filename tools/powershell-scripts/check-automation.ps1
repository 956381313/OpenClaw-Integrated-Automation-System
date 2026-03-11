# OpenClaw Automation Monitor
Write-Host "=== OpenClaw Automation Status ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

Write-Host "Available scripts:" -ForegroundColor Yellow
Write-Host "1. Backup: run-backup.bat" -ForegroundColor Gray
Write-Host "2. Security Check: run-security.bat" -ForegroundColor Gray
Write-Host "3. Repository Organization & Cleanup: run-organize-cleanup.bat" -ForegroundColor Gray
Write-Host "4. Knowledge Base: run-knowledge.bat" -ForegroundColor Gray
Write-Host "5. Monitor: monitor-automation-english.ps1" -ForegroundColor Gray
Write-Host ""

Write-Host "Configuration:" -ForegroundColor Yellow
if (Test-Path "automation-config-english.json") {
    $config = Get-Content "automation-config-english.json" | ConvertFrom-Json
    Write-Host "  System: $($config.System.Name)" -ForegroundColor Gray
    Write-Host "  Version: $($config.System.Version)" -ForegroundColor Gray
    Write-Host "  Scripts: $($config.Scripts.Keys.Count)" -ForegroundColor Gray
} else {
    Write-Host "  Configuration file not found" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Quick commands:" -ForegroundColor Cyan
Write-Host "  .\run-backup.bat" -ForegroundColor Gray
Write-Host "  .\run-security.bat" -ForegroundColor Gray
Write-Host "  .\run-organize-cleanup.bat" -ForegroundColor Gray
Write-Host "  .\run-knowledge.bat" -ForegroundColor Gray
Write-Host "  .\monitor-automation-english.ps1" -ForegroundColor Gray

Write-Host ""
Write-Host "Press Enter to exit..." -ForegroundColor Gray
Read-Host
