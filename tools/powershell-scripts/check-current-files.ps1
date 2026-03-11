# Check current directory files
Write-Host "Current directory analysis..." -ForegroundColor Cyan
Write-Host "Current directory: $PWD" -ForegroundColor Yellow
Write-Host ""

# List directories
Write-Host "Directory list:" -ForegroundColor Cyan
$directories = Get-ChildItem -Directory | Sort-Object Name
foreach ($dir in $directories) {
    Write-Host ("  {0}" -f $dir.Name) -ForegroundColor Gray
}

Write-Host ""

# List files in root directory
Write-Host "Files in root directory:" -ForegroundColor Cyan
$files = Get-ChildItem -File | Sort-Object Name
foreach ($file in $files) {
    $sizeKB = [math]::Round($file.Length/1KB, 1)
    Write-Host ("  {0,-40} {1,8} KB" -f $file.Name, $sizeKB) -ForegroundColor Gray
}

Write-Host ""
Write-Host "Total files in root: $($files.Count)" -ForegroundColor Yellow
Write-Host ""

# Identify files that should be organized
Write-Host "Files that should be organized:" -ForegroundColor Cyan

$unorganizedFiles = @()

# PowerShell scripts not in scripts directory
$ps1Files = $files | Where-Object { $_.Extension -eq ".ps1" }
if ($ps1Files.Count -gt 0) {
    Write-Host "  PowerShell scripts (.ps1): $($ps1Files.Count)" -ForegroundColor Yellow
    foreach ($file in $ps1Files) {
        Write-Host ("    {0}" -f $file.Name) -ForegroundColor Gray
        $unorganizedFiles += $file
    }
}

# JSON files not in configs directory
$jsonFiles = $files | Where-Object { $_.Extension -eq ".json" }
if ($jsonFiles.Count -gt 0) {
    Write-Host "  JSON files (.json): $($jsonFiles.Count)" -ForegroundColor Yellow
    foreach ($file in $jsonFiles) {
        Write-Host ("    {0}" -f $file.Name) -ForegroundColor Gray
        $unorganizedFiles += $file
    }
}

# Markdown files not in docs directory
$mdFiles = $files | Where-Object { $_.Extension -eq ".md" }
if ($mdFiles.Count -gt 0) {
    Write-Host "  Markdown files (.md): $($mdFiles.Count)" -ForegroundColor Yellow
    foreach ($file in $mdFiles) {
        Write-Host ("    {0}" -f $file.Name) -ForegroundColor Gray
        $unorganizedFiles += $file
    }
}

# Batch files not in scripts directory
$batFiles = $files | Where-Object { $_.Extension -eq ".bat" }
if ($batFiles.Count -gt 0) {
    Write-Host "  Batch files (.bat): $($batFiles.Count)" -ForegroundColor Yellow
    foreach ($file in $batFiles) {
        Write-Host ("    {0}" -f $file.Name) -ForegroundColor Gray
        $unorganizedFiles += $file
    }
}

Write-Host ""
Write-Host "Total unorganized files: $($unorganizedFiles.Count)" -ForegroundColor Red
Write-Host ""

# Show file types that should stay in root
Write-Host "Files that should stay in root (special files):" -ForegroundColor Cyan
$specialFiles = $files | Where-Object { 
    $_.Name -eq ".gitignore" -or 
    $_.Name -eq "README.md" -or 
    $_.Name -eq "LICENSE" -or 
    $_.Name -eq "package.json" -or
    $_.Name -like "*report*" -or
    $_.Name -like "*backup*" -or
    $_.Name -like "*log*"
}

foreach ($file in $specialFiles) {
    Write-Host ("  {0}" -f $file.Name) -ForegroundColor Gray
}