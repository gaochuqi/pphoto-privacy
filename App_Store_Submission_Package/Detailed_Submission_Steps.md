# pphoto - App Store 详细上架步骤

## 🚀 第一阶段：准备工作

### 1.1 开发者账号设置

#### 1.1.1 账号激活
1. 登录 [Apple Developer](https://developer.apple.com)
2. 确认账号状态为 "Active"
3. 检查会员资格是否有效
4. 确认身份验证已完成

#### 1.1.2 协议签署
1. 进入 "Agreements, Tax, and Banking"
2. 签署 "Apple Developer Agreement"
3. 签署 "App Store Connect Agreement"
4. 确认所有协议状态为 "Active"

#### 1.1.3 税务信息
1. 填写税务信息表格
2. 选择正确的税务分类
3. 提供有效的税务识别号
4. 确认税务信息已审核通过

#### 1.1.4 银行信息
1. 添加银行账户信息
2. 提供准确的银行账户详情
3. 确认银行信息已验证
4. 设置付款偏好

### 1.2 证书和配置文件

#### 1.2.1 创建发布证书
```bash
# 在 Xcode 中操作
1. 打开 Xcode
2. 进入 Preferences > Accounts
3. 选择 Apple ID
4. 点击 "Manage Certificates"
5. 点击 "+" 创建新证书
6. 选择 "Apple Distribution"
7. 下载并安装证书
```

#### 1.2.2 创建应用ID
```bash
# 在 Apple Developer 网站操作
1. 登录 Apple Developer
2. 进入 "Certificates, Identifiers & Profiles"
3. 选择 "Identifiers"
4. 点击 "+" 创建新标识符
5. 选择 "App IDs"
6. 选择 "App"
7. 填写应用信息：
   - Description: pphoto
   - Bundle ID: lazy-tech.pphoto
   - Capabilities: 根据需要选择
8. 点击 "Continue" 和 "Register"
```

#### 1.2.3 创建发布配置文件
```bash
# 在 Apple Developer 网站操作
1. 进入 "Profiles"
2. 点击 "+" 创建新配置文件
3. 选择 "App Store"
4. 选择应用ID: lazy-tech.pphoto
5. 选择发布证书
6. 命名配置文件: pphoto_AppStore
7. 下载配置文件
8. 双击安装到 Xcode
```

## 📱 第二阶段：应用构建

### 2.1 Xcode 项目配置

#### 2.1.1 项目设置
```swift
// 在 Xcode 中操作
1. 选择项目 pphoto
2. 选择 target pphoto
3. 在 "General" 标签页中：
   - Display Name: pphoto
   - Bundle Identifier: lazy-tech.pphoto
   - Version: 1.0
   - Build: 1
   - Deployment Target: iOS 18.5
```

#### 2.1.2 签名配置
```swift
// 在 "Signing & Capabilities" 标签页中：
1. 勾选 "Automatically manage signing"
2. 选择 Team: 您的开发者账号
3. 确认 Bundle Identifier 正确
4. 确认 Provisioning Profile 自动选择
```

#### 2.1.3 权限配置
```xml
<!-- 确认 Info.plist 包含以下权限 -->
<key>NSCameraUsageDescription</key>
<string>需要访问相机用于拍照和实时滤镜</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册用于保存和选择照片</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>需要保存照片到相册</string>
<key>NSMotionUsageDescription</key>
<string>需要访问运动与陀螺仪用于照片方向识别</string>
```

### 2.2 应用图标

#### 2.2.1 生成图标
```bash
# 使用提供的脚本生成图标
1. 准备 1024x1024 的源图片
2. 运行图标生成脚本：
   ./App_Store_Submission_Package/generate_icons.sh app_icon_source.png
3. 检查生成的图标文件
4. 将 Assets.xcassets 复制到项目中
```

#### 2.2.2 验证图标
```bash
# 在 Xcode 中验证
1. 打开 Assets.xcassets
2. 选择 AppIcon
3. 确认所有尺寸的图标都已添加
4. 检查图标显示效果
5. 在不同设备模拟器中测试
```

### 2.3 构建应用

#### 2.3.1 清理项目
```bash
# 在 Xcode 中操作
1. Product > Clean Build Folder
2. 删除 Derived Data
3. 重置模拟器
```

#### 2.3.2 Archive 构建
```bash
# 在 Xcode 中操作
1. 选择 "Any iOS Device" 作为目标
2. Product > Archive
3. 等待构建完成
4. 检查构建日志是否有错误
```

#### 2.3.3 验证构建
```bash
# 在 Organizer 中验证
1. 打开 Organizer (Window > Organizer)
2. 选择刚创建的 Archive
3. 点击 "Validate App"
4. 选择 "App Store Connect"
5. 点击 "Validate"
6. 检查验证结果
```

## 🌐 第三阶段：App Store Connect 配置

### 3.1 创建应用

#### 3.1.1 添加新应用
```bash
# 在 App Store Connect 中操作
1. 登录 [App Store Connect](https://appstoreconnect.apple.com)
2. 点击 "My Apps"
3. 点击 "+" 添加新应用
4. 填写应用信息：
   - Platform: iOS
   - Name: pphoto
   - Primary language: Chinese (Simplified)
   - Bundle ID: lazy-tech.pphoto
   - SKU: pphoto-ios-v1
   - User Access: Full Access
5. 点击 "Create"
```

#### 3.1.2 应用信息配置
```bash
# 在应用详情页面配置
1. 基本信息：
   - 副标题: 专业相机滤镜应用
   - 关键词: 相机,滤镜,拍照,摄影
   - 支持网站: https://pphoto.lazytech.com
   - 营销URL: https://pphoto.lazytech.com
   - 隐私政策URL: https://pphoto.lazytech.com/privacy

2. 分类信息：
   - 主要分类: 摄影与录像
   - 次要分类: 工具
   - 年龄分级: 4+
```

### 3.2 版本信息

#### 3.2.1 创建版本
```bash
# 在 "App Store" 标签页中
1. 点击 "+" 创建新版本
2. 版本号: 1.0
3. 版本信息: 初始版本
4. 点击 "Create"
```

#### 3.2.2 填写版本信息
```bash
# 在版本详情页面
1. 版本信息：
   - 版本号: 1.0
   - 版权: © 2025 Lazy Tech
   - 版本描述: 参考 App_Description.md

2. 关键词：
   - 中文: 相机,滤镜,拍照,摄影,美颜,修图,相册,照片,摄影工具,相机应用
   - 英文: camera,filter,photo,photography,beauty,edit,album,picture,photo tool,camera app
```

### 3.3 截图上传

#### 3.3.1 准备截图
```bash
# 按照 App_Store_Screenshots_Guide.md 准备截图
1. 使用 Xcode Simulator 或真机截图
2. 确保截图分辨率符合要求
3. 选择最佳展示场景
4. 编辑和优化截图
```

#### 3.3.2 上传截图
```bash
# 在 App Store Connect 中上传
1. 进入 "Screenshots" 部分
2. 选择设备类型: iPhone 6.7" Display
3. 上传 5-10 张截图
4. 为每张截图添加描述
5. 保存更改
```

## 📤 第四阶段：提交审核

### 4.1 构建上传

#### 4.1.1 上传构建
```bash
# 在 Xcode Organizer 中
1. 选择 Archive
2. 点击 "Distribute App"
3. 选择 "App Store Connect"
4. 选择 "Upload"
5. 选择发布配置文件
6. 点击 "Upload"
7. 等待上传完成
```

#### 4.1.2 选择构建版本
```bash
# 在 App Store Connect 中
1. 进入版本详情页面
2. 点击 "Build" 部分
3. 选择刚上传的构建版本
4. 点击 "Done"
```

### 4.2 审核信息

#### 4.2.1 填写审核信息
```bash
# 在 "App Review Information" 部分
1. 联系信息：
   - 姓名: 您的姓名
   - 电话: 您的电话
   - 邮箱: support@lazytech.com

2. 审核说明：
   - 应用功能说明
   - 测试账号信息（如需要）
   - 特殊功能说明
   - 权限使用说明
```

#### 4.2.2 版本发布
```bash
# 在 "Version Release" 部分
1. 选择发布方式：
   - 手动发布
   - 自动发布
   - 分阶段发布

2. 设置发布日期（如选择手动发布）
```

### 4.3 提交审核

#### 4.3.1 最终检查
```bash
# 使用 App_Store_Submission_Checklist.md 进行最终检查
1. 检查所有必填项
2. 确认信息准确
3. 验证截图和描述
4. 检查法律文件链接
```

#### 4.3.2 提交应用
```bash
# 在版本详情页面
1. 点击 "Save" 保存所有更改
2. 点击 "Submit for Review"
3. 确认提交信息
4. 点击 "Submit"
```

## 📊 第五阶段：审核监控

### 5.1 审核状态跟踪

#### 5.1.1 状态监控
```bash
# 在 App Store Connect 中监控
1. 审核状态：
   - Waiting for Review
   - In Review
   - Ready for Sale
   - Rejected

2. 审核时间：
   - 通常 24-48 小时
   - 复杂应用可能需要更长时间
```

#### 5.1.2 审核结果处理
```bash
# 根据审核结果采取行动
1. 审核通过：
   - 确认发布设置
   - 监控应用状态
   - 准备营销活动

2. 审核被拒：
   - 查看拒绝原因
   - 修复问题
   - 重新提交
```

### 5.2 发布后监控

#### 5.2.1 应用状态
```bash
# 监控应用发布状态
1. 检查应用是否在 App Store 上架
2. 验证应用信息显示正确
3. 测试下载和安装
4. 检查用户评价
```

#### 5.2.2 性能监控
```bash
# 使用 App Analytics 监控
1. 下载量统计
2. 用户活跃度
3. 崩溃报告
4. 用户反馈
```

## 🔧 常见问题解决

### 6.1 构建问题

#### 6.1.1 证书问题
```bash
# 解决方案
1. 检查证书是否过期
2. 重新生成证书
3. 更新配置文件
4. 清理项目缓存
```

#### 6.1.2 签名问题
```bash
# 解决方案
1. 检查 Bundle ID 匹配
2. 确认团队选择正确
3. 重新设置签名配置
4. 清理构建文件
```

### 6.2 审核问题

#### 6.2.1 元数据问题
```bash
# 解决方案
1. 检查应用描述
2. 验证关键词设置
3. 确认截图质量
4. 更新隐私政策
```

#### 6.2.2 功能问题
```bash
# 解决方案
1. 修复崩溃问题
2. 完善错误处理
3. 优化用户体验
4. 添加必要说明
```

## 📞 支持资源

### 7.1 官方资源
- [Apple Developer Documentation](https://developer.apple.com/documentation)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines)
- [App Store Connect Help](https://help.apple.com/app-store-connect)

### 7.2 技术支持
- 邮箱: support@lazytech.com
- 网站: https://pphoto.lazytech.com
- 响应时间: 24-48小时

---

**重要提示**: 请按照步骤顺序执行，确保每个步骤都正确完成后再进行下一步。如有问题，请参考相应的文档或联系技术支持。
