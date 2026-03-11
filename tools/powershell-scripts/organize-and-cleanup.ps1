# OpenClaw Organize and Cleanup Script (English)
# Version: 2.0.0
# Description: Combined repository organization and automatic cleanup
# Author: Hell Cat (Digital Ghost Assistant)
# Date: 2026-03-06

# Configuration
$WorkspacePath = "C:\Users\luchaochao\.openclaw\workspace"
$ReportsDir = "organize-data/reports"
$LogsDir = "organize-cleanup-logs"
$BackupRetentionDays = 7
$MaxBackupsToKeep = 10

# Create directories if they don't exist
if (-not (Test-Path "$WorkspacePath\$ReportsDir")) {
    New-Item -ItemType Directory -Path "$WorkspacePath\$ReportsDir" -Force | Out-Null
}
if (-not (Test-Path "$WorkspacePath\$LogsDir")) {
    New-Item -ItemType Directory -Path "$WorkspacePath\$LogsDir" -Force | Out-Null
}

# Timestamp for this run
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$LogFile = "$WorkspacePath\$LogsDir\organize-cleanup-log-$Timestamp.txt"
$ReportFile = "$WorkspacePath\$ReportsDir\organize-cleanup-report-$Timestamp.md"
$JsonReportFile = "$WorkspacePath\$ReportsDir\organize-cleanup-report-$Timestamp.json"

# Start logging
Start-Transcript -Path $LogFile -Append
Write-Host "=== OpenClaw Organize and Cleanup Script ===" -ForegroundColor Cyan
Write-Host "Start Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "Workspace: $WorkspacePath"
Write-Host ""

# Function: Get file statistics
function Get-FileStatistics {
    param([string]$Path)
    
    $stats = @{
        TotalFiles = 0
        TotalSizeMB = 0
        ByExtension = @{}
        ByType = @{
            Documents = 0
            Scripts = 0
            Configs = 0
            Logs = 0
            Images = 0
            Archives = 0
            Other = 0
        }
    }
    
    $files = Get-ChildItem -Path $Path -File -Recurse -ErrorAction SilentlyContinue
    
    foreach ($file in $files) {
        $stats.TotalFiles++
        $stats.TotalSizeMB += [math]::Round($file.Length / 1MB, 2)
        
        # Count by extension
        $ext = $file.Extension.ToLower()
        if ($stats.ByExtension.ContainsKey($ext)) {
            $stats.ByExtension[$ext]++
        } else {
            $stats.ByExtension[$ext] = 1
        }
        
        # Classify by type
        switch ($ext) {
            {$_ -in '.md', '.txt', '.pdf', '.doc', '.docx', '.rtf'} {
                $stats.ByType.Documents++
            }
            {$_ -in '.ps1', '.bat', '.cmd', '.sh', '.js', '.py'} {
                $stats.ByType.Scripts++
            }
            {$_ -in '.json', '.yml', '.yaml', '.xml', '.config', '.ini'} {
                $stats.ByType.Configs++
            }
            {$_ -in '.log', '.txt'} {
                $stats.ByType.Logs++
            }
            {$_ -in '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.svg'} {
                $stats.ByType.Images++
            }
            {$_ -in '.zip', '.rar', '.7z', '.tar', '.gz'} {
                $stats.ByType.Archives++
            }
            default {
                $stats.ByType.Other++
            }
        }
    }
    
    return $stats
}

# Function: Clean old backups
function Clean-OldBackups {
    param([string]$BackupPath)
    
    Write-Host "Cleaning old backups in: $BackupPath" -ForegroundColor Yellow
    
    $backupDirs = Get-ChildItem -Path $BackupPath -Directory -ErrorAction SilentlyContinue | 
                  Sort-Object LastWriteTime -Descending
    
    $totalBackups = $backupDirs.Count
    $backupsToKeep = [math]::Min($MaxBackupsToKeep, $totalBackups)
    $backupsToDelete = $totalBackups - $backupsToKeep
    
    if ($backupsToDelete -gt 0) {
        Write-Host "Found $totalBackups backups. Keeping $backupsToKeep, deleting $backupsToDelete" -ForegroundColor Yellow
        
        $deletedCount = 0
        $spaceSavedMB = 0
        
        for ($i = $backupsToKeep; $i -lt $totalBackups; $i++) {
            $dirToDelete = $backupDirs[$i]
            $sizeMB = [math]::Round((Get-ChildItem $dirToDelete.FullName -Recurse -File | Measure-Object Length -Sum).Sum / 1MB, 2)
            
            try {
                Remove-Item -Path $dirToDelete.FullName -Recurse -Force -ErrorAction Stop
                $deletedCount++
                $spaceSavedMB += $sizeMB
                Write-Host "  Deleted: $($dirToDelete.Name) (${sizeMB}MB)" -ForegroundColor Green
            } catch {
                Write-Host "  Failed to delete: $($dirToDelete.Name) - $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        
        return @{
            DeletedCount = $deletedCount
            SpaceSavedMB = $spaceSavedMB
            TotalBackups = $totalBackups
            KeptBackups = $backupsToKeep
        }
    } else {
        Write-Host "No old backups to clean (keeping all $totalBackups backups)" -ForegroundColor Green
        return @{
            DeletedCount = 0
            SpaceSavedMB = 0
            TotalBackups = $totalBackups
            KeptBackups = $totalBackups
        }
    }
}

# Function: Clean empty directories
function Clean-EmptyDirectories {
    param([string]$Path)
    
    Write-Host "Cleaning empty directories in: $Path" -ForegroundColor Yellow
    
    $emptyDirs = Get-ChildItem -Path $Path -Directory -Recurse -ErrorAction SilentlyContinue | 
                 Where-Object { (Get-ChildItem $_.FullName -Recurse -Force -ErrorAction SilentlyContinue).Count -eq 0 } |
                 Sort-Object FullName -Descending
    
    $deletedCount = 0
    
    foreach ($dir in $emptyDirs) {
        try {
            Remove-Item -Path $dir.FullName -Recurse -Force -ErrorAction Stop
            $deletedCount++
            Write-Host "  Deleted empty directory: $($dir.FullName.Replace($WorkspacePath, ''))" -ForegroundColor Green
        } catch {
            Write-Host "  Failed to delete empty directory: $($dir.FullName) - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    return @{
        DeletedCount = $deletedCount
        EmptyDirectories = $emptyDirs.Count
    }
}

# Function: Generate knowledge base
function Generate-KnowledgeBase {
    param([string]$Path, [string]$OutputPath)
    
    Write-Host "Generating knowledge base..." -ForegroundColor Yellow
    
    $knowledgeBase = @{
        Generated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Workspace = $WorkspacePath
        Files = @()
        Statistics = @{}
    }
    
    # Get important files
    $importantFiles = Get-ChildItem -Path $Path -File -Recurse -Include "*.md", "*.json", "*.ps1", "*.bat" -ErrorAction SilentlyContinue |
                      Where-Object { $_.Name -match "README|AGENTS|IDENTITY|SOUL|USER|TOOLS|MEMORY|FINAL|TODO|GUIDE|REPORT" } |
                      Sort-Object LastWriteTime -Descending |
                      Select-Object -First 50
    
    foreach ($file in $importantFiles) {
        $fileInfo = @{
            Name = $file.Name
            Path = $file.FullName.Replace($WorkspacePath, "")
            SizeKB = [math]::Round($file.Length / 1KB, 2)
            LastModified = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
            Type = $file.Extension.ToLower()
        }
        
        $knowledgeBase.Files += $fileInfo
    }
    
    # Save knowledge base
    $knowledgeBase | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
    
    Write-Host "Knowledge base generated: $OutputPath" -ForegroundColor Green
    return @{
        FilesIncluded = $importantFiles.Count
        OutputPath = $OutputPath
    }
}

# Main execution
try {
    Write-Host "Step 1: Analyzing workspace..." -ForegroundColor Cyan
    $stats = Get-FileStatistics -Path $WorkspacePath
    
    Write-Host "Step 2: Cleaning old backups..." -ForegroundColor Cyan
    $backupCleanupResults = @{}
    
    # Clean different backup directories
    $backupDirs = @(
        "$WorkspacePath\modules/backup/data",
        "$WorkspacePath\backups/system",
        "$WorkspacePath\services/github/cloud-backup\simple-backups",
        "$WorkspacePath\services/github/cloud-backup\backups"
    )
    
    foreach ($backupDir in $backupDirs) {
        if (Test-Path $backupDir) {
            $results = Clean-OldBackups -BackupPath $backupDir
            $backupCleanupResults[$backupDir] = $results
        }
    }
    
    Write-Host "Step 3: Cleaning empty directories..." -ForegroundColor Cyan
    $emptyDirResults = Clean-EmptyDirectories -Path $WorkspacePath
    
    Write-Host "Step 4: Generating knowledge base..." -ForegroundColor Cyan
    $kbPath = "$WorkspacePath\$ReportsDir\knowledge-base-$Timestamp.json"
    $kbResults = Generate-KnowledgeBase -Path $WorkspacePath -OutputPath $kbPath
    
    # Calculate total space saved
    $totalSpaceSavedMB = 0
    foreach ($result in $backupCleanupResults.Values) {
        $totalSpaceSavedMB += $result.SpaceSavedMB
    }
    
    # Prepare report data
    $reportData = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Workspace = $WorkspacePath
        FileStatistics = $stats
        BackupCleanup = $backupCleanupResults
        EmptyDirectoryCleanup = $emptyDirResults
        KnowledgeBase = $kbResults
        Summary = @{
            TotalFiles = $stats.TotalFiles
            TotalSizeMB = $stats.TotalSizeMB
            TotalSpaceSavedMB = $totalSpaceSavedMB
            TotalBackupsDeleted = ($backupCleanupResults.Values | Measure-Object -Property DeletedCount -Sum).Sum
            EmptyDirectoriesDeleted = $emptyDirResults.DeletedCount
            ExecutionTime = ""
        }
    }
    
    # Save JSON report
    $reportData | ConvertTo-Json -Depth 10 | Out-File -FilePath $JsonReportFile -Encoding UTF8
    
    # Generate human-readable report
    $reportContent = @"
# OpenClaw 浠撳簱鏁寸悊涓庤嚜鍔ㄦ竻鐞嗘姤鍛?## 鏃堕棿: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
## 宸ヤ綔绌洪棿: $WorkspacePath

## 馃搳 鏂囦欢缁熻
- **鎬绘枃浠舵暟**: $($stats.TotalFiles) 涓枃浠?- **鎬诲ぇ灏?*: $($stats.TotalSizeMB) MB

### 鏂囦欢绫诲瀷鍒嗗竷:
- 馃搫 鏂囨。鏂囦欢: $($stats.ByType.Documents) 涓?- 馃摐 鑴氭湰鏂囦欢: $($stats.ByType.Scripts) 涓?- 鈿欙笍 閰嶇疆鏂囦欢: $($stats.ByType.Configs) 涓?- 馃搵 鏃ュ織鏂囦欢: $($stats.ByType.Logs) 涓?- 馃柤锔?鍥剧墖鏂囦欢: $($stats.ByType.Images) 涓?- 馃摝 鍘嬬缉鏂囦欢: $($stats.ByType.Archives) 涓?- 馃敡 鍏朵粬鏂囦欢: $($stats.ByType.Other) 涓?
## 馃Ч 娓呯悊缁撴灉

### 澶囦唤娓呯悊:
"@
    
    foreach ($backupDir in $backupCleanupResults.Keys) {
        $result = $backupCleanupResults[$backupDir]
        $reportContent += @"
- **$(Split-Path $backupDir -Leaf)**:
  - 鎬诲浠芥暟: $($result.TotalBackups) 涓?  - 淇濈暀澶囦唤: $($result.KeptBackups) 涓?  - 鍒犻櫎澶囦唤: $($result.DeletedCount) 涓?  - 鑺傜渷绌洪棿: $($result.SpaceSavedMB) MB

"@
    }
    
    $reportContent += @"
### 绌虹洰褰曟竻鐞?
- 鍒犻櫎绌虹洰褰? $($emptyDirResults.DeletedCount) 涓?- 鍙戠幇绌虹洰褰? $($emptyDirResults.EmptyDirectories) 涓?
## 馃 鐭ヨ瘑搴撶敓鎴?- 鍖呭惈鏂囦欢: $($kbResults.FilesIncluded) 涓噸瑕佹枃浠?- 杈撳嚭璺緞: $($kbResults.OutputPath.Replace($WorkspacePath, ''))

## 馃搱 鎬荤粨
- 鉁?鎬昏妭鐪佺┖闂? ${totalSpaceSavedMB} MB
- 鉁?鎬诲垹闄ゅ浠? $(($backupCleanupResults.Values | Measure-Object -Property DeletedCount -Sum).Sum) 涓?- 鉁?鍒犻櫎绌虹洰褰? $($emptyDirResults.DeletedCount) 涓?- 鉁?鐭ヨ瘑搴撴洿鏂? 瀹屾垚

## 鈿狅笍 寤鸿
1. **瀹氭湡杩愯**姝よ剼鏈互淇濇寔宸ヤ綔绌洪棿鏁存磥
2. **妫€鏌ュ浠界瓥鐣?*锛岀‘淇濋噸瑕佹暟鎹畨鍏?3. **鐩戞帶纾佺洏绌洪棿**锛屽強鏃舵竻鐞嗕笉闇€瑕佺殑鏂囦欢

## 馃搧 鐢熸垚鐨勬枃浠?1. 璇︾粏鏃ュ織: $LogFile.Replace($WorkspacePath, '')
2. JSON鎶ュ憡: $JsonReportFile.Replace($WorkspacePath, '')
3. 鐭ヨ瘑搴? $kbPath.Replace($WorkspacePath, '')

---
*OpenClaw 浠撳簱鏁寸悊涓庤嚜鍔ㄦ竻鐞嗙郴缁?v2.0*
*鎵ц瀹屾垚鏃堕棿: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')*
"@
    
    # Save report
    $reportContent | Out-File -FilePath $ReportFile -Encoding UTF8
    
    Write-Host "`n=== Execution Summary ===" -ForegroundColor Green
    Write-Host "Total files analyzed: $($stats.TotalFiles)" -ForegroundColor White
    Write-Host "Total size: $($stats.TotalSizeMB) MB" -ForegroundColor White
    Write-Host "Space saved: ${totalSpaceSavedMB} MB" -ForegroundColor Green
    Write-Host "Backups deleted: $(($backupCleanupResults.Values | Measure-Object -Property DeletedCount -Sum).Sum)" -ForegroundColor Green
    Write-Host "Empty directories deleted: $($emptyDirResults.DeletedCount)" -ForegroundColor Green
    Write-Host "Knowledge base updated: $($kbResults.FilesIncluded) files" -ForegroundColor Green
    Write-Host "Reports generated: 3 files" -ForegroundColor Green
    Write-Host "`nExecution completed successfully!" -ForegroundColor Cyan
    
} catch {
    Write-Host "Error during execution: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    exit 1
} finally {
    Stop-Transcript
}

Write-Host "`nLog file: $LogFile" -ForegroundColor Gray
Write-Host "Report file: $ReportFile" -ForegroundColor Gray
Write-Host "JSON report: $JsonReportFile" -ForegroundColor Gray
