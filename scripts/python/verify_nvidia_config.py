#!/usr/bin/env python3
"""
验证 NVIDIA NIM API 配置是否生效
"""

import json
import os

def check_config_file():
    """检查配置文件"""
    config_path = r"C:\Users\luchaochao\.openclaw\openclaw.json"
    
    print("="*60)
    print("验证 OpenClaw 配置文件")
    print("="*60)
    
    if not os.path.exists(config_path):
        print(f"[错误] 配置文件不存在: {config_path}")
        return False
    
    try:
        with open(config_path, 'r', encoding='utf-8') as f:
            config = json.load(f)
        
        print(f"[成功] 配置文件加载成功")
        
        # 检查 NVIDIA 配置
        if "auth" in config and "profiles" in config["auth"]:
            if "nvidia:default" in config["auth"]["profiles"]:
                nvidia_config = config["auth"]["profiles"]["nvidia:default"]
                print(f"[成功] NVIDIA 认证配置存在")
                print(f"       Provider: {nvidia_config.get('provider', 'N/A')}")
                print(f"       Mode: {nvidia_config.get('mode', 'N/A')}")
                api_key = nvidia_config.get('apiKey', '')
                if api_key:
                    print(f"       API Key: {api_key[:15]}...{api_key[-10:]}")
                else:
                    print(f"[警告] API Key 为空")
            else:
                print(f"[错误] NVIDIA 认证配置不存在")
                return False
        else:
            print(f"[错误] 认证配置部分不存在")
            return False
        
        # 检查模型配置
        if "models" in config and "providers" in config["models"]:
            if "nvidia" in config["models"]["providers"]:
                nvidia_models = config["models"]["providers"]["nvidia"]
                print(f"[成功] NVIDIA 模型配置存在")
                print(f"       Base URL: {nvidia_models.get('baseUrl', 'N/A')}")
                
                models = nvidia_models.get('models', [])
                print(f"       配置模型数量: {len(models)}")
                for model in models:
                    print(f"         - {model.get('id', '未知')}: {model.get('name', '未知')}")
            else:
                print(f"[错误] NVIDIA 模型配置不存在")
                return False
        else:
            print(f"[错误] 模型配置部分不存在")
            return False
        
        # 检查代理配置
        if "agents" in config and "defaults" in config["agents"]:
            defaults = config["agents"]["defaults"]
            if "model" in defaults:
                model_config = defaults["model"]
                print(f"[成功] 代理模型配置存在")
                print(f"       主模型: {model_config.get('primary', 'N/A')}")
                
                fallbacks = model_config.get('fallbacks', [])
                if fallbacks:
                    print(f"       备选模型 ({len(fallbacks)}个):")
                    for fb in fallbacks:
                        print(f"         - {fb}")
                else:
                    print(f"[警告] 无备选模型配置")
            else:
                print(f"[警告] 代理模型配置不存在")
        else:
            print(f"[警告] 代理配置部分不存在")
        
        return True
        
    except json.JSONDecodeError as e:
        print(f"[错误] JSON 解析失败: {e}")
        return False
    except Exception as e:
        print(f"[错误] 读取配置文件失败: {e}")
        return False

def test_nvidia_api():
    """测试 NVIDIA API 连接"""
    print("\n" + "="*60)
    print("测试 NVIDIA NIM API 连接")
    print("="*60)
    
    import requests
    import time
    
    API_KEY = "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"
    BASE_URL = "https://integrate.api.nvidia.com/v1"
    
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }
    
    # 测试获取模型列表
    try:
        print("正在测试 API 连接...")
        start_time = time.time()
        response = requests.get(
            f"{BASE_URL}/models",
            headers=headers,
            timeout=10
        )
        end_time = time.time()
        
        response_time = round((end_time - start_time) * 1000, 2)
        
        if response.status_code == 200:
            models = response.json()
            total_models = len(models.get('data', []))
            print(f"[成功] API 连接测试通过")
            print(f"       响应时间: {response_time}ms")
            print(f"       可用模型: {total_models}个")
            
            # 检查配置的模型是否可用
            configured_models = ["meta/llama-3.1-8b-instruct", "google/gemma-2-27b-it", "microsoft/phi-3-mini-128k-instruct"]
            available_model_ids = [m.get('id', '') for m in models.get('data', [])]
            
            print(f"\n检查配置模型可用性:")
            for model_id in configured_models:
                if model_id in available_model_ids:
                    print(f"   ✅ {model_id} - 可用")
                else:
                    print(f"   ❌ {model_id} - 不可用")
            
            return True
        else:
            print(f"[失败] API 连接测试失败")
            print(f"       状态码: {response.status_code}")
            print(f"       错误信息: {response.text[:200]}")
            return False
            
    except requests.exceptions.Timeout:
        print("[失败] 连接超时")
        return False
    except requests.exceptions.ConnectionError:
        print("[失败] 连接错误")
        return False
    except Exception as e:
        print(f"[失败] 未知错误: {e}")
        return False

def main():
    """主函数"""
    import time as time_module
    print("NVIDIA NIM API 配置验证工具")
    print(f"时间: {time_module.strftime('%Y-%m-%d %H:%M:%S')}")
    
    # 检查配置文件
    config_ok = check_config_file()
    
    if not config_ok:
        print("\n[错误] 配置文件检查失败，请检查配置")
        return
    
    # 测试 API 连接
    api_ok = test_nvidia_api()
    
    # 总结
    print("\n" + "="*60)
    print("验证总结")
    print("="*60)
    
    if config_ok and api_ok:
        print("[成功] ✅ 所有检查通过！")
        print("\n下一步:")
        print("  1. 重启 OpenClaw 服务:")
        print("     openclaw gateway restart")
        print("  2. 验证模型切换:")
        print("     /session_status")
        print("  3. 测试模型使用:")
        print("     发送消息测试 Llama 3.1 8B 模型")
    elif config_ok and not api_ok:
        print("[警告] ⚠️ 配置文件正确，但 API 连接失败")
        print("      请检查网络连接和 API 密钥")
    elif not config_ok and api_ok:
        print("[警告] ⚠️ API 连接正常，但配置文件有问题")
        print("      请检查 openclaw.json 配置文件")
    else:
        print("[错误] ❌ 配置文件和 API 连接都有问题")
        print("      请检查配置和网络连接")

if __name__ == "__main__":
    import time as time_module
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n[中断] 用户中断验证")
    except Exception as e:
        print(f"\n[异常] 程序异常: {e}")