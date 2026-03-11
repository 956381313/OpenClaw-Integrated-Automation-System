# Simple Memory Check Script

Write-Host "=== System Memory Check ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Get memory info
try {
    $os = Get-WmiObject Win32_OperatingSystem
    $totalMB = [math]::Round($os.TotalVisibleMemorySize / 1024, 2)
    $freeMB = [math]::Round($os.FreePhysicalMemory / 1024, 2)
    $usedMB = $totalMB - $freeMB
    $usagePercent = [math]::Round(($usedMB / $totalMB) * 100, 2)
    
    Write-Host "Memory Usage:" -ForegroundColor Yellow
    Write-Host "  Total: ${totalMB}MB" -ForegroundColor Gray
    Write-Host "  Used: ${usedMB}MB" -ForegroundColor Gray
    Write-Host "  Free: ${freeMB}MB" -ForegroundColor Gray
    Write-Host "  Usage: ${usagePercent}%" -ForegroundColor $(if ($usagePercent -gt 90) { "Red" } elseif ($usagePercent -gt 70) { "Yellow" } else { "Green" })
    
} catch {
    Write-Host "Error: Cannot get memory info" -ForegroundColor Red
    Write-Host "Details: $_" -ForegroundColor Yellow
}

# Check disk space
Write-Host "`nDisk Space:" -ForegroundColor Yellow

try {
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -gt 0 }
    foreach ($drive in $drives) {
        $totalGB = [math]::Round($drive.Used / 1GB, 2)
        $freeGB = [math]::Round($drive.Free / 1GB, 2)
        $usedPercent = [math]::Round(($totalGB - $freeGB) / $totalGB * 100, 2)
        
        $color = if ($usedPercent -gt 90) { "Red" } elseif ($usedPercent -gt 70) { "Yellow" } else { "Green" }
        
        Write-Host "  $($drive.Name): $usedPercent% used" -ForegroundColor $color
    }
} catch {
    Write-Host "  Error checking disk space" -ForegroundColor Yellow
}

# Top processes
Write-Host "`nTop Memory Processes:" -ForegroundColor Yellow

try {
    $processes = Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 3
    foreach ($process in $processes) {
        $memoryMB = [math]::Round($process.WorkingSet64 / 1MB, 2)
        Write-Host "  $($process.Name): ${memoryMB}MB" -ForegroundColor Gray
    }
} catch {
    Write-Host "  Error getting process info" -ForegroundColor Yellow
}

Write-Host "`n=== Check Complete ===" -ForegroundColor Green