#!/bin/bash

# 所见 - App Store 截图处理脚本
# 使用 ImageMagick 处理和优化 App Store 截图

echo "📸 开始处理 所见 App Store 截图..."

# 检查 ImageMagick 是否安装
if ! command -v convert &> /dev/null; then
    echo "❌ 错误: 未找到 ImageMagick"
    echo "请先安装 ImageMagick:"
    echo "  macOS: brew install imagemagick"
    echo "  Ubuntu: sudo apt-get install imagemagick"
    echo "  CentOS: sudo yum install ImageMagick"
    exit 1
fi

# 创建目录
mkdir -p Screenshots/Raw
mkdir -p Screenshots/Processed
mkdir -p Screenshots/Final

# 检查原始截图
if [ ! -d "Screenshots/Raw" ] || [ -z "$(ls -A Screenshots/Raw 2>/dev/null)" ]; then
    echo "❌ 错误: 未找到原始截图"
    echo "请将您的原始截图放在 Screenshots/Raw 目录中"
    echo ""
    echo "📋 支持的截图尺寸:"
    echo "  - iPhone 6.7 英寸: 1290 x 2796"
    echo "  - iPhone 6.5 英寸: 1242 x 2688"
    echo "  - iPhone 5.5 英寸: 1242 x 2208"
    echo "  - iPhone 4.7 英寸: 750 x 1334"
    echo ""
    echo "📁 目录结构:"
    echo "  Screenshots/"
    echo "  ├── Raw/          # 原始截图"
    echo "  ├── Processed/    # 处理后的截图"
    echo "  └── Final/        # 最终优化截图"
    exit 1
fi

echo "📁 原始截图目录: Screenshots/Raw"
echo "📁 处理后目录: Screenshots/Processed"
echo "📁 最终目录: Screenshots/Final"

# 处理原始截图
echo ""
echo "🔄 开始处理截图..."

for file in Screenshots/Raw/*.{png,jpg,jpeg}; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        name="${filename%.*}"
        
        echo "🔄 处理: $filename"
        
        # 获取图片信息
        info=$(identify "$file" 2>/dev/null)
        if [ $? -ne 0 ]; then
            echo "❌ 无法读取图片信息: $filename"
            continue
        fi
        
        # 提取尺寸信息
        dimensions=$(echo "$info" | awk '{print $3}')
        width=$(echo "$dimensions" | cut -d'x' -f1)
        height=$(echo "$dimensions" | cut -d'x' -f2)
        
        echo "  📐 原始尺寸: ${width}x${height}"
        
        # 根据尺寸确定设备类型和目标尺寸
        if [ "$width" -eq 1290 ] && [ "$height" -eq 2796 ]; then
            device="iPhone_6.7"
            target_width=1290
            target_height=2796
        elif [ "$width" -eq 1242 ] && [ "$height" -eq 2688 ]; then
            device="iPhone_6.5"
            target_width=1242
            target_height=2688
        elif [ "$width" -eq 1242 ] && [ "$height" -eq 2208 ]; then
            device="iPhone_5.5"
            target_width=1242
            target_height=2208
        elif [ "$width" -eq 750 ] && [ "$height" -eq 1334 ]; then
            device="iPhone_4.7"
            target_width=750
            target_height=1334
        else
            echo "  ⚠️  未知尺寸，保持原尺寸"
            device="Unknown"
            target_width=$width
            target_height=$height
        fi
        
        # 处理截图
        output_file="Screenshots/Processed/${name}_processed.png"
        
        # 基本处理：调整大小、优化质量
        convert "$file" \
            -resize "${target_width}x${target_height}" \
            -quality 95 \
            -strip \
            "$output_file"
        
        if [ $? -eq 0 ]; then
            echo "  ✅ 已处理: $output_file"
            
            # 进一步优化
            final_file="Screenshots/Final/${name}_final.png"
            
            convert "$output_file" \
                -quality 90 \
                -strip \
                -define png:compression-level=9 \
                -define png:compression-strategy=1 \
                "$final_file"
            
            if [ $? -eq 0 ]; then
                echo "  ✅ 已优化: $final_file"
                
                # 显示文件大小对比
                original_size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
                final_size=$(stat -f%z "$final_file" 2>/dev/null || stat -c%s "$final_file" 2>/dev/null)
                
                if [ "$original_size" -gt 0 ] && [ "$final_size" -gt 0 ]; then
                    compression_ratio=$(echo "scale=1; $final_size * 100 / $original_size" | bc -l 2>/dev/null || echo "N/A")
                    echo "  📊 文件大小: ${original_size} → ${final_size} bytes (${compression_ratio}%)"
                fi
            else
                echo "  ❌ 优化失败: $final_file"
            fi
        else
            echo "  ❌ 处理失败: $output_file"
        fi
        
        echo ""
    fi
done

# 生成 App Store 截图清单
echo "📋 生成 App Store 截图清单..."

cat > Screenshots/screenshot_inventory.md << 'EOF'
# 所见 - App Store 截图清单

## 📱 设备截图

### iPhone 6.7 英寸 (iPhone 14 Pro Max, iPhone 15 Pro Max)
- 尺寸: 1290 x 2796
- 用途: App Store 展示
- 状态: 待上传

### iPhone 6.5 英寸 (iPhone 14 Plus, iPhone 15 Plus)
- 尺寸: 1242 x 2688
- 用途: App Store 展示
- 状态: 待上传

### iPhone 5.5 英寸 (iPhone 8 Plus)
- 尺寸: 1242 x 2208
- 用途: App Store 展示
- 状态: 待上传

### iPhone 4.7 英寸 (iPhone 8)
- 尺寸: 750 x 1334
- 用途: App Store 展示
- 状态: 待上传

## 📸 截图内容建议

### 截图 1: 主界面
- 展示相机主界面
- 突出多镜头切换功能
- 显示实时预览效果

### 截图 2: 滤镜功能
- 展示滤镜选择界面
- 显示实时滤镜预览
- 突出滤镜效果

### 截图 3: 专业调节
- 展示参数调节面板
- 显示对比度、饱和度、色温调节
- 突出专业功能

### 截图 4: 场景模式
- 展示场景选择界面
- 显示不同场景的滤镜预设
- 突出智能场景识别

### 截图 5: 照片管理
- 展示照片查看器
- 显示左右滑动浏览功能
- 突出照片管理体验

## 📋 上传清单

### 必需截图
- [ ] iPhone 6.7 英寸截图 (5张)
- [ ] iPhone 6.5 英寸截图 (5张)
- [ ] iPhone 5.5 英寸截图 (5张)
- [ ] iPhone 4.7 英寸截图 (5张)

### 可选截图
- [ ] iPad 截图 (如果支持)
- [ ] Apple Watch 截图 (如果支持)

## ⚠️ 注意事项

1. **图片质量**: 确保截图清晰、无模糊
2. **内容合规**: 避免显示敏感内容
3. **功能展示**: 突出应用核心功能
4. **用户体验**: 展示良好的用户界面
5. **品牌一致**: 保持与应用风格一致

## 📊 文件统计

EOF

# 统计处理结果
processed_count=$(find Screenshots/Processed -name "*.png" 2>/dev/null | wc -l)
final_count=$(find Screenshots/Final -name "*.png" 2>/dev/null | wc -l)
raw_count=$(find Screenshots/Raw -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" 2>/dev/null | wc -l)

echo "📊 处理统计:" >> Screenshots/screenshot_inventory.md
echo "- 原始截图: $raw_count 张" >> Screenshots/screenshot_inventory.md
echo "- 处理后: $processed_count 张" >> Screenshots/screenshot_inventory.md
echo "- 最终优化: $final_count 张" >> Screenshots/screenshot_inventory.md

echo ""
echo "🎉 截图处理完成！"
echo ""
echo "📁 处理结果:"
echo "  - 原始截图: $raw_count 张"
echo "  - 处理后: $processed_count 张"
echo "  - 最终优化: $final_count 张"
echo ""
echo "📋 下一步操作:"
echo "  1. 检查 Screenshots/Final 目录中的优化截图"
echo "  2. 验证截图质量和尺寸"
echo "  3. 上传到 App Store Connect"
echo "  4. 在 App Store Connect 中添加截图描述"
echo ""
echo "📱 所见 - 让每一张照片都成为艺术品"
