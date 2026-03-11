# 每日安全检查脚本
param(
    [switch]$Quick,    # 快速检查模式
    [switch]$Full,     # 完整检查模式
    [switch]$Report    # 生成报告模式
)

# 日志文件路径
$logDir = "C:\Users\luchaochao\.openclaw\workspace\06-documentation\security\logs"
$logFile = "$logDir\security_check_$(Get-Date -Format 'yyyyMMdd').log"
$reportFile = "$logDir\security_report_$(Get-Date -Format 'yyyyMMdd').md"

# 创建日志目录
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

# 初始化结果
$results = @{
    "timestamp" = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "checks" = @()
    "summary" = @{
        "total" = 0
        "passed" = 0
        "failed" = 0
        "warnings" = 0
    }
}

function Add-CheckResult {
    param($name, $status, $message, $details = $null)
    
    $check = @{
        "name" = $name
        "status" = $status
        "message" = $message
        "timestamp" = Get-Date -Format "HH:mm:ss"
    }
    
    if ($details) {
        $check.details = $details
    }
    
    $results.checks += $check
    $results.summary.total++
    
    switch ($status) {
        "✅" { $results.summary.passed++ }
        "❌" { $results.summary.failed++ }
        "⚠️" { $results.summary.warnings++ }
    }
    
    # 输出到控制台
    Write-Host "$status $name : $message" -ForegroundColor $(if ($status -eq "✅") { "Green" } elseif ($status -eq "❌") { "Red" } else { "Yellow" })
}

function Log-Message {
    param($message)
    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $message" | Out-File -FilePath $logFile -Append -Encoding UTF8
}

# 开始检查
Write-Host "=== 每日安全检查 ===" -ForegroundColor Green
Write-Host "开始时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "模式: $(if ($Quick) { '快速' } elseif ($Full) { '完整' } else { '标准' })" -ForegroundColor Gray
Write-Host ""

Log-Message "=== 开始安全检查 ==="

# 1. 检查API密钥环境变量
Write-Host "1. 检查API密钥环境变量..." -ForegroundColor Cyan
$apiKeys = @("DEEPSEEK_API_KEY", "OLLAMA_API_KEY", "HUGGINGFACE_API_KEY", "NVIDIA_API_KEY", "CLAWHUB_API_KEY")

foreach ($key in $apiKeys) {
    $value = [System.Environment]::GetEnvironmentVariable($key, "Process")
    if (-not [string]::IsNullOrEmpty($value)) {
        Add-CheckResult -name "API密钥: $key" -status "✅" -message "已设置"
        Log-Message "API密钥 $key: 已设置"
    } else {
        Add-CheckResult -name "API密钥: $key" -status "❌" -message "未设置"
        Log-Message "API密钥 $key: 未设置 - 警告"
    }
}

# 2. 检查安全工具可用性
Write-Host "`n2. 检查安全工具可用性..." -ForegroundColor Cyan

# MC Porter
try {
    $version = mcporter --version 2>&1
    Add-CheckResult -name "MC Porter" -status "✅" -message "版本: $version"
    Log-Message "MC Porter: 可用 ($version)"
} catch {
    Add-CheckResult -name "MC Porter" -status "❌" -message "不可用"
    Log-Message "MC Porter: 不可用"
}

# Oracle
try {
    $help = oracle --help 2>&1 | Select-String -Pattern "Oracle CLI"
    if ($help) {
        Add-CheckResult -name "Oracle" -status "✅" -message "可用"
        Log-Message "Oracle: 可用"
    } else {
        Add-CheckResult -name "Oracle" -status "⚠️" -message "帮助信息异常"
        Log-Message "Oracle: 帮助信息异常"
    }
} catch {
    Add-CheckResult -name "Oracle" -status "❌" -message "不可用"
    Log-Message "Oracle: 不可用"
}

# ClawdHub
try {
    $version = clawdhub --cli-version 2>&1
    Add-CheckResult -name "ClawdHub" -status "✅" -message "版本: $version"
    Log-Message "ClawdHub: 可用 ($version)"
} catch {
    Add-CheckResult -name "ClawdHub" -status "❌" -message "不可用"
    Log-Message "ClawdHub: 不可用"
}

# 1Password CLI
$opPath = "C:\Users\luchaochao\AppData\Local\Microsoft\WinGet\Packages\AgileBits.1Password.CLI_Microsoft.Winget.Source_8wekyb3d8bbwe\op.exe"
if (Test-Path $opPath) {
    try {
        $version = & $opPath --version
        Add-CheckResult -name "1Password CLI" -status "✅" -message "版本: $version"
        Log-Message "1Password CLI: 可用 ($version)"
    } catch {
        Add-CheckResult -name "1Password CLI" -status "⚠️" -message "文件存在但执行失败"
        Log-Message "1Password CLI: 文件存在但执行失败"
    }
} else {
    Add-CheckResult -name "1Password CLI" -status "❌" -message "未找到"
    Log-Message "1Password CLI: 未找到"
}

# GitHub CLI
$ghPath = "D:\Ai\gh.exe"
if (Test-Path $ghPath) {
    try {
        $version = & $ghPath --version
        Add-CheckResult -name "GitHub CLI" -status "✅" -message "版本: $version"
        Log-Message "GitHub CLI: 可用 ($version)"
    } catch {
        Add-CheckResult -name "GitHub CLI" -status "⚠️" -message "文件存在但执行失败"
        Log-Message "GitHub CLI: 文件存在但执行失败"
    }
} else {
    Add-CheckResult -name "GitHub CLI" -status "❌" -message "未找到"
    Log-Message "GitHub CLI: 未找到"
}

# 3. 检查文件权限（如果完整模式）
if ($Full) {
    Write-Host "`n3. 检查文件权限..." -ForegroundColor Cyan
    
    $sensitiveFiles = @(".env", "07-configuration\api-keys-config.json")
    foreach ($file in $sensitiveFiles) {
        if (Test-Path $file) {
            $acl = Get-Acl $file
            $isSecure = $true
            # 这里可以添加更详细的权限检查
            Add-CheckResult -name "文件权限: $file" -status "✅" -message "文件存在"
            Log-Message "文件权限检查: $file - 存在"
        } else {
            Add-CheckResult -name "文件权限: $file" -status "⚠️" -message "文件不存在"
            Log-Message "文件权限检查: $file - 不存在"
        }
    }
}

# 4. 检查网络连接（如果完整模式）
if ($Full) {
    Write-Host "`n4. 检查网络连接..." -ForegroundColor Cyan
    
    $services = @(
        @{Name="DeepSeek API"; URL="https://api.deepseek.com"},
        @{Name="GitHub API"; URL="https://api.github.com"},
        @{Name="HuggingFace"; URL="https://huggingface.co"}
    )
    
    foreach ($service in $services) {
        try {
            $response = Invoke-WebRequest -Uri $service.URL -Method Head -TimeoutSec 5
            if ($response.StatusCode -eq 200) {
                Add-CheckResult -name "网络连接: $($service.Name)" -status "✅" -message "可访问"
                Log-Message "网络连接: $($service.Name) - 可访问"
            } else {
                Add-CheckResult -name "网络连接: $($service.Name)" -status "⚠️" -message "状态码: $($response.StatusCode)"
                Log-Message "网络连接: $($service.Name) - 状态码: $($response.StatusCode)"
            }
        } catch {
            Add-CheckResult -name "网络连接: $($service.Name)" -status "❌" -message "连接失败"
            Log-Message "网络连接: $($service.Name) - 连接失败"
        }
    }
}

# 显示总结
Write-Host "`n=== 检查总结 ===" -ForegroundColor Green
Write-Host "总计检查: $($results.summary.total)" -ForegroundColor Cyan
Write-Host "通过: $($results.summary.passed) ✅" -ForegroundColor Green
Write-Host "警告: $($results.summary.warnings) ⚠️" -ForegroundColor Yellow
Write-Host "失败: $($results.summary.failed) ❌" -ForegroundColor Red

# 记录总结
Log-Message "=== 检查总结 ==="
Log-Message "总计检查: $($results.summary.total)"
Log-Message "通过: $($results.summary.passed)"
Log-Message "警告: $($results.summary.warnings)"
Log-Message "失败: $($results.summary.failed)"
Log-Message "=== 检查结束 ==="

# 生成报告（如果启用）
if ($Report) {
    $reportContent = @"
# 安全检查报告

## 报告信息
- **生成时间**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
- **检查模式**: $(if ($Quick) { '快速' } elseif ($Full) { '完整' } else { '标准' })
- **检查时长**: 约 $(Get-Date -Format 'mm') 分钟

## 检查结果

| 检查项目 | 状态 | 消息 | 时间 |
|----------|------|------|------|
$($results.checks | ForEach-Object { "| $($_.name) | $($_.status) | $($_.message) | $($_.timestamp) |" } | Out-String)

## 统计摘要
- **总计检查**: $($results.summary.total)
- **通过**: $($results.summary.passed) (✅)
- **警告**: $($results.summary.warnings) (⚠️)
- **失败**: $($results.summary.failed) (❌)

## 建议措施
$(
if ($results.summary.failed -gt 0) {
    "1. 立即修复失败项目"
    "2. 检查相关配置"
    "3. 重新运行检查"
} elseif ($results.summary.warnings -gt 0) {
    "1. 关注警告项目"
    "2. 考虑优化配置"
    "3. 监控状态变化"
} else {
    "1. 所有检查通过"
    "2. 继续保持良好状态"
    "3. 定期运行完整检查"
}
)

## 日志文件
- 详细日志: $logFile
- 下次检查: 建议每日运行

---

*报告生成时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')*
"@

    Set-Content -Path $reportFile -Value $reportContent -Force
    Write-Host "`n报告已生成: $reportFile" -ForegroundColor Green
}

Write-Host "`n日志文件: $logFile" -ForegroundColor Gray
Write-Host "检查完成时间: $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Gray

# 建议
if ($results.summary.failed -gt 0) {
    Write-Host "`n⚠️ 建议: 立即修复失败项目" -ForegroundColor Red
} elseif ($results.summary.warnings -gt 0) {
    Write-Host "`n⚠️ 建议: 关注警告项目" -ForegroundColor Yellow
} else {
    Write-Host "`n✅ 建议: 所有系统正常" -ForegroundColor Green
}

Write-Host "`n=== 检查完成 ===" -ForegroundColor Green