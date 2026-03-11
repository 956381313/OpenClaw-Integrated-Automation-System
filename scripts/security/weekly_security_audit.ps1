# 每周安全审计脚本
param(
    [switch]$GenerateReport,
    [switch]$SendNotification
)

Write-Host "=== 每周安全审计 ===" -ForegroundColor Green
Write-Host "开始时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# 审计结果
$auditResults = @{
    "timestamp" = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "checks" = @()
    "summary" = @{
        "total" = 0
        "passed" = 0
        "failed" = 0
        "warnings" = 0
    }
}

function Add-AuditResult {
    param($category, $check, $status, $message, $details = $null)
    
    $result = @{
        "category" = $category
        "check" = $check
        "status" = $status
        "message" = $message
        "timestamp" = Get-Date -Format "HH:mm:ss"
    }
    
    if ($details) {
        $result.details = $details
    }
    
    $auditResults.checks += $result
    $auditResults.summary.total++
    
    switch ($status) {
        "✅" { $auditResults.summary.passed++ }
        "❌" { $auditResults.summary.failed++ }
        "⚠️" { $auditResults.summary.warnings++ }
    }
    
    # 输出到控制台
    $color = if ($status -eq "✅") { "Green" } elseif ($status -eq "❌") { "Red" } else { "Yellow" }
    Write-Host "$status [$category] $check : $message" -ForegroundColor $color
}

# 1. 系统安全检查
Write-Host "1. 系统安全检查..." -ForegroundColor Cyan

# 检查Windows更新
try {
    $updates = Get-HotFix | Measure-Object | Select-Object -ExpandProperty Count
    if ($updates -gt 0) {
        Add-AuditResult -category "系统" -check "Windows更新" -status "✅" -message "已安装 $updates 个更新"
    } else {
        Add-AuditResult -category "系统" -check "Windows更新" -status "⚠️" -message "未找到更新记录"
    }
} catch {
    Add-AuditResult -category "系统" -check "Windows更新" -status "❌" -message "检查失败"
}

# 检查防病毒软件
try {
    $antivirus = Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntivirusProduct
    if ($antivirus) {
        $enabled = ($antivirus | Where-Object { $_.productState -eq 266240 }).Count -gt 0
        if ($enabled) {
            Add-AuditResult -category "系统" -check "防病毒软件" -status "✅" -message "已启用"
        } else {
            Add-AuditResult -category "系统" -check "防病毒软件" -status "⚠️" -message "未启用"
        }
    } else {
        Add-AuditResult -category "系统" -check "防病毒软件" -status "❌" -message "未安装"
    }
} catch {
    Add-AuditResult -category "系统" -check "防病毒软件" -status "⚠️" -message "检查失败"
}

# 2. 网络安全检查
Write-Host "`n2. 网络安全检查..." -ForegroundColor Cyan

# 检查防火墙状态
try {
    $firewall = Get-NetFirewallProfile | Where-Object { $_.Enabled -eq "True" }
    if ($firewall) {
        $enabledProfiles = $firewall.Name -join ", "
        Add-AuditResult -category "网络" -check "防火墙" -status "✅" -message "已启用 ($enabledProfiles)"
    } else {
        Add-AuditResult -category "网络" -check "防火墙" -status "❌" -message "未启用"
    }
} catch {
    Add-AuditResult -category "网络" -check "防火墙" -status "⚠️" -message "检查失败"
}

# 检查开放的端口
try {
    $listeningPorts = Get-NetTCPConnection -State Listen | Measure-Object | Select-Object -ExpandProperty Count
    if ($listeningPorts -lt 50) {
        Add-AuditResult -category "网络" -check "监听端口" -status "✅" -message "$listeningPorts 个端口"
    } else {
        Add-AuditResult -category "网络" -check "监听端口" -status "⚠️" -message "较多端口 ($listeningPorts)"
    }
} catch {
    Add-AuditResult -category "网络" -check "监听端口" -status "⚠️" -message "检查失败"
}

# 3. 文件权限检查
Write-Host "`n3. 文件权限检查..." -ForegroundColor Cyan

$sensitiveFiles = @(
    @{Path=".env"; Description="环境变量文件"},
    @{Path="07-configuration\api-keys-config.json"; Description="API密钥配置"},
    @{Path="09-projects\security-tools\"; Description="安全工具目录"}
)

foreach ($file in $sensitiveFiles) {
    if (Test-Path $file.Path) {
        try {
            $acl = Get-Acl $file.Path
            $permissions = $acl.Access | Where-Object { $_.FileSystemRights -match "FullControl|Write" }
            
            if ($permissions.Count -eq 1 -and $permissions.IdentityReference -eq "BUILTIN\Administrators") {
                Add-AuditResult -category "文件" -check $file.Description -status "✅" -message "权限正常"
            } else {
                Add-AuditResult -category "文件" -check $file.Description -status "⚠️" -message "权限需检查"
            }
        } catch {
            Add-AuditResult -category "文件" -check $file.Description -status "⚠️" -message "权限检查失败"
        }
    } else {
        Add-AuditResult -category "文件" -check $file.Description -status "❌" -message "文件不存在"
    }
}

# 4. 应用程序安全检查
Write-Host "`n4. 应用程序安全检查..." -ForegroundColor Cyan

# 检查Node.js版本
try {
    $nodeVersion = node --version
    if ($nodeVersion) {
        Add-AuditResult -category "应用" -check "Node.js" -status "✅" -message "版本: $nodeVersion"
    }
} catch {
    Add-AuditResult -category "应用" -check "Node.js" -status "❌" -message "未安装"
}

# 检查npm版本
try {
    $npmVersion = npm --version
    if ($npmVersion) {
        Add-AuditResult -category "应用" -check "npm" -status "✅" -message "版本: $npmVersion"
    }
} catch {
    Add-AuditResult -category "应用" -check "npm" -status "❌" -message "未安装"
}

# 检查Git版本
try {
    $gitVersion = git --version
    if ($gitVersion) {
        Add-AuditResult -category "应用" -check "Git" -status "✅" -message "已安装"
    }
} catch {
    Add-AuditResult -category "应用" -check "Git" -status "❌" -message "未安装"
}

# 5. 安全工具深度检查
Write-Host "`n5. 安全工具深度检查..." -ForegroundColor Cyan

# 检查MC Porter配置
try {
    $config = mcporter config list 2>&1
    if ($config -like "*error*") {
        Add-AuditResult -category "工具" -check "MC Porter配置" -status "⚠️" -message "需要配置"
    } else {
        Add-AuditResult -category "工具" -check "MC Porter配置" -status "✅" -message "配置正常"
    }
} catch {
    Add-AuditResult -category "工具" -check "MC Porter配置" -status "❌" -message "检查失败"
}

# 检查ClawdHub更新
try {
    $updates = clawdhub list --outdated 2>&1
    if ($updates -like "*outdated*") {
        Add-AuditResult -category "工具" -check "ClawdHub更新" -status "⚠️" -message "有可用更新"
    } else {
        Add-AuditResult -category "工具" -check "ClawdHub更新" -status "✅" -message "已是最新"
    }
} catch {
    Add-AuditResult -category "工具" -check "ClawdHub更新" -status "❌" -message "检查失败"
}

# 6. 性能检查
Write-Host "`n6. 性能检查..." -ForegroundColor Cyan

# 检查磁盘空间
try {
    $disk = Get-PSDrive C
    $freeGB = [math]::Round($disk.Free / 1GB, 2)
    $totalGB = [math]::Round($disk.Used / 1GB + $disk.Free / 1GB, 2)
    $percentFree = [math]::Round(($disk.Free / ($disk.Used + $disk.Free)) * 100, 2)
    
    if ($percentFree -gt 20) {
        Add-AuditResult -category "性能" -check "磁盘空间" -status "✅" -message "剩余 ${freeGB}GB (${percentFree}%)"
    } elseif ($percentFree -gt 10) {
        Add-AuditResult -category "性能" -check "磁盘空间" -status "⚠️" -message "剩余 ${freeGB}GB (${percentFree}%)"
    } else {
        Add-AuditResult -category "性能" -check "磁盘空间" -status "❌" -message "空间不足 ${freeGB}GB (${percentFree}%)"
    }
} catch {
    Add-AuditResult -category "性能" -check "磁盘空间" -status "⚠️" -message "检查失败"
}

# 检查内存使用
try {
    $memory = Get-CimInstance Win32_OperatingSystem
    $freeMB = [math]::Round($memory.FreePhysicalMemory / 1KB, 2)
    $totalMB = [math]::Round($memory.TotalVisibleMemorySize / 1KB, 2)
    $percentFree = [math]::Round(($freeMB / $totalMB) * 100, 2)
    
    if ($percentFree -gt 30) {
        Add-AuditResult -category "性能" -check "内存使用" -status "✅" -message "剩余 ${freeMB}MB (${percentFree}%)"
    } elseif ($percentFree -gt 15) {
        Add-AuditResult -category "性能" -check "内存使用" -status "⚠️" -message "剩余 ${freeMB}MB (${percentFree}%)"
    } else {
        Add-AuditResult -category "性能" -check "内存使用" -status "❌" -message "内存紧张 ${freeMB}MB (${percentFree}%)"
    }
} catch {
    Add-AuditResult -category "性能" -check "内存使用" -status "⚠️" -message "检查失败"
}

# 显示审计总结
Write-Host "`n=== 审计总结 ===" -ForegroundColor Green
Write-Host "总计检查: $($auditResults.summary.total)" -ForegroundColor Cyan
Write-Host "通过: $($auditResults.summary.passed) ✅" -ForegroundColor Green
Write-Host "警告: $($auditResults.summary.warnings) ⚠️" -ForegroundColor Yellow
Write-Host "失败: $($auditResults.summary.failed) ❌" -ForegroundColor Red

# 按类别统计
$categories = $auditResults.checks | Group-Object -Property category
Write-Host "`n按类别统计:" -ForegroundColor Cyan
foreach ($category in $categories) {
    $passed = ($category.Group | Where-Object { $_.status -eq "✅" }).Count
    $total = $category.Count
    $percent = [math]::Round(($passed / $total) * 100, 1)
    
    $color = if ($percent -ge 80) { "Green" } elseif ($percent -ge 60) { "Yellow" } else { "Red" }
    Write-Host "  $($category.Name): $passed/$total ($percent%)" -ForegroundColor $color
}

# 生成报告
if ($GenerateReport) {
    $reportDir = "C:\Users\luchaochao\.openclaw\workspace\06-documentation\security\reports"
    if (-not (Test-Path $reportDir)) {
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    }
    
    $reportFile = "$reportDir\weekly_audit_$(Get-Date -Format 'yyyyMMdd').md"
    
    $reportContent = @"
# 每周安全审计报告

## 审计信息
- **审计时间**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
- **审计范围**: 系统、网络、文件、应用、工具、性能
- **审计模式**: 完整深度检查

## 审计结果

### 按类别详情

$($categories | ForEach-Object {
    "#### $($_.Name)"
    ""
    "| 检查项目 | 状态 | 消息 | 时间 |"
    "|----------|------|------|------|"
    ($_.Group | ForEach-Object { "| $($_.check) | $($_.status) | $($_.message) | $($_.timestamp) |" } | Out-String)
    ""
} | Out-String)

## 统计摘要
- **总计检查**: $($auditResults.summary.total)
- **通过**: $($auditResults.summary.passed) (✅)
- **警告**: $($auditResults.summary.warnings) (⚠️)
- **失败**: $($auditResults.summary.failed) (❌)

## 类别通过率
$($categories | ForEach-Object {
    $passed = ($_.Group | Where-Object { $_.status -eq "✅" }).Count
    $total = $_.Count
    $percent = [math]::Round(($passed / $total) * 100, 1)
    "- **$($_.Name)**: $passed/$total ($percent%)"
} | Out-String)

## 关键发现
$(
$criticalIssues = $auditResults.checks | Where-Object { $_.status -eq "❌" }
if ($criticalIssues.Count -gt 0) {
    "### ❌ 需要立即处理的问题"
    ""
    $criticalIssues | ForEach-Object { "- **$($_.category) - $($_.check)**: $($_.message)" }
} else {
    "### ✅ 无关键问题"
}
)

$(
$warnings = $auditResults.checks | Where-Object { $_.status -eq "⚠️" }
if ($warnings.Count -gt 0) {
    "`n### ⚠️ 需要注意的警告"
    ""
    $warnings | ForEach-Object { "- **$($_.category) - $($_.check)**: $($_.message)" }
} else {
    "`n### ✅ 无警告信息"
}
)

## 建议措施
$(
if ($auditResults.summary.failed -gt 0) {
    "1. **立即处理失败项目**"
    "2. **优先修复关键安全问题**"
    "3. **重新运行审计验证修复**"
} elseif ($auditResults.summary.warnings -gt 0) {
    "1. **关注警告项目**"
    "2. **制定优化计划**"
    "3. **监控警告状态变化**"
} else {
    "1. **所有检查通过，系统状态良好**"
    "2. **继续保持当前安全配置**"
    "3. **定期运行完整审计**"
}
)

## 后续计划
1. **每日检查**: 持续监控基础安全状态
2. **每周审计**: 深度检查系统安全
3. **每月回顾**: 分析趋势和优化策略

---

*报告生成时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')*
*下次审计: 下周一 10:00*
"@

    Set-Content -Path $reportFile -Value $reportContent -Force
    Write-Host "`n审计报告已生成: $reportFile" -ForegroundColor Green
}

# 建议
Write-Host "`n=== 建议 ===" -ForegroundColor Cyan
if ($auditResults.summary.failed -gt 0) {
    Write-Host "❌ 发现关键问题，建议立即处理" -ForegroundColor Red
} elseif ($auditResults.summary.warnings -gt 0) {
    Write-Host "⚠️ 发现警告，建议关注并优化" -ForegroundColor Yellow
} else {
    Write-Host "✅ 所有检查通过，系统状态良好" -ForegroundColor Green
}

Write-Host "`n审计完成时间: $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Gray
Write-Host "=== 审计完成 ===" -ForegroundColor Green