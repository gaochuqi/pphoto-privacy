#!/bin/bash

# 所见 - iPhone 16 截图处理脚本
# 专门为只有iPhone 16的用户生成所有App Store需要的截图尺寸

echo "📱 所见 - iPhone 16 截图处理脚本"
echo "=================================="

# 检查 ImageMagick 是否安装
if ! command -v convert &> /dev/null; then
    echo "❌ 错误: 未找到 ImageMagick"
    echo "请先安装 ImageMagick:"
    echo "  macOS: brew install imagemagick"
    echo "  Ubuntu: sudo apt-get install imagemagick"
    echo "  CentOS: sudo yum install ImageMagick"
    exit 1
fi

# 创建目录结构
mkdir -p iPhone16_Screenshots/{Raw,Processed,Final}
mkdir -p iPhone16_Screenshots/Final/{iPhone_6.9,iPhone_6.5}

echo "📁 目录结构已创建"
echo "  - iPhone16_Screenshots/Raw/ - 原始截图"
echo "  - iPhone16_Screenshots/Processed/ - 处理中"
echo "  - iPhone16_Screenshots/Final/ - 最终截图"

# 检查原始截图
if [ ! -d "iPhone16_Screenshots/Raw" ] || [ -z "$(ls -A iPhone16_Screenshots/Raw 2>/dev/null)" ]; then
    echo ""
    echo "❌ 未找到原始截图"
    echo ""
    echo "📋 请按以下步骤操作："
    echo ""
    echo "1. 📱 在iPhone 16上拍摄截图："
    echo "   - 打开 所见 应用"
    echo "   - 进入不同功能页面"
    echo "   - 使用 音量上键 + 电源键 拍摄截图"
    echo ""
    echo "2. 📸 建议拍摄的截图："
    echo "   - 主界面（相机预览）"
    echo "   - 滤镜选择界面"
    echo "   - 参数调节界面"
    echo "   - 场景模式界面"
    echo "   - 照片查看器界面"
    echo ""
    echo "3. 💻 传输截图到电脑："
    echo "   - 通过AirDrop传输"
    echo "   - 或通过iCloud同步"
    echo "   - 或通过数据线传输"
    echo ""
    echo "4. 📂 将截图放入目录："
    echo "   - 将所有截图放入 iPhone16_Screenshots/Raw/ 目录"
    echo "   - 支持格式：PNG, JPG, JPEG"
    echo ""
    echo "5. 🔄 重新运行脚本："
    echo "   ./iphone16_screenshot_processor.sh"
    echo ""
    exit 1
fi

echo ""
echo "🔄 开始处理iPhone 16截图..."

# App Store 要求的尺寸
declare -A TARGET_SIZES=(
    ["iPhone_6.9"]="1290x2796"  # iPhone 16 Pro Max
    ["iPhone_6.5"]="1242x2688"  # iPhone 16 Plus
)

# 处理每张原始截图
for file in iPhone16_Screenshots/Raw/*.{png,jpg,jpeg}; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        name="${filename%.*}"
        
        echo ""
        echo "🔄 处理: $filename"
        
        # 获取原始尺寸
        info=$(identify "$file" 2>/dev/null)
        if [ $? -ne 0 ]; then
            echo "❌ 无法读取图片信息: $filename"
            continue
        fi
        
        dimensions=$(echo "$info" | awk '{print $3}')
        width=$(echo "$dimensions" | cut -d'x' -f1)
        height=$(echo "$dimensions" | cut -d'x' -f2)
        
        echo "  📐 原始尺寸: ${width}x${height}"
        
        # 为每个目标尺寸生成截图
        for device in "${!TARGET_SIZES[@]}"; do
            target_size="${TARGET_SIZES[$device]}"
            target_width=$(echo "$target_size" | cut -d'x' -f1)
            target_height=$(echo "$target_size" | cut -d'x' -f2)
            
            output_file="iPhone16_Screenshots/Final/${device}/${name}_${device}.png"
            
            echo "  📱 生成 ${device} (${target_size})..."
            
            # 智能调整尺寸，保持比例
            convert "$file" \
                -resize "${target_width}x${target_height}^" \
                -gravity center \
                -extent "${target_width}x${target_height}" \
                -quality 95 \
                -strip \
                "$output_file"
            
            if [ $? -eq 0 ]; then
                echo "    ✅ 已生成: $output_file"
                
                # 显示文件大小
                final_size=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file" 2>/dev/null)
                echo "    📊 文件大小: ${final_size} bytes"
            else
                echo "    ❌ 生成失败: $output_file"
            fi
        done
    fi
done

# 生成上传指南
echo ""
echo "📋 生成上传指南..."

cat > iPhone16_Screenshots/upload_guide.md << 'EOF'
# 所见 - App Store 截图上传指南

## 📱 设备尺寸说明

### iPhone 6.9 英寸 (iPhone 16 Pro Max)
- **尺寸**: 1290 x 2796 像素
- **用途**: 主要展示尺寸
- **文件位置**: iPhone16_Screenshots/Final/iPhone_6.9/

### iPhone 6.5 英寸 (iPhone 16 Plus)
- **尺寸**: 1242 x 2688 像素
- **用途**: 兼容性展示
- **文件位置**: iPhone16_Screenshots/Final/iPhone_6.5/

## 📸 截图内容建议

### 必需截图 (至少3张)
1. **主界面截图**
   - 展示相机预览界面
   - 突出多镜头切换功能
   - 显示实时预览效果

2. **滤镜功能截图**
   - 展示滤镜选择界面
   - 显示实时滤镜预览
   - 突出滤镜效果

3. **专业调节截图**
   - 展示参数调节面板
   - 显示对比度、饱和度、色温调节
   - 突出专业功能

### 推荐截图 (最多10张)
4. **场景模式截图**
   - 展示场景选择界面
   - 显示不同场景的滤镜预设

5. **照片管理截图**
   - 展示照片查看器
   - 显示左右滑动浏览功能

6. **设置界面截图**
   - 展示应用设置
   - 显示用户偏好选项

## 🚀 上传步骤

### 1. 准备截图
- 确保截图清晰、无模糊
- 避免显示敏感内容
- 突出应用核心功能
- 保持与应用风格一致

### 2. 选择设备尺寸
在App Store Connect中：
- 选择 "iPhone 6.9 英寸显示屏"
- 上传对应的截图文件

### 3. 上传截图
- 拖拽截图到上传区域
- 或点击 "选取文件" 按钮
- 最多上传10张截图

### 4. 添加描述
为每张截图添加描述：
- 简洁说明功能
- 突出特色
- 吸引用户注意

## ⚠️ 注意事项

1. **图片质量**
   - 确保截图清晰
   - 避免压缩失真
   - 保持色彩准确

2. **内容合规**
   - 避免显示敏感内容
   - 符合App Store审核要求
   - 不包含不当元素

3. **功能展示**
   - 突出核心功能
   - 展示用户价值
   - 体现应用特色

4. **用户体验**
   - 展示良好界面
   - 体现易用性
   - 突出设计美感

## 📊 文件统计

EOF

# 统计处理结果
iphone_69_count=$(find iPhone16_Screenshots/Final/iPhone_6.9 -name "*.png" 2>/dev/null | wc -l)
iphone_65_count=$(find iPhone16_Screenshots/Final/iPhone_6.5 -name "*.png" 2>/dev/null | wc -l)
raw_count=$(find iPhone16_Screenshots/Raw -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" 2>/dev/null | wc -l)

echo "📊 处理统计:" >> iPhone16_Screenshots/upload_guide.md
echo "- 原始截图: $raw_count 张" >> iPhone16_Screenshots/upload_guide.md
echo "- iPhone 6.9 英寸: $iphone_69_count 张" >> iPhone16_Screenshots/upload_guide.md
echo "- iPhone 6.5 英寸: $iphone_65_count 张" >> iPhone16_Screenshots/upload_guide.md

echo ""
echo "🎉 iPhone 16 截图处理完成！"
echo ""
echo "📁 处理结果:"
echo "  - 原始截图: $raw_count 张"
echo "  - iPhone 6.9 英寸: $iphone_69_count 张"
echo "  - iPhone 6.5 英寸: $iphone_65_count 张"
echo ""
echo "📋 下一步操作:"
echo "  1. 检查 iPhone16_Screenshots/Final/ 目录中的截图"
echo "  2. 选择最佳的3-10张截图"
echo "  3. 上传到 App Store Connect"
echo "  4. 参考 upload_guide.md 添加截图描述"
echo ""
echo "📱 所见 - 让每一张照片都成为艺术品"
