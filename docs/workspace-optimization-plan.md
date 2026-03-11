# 工作空间优化计划

## 目标
1. 文件合并与去重
2. 无效文件清理
3. 目录结构优化
4. 空间效率提升

## 当前状态分析
基于初步扫描，需要处理以下问题：

### 1. 重复文件问题
- 相同文件名不同位置
- 相同内容不同文件名
- 版本备份文件

### 2. 无效文件问题
- 零字节文件
- 临时文件 (.tmp, .temp, .bak)
- 日志文件 (.log)
- 备份文件 (~*)

### 3. 目录结构问题
- 嵌套过深
- 分类不清晰
- 冗余目录

## 优化策略

### 阶段1：安全备份
创建完整备份后再进行操作

### 阶段2：无效文件清理
按优先级清理：
1. 零字节文件（安全）
2. 临时文件（相对安全）
3. 旧备份文件（需要验证）

### 阶段3：重复文件合并
1. 按文件名识别重复
2. 按内容哈希识别重复
3. 保留最新/最完整版本

### 阶段4：目录重组
1. 扁平化过深嵌套
2. 按功能/类型重新分类
3. 创建标准目录结构

## 实施步骤

### 步骤1：创建备份
```powershell
# 创建完整备份
$backupDir = "C:\Users\luchaochao\.openclaw\workspace-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Copy-Item -Path "C:\Users\luchaochao\.openclaw\workspace" -Destination $backupDir -Recurse
```

### 步骤2：清理无效文件
```powershell
# 删除零字节文件
Get-ChildItem -Path "." -Recurse -File | Where-Object {$_.Length -eq 0} | Remove-Item -Force

# 删除临时文件
Get-ChildItem -Path "." -Recurse -File -Include "*.tmp", "*.temp", "*.bak", "*.log" | Remove-Item -Force

# 删除备份文件（~开头）
Get-ChildItem -Path "." -Recurse -File | Where-Object {$_.Name -match '^~'} | Remove-Item -Force
```

### 步骤3：识别重复文件
```powershell
# 按文件名分组
$filesByName = Get-ChildItem -Path "." -Recurse -File | Group-Object Name

# 按内容哈希分组（更精确）
$filesByHash = Get-ChildItem -Path "." -Recurse -File | ForEach-Object {
    $hash = Get-FileHash $_.FullName -Algorithm MD5
    [PSCustomObject]@{
        File = $_
        Hash = $hash.Hash
    }
} | Group-Object Hash
```

### 步骤4：目录优化
```powershell
# 创建标准目录结构
$standardDirs = @(
    "docs",
    "scripts",
    "data",
    "config",
    "temp",
    "archive",
    "projects"
)

foreach ($dir in $standardDirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force
    }
}
```

## 风险控制

### 安全措施
1. **完整备份**：操作前创建完整备份
2. **预览模式**：重要操作前先预览
3. **逐步执行**：分阶段执行，每阶段验证
4. **恢复计划**：明确误操作的恢复方法

### 验证方法
1. 文件数量前后对比
2. 磁盘空间变化
3. 关键文件完整性检查
4. 功能测试

## 预期成果

### 量化目标
1. 减少重复文件至少50%
2. 清理无效文件100%
3. 目录深度控制在3层以内
4. 空间节省10-20%

### 质量目标
1. 文件组织更清晰
2. 查找效率提升
3. 维护成本降低
4. 系统更稳定

## 时间计划
- 阶段1（备份）：5分钟
- 阶段2（清理）：10分钟
- 阶段3（去重）：15分钟
- 阶段4（重组）：10分钟
- 验证：5分钟

总计：约45分钟

## 监控指标
1. 文件总数变化
2. 目录总数变化
3. 磁盘空间变化
4. 平均目录深度
5. 重复文件比例

---
*计划创建时间: 2026-03-07 14:01 GMT+8*
*预计执行时间: 45分钟*