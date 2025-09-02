#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
App Store 截图组织工具 (修复版)
将修复后的截图按设备类型分类整理
"""

import os
import shutil
import re

def organize_screenshots():
    """组织截图文件"""
    source_folder = "App_Store_Screenshots_Fixed"
    
    if not os.path.exists(source_folder):
        print(f"❌ 源文件夹 '{source_folder}' 不存在")
        return
    
    # 设备分类
    device_categories = {
        "iPhone_6_7_8": "iPhone_5_5",
        "iPhone_6_7_8_Plus": "iPhone_5_5_Plus", 
        "iPhone_X_XS": "iPhone_5_8",
        "iPhone_XR": "iPhone_6_1",
        "iPhone_XS_Max": "iPhone_6_5",
        "iPhone_11": "iPhone_6_1",
        "iPhone_11_Pro": "iPhone_5_8",
        "iPhone_11_Pro_Max": "iPhone_6_5",
        "iPhone_12_mini": "iPhone_5_4",
        "iPhone_12": "iPhone_6_1",
        "iPhone_12_Pro": "iPhone_6_1",
        "iPhone_12_Pro_Max": "iPhone_6_7",
        "iPhone_13_mini": "iPhone_5_4",
        "iPhone_13": "iPhone_6_1",
        "iPhone_13_Pro": "iPhone_6_1",
        "iPhone_13_Pro_Max": "iPhone_6_7",
        "iPhone_14": "iPhone_6_1",
        "iPhone_14_Plus": "iPhone_6_7",
        "iPhone_14_Pro": "iPhone_6_1",
        "iPhone_14_Pro_Max": "iPhone_6_7",
        "iPhone_15": "iPhone_6_1",
        "iPhone_15_Plus": "iPhone_6_7",
        "iPhone_15_Pro": "iPhone_6_1",
        "iPhone_15_Pro_Max": "iPhone_6_7",
        "iPhone_16": "iPhone_6_1",
        "iPhone_16_Plus": "iPhone_6_7",
        "iPhone_16_Pro": "iPhone_6_1",
        "iPhone_16_Pro_Max": "iPhone_6_7",
        # 新增的iPhone 6.7"和6.9"尺寸
        "iPhone_6_7_New": "iPhone_6_7_New",
        "iPhone_6_7_Landscape": "iPhone_6_7_Landscape",
        "iPhone_6_9": "iPhone_6_9",
        "iPhone_6_9_Landscape": "iPhone_6_9_Landscape",
        "iPad_9_7": "iPad_9_7",
        "iPad_10_2": "iPad_10_2",
        "iPad_10_9": "iPad_10_9",
        "iPad_11": "iPad_11",
        "iPad_12_9": "iPad_12_9",
        "iPad_Air_10_9": "iPad_10_9",
        "iPad_Air_11": "iPad_11",
        "iPad_Pro_11": "iPad_11",
        "iPad_Pro_12_9": "iPad_12_9",
        "iPad_mini_8_3": "iPad_8_3"
    }
    
    # 创建组织后的文件夹
    organized_folder = "App_Store_Screenshots_Fixed_Organized"
    if os.path.exists(organized_folder):
        shutil.rmtree(organized_folder)
    os.makedirs(organized_folder)
    
    # 获取所有截图文件
    files = [f for f in os.listdir(source_folder) if f.endswith('.png')]
    
    print(f"📱 开始组织 {len(files)} 个修复后的截图文件...")
    
    # 按设备类型分类
    device_files = {}
    
    for file in files:
        # 提取设备类型
        for device_type in device_categories.keys():
            if device_type in file:
                category = device_categories[device_type]
                if category not in device_files:
                    device_files[category] = []
                device_files[category].append(file)
                break
    
    # 创建文件夹并移动文件
    for category, files_list in device_files.items():
        category_folder = os.path.join(organized_folder, category)
        os.makedirs(category_folder, exist_ok=True)
        
        print(f"📁 创建文件夹: {category}")
        
        for file in files_list:
            source_path = os.path.join(source_folder, file)
            dest_path = os.path.join(category_folder, file)
            shutil.copy2(source_path, dest_path)
            print(f"   📄 复制: {file}")
    
    # 创建推荐截图文件夹
    recommended_folder = os.path.join(organized_folder, "Recommended")
    os.makedirs(recommended_folder, exist_ok=True)
    
    # 选择推荐的截图尺寸
    recommended_sizes = [
        "iPhone_6_7_New",    # iPhone 6.7" 新尺寸 (主要展示)
        "iPhone_6_7",        # iPhone 6.7" (兼容性)
        "iPhone_6_5",        # iPhone 6.5" (兼容性)
        "iPhone_5_5_Plus",   # iPhone 5.5" (传统尺寸)
        "iPhone_6_9",        # iPhone 6.9" (最新尺寸)
        "iPad_12_9"          # iPad 12.9" (iPad支持)
    ]
    
    print(f"\n📋 创建推荐截图文件夹...")
    
    for size in recommended_sizes:
        if size in device_files:
            size_folder = os.path.join(recommended_folder, size)
            os.makedirs(size_folder, exist_ok=True)
            
            for file in device_files[size]:
                source_path = os.path.join(source_folder, file)
                dest_path = os.path.join(size_folder, file)
                shutil.copy2(source_path, dest_path)
                print(f"   ⭐ 推荐: {file}")
    
    # 创建使用说明
    create_usage_guide(organized_folder, device_files)
    
    print(f"\n🎉 修复版截图组织完成！")
    print(f"📁 组织后的文件夹: {organized_folder}")
    print(f"📁 推荐截图文件夹: {organized_folder}/Recommended")

def create_usage_guide(folder, device_files):
    """创建使用说明"""
    guide_content = """# App Store 截图使用指南 (修复版)

## 📱 文件夹结构说明

### 推荐截图 (Recommended/)
这些是App Store上架最常用的截图尺寸：

- **iPhone_6_7_New/** - iPhone 6.7" 新尺寸 (1320x2868) - 主要展示尺寸
- **iPhone_6_7/** - iPhone 6.7" (1290x2796) - 兼容性尺寸
- **iPhone_6_5/** - iPhone 6.5" (1242x2688) - 兼容性尺寸  
- **iPhone_5_5_Plus/** - iPhone 5.5" (1242x2208) - 传统尺寸
- **iPhone_6_9/** - iPhone 6.9" (1290x2796) - 最新尺寸
- **iPad_12_9/** - iPad 12.9" (2048x2732) - iPad支持

### 完整设备支持
按设备类型分类的完整截图集合：

#### iPhone 设备
- **iPhone_5_4/** - iPhone 12/13 mini (1080x2340)
- **iPhone_5_5/** - iPhone 6/7/8 (750x1334)
- **iPhone_5_5_Plus/** - iPhone 6/7/8 Plus (1242x2208)
- **iPhone_5_8/** - iPhone X/XS/11 Pro (1125x2436)
- **iPhone_6_1/** - iPhone XR/11/12/13/14/15/16 (828x1792/1170x2532/1179x2556)
- **iPhone_6_5/** - iPhone XS Max/11 Pro Max (1242x2688)
- **iPhone_6_7/** - iPhone 12/13/14/15/16 Pro Max (1284x2778/1290x2796)
- **iPhone_6_7_New/** - iPhone 6.7" 新尺寸 (1320x2868)
- **iPhone_6_7_Landscape/** - iPhone 6.7" 横屏 (2868x1320)
- **iPhone_6_9/** - iPhone 6.9" 竖屏 (1290x2796)
- **iPhone_6_9_Landscape/** - iPhone 6.9" 横屏 (2796x1290)

#### iPad 设备
- **iPad_8_3/** - iPad mini (1488x2266)
- **iPad_9_7/** - iPad 9.7" (1536x2048)
- **iPad_10_2/** - iPad 10.2" (1620x2160)
- **iPad_10_9/** - iPad 10.9" (1640x2360)
- **iPad_11/** - iPad 11" (1668x2388)
- **iPad_12_9/** - iPad 12.9" (2048x2732)

## 📋 App Store 上传要求

### 必需截图
1. **iPhone 截图**: 至少需要 iPhone 6.7" 新尺寸 (1320x2868)
2. **iPad 截图**: 如果支持 iPad，需要 iPad 12.9" 尺寸

### 推荐上传顺序
1. **iPhone_6_7_New** - 主要展示截图 (1320x2868)
2. **iPhone_6_7** - 兼容性截图 (1290x2796)
3. **iPhone_6_5** - 兼容性截图 (1242x2688)
4. **iPhone_5_5_Plus** - 传统设备截图 (1242x2208)
5. **iPhone_6_9** - 最新尺寸截图 (1290x2796)
6. **iPad_12_9** - iPad支持截图 (2048x2732)

## 🎯 使用建议

1. **优先使用推荐尺寸**: 从 Recommended 文件夹选择
2. **内容一致性**: 确保所有尺寸的截图内容一致
3. **质量保证**: 使用高质量的原图，避免模糊
4. **测试验证**: 在 App Store Connect 中预览效果

## 📁 文件命名说明

文件名格式：`原始文件名_设备类型_尺寸.png`

例如：
- `IMG_4857_iPhone_6_7_New_1320x2868.png`
- `IMG_4857_iPhone_6_9_1290x2796.png`
- `IMG_4857_iPad_Pro_12_9_2048x2732.png`

## 🔧 快速选择

### 只上传iPhone版本
使用 `Recommended/iPhone_6_7_New/` 文件夹中的截图

### 同时支持iPhone和iPad
使用 `Recommended/` 文件夹中的所有截图

### 完整设备支持
根据需要选择对应设备文件夹中的截图

## ✅ 修复说明

此版本修复了以下问题：
- ✅ 图片尺寸与文件名完全一致
- ✅ 移除了设备边框，生成纯截图
- ✅ 所有尺寸都经过验证
- ✅ 符合App Store官方要求
- ✅ 新增iPhone 6.7"和6.9"最新尺寸支持
"""
    
    guide_path = os.path.join(folder, "README.md")
    with open(guide_path, 'w', encoding='utf-8') as f:
        f.write(guide_content)
    
    print(f"📖 已创建使用指南: {guide_path}")

if __name__ == "__main__":
    organize_screenshots()
