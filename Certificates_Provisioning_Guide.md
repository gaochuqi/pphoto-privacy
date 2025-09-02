# iOS 证书和配置文件指南

## 📋 概述

iOS 应用上架需要正确的证书和配置文件配置。本指南将帮助您完成所有必要的设置。

## 🔑 证书类型

### 1. 开发证书 (Development Certificate)
- **用途**: 开发阶段测试
- **有效期**: 1年
- **限制**: 只能在注册设备上运行

### 2. 分发证书 (Distribution Certificate)
- **用途**: App Store 发布
- **有效期**: 1年
- **限制**: 可以发布到 App Store

### 3. 推送证书 (Push Certificate)
- **用途**: 推送通知（如需要）
- **有效期**: 1年
- **限制**: 仅用于推送服务

## 📱 配置文件类型

### 1. 开发配置文件 (Development Provisioning Profile)
- **用途**: 开发阶段测试
- **包含**: 开发证书 + 测试设备
- **有效期**: 1年

### 2. App Store 配置文件 (App Store Provisioning Profile)
- **用途**: App Store 发布
- **包含**: 分发证书 + App ID
- **有效期**: 1年

### 3. Ad Hoc 配置文件 (Ad Hoc Provisioning Profile)
- **用途**: 特定设备测试
- **包含**: 分发证书 + 特定设备
- **有效期**: 1年

## 🛠️ 设置步骤

### 步骤1: 创建 App ID

1. **登录 Apple Developer**
   - 访问 https://developer.apple.com
   - 使用您的 Apple ID 登录

2. **创建 App ID**
   - 进入 "Certificates, Identifiers & Profiles"
   - 选择 "Identifiers"
   - 点击 "+" 创建新的 App ID

3. **配置 App ID**
   ```
   Description: pphoto
   Bundle ID: lazy-tech.pphoto
   Capabilities: 
   - Camera
   - Photo Library
   - Motion & Fitness
   ```

### 步骤2: 创建证书

#### 创建开发证书
1. **生成 CSR 文件**
   ```bash
   # 在终端中执行
   openssl genrsa -out private_key.key 2048
   openssl req -new -key private_key.key -out certificate.csr
   ```

2. **上传 CSR 到 Apple Developer**
   - 进入 "Certificates"
   - 选择 "Development" 或 "Distribution"
   - 上传 CSR 文件
   - 下载生成的证书

3. **安装证书**
   - 双击下载的证书文件
   - 证书将自动安装到 Keychain Access

#### 创建分发证书
1. **重复上述步骤**
   - 选择 "Distribution" 类型
   - 使用相同的 CSR 文件或生成新的

### 步骤3: 创建配置文件

#### 创建开发配置文件
1. **进入配置文件页面**
   - 选择 "Provisioning Profiles"
   - 点击 "+" 创建新的配置文件

2. **配置开发配置文件**
   ```
   Type: iOS App Development
   App ID: lazy-tech.pphoto
   Certificate: 您的开发证书
   Devices: 选择测试设备
   Name: pphoto Development
   ```

#### 创建 App Store 配置文件
1. **创建分发配置文件**
   ```
   Type: App Store
   App ID: lazy-tech.pphoto
   Certificate: 您的分发证书
   Name: pphoto App Store
   ```

### 步骤4: Xcode 配置

#### 配置项目设置
1. **打开项目设置**
   - 在 Xcode 中选择项目
   - 选择 "Signing & Capabilities"

2. **配置签名**
   ```
   Team: 选择您的开发者团队
   Bundle Identifier: lazy-tech.pphoto
   Automatically manage signing: 勾选
   ```

3. **选择配置文件**
   - Development: 选择开发配置文件
   - Release: 选择 App Store 配置文件

#### 验证配置
1. **检查签名状态**
   - 确保没有签名错误
   - 验证证书和配置文件有效

2. **测试构建**
   - 选择 "Any iOS Device" 作为目标
   - 执行 Archive 构建

## 📋 检查清单

### ✅ 证书检查
- [ ] 开发证书已创建并安装
- [ ] 分发证书已创建并安装
- [ ] 证书未过期
- [ ] 证书与开发者账号匹配

### ✅ 配置文件检查
- [ ] 开发配置文件已创建
- [ ] App Store 配置文件已创建
- [ ] 配置文件包含正确的 App ID
- [ ] 配置文件包含正确的证书
- [ ] 配置文件未过期

### ✅ Xcode 配置检查
- [ ] 项目 Bundle Identifier 正确
- [ ] 开发者团队已选择
- [ ] 自动签名已启用
- [ ] 配置文件已正确选择

### ✅ 构建检查
- [ ] Archive 构建成功
- [ ] 没有签名错误
- [ ] 构建版本可以上传到 App Store Connect

## 🔧 常见问题解决

### 问题1: 证书过期
**解决方案**:
1. 创建新的证书
2. 更新配置文件
3. 重新配置 Xcode 项目

### 问题2: 配置文件不匹配
**解决方案**:
1. 检查 Bundle Identifier
2. 确认 App ID 配置
3. 重新生成配置文件

### 问题3: 签名错误
**解决方案**:
1. 清理项目 (Product > Clean Build Folder)
2. 删除派生数据
3. 重新配置签名设置

### 问题4: 设备未注册
**解决方案**:
1. 在开发者账号中添加设备
2. 更新开发配置文件
3. 重新安装配置文件

## 📱 自动化配置

### 使用 Fastlane
```ruby
# Fastfile 配置示例
platform :ios do
  desc "Setup certificates and provisioning profiles"
  lane :setup_certificates do
    match(
      type: "development",
      app_identifier: "lazy-tech.pphoto",
      team_id: "YOUR_TEAM_ID"
    )
    
    match(
      type: "appstore",
      app_identifier: "lazy-tech.pphoto",
      team_id: "YOUR_TEAM_ID"
    )
  end
end
```

### 使用 Xcode 自动管理
1. **启用自动签名**
   - 在项目设置中勾选 "Automatically manage signing"
   - Xcode 将自动处理证书和配置文件

2. **配置团队**
   - 选择正确的开发者团队
   - Xcode 将自动下载和配置证书

## 🔒 安全建议

### 证书安全
- 妥善保管私钥文件
- 定期更新证书
- 不要分享证书文件

### 配置文件安全
- 定期更新配置文件
- 及时移除不需要的设备
- 监控配置文件使用情况

### 团队管理
- 限制团队成员权限
- 定期审查证书使用
- 及时撤销不需要的证书

---

**重要提醒**:
- 证书和配置文件是应用发布的关键
- 定期检查和更新证书
- 保持开发者账号活跃状态
- 遵循 Apple 的安全最佳实践
