# 删除备份文件夹的专用脚本
$ErrorActionPreference = "Stop"

function Remove-LongPathFolder {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        Write-Host "Path does not exist: $Path"
        return
    }
    
    Write-Host "Processing: $Path"
    
    # 方法1: 使用robocopy镜像删除
    $emptyDir = Join-Path $env:TEMP "empty-$(Get-Random)"
    New-Item -ItemType Directory -Path $emptyDir -Force | Out-Null
    
    try {
        robocopy $emptyDir $Path /MIR /NJH /NJS /NP /NS /NC /NDL /NFL /R:1 /W:1 2>&1 | Out-Null
    } catch {
        Write-Host "Robocopy failed, trying other methods..."
    }
    
    # 清理临时目录
    Remove-Item -Path $emptyDir -Recurse -Force -ErrorAction SilentlyContinue
    
    # 方法2: 使用PowerShell删除
    try {
        Remove-Item -Path $Path -Recurse -Force -ErrorAction Stop
        Write-Host "Successfully deleted: $Path"
    } catch {
        Write-Host "PowerShell delete failed, trying cmd..."
        # 方法3: 使用cmd删除
        $result = cmd /c "rd /s /q `"$Path`" 2>&1"
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Successfully deleted with cmd: $Path"
        } else {
            Write-Host "All deletion methods failed for: $Path"
            Write-Host "Error: $result"
        }
    }
}

# 要删除的文件夹
$backupFolders = @(
    "english-reorg-backup-20260306-234623",
    "pre-architecture-backup-20260306-172408"
)

foreach ($folder in $backupFolders) {
    if (Test-Path $folder) {
        Remove-LongPathFolder -Path $folder
    } else {
        Write-Host "Folder not found: $folder"
    }
}

Write-Host "`nCleanup complete!"
