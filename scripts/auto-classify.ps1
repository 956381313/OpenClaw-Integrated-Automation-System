# Auto File Classification
Write-Host "Auto File Classification"
Write-Host "========================"
Write-Host "Start: $(Get-Date -Format 'HH:mm:ss')"
Write-Host ""

# Target directories
$targetDirs = @{
    "scripts" = @(".ps1", ".bat", ".sh")
    "docs" = @(".md", ".txt", ".pdf")
    "config" = @(".json", ".yaml", ".yml")
    "data" = @(".csv", ".xlsx")
    "temp" = @(".tmp", ".temp", ".bak")
    "archive" = @(".zip", ".rar")
}

# Create directories
foreach ($dir in $targetDirs.Keys) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "Created: $dir"
    }
}
Write-Host ""

# Stats
$stats = @{
    Moved = 0
    Skipped = 0
    Errors = 0
}

# Get root files
$files = Get-ChildItem -Path "." -File -Depth 0
Write-Host "Found $($files.Count) files to classify"
Write-Host ""

foreach ($file in $files) {
    $moved = $false
    
    foreach ($dir in $targetDirs.Keys) {
        $extensions = $targetDirs[$dir]
        
        foreach ($ext in $extensions) {
            if ($file.Extension -eq $ext) {
                try {
                    Move-Item -Path $file.FullName -Destination $dir -Force
                    Write-Host "Moved: $($file.Name) -> $dir/"
                    $stats.Moved++
                    $moved = $true
                    break
                } catch {
                    Write-Host "Error: Cannot move $($file.Name)" -ForegroundColor Red
                    $stats.Errors++
                    $moved = $true
                }
            }
            if ($moved) { break }
        }
        if ($moved) { break }
    }
    
    if (-not $moved) {
        $stats.Skipped++
    }
}

Write-Host ""
Write-Host "=== Results ===" -ForegroundColor Green
Write-Host "Moved: $($stats.Moved) files" -ForegroundColor Cyan
Write-Host "Skipped: $($stats.Skipped) files" -ForegroundColor Gray
Write-Host "Errors: $($stats.Errors) files" -ForegroundColor $(if ($stats.Errors -gt 0) {"Red"} else {"Gray"})
Write-Host ""

# Show directory stats
Write-Host "Directory statistics:" -ForegroundColor Yellow
foreach ($dir in $targetDirs.Keys) {
    $fileCount = (Get-ChildItem -Path $dir -File -ErrorAction SilentlyContinue).Count
    if ($fileCount -gt 0) {
        Write-Host "  $dir/: $fileCount files" -ForegroundColor Gray
    }
}
Write-Host ""

# Show remaining files
$remainingFiles = Get-ChildItem -Path "." -File -Depth 0
if ($remainingFiles.Count -gt 0) {
    Write-Host "Unclassified files ($($remainingFiles.Count)):" -ForegroundColor Yellow
    $remainingFiles | Select-Object -First 10 Name, Extension | ForEach-Object {
        Write-Host "  - $($_.Name)" -ForegroundColor Gray
    }
    if ($remainingFiles.Count -gt 10) {
        Write-Host "  ... and $($remainingFiles.Count - 10) more" -ForegroundColor Gray
    }
} else {
    Write-Host "All files classified" -ForegroundColor Green
}

Write-Host ""
Write-Host "End: $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Gray