# Disk Space Check Tool - PowerShell Version

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Disk Status Check Tool" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get disk information
$disk = Get-PSDrive C
if ($disk) {
    $freeGB = [math]::Round($disk.Free / 1GB, 2)
    $totalGB = [math]::Round(($disk.Used + $disk.Free) / 1GB, 2)
    $usedGB = [math]::Round($disk.Used / 1GB, 2)
    $usagePercent = [math]::Round(($disk.Used / ($disk.Used + $disk.Free)) * 100, 2)
    
    Write-Host "Disk C: Information:" -ForegroundColor Yellow
    Write-Host "  Total Capacity: ${totalGB} GB" -ForegroundColor Gray
    Write-Host "  Used: ${usedGB} GB" -ForegroundColor Gray
    Write-Host "  Free Space: ${freeGB} GB" -ForegroundColor Gray
    Write-Host "  Usage: ${usagePercent}%" -ForegroundColor Gray
    Write-Host ""
    
    if ($usagePercent -gt 85) {
        Write-Host "⚠️ Warning: Disk usage exceeds 85%!" -ForegroundColor Red
        Write-Host "  Recommended to clean temporary files" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Run cleanup commands:" -ForegroundColor Yellow
        Write-Host "  Remove-Item -Path `"C:\Users\luchaochao\.openclaw\workspace\*.tmp`" -Force -ErrorAction SilentlyContinue" -ForegroundColor Gray
        Write-Host "  Remove-Item -Path `"C:\Users\luchaochao\.openclaw\workspace\*.temp`" -Force -ErrorAction SilentlyContinue" -ForegroundColor Gray
        Write-Host "  Remove-Item -Path `"C:\Users\luchaochao\.openclaw\workspace\temp\*`" -Force -ErrorAction SilentlyContinue" -ForegroundColor Gray
    } else {
        Write-Host "✅ Status OK: Disk usage is within safe range" -ForegroundColor Green
    }
} else {
    Write-Host "Error: Could not get disk information for C:" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")