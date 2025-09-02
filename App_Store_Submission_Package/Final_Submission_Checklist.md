# App Store 上架最终检查清单 - 所见 (Vision)

## ✅ 文件准备状态检查

### 📋 必需文档文件
- [x] **完整上架指南** - `App_Store_Complete_Submission_Guide.md`
- [x] **应用元数据** - `App_Store_Metadata_Complete.md`
- [x] **隐私政策** - `Privacy_Policy_Complete.md`
- [x] **服务条款** - `Terms_of_Service_Complete.md`
- [x] **最终检查清单** - `Final_Submission_Checklist.md` (本文件)

### 🎨 应用图标 (需要生成)
- [ ] **App Store 图标** - 1024x1024 PNG
- [ ] **iPhone 图标** - 各种尺寸 (20pt, 29pt, 40pt, 60pt @2x, @3x)
- [ ] **iPad 图标** - 各种尺寸 (20pt, 29pt, 40pt, 76pt, 83.5pt @1x, @2x)

### 📱 应用截图 (需要生成)
- [ ] **iPhone 6.7"** - 1290x2796 (iPhone 14 Pro Max, 15 Pro Max)
- [ ] **iPhone 6.5"** - 1242x2688 (iPhone 11/12/13 Pro Max)
- [ ] **iPhone 5.5"** - 1242x2208 (iPhone 8 Plus)
- [ ] **iPad Pro 12.9"** - 2048x2732 (第6代)
- [ ] **iPad Pro 11"** - 1668x2388 (第4代)

## 🔧 技术准备检查

### Xcode 项目设置
- [ ] **Bundle Identifier**: lazy-tech.pphoto
- [ ] **版本号**: 1.0
- [ ] **构建号**: 1
- [ ] **部署目标**: iOS 15.0+
- [ ] **设备支持**: iPhone, iPad
- [ ] **方向支持**: Portrait, Landscape

### 权限配置 (Info.plist)
- [x] **相机权限**: NSCameraUsageDescription
- [x] **相册权限**: NSPhotoLibraryUsageDescription
- [x] **相册添加权限**: NSPhotoLibraryAddUsageDescription
- [x] **运动权限**: NSMotionUsageDescription

### 应用签名
- [ ] **发布证书**: Distribution Certificate
- [ ] **发布描述文件**: Distribution Provisioning Profile
- [ ] **应用签名**: 已正确签名

## 📝 App Store Connect 设置检查

### 应用信息
- [ ] **应用名称**: 所见 (Vision)
- [ ] **副标题**: 智能拍照，所见即所得
- [ ] **关键词**: 拍照,相机,滤镜,摄影,照片,美颜,修图,AI,智能,所见
- [ ] **分类**: 摄影与录像 (主要), 工具 (次要)
- [ ] **年龄分级**: 4+ (无限制)
- [ ] **价格**: 免费

### 元数据
- [ ] **应用描述**: 已准备完整的中英文描述
- [ ] **隐私政策链接**: https://lazy-tech.com/privacy-policy
- [ ] **支持网站**: https://lazy-tech.com
- [ ] **营销URL**: https://lazy-tech.com/vision (可选)

### 联系信息
- [ ] **开发者名称**: Lazy Tech
- [ ] **支持邮箱**: support@lazy-tech.com
- [ ] **法律邮箱**: legal@lazy-tech.com
- [ ] **隐私邮箱**: privacy@lazy-tech.com

## 🚀 上架步骤检查

### 步骤1: 准备构建版本
- [ ] 在Xcode中选择"Any iOS Device"
- [ ] Product → Archive
- [ ] 验证构建版本
- [ ] 上传到App Store Connect

### 步骤2: 配置App Store Connect
- [ ] 登录App Store Connect
- [ ] 创建新应用
- [ ] 填写应用信息
- [ ] 上传图标和截图
- [ ] 填写元数据

### 步骤3: 提交审核
- [ ] 创建新版本
- [ ] 选择构建版本
- [ ] 填写版本信息
- [ ] 提交审核

## ⚠️ 常见问题检查

### 审核被拒风险
- [ ] **应用崩溃**: 已充分测试，无崩溃问题
- [ ] **功能不完整**: 所有功能都已实现并测试
- [ ] **元数据不准确**: 描述与实际功能一致
- [ ] **隐私政策缺失**: 已提供完整隐私政策
- [ ] **截图不符合要求**: 使用真实应用截图

### 技术问题
- [ ] **权限说明**: 所有权限都有合理的说明
- [ ] **性能优化**: 应用性能良好
- [ ] **兼容性**: 支持目标设备
- [ ] **网络使用**: 如有网络功能，已说明用途

## 📋 文件生成命令

### 生成图标
```bash
cd App_Store_Submission_Package
chmod +x generate_icons.sh
./generate_icons.sh
```

### 生成截图
```bash
cd App_Store_Submission_Package
chmod +x process_screenshots.sh
./process_screenshots.sh
```

### 验证构建
```bash
# 在Xcode中
# 1. 选择 "Any iOS Device"
# 2. Product → Archive
# 3. 验证构建版本
# 4. 上传到App Store Connect
```

## 🔍 最终验证清单

### 提交前最终检查
- [ ] 所有必需文件都已准备
- [ ] 应用图标符合要求
- [ ] 应用截图真实且符合尺寸
- [ ] 元数据准确完整
- [ ] 隐私政策和服务条款完整
- [ ] 应用功能已充分测试
- [ ] 无已知bug或崩溃问题
- [ ] 性能优化完成
- [ ] 权限说明合理
- [ ] 法律文件完整

### 审核前检查
- [ ] 应用功能完整可用
- [ ] 所有描述的功能都已实现
- [ ] 截图展示真实功能
- [ ] 元数据与功能一致
- [ ] 隐私政策链接有效
- [ ] 支持网站链接有效

## 📞 紧急联系信息

### 技术支持
- **邮箱**: support@lazy-tech.com
- **响应时间**: 7个工作日内

### 法律问题
- **邮箱**: legal@lazy-tech.com
- **响应时间**: 3个工作日内

### 隐私问题
- **邮箱**: privacy@lazy-tech.com
- **响应时间**: 5个工作日内

## 🎯 成功上架后的后续工作

### 监控和优化
- [ ] 监控应用下载量
- [ ] 收集用户反馈
- [ ] 分析使用数据
- [ ] 准备后续更新

### 营销推广
- [ ] 准备营销材料
- [ ] 社交媒体宣传
- [ ] 用户评价管理
- [ ] 竞品分析

---

## 📊 检查进度

**总体进度**: 4/5 主要文件已完成

### 已完成文件:
- ✅ 完整上架指南
- ✅ 应用元数据
- ✅ 隐私政策
- ✅ 服务条款
- ✅ 最终检查清单

### 待完成项目:
- 🔄 应用图标生成
- 🔄 应用截图生成
- 🔄 构建版本准备
- 🔄 App Store Connect配置
- 🔄 提交审核

---

**重要提醒**: 
1. 请按照此清单逐项检查
2. 确保所有文件都符合Apple的审核要求
3. 在提交前进行充分测试
4. 如有疑问，请及时联系技术支持

**预计完成时间**: 根据您的进度，预计需要1-2天完成所有准备工作。
