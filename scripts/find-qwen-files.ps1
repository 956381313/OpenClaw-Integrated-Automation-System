# Find and Clean Qwen3.5-35B-A3B-Q4_0 Files
Write-Host "=== FINDING QWEN3.5-35B-A3B-Q4_0 FILES ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "Searching for files containing 'Qwen3.5-35B-A3B-Q4_0'..." -ForegroundColor Yellow
Write-Host ""

# Search patterns
$searchPatterns = @(
    "*Qwen3.5-35B-A3B-Q4_0*",
    "*qwen3.5-35b-a3b-q4_0*",
    "*Qwen*35B*",
    "*qwen*35b*"
)

$allFiles = @()
$totalSize = 0

# Search in current directory and subdirectories
foreach ($pattern in $searchPatterns) {
    Write-Host "Searching for pattern: $pattern" -ForegroundColor Gray
    
    $files = Get-ChildItem -Path . -Filter $pattern -Recurse -ErrorAction SilentlyContinue -Force
    $allFiles += $files
    
    if ($files.Count -gt 0) {
        $patternSize = ($files | Measure-Object -Property Length -Sum).Sum
        $patternSizeMB = [math]::Round($patternSize / 1MB, 2)
        $totalSize += $patternSize
        
        Write-Host "   Found $($files.Count) files (${patternSizeMB} MB)" -ForegroundColor Green
    } else {
        Write-Host "   No files found" -ForegroundColor Gray
    }
}
Write-Host ""

# Remove duplicates from array
$uniqueFiles = $allFiles | Sort-Object FullName -Unique

if ($uniqueFiles.Count -eq 0) {
    Write-Host "No files containing 'Qwen3.5-35B-A3B-Q4_0' found." -ForegroundColor Yellow
    exit 0
}

# Group files by name to find duplicates
Write-Host "ANALYZING FILES:" -ForegroundColor Yellow
$fileGroups = @{}
$duplicateGroups = @{}

foreach ($file in $uniqueFiles) {
    $fileName = $file.Name
    if (-not $fileGroups.ContainsKey($fileName)) {
        $fileGroups[$fileName] = @()
    }
    $fileGroups[$fileName] += $file
}

# Identify duplicate files (same name, different locations)
foreach ($fileName in $fileGroups.Keys) {
    $files = $fileGroups[$fileName]
    if ($files.Count -gt 1) {
        $duplicateGroups[$fileName] = $files
    }
}

# Display results
$totalSizeMB = [math]::Round($totalSize / 1MB, 2)
Write-Host "Total files found: $($uniqueFiles.Count)" -ForegroundColor Green
Write-Host "Total size: ${totalSizeMB} MB" -ForegroundColor Green
Write-Host "Duplicate file groups: $($duplicateGroups.Count)" -ForegroundColor $(if ($duplicateGroups.Count -gt 0) {"Yellow"} else {"Green"})
Write-Host ""

if ($duplicateGroups.Count -gt 0) {
    Write-Host "DUPLICATE FILE GROUPS FOUND:" -ForegroundColor Red
    
    $groupNumber = 1
    foreach ($fileName in $duplicateGroups.Keys) {
        $files = $duplicateGroups[$fileName]
        $groupSize = ($files | Measure-Object -Property Length -Sum).Sum
        $groupSizeMB = [math]::Round($groupSize / 1MB, 2)
        
        Write-Host ""
        Write-Host "Group ${groupNumber}: $fileName" -ForegroundColor Yellow
        Write-Host "   Files: $($files.Count)" -ForegroundColor Gray
        Write-Host "   Total size: ${groupSizeMB} MB" -ForegroundColor Gray
        Write-Host "   Locations:" -ForegroundColor Gray
        
        # Sort by last write time (newest first)
        $sortedFiles = $files | Sort-Object LastWriteTime -Descending
        
        $fileNumber = 1
        foreach ($file in $sortedFiles) {
            $fileSizeMB = [math]::Round($file.Length / 1MB, 2)
            $relativePath = $file.FullName.Replace((Get-Location).Path + "\", "")
            $modified = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm")
            
            Write-Host "   $fileNumber. ${fileSizeMB} MB - $relativePath" -ForegroundColor Gray
            Write-Host "      Modified: $modified" -ForegroundColor DarkGray
            
            $fileNumber++
        }
        
        # Recommendation for this group
        Write-Host "   RECOMMENDATION: Keep newest file (#1), delete others" -ForegroundColor Green
        
        $groupNumber++
    }
} else {
    Write-Host "No duplicate files found (all files have unique names)" -ForegroundColor Green
}
Write-Host ""

# Show all unique files
Write-Host "ALL FILES FOUND:" -ForegroundColor Yellow
$fileNumber = 1
foreach ($file in $uniqueFiles | Sort-Object LastWriteTime -Descending) {
    $fileSizeMB = [math]::Round($file.Length / 1MB, 2)
    $relativePath = $file.FullName.Replace((Get-Location).Path + "\", "")
    $modified = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm")
    
    Write-Host "$fileNumber. $fileName (${fileSizeMB} MB)" -ForegroundColor Gray
    Write-Host "   Path: $relativePath" -ForegroundColor DarkGray
    Write-Host "   Modified: $modified" -ForegroundColor DarkGray
    
    $fileNumber++
}
Write-Host ""

# Create cleanup script
Write-Host "CREATING CLEANUP SCRIPT..." -ForegroundColor Yellow
$cleanupScript = @'
# Cleanup Qwen3.5-35B-A3B-Q4_0 Duplicate Files
param(
    [switch]$Preview,
    [switch]$Force,
    [string]$KeepStrategy = "Newest"  # Newest, Oldest, Largest, Smallest
)

Write-Host "=== CLEANING QWEN3.5-35B-A3B-Q4_0 DUPLICATE FILES ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "Mode: $(if ($Preview) {'PREVIEW'} else {'EXECUTION'})" -ForegroundColor $(if ($Preview) {"Yellow"} else {"Red"})
Write-Host "Keep strategy: $KeepStrategy" -ForegroundColor Gray
Write-Host ""

# Create backup directory
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupDir = "qwen-cleanup-backup-$timestamp"
if (-not $Preview) {
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    Write-Host "Backup directory created: $backupDir" -ForegroundColor Green
}
Write-Host ""

# Search for Qwen files
$searchPatterns = @("*Qwen3.5-35B-A3B-Q4_0*", "*qwen3.5-35b-a3b-q4_0*")
$allFiles = @()

foreach ($pattern in $searchPatterns) {
    $files = Get-ChildItem -Path . -Filter $pattern -Recurse -ErrorAction SilentlyContinue -Force
    $allFiles += $files
}

$uniqueFiles = $allFiles | Sort-Object FullName -Unique

if ($uniqueFiles.Count -eq 0) {
    Write-Host "No Qwen files found to clean up." -ForegroundColor Yellow
    exit 0
}

# Group by filename
$fileGroups = @{}
foreach ($file in $uniqueFiles) {
    $fileName = $file.Name
    if (-not $fileGroups.ContainsKey($fileName)) {
        $fileGroups[$fileName] = @()
    }
    $fileGroups[$fileName] += $file
}

# Process each group
$totalDeleted = 0
$totalFreedMB = 0
$groupsProcessed = 0

foreach ($fileName in $fileGroups.Keys) {
    $files = $fileGroups[$fileName]
    
    if ($files.Count -eq 1) {
        # Single file, keep it
        continue
    }
    
    $groupsProcessed++
    Write-Host "Processing group: $fileName" -ForegroundColor Yellow
    Write-Host "   Files in group: $($files.Count)" -ForegroundColor Gray
    
    # Sort files based on strategy
    switch ($KeepStrategy) {
        "Newest" {
            $sortedFiles = $files | Sort-Object LastWriteTime -Descending
            $fileToKeep = $sortedFiles[0]
        }
        "Oldest" {
            $sortedFiles = $files | Sort-Object LastWriteTime
            $fileToKeep = $sortedFiles[0]
        }
        "Largest" {
            $sortedFiles = $files | Sort-Object Length -Descending
            $fileToKeep = $sortedFiles[0]
        }
        "Smallest" {
            $sortedFiles = $files | Sort-Object Length
            $fileToKeep = $sortedFiles[0]
        }
        default {
            $sortedFiles = $files | Sort-Object LastWriteTime -Descending
            $fileToKeep = $sortedFiles[0]
        }
    }
    
    Write-Host "   Keeping: $($fileToKeep.FullName)" -ForegroundColor Green
    Write-Host "   Strategy: $KeepStrategy" -ForegroundColor Gray
    Write-Host ""
    
    # Files to delete
    $filesToDelete = $files | Where-Object { $_.FullName -ne $fileToKeep.FullName }
    
    foreach ($file in $filesToDelete) {
        $fileSizeMB = [math]::Round($file.Length / 1MB, 2)
        
        if ($Preview) {
            Write-Host "   [PREVIEW] Would delete: $($file.FullName)" -ForegroundColor Gray
            Write-Host "             Size: ${fileSizeMB} MB" -ForegroundColor DarkGray
        } else {
            # Backup before deletion
            $backupPath = Join-Path $backupDir $file.Name
            try {
                Copy-Item -Path $file.FullName -Destination $backupPath -Force -ErrorAction SilentlyContinue
            } catch {
                Write-Host "   [WARNING] Could not backup: $($file.FullName)" -ForegroundColor Yellow
            }
            
            # Delete file
            try {
                Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
                Write-Host "   [DELETED] $($file.FullName)" -ForegroundColor Green
                Write-Host "            Size: ${fileSizeMB} MB" -ForegroundColor DarkGray
                $totalDeleted++
                $totalFreedMB += $fileSizeMB
            } catch {
                Write-Host "   [ERROR] Could not delete: $($file.FullName)" -ForegroundColor Red
            }
        }
    }
    
    Write-Host ""
}

# Summary
Write-Host "=== CLEANUP SUMMARY ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

if ($groupsProcessed -eq 0) {
    Write-Host "No duplicate groups found to process." -ForegroundColor Green
} else {
    Write-Host "Groups processed: $groupsProcessed" -ForegroundColor Gray
    Write-Host "Files deleted: $totalDeleted" -ForegroundColor $(if ($totalDeleted -gt 0) {"Green"} else {"Gray"})
    Write-Host "Space freed: ${totalFreedMB} MB" -ForegroundColor $(if ($totalFreedMB -gt 0) {"Green"} else {"Gray"})
    
    if (-not $Preview) {
        Write-Host "Backup directory: $backupDir" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "Cleanup completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray

if ($Preview) {
    Write-Host ""
    Write-Host "To execute cleanup, run:" -ForegroundColor Yellow
    Write-Host "   .\$($MyInvocation.MyCommand.Name) -Force" -ForegroundColor Gray
}
'@

$cleanupScriptPath = "cleanup-qwen-duplicates.ps1"
$cleanupScript | Set-Content $cleanupScriptPath -Encoding UTF8
Write-Host "   Cleanup script created: $cleanupScriptPath" -ForegroundColor Green
Write-Host ""

# Create batch file for easy execution
$batchContent = @'
@echo off
echo ========================================
echo   QWEN3.5-35B-A3B-Q4_0 DUPLICATE CLEANUP
echo ========================================
echo.
echo Options:
echo   1. Preview cleanup (safe, no deletion)
echo   2. Execute cleanup (delete duplicates)
echo   3. Custom cleanup strategy
echo   4. Exit
echo.

set /p choice="Enter choice (1-4): "

cd /d "%~dp0"

if "%choice%"=="1" (
    echo Running in PREVIEW mode...
    powershell -ExecutionPolicy Bypass -File "cleanup-qwen-duplicates.ps1" -Preview
) else if "%choice%"=="2" (
    echo WARNING: This will delete duplicate Qwen files!
    set /p confirm="Type 'YES' to confirm: "
    if "%confirm%"=="YES" (
        echo Executing cleanup...
        powershell -ExecutionPolicy Bypass -File "cleanup-qwen-duplicates.ps1" -Force
    ) else (
        echo Cleanup cancelled.
    )
) else if "%choice%"=="3" (
    echo Select keep strategy:
    echo   1. Keep newest file (default)
    echo   2. Keep oldest file
    echo   3. Keep largest file
    echo   4. Keep smallest file
    set /p strategy="Enter strategy (1-4): "
    
    if "%strategy%"=="1" ( set keep=newest )
    if "%strategy%"=="2" ( set keep=oldest )
    if "%strategy%"=="3" ( set keep=largest )
    if "%strategy%"=="4" ( set keep=smallest )
    
    echo.
    echo Options for strategy %keep%:
    echo   1. Preview
    echo   2. Execute
    set /p subchoice="Choice: "
    
    if "%subchoice%"=="1" (
        powershell -ExecutionPolicy Bypass -File "cleanup-qwen-duplicates.ps1" -Preview -KeepStrategy %keep%
    ) else if "%subchoice%"=="2" (
        echo WARNING: This will delete duplicate Qwen files!
        set /p confirm="Type 'YES' to confirm: "
        if "%confirm%"=="YES" (
            powershell -ExecutionPolicy Bypass -File "cleanup-qwen-duplicates.ps1" -Force -KeepStrategy %keep%
        ) else (
            echo Cleanup cancelled.
        )
    )
) else (
    echo Exiting.
)

echo.
pause
'@

$batchPath = "cleanup-qwen.bat"
$batchContent | Set-Content $batchPath -Encoding ASCII
Write-Host "   Batch file created: $batchPath" -ForegroundColor Green
Write-Host ""

# Instructions
Write-Host "INSTRUCTIONS:" -ForegroundColor Cyan
Write-Host "1. Run preview to see what will be deleted:" -ForegroundColor Gray
Write-Host "   .\cleanup-qwen.bat (select option 1)" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Execute cleanup to delete duplicates:" -ForegroundColor Gray
Write-Host "   .\cleanup-qwen.bat (select option 2, confirm with YES)" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Or run PowerShell directly:" -ForegroundColor Gray
Write-Host "   .\cleanup-qwen-duplicates.ps1 -Preview" -ForegroundColor Gray
Write-Host "   .\cleanup-qwen-duplicates.ps1 -Force" -ForegroundColor Gray
Write-Host ""

Write-Host "File search completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray