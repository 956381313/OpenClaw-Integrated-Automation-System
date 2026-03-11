# Simple Delete Script - No fancy formatting
Write-Host "Simple Delete Script"
Write-Host "===================="
Write-Host ""

# Folders to delete
$folders = @(
    "C:\Users\luchaochao\.openclaw\workspace\english-reorg-backup-20260306-234623",
    "C:\Users\luchaochao\.openclaw\workspace\pre-architecture-backup-20260306-172408"
)

Write-Host "Target folders:"
foreach ($folder in $folders) {
    $name = Split-Path $folder -Leaf
    Write-Host "  - $name"
}
Write-Host ""

$deletedCount = 0
$totalCount = $folders.Count

foreach ($folder in $folders) {
    $folderName = Split-Path $folder -Leaf
    
    if (Test-Path $folder) {
        Write-Host "Deleting: $folderName"
        
        # Method 1: Simple rd command
        Write-Host "  Trying rd command..."
        cmd /c "rd /s /q `"$folder`" 2>nul"
        Start-Sleep -Seconds 2
        
        if (-not (Test-Path $folder)) {
            Write-Host "  SUCCESS: Deleted with rd" -ForegroundColor Green
            $deletedCount++
            continue
        }
        
        # Method 2: PowerShell Remove-Item
        Write-Host "  Trying PowerShell Remove-Item..."
        Remove-Item -Path $folder -Recurse -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        
        if (-not (Test-Path $folder)) {
            Write-Host "  SUCCESS: Deleted with PowerShell" -ForegroundColor Green
            $deletedCount++
            continue
        }
        
        # Method 3: robocopy mirror
        Write-Host "  Trying robocopy..."
        $emptyDir = "C:\temp_empty_$([guid]::NewGuid().ToString().Substring(0,8))"
        New-Item -ItemType Directory -Path $emptyDir -Force | Out-Null
        robocopy $emptyDir $folder /MIR /NJH /NJS /NP /NDL /NS /NC 2>$null
        Remove-Item -Path $folder -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $emptyDir -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        
        if (-not (Test-Path $folder)) {
            Write-Host "  SUCCESS: Deleted with robocopy" -ForegroundColor Green
            $deletedCount++
            continue
        }
        
        Write-Host "  FAILED: All methods failed" -ForegroundColor Red
        
    } else {
        Write-Host "  Folder does not exist: $folderName" -ForegroundColor Gray
        $deletedCount++
    }
    
    Write-Host ""
}

Write-Host ""
Write-Host "=== RESULTS ==="
Write-Host "Deleted: $deletedCount/$totalCount folders"

if ($deletedCount -eq $totalCount) {
    Write-Host "SUCCESS: All folders deleted!" -ForegroundColor Green
} else {
    Write-Host "FAILED: $($totalCount - $deletedCount) folders remain" -ForegroundColor Red
    Write-Host "Recommendation: Restart computer and try again" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")