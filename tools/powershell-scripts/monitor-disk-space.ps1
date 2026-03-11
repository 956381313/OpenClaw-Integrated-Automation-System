# Simple Disk Monitor
param([switch]$Quick)

Write-Host "=== Disk Space Check ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray

try {
    $disks = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3"
    
    foreach ($disk in $disks) {
        $usedPercent = [math]::Round((($disk.Size - $disk.FreeSpace)/$disk.Size)*100, 2)
        $freeGB = [math]::Round($disk.FreeSpace/1GB, 2)
        $totalGB = [math]::Round($disk.Size/1GB, 2)
        
        if ($usedPercent -gt 90) {
            Write-Host "$($disk.DeviceID): $usedPercent% used ($freeGB GB free of $totalGB GB) [CRITICAL]" -ForegroundColor Red
        } elseif ($usedPercent -gt 80) {
            Write-Host "$($disk.DeviceID): $usedPercent% used ($freeGB GB free of $totalGB GB) [WARNING]" -ForegroundColor Yellow
        } else {
            Write-Host "$($disk.DeviceID): $usedPercent% used ($freeGB GB free of $totalGB GB) [OK]" -ForegroundColor Green
        }
    }
    
    Write-Host ""
    Write-Host "Recommendations:" -ForegroundColor Yellow
    Write-Host "1. Clean temporary files" -ForegroundColor Gray
    Write-Host "2. Run duplicate file cleanup" -ForegroundColor Gray
    Write-Host "3. Archive old backups" -ForegroundColor Gray
    
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
}
