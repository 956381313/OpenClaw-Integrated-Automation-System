# Auto Delete on Startup
# This script runs automatically after system restart

$logFile = "C:\Users\luchaochao\.openclaw\workspace\delete-log.txt"
$targetFolder = "C:\Users\luchaochao\.openclaw\workspace\pre-architecture-backup-20260306-172408"

# Start logging
"=== Auto Delete Started ===" | Out-File $logFile -Encoding UTF8
"Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File $logFile -Encoding UTF8 -Append
"Target: $targetFolder" | Out-File $logFile -Encoding UTF8 -Append
"" | Out-File $logFile -Encoding UTF8 -Append

if (Test-Path $targetFolder) {
    "Folder exists, attempting deletion..." | Out-File $logFile -Encoding UTF8 -Append
    
    # Method 1: Simple rd command
    "Trying rd command..." | Out-File $logFile -Encoding UTF8 -Append
    $output1 = cmd /c "rd /s /q `"$targetFolder`" 2>&1"
    "Output: $output1" | Out-File $logFile -Encoding UTF8 -Append
    Start-Sleep -Seconds 3
    
    if (-not (Test-Path $targetFolder)) {
        "SUCCESS: Deleted with rd command" | Out-File $logFile -Encoding UTF8 -Append
        "Status: DELETED" | Out-File $logFile -Encoding UTF8 -Append
    } else {
        "rd command failed, trying PowerShell..." | Out-File $logFile -Encoding UTF8 -Append
        
        # Method 2: PowerShell
        Remove-Item -Path $targetFolder -Recurse -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 3
        
        if (-not (Test-Path $targetFolder)) {
            "SUCCESS: Deleted with PowerShell" | Out-File $logFile -Encoding UTF8 -Append
            "Status: DELETED" | Out-File $logFile -Encoding UTF8 -Append
        } else {
            "FAILED: Both methods failed" | Out-File $logFile -Encoding UTF8 -Append
            "Status: STILL EXISTS" | Out-File $logFile -Encoding UTF8 -Append
            "Recommendation: Try Safe Mode deletion" | Out-File $logFile -Encoding UTF8 -Append
        }
    }
} else {
    "Folder does not exist - already deleted!" | Out-File $logFile -Encoding UTF8 -Append
    "Status: ALREADY DELETED" | Out-File $logFile -Encoding UTF8 -Append
}

# Final status
"" | Out-File $logFile -Encoding UTF8 -Append
"=== Auto Delete Completed ===" | Out-File $logFile -Encoding UTF8 -Append
"Completion Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File $logFile -Encoding UTF8 -Append

# Show brief result
if (Test-Path $targetFolder) {
    Write-Host "Auto Delete: FAILED - Folder still exists"
    Write-Host "Check log file: $logFile"
} else {
    Write-Host "Auto Delete: SUCCESS - Folder deleted"
    Write-Host "Log saved to: $logFile"
}