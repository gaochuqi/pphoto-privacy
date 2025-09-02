#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
App Store 截图生成工具 (修复版)
确保生成的截图尺寸与文件名完全一致
"""

import os
import sys
from PIL import Image, ImageDraw, ImageFont
import math

# App Store 截图尺寸要求
SCREENSHOT_SIZES = {
    # iPhone 截图尺寸
    "iPhone_6_7_8": (750, 1334),      # iPhone 6, 7, 8
    "iPhone_6_7_8_Plus": (1242, 2208), # iPhone 6 Plus, 7 Plus, 8 Plus
    "iPhone_X_XS": (1125, 2436),      # iPhone X, XS
    "iPhone_XR": (828, 1792),         # iPhone XR
    "iPhone_XS_Max": (1242, 2688),    # iPhone XS Max
    "iPhone_11": (828, 1792),         # iPhone 11
    "iPhone_11_Pro": (1125, 2436),    # iPhone 11 Pro
    "iPhone_11_Pro_Max": (1242, 2688), # iPhone 11 Pro Max
    "iPhone_12_mini": (1080, 2340),   # iPhone 12 mini
    "iPhone_12": (1170, 2532),        # iPhone 12
    "iPhone_12_Pro": (1170, 2532),    # iPhone 12 Pro
    "iPhone_12_Pro_Max": (1284, 2778), # iPhone 12 Pro Max
    "iPhone_13_mini": (1080, 2340),   # iPhone 13 mini
    "iPhone_13": (1170, 2532),        # iPhone 13
    "iPhone_13_Pro": (1170, 2532),    # iPhone 13 Pro
    "iPhone_13_Pro_Max": (1284, 2778), # iPhone 13 Pro Max
    "iPhone_14": (1170, 2532),        # iPhone 14
    "iPhone_14_Plus": (1284, 2778),   # iPhone 14 Plus
    "iPhone_14_Pro": (1179, 2556),    # iPhone 14 Pro
    "iPhone_14_Pro_Max": (1290, 2796), # iPhone 14 Pro Max
    "iPhone_15": (1179, 2556),        # iPhone 15
    "iPhone_15_Plus": (1290, 2796),   # iPhone 15 Plus
    "iPhone_15_Pro": (1179, 2556),    # iPhone 15 Pro
    "iPhone_15_Pro_Max": (1290, 2796), # iPhone 15 Pro Max
    "iPhone_16": (1179, 2556),        # iPhone 16
    "iPhone_16_Plus": (1290, 2796),   # iPhone 16 Plus
    "iPhone_16_Pro": (1179, 2556),    # iPhone 16 Pro
    "iPhone_16_Pro_Max": (1290, 2796), # iPhone 16 Pro Max
    
    # 新增的iPhone 6.7"和6.9"尺寸
    "iPhone_6_7_New": (1320, 2868),   # iPhone 6.7" 新尺寸
    "iPhone_6_7_Landscape": (2868, 1320), # iPhone 6.7" 横屏
    "iPhone_6_9": (1290, 2796),       # iPhone 6.9" 竖屏
    "iPhone_6_9_Landscape": (2796, 1290), # iPhone 6.9" 横屏
    
    # iPad 截图尺寸
    "iPad_9_7": (1536, 2048),         # iPad 9.7-inch
    "iPad_10_2": (1620, 2160),        # iPad 10.2-inch
    "iPad_10_9": (1640, 2360),        # iPad 10.9-inch
    "iPad_11": (1668, 2388),          # iPad 11-inch
    "iPad_12_9": (2048, 2732),        # iPad 12.9-inch
    "iPad_Air_10_9": (1640, 2360),    # iPad Air 10.9-inch
    "iPad_Air_11": (1668, 2388),      # iPad Air 11-inch
    "iPad_Pro_11": (1668, 2388),      # iPad Pro 11-inch
    "iPad_Pro_12_9": (2048, 2732),    # iPad Pro 12.9-inch
    "iPad_mini_8_3": (1488, 2266),    # iPad mini 8.3-inch
}

def resize_image_to_exact_size(image, target_size):
    """将图片调整到精确的目标尺寸"""
    target_width, target_height = target_size
    
    # 计算宽高比
    original_ratio = image.width / image.height
    target_ratio = target_width / target_height
    
    if original_ratio > target_ratio:
        # 原图更宽，需要裁剪宽度
        new_width = int(image.height * target_ratio)
        new_height = image.height
        left = (image.width - new_width) // 2
        top = 0
        right = left + new_width
        bottom = new_height
    else:
        # 原图更高，需要裁剪高度
        new_width = image.width
        new_height = int(image.width / target_ratio)
        left = 0
        top = (image.height - new_height) // 2
        right = new_width
        bottom = top + new_height
    
    # 裁剪图片
    cropped_image = image.crop((left, top, right, bottom))
    
    # 调整到目标尺寸
    resized_image = cropped_image.resize((target_width, target_height), Image.Resampling.LANCZOS)
    
    return resized_image

def generate_screenshots(input_folder, output_folder):
    """生成所有尺寸的截图"""
    if not os.path.exists(output_folder):
        os.makedirs(output_folder)
    
    # 获取输入文件夹中的所有图片
    image_files = [f for f in os.listdir(input_folder) 
                   if f.lower().endswith(('.png', '.jpg', '.jpeg'))]
    
    if not image_files:
        print("❌ 在输入文件夹中没有找到图片文件")
        return
    
    print(f"📱 找到 {len(image_files)} 张原始截图")
    
    for image_file in image_files:
        input_path = os.path.join(input_folder, image_file)
        print(f"\n🔄 处理图片: {image_file}")
        
        try:
            # 打开原始图片
            original_image = Image.open(input_path)
            print(f"   原始尺寸: {original_image.size}")
            
            # 为每个设备尺寸生成截图
            for device_name, size in SCREENSHOT_SIZES.items():
                print(f"   📱 生成 {device_name} 尺寸: {size}")
                
                # 调整图片到精确尺寸
                resized_image = resize_image_to_exact_size(original_image, size)
                
                # 验证尺寸
                if resized_image.size != size:
                    print(f"   ⚠️  尺寸不匹配: 期望 {size}, 实际 {resized_image.size}")
                    continue
                
                # 生成输出文件名
                base_name = os.path.splitext(image_file)[0]
                output_filename = f"{base_name}_{device_name}_{size[0]}x{size[1]}.png"
                output_path = os.path.join(output_folder, output_filename)
                
                # 保存图片
                resized_image.save(output_path, 'PNG', quality=95)
                print(f"   ✅ 已保存: {output_filename} (尺寸: {resized_image.size})")
                
        except Exception as e:
            print(f"   ❌ 处理 {image_file} 时出错: {str(e)}")
            continue

def verify_screenshots(output_folder):
    """验证生成的截图尺寸"""
    print(f"\n🔍 验证截图尺寸...")
    
    files = [f for f in os.listdir(output_folder) if f.endswith('.png')]
    
    for file in files:
        file_path = os.path.join(output_folder, file)
        
        # 从文件名提取期望的尺寸
        if 'x' in file and file.endswith('.png'):
            try:
                # 提取尺寸信息
                size_part = file.split('_')[-1].replace('.png', '')
                if 'x' in size_part:
                    width, height = map(int, size_part.split('x'))
                    expected_size = (width, height)
                    
                    # 检查实际尺寸
                    with Image.open(file_path) as img:
                        actual_size = img.size
                        
                        if actual_size == expected_size:
                            print(f"   ✅ {file}: {actual_size}")
                        else:
                            print(f"   ❌ {file}: 期望 {expected_size}, 实际 {actual_size}")
            except Exception as e:
                print(f"   ⚠️  无法验证 {file}: {str(e)}")

def main():
    """主函数"""
    print("📱 App Store 截图生成工具 (修复版)")
    print("=" * 50)
    
    # 设置输入和输出文件夹
    input_folder = "ios上架准备"
    output_folder = "App_Store_Screenshots_Fixed"
    
    # 检查输入文件夹是否存在
    if not os.path.exists(input_folder):
        print(f"❌ 输入文件夹 '{input_folder}' 不存在")
        return
    
    print(f"📂 输入文件夹: {input_folder}")
    print(f"📂 输出文件夹: {output_folder}")
    
    # 生成截图
    generate_screenshots(input_folder, output_folder)
    
    # 验证截图尺寸
    verify_screenshots(output_folder)
    
    print("\n🎉 截图生成完成！")
    print(f"📁 所有截图已保存到: {output_folder}")
    print("🔍 所有截图尺寸已验证")

if __name__ == "__main__":
    main()
