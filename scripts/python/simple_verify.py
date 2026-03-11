#!/usr/bin/env python3
"""
简单验证 NVIDIA 配置
"""

import json
import requests

print("="*60)
print("NVIDIA NIM API 配置验证")
print("="*60)

# 1. 检查配置文件
config_path = r"C:\Users\luchaochao\.openclaw\openclaw.json"
try:
    with open(config_path, 'r', encoding='utf-8') as f:
        config = json.load(f)
    print("[OK] 配置文件加载成功")
    
    # 检查关键配置
    nvidia_auth = config.get("auth", {}).get("profiles", {}).get("nvidia:default", {})
    if nvidia_auth:
        print("[OK] NVIDIA 认证配置存在")
        print(f"    API Key: {nvidia_auth.get('apiKey', '')[0:15]}...")
    else:
        print("[ERROR] NVIDIA 认证配置不存在")
    
    nvidia_models = config.get("models", {}).get("providers", {}).get("nvidia", {})
    if nvidia_models:
        print("[OK] NVIDIA 模型配置存在")
        print(f"    模型数量: {len(nvidia_models.get('models', []))}")
    else:
        print("[ERROR] NVIDIA 模型配置不存在")
    
    primary_model = config.get("agents", {}).get("defaults", {}).get("model", {}).get("primary", "")
    if primary_model:
        print(f"[OK] 主模型配置: {primary_model}")
    else:
        print("[ERROR] 主模型未配置")
        
except Exception as e:
    print(f"[ERROR] 配置文件错误: {e}")

print("\n" + "="*60)
print("测试 API 连接")
print("="*60)

# 2. 测试 API 连接
API_KEY = "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"
BASE_URL = "https://integrate.api.nvidia.com/v1"

headers = {
    "Authorization": f"Bearer {API_KEY}",
    "Content-Type": "application/json"
}

try:
    response = requests.get(f"{BASE_URL}/models", headers=headers, timeout=10)
    if response.status_code == 200:
        models = response.json()
        total = len(models.get('data', []))
        print(f"[OK] API 连接成功")
        print(f"     可用模型: {total}个")
        
        # 检查我们的模型
        our_models = ["meta/llama-3.1-8b-instruct", "google/gemma-2-27b-it", "microsoft/phi-3-mini-128k-instruct"]
        available_ids = [m.get('id', '') for m in models.get('data', [])]
        
        print("\n模型可用性检查:")
        for model in our_models:
            if model in available_ids:
                print(f"  [OK] {model}")
            else:
                print(f"  [MISSING] {model}")
    else:
        print(f"[ERROR] API 连接失败: {response.status_code}")
        
except Exception as e:
    print(f"[ERROR] API 测试失败: {e}")

print("\n" + "="*60)
print("验证总结")
print("="*60)
print("配置已完成！下一步：")
print("1. 重启 OpenClaw 服务")
print("2. 测试模型使用")
print("3. 验证回退链工作正常")