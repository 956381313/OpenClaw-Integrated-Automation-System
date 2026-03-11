# Auto Summarize Script

Write-Host "=== OpenClaw Auto Summarize ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Configuration
$sourceDir = "C:\Users\luchaochao\.openclaw\workspace"
$outputDir = "data/reports"
$maxFiles = 10

# Create output directory
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    Write-Host "Created output directory: $outputDir" -ForegroundColor Green
}

# Find markdown files
$files = Get-ChildItem $sourceDir -Recurse -File -Filter "*.md" -ErrorAction SilentlyContinue | 
    Select-Object -First $maxFiles

Write-Host "Found $($files.Count) markdown files to summarize" -ForegroundColor Green
Write-Host ""

$processedCount = 0
foreach ($file in $files) {
    try {
        Write-Host "Processing: $($file.Name)" -ForegroundColor Gray
        
        # Read file content
        $content = Get-Content $file.FullName -Raw -ErrorAction Stop
        
        # Simple summarization (first 3 paragraphs or 500 chars)
        $lines = $content -split "`n"
        $summary = ""
        $paragraphCount = 0
        
        foreach ($line in $lines) {
            $trimmed = $line.Trim()
            if ($trimmed -and -not $trimmed.StartsWith("#") -and -not $trimmed.StartsWith("<!--")) {
                $summary += $trimmed + "`n`n"
                $paragraphCount++
                
                if ($paragraphCount -ge 3 -or $summary.Length -ge 500) {
                    break
                }
            }
        }
        
        # Create summary file
        $summaryFile = Join-Path $outputDir "$($file.BaseName)-summary.md"
        
        $summaryContent = @"
# Summary: $($file.Name)
## Source: $($file.FullName)
## Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
## Original size: $([math]::Round($file.Length / 1024, 2)) KB

## Summary:
$summary

## File Info:
- Created: $($file.CreationTime)
- Modified: $($file.LastWriteTime)
- Lines: $(($content -split "`n").Count)
- Characters: $($content.Length)

## Full Content Available:
See original file for complete content.

---
*Auto-generated summary by OpenClaw*
"@
        
        $summaryContent | Out-File $summaryFile -Encoding UTF8
        
        $processedCount++
        Write-Host "  Summary saved: $summaryFile" -ForegroundColor Green
        
    } catch {
        Write-Host "  Error processing: $($file.Name)" -ForegroundColor Yellow
    }
}

# Generate summary report
$report = @"
# Auto Summarize Report
## Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
## Processed: $processedCount files
## Source: $sourceDir
## Output: $outputDir

## Summary Statistics:
- Total files found: $($files.Count)
- Successfully processed: $processedCount
- Failed: $($files.Count - $processedCount)

## Generated Files:
$(Get-ChildItem $outputDir -File | ForEach-Object { "- $($_.Name) ($([math]::Round($_.Length / 1024, 2)) KB)" })

## Next Steps:
1. Review summaries in $outputDir directory
2. Adjust summarization logic as needed
3. Schedule regular summarization
4. Integrate with knowledge base

## Usage:
Run this script regularly to keep summaries updated.

---
*OpenClaw Auto Summarize System v1.0*
"@

$reportFile = Join-Path $outputDir "summarize-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
$report | Out-File $reportFile -Encoding UTF8

Write-Host "`n=== Auto Summarize Complete ===" -ForegroundColor Green
Write-Host "Processed files: $processedCount" -ForegroundColor Cyan
Write-Host "Output directory: $outputDir" -ForegroundColor Cyan
Write-Host "Report: $reportFile" -ForegroundColor Cyan

Write-Host "`nView results:" -ForegroundColor Yellow
Write-Host "  Get-ChildItem $outputDir -File" -ForegroundColor Gray
Write-Host "  Get-Content $reportFile" -ForegroundColor Gray
