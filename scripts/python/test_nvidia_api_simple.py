#!/usr/bin/env python3
"""
NVIDIA NIM API 测试脚本 - 简化版（兼容Windows编码）
"""

import requests
import json
import time
import sys

# 你的 NVIDIA API 密钥
API_KEY = "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"
BASE_URL = "https://integrate.api.nvidia.com/v1"

def print_section(title):
    """打印章节标题"""
    print("\n" + "="*60)
    print(f"  {title}")
    print("="*60)

def test_api_connection():
    """测试 API 连接"""
    print_section("测试 API 连接")
    
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }
    
    try:
        print("正在连接到 NVIDIA NIM API...")
        response = requests.get(
            f"{BASE_URL}/models",
            headers=headers,
            timeout=10
        )
        
        if response.status_code == 200:
            models = response.json()
            total_models = len(models.get('data', []))
            print(f"[成功] API 连接成功！")
            print(f"[信息] 可用模型数量: {total_models}")
            
            # 显示前5个模型
            print("\n前5个可用模型:")
            for i, model in enumerate(models.get('data', [])[:5], 1):
                model_id = model.get('id', '未知')
                print(f"  {i}. {model_id}")
            
            return True, total_models
        else:
            print(f"[失败] API 连接失败 - 状态码: {response.status_code}")
            print(f"       错误信息: {response.text[:200]}")
            return False, 0
            
    except requests.exceptions.Timeout:
        print("[失败] 连接超时 - 请检查网络连接")
        return False, 0
    except requests.exceptions.ConnectionError:
        print("[失败] 连接错误 - 无法连接到服务器")
        return False, 0
    except Exception as e:
        print(f"[失败] 未知错误: {e}")
        return False, 0

def test_model(model_id, prompt="请用中文简单介绍一下你自己"):
    """测试特定模型"""
    print(f"\n测试模型: {model_id}")
    
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
            
            print(f"[成功] 测试成功")
            print(f"       响应时间: {response_time}ms")
            print(f"       响应内容: {content[:80]}...")
            
            if 'usage' in result:
                usage = result['usage']
                print(f"       Token使用:")
                print(f"         输入: {usage.get('prompt_tokens', 'N/A')}")
                print(f"         输出: {usage.get('completion_tokens', 'N/A')}")
                print(f"         总计: {usage.get('total_tokens', 'N/A')}")
            
            return True, response_time, content
            
        else:
            print(f"[失败] 测试失败 - 状态码: {response.status_code}")
            print(f"       错误信息: {response.text[:200]}")
            return False, response_time, None
            
    except requests.exceptions.Timeout:
        print("[失败] 请求超时")
        return False, 0, None
    except Exception as e:
        print(f"[失败] 未知错误: {e}")
        return False, 0, None

def main():
    """主函数"""
    print_section("NVIDIA NIM API 测试工具")
    print(f"开始时间: {time.strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"API 密钥: {API_KEY[:15]}...{API_KEY[-10:]}")
    
    # 测试 API 连接
    connection_success, model_count = test_api_connection()
    
    if not connection_success:
        print("\n[错误] API 连接测试失败，请检查:")
        print("  1. API 密钥是否正确")
        print("  2. 网络连接是否正常")
        print("  3. 防火墙或代理设置")
        return
    
    # 测试推荐的模型
    print_section("测试推荐模型")
    
    models_to_test = [
        ("meta/llama-3.1-8b-instruct", "Llama 3.1 8B", "请用中文简单介绍一下你自己"),
        ("google/gemma-2-27b-it", "Gemma 2 27B", "请用中文介绍一下 Google Gemma 2 模型的特点"),
        ("microsoft/phi-3-mini-128k-instruct", "Phi 3 Mini 128K", "请用中文解释一下 128K 上下文窗口的优势"),
        ("deepseek-ai/deepseek-coder-6.7b-instruct", "DeepSeek Coder 6.7B", "请用中文写一个简单的 Python 函数")
    ]
    
    results = []
    
    for model_id, model_name, prompt in models_to_test:
        success, response_time, content = test_model(model_id, prompt)
        
        results.append({
            "model": model_name,
            "id": model_id,
            "success": success,
            "response_time": response_time
        })
        
        # 避免请求过于频繁
        if (model_id, model_name, prompt) != models_to_test[-1]:
            time.sleep(1)
    
    # 生成配置建议
    print_section("配置建议")
    
    # 找出成功的模型
    successful_models = [r for r in results if r["success"]]
    
    if not successful_models:
        print("[警告] 没有模型测试成功，无法生成配置建议")
        return
    
    # 按响应时间排序（从快到慢）
    successful_models.sort(key=lambda x: x["response_time"])
    
    print("测试成功的模型（按响应速度排序）:")
    for i, model in enumerate(successful_models, 1):
        print(f"  {i}. {model['model']} ({model['id']})")
        print(f"     响应时间: {model['response_time']}ms")
    
    # 生成配置建议
    print("\n推荐配置策略:")
    print(f"  主模型: {successful_models[0]['model']} (最快)")
    
    if len(successful_models) > 1:
        print("  备选模型:")
        for i, model in enumerate(successful_models[1:], 2):
            print(f"    {i}. {model['model']}")
    
    # 生成 OpenClaw 配置片段
    print("\nOpenClaw 配置代码片段:")
    print('{')
    print('  "agents": {')
    print('    "defaults": {')
    print('      "model": {')
    print(f'        "primary": "nvidia/{successful_models[0]["id"]}",')
    print('        "fallbacks": [')
    
    for i, model in enumerate(successful_models[1:], 1):
        comma = "," if i < len(successful_models) - 1 else ""
        print(f'          "nvidia/{model["id"]}"{comma}')
    
    print('        ]')
    print('      }')
    print('    }')
    print('  }')
    print('}')
    
    # 总结
    print_section("测试总结")
    total_tests = len(results)
    successful_tests = len(successful_models)
    
    print(f"测试统计:")
    print(f"  总测试模型: {total_tests}")
    print(f"  成功模型: {successful_tests}")
    print(f"  失败模型: {total_tests - successful_tests}")
    
    if successful_tests > 0:
        print("\n[成功] 测试完成！可以开始配置 OpenClaw。")
        print("\n下一步:")
        print("  1. 备份当前 OpenClaw 配置")
        print("  2. 更新 openclaw.json 文件")
        print("  3. 重启 OpenClaw 服务")
        print("  4. 验证配置生效")
    else:
        print("\n[失败] 所有模型测试失败")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n[中断] 用户中断测试")
    except Exception as e:
        print(f"\n[异常] 程序异常: {e}")