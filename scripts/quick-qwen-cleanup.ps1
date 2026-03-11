# Quick Qwen Duplicate Cleanup - Preview Mode
Write-Host "=== QUICK QWEN DUPLICATE CLEANUP PREVIEW ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "Searching for Qwen3.5-35B-A3B-Q4_0 files..." -ForegroundColor Yellow
Write-Host ""

# Quick search
$searchTerm = "Qwen3.5-35B-A3B-Q4_0"
Write-Host "Search term: $searchTerm" -ForegroundColor Gray

# Method 1: Direct file search
Write-Host "1. Searching for exact filename matches..." -ForegroundColor Yellow
$exactFiles = Get-ChildItem -Path . -Filter "*$searchTerm*" -Recurse -ErrorAction SilentlyContinue -Force

if ($exactFiles.Count -gt 0) {
    Write-Host "   Found $($exactFiles.Count) files with exact match" -ForegroundColor Green
    
    # Group by filename
    $fileGroups = @{}
    foreach ($file in $exactFiles) {
        $fileName = $file.Name
        if (-not $fileGroups.ContainsKey($fileName)) {
            $fileGroups[$fileName] = @()
        }
        $fileGroups[$fileName] += $file
    }
    
    # Find duplicates
    $duplicateGroups = $fileGroups.Keys | Where-Object { $fileGroups[$_].Count -gt 1 }
    
    if ($duplicateGroups.Count -gt 0) {
        Write-Host "   Found $($duplicateGroups.Count) duplicate file groups" -ForegroundColor Yellow
        Write-Host ""
        
        $groupNum = 1
        foreach ($fileName in $duplicateGroups) {
            $files = $fileGroups[$fileName] | Sort-Object LastWriteTime -Descending
            $totalSize = ($files | Measure-Object -Property Length -Sum).Sum
            $totalSizeMB = [math]::Round($totalSize / 1MB, 2)
            
            Write-Host "   Group ${groupNum}: $fileName" -ForegroundColor Yellow
            Write-Host "     Files: $($files.Count)" -ForegroundColor Gray
            Write-Host "     Total size: ${totalSizeMB} MB" -ForegroundColor Gray
            Write-Host "     Locations:" -ForegroundColor Gray
            
            $fileNum = 1
            foreach ($file in $files) {
                $fileSizeMB = [math]::Round($file.Length / 1MB, 2)
                $relativePath = $file.FullName.Replace((Get-Location).Path + "\", "")
                $modified = $file.LastWriteTime.ToString("MM/dd HH:mm")
                
                if ($fileNum -eq 1) {
                    Write-Host "     $fileNum. [KEEP] ${fileSizeMB} MB - $relativePath" -ForegroundColor Green
                } else {
                    Write-Host "     $fileNum. [DELETE] ${fileSizeMB} MB - $relativePath" -ForegroundColor Red
                }
                Write-Host "        Modified: $modified" -ForegroundColor DarkGray
                
                $fileNum++
            }
            
            # Calculate space to free
            $filesToDelete = $files | Select-Object -Skip 1
            $spaceToFree = ($filesToDelete | Measure-Object -Property Length -Sum).Sum
            $spaceToFreeMB = [math]::Round($spaceToFree / 1MB, 2)
            
            Write-Host "     Space to free: ${spaceToFreeMB} MB" -ForegroundColor $(if ($spaceToFreeMB -gt 0) {"Green"} else {"Gray"})
            Write-Host ""
            
            $groupNum++
        }
        
        # Total summary
        $allDuplicates = $duplicateGroups | ForEach-Object { $fileGroups[$_] | Select-Object -Skip 1 }
        $totalSpaceToFree = ($allDuplicates | Measure-Object -Property Length -Sum).Sum
        $totalSpaceToFreeMB = [math]::Round($totalSpaceToFree / 1MB, 2)
        $totalSpaceToFreeGB = [math]::Round($totalSpaceToFree / 1GB, 2)
        
        Write-Host "=== TOTAL SUMMARY ===" -ForegroundColor Cyan
        Write-Host "Duplicate groups: $($duplicateGroups.Count)" -ForegroundColor Gray
        Write-Host "Files to delete: $($allDuplicates.Count)" -ForegroundColor Gray
        Write-Host "Space to free: ${totalSpaceToFreeMB} MB (${totalSpaceToFreeGB} GB)" -ForegroundColor Green
        Write-Host ""
        
    } else {
        Write-Host "   No duplicate files found (all files are unique)" -ForegroundColor Green
    }
    
    # Show all files found
    Write-Host "2. ALL FILES FOUND:" -ForegroundColor Yellow
    $fileNum = 1
    foreach ($file in $exactFiles | Sort-Object LastWriteTime -Descending) {
        $fileSizeMB = [math]::Round($file.Length / 1MB, 2)
        $relativePath = $file.FullName.Replace((Get-Location).Path + "\", "")
        $modified = $file.LastWriteTime.ToString("MM/dd HH:mm")
        
        Write-Host "   $fileNum. ${fileSizeMB} MB - $relativePath" -ForegroundColor Gray
        Write-Host "      Modified: $modified" -ForegroundColor DarkGray
        
        $fileNum++
    }
    
} else {
    Write-Host "   No files found with exact match" -ForegroundColor Yellow
}
Write-Host ""

# Method 2: Search in file contents
Write-Host "3. SEARCHING IN FILE CONTENTS..." -ForegroundColor Yellow
try {
    # Search for the term in text files
    $textFiles = Get-ChildItem -Path . -Include "*.txt", "*.log", "*.md", "*.json", "*.yml", "*.yaml" -Recurse -ErrorAction SilentlyContinue | 
        Select-Object -First 50
    
    $filesWithTerm = @()
    foreach ($file in $textFiles) {
        try {
            $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
            if ($content -and $content -match $searchTerm) {
                $filesWithTerm += $file
            }
        } catch {
            # Skip files that can't be read
        }
    }
    
    if ($filesWithTerm.Count -gt 0) {
        Write-Host "   Found $($filesWithTerm.Count) files containing the term in content" -ForegroundColor Green
        
        foreach ($file in $filesWithTerm | Select-Object -First 5) {
            $relativePath = $file.FullName.Replace((Get-Location).Path + "\", "")
            Write-Host "   - $relativePath" -ForegroundColor Gray
        }
        
        if ($filesWithTerm.Count -gt 5) {
            Write-Host "   ... and $($filesWithTerm.Count - 5) more" -ForegroundColor Gray
        }
    } else {
        Write-Host "   No files found with term in content" -ForegroundColor Gray
    }
} catch {
    Write-Host "   Error searching file contents" -ForegroundColor Yellow
}
Write-Host ""

# Create immediate cleanup command
Write-Host "4. IMMEDIATE CLEANUP COMMANDS:" -ForegroundColor Red
Write-Host ""
Write-Host "To delete all duplicate Qwen files (keep newest):" -ForegroundColor Gray
Write-Host "   powershell -Command `"`$files = Get-ChildItem -Path . -Filter '*Qwen3.5-35B-A3B-Q4_0*' -Recurse -ErrorAction SilentlyContinue; `$groups = `$files | Group-Object Name; foreach (`$group in `$groups) { if (`$group.Count -gt 1) { `$keep = `$group.Group | Sort-Object LastWriteTime -Descending | Select-Object -First 1; `$delete = `$group.Group | Where-Object { `$_.FullName -ne `$keep.FullName }; `$delete | Remove-Item -Force -ErrorAction SilentlyContinue; Write-Host 'Deleted ' + `$delete.Count + ' duplicates of ' + `$group.Name } }`"" -ForegroundColor Gray
Write-Host ""

# Or use the batch file
Write-Host "Using batch file:" -ForegroundColor Gray
Write-Host "   .\cleanup-qwen.bat" -ForegroundColor Gray
Write-Host "   Select option 2 and confirm with YES" -ForegroundColor Gray
Write-Host ""

# Safety warning
Write-Host "⚠️  SAFETY WARNING:" -ForegroundColor Red
Write-Host "   Make sure these are actually duplicate files before deleting!" -ForegroundColor Red
Write-Host "   Check file contents if unsure." -ForegroundColor Red
Write-Host ""

Write-Host "Preview completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray