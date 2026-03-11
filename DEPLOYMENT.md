# 部署指南

本文档说明如何将此技能库部署到其他电脑上的OpenClaw。

## 前提条件

1. 目标电脑已安装OpenClaw
   ```bash
   npm install -g openclaw-cn
   ```

2. OpenClaw工作空间已初始化
   ```bash
   openclaw init
   ```

## 部署方法

### 方法1：完整部署（推荐）

将整个技能库部署到目标电脑：

```bash
# 1. 克隆或下载此仓库
git clone <repository-url>
# 或直接下载ZIP文件并解压

# 2. 进入仓库目录
cd openclaw-skills-repo

# 3. 复制核心文件到OpenClaw工作空间
cp AGENTS.md SOUL.md IDENTITY.md HEARTBEAT.md TOOLS.md BOOTSTRAP.md ~/.openclaw/workspace/

# 4. 复制技能目录
cp -r skills/ ~/.openclaw/workspace/

# 5. 复制工具脚本（可选）
cp -r tools/ ~/.openclaw/workspace/

# 6. 复制文档（可选）
cp -r docs/ ~/.openclaw/workspace/
```

### 方法2：最小化部署

只部署必要的技能和配置：

```bash
# 1. 只复制技能目录
cp -r skills/ ~/.openclaw/workspace/

# 2. 根据需要复制配置文件
# 编辑以下文件以适应目标环境
cp AGENTS.md ~/.openclaw/workspace/AGENTS.md.example
cp SOUL.md ~/.openclaw/workspace/SOUL.md.example
```

## 配置调整

部署后，需要根据目标环境调整以下文件：

### 1. USER.md
编辑用户信息：
```markdown
# USER.md - About Your Human

- **Name:** [用户姓名]
- **What to call them:** [称呼]
- **Pronouns:** [代词]
- **Timezone:** Asia/Shanghai
- **Notes:** [用户备注]
```

### 2. TOOLS.md
配置本地工具和环境：
```markdown
# TOOLS.md - Local Notes

## 环境配置
- Python路径: C:\Python39\
- 文档处理工具: python-docx, docx2txt
- 工作目录: C:\Users\[用户名]\.openclaw\workspace

## 技能配置
- Word文档技能: 已启用
- 自动化脚本: 已配置
```

### 3. HEARTBEAT.md
配置定期检查任务：
```markdown
# HEARTBEAT.md

## 定期检查任务
- 检查电子邮件（每2小时）
- 检查日历事件（每1小时）
- 检查系统状态（每4小时）
```

## 验证部署

部署完成后，验证技能是否正常工作：

### 1. 启动OpenClaw
```bash
openclaw start
```

### 2. 测试技能
在OpenClaw聊天界面中：
```
测试Word文档技能：创建测试文档
```

### 3. 检查技能列表
```
列出所有可用技能
```

## 故障排除

### 问题1：技能未显示
**症状**：在技能列表中看不到部署的技能
**解决方案**：
1. 检查技能目录位置：`~/.openclaw/workspace/skills/`
2. 确保每个技能目录包含 `SKILL.md` 文件
3. 重启OpenClaw服务

### 问题2：脚本无法执行
**症状**：工具脚本无法运行或报错
**解决方案**：
1. 检查脚本文件权限
   ```bash
   chmod +x ~/.openclaw/workspace/tools/*.bat
   ```
2. 检查依赖是否安装
3. 查看脚本日志文件

### 问题3：配置文件错误
**症状**：OpenClaw启动失败或行为异常
**解决方案**：
1. 检查配置文件语法
2. 恢复默认配置并逐步添加
3. 查看OpenClaw日志
   ```bash
   openclaw logs
   ```

## 更新部署

当技能库更新时，同步到已部署的环境：

### 1. 增量更新
```bash
# 只更新修改的文件
rsync -av --update skills/ ~/.openclaw/workspace/skills/
```

### 2. 完整更新
```bash
# 备份现有配置
cp -r ~/.openclaw/workspace ~/.openclaw/workspace-backup-$(date +%Y%m%d)

# 重新部署
cp -r skills/ ~/.openclaw/workspace/
cp AGENTS.md SOUL.md ~/.openclaw/workspace/
```

## 多环境部署

### 开发环境
```bash
# 使用开发配置
cp config/development/* ~/.openclaw/workspace/config/
```

### 生产环境
```bash
# 使用生产配置
cp config/production/* ~/.openclaw/workspace/config/
```

### 测试环境
```bash
# 使用测试配置
cp config/testing/* ~/.openclaw/workspace/config/
```

## 自动化部署脚本

仓库中包含自动化部署脚本：

### Windows
```bash
# 运行部署脚本
.\tools\deploy-windows.bat
```

### Linux/macOS
```bash
# 运行部署脚本
chmod +x tools/deploy-linux.sh
./tools/deploy-linux.sh
```

## 注意事项

1. **权限管理**：确保OpenClaw有足够的权限访问所需文件
2. **路径差异**：Windows和Linux/macOS的路径格式不同，需要相应调整
3. **环境变量**：设置必要的环境变量
4. **依赖安装**：确保所有技能依赖已安装
5. **定期备份**：定期备份工作空间配置

## 支持

如有部署问题，请：
1. 查看 `docs/` 目录中的文档
2. 检查OpenClaw日志
3. 提交GitHub Issue