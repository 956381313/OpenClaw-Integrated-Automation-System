#!/usr/bin/env python3
"""
简单磁盘检查脚本 - 无特殊字符版本
"""

import shutil
import os

def check_disk_usage():
    """检查磁盘使用情况"""
    print("="*50)
    print("  磁盘状态检查")
    print("="*50)
    
    # 获取磁盘使用情况
    usage = shutil.disk_usage("C:/")
    
    # 计算GB
    total_gb = usage.total / (1024**3)
    used_gb = usage.used / (1024**3)
    free_gb = usage.free / (1024**3)
    
    # 计算百分比
    usage_percent = (used_gb / total_gb) * 100
    
    print(f"磁盘 C: 信息:")
    print(f"  总容量: {total_gb:.2f} GB")
    print(f"  已使用: {used_gb:.2f} GB")
    print(f"  可用空间: {free_gb:.2f} GB")
    print(f"  使用率: {usage_percent:.2f}%")
    print()
    
    # 检查阈值
    threshold = 85
    if usage_percent > threshold:
        print(f"[警告] 磁盘使用率超过 {threshold}%!")
        print(f"   建议清理临时文件")
        return True
    else:
        print(f"[正常] 磁盘使用率在安全范围内")
        return False

def main():
    """主函数"""
    try:
        needs_cleanup = check_disk_usage()
        
        print()
        print("="*50)
        if needs_cleanup:
            print("建议执行清理操作")
            print("可以使用自动化系统: auto-system-english.ps1")
        else:
            print("系统状态良好")
        print("="*50)
        
    except Exception as e:
        print(f"错误: {e}")

if __name__ == "__main__":
    main()