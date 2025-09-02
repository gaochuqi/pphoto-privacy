#!/bin/bash

# 所见 - 应用图标生成脚本
# 使用 ImageMagick 生成所有必需的 App Store 图标尺寸

echo "🎨 开始生成 所见 应用图标..."

# 检查 ImageMagick 是否安装
if ! command -v convert &> /dev/null; then
    echo "❌ 错误: 未找到 ImageMagick"
    echo "请先安装 ImageMagick:"
    echo "  macOS: brew install imagemagick"
    echo "  Ubuntu: sudo apt-get install imagemagick"
    echo "  CentOS: sudo yum install ImageMagick"
    exit 1
fi

# 创建输出目录
mkdir -p App_Icons

# 源图标文件（请确保存在）
SOURCE_ICON="source_icon.png"

if [ ! -f "$SOURCE_ICON" ]; then
    echo "❌ 错误: 未找到源图标文件 $SOURCE_ICON"
    echo "请将您的源图标文件重命名为 $SOURCE_ICON 并放在当前目录"
    exit 1
fi

echo "📁 源图标: $SOURCE_ICON"

# iOS App Store 图标尺寸
declare -a sizes=(
    "20x20"     # iPhone 通知栏
    "29x29"     # iPhone 设置
    "40x40"     # iPhone 通知栏 @2x
    "58x58"     # iPhone 设置 @2x
    "60x60"     # iPhone 主屏幕 @2x
    "76x76"     # iPad 主屏幕
    "80x80"     # iPhone 通知栏 @3x
    "87x87"     # iPhone 设置 @3x
    "120x120"   # iPhone 主屏幕 @3x
    "152x152"   # iPad 主屏幕 @2x
    "167x167"   # iPad Pro 主屏幕 @2x
    "180x180"   # iPhone 主屏幕 @3x (iPhone 6 Plus)
    "1024x1024" # App Store
)

# 生成图标
for size in "${sizes[@]}"; do
    width=$(echo $size | cut -d'x' -f1)
    height=$(echo $size | cut -d'x' -f2)
    
    output_file="App_Icons/Icon_${size}.png"
    
    echo "🔄 生成 $size 图标..."
    
    # 使用 ImageMagick 生成图标
    convert "$SOURCE_ICON" \
        -resize "${width}x${height}" \
        -background transparent \
        -gravity center \
        -extent "${width}x${height}" \
        "$output_file"
    
    if [ $? -eq 0 ]; then
        echo "✅ 已生成: $output_file"
    else
        echo "❌ 生成失败: $output_file"
    fi
done

# 生成圆角图标（可选）
echo "🔄 生成圆角图标..."

# 圆角半径（像素）
corner_radius=20

for size in "${sizes[@]}"; do
    width=$(echo $size | cut -d'x' -f1)
    height=$(echo $size | cut -d'x' -f2)
    
    # 根据图标大小调整圆角半径
    if [ $width -le 40 ]; then
        radius=4
    elif [ $width -le 80 ]; then
        radius=8
    elif [ $width -le 120 ]; then
        radius=12
    else
        radius=20
    fi
    
    input_file="App_Icons/Icon_${size}.png"
    output_file="App_Icons/Icon_${size}_rounded.png"
    
    if [ -f "$input_file" ]; then
        echo "🔄 生成圆角 $size 图标..."
        
        convert "$input_file" \
            \( +clone -alpha extract \
                -draw "fill black polygon 0,0 0,$radius $radius,0 fill white circle $radius,$radius $radius,0" \
                \( +clone -flip \) -compose Multiply -composite \
                \( +clone -flop \) -compose Multiply -composite \
            \) -alpha off -compose CopyOpacity -composite \
            "$output_file"
        
        if [ $? -eq 0 ]; then
            echo "✅ 已生成圆角图标: $output_file"
        else
            echo "❌ 圆角图标生成失败: $output_file"
        fi
    fi
done

# 生成 Xcode Assets.xcassets 格式
echo "🔄 生成 Xcode Assets.xcassets 格式..."

mkdir -p AppIcon.appiconset

# 创建 Contents.json 文件
cat > AppIcon.appiconset/Contents.json << 'EOF'
{
  "images" : [
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "20x20"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "29x29"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "40x40"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "76x76"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "83.5x83.5"
    },
    {
      "idiom" : "ios-marketing",
      "scale" : "1x",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

# 复制图标到 AppIcon.appiconset 目录
cp App_Icons/Icon_40x40.png AppIcon.appiconset/icon-20@2x.png
cp App_Icons/Icon_60x60.png AppIcon.appiconset/icon-20@3x.png
cp App_Icons/Icon_58x58.png AppIcon.appiconset/icon-29@2x.png
cp App_Icons/Icon_87x87.png AppIcon.appiconset/icon-29@3x.png
cp App_Icons/Icon_80x80.png AppIcon.appiconset/icon-40@2x.png
cp App_Icons/Icon_120x120.png AppIcon.appiconset/icon-40@3x.png
cp App_Icons/Icon_120x120.png AppIcon.appiconset/icon-60@2x.png
cp App_Icons/Icon_180x180.png AppIcon.appiconset/icon-60@3x.png
cp App_Icons/Icon_40x40.png AppIcon.appiconset/icon-20.png
cp App_Icons/Icon_58x58.png AppIcon.appiconset/icon-29.png
cp App_Icons/Icon_80x80.png AppIcon.appiconset/icon-40.png
cp App_Icons/Icon_76x76.png AppIcon.appiconset/icon-76.png
cp App_Icons/Icon_152x152.png AppIcon.appiconset/icon-76@2x.png
cp App_Icons/Icon_167x167.png AppIcon.appiconset/icon-83.5@2x.png
cp App_Icons/Icon_1024x1024.png AppIcon.appiconset/icon-1024.png

echo "✅ 已生成 Xcode Assets.xcassets 格式"

# 显示生成结果
echo ""
echo "🎉 图标生成完成！"
echo ""
echo "📁 生成的文件:"
echo "  - App_Icons/ - 所有尺寸的图标"
echo "  - AppIcon.appiconset/ - Xcode 项目格式"
echo ""
echo "📋 使用说明:"
echo "  1. 将 AppIcon.appiconset 文件夹复制到您的 Xcode 项目的 Assets.xcassets 中"
echo "  2. 重命名为 AppIcon"
echo "  3. 在 Xcode 中验证图标显示"
echo ""
echo "🔍 验证图标:"
echo "  - 检查所有尺寸是否正确"
echo "  - 确认图标在浅色和深色背景下都清晰可见"
echo "  - 验证在模拟器和真机上的显示效果"
echo ""
echo "📱 所见 - 让每一张照片都成为艺术品"
