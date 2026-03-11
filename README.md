# OpenClaw 技能与功能库

这是一个OpenClaw AI助手的技能和功能库，包含自定义技能、工具脚本和配置模板。

## 目录结构

```
├── README.md              # 项目说明
├── AGENTS.md              # 工作空间定义
├── SOUL.md                # AI身份定义
├── USER.md                # 用户信息
├── IDENTITY.md            # 身份配置
├── HEARTBEAT.md           # 心跳检查配置
├── TOOLS.md               # 工具配置
├── BOOTSTRAP.md           # 引导文件
├── skills/                # 自定义技能
│   └── word-document/     # Word文档处理技能
├── scripts/               # 脚本文件
├── tools/                 # 工具集合
├── docs/                  # 文档
├── config/                # 配置文件模板
├── examples/              # 使用示例
└── tests/                 # 测试文件
```

## 包含的技能

### 1. Word文档处理技能
位于 `skills/word-document/`

一个全面的Microsoft Word文档处理技能，支持：
- 文档创建、编辑和转换
- 中文文档处理
- 模板处理和报告生成
- 合同处理和批量操作
- 使用python-docx、docx2txt等库

## 工具集合

位于 `tools/` 目录，包含以下自动化脚本：
- `admin-update.bat` - 管理员更新脚本
- `create-repo-system.bat` - 创建仓库系统
- `fix-automation.bat` - 修复自动化
- `manage-automation.bat` - 管理自动化
- `organize-simple.bat` - 简单整理
- 以及其他实用脚本

## 快速开始

### 1. 安装OpenClaw
```bash
npm install -g openclaw-cn
```

### 2. 部署技能
将 `skills/` 目录复制到你的OpenClaw工作空间：
```bash
# 复制技能到工作空间
cp -r skills/ ~/.openclaw/workspace/skills/
```

### 3. 配置工作空间
编辑核心配置文件：
- `AGENTS.md` - 定义工作空间行为
- `SOUL.md` - 定义AI身份
- `USER.md` - 添加用户信息
- `TOOLS.md` - 配置本地工具

## 使用示例

### 使用Word文档技能
```bash
# 在OpenClaw中激活技能
技能: Word文档处理

# 创建新文档
创建名为"报告.docx"的Word文档，包含标题和章节

# 编辑现有文档
编辑"合同.docx"，更新条款和日期

# 转换文档格式
将"文档.docx"转换为PDF格式
```

### 使用自动化脚本
```bash
# 运行整理脚本
.\tools\organize-simple.bat

# 运行自动化管理
.\tools\manage-automation.bat
```

## 部署到其他电脑

### 方法1：完整部署
1. 克隆此仓库
2. 复制整个 `github-repo/` 目录到目标电脑的OpenClaw工作空间
3. 根据需要修改配置文件

### 方法2：最小化部署
1. 只复制 `skills/` 目录
2. 复制必要的配置文件（AGENTS.md, SOUL.md等）
3. 根据目标环境调整配置

## 配置说明

### 核心配置文件
- **AGENTS.md** - 定义工作空间行为和工作流程
- **SOUL.md** - 定义AI助手的性格和行为方式
- **USER.md** - 存储用户信息和偏好
- **IDENTITY.md** - AI身份配置
- **HEARTBEAT.md** - 定期检查任务配置
- **TOOLS.md** - 本地工具和环境配置

### 技能配置
每个技能目录包含：
- `SKILL.md` - 技能说明和使用方法
- `scripts/` - 相关脚本文件
- `references/` - 参考文档

## 维护和更新

### 添加新技能
1. 在 `skills/` 目录创建新技能文件夹
2. 按照现有技能结构创建文件
3. 更新README.md文档

### 更新现有技能
1. 修改技能目录中的文件
2. 更新技能文档
3. 测试功能是否正常

### 备份和恢复
```bash
# 备份技能库
tar -czf openclaw-skills-backup.tar.gz skills/

# 恢复技能库
tar -xzf openclaw-skills-backup.tar.gz -C ~/.openclaw/workspace/
```

## 许可证

本项目采用MIT许可证。详见LICENSE文件。

## 贡献

欢迎提交Issue和Pull Request来改进这个技能库。

## 支持

如有问题，请：
1. 查看 `docs/` 目录中的文档
2. 检查技能目录中的 `SKILL.md` 文件
3. 提交GitHub Issue