#!/usr/bin/env python3
"""
简单磁盘检查脚本
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
        print(f"⚠️ 警告: 磁盘使用率超过 {threshold}%!")
        print(f"   建议清理临时文件")
        print()
        print("建议清理:")
        print("  1. 工作空间临时文件")
        print("  2. 系统临时文件夹")
        print("  3. 浏览器缓存")
        return True
    else:
        print(f"✅ 状态正常: 磁盘使用率在安全范围内")
        return False

def check_workspace():
    """检查工作空间"""
    workspace = r"C:\Users\luchaochao\.openclaw\workspace"
    print()
    print("工作空间检查:")
    
    if os.path.exists(workspace):
        # 计算工作空间大小
        total_size = 0
        for dirpath, dirnames, filenames in os.walk(workspace):
            for f in filenames:
                fp = os.path.join(dirpath, f)
                try:
                    total_size += os.path.getsize(fp)
                except:
                    pass
        
        workspace_gb = total_size / (1024**3)
        print(f"  工作空间大小: {workspace_gb:.2f} GB")
        
        # 检查临时文件
        temp_files = []
        for root, dirs, files in os.walk(workspace):
            for file in files:
                if file.endswith(('.tmp', '.temp', '.log', '.cache')):
                    temp_files.append(os.path.join(root, file))
        
        print(f"  临时文件数量: {len(temp_files)}")
        
        if temp_files:
            print("  建议清理的临时文件:")
            for i, file in enumerate(temp_files[:5]):  # 只显示前5个
                size_mb = os.path.getsize(file) / (1024**2) if os.path.exists(file) else 0
                print(f"    - {os.path.basename(file)} ({size_mb:.2f} MB)")
            if len(temp_files) > 5:
                print(f"    ... 还有 {len(temp_files)-5} 个文件")
    else:
        print(f"  工作空间不存在: {workspace}")

def main():
    """主函数"""
    try:
        needs_cleanup = check_disk_usage()
        check_workspace()
        
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