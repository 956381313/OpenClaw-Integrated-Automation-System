# 自动化系统使用指南

## 系统概述
这是一个集成化的自动化管理系统，用于维护工作空间和磁盘空间。

### 核心功能
1. **磁盘空间清理** - 自动清理临时文件、日志文件等
2. **文件整理** - 自动分类和组织文件
3. **空间监控** - 监控磁盘使用情况并告警
4. **定期维护** - 自动化定期维护任务

## 快速开始

### 1. 系统状态检查
```powershell
.\auto-system-final.ps1 status
```

### 2. 快速清理
```powershell
.\auto-system-final.ps1 clean -Mode quick
```

### 3. 完整清理
```powershell
.\auto-system-final.ps1 clean -Mode full
```

### 4. 模拟运行（不实际删除）
```powershell
.\auto-system-final.ps1 clean -Mode full -DryRun
```

### 5. 监控磁盘空间
```powershell
.\auto-system-final.ps1 monitor
```

### 6. 生成报告
```powershell
.\auto-system-final.ps1 report
```

## 详细说明

### 清理模式

#### 快速模式 (`-Mode quick`)
- 清理临时文件 (.tmp, .temp, .bak)
- 清理零字节文件
- 执行时间: 1-2分钟

#### 完整模式 (`-Mode full`)
- 包含快速模式的所有功能
- 清理旧日志文件（超过7天）
- 执行时间: 3-5分钟

### 选项说明

#### `-Verbose`
显示详细的操作信息，适合调试和监控。

#### `-DryRun`
模拟运行模式，显示将执行的操作但不实际删除文件。

#### `-Force`
强制运行，忽略所有警告提示。

## 定期维护计划

### 每日维护（建议）
```powershell
# 快速检查磁盘空间
.\auto-system-final.ps1 monitor
```

### 每周维护（重要）
```powershell
# 完整清理
.\auto-system-final.ps1 clean -Mode full
```

### 每月维护（推荐）
```powershell
# 生成详细报告
.\auto-system-final.ps1 report
```

## 自动化调度

### Windows 任务计划程序
1. 打开"任务计划程序"
2. 创建基本任务
3. 设置触发器（如每天凌晨2点）
4. 设置操作：启动程序
   - 程序/脚本: `powershell.exe`
   - 参数: `-ExecutionPolicy Bypass -File "C:\Users\luchaochao\.openclaw\workspace\auto-system-final.ps1" clean -Mode quick`

### 每周完整清理任务
- 触发器: 每周一凌晨3点
- 操作: `.\auto-system-final.ps1 clean -Mode full`

## 监控阈值

### 磁盘空间告警级别
- **正常**: 使用率 < 80% (绿色)
- **警告**: 使用率 80-90% (黄色)
- **危险**: 使用率 > 90% (红色)

### 建议操作
1. **正常状态**: 定期维护即可
2. **警告状态**: 运行完整清理
3. **危险状态**: 立即运行紧急清理

## 故障排除

### 常见问题

#### 1. 脚本无法执行
```powershell
# 设置执行策略
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### 2. 权限不足
- 以管理员身份运行PowerShell
- 检查文件权限

#### 3. 磁盘空间未释放
- 重启电脑后运行清理
- 检查是否有程序占用文件

### 错误代码
- **0**: 成功
- **1**: 一般错误
- **2**: 参数错误
- **3**: 权限错误
- **4**: 磁盘空间不足

## 高级功能

### 自定义清理规则
可以修改脚本中的清理规则：
- 文件类型扩展名
- 文件保留天数
- 最小文件大小

### 扩展模块
系统支持模块化扩展，可以添加：
- 备份管理模块
- 版本控制模块
- 性能监控模块

## 安全注意事项

### 数据安全
1. **重要文件备份**: 清理前确保重要文件已备份
2. **模拟运行**: 首次使用建议先运行 `-DryRun` 模式
3. **文件恢复**: 误删文件可从回收站恢复

### 权限管理
- 系统需要文件读写权限
- 建议在用户权限下运行
- 避免使用系统管理员权限除非必要

## 性能优化

### 清理效率
- 快速模式: 针对临时文件，效率高
- 完整模式: 全面清理，时间稍长

### 资源占用
- 内存占用: < 50MB
- CPU占用: < 10%
- 执行时间: 1-5分钟

## 更新和维护

### 系统更新
定期检查更新：
1. 备份当前配置
2. 下载新版本
3. 测试新功能
4. 部署到生产环境

### 配置备份
建议备份以下文件：
- `auto-system-final.ps1` (主脚本)
- 自定义配置文件
- 任务计划配置

## 技术支持

### 获取帮助
```powershell
# 显示帮助信息
.\auto-system-final.ps1 help
```

### 问题反馈
遇到问题时：
1. 运行 `.\auto-system-final.ps1 report` 生成报告
2. 检查日志文件
3. 联系技术支持

## 版本历史

### v1.0.0 (2026-03-07)
- 初始版本发布
- 基础清理功能
- 状态监控
- 报告生成

---
*最后更新: 2026-03-07*
*系统版本: 1.0.0*