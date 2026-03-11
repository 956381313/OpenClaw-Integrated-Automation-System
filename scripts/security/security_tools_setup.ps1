# 安全工具配置脚本
Write-Host "=== 安全工具配置开始 ===" -ForegroundColor Green

# 1. 检查并安装GitHub CLI
Write-Host "`n1. 检查GitHub CLI..." -ForegroundColor Cyan
if (Get-Command gh -ErrorAction SilentlyContinue) {
    Write-Host "GitHub CLI 已安装: $(gh --version)" -ForegroundColor Green
} else {
    Write-Host "正在安装GitHub CLI..." -ForegroundColor Yellow
    try {
        # 尝试使用winget安装
        winget install --id GitHub.cli --silent --accept-package-agreements --accept-source-agreements
        Write-Host "GitHub CLI 安装完成" -ForegroundColor Green
    } catch {
        Write-Host "winget安装失败，尝试其他方法..." -ForegroundColor Yellow
        # 可以添加其他安装方法
    }
}

# 2. 检查并安装MC Porter
Write-Host "`n2. 检查MC Porter..." -ForegroundColor Cyan
if (Get-Command mcporter -ErrorAction SilentlyContinue) {
    Write-Host "MC Porter 已安装" -ForegroundColor Green
} else {
    Write-Host "正在安装MC Porter..." -ForegroundColor Yellow
    npm install -g mcporter
    Write-Host "MC Porter 安装完成" -ForegroundColor Green
}

# 3. 检查并安装Oracle
Write-Host "`n3. 检查Oracle..." -ForegroundColor Cyan
if (Get-Command oracle -ErrorAction SilentlyContinue) {
    Write-Host "Oracle 已安装" -ForegroundColor Green
} else {
    Write-Host "正在安装Oracle..." -ForegroundColor Yellow
    npm install -g @steipete/oracle
    Write-Host "Oracle 安装完成" -ForegroundColor Green
}

# 4. 检查ClawdHub
Write-Host "`n4. 检查ClawdHub..." -ForegroundColor Cyan
if (Get-Command clawdhub -ErrorAction SilentlyContinue) {
    Write-Host "ClawdHub 已安装: $(clawdhub --cli-version)" -ForegroundColor Green
} else {
    Write-Host "正在安装ClawdHub..." -ForegroundColor Yellow
    npm install -g clawdhub
    Write-Host "ClawdHub 安装完成" -ForegroundColor Green
}

# 5. 1Password CLI (需要手动安装)
Write-Host "`n5. 1Password CLI 安装说明:" -ForegroundColor Cyan
Write-Host "请访问 https://developer.1password.com/docs/cli/get-started/" -ForegroundColor Yellow
Write-Host "下载并安装1Password CLI" -ForegroundColor Yellow
Write-Host "安装后需要启用桌面应用集成" -ForegroundColor Yellow

# 6. 创建安全配置目录
Write-Host "`n6. 创建安全配置目录..." -ForegroundColor Cyan
$securityDir = "$env:USERPROFILE\.openclaw\security"
if (-not (Test-Path $securityDir)) {
    New-Item -ItemType Directory -Path $securityDir -Force
    Write-Host "安全配置目录已创建: $securityDir" -ForegroundColor Green
} else {
    Write-Host "安全配置目录已存在: $securityDir" -ForegroundColor Green
}

# 7. 创建安全配置文件
Write-Host "`n7. 创建安全配置文件..." -ForegroundColor Cyan
$configFile = "$securityDir\security_config.md"
@"
# 安全配置指南

## 已安装的安全工具
1. **GitHub CLI (gh)** - 代码仓库安全管理
2. **MC Porter** - MCP服务器安全配置
3. **Oracle** - 代码安全分析
4. **ClawdHub** - 技能安全更新
5. **1Password CLI (需要手动安装)** - 密码安全管理

## 安全最佳实践

### 密码管理
- 使用1Password管理所有敏感凭证
- 避免在日志中暴露秘密
- 使用`op run`/`op inject`而不是写入磁盘

### 代码安全
- 定期使用`gh`检查仓库安全状态
- 监控CI/CD工作流
- 审查PR和代码变更

### API安全
- 使用MC Porter进行安全的API集成
- 配置OAuth认证
- 定期更新API密钥

### 系统安全
- 定期使用ClawdHub更新技能
- 监控系统日志
- 配置访问控制

## 紧急响应
1. 发现安全事件时立即停止相关操作
2. 检查日志和审计记录
3. 更新凭证和密钥
4. 报告安全事件

最后更新: $(Get-Date)
"@ | Out-File -FilePath $configFile -Encoding UTF8

Write-Host "安全配置文件已创建: $configFile" -ForegroundColor Green

Write-Host "`n=== 安全工具配置完成 ===" -ForegroundColor Green
Write-Host "请按照上述说明完成1Password CLI的安装和配置" -ForegroundColor Yellow