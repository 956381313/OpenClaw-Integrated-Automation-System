# Check after cleanup
Write-Host "After cleanup analysis..." -ForegroundColor Cyan
Write-Host "Current directory: $PWD" -ForegroundColor Yellow
Write-Host ""

# List directories
Write-Host "Directory list:" -ForegroundColor Cyan
$dirs = Get-ChildItem -Directory | Sort-Object Name
foreach ($dir in $dirs) {
    Write-Host "  $($dir.Name)" -ForegroundColor Gray
}

Write-Host ""

# List files in root
Write-Host "Files in root directory (after cleanup):" -ForegroundColor Cyan
$files = Get-ChildItem -File | Sort-Object Name
Write-Host "  Total files: $($files.Count)" -ForegroundColor Yellow
Write-Host ""

foreach ($file in $files) {
    $sizeKB = [math]::Round($file.Length/1KB, 1)
    Write-Host "  $($file.Name) ($sizeKB KB)" -ForegroundColor Gray
}

Write-Host ""

# Check tools/batch directory
Write-Host "Batch scripts directory:" -ForegroundColor Cyan
if (Test-Path "tools/batch") {
    $batchFiles = Get-ChildItem "batch-tools/scripts/" -Filter "*.bat" | Sort-Object Name
    Write-Host "  Total batch files: $($batchFiles.Count)" -ForegroundColor Yellow
    $batchFiles | Select-Object -First 10 | ForEach-Object {
        Write-Host "    $($_.Name)" -ForegroundColor Gray
    }
    if ($batchFiles.Count -gt 10) {
        Write-Host "    ... and $($batchFiles.Count - 10) more" -ForegroundColor Gray
    }
} else {
    Write-Host "  tools/batch directory not found" -ForegroundColor Red
}

Write-Host ""

# Check scripts directory
Write-Host "PowerShell scripts directory:" -ForegroundColor Cyan
if (Test-Path "scripts") {
    $ps1Files = Get-ChildItem "tools/scripts/" -Filter "*.ps1" | Sort-Object Name
    Write-Host "  Total PowerShell scripts: $($ps1Files.Count)" -ForegroundColor Yellow
    $ps1Files | Select-Object -First 10 | ForEach-Object {
        Write-Host "    $($_.Name)" -ForegroundColor Gray
    }
    if ($ps1Files.Count -gt 10) {
        Write-Host "    ... and $($ps1Files.Count - 10) more" -ForegroundColor Gray
    }
} else {
    Write-Host "  scripts directory not found" -ForegroundColor Red
}
