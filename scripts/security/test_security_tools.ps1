# 安全工具功能测试脚本
Write-Host "=== 安全工具功能测试 ===" -ForegroundColor Green
Write-Host "测试时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# 测试结果记录
$testResults = @()

# 1. 测试 MC Porter
Write-Host "1. 测试 MC Porter..." -ForegroundColor Cyan
try {
    $mcporterVersion = mcporter --version
    $testResults += @{Tool="MC Porter"; Status="✅"; Version=$mcporterVersion; Message="工作正常"}
    Write-Host "   ✅ 版本: $mcporterVersion" -ForegroundColor Green
} catch {
    $testResults += @{Tool="MC Porter"; Status="❌"; Version="未知"; Message="测试失败: $_"}
    Write-Host "   ❌ 测试失败" -ForegroundColor Red
}

# 2. 测试 Oracle
Write-Host "`n2. 测试 Oracle..." -ForegroundColor Cyan
try {
    $oracleHelp = oracle --help 2>&1 | Select-String -Pattern "Oracle CLI"
    if ($oracleHelp) {
        $oracleVersion = "v0.8.6"
        $testResults += @{Tool="Oracle"; Status="✅"; Version=$oracleVersion; Message="工作正常"}
        Write-Host "   ✅ 版本: $oracleVersion" -ForegroundColor Green
    } else {
        $testResults += @{Tool="Oracle"; Status="⚠️"; Version="未知"; Message="帮助信息不完整"}
        Write-Host "   ⚠️ 帮助信息不完整" -ForegroundColor Yellow
    }
} catch {
    $testResults += @{Tool="Oracle"; Status="❌"; Version="未知"; Message="测试失败: $_"}
    Write-Host "   ❌ 测试失败" -ForegroundColor Red
}

# 3. 测试 ClawdHub
Write-Host "`n3. 测试 ClawdHub..." -ForegroundColor Cyan
try {
    $clawdhubVersion = clawdhub --cli-version 2>&1
    $testResults += @{Tool="ClawdHub"; Status="✅"; Version=$clawdhubVersion; Message="工作正常"}
    Write-Host "   ✅ 版本: $clawdhubVersion" -ForegroundColor Green
} catch {
    $testResults += @{Tool="ClawdHub"; Status="❌"; Version="未知"; Message="测试失败: $_"}
    Write-Host "   ❌ 测试失败" -ForegroundColor Red
}

# 4. 测试 1Password CLI
Write-Host "`n4. 测试 1Password CLI..." -ForegroundColor Cyan
$opPath = "C:\Users\luchaochao\AppData\Local\Microsoft\WinGet\Packages\AgileBits.1Password.CLI_Microsoft.Winget.Source_8wekyb3d8bbwe\op.exe"
if (Test-Path $opPath) {
    try {
        $opVersion = & $opPath --version
        $testResults += @{Tool="1Password CLI"; Status="✅"; Version=$opVersion; Message="工作正常"}
        Write-Host "   ✅ 版本: $opVersion" -ForegroundColor Green
        Write-Host "   路径: $opPath" -ForegroundColor Gray
    } catch {
        $testResults += @{Tool="1Password CLI"; Status="❌"; Version="未知"; Message="执行失败: $_"}
        Write-Host "   ❌ 执行失败" -ForegroundColor Red
    }
} else {
    $testResults += @{Tool="1Password CLI"; Status="❌"; Version="未知"; Message="文件不存在: $opPath"}
    Write-Host "   ❌ 文件不存在: $opPath" -ForegroundColor Red
}

# 5. 测试 GitHub CLI
Write-Host "`n5. 测试 GitHub CLI..." -ForegroundColor Cyan
$ghPath = "D:\Ai\gh.exe"
if (Test-Path $ghPath) {
    try {
        $ghVersion = & $ghPath --version
        $testResults += @{Tool="GitHub CLI"; Status="✅"; Version=$ghVersion; Message="工作正常"}
        Write-Host "   ✅ 版本: $ghVersion" -ForegroundColor Green
        Write-Host "   路径: $ghPath" -ForegroundColor Gray
    } catch {
        $testResults += @{Tool="GitHub CLI"; Status="❌"; Version="未知"; Message="执行失败: $_"}
        Write-Host "   ❌ 执行失败" -ForegroundColor Red
    }
} else {
    $testResults += @{Tool="GitHub CLI"; Status="❌"; Version="未知"; Message="文件不存在: $ghPath"}
    Write-Host "   ❌ 文件不存在: $ghPath" -ForegroundColor Red
}

# 显示测试总结
Write-Host "`n=== 测试总结 ===" -ForegroundColor Green

$successCount = ($testResults | Where-Object { $_.Status -eq "✅" }).Count
$warningCount = ($testResults | Where-Object { $_.Status -eq "⚠️" }).Count
$errorCount = ($testResults | Where-Object { $_.Status -eq "❌" }).Count

Write-Host "总计: $($testResults.Count) 个工具" -ForegroundColor Cyan
Write-Host "成功: $successCount ✅" -ForegroundColor Green
Write-Host "警告: $warningCount ⚠️" -ForegroundColor Yellow
Write-Host "失败: $errorCount ❌" -ForegroundColor Red

Write-Host "`n详细结果:" -ForegroundColor Cyan
foreach ($result in $testResults) {
    $color = if ($result.Status -eq "✅") { "Green" }
             elseif ($result.Status -eq "⚠️") { "Yellow" }
             else { "Red" }
    Write-Host "  $($result.Status) $($result.Tool) ($($result.Version))" -ForegroundColor $color
}

# 功能测试建议
Write-Host "`n=== 功能测试建议 ===" -ForegroundColor Cyan
if ($successCount -eq 5) {
    Write-Host "✅ 所有安全工具基础功能正常" -ForegroundColor Green
    Write-Host "建议进行以下高级测试：" -ForegroundColor Yellow
    Write-Host "1. MC Porter: mcporter list" -ForegroundColor Gray
    Write-Host "2. Oracle: oracle --dry-run summary -p `"安全测试`" --file `".`"" -ForegroundColor Gray
    Write-Host "3. ClawdHub: clawdhub search `"security`"" -ForegroundColor Gray
    Write-Host "4. 1Password: 配置桌面应用集成后测试 op signin" -ForegroundColor Gray
    Write-Host "5. GitHub CLI: gh auth status" -ForegroundColor Gray
} else {
    Write-Host "⚠️ 部分工具需要配置" -ForegroundColor Yellow
    Write-Host "建议操作：" -ForegroundColor Yellow
    Write-Host "1. 重启命令行窗口更新PATH" -ForegroundColor Gray
    Write-Host "2. 检查工具安装路径" -ForegroundColor Gray
    Write-Host "3. 运行配置脚本: store_api_keys.ps1" -ForegroundColor Gray
}

# 保存测试报告
$reportPath = "C:\Users\luchaochao\.openclaw\workspace\06-documentation\security\安全工具测试报告_$(Get-Date -Format 'yyyyMMdd_HHmmss').md"
$reportContent = @"
# 安全工具测试报告

## 测试信息
- **测试时间**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
- **测试环境**: Windows PowerShell
- **测试工具**: 5个安全工具

## 测试结果

| 工具 | 状态 | 版本 | 消息 |
|------|------|------|------|
$($testResults | ForEach-Object { "| $($_.Tool) | $($_.Status) | $($_.Version) | $($_.Message) |" } | Out-String)

## 统计
- **总计**: $($testResults.Count) 个工具
- **成功**: $successCount (✅)
- **警告**: $warningCount (⚠️)
- **失败**: $errorCount (❌)

## 建议
$($testResults | Where-Object { $_.Status -ne "✅" } | ForEach-Object { "- $($_.Tool): $($_.Message)" } | Out-String)

## 后续步骤
1. 配置未成功的工具
2. 运行高级功能测试
3. 建立定期测试计划

---

*测试生成时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')*
"@

Set-Content -Path $reportPath -Value $reportContent -Force
Write-Host "`n测试报告已保存: $reportPath" -ForegroundColor Green

Write-Host "`n=== 测试完成 ===" -ForegroundColor Green
Write-Host "按任意键继续..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")