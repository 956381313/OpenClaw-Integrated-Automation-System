# Simple Knowledge Base Builder

Write-Host "=== OpenClaw Simple Knowledge Base ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Configuration
$kbRoot = "modules/organization\05-knowledge-base"
$workspacePath = "C:\Users\luchaochao\.openclaw\workspace"

# Ensure directory exists
if (-not (Test-Path $kbRoot)) {
    New-Item -ItemType Directory -Path $kbRoot -Force | Out-Null
    Write-Host "Created directory: $kbRoot" -ForegroundColor Green
}

Write-Host "1. Scanning workspace..." -ForegroundColor Yellow

# Scan for markdown files
$mdFiles = Get-ChildItem $workspacePath -Recurse -File -Filter "*.md" -ErrorAction SilentlyContinue | Select-Object -First 20
$txtFiles = Get-ChildItem $workspacePath -Recurse -File -Filter "*.txt" -ErrorAction SilentlyContinue | Select-Object -First 10

$allFiles = @($mdFiles) + @($txtFiles)
$fileCount = $allFiles.Count

Write-Host "  Found $fileCount documentation files" -ForegroundColor Green

# Process files
$knowledge = @()

foreach ($file in $allFiles) {
    try {
        # Read first few lines
        $lines = Get-Content $file.FullName -TotalCount 10 -ErrorAction Stop
        
        # Create knowledge entry
        $entry = @{
            Name = $file.Name
            Path = $file.FullName
            Size = "$([math]::Round($file.Length / 1KB, 2)) KB"
            Modified = $file.LastWriteTime.ToString("yyyy-MM-dd")
            Type = if ($file.Extension -eq '.md') { "Markdown" } else { "Text" }
            Preview = ($lines -join " ").Substring(0, [math]::Min(100, ($lines -join " ").Length))
        }
        
        $knowledge += $entry
        Write-Host "  Added: $($file.Name)" -ForegroundColor Gray
        
    } catch {
        Write-Host "  Skipped: $($file.Name)" -ForegroundColor Yellow
    }
}

Write-Host "`n2. Building knowledge base..." -ForegroundColor Yellow

# Create knowledge base
$kbData = @{
    Created = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    TotalFiles = $knowledge.Count
    Source = $workspacePath
    Files = $knowledge
}

# Save as JSON
$jsonFile = Join-Path $kbRoot "simple-kb-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$kbData | ConvertTo-Json -Depth 3 | Out-File $jsonFile -Encoding UTF8

Write-Host "  Knowledge base saved: $jsonFile" -ForegroundColor Green

# Create summary
Write-Host "`n3. Creating summary..." -ForegroundColor Yellow

$summary = "# OpenClaw Knowledge Base Summary`n"
$summary += "## Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"
$summary += "## Files: $($knowledge.Count)`n`n"

$summary += "## File Types`n"
$mdCount = ($knowledge | Where-Object { $_.Type -eq "Markdown" }).Count
$txtCount = ($knowledge | Where-Object { $_.Type -eq "Text" }).Count
$summary += "- Markdown: $mdCount files`n"
$summary += "- Text: $txtCount files`n`n"

$summary += "## Recent Files`n"
$recent = $knowledge | Sort-Object Modified -Descending | Select-Object -First 5
foreach ($file in $recent) {
    $summary += "- **$($file.Name)** ($($file.Size), $($file.Modified))`n"
    $summary += "  $($file.Preview)...`n"
}

$summary += "`n## How to Use`n"
$summary += "1. View full data: $jsonFile`n"
$summary += "2. Search for information`n"
$summary += "3. Update regularly`n"
$summary += "`n---`n"
$summary += "*Simple Knowledge Base v1.0*"

$summaryFile = Join-Path $kbRoot "simple-summary-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
$summary | Out-File $summaryFile -Encoding UTF8

Write-Host "  Summary saved: $summaryFile" -ForegroundColor Green

# Complete
Write-Host "`n=== Knowledge Base Complete ===" -ForegroundColor Green
Write-Host "Files processed: $($knowledge.Count)" -ForegroundColor Cyan
Write-Host "Knowledge base: $jsonFile" -ForegroundColor Cyan
Write-Host "Summary: $summaryFile" -ForegroundColor Cyan

Write-Host "`nView results:" -ForegroundColor Yellow
Write-Host "  Get-Content $summaryFile" -ForegroundColor Gray
Write-Host "  Get-Content $jsonFile | Select-Object -First 30" -ForegroundColor Gray
