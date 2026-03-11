# Execute Emergency Cleanup Now
Write-Host "=== EXECUTING EMERGENCY DISK CLEANUP NOW ===" -ForegroundColor Red
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Show critical status
Write-Host "CRITICAL STATUS - REQUIRES IMMEDIATE ACTION:" -ForegroundColor Red
Write-Host "C: 99.32% used (6.34 GB free) - SYSTEM DISK AT RISK!" -ForegroundColor Red
Write-Host "System may crash or become unstable at any moment!" -ForegroundColor Red
Write-Host ""

# Confirm execution
Write-Host "WARNING: This will delete temporary files from C:, E:, F:, G: drives" -ForegroundColor Yellow
$confirm = Read-Host "Type 'YES-EMERGENCY' to confirm and execute cleanup"

if ($confirm -ne "YES-EMERGENCY") {
    Write-Host "Cleanup cancelled. System remains at risk!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Executing emergency cleanup..." -ForegroundColor Green
Write-Host ""

# Run emergency cleanup
$emergencyScript = "tool-collections\powershell-scripts\emergency-disk-cleanup.ps1"
if (Test-Path $emergencyScript) {
    try {
        # Execute with force flag
        & $emergencyScript -Force
        
        Write-Host ""
        Write-Host "=== EMERGENCY CLEANUP EXECUTED ===" -ForegroundColor Green
        Write-Host "Check the generated report for details." -ForegroundColor Gray
        Write-Host ""
        
        # Quick check after cleanup
        Write-Host "Quick status check after cleanup:" -ForegroundColor Yellow
        try {
            $diskC = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
            if ($diskC) {
                $usedPercent = [math]::Round((($diskC.Size - $diskC.FreeSpace)/$diskC.Size)*100, 2)
                $freeGB = [math]::Round($diskC.FreeSpace/1GB, 2)
                
                Write-Host "C: drive: ${usedPercent}% used, ${freeGB} GB free" -ForegroundColor $(if ($usedPercent -lt 99) {"Green"} else {"Red"})
                
                if ($usedPercent -lt 99.32) {
                    $improvement = 99.32 - $usedPercent
                    Write-Host "Improvement: ${improvement}% reduction" -ForegroundColor Green
                }
            }
        } catch {
            Write-Host "Could not check disk status: $_" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "ERROR during cleanup execution: $_" -ForegroundColor Red
    }
} else {
    Write-Host "ERROR: Emergency cleanup script not found!" -ForegroundColor Red
}

Write-Host ""
Write-Host "Execution completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""
Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. Check the cleanup report in data-storage\reports\emergency-cleanup\" -ForegroundColor Gray
Write-Host "2. Monitor disk space with: .\monitor-disk.bat" -ForegroundColor Gray
Write-Host "3. Consider moving large files from C: to D: drive" -ForegroundColor Gray
Write-Host "4. Set up automated monitoring to prevent future crises" -ForegroundColor Gray