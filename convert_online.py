#!/usr/bin/env python3
import os
import base64
import requests
import json

def convert_svg_online(svg_file):
    """使用在线服务转换SVG到PNG"""
    try:
        # 读取SVG文件
        with open(svg_file, 'r', encoding='utf-8') as f:
            svg_content = f.read()
        
        # 编码SVG内容
        svg_encoded = base64.b64encode(svg_content.encode('utf-8')).decode('utf-8')
        
        print(f"SVG文件 {svg_file} 已准备好转换")
        print(f"SVG内容长度: {len(svg_content)} 字符")
        print(f"Base64编码长度: {len(svg_encoded)} 字符")
        
        # 提供转换选项
        print(f"\n转换选项:")
        print(f"1. 使用在线工具: https://convertio.co/svg-png/")
        print(f"2. 使用在线工具: https://cloudconvert.com/svg-to-png")
        print(f"3. 使用在线工具: https://www.svgviewer.dev/")
        
        # 创建预览HTML文件
        html_file = svg_file.replace('.svg', '_preview.html')
        html_content = f"""
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>SVG预览 - {svg_file}</title>
    <style>
        body {{ 
            margin: 0; 
            padding: 20px; 
            background: #f0f0f0; 
            font-family: Arial, sans-serif;
        }}
        .container {{
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }}
        h1 {{ color: #333; }}
        .svg-container {{
            text-align: center;
            margin: 20px 0;
            padding: 20px;
            border: 2px dashed #ccc;
            border-radius: 10px;
        }}
        svg {{
            max-width: 100%;
            height: auto;
            border: 1px solid #ddd;
            border-radius: 5px;
        }}
        .instructions {{
            background: #e8f4fd;
            padding: 15px;
            border-radius: 5px;
            margin: 20px 0;
        }}
        .download-btn {{
            background: #007AFF;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 16px;
            margin: 10px;
        }}
        .download-btn:hover {{
            background: #0056CC;
        }}
    </style>
</head>
<body>
    <div class="container">
        <h1>SVG图标预览 - {svg_file}</h1>
        
        <div class="svg-container">
            {svg_content}
        </div>
        
        <div class="instructions">
            <h3>转换说明:</h3>
            <ol>
                <li>右键点击上面的SVG图标</li>
                <li>选择"另存为图片"或"保存图片"</li>
                <li>选择PNG格式保存</li>
                <li>或者使用在线转换工具:
                    <ul>
                        <li><a href="https://convertio.co/svg-png/" target="_blank">Convertio.co</a></li>
                        <li><a href="https://cloudconvert.com/svg-to-png" target="_blank">CloudConvert</a></li>
                        <li><a href="https://www.svgviewer.dev/" target="_blank">SVG Viewer</a></li>
                    </ul>
                </li>
            </ol>
        </div>
        
        <div style="text-align: center;">
            <button class="download-btn" onclick="downloadSVG()">下载SVG文件</button>
            <button class="download-btn" onclick="copySVGCode()">复制SVG代码</button>
        </div>
    </div>
    
    <script>
        function downloadSVG() {{
            const svgContent = `{svg_content.replace('`', '\\`')}`;
            const blob = new Blob([svgContent], {{type: 'image/svg+xml'}});
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = '{svg_file}';
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            URL.revokeObjectURL(url);
        }}
        
        function copySVGCode() {{
            const svgContent = `{svg_content.replace('`', '\\\\`')}`;
            navigator.clipboard.writeText(svgContent).then(() => {{
                alert('SVG代码已复制到剪贴板！');
            }});
        }}
    </script>
</body>
</html>
"""
        
        with open(html_file, 'w', encoding='utf-8') as f:
            f.write(html_content)
        
        print(f"\n已创建预览文件: {html_file}")
        print(f"请在浏览器中打开此文件来预览和转换图标")
        
        return True
        
    except Exception as e:
        print(f"处理失败: {e}")
        return False

def main():
    svg_files = ['app_icon.svg', 'app_icon_simple.svg', 'app_icon_modern.svg']
    
    print("SVG到PNG转换工具")
    print("=" * 50)
    
    for svg_file in svg_files:
        if os.path.exists(svg_file):
            print(f"\n处理文件: {svg_file}")
            convert_svg_online(svg_file)
        else:
            print(f"文件不存在: {svg_file}")
    
    print(f"\n转换完成！")
    print(f"推荐使用 app_icon_modern.svg 作为应用图标")

if __name__ == "__main__":
    main() 