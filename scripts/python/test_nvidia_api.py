#!/usr/bin/env python3
"""
NVIDIA NIM API 测试脚本
测试你的 API 密钥和模型可用性
"""

import requests
import json
import time
from datetime import datetime

# 你的 NVIDIA API 密钥
API_KEY = "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"
BASE_URL = "https://integrate.api.nvidia.com/v1"

def print_header(text):
    """打印标题"""
    print(f"\n{'='*60}")
    print(f"🧪 {text}")
    print(f"{'='*60}")

def test_api_connection():
    """测试 API 连接和获取模型列表"""
    print_header("测试 API 连接")
    
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }
    
    try:
        # 测试获取模型列表
        print("📡 正在连接到 NVIDIA NIM API...")
        response = requests.get(
            f"{BASE_URL}/models",
            headers=headers,
            timeout=10
        )
        
        if response.status_code == 200:
            models = response.json()
            total_models = len(models.get('data', []))
            print(f"✅ API 连接成功！")
            print(f"📊 可用模型数量: {total_models}")
            
            # 显示前10个模型
            print("\n📋 前10个可用模型:")
            for i, model in enumerate(models.get('data', [])[:10], 1):
                model_id = model.get('id', '未知')
                print(f"  {i:2d}. {model_id}")
            
            return True, total_models
        else:
            print(f"❌ API 连接失败 - 状态码: {response.status_code}")
            print(f"   错误信息: {response.text[:200]}")
            return False, 0
            
    except requests.exceptions.Timeout:
        print("❌ 连接超时 - 请检查网络连接")
        return False, 0
    except requests.exceptions.ConnectionError:
        print("❌ 连接错误 - 无法连接到服务器")
        return False, 0
    except Exception as e:
        print(f"❌ 未知错误: {e}")
        return False, 0

def test_specific_model(model_id, prompt="请用中文简单介绍一下你自己"):
    """测试特定模型"""
    print(f"\n🔍 测试模型: {model_id}")
    
    url = f"{BASE_URL}/chat/completions"
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }
    
    data = {
        "model": model_id,
        "messages": [{"role": "user", "content": prompt}],
        "max_tokens": 100,
        "temperature": 0.7,
        "stream": False
    }
    
    try:
        start_time = time.time()
        response = requests.post(url, headers=headers, json=data, timeout=30)
        end_time = time.time()
        
        response_time = round((end_time - start_time) * 1000, 2)  # 毫秒
        
        if response.status_code == 200:
            result = response.json()
            content = result['choices'][0]['message']['content'].strip()
            
            print(f"✅ 测试成功")
            print(f"   ⏱️  响应时间: {response_time}ms")
            print(f"   💬 响应内容: {content[:80]}...")
            
            if 'usage' in result:
                usage = result['usage']
                print(f"   📊 Token使用:")
                print(f"      - 输入: {usage.get('prompt_tokens', 'N/A')}")
                print(f"      - 输出: {usage.get('completion_tokens', 'N/A')}")
                print(f"      - 总计: {usage.get('total_tokens', 'N/A')}")
            
            return True, response_time, content
            
        else:
            print(f"❌ 测试失败 - 状态码: {response.status_code}")
            print(f"   错误信息: {response.text[:200]}")
            return False, response_time, None
            
    except requests.exceptions.Timeout:
        print("❌ 请求超时")
        return False, 0, None
    except Exception as e:
        print(f"❌ 未知错误: {e}")
        return False, 0, None

def test_recommended_models():
    """测试推荐的模型"""
    print_header("测试推荐模型")
    
    # 推荐的模型列表
    recommended_models = [
        {
            "id": "meta/llama-3.1-8b-instruct",
            "name": "Llama 3.1 8B",
            "prompt": "请用中文简单介绍一下你自己，并说明你的主要能力"
        },
        {
            "id": "google/gemma-2-27b-it",
            "name": "Gemma 2 27B",
            "prompt": "请用中文介绍一下 Google Gemma 2 模型的特点和优势"
        },
        {
            "id": "microsoft/phi-3-mini-128k-instruct",
            "name": "Phi 3 Mini 128K",
            "prompt": "请用中文解释一下 Phi 3 Mini 模型的 128K 上下文窗口有什么优势"
        },
        {
            "id": "deepseek-ai/deepseek-coder-6.7b-instruct",
            "name": "DeepSeek Coder 6.7B",
            "prompt": "请用中文写一个简单的 Python 函数，计算斐波那契数列"
        }
    ]
    
    results = []
    
    for model_info in recommended_models:
        success, response_time, content = test_specific_model(
            model_info["id"],
            model_info["prompt"]
        )
        
        results.append({
            "model": model_info["name"],
            "id": model_info["id"],
            "success": success,
            "response_time": response_time,
            "content_preview": content[:50] + "..." if content else None
        })
        
        # 避免请求过于频繁
        if model_info != recommended_models[-1]:
            time.sleep(1)
    
    return results

def generate_config_suggestion(results):
    """根据测试结果生成配置建议"""
    print_header("配置建议")
    
    # 找出成功的模型
    successful_models = [r for r in results if r["success"]]
    
    if not successful_models:
        print("❌ 没有模型测试成功，无法生成配置建议")
        return
    
    # 按响应时间排序（从快到慢）
    successful_models.sort(key=lambda x: x["response_time"])
    
    print("✅ 测试成功的模型（按响应速度排序）:")
    for i, model in enumerate(successful_models, 1):
        print(f"  {i}. {model['model']} ({model['id']})")
        print(f"     响应时间: {model['response_time']}ms")
    
    # 生成配置建议
    print("\n🎯 推荐配置策略:")
    print(f"  主模型: {successful_models[0]['model']} (最快)")
    
    if len(successful_models) > 1:
        print("  备选模型:")
        for i, model in enumerate(successful_models[1:], 2):
            print(f"    {i}. {model['model']}")
    
    # 生成 OpenClaw 配置片段
    print("\n📋 OpenClaw 配置代码片段:")
    print("```json")
    print('"agents": {')
    print('  "defaults": {')
    print('    "model": {')
    print(f'      "primary": "nvidia/{successful_models[0]["id"]}",')
    print('      "fallbacks": [')
    
    for i, model in enumerate(successful_models[1:], 1):
        comma = "," if i < len(successful_models) - 1 else ""
        print(f'        "nvidia/{model["id"]}"{comma}')
    
    print('      ]')
    print('    }')
    print('  }')
    print('}')
    print("```")

def main():
    """主函数"""
    print_header("NVIDIA NIM API 测试工具")
    print(f"🕐 开始时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"🔑 API 密钥: {API_KEY[:15]}...{API_KEY[-10:]}")
    
    # 测试 API 连接
    connection_success, model_count = test_api_connection()
    
    if not connection_success:
        print("\n❌ API 连接测试失败，请检查:")
        print("   1. API 密钥是否正确")
        print("   2. 网络连接是否正常")
        print("   3. 防火墙或代理设置")
        return
    
    # 测试推荐模型
    results = test_recommended_models()
    
    # 生成配置建议
    generate_config_suggestion(results)
    
    # 总结
    print_header("测试总结")
    total_tests = len(results)
    successful_tests = len([r for r in results if r["success"]])
    
    print(f"📊 测试统计:")
    print(f"   总测试模型: {total_tests}")
    print(f"   成功模型: {successful_tests}")
    print(f"   失败模型: {total_tests - successful_tests}")
    
    if successful_tests > 0:
        print("\n✅ 测试成功！可以开始配置 OpenClaw。")
        print("\n🚀 下一步:")
        print("   1. 备份当前 OpenClaw 配置")
        print("   2. 更新 openclaw.json 文件")
        print("   3. 重启 OpenClaw 服务")
        print("   4. 验证配置生效")
    else:
        print("\n❌ 所有模型测试失败，请检查:")
        print("   1. API 密钥权限")
        print("   2. 模型ID是否正确")
        print("   3. 网络连接问题")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⚠️ 用户中断测试")
    except Exception as e:
        print(f"\n❌ 程序异常: {e}")