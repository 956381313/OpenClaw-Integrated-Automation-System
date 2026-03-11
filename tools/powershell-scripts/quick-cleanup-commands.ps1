# Quick Cleanup Commands

Write-Host "=== Quick Workspace Cleanup Commands ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "1. View organization report:" -ForegroundColor Yellow
Write-Host "   Get-ChildItem organization-report-*.md | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | Get-Content" -ForegroundColor Gray
Write-Host ""

Write-Host "2. View cleanup report:" -ForegroundColor Yellow
Write-Host "   Get-ChildItem data/reports\*.md | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | Get-Content" -ForegroundColor Gray
Write-Host ""

Write-Host "3. Safe duplicate check (preview):" -ForegroundColor Yellow
Write-Host "   Get-ChildItem modules/backup/data -Recurse -File | Group-Object Name | Where-Object Count -gt 1 | Select-Object -First 5" -ForegroundColor Gray
Write-Host ""

Write-Host "4. Remove old backups (preview - use -WhatIf first):" -ForegroundColor Yellow
Write-Host "   # Keep only latest 5 backups" -ForegroundColor Gray
Write-Host "   Get-ChildItem modules/backup/data -Directory | Sort-Object LastWriteTime -Descending | Select-Object -Skip 5 | Remove-Item -Recurse -WhatIf" -ForegroundColor Gray
Write-Host ""

Write-Host "5. Clean empty directories (preview):" -ForegroundColor Yellow
Write-Host "   Get-ChildItem -Recurse -Directory | Where-Object { (Get-ChildItem $_.FullName).Count -eq 0 } | Remove-Item -WhatIf" -ForegroundColor Gray
Write-Host ""

Write-Host "IMPORTANT: Always use -WhatIf flag first to preview changes!" -ForegroundColor Red
Write-Host "Example: Remove-Item file.txt -WhatIf" -ForegroundColor Gray

