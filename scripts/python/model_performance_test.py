#!/usr/bin/env python3
"""
模型性能测试脚本
测试 NVIDIA 模型的响应时间和质量
"""

import time
import json

def test_model_performance():
    """测试模型性能"""
    print("="*60)
    print("  模型性能测试")
    print("="*60)
    
    print("当前配置的模型链:")
    print("  1. Llama 3.1 8B (主模型，最快)")
    print("  2. Gemma 2 27B (高质量)")
    print("  3. Phi 3 Mini 128K (长上下文)")
    print("  4. DeepSeek Chat (保底)")
    print()
    
    # 测试用例
    test_cases = [
        {
            "name": "快速响应测试",
            "description": "测试日常聊天的响应速度",
            "prompt": "请用中文简单介绍一下你自己",
            "expected_model": "Llama 3.1 8B"
        },
        {
            "name": "质量对比测试",
            "description": "测试复杂问题的回答质量",
            "prompt": "请详细解释一下人工智能的三大核心要素",
            "expected_model": "Gemma 2 27B"
        },
        {
            "name": "长上下文测试",
            "description": "测试处理长文本的能力",
            "prompt": "请总结以下关于机器学习的要点：" + "机器学习是人工智能的一个分支。" * 20,
            "expected_model": "Phi 3 Mini 128K"
        }
    ]
    
    print("测试计划:")
    for i, test in enumerate(test_cases, 1):
        print(f"  {i}. {test['name']}")
        print(f"     描述: {test['description']}")
        print(f"     预期模型: {test['expected_model']}")
    print()
    
    print("测试方法:")
    print("  1. 使用当前配置的模型链")
    print("  2. 记录响应时间和质量")
    print("  3. 验证智能模型选择")
    print("  4. 测试回退功能")
    print()
    
    print("性能指标:")
    print("  - 响应时间: <3秒 (日常任务)")
    print("  - 响应质量: 相关、准确、完整")
    print("  - 稳定性: 连续请求无失败")
    print("  - 回退功能: 主模型失败时自动切换")
    print()
    
    print("执行建议:")
    print("  1. 发送测试prompt观察响应")
    print("  2. 检查/session_status确认模型")
    print("  3. 测试手动模型切换")
    print("  4. 模拟失败测试回退")
    print()
    
    print("="*60)
    print("  立即开始测试")
    print("="*60)
    
    print("第一步: 测试当前模型 (应该是 Llama 3.1 8B)")
    print("请发送: '请用中文简单介绍一下你自己'")
    print()
    
    print("第二步: 检查模型状态")
    print("在聊天中输入: /session_status")
    print()
    
    print("第三步: 测试模型切换")
    print("尝试切换到 Gemma 2 27B:")
    print("在聊天中输入: /session_status model=nvidia/google/gemma-2-27b-it")
    print()
    
    print("第四步: 测试回退功能")
    print("模拟主模型失败，观察是否自动切换到备选模型")
    print()
    
    print("第五步: 记录测试结果")
    print("记录每个模型的响应时间和质量")
    print()

def generate_test_report():
    """生成测试报告模板"""
    report = {
        "测试时间": time.strftime("%Y-%m-%d %H:%M:%S"),
        "测试环境": {
            "OpenClaw版本": "0.1.7",
            "当前模型": "nvidia/meta/llama-3.1-8b-instruct",
            "配置模型": [
                "nvidia/meta/llama-3.1-8b-instruct",
                "nvidia/google/gemma-2-27b-it",
                "nvidia/microsoft/phi-3-mini-128k-instruct",
                "deepseek/deepseek-chat"
            ]
        },
        "测试用例": [
            {
                "名称": "快速响应测试",
                "prompt": "请用中文简单介绍一下你自己",
                "预期模型": "Llama 3.1 8B",
                "结果": {
                    "实际模型": "",
                    "响应时间": "",
                    "响应质量": "",
                    "备注": ""
                }
            },
            {
                "名称": "质量对比测试",
                "prompt": "请详细解释一下人工智能的三大核心要素",
                "预期模型": "Gemma 2 27B",
                "结果": {
                    "实际模型": "",
                    "响应时间": "",
                    "响应质量": "",
                    "备注": ""
                }
            },
            {
                "名称": "长上下文测试",
                "prompt": "请总结以下关于机器学习的要点：" + "机器学习是人工智能的一个分支。" * 20,
                "预期模型": "Phi 3 Mini 128K",
                "结果": {
                    "实际模型": "",
                    "响应时间": "",
                    "响应质量": "",
                    "备注": ""
                }
            }
        ],
        "回退功能测试": {
            "描述": "模拟主模型失败，测试自动切换到备选模型",
            "结果": {
                "回退触发": "",
                "切换时间": "",
                "最终模型": "",
                "备注": ""
            }
        },
        "总结": {
            "总体性能": "",
            "建议优化": "",
            "结论": ""
        }
    }
    
    # 保存报告模板
    report_file = f"model_test_report_{time.strftime('%Y%m%d_%H%M%S')}.json"
    with open(report_file, 'w', encoding='utf-8') as f:
        json.dump(report, f, ensure_ascii=False, indent=2)
    
    print(f"测试报告模板已生成: {report_file}")
    print("请在测试过程中填写结果")
    return report_file

def main():
    """主函数"""
    print("模型性能测试工具")
    print(f"时间: {time.strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    # 显示测试计划
    test_model_performance()
    
    # 生成测试报告
    report_file = generate_test_report()
    
    print("="*60)
    print("下一步行动:")
    print("  1. 按照上面的步骤进行测试")
    print("  2. 记录测试结果到报告文件")
    print("  3. 分析性能数据")
    print("  4. 优化模型配置")
    print()
    print(f"报告文件: {report_file}")
    print("="*60)

if __name__ == "__main__":
    main()