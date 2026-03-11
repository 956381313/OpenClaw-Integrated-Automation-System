# OpenClaw Knowledge Base System (English Version)

Write-Host "=== OpenClaw Knowledge Base System ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Configuration
$kbRoot = "modules/organization\05-knowledge-base"
$workspacePath = "C:\Users\luchaochao\.openclaw\workspace"

# Ensure knowledge base directory exists
if (-not (Test-Path $kbRoot)) {
    New-Item -ItemType Directory -Path $kbRoot -Force | Out-Null
    Write-Host "Created knowledge base directory: $kbRoot" -ForegroundColor Green
}

Write-Host "1. Scanning workspace for knowledge..." -ForegroundColor Yellow

# Scan for important files
$importantFiles = Get-ChildItem $workspacePath -Recurse -File -ErrorAction SilentlyContinue | 
    Where-Object { 
        $_.Extension -match '\.(md|txt)$' -or 
        $_.Name -match '(README|GUIDE|MANUAL|DOCUMENTATION|CONFIG|SETUP)'
    } |
    Select-Object -First 30

$fileCount = $importantFiles.Count
Write-Host "  Found $fileCount important files" -ForegroundColor Green

# 2. Extract knowledge from files
Write-Host "`n2. Extracting knowledge from files..." -ForegroundColor Yellow

$knowledgeEntries = @()

foreach ($file in $importantFiles) {
    try {
        $content = Get-Content $file.FullName -Raw -ErrorAction Stop
        
        # Extract basic info
        $entry = @{
            FileName = $file.Name
            FilePath = $file.FullName
            FileSize = "$([math]::Round($file.Length / 1KB, 2)) KB"
            LastModified = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
            Extension = $file.Extension
            Category = "Unknown"
            Summary = ""
            Keywords = @()
        }
        
        # Determine category
        if ($file.Name -match 'README') {
            $entry.Category = "Documentation"
        }
        elseif ($file.Name -match '(GUIDE|MANUAL|DOCUMENTATION)') {
            $entry.Category = "Guide"
        }
        elseif ($file.Name -match '(CONFIG|SETUP)') {
            $entry.Category = "Configuration"
        }
        elseif ($file.Extension -eq '.md') {
            $entry.Category = "Markdown Document"
        }
        else {
            $entry.Category = "Text Document"
        }
        
        # Extract summary (first 3 lines or 200 chars)
        $lines = $content -split "`n"
        $summary = ""
        $lineCount = 0
        
        foreach ($line in $lines) {
            $trimmed = $line.Trim()
            if ($trimmed -and -not $trimmed.StartsWith("#") -and -not $trimmed.StartsWith("<!--")) {
                $summary += $trimmed + " "
                $lineCount++
                if ($lineCount -ge 3 -or $summary.Length -ge 200) {
                    break
                }
            }
        }
        
        if ($summary.Length -gt 200) {
            $summary = $summary.Substring(0, 200) + "..."
        }
        
        $entry.Summary = $summary
        
        # Extract keywords from filename and content
        $keywords = @()
        
        # Keywords from filename
        $nameWords = $file.Name -replace '[^a-zA-Z0-9]', ' ' -split ' ' | Where-Object { $_ -and $_.Length -gt 3 }
        $keywords += $nameWords | Select-Object -First 5
        
        # Add to knowledge base
        $knowledgeEntries += $entry
        
        Write-Host "  Processed: $($file.Name)" -ForegroundColor Gray
        
    } catch {
        Write-Host "  Error processing: $($file.Name)" -ForegroundColor Yellow
    }
}

# 3. Build knowledge base
Write-Host "`n3. Building knowledge base..." -ForegroundColor Yellow

$knowledgeBase = @{
    Metadata = @{
        Created = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Source = $workspacePath
        FileCount = $knowledgeEntries.Count
        Version = "1.0.0"
    }
    Statistics = @{
        ByCategory = @{}
        ByExtension = @{}
    }
    KnowledgeEntries = $knowledgeEntries
}

# Calculate statistics
foreach ($entry in $knowledgeEntries) {
    $category = $entry.Category
    $extension = $entry.Extension
    
    if (-not $knowledgeBase.Statistics.ByCategory.ContainsKey($category)) {
        $knowledgeBase.Statistics.ByCategory[$category] = 0
    }
    $knowledgeBase.Statistics.ByCategory[$category]++
    
    if (-not $knowledgeBase.Statistics.ByExtension.ContainsKey($extension)) {
        $knowledgeBase.Statistics.ByExtension[$extension] = 0
    }
    $knowledgeBase.Statistics.ByExtension[$extension]++
}

# Save knowledge base
$kbFile = Join-Path $kbRoot "knowledge-base-full-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$knowledgeBase | ConvertTo-Json -Depth 4 | Out-File $kbFile -Encoding UTF8

Write-Host "  Knowledge base saved: $kbFile" -ForegroundColor Green

# 4. Generate knowledge summary
Write-Host "`n4. Generating knowledge summary..." -ForegroundColor Yellow

$summaryLines = @()
$summaryLines += "# OpenClaw Knowledge Base Summary"
$summaryLines += "## Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$summaryLines += "## Source: $workspacePath"
$summaryLines += "## Total entries: $($knowledgeEntries.Count)"
$summaryLines += ""

$summaryLines += "## Categories"
foreach ($category in $knowledgeBase.Statistics.ByCategory.Keys | Sort-Object) {
    $count = $knowledgeBase.Statistics.ByCategory[$category]
    $summaryLines += "- **$category**: $count entries"
}
$summaryLines += ""

$summaryLines += "## File Types"
foreach ($extension in $knowledgeBase.Statistics.ByExtension.Keys | Sort-Object) {
    $count = $knowledgeBase.Statistics.ByExtension[$extension]
    $summaryLines += "- $extension: $count files"
}
$summaryLines += ""

$summaryLines += "## Knowledge Entries (Sample)"
$sampleCount = [math]::Min(5, $knowledgeEntries.Count)
for ($i = 0; $i -lt $sampleCount; $i++) {
    $entry = $knowledgeEntries[$i]
    $summaryLines += "### $($entry.FileName)"
    $summaryLines += "- Category: $($entry.Category)"
    $summaryLines += "- Size: $($entry.FileSize)"
    $summaryLines += "- Summary: $($entry.Summary)"
    $summaryLines += ""
}

$summaryLines += "## How to Use"
$summaryLines += "1. View full knowledge base: $kbFile"
$summaryLines += "2. Search for specific information"
$summaryLines += "3. Update knowledge base regularly"
$summaryLines += "4. Integrate with other systems"
$summaryLines += ""
$summaryLines += "---"
$summaryLines += "*Knowledge base generated by OpenClaw Knowledge System*"

$summaryFile = Join-Path $kbRoot "knowledge-summary-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
$summaryLines | Out-File $summaryFile -Encoding UTF8

Write-Host "  Knowledge summary: $summaryFile" -ForegroundColor Green

# 5. Create search index
Write-Host "`n5. Creating search index..." -ForegroundColor Yellow

$searchIndex = @{
    Created = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    TotalEntries = $knowledgeEntries.Count
    Index = @()
}

foreach ($entry in $knowledgeEntries) {
    $indexEntry = @{
        FileName = $entry.FileName
        Category = $entry.Category
        Summary = $entry.Summary
        Path = $entry.FilePath
        Keywords = @($entry.FileName, $entry.Category)
    }
    
    $searchIndex.Index += $indexEntry
}

$indexFile = Join-Path $kbRoot "search-index-$(Get-Date -Format 'yyyyMMdd').json"
$searchIndex | ConvertTo-Json -Depth 3 | Out-File $indexFile -Encoding UTF8

Write-Host "  Search index: $indexFile" -ForegroundColor Green

# Complete
Write-Host "`n=== Knowledge Base Complete ===" -ForegroundColor Green
Write-Host "Knowledge entries: $($knowledgeEntries.Count)" -ForegroundColor Cyan
Write-Host "Categories: $($knowledgeBase.Statistics.ByCategory.Keys.Count)" -ForegroundColor Cyan
Write-Host "Full knowledge base: $kbFile" -ForegroundColor Cyan
Write-Host "Knowledge summary: $summaryFile" -ForegroundColor Cyan
Write-Host "Search index: $indexFile" -ForegroundColor Cyan

Write-Host "`nView knowledge base:" -ForegroundColor Yellow
Write-Host "  Get-Content $summaryFile" -ForegroundColor Gray
Write-Host "  Get-Content $kbFile | Select-Object -First 50" -ForegroundColor Gray
Write-Host "  Get-Content $indexFile | Select-Object -First 20" -ForegroundColor Gray

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Review knowledge base content" -ForegroundColor Gray
Write-Host "2. Update knowledge base regularly" -ForegroundColor Gray
Write-Host "3. Integrate with search system" -ForegroundColor Gray
Write-Host "4. Add more knowledge sources" -ForegroundColor Gray
