#!/usr/bin/env python3
import os
import sys
from xml.etree import ElementTree as ET

def svg_to_png(svg_file, png_file, size=1024):
    """简单的SVG到PNG转换器"""
    try:
        # 读取SVG文件
        with open(svg_file, 'r', encoding='utf-8') as f:
            svg_content = f.read()
        
        # 创建一个简单的HTML文件来渲染SVG
        html_content = f"""
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>SVG to PNG</title>
    <style>
        body {{ margin: 0; padding: 0; }}
        svg {{ width: {size}px; height: {size}px; }}
    </style>
</head>
<body>
    {svg_content}
</body>
</html>
"""
        
        # 保存HTML文件
        html_file = svg_file.replace('.svg', '.html')
        with open(html_file, 'w', encoding='utf-8') as f:
            f.write(html_content)
        
        print(f"已创建HTML文件: {html_file}")
        print(f"请使用浏览器打开 {html_file} 并截图保存为PNG")
        print(f"或者使用在线工具如 https://convertio.co/svg-png/ 来转换")
        
        return True
        
    except Exception as e:
        print(f"转换失败: {e}")
        return False

def main():
    svg_files = ['app_icon.svg', 'app_icon_simple.svg', 'app_icon_modern.svg']
    
    for svg_file in svg_files:
        if os.path.exists(svg_file):
            print(f"\n处理文件: {svg_file}")
            png_file = svg_file.replace('.svg', '.png')
            svg_to_png(svg_file, png_file)
        else:
            print(f"文件不存在: {svg_file}")

if __name__ == "__main__":
    main() 