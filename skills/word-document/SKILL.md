---
name: Word文档处理
description: 全面的Microsoft Word文档处理技能，支持文档创建、编辑、转换、分析、批量处理和高级功能。包含中文文档处理、模板处理、报告生成、合同处理等专业功能。使用python-docx、docx2txt、pdf2docx、pandoc等库实现完整的Word文档工作流。
---

# Word文档处理技能

## 概述

本技能提供全面的Microsoft Word文档处理能力，涵盖从基础编辑到高级批量处理的所有功能。支持中文文档处理，包含完整的Python脚本和工作流。

## 快速开始

### 安装依赖
```bash
pip install python-docx docx2txt pdf2docx python-pptx beautifulsoup4 lxml pandas openpyxl pillow reportlab pypandoc
```

### 基本使用
```python
from docx import Document

# 创建新文档
doc = Document()
doc.add_heading('文档标题', 0)
doc.add_paragraph('这是一个段落。')
doc.save('新文档.docx')
```

## 核心功能

### 1. 文档创建和编辑
- **创建新文档**：支持各种格式和模板
- **文本编辑**：添加、删除、修改文本内容
- **格式化**：字体、颜色、大小、对齐方式
- **元素添加**：图片、表格、图表、形状
- **样式管理**：应用和自定义文档样式

### 2. 文档转换
- **Word ↔ PDF**：高质量双向转换
- **Word ↔ HTML**：保留格式的网页转换
- **Word ↔ Markdown**：简洁的文本转换
- **Word ↔ 纯文本**：提取纯文本内容
- **Word ↔ 其他格式**：支持多种文档格式

### 3. 文档分析
- **内容提取**：提取文本、图片、表格
- **统计分析**：字数、段落数、页数统计
- **结构分析**：分析文档大纲和层次结构
- **元数据提取**：作者、创建时间、修改历史
- **质量检查**：检查格式一致性和错误

### 4. 批量处理
- **批量转换**：同时处理多个文档
- **批量替换**：全局文本查找和替换
- **批量合并**：合并多个文档为一个
- **批量添加**：添加水印、页眉页脚、编号
- **批量重命名**：按照规则重命名文件

### 5. 高级功能
- **模板处理**：基于模板生成文档
- **表格处理**：创建、编辑、分析表格数据
- **图片处理**：插入、调整、提取图片
- **图表生成**：创建各种类型的图表
- **自动化报告**：自动生成数据分析报告

### 6. 特定场景
- **报告生成**：业务报告、分析报告
- **合同处理**：合同模板、条款管理
- **简历处理**：简历创建、格式优化
- **学术论文**：论文格式、参考文献
- **中文文档**：专门的中文排版和处理

## 详细功能指南

### 文档创建和编辑
详见 [创建编辑指南](references/creation-editing.md)

### 文档转换
详见 [转换指南](references/conversion.md)

### 文档分析
详见 [分析指南](references/analysis.md)

### 批量处理
详见 [批量处理指南](references/batch-processing.md)

### 高级功能
详见 [高级功能指南](references/advanced-features.md)

### 特定场景
详见 [场景应用指南](references/scenarios.md)

## 脚本目录

### 核心脚本
- `scripts/create_document.py` - 创建新文档
- `scripts/edit_document.py` - 编辑现有文档
- `scripts/convert_format.py` - 格式转换
- `scripts/extract_content.py` - 内容提取
- `scripts/batch_process.py` - 批量处理
- `scripts/template_processor.py` - 模板处理

### 工具脚本
- `scripts/word_to_pdf.py` - Word转PDF
- `scripts/pdf_to_word.py` - PDF转Word
- `scripts/merge_documents.py` - 合并文档
- `scripts/split_document.py` - 拆分文档
- `scripts/add_watermark.py` - 添加水印
- `scripts/extract_images.py` - 提取图片
- `scripts/table_processor.py` - 表格处理
- `scripts/chart_generator.py` - 图表生成

### 中文处理脚本
- `scripts/chinese_formatter.py` - 中文格式化
- `scripts/chinese_template.py` - 中文模板
- `scripts/chinese_report.py` - 中文报告生成

## 使用示例

### 示例1：创建中文报告
```python
# 使用中文报告生成脚本
python scripts/chinese_report.py --template 月报模板.docx --data 数据.xlsx --output 月度报告.docx
```

### 示例2：批量转换PDF
```bash
# 批量将Word转换为PDF
python scripts/batch_process.py --input-dir ./documents --output-dir ./pdfs --format pdf
```

### 示例3：提取文档内容
```python
# 提取文档所有文本和表格
python scripts/extract_content.py --input 文档.docx --output 内容.txt --include-tables
```

### 示例4：处理合同模板
```python
# 使用合同模板生成新合同
python scripts/template_processor.py --template 合同模板.docx --data 客户信息.json --output 新合同.docx
```

## 最佳实践

### 1. 文件管理
- 使用相对路径而不是绝对路径
- 在处理前备份原始文件
- 使用临时文件进行中间处理
- 清理不再需要的临时文件

### 2. 错误处理
- 检查文件是否存在和可访问
- 处理文件格式不兼容的情况
- 捕获和处理异常
- 提供有意义的错误信息

### 3. 性能优化
- 对于大文档使用流式处理
- 批量处理时使用多线程
- 缓存重复使用的资源
- 优化内存使用

### 4. 中文处理
- 使用支持中文的字体
- 正确处理中文标点符号
- 考虑中文排版规则
- 处理中文编码问题

## 常见问题

### Q1: 如何处理中文乱码？
A: 确保使用UTF-8编码，使用支持中文的字体（如宋体、微软雅黑）。

### Q2: 如何保留原文档格式？
A: 使用python-docx库可以很好地保留格式，对于复杂格式考虑使用模板。

### Q3: 如何处理大型文档？
A: 使用分块处理，避免一次性加载整个文档到内存。

### Q4: 如何批量处理多个文档？
A: 使用batch_process.py脚本，支持文件夹递归处理。

### Q5: 如何自定义输出格式？
A: 修改模板文件或使用样式配置。

## 扩展功能

### 自定义模块
你可以根据需要添加自定义模块：
1. 在`scripts/custom/`目录中添加新脚本
2. 在`references/custom-guides.md`中添加使用说明
3. 更新SKILL.md中的相关部分

### 集成其他工具
- 与数据库集成：从数据库读取数据生成报告
- 与API集成：调用外部服务处理文档
- 与工作流集成：作为自动化流程的一部分

## 更新日志

### v1.0.0 (2026-03-10)
- 初始版本发布
- 包含所有核心功能
- 完整的中文支持
- 详细的文档和示例

## 技术支持

如有问题或建议：
1. 查看相关参考文档
2. 运行测试脚本验证功能
3. 检查错误日志
4. 联系技能维护者

---

**注意**：本技能需要Python环境和相关依赖库。请确保已安装所有必需的包。