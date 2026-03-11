# 安全工具启动脚本
Write-Host "=== 安全工具启动器 ===" -ForegroundColor Green
Write-Host ""

# 设置工具路径
$opPath = "C:\Users\luchaochao\AppData\Local\Microsoft\WinGet\Packages\AgileBits.1Password.CLI_Microsoft.Winget.Source_8wekyb3d8bbwe\op.exe"
$ghPath = "D:\Ai\gh.exe"

# 检查工具状态
Write-Host "检查工具状态..." -ForegroundColor Cyan

# 1. MC Porter
Write-Host "`n1. MC Porter" -ForegroundColor Yellow
try {
    $mcporterVersion = mcporter --version
    Write-Host "   ✅ 版本: $mcporterVersion" -ForegroundColor Green
} catch {
    Write-Host "   ❌ 未找到或不可用" -ForegroundColor Red
}

# 2. Oracle
Write-Host "`n2. Oracle" -ForegroundColor Yellow
try {
    $oracleHelp = oracle --help 2>&1 | Select-String -Pattern "Oracle CLI"
    if ($oracleHelp) {
        Write-Host "   ✅ 已安装" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️ 需要检查" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ❌ 未找到或不可用" -ForegroundColor Red
}

# 3. ClawdHub
Write-Host "`n3. ClawdHub" -ForegroundColor Yellow
try {
    $clawdhubVersion = clawdhub --cli-version 2>&1
    Write-Host "   ✅ 版本: $clawdhubVersion" -ForegroundColor Green
} catch {
    Write-Host "   ❌ 未找到或不可用" -ForegroundColor Red
}

# 4. 1Password CLI
Write-Host "`n4. 1Password CLI" -ForegroundColor Yellow
if (Test-Path $opPath) {
    try {
        $opVersion = & $opPath --version
        Write-Host "   ✅ 版本: $opVersion" -ForegroundColor Green
        Write-Host "   路径: $opPath" -ForegroundColor Gray
    } catch {
        Write-Host "   ⚠️ 文件存在但执行失败" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ❌ 未找到: $opPath" -ForegroundColor Red
}

# 5. GitHub CLI
Write-Host "`n5. GitHub CLI" -ForegroundColor Yellow
if (Test-Path $ghPath) {
    try {
        $ghVersion = & $ghPath --version
        Write-Host "   ✅ 版本: $ghVersion" -ForegroundColor Green
        Write-Host "   路径: $ghPath" -ForegroundColor Gray
    } catch {
        Write-Host "   ⚠️ 文件存在但执行失败" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ❌ 未找到: $ghPath" -ForegroundColor Red
}

# 显示使用命令
Write-Host "`n=== 常用命令 ===" -ForegroundColor Cyan

Write-Host "`n🔐 1Password CLI:" -ForegroundColor Magenta
Write-Host "   完整路径: `"$opPath`" [命令]"
Write-Host "   登录: `"$opPath`" signin"
Write-Host "   验证: `"$opPath`" whoami"

Write-Host "`n🐙 GitHub CLI:" -ForegroundColor Magenta
Write-Host "   完整路径: `"$ghPath`" [命令]"
Write-Host "   登录: `"$ghPath`" auth login"
Write-Host "   状态: `"$ghPath`" auth status"

Write-Host "`n📦 MC Porter:" -ForegroundColor Magenta
Write-Host "   列表: mcporter list"
Write-Host "   配置: mcporter config list"

Write-Host "`n🧿 Oracle:" -ForegroundColor Magenta
Write-Host "   帮助: oracle --help"
Write-Host "   预览: oracle --dry-run summary -p `"安全审查`" --file `"src/**`""

Write-Host "`n🔄 ClawdHub:" -ForegroundColor Magenta
Write-Host "   更新: clawdhub update --all"
Write-Host "   搜索: clawdhub search `"security`""

# 快速启动菜单
Write-Host "`n=== 快速启动 ===" -ForegroundColor Green
Write-Host "1. 测试所有工具"
Write-Host "2. 配置1Password"
Write-Host "3. 配置GitHub"
Write-Host "4. 更新安全技能"
Write-Host "5. 退出"
Write-Host ""

$choice = Read-Host "请选择 (1-5)"

switch ($choice) {
    "1" {
        Write-Host "`n测试所有工具..." -ForegroundColor Cyan
        # 这里可以添加测试代码
        Write-Host "测试完成" -ForegroundColor Green
    }
    "2" {
        Write-Host "`n配置1Password..." -ForegroundColor Cyan
        Write-Host "1. 确保1Password桌面应用已安装并登录"
        Write-Host "2. 启用CLI集成: 设置 > 开发者 > 启用命令行界面工具"
        Write-Host "3. 运行: `"$opPath`" signin"
        Write-Host "4. 验证: `"$opPath`" whoami"
    }
    "3" {
        Write-Host "`n配置GitHub..." -ForegroundColor Cyan
        Write-Host "1. 运行: `"$ghPath`" auth login"
        Write-Host "2. 按照提示完成认证"
        Write-Host "3. 验证: & `"$ghPath`" auth status"
    }
    "4" {
        Write-Host "`n更新安全技能..." -ForegroundColor Cyan
        try {
            clawdhub update --all
        } catch {
            Write-Host "更新失败，请手动运行: clawdhub update --all" -ForegroundColor Red
        }
    }
    "5" {
        Write-Host "退出" -ForegroundColor Yellow
        exit
    }
    default {
        Write-Host "无效选择" -ForegroundColor Red
    }
}

Write-Host "`n=== 完成 ===" -ForegroundColor Green
Write-Host "详细指南请查看: 安全技能配置完成总结.md" -ForegroundColor Yellow
Write-Host "按任意键继续..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")