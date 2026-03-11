# OpenClaw Repository Organization (English Version)

Write-Host "=== OpenClaw Repository Organization ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Configuration
$repoRoot = "modules/organization"
$workspacePath = "C:\Users\luchaochao\.openclaw\workspace"

# 1. Create directory structure
Write-Host "1. Creating directory structure..." -ForegroundColor Yellow

if (-not (Test-Path $repoRoot)) {
    New-Item -ItemType Directory -Path $repoRoot -Force | Out-Null
    Write-Host "  Created: $repoRoot" -ForegroundColor Green
}

# Create subdirectories
$subDirs = @(
    "01-data-collection",
    "02-preprocessing", 
    "03-classification",
    "04-summarization",
    "05-knowledge-base",
    "06-search-retrieval",
    "07-automation",
    "08-monitoring",
    "09-configuration"
)

foreach ($dir in $subDirs) {
    $fullPath = Join-Path $repoRoot $dir
    if (-not (Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Host "  Created: $dir" -ForegroundColor Green
    }
}

# 2. Scan workspace files
Write-Host "`n2. Scanning workspace files..." -ForegroundColor Yellow

$files = Get-ChildItem $workspacePath -Recurse -File -ErrorAction SilentlyContinue | 
    Where-Object { $_.Extension -match '\.(md|ps1|bat|json|txt|log|yml|yaml|xml)$' } |
    Select-Object -First 50

$fileCount = $files.Count
Write-Host "  Found $fileCount files" -ForegroundColor Green

# 3. Simple classification
Write-Host "`n3. Classifying files..." -ForegroundColor Yellow

$categories = @{
    "Documents" = @()
    "Scripts" = @()
    "Configs" = @()
    "Logs" = @()
    "Other" = @()
}

foreach ($file in $files) {
    $ext = $file.Extension.ToLower()
    
    if ($ext -in @('.md', '.txt')) {
        $categories.Documents += $file
    }
    elseif ($ext -in @('.ps1', '.bat', '.sh')) {
        $categories.Scripts += $file
    }
    elseif ($ext -in @('.json', '.yml', '.yaml', '.xml', '.config')) {
        $categories.Configs += $file
    }
    elseif ($ext -in @('.log')) {
        $categories.Logs += $file
    }
    else {
        $categories.Other += $file
    }
}

# Show results
Write-Host "`nClassification results:" -ForegroundColor Cyan
foreach ($cat in $categories.Keys | Sort-Object) {
    $count = $categories[$cat].Count
    $pct = if ($fileCount -gt 0) { [math]::Round(($count / $fileCount) * 100, 1) } else { 0 }
    Write-Host "  $cat : $count files ($pct%)" -ForegroundColor Gray
}

# 4. Save classification results
Write-Host "`n4. Saving classification results..." -ForegroundColor Yellow

$classDir = Join-Path $repoRoot "03-classification"
$classFile = Join-Path $classDir "classification-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"

$classData = @{
    ScanTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    TotalFiles = $fileCount
    Categories = @{}
}

foreach ($cat in $categories.Keys) {
    $classData.Categories[$cat] = $categories[$cat].Count
}

$classData | ConvertTo-Json | Out-File $classFile -Encoding UTF8
Write-Host "  Classification results: $classFile" -ForegroundColor Green

# 5. Build knowledge base
Write-Host "`n5. Building knowledge base..." -ForegroundColor Yellow

$kbDir = Join-Path $repoRoot "05-knowledge-base"
$kbFile = Join-Path $kbDir "knowledge-base-$(Get-Date -Format 'yyyyMMdd').json"

$kbData = @{
    Created = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    FileCount = $fileCount
    Categories = $classData.Categories
    Summary = "OpenClaw workspace knowledge base"
}

$kbData | ConvertTo-Json | Out-File $kbFile -Encoding UTF8
Write-Host "  Knowledge base: $kbFile" -ForegroundColor Green

# 6. Generate report
Write-Host "`n6. Generating organization report..." -ForegroundColor Yellow

$reportLines = @()
$reportLines += "# OpenClaw Repository Organization Report"
$reportLines += "## Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$reportLines += "## Files processed: $fileCount"
$reportLines += ""
$reportLines += "## Classification Statistics"
foreach ($cat in $categories.Keys | Sort-Object) {
    $count = $categories[$cat].Count
    $pct = if ($fileCount -gt 0) { [math]::Round(($count / $fileCount) * 100, 1) } else { 0 }
    $reportLines += "- **$cat**: $count files ($pct%)"
}
$reportLines += ""
$reportLines += "## Generated Files"
$reportLines += "1. Classification results: $classFile"
$reportLines += "2. Knowledge base: $kbFile"
$reportLines += ""
$reportLines += "## System Information"
$reportLines += "- Organization system version: 1.0.0"
$reportLines += "- Running environment: PowerShell"
$reportLines += "- Workspace directory: $workspacePath"
$reportLines += ""
$reportLines += "---"
$reportLines += "*Report generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')*"

$reportFile = "organization-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
$reportLines | Out-File $reportFile -Encoding UTF8
Write-Host "  Organization report: $reportFile" -ForegroundColor Green

# Complete
Write-Host "`n=== Organization Complete ===" -ForegroundColor Green
Write-Host "Files processed: $fileCount" -ForegroundColor Cyan
Write-Host "Categories: $($categories.Keys.Count)" -ForegroundColor Cyan
Write-Host "Knowledge base: $kbFile" -ForegroundColor Cyan
Write-Host "Report: $reportFile" -ForegroundColor Cyan

Write-Host "`nView results:" -ForegroundColor Yellow
Write-Host "  Get-Content $reportFile" -ForegroundColor Gray
Write-Host "  Get-Content $classFile" -ForegroundColor Gray
Write-Host "  Get-Content $kbFile" -ForegroundColor Gray
