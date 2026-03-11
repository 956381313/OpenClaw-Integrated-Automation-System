# NVIDIA 可用模型列表总结

## 📊 总览
- **总模型数**: 187 个
- **API 状态**: ✅ 正常工作
- **提供者**: NVIDIA NIM API

## 🏆 推荐模型（免费开源）

### 1. **Meta Llama 系列**（最受欢迎的开源模型）
- `meta/llama-3.1-70b-instruct` - 70B 参数，性能优秀
- `meta/llama-3.1-8b-instruct` - 8B 参数，轻量高效
- `meta/llama-3.2-11b-vision-instruct` - 11B，支持视觉
- `meta/llama-3.3-70b-instruct` - 最新版本，70B
- `meta/llama-4-maverick-17b-128e-instruct` - Llama 4 系列

### 2. **Google Gemma 系列**（Google 开源）
- `google/gemma-2-27b-it` - 27B 参数
- `google/gemma-2-9b-it` - 9B 参数
- `google/gemma-3-12b-it` - 最新 Gemma 3，12B
- `google/gemma-3-27b-it` - 最新 Gemma 3，27B

### 3. **Microsoft Phi 系列**（轻量高效）
- `microsoft/phi-3-medium-128k-instruct` - 中等规模，128K上下文
- `microsoft/phi-3-mini-128k-instruct` - 迷你版，128K上下文
- `microsoft/phi-3.5-mini-instruct` - Phi 3.5 迷你版
- `microsoft/phi-4-mini-instruct` - 最新 Phi 4

### 4. **Mistral AI 系列**（法国开源）
- `mistralai/mistral-large-2-instruct` - Mistral Large 2
- `mistralai/mistral-7b-instruct-v0.3` - 7B 基础版
- `mistralai/mixtral-8x7b-instruct-v0.1` - MoE 模型，8x7B

### 5. **DeepSeek 系列**（中国开源）
- `deepseek-ai/deepseek-v3.1` - DeepSeek V3.1
- `deepseek-ai/deepseek-v3.2` - DeepSeek V3.2
- `deepseek-ai/deepseek-coder-6.7b-instruct` - 代码专用

### 6. **Qwen 系列**（阿里开源）
- `qwen/qwen2.5-7b-instruct` - Qwen 2.5，7B
- `qwen/qwen2.5-coder-32b-instruct` - 代码专用，32B
- `qwen/qwen3-next-80b-a3b-instruct` - Qwen 3 Next，80B

### 7. **NVIDIA 自家模型**
- `nvidia/nemotron-4-340b-instruct` - 340B 超大模型
- `nvidia/llama-3.1-nemotron-70b-instruct` - Llama 3.1 + NVIDIA 优化
- `nvidia/nemotron-mini-4b-instruct` - 迷你版，4B

## 🎯 按用途推荐

### **通用聊天/助手**
1. `meta/llama-3.1-70b-instruct` - 平衡性能与质量
2. `google/gemma-2-27b-it` - Google 出品，质量优秀
3. `mistralai/mistral-large-2-instruct` - 法语优化，多语言

### **代码编程**
1. `deepseek-ai/deepseek-coder-6.7b-instruct` - 专门代码模型
2. `qwen/qwen2.5-coder-32b-instruct` - 大代码模型
3. `meta/codellama-70b` - CodeLlama，70B

### **轻量/快速响应**
1. `microsoft/phi-3-mini-128k-instruct` - 轻量，长上下文
2. `meta/llama-3.1-8b-instruct` - 8B，响应快
3. `google/gemma-2-2b-it` - 超轻量，2B

### **多模态（视觉+文本）**
1. `meta/llama-3.2-11b-vision-instruct` - Llama 3.2 视觉版
2. `microsoft/phi-3-vision-128k-instruct` - Phi 3 视觉版
3. `nvidia/llama-3.1-nemotron-nano-vl-8b-v1` - NVIDIA 视觉语言模型

## ⚙️ 配置建议

### 初级用户推荐
```yaml
主模型: meta/llama-3.1-8b-instruct
备选1: microsoft/phi-3-mini-128k-instruct
备选2: google/gemma-2-2b-it
```

### 高级用户推荐
```yaml
主模型: meta/llama-3.1-70b-instruct
备选1: nvidia/nemotron-4-340b-instruct
备选2: qwen/qwen3-next-80b-a3b-instruct
代码专用: deepseek-ai/deepseek-coder-6.7b-instruct
```

### 平衡型推荐
```yaml
主模型: google/gemma-2-27b-it
备选1: mistralai/mistral-large-2-instruct
备选2: deepseek-ai/deepseek-v3.2
轻量备用: microsoft/phi-3.5-mini-instruct
```

## 📝 注意事项
1. **免费额度**: NVIDIA API 可能有免费额度限制
2. **速率限制**: 注意 API 调用频率限制
3. **模型大小**: 越大模型响应越慢，但质量可能更高
4. **上下文长度**: 注意不同模型的上下文长度限制

## 🔧 下一步操作
1. 选择 1-3 个模型进行测试
2. 配置到 OpenClaw 中
3. 设置回退链（主模型 → 备选1 → 备选2）
4. 测试模型切换功能