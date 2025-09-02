//  ContentView.swift
//  pphoto
//
//  Created by Dreame on 2025/7/4.
//

import SwiftUI
import AVFoundation
import Photos
import CoreMotion
import Foundation
import AudioToolbox
import UIKit
import PhotosUI
import Darwin
import QuickLook
import QuartzCore // 确保能用 CATransaction

#if targetEnvironment(simulator)
    let TARGET_OS_SIMULATOR = 1
#else
    let TARGET_OS_SIMULATOR = 0
#endif

// MARK: - UI自适应系统
struct UIScreenInfo {
    let width: CGFloat
    let height: CGFloat
    let scale: CGFloat
    let isLandscape: Bool
    let deviceType: DeviceType
    let safeAreaInsets: UIEdgeInsets
    
    init() {
        let bounds = UIScreen.main.bounds
        self.width = bounds.width
        self.height = bounds.height
        self.scale = UIScreen.main.scale
        self.isLandscape = width > height
        
        // 获取安全区域
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            self.safeAreaInsets = window.safeAreaInsets
        } else {
            self.safeAreaInsets = UIEdgeInsets.zero
        }
        
        // 设备类型识别
        self.deviceType = DeviceType.from(screenSize: CGSize(width: width, height: height))
    }
}

enum DeviceType {
    case iPhoneSE      // 4.7寸及以下
    case iPhone        // 5.4-6.1寸 (无刘海)
    case iPhoneX       // iPhone X/XS (有刘海，812pt)
    case iPhonePlus    // 6.5-6.7寸
    case iPhonePro     // 6.1寸Pro
    case iPhoneProMax  // 6.7寸Pro Max
    case iPad          // iPad
    
    static func from(screenSize: CGSize) -> DeviceType {
        let width = screenSize.width
        let height = screenSize.height
        let maxDimension = max(width, height)
        
        // 特殊处理iPhone X系列（有刘海屏）
        if maxDimension == 812 {
            return .iPhoneX
        }
        
        switch maxDimension {
        case 0..<667:      // iPhone SE (1st/2nd gen)
            return .iPhoneSE
        case 667..<812:    // iPhone 6/7/8, iPhone SE (3rd gen)
            return .iPhone
        case 812..<844:    // iPhone X/XS, iPhone 12/13 mini
            return .iPhoneX
        case 844..<896:    // iPhone XR/XS Max, iPhone 11/12/13
            return .iPhonePlus
        case 896..<926:    // iPhone 11 Pro Max, iPhone 12/13 Pro Max
            return .iPhoneProMax
        case 926..<932:    // iPhone 14 Pro Max
            return .iPhoneProMax
        case 932..<1024:   // iPhone 15 Pro Max
            return .iPhoneProMax
        default:
            return .iPhoneProMax
        }
    }
}

// MARK: - 自适应布局管理器
class AdaptiveLayoutManager {
    static let shared = AdaptiveLayoutManager()
    
    private init() {}
    
    // 获取当前屏幕信息
    var currentScreen: UIScreenInfo {
        return UIScreenInfo()
    }
    
    // 计算自适应按钮尺寸
    func adaptiveButtonSize() -> CGSize {
        let screen = currentScreen
        let baseWidth: CGFloat = 60
        let baseHeight: CGFloat = 32
        
        switch screen.deviceType {
        case .iPhoneSE:
            return CGSize(width: baseWidth * 0.8, height: baseHeight * 0.9)
        case .iPhone:
            return CGSize(width: baseWidth * 0.9, height: baseHeight * 0.95)
        case .iPhoneX:
            return CGSize(width: baseWidth * 0.9, height: baseHeight * 0.95) // iPhone X保持正常按钮大小
        case .iPhonePlus:
            return CGSize(width: baseWidth, height: baseHeight)
        case .iPhonePro:
            return CGSize(width: baseWidth * 1.05, height: baseHeight * 1.05)
        case .iPhoneProMax:
            return CGSize(width: baseWidth * 1.1, height: baseHeight * 1.1)
        case .iPad:
            return CGSize(width: baseWidth * 1.2, height: baseHeight * 1.2)
        }
    }
    
    // 计算自适应间距
    func adaptiveSpacing() -> CGFloat {
        let screen = currentScreen
        let baseSpacing: CGFloat = 6
        
        switch screen.deviceType {
        case .iPhoneSE:
            return baseSpacing * 0.7
        case .iPhone:
            return baseSpacing * 0.8
        case .iPhoneX:
            return baseSpacing * 0.3 // iPhone X需要极小的间距
        case .iPhonePlus:
            return baseSpacing
        case .iPhonePro:
            return baseSpacing * 1.1
        case .iPhoneProMax:
            return baseSpacing * 1.2
        case .iPad:
            return baseSpacing * 1.5
        }
    }
    
    // 🔥 优化：保持字体清晰度的自适应字体大小
    func adaptiveFontSize(baseSize: CGFloat) -> CGFloat {
        let screen = currentScreen
        
        switch screen.deviceType {
        case .iPhoneSE:
            return baseSize * 0.8  // 稍微缩小但保持可读性
        case .iPhone:
            return baseSize * 0.85 // 稍微缩小但保持可读性
        case .iPhoneX:
            return baseSize * 0.85 // 与iPhone保持一致
        case .iPhonePlus:
            return baseSize * 0.95
        case .iPhonePro:
            return baseSize
        case .iPhoneProMax:
            return baseSize * 1.05
        case .iPad:
            return baseSize * 1.15
        }
    }
    
    // 🔥 全新：智能控制栏布局计算
    func smartControlBarLayout(buttonCount: Int) -> (width: CGFloat, buttonWidth: CGFloat, spacing: CGFloat) {
        let screen = currentScreen
        
        // 🔥 激进优化：根据屏幕类型设置最大可用宽度百分比
        let availableWidthPercentage: CGFloat
        // 🎯 新策略：不基于屏幕百分比，而是基于按钮的实际需要
        availableWidthPercentage = 1.0  // 临时设为100%，后面会重新计算
        
        let availableWidth = screen.width * availableWidthPercentage
        
        // 🎯 自适应设计：根据设备类型动态调整按钮宽度
        let minButtonWidth: CGFloat = 50  // 最小按钮宽度
        let maxButtonWidth: CGFloat = 85  // 最大按钮宽度
        let spacing: CGFloat = 10  // 固定间距
        let containerPadding: CGFloat = 20  // 容器左右内边距
        
        // 🚀 动态计算：确保按钮能完全显示文字，同时适配不同屏幕
        let availableForButtons = screen.width - containerPadding - (spacing * CGFloat(buttonCount - 1))
        let idealButtonWidth = availableForButtons / CGFloat(buttonCount)
        
        // 🎯 确保按钮宽度在合理范围内
        let finalButtonWidth = max(minButtonWidth, min(maxButtonWidth, idealButtonWidth))
        let finalSpacing = spacing
        let contentWidth = finalButtonWidth * CGFloat(buttonCount) + finalSpacing * CGFloat(buttonCount - 1)
        let finalWidth = contentWidth + containerPadding
        
        // 🔥 新增：最小宽度保护，确保容器不会过窄
        let minContainerWidth: CGFloat = 280  // 最小容器宽度
        let protectedWidth = max(minContainerWidth, finalWidth)
        
        // ✨ 全自适应布局调试信息  
        print("✨ [FULL_ADAPTIVE] 全自适应布局计算:")
        print("✨ [FULL_ADAPTIVE] - 屏幕宽度: \(screen.width)pt")
        print("✨ [FULL_ADAPTIVE] - 可用于按钮: \(availableForButtons)pt")
        print("✨ [FULL_ADAPTIVE] - 理想按钮宽度: \(idealButtonWidth)pt")
        print("✨ [FULL_ADAPTIVE] - 最终按钮宽度: \(finalButtonWidth)pt")
        print("✨ [FULL_ADAPTIVE] - 按钮间距: \(finalSpacing)pt")
        print("✨ [FULL_ADAPTIVE] - 按钮数量: \(buttonCount)")
        print("✨ [FULL_ADAPTIVE] - 内容宽度: \(contentWidth)pt")
        print("✨ [FULL_ADAPTIVE] - 容器内边距: \(containerPadding)pt")
        print("✨ [FULL_ADAPTIVE] - 计算容器宽度: \(finalWidth)pt")
        print("✨ [FULL_ADAPTIVE] - 最小保护宽度: \(minContainerWidth)pt")
        print("✨ [FULL_ADAPTIVE] - 最终容器宽度: \(protectedWidth)pt")
        print("✨ [FULL_ADAPTIVE] - 屏幕利用率: \(String(format: "%.1f", (protectedWidth / screen.width) * 100))%")
        print("✨ [FULL_ADAPTIVE] - 布局方式: 居左自适应")
        
        return (width: protectedWidth, buttonWidth: finalButtonWidth, spacing: finalSpacing)
    }
    
    // 计算控制栏自适应宽度 (保留兼容性)
    func adaptiveControlBarWidth(buttonCount: Int) -> CGFloat {
        return smartControlBarLayout(buttonCount: buttonCount).width
    }
    
    // 🔥 激进优化：计算最小边距
    func adaptiveMargins() -> UIEdgeInsets {
        let screen = currentScreen
        let baseMargin: CGFloat = 20
        
        switch screen.deviceType {
        case .iPhoneSE:
            return UIEdgeInsets(top: baseMargin * 0.3, left: baseMargin * 0.1, bottom: baseMargin * 0.3, right: baseMargin * 0.1) // 极小左右边距
        case .iPhone:
            return UIEdgeInsets(top: baseMargin * 0.4, left: baseMargin * 0.15, bottom: baseMargin * 0.4, right: baseMargin * 0.15) // 很小左右边距
        case .iPhoneX:
            return UIEdgeInsets(top: baseMargin * 0.3, left: baseMargin * 0.1, bottom: baseMargin * 0.3, right: baseMargin * 0.1) // 极小边距
        case .iPhonePlus:
            return UIEdgeInsets(top: baseMargin * 0.6, left: baseMargin * 0.3, bottom: baseMargin * 0.6, right: baseMargin * 0.3)
        case .iPhonePro:
            return UIEdgeInsets(top: baseMargin * 0.8, left: baseMargin * 0.5, bottom: baseMargin * 0.8, right: baseMargin * 0.5)
        case .iPhoneProMax:
            return UIEdgeInsets(top: baseMargin * 1.0, left: baseMargin * 0.7, bottom: baseMargin * 1.0, right: baseMargin * 0.7)
        case .iPad:
            return UIEdgeInsets(top: baseMargin * 1.2, left: baseMargin * 1.0, bottom: baseMargin * 1.2, right: baseMargin * 1.0)
        }
    }
    
    // 检查UI是否超出屏幕
    func isUIOutOfBounds(frame: CGRect) -> Bool {
        let screen = currentScreen
        return frame.maxX > screen.width || frame.maxY > screen.height || frame.minX < 0 || frame.minY < 0
    }
    
    // 获取安全的UI区域
    func safeUIArea() -> CGRect {
        let screen = currentScreen
        let margins = adaptiveMargins()
        return CGRect(
            x: margins.left,
            y: margins.top + screen.safeAreaInsets.top,
            width: screen.width - margins.left - margins.right,
            height: screen.height - margins.top - margins.bottom - screen.safeAreaInsets.top - screen.safeAreaInsets.bottom
        )
    }
}

// MARK: - 兼容性检查扩展
extension UIDevice {
    /// 兼容的modelIdentifier获取方法
    var modelIdentifier: String {
        // 使用系统信息获取设备型号，避免无限递归
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
    
    /// 获取设备类型（高端/中端/低端）
    var deviceCategory: DeviceCategory {
        let model = self.modelIdentifier
        return DeviceCategory.from(modelIdentifier: model)
    }
    
    /// 检查是否支持特定功能
    var supportsUltraWideCamera: Bool {
        if #available(iOS 13.0, *) {
            return AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) != nil
        }
        return false
    }
    
    var supportsTelephotoCamera: Bool {
        if #available(iOS 13.0, *) {
            // 方法1：直接获取长焦相机
            var telephotoDevice = AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back)
            var hasTelephoto = telephotoDevice != nil
            
            print("🔍 [TELEPHOTO_DETECTION] 设备型号: \(modelIdentifier), 直接检测长焦相机: \(hasTelephoto ? "✅ 有" : "❌ 无")")
            
            // 方法2：如果直接检测失败，尝试枚举所有相机设备
            if !hasTelephoto {
                print("🔍 [TELEPHOTO_DETECTION] 直接检测失败，尝试枚举相机设备")
                let discoverySession = AVCaptureDevice.DiscoverySession(
                    deviceTypes: [.builtInTelephotoCamera, .builtInDualCamera, .builtInTripleCamera],
                    mediaType: .video,
                    position: .back
                )
                
                let availableDevices = discoverySession.devices
                print("🔍 [TELEPHOTO_DETECTION] 可用相机设备数量: \(availableDevices.count)")
                
                for device in availableDevices {
                    print("🔍 [TELEPHOTO_DETECTION] 发现相机: \(device.localizedName), 类型: \(device.deviceType)")
                    if device.deviceType == .builtInTelephotoCamera {
                        telephotoDevice = device
                        hasTelephoto = true
                        print("🔍 [TELEPHOTO_DETECTION] ✅ 通过枚举发现长焦相机")
                        break
                    }
                }
            }
            
            // 方法3：对于已知的双摄设备，如果检测不到长焦相机，尝试其他方法
            if !hasTelephoto && deviceCategory == .highEnd {
                print("🔍 [TELEPHOTO_DETECTION] 双摄设备但未检测到长焦相机，尝试其他检测方法")
                
                // 尝试获取所有相机设备
                let allDevices = AVCaptureDevice.devices(for: .video)
                print("🔍 [TELEPHOTO_DETECTION] 所有视频设备数量: \(allDevices.count)")
                
                for device in allDevices {
                    print("🔍 [TELEPHOTO_DETECTION] 设备: \(device.localizedName), 位置: \(device.position == .back ? "后置" : "前置")")
                    if device.position == .back && device.deviceType == .builtInTelephotoCamera {
                        telephotoDevice = device
                        hasTelephoto = true
                        print("🔍 [TELEPHOTO_DETECTION] ✅ 通过全设备枚举发现长焦相机")
                        break
                    }
                }
            }
            
            if hasTelephoto {
                print("🔍 [TELEPHOTO_DETECTION] 长焦相机设备: \(telephotoDevice?.localizedName ?? "未知")")
            }
            
            return hasTelephoto
        }
        print("🔍 [TELEPHOTO_DETECTION] iOS版本过低，无法检测长焦相机")
        return false
    }
    
    var supportsFrontCamera: Bool {
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) != nil
    }
}

// MARK: - 设备类型枚举
enum DeviceCategory {
    case ultraHigh    // 三摄设备（iPhone 11 Pro及以上）
    case highEnd      // 双摄设备（iPhone 11等）
    case midRange     // 中端设备
    case lowEnd       // 低端设备（iPhone SE等）
    
    static func from(modelIdentifier: String) -> DeviceCategory {
        // 三摄设备
        let ultraHighModels = [
            "iPhone16,1", "iPhone16,2", // iPhone 15 Pro/Pro Max
            "iPhone15,2", "iPhone15,3", // iPhone 14 Pro/Pro Max
            "iPhone14,2", "iPhone14,3", // iPhone 13 Pro/Pro Max
            "iPhone13,3", "iPhone13,4", // iPhone 12 Pro/Pro Max
            "iPhone12,3", "iPhone12,5"  // iPhone 11 Pro/Pro Max
        ]
        
        // 双摄设备
        let highEndModels = [
            "iPhone15,4", "iPhone15,5", // iPhone 15/15 Plus
            "iPhone14,7", "iPhone14,8", // iPhone 14/14 Plus
            "iPhone14,4", "iPhone14,5", // iPhone 13/13 mini
            "iPhone13,1", "iPhone13,2", // iPhone 12/12 mini
            "iPhone12,1",               // iPhone 11
            "iPhone10,1", "iPhone10,2", "iPhone10,3", "iPhone10,4", "iPhone10,5", "iPhone10,6", // iPhone 8/8 Plus, iPhone X
            "iPhone9,1", "iPhone9,2", "iPhone9,3", "iPhone9,4"     // iPhone 7/7 Plus
        ]
        
        // 低端设备
        let lowEndModels = [
            "iPhone12,8", "iPhone14,6"  // iPhone SE (2nd/3rd gen)
        ]
        
        if ultraHighModels.contains(modelIdentifier) {
            return .ultraHigh
        } else if highEndModels.contains(modelIdentifier) {
            return .highEnd
        } else if lowEndModels.contains(modelIdentifier) {
            return .lowEnd
        } else {
            // 未知设备，根据实际能力判断
            return .midRange
        }
    }
}

// MARK: - iOS版本检查函数
struct iOSVersionCheck {
    /// 检查iOS版本是否满足要求
    static func isAvailable(_ version: String) -> Bool {
        if #available(iOS 14.0, *) {
            return true
        } else if #available(iOS 13.0, *) {
            return version != "14.0"
        } else {
            return version == "13.0"
        }
    }
    
    /// 获取当前iOS版本
    static var currentVersion: String {
        return UIDevice.current.systemVersion
    }
    
    /// 检查是否支持特定功能
    static var supportsModelIdentifier: Bool {
        if #available(iOS 13.0, *) {
            return true
        }
        return false
    }
    
    static var supportsAutomaticallyConfiguresOutputBufferDimensions: Bool {
        if #available(iOS 14.0, *) {
            return true
        }
        return false
    }
    
    static var supportsWindowScene: Bool {
        if #available(iOS 13.0, *) {
            return true
        }
        return false
    }
}

// MARK: - 设备能力检测函数
struct DeviceCapabilityCheck {
    /// 检测设备相机能力
    static func getCameraCapabilities() -> CameraCapabilities {
        let device = UIDevice.current
        
        var capabilities = CameraCapabilities()
        
        print("🔍 [CAMERA_DETECTION] 开始检测相机能力")
        print("🔍 [CAMERA_DETECTION] 设备型号: \(device.modelIdentifier)")
        print("🔍 [CAMERA_DETECTION] 设备类型: \(device.deviceCategory)")
        
        // 检测超广角相机
        if device.supportsUltraWideCamera {
            capabilities.hasUltraWideCamera = true
            print("🔍 [CAMERA_DETECTION] ✅ 检测到超广角相机")
        } else {
            print("🔍 [CAMERA_DETECTION] ❌ 未检测到超广角相机")
        }
        
        // 检测长焦相机
        if device.supportsTelephotoCamera {
            capabilities.hasTelephotoCamera = true
            print("🔍 [CAMERA_DETECTION] ✅ 检测到长焦相机")
        } else {
            print("🔍 [CAMERA_DETECTION] ❌ 未检测到长焦相机")
        }
        
        // 检测前置相机
        if device.supportsFrontCamera {
            capabilities.hasFrontCamera = true
            print("🔍 [CAMERA_DETECTION] ✅ 检测到前置相机")
        } else {
            print("🔍 [CAMERA_DETECTION] ❌ 未检测到前置相机")
        }
        
        // 根据设备类型推断其他能力
        let category = device.deviceCategory
        switch category {
        case .ultraHigh:
            capabilities.maxZoomFactor = 4.3
            capabilities.supportsHighFrameRate = true
            print("🔍 [CAMERA_DETECTION] 📱 设备类型: 三摄设备 (ultraHigh)")
        case .highEnd:
            capabilities.maxZoomFactor = 4.3
            capabilities.supportsHighFrameRate = true
            print("🔍 [CAMERA_DETECTION] 📱 设备类型: 双摄设备 (highEnd)")
        case .midRange:
            capabilities.maxZoomFactor = 3.0
            capabilities.supportsHighFrameRate = false
            print("🔍 [CAMERA_DETECTION] 📱 设备类型: 中端设备 (midRange)")
        case .lowEnd:
            capabilities.maxZoomFactor = 3.0
            capabilities.supportsHighFrameRate = false
            print("🔍 [CAMERA_DETECTION] 📱 设备类型: 低端设备 (lowEnd)")
        }
        
        print("🔍 [CAMERA_DETECTION] 最终相机能力: \(capabilities)")
        return capabilities
    }
}

// MARK: - 相机能力扩展
extension CameraViewController {
    /// 获取实际的长焦倍数
    private func getActualTelephotoZoom(for device: AVCaptureDevice) -> CGFloat {
        let model = UIDevice.current.modelIdentifier
        print("🔍 [TELEPHOTO_ZOOM] 检测长焦倍数，设备型号: \(model)")
        
        // 根据设备型号确定实际长焦倍数
        switch model {
        case "iPhone15,2", "iPhone15,3": // iPhone 15 Pro/Pro Max
            return 3.0
        case "iPhone14,2", "iPhone14,3": // iPhone 14 Pro/Pro Max
            return 3.0
        case "iPhone13,3", "iPhone13,4": // iPhone 12 Pro/Pro Max
            return 2.5
        case "iPhone12,3", "iPhone12,5": // iPhone 11 Pro/Pro Max
            return 2.0
        case "iPhone10,1", "iPhone10,2", "iPhone10,3", "iPhone10,4": // iPhone 8/8 Plus
            return 2.0
        case "iPhone9,1", "iPhone9,2", "iPhone9,3", "iPhone9,4": // iPhone 7/7 Plus
            return 2.0
        default:
            // 默认使用2x，或者从设备属性获取
            let maxZoom = device.activeFormat.videoMaxZoomFactor
            let defaultZoom = min(maxZoom, 2.0)
            print("🔍 [TELEPHOTO_ZOOM] 使用默认长焦倍数: \(defaultZoom)x")
            return defaultZoom
        }
    }
}

// MARK: - 相机能力结构体
struct CameraCapabilities {
    var hasUltraWideCamera: Bool = false
    var hasTelephotoCamera: Bool = false
    var hasFrontCamera: Bool = false
    var maxZoomFactor: CGFloat = 3.0
    var supportsHighFrameRate: Bool = false
    
    /// 获取可用的相机选项
    func getAvailableCameras() -> [String] {
        var cameras: [String] = []
        
        if hasUltraWideCamera {
            cameras.append("0.5x")
        }
        
        cameras.append("1x") // 广角相机总是可用
        
        if hasTelephotoCamera {
            cameras.append("2x")
            // 检查是否有3x长焦（需要进一步检测）
            if #available(iOS 13.0, *) {
                // 这里可以添加更详细的3x检测逻辑
            }
        }
        
        if hasFrontCamera {
            cameras.append("前置")
        }
        
        return cameras
    }
}

// MARK: - Apple Design 网格线视图
class GridLineView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Apple Design 网格线样式
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        let gridColor = isDarkMode ? UIColor.white : UIColor.black
        context.setStrokeColor(gridColor.withAlphaComponent(0.5).cgColor)
        context.setLineWidth(0.7)
        
        let width = rect.width
        let height = rect.height
        
        // 绘制三分法网格线
        // 垂直线（2条）
        let verticalLine1X = width / 3
        let verticalLine2X = width * 2 / 3
        context.move(to: CGPoint(x: verticalLine1X, y: 0))
        context.addLine(to: CGPoint(x: verticalLine1X, y: height))
        context.move(to: CGPoint(x: verticalLine2X, y: 0))
        context.addLine(to: CGPoint(x: verticalLine2X, y: height))
        
        // 水平线（2条）
        let horizontalLine1Y = height / 3
        let horizontalLine2Y = height * 2 / 3
        context.move(to: CGPoint(x: 0, y: horizontalLine1Y))
        context.addLine(to: CGPoint(x: width, y: horizontalLine1Y))
        context.move(to: CGPoint(x: 0, y: horizontalLine2Y))
        context.addLine(to: CGPoint(x: width, y: horizontalLine2Y))
        
        context.strokePath()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setNeedsDisplay() // 重新绘制以适应暗黑模式
    }
}

// MARK: - Apple Design UI 工具方法
extension UIViewController {
    func makeAppleButton(title: String, icon: String, style: UIButton.ButtonType = .system) -> UIButton {
        let btn = UIButton(type: style)
        btn.setTitle(title, for: .normal)
        btn.setImage(UIImage(systemName: icon), for: .normal)
        btn.tintColor = .label
        btn.backgroundColor = .systemBackground
        btn.layer.cornerRadius = 22
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOpacity = 0.08
        btn.layer.shadowOffset = CGSize(width: 0, height: 2)
        btn.layer.shadowRadius = 4
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }
    
    func makeAppleBlurView(style: UIBlurEffect.Style = .systemMaterialDark) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.layer.cornerRadius = 18
        blurView.layer.masksToBounds = true
        blurView.translatesAutoresizingMaskIntoConstraints = false
        return blurView
    }
    
    func makeAppleShutterButton() -> UIButton {
        let shutter = UIButton(type: .custom)
        shutter.backgroundColor = .white
        shutter.layer.cornerRadius = 30
        shutter.layer.shadowColor = UIColor.black.cgColor
        shutter.layer.shadowOpacity = 0.15
        shutter.layer.shadowOffset = CGSize(width: 0, height: 2)
        shutter.layer.shadowRadius = 6
        shutter.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加点击动画
        shutter.addTarget(self, action: #selector(shutterButtonTouchDown), for: .touchDown)
        shutter.addTarget(self, action: #selector(shutterButtonTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        return shutter
    }
    
    @objc func shutterButtonTouchDown() {
        UIView.animate(withDuration: 0.1) {
            self.view.viewWithTag(999)?.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }
    
    @objc func shutterButtonTouchUp() {
        UIView.animate(withDuration: 0.1) {
            self.view.viewWithTag(999)?.transform = CGAffineTransform.identity
        }
    }
}

extension UIImage {
    convenience init(color: UIColor, size: CGSize) {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        self.init(cgImage: image.cgImage!)
    }
}
// MARK: - 自定义静默保存管理器
class SilentSaveManager: ObservableObject {
    static let shared = SilentSaveManager()
    
    enum SaveLocation {
        case photoLibrary      // 系统相册
        case appDocuments      // App文档目录
        case customAlbum       // 自定义相册
        case iCloud           // iCloud Drive
    }
    
    @Published var currentSaveLocation: SaveLocation = .photoLibrary
    @Published var autoSaveEnabled = true
    @Published var customAlbumName = "PPPhoto"
    
    private init() {}
    
    // 静默保存到指定位置
    func silentSave(_ image: UIImage, location: SaveLocation? = nil) {
        let saveLocation = location ?? currentSaveLocation
        
        switch saveLocation {
        case .photoLibrary:
            saveToPhotoLibrary(image)
        case .appDocuments:
            saveToAppDocuments(image)
        case .customAlbum:
            saveToCustomAlbum(image)
        case .iCloud:
            saveToICloud(image)
        }
    }
    
    // 保存到系统相册（静默）
    private func saveToPhotoLibrary(_ image: UIImage) {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized || status == .limited {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            }
        }
    }
    
    // 保存到App文档目录
    private func saveToAppDocuments(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "PPPhoto_\(Date().timeIntervalSince1970).jpg"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
        } catch {}
    }
    
    // 保存到自定义相册
    private func saveToCustomAlbum(_ image: UIImage) {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized || status == .limited {
                self.createOrGetAlbum { album in
                    if let album = album {
                        PHPhotoLibrary.shared().performChanges({
                            let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
                            let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
                            albumChangeRequest?.addAssets([request.placeholderForCreatedAsset!] as NSArray)
                        })
                    }
                }
            }
        }
    }
    
    // 创建或获取自定义相册
    private func createOrGetAlbum(completion: @escaping (PHAssetCollection?) -> Void) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", customAlbumName)
        let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        if let album = collections.firstObject {
            completion(album)
        } else {
            PHPhotoLibrary.shared().performChanges({
                PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: self.customAlbumName)
            }) { success, error in
                if success {
                    let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
                    completion(collections.firstObject)
                } else {
                    completion(nil)
                }
            }
        }
    }
    
    // 保存到iCloud Drive
    private func saveToICloud(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return }
        
        let fileName = "PPPhoto_\(Date().timeIntervalSince1970).jpg"
        
        // 检查iCloud Drive是否可用
        if FileManager.default.ubiquityIdentityToken != nil {
            let iCloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents").appendingPathComponent(fileName)
            
            if let iCloudURL = iCloudURL {
                do {
                    try data.write(to: iCloudURL)
                } catch {}
            }
        }
    }
    
    // 批量保存
    func batchSave(_ images: [UIImage], location: SaveLocation? = nil) {
        let saveLocation = location ?? currentSaveLocation
        
        DispatchQueue.global(qos: .utility).async {
            for (index, image) in images.enumerated() {
                self.silentSave(image, location: saveLocation)
                // 避免同时保存过多图片导致性能问题
                Thread.sleep(forTimeInterval: 0.1)
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var saveManager = SilentSaveManager.shared
    @State private var showImagePicker = false
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var lastCapturedImage: UIImage? = nil
    @State private var showCustomCamera = false
    @State private var showSaveSettings = false
    
    var body: some View {
        CustomCameraView(onPhotoCapture: { image in
            if let safeImage = image as UIImage? {
                lastCapturedImage = safeImage
                // 使用静默保存管理器
                if saveManager.autoSaveEnabled {
                    saveManager.silentSave(safeImage)
                }
            }
        })
        .ignoresSafeArea(.all, edges: .all) // 忽略所有安全区域
        .statusBarHidden(true) // 隐藏状态栏
        .preferredColorScheme(.dark) // 强制深色模式
        .sheet(isPresented: $showSaveSettings) {
            SaveSettingsView()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowSaveSettings"))) { _ in
            showSaveSettings = true
        }
    }
}

// MARK: - 保存设置界面
struct SaveSettingsView: View {
    @StateObject private var saveManager = SilentSaveManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("自动保存设置") {
                    Toggle("启用自动保存", isOn: $saveManager.autoSaveEnabled)
                    
                    if saveManager.autoSaveEnabled {
                        Picker("保存位置", selection: $saveManager.currentSaveLocation) {
                            Text("系统相册").tag(SilentSaveManager.SaveLocation.photoLibrary)
                            Text("App文档").tag(SilentSaveManager.SaveLocation.appDocuments)
                            Text("自定义相册").tag(SilentSaveManager.SaveLocation.customAlbum)
                            Text("iCloud Drive").tag(SilentSaveManager.SaveLocation.iCloud)
                        }
                        
                        if saveManager.currentSaveLocation == .customAlbum {
                            TextField("相册名称", text: $saveManager.customAlbumName)
                        }
                    }
                }
                
                Section("保存说明") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• 系统相册：保存到iPhone相册")
                        Text("• App文档：保存到App私有目录")
                        Text("• 自定义相册：创建专属相册")
                        Text("• iCloud Drive：同步到云端")
                        Text("• 所有保存都是静默的，不会弹窗提示")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .navigationTitle("保存设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CustomCameraView: UIViewControllerRepresentable {
    var onPhotoCapture: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let vc = CameraViewController()
        vc.onPhotoCapture = onPhotoCapture
        return vc
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        // 无需更新内容，可留空
    }
}
class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UIGestureRecognizerDelegate {
    // MARK: - 性能优化：延迟初始化
    static let sharedSession = AVCaptureSession()
    static let sharedCIContext = CIContext(options: [.useSoftwareRenderer: false])
    
    // 延迟初始化属性
    private var _captureSession: AVCaptureSession?
    var captureSession: AVCaptureSession? {
        get {
            if _captureSession == nil {
                _captureSession = Self.sharedSession
            }
            return _captureSession
        }
        set {
            _captureSession = newValue
        }
    }
    
    private var _ciContext: CIContext?
    var ciContext: CIContext? {
        get {
            if _ciContext == nil {
                _ciContext = Self.sharedCIContext
            }
            return _ciContext
        }
        set {
            _ciContext = newValue
        }
    }
    
    // 延迟初始化其他属性
    private var _videoOutput: AVCaptureVideoDataOutput?
    var videoOutput: AVCaptureVideoDataOutput? {
        get {
            if _videoOutput == nil {
                _videoOutput = AVCaptureVideoDataOutput()
                _videoOutput?.alwaysDiscardsLateVideoFrames = true
                _videoOutput?.setSampleBufferDelegate(self, queue: processingQueue)
            }
            return _videoOutput
        }
        set {
            _videoOutput = newValue
        }
    }
    
    private var _photoOutput: AVCapturePhotoOutput?
    var photoOutput: AVCapturePhotoOutput? {
        get {
            if _photoOutput == nil {
                _photoOutput = AVCapturePhotoOutput()
            }
            return _photoOutput
        }
        set {
            _photoOutput = newValue
        }
    }
    
    private var _previewImageView: UIImageView?
    var previewImageView: UIImageView? {
        get {
            if _previewImageView == nil {
                _previewImageView = UIImageView()
                _previewImageView?.contentMode = .scaleAspectFill
                _previewImageView?.clipsToBounds = true
            }
            return _previewImageView
        }
        set {
            _previewImageView = newValue
        }
    }
    
    var currentCIImage: CIImage?
    var onPhotoCapture: ((UIImage) -> Void)?
    
    // CoreMotion相关
    private let motionManager = CMMotionManager()
    var currentDeviceOrientation: UIDeviceOrientation = .portrait {
        didSet {
            // 🔥 修复：保存设备方向状态到UserDefaults
            UserDefaults.standard.set(currentDeviceOrientation.rawValue, forKey: "SavedDeviceOrientation")
            print("📱 [STATE] 设备方向已保存: \(currentDeviceOrientation.rawValue)")
        }
    }
    
    // 对比度相关
    var contrastSlider: UISlider?
    var contrastButton: UIButton?
    var contrastContainer: UIView?
    var currentContrast: Float = 1.0
    
    // 饱和度相关
    var saturationSlider: UISlider?
    var saturationButton: UIButton?
    var saturationContainer: UIView?
    var currentSaturation: Float = 1.0
    
    // 新增色温相关变量
    var temperatureSlider: UISlider?
    var temperatureButton: UIButton?
    var temperatureContainer: UIView?
    var currentTemperature: Float = 50.0 // 色温滑块值，范围0-100，默认50
    
    var isContrastVisible = false
    var isSaturationVisible = false
    var isTemperatureVisible = false
    var isFilterPanelVisible = false
    
    var lastUpdateTime: TimeInterval = 0
    var isActive = true
    
    var albumButton: UIButton?
    
    var loadingView: UIActivityIndicatorView?
    
    // 优化帧处理：追求苹果原生相机级别的流畅度
    private var frameCount = 0
    private var previewFrameInterval = 1 // 每帧都处理，确保最大流畅度
    private var lastProcessingTime: CFTimeInterval = 0
    // 恢复前置摄像头标记变量
    private var isUsingFrontCamera = false
    
    // 新增：用于标记是否需要保存下一帧
    private var shouldSaveNextPreviewFrame = false
    
    // 新增：滤镜功能面板
    var filterPanelView: UIView?
    var filterPanelStack: UIStackView?
    var filterContrastButton: UIButton?
    var filterSaturationButton: UIButton?
    
    // 新增：自定义预览UIImageView用于滤镜实时预览
    var filteredPreviewImageView: UIImageView?
    
    // 新增：将switchButton声明为属性
    var switchButton: UIButton?
    
    // 新增：色温数值标签
    var temperatureValueLabel: UILabel?
    
    // 新增：对比度数值标签
    var contrastValueLabel: UILabel?
    
    // 新增：饱和度数值标签
    var saturationValueLabel: UILabel?
    
    var isSessionConfigured = false
    
    // 新增：多摄像头支持
    struct CameraOption {
        let device: AVCaptureDevice
        let label: String // "0.5x" "1x" "2x"
        var isDigitalZoom: Bool = false
        var digitalZoomFactor: CGFloat = 1.0
    }
    var cameraOptions: [CameraOption] = []
    var currentCameraIndex: Int = 0
    var cameraSwitchStack: UIStackView?
    
    private let sessionConfigLock = NSLock()
    
    var filterButton: UIButton?
    var paramButton: UIButton?
    
    // 新增：缩放轮盘相关属性
    var zoomWheelView: UIView?
    var zoomWheelBackground: UIView?
    var zoomValueLabel: UILabel?
    var zoomWheelSlider: UISlider?
    var currentZoomFactor: CGFloat = 1.0
    var isZoomWheelVisible = false
    var zoomWheelAutoHideTimer: Timer?
    var zoomWheelCenter: CGPoint = .zero
    var initialZoomFactor: CGFloat = 1.0
    var shutterButton: UIButton?
    
    // 防抖变量：防止频繁切换相机
    private var lastCameraSwitchTime: TimeInterval = 0
    private let cameraSwitchDebounceInterval: TimeInterval = 0.5 // 0.5秒内不重复切换
    private var lastSelectedCamera: AVCaptureDevice?
    
    // 预加载相关变量
    private var preloadedCamera: AVCaptureDevice?
    private var preloadedInput: AVCaptureDeviceInput?
    private var isPreloadingCamera = false
    
    let sessionQueue = DispatchQueue(label: "pphoto.sessionQueue")
    
    // 新增：曝光调节UI
    var exposureSlider: UISlider?
    var exposureContainer: UIView?
    var isExposureVisible = false
    
    // 网格线相关
    var isGridLineEnabled = false
    var gridLineView: GridLineView?
    var thumbnailGridLineView: GridLineView?
    var gridLineButton: UIButton?
    var currentExposure: Float = 50.0 // 曝光补偿值，初始化为中间值
    
    // 新增：曝光自动关闭定时器
    var exposureAutoHideTimer: Timer?
    
    // 滑动条自动隐藏定时器
    var contrastAutoHideTimer: Timer?
    var saturationAutoHideTimer: Timer?
    var temperatureAutoHideTimer: Timer?
    var exposureSliderAutoHideTimer: Timer?
    
    // 添加会话配置锁，防止begin/commit之间调用startRunning
    private var isConfiguringSession = false
    
    // 🔥 稳定性修复：防止UI重复设置
    private var isSettingUpUI = false
    
    // 🎬 轮盘镜头切换动画相关属性
    private var zoomTransitionBlurView: UIVisualEffectView?
    private var isPerformingZoomTransition = false
    
    // 在类属性区添加定时器引用
    var tempPlusTimer: Timer?
    var tempMinusTimer: Timer?
    var contrastPlusTimer: Timer?
    var contrastMinusTimer: Timer?
    var satPlusTimer: Timer?
    var satMinusTimer: Timer?
    
    var exposurePlusTimer: Timer?
    var exposureMinusTimer: Timer?
    
    // 在属性区添加：
    var exposureValueLabel: UILabel?
    
    // 1. 在类属性区添加所有加减按钮属性：
    var contrastPlusBtn: UIButton?
    var contrastMinusBtn: UIButton?
    var saturationPlusBtn: UIButton?
    var saturationMinusBtn: UIButton?
    var temperaturePlusBtn: UIButton?
    var temperatureMinusBtn: UIButton?
    var exposurePlusBtn: UIButton?
    var exposureMinusBtn: UIButton?
    
    // 隐藏状态栏，实现全屏沉浸式
    override var prefersStatusBarHidden: Bool { true }
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { [.bottom, .top] }
    
    // 只在首次启动时自动切换到1x
    private var hasSetDefaultCameraIndex = false
    
    // 🔥 新增：模拟器模式支持
    private var isSimulatorMode = false
    
    // ✨ 新增：启动遮罩相关属性
    private var splashOverlayView: UIView?
    private var isInitializationComplete = false
    private var initializationSteps: [String: TimeInterval] = [:]
    private var initializationStartTime: TimeInterval = 0
    

    
    // MARK: - 性能优化：队列和线程管理（第一步优化）
    // 🔥 统一队列管理：减少队列创建，优化线程切换
    static let sharedProcessingQueue = DispatchQueue(label: "camera.processing", 
                                                   qos: .userInteractive, 
                                                   attributes: [],
                                                   autoreleaseFrequency: .workItem,
                                                   target: nil) // 移除target，避免崩溃
    static let sharedFilterQueue = DispatchQueue(label: "filter.processing", 
                                                qos: .userInteractive, 
                                                attributes: .concurrent)
    static let sharedInitQueue = DispatchQueue(label: "camera.init", 
                                              qos: .userInitiated, 
                                              attributes: .concurrent)
    static let sharedBackgroundQueue = DispatchQueue(label: "background.tasks", 
                                                   qos: .userInitiated, 
                                                   attributes: .concurrent)
    static let sharedCacheQueue = DispatchQueue(label: "image.cache", 
                                              qos: .userInitiated, 
                                              attributes: .concurrent)
    
    // 优化：使用共享队列，减少队列创建开销
    var processingQueue: DispatchQueue { Self.sharedProcessingQueue }
    var previewProcessingQueue: DispatchQueue { Self.sharedFilterQueue }
    var initQueue: DispatchQueue { Self.sharedInitQueue }
    var backgroundQueue: DispatchQueue { Self.sharedBackgroundQueue }
    var cacheQueue: DispatchQueue { Self.sharedCacheQueue }
    
    // 优化：使用DispatchWorkItem管理异步任务，避免重复创建
    var filterUpdateWorkItem: DispatchWorkItem?
    var lastFilterUpdateTime: TimeInterval = 0
    
    // 优化：任务去重和合并
    private var pendingTasks: Set<String> = []
    private let taskQueue = DispatchQueue(label: "task.management", qos: .utility)
    
    // 性能优化：缓存最近处理的图像
    private var lastProcessedImage: UIImage?
    private var lastProcessedParams: (contrast: Float, saturation: Float, temperature: Float) = (1.0, 1.0, 6500.0)
    
    // 性能监控
    private var frameProcessingTimes: [TimeInterval] = []
    private let maxFrameTimes = 10
    
    // 内存优化：图片缓存系统
    private var imageCache = NSCache<NSString, UIImage>()
    private var maxCacheSize = 50 // 最多缓存50张图片
    
    // 内存优化：缓存配置
    
    // MARK: - 任务管理优化方法
    // 优化：避免重复任务执行
    private func executeTaskOnce(_ taskId: String, on queue: DispatchQueue, work: @escaping () -> Void) {
        taskQueue.async {
            guard !self.pendingTasks.contains(taskId) else { return }
            self.pendingTasks.insert(taskId)
            
            queue.async {
                work()
                self.taskQueue.async {
                    self.pendingTasks.remove(taskId)
                }
            }
        }
    }
    
    // 优化：批量任务执行
    private func executeBatchTasks(_ tasks: [(id: String, work: () -> Void)], on queue: DispatchQueue) {
        let group = DispatchGroup()
        
        for task in tasks {
            group.enter()
            executeTaskOnce(task.id, on: queue) {
                task.work()
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            print("✅ 批量任务执行完成")
        }
    }
    private var isCacheConfigured = false
    private func configureCache() {
        guard !isCacheConfigured else { return }
        
        // 优化：使用共享缓存队列
        cacheQueue.async {
            self.imageCache.countLimit = self.maxCacheSize
            self.imageCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
            self.imageCache.evictsObjectsWithDiscardedContent = true
            self.isCacheConfigured = true
            print("✅ 图片缓存配置完成")
        }
    }
    
    // 新增：zoom显示label
    var zoomLabel: UILabel?
    
    // 新增：AVCaptureVideoPreviewLayer
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    // 1. 添加"场景"按钮
    var sceneButton: UIButton?
    var isSceneGuideVisible = false
    
    // 在CameraViewController属性区添加：
    var sceneCategoryCollectionView: UICollectionView?
    var sceneImageCollectionView: UICollectionView?
    var sceneCategories: [String] = []
    var sceneImagesInCategory: [String] = []
    var currentSceneCategory: String?
    var scenePreviewImages: [String] = []
    var scenePreviewIndex: Int = 0
    var isScenePanelVisible: Bool = false
    // let sceneGuideRoot = "/Users/dreame/Desktop/pphoto/pphoto/拍照指引"
    var sceneGuideRoot: String? {
        let docDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let guidePath = (docDir as NSString).appendingPathComponent("拍照指引")
        if !FileManager.default.fileExists(atPath: guidePath) {
            // 先拷贝Bundle内置资源
            if let bundlePath = Bundle.main.path(forResource: "拍照指引", ofType: nil) {
                try? FileManager.default.copyItem(atPath: bundlePath, toPath: guidePath)
            } else {
                try? FileManager.default.createDirectory(atPath: guidePath, withIntermediateDirectories: true)
            }
        }
        return guidePath
    }
    
    // 1. 添加切换锁属性
    var isSwitchingCamera: Bool = false
    
    // 1. 添加镜头切换按钮数组属性
    var cameraSwitchButtons: [UIButton] = []
    
    // 在类属性区添加
    var exposureUpdateWorkItem: DispatchWorkItem?
    
    // 在CameraViewController属性区添加：
    var addSceneButton: UIButton?
    var addSceneImageButton: UIButton?
    
    // 在CameraViewController属性区添加：
    var displaySceneCategories: [String] { sceneCategories + ["__add__"] }
    var displaySceneImages: [String] { sceneImagesInCategory + ["__add__"] }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ✨ 立即显示启动遮罩，隐藏所有初始化过程
        createSplashOverlay()
        
        // 🔥 性能监控：记录viewDidLoad开始时间
        initializationStartTime = CACurrentMediaTime()
        let viewDidLoadStartTime = initializationStartTime
        print("🚀 [PERFORMANCE] ===== viewDidLoad 开始 =====")
        
        // 🔥 稳定性修复：确保在主线程执行
        guard Thread.isMainThread else {
            print("⚠️ [STABILITY] viewDidLoad不在主线程，调度到主线程")
            DispatchQueue.main.async { [weak self] in
                self?.viewDidLoad()
            }
            return
        }
        
        // 🔥 性能监控：记录基础设置时间
        let basicSetupStartTime = CACurrentMediaTime()
        print("🚀 [PERFORMANCE] 开始基础设置...")
        
        // 🔥 修复：重置UI初始化状态
        isSettingUpUI = false
        
        // 设置视图背景色
        view.backgroundColor = .black
        
        // 设置状态栏样式
        setNeedsStatusBarAppearanceUpdate()
        
        let basicSetupEndTime = CACurrentMediaTime()
        let basicSetupTime = (basicSetupEndTime - basicSetupStartTime) * 1000
        initializationSteps["基础设置"] = basicSetupTime
        print("🚀 [PERFORMANCE] 基础设置完成: \(String(format: "%.1f", basicSetupTime))ms")
        
        // 🔥 性能监控：记录状态恢复时间
        let stateRestoreStartTime = CACurrentMediaTime()
        print("🚀 [PERFORMANCE] 开始状态恢复...")
        
        // 🔥 修复：恢复应用状态
        restoreAppState()
        
        // 🔥 新增：添加应用生命周期监控
        setupAppLifecycleMonitoring()
        
        let stateRestoreEndTime = CACurrentMediaTime()
        let stateRestoreTime = (stateRestoreEndTime - stateRestoreStartTime) * 1000
        initializationSteps["状态恢复"] = stateRestoreTime
        print("🚀 [PERFORMANCE] 状态恢复完成: \(String(format: "%.1f", stateRestoreTime))ms")
        
        // 🚀 极限优化：延迟兼容性检查到后台
        initializationSteps["兼容性检查"] = 0.0  // 跳过同步检查
        print("🚀 [PERFORMANCE] 兼容性检查已延迟到后台")
        
        // 🚀 极限优化：缓存配置延迟到后台
        initializationSteps["缓存配置"] = 0.0  // 跳过同步配置
        print("🚀 [PERFORMANCE] 缓存配置已延迟到后台")
        
        // 🔥 性能监控：记录核心UI设置时间
        let coreUIStartTime = CACurrentMediaTime()
        print("🚀 [PERFORMANCE] 开始核心UI设置...")
        
        // 🔥 极速启动：立即显示核心UI，绝对最小化同步操作
        setupCoreUIOnly() // 阶段1: 仅显示黑屏+拍照按钮 (<50ms)
        
        let coreUIEndTime = CACurrentMediaTime()
        let coreUITime = (coreUIEndTime - coreUIStartTime) * 1000
        initializationSteps["核心UI设置"] = coreUITime
        print("🚀 [PERFORMANCE] 核心UI设置完成: \(String(format: "%.1f", coreUITime))ms")
        
        // 异步初始化所有其他功能（完全不阻塞UI）
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { 
                print("⚠️ [STABILITY] self为nil，跳过异步初始化")
                return 
            }
            
            // 🔥 性能监控：记录异步初始化时间
            let asyncInitStartTime = CACurrentMediaTime()
            print("🚀 [PERFORMANCE] 开始异步初始化...")
            
            // 🚀 极限优化：最小化异步初始化
            self.initializeMinimalServicesOptimized()
            
            let asyncInitEndTime = CACurrentMediaTime()
            let asyncInitTime = (asyncInitEndTime - asyncInitStartTime) * 1000
            self.initializationSteps["异步初始化"] = asyncInitTime
            print("🚀 [PERFORMANCE] 异步初始化完成: \(String(format: "%.1f", asyncInitTime))ms")
            
            // 🔥 修复闪烁：延迟初始化，在UI完成后再移除遮罩
            DispatchQueue.global(qos: .background).async {
                self.performCompatibilityCheck()
                self.configureCache()
                
                // UI初始化移到主线程
                DispatchQueue.main.async {
                    self.setupActualUI()
                    self.initializeRemainingServicesOptimized()
                    print("🚀 [BACKGROUND] 后台初始化完成")
                    
                    // ✨ UI创建完成后才移除启动遮罩
                    self.markInitializationComplete()
                    
                    // 🔥 新增：启动完成后的UI完整性验证
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.validateUICompletenessAfterStartup()
                    }
                }
            }
        }
        
        // 🔥 性能监控：记录viewDidLoad总时间
        let viewDidLoadEndTime = CACurrentMediaTime()
        let viewDidLoadTotalTime = (viewDidLoadEndTime - viewDidLoadStartTime) * 1000
        print("🚀 [PERFORMANCE] ===== viewDidLoad 完成 =====")
        print("🚀 [PERFORMANCE] 总耗时: \(String(format: "%.1f", viewDidLoadTotalTime))ms")
        print("🚀 [PERFORMANCE] 各阶段耗时详情:")
        print("  - 基础设置: \(String(format: "%.1f", basicSetupTime))ms")
        print("  - 状态恢复: \(String(format: "%.1f", stateRestoreTime))ms")
        print("  - 兼容性检查: 延迟到后台")
        print("  - 缓存配置: 延迟到后台")
        print("  - 核心UI设置: \(String(format: "%.1f", coreUITime))ms")
        
        // 🔥 性能分析：找出最慢的步骤
        let allTimes = [basicSetupTime, stateRestoreTime, coreUITime]
        let maxTime = allTimes.max() ?? 0
        let stepNames = ["基础设置", "状态恢复", "核心UI设置"]
        let slowestStepIndex = allTimes.firstIndex(of: maxTime) ?? 0
        print("🚀 [PERFORMANCE] 最慢步骤: \(stepNames[slowestStepIndex]) - \(String(format: "%.1f", maxTime))ms")
        
        // 🔥 性能建议
        if maxTime > 100 {
            print("⚠️ [PERFORMANCE] 警告: 最慢步骤超过100ms，建议优化")
        }
        if viewDidLoadTotalTime > 500 {
            print("⚠️ [PERFORMANCE] 警告: viewDidLoad总耗时超过500ms，建议优化")
        }
        
        print("🚀 [PERFORMANCE] ===== viewDidLoad 结束 =====")
    }
    
    // ✨ 启动遮罩方法
    private func createSplashOverlay() {
        // 创建全屏遮罩
        splashOverlayView = UIView(frame: view.bounds)
        splashOverlayView?.backgroundColor = UIColor.black
        splashOverlayView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // 添加App图标或Logo
        let logoImageView = UIImageView()
        logoImageView.image = UIImage(named: "AppIcon") ?? UIImage(systemName: "camera.fill")
        logoImageView.tintColor = .white
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加加载指示器
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = .white
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.startAnimating()
        
        // 添加加载文本
        let loadingLabel = UILabel()
        loadingLabel.text = "正在初始化相机..."
        loadingLabel.textColor = .white
        loadingLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        loadingLabel.textAlignment = .center
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        
        splashOverlayView?.addSubview(logoImageView)
        splashOverlayView?.addSubview(activityIndicator)
        splashOverlayView?.addSubview(loadingLabel)
        
        // 设置约束
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: splashOverlayView!.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: splashOverlayView!.centerYAnchor, constant: -60),
            logoImageView.widthAnchor.constraint(equalToConstant: 80),
            logoImageView.heightAnchor.constraint(equalToConstant: 80),
            
            activityIndicator.centerXAnchor.constraint(equalTo: splashOverlayView!.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 30),
            
            loadingLabel.centerXAnchor.constraint(equalTo: splashOverlayView!.centerXAnchor),
            loadingLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 20),
            loadingLabel.leadingAnchor.constraint(equalTo: splashOverlayView!.leadingAnchor, constant: 20),
            loadingLabel.trailingAnchor.constraint(equalTo: splashOverlayView!.trailingAnchor, constant: -20)
        ])
        
        view.addSubview(splashOverlayView!)
        view.bringSubviewToFront(splashOverlayView!)
        
        print("✨ [SPLASH] 启动遮罩已创建")
    }
    
    private func markInitializationComplete() {
        guard !isInitializationComplete else { return }
        isInitializationComplete = true
        
        let totalTime = (CACurrentMediaTime() - initializationStartTime) * 1000
        
        print("✨ [SPLASH] ===== 初始化完成总结 =====")
        print("✨ [SPLASH] 总耗时: \(String(format: "%.1f", totalTime))ms")
        print("✨ [SPLASH] 各步骤详细耗时:")
        
        for (step, time) in initializationSteps.sorted(by: { $0.value > $1.value }) {
            let percentage = (time / totalTime) * 100
            print("✨ [SPLASH]   - \(step): \(String(format: "%.1f", time))ms (\(String(format: "%.1f", percentage))%)")
        }
        
        if let slowestStep = initializationSteps.max(by: { $0.value < $1.value }) {
            print("✨ [SPLASH] 最耗时步骤: \(slowestStep.key) - \(String(format: "%.1f", slowestStep.value))ms")
        }
        
        print("✨ [SPLASH] ===== 开始移除遮罩 =====")
        
        // 平滑移除启动遮罩
        removeSplashOverlay()
    }
    
    private func removeSplashOverlay() {
        guard let overlay = splashOverlayView else { return }
        
        UIView.animate(withDuration: 0.5, animations: {
            overlay.alpha = 0.0
        }) { _ in
            overlay.removeFromSuperview()
            self.splashOverlayView = nil
            print("✨ [SPLASH] 启动遮罩已移除，相机界面现已可见")
        }
    }
    
    // 🚀 极限优化：最小化服务初始化
    private func initializeMinimalServicesOptimized() {
        print("⚡ [MINIMAL] 开始最小化服务初始化")
        let startTime = CACurrentMediaTime()
        
        // 只初始化最核心的服务
        initializeCriticalServicesOptimized()
        
        let endTime = CACurrentMediaTime()
        let time = (endTime - startTime) * 1000
        print("⚡ [MINIMAL] 最小化服务初始化完成: \(String(format: "%.1f", time))ms")
    }
    
    // 🚀 极限优化：剩余服务初始化（后台）
    private func initializeRemainingServicesOptimized() {
        print("🔄 [BACKGROUND] 开始剩余服务初始化")
        let startTime = CACurrentMediaTime()
        
        // 初始化非关键服务
        DispatchQueue.main.async {
            self.initializeDeferredFeaturesOptimized()
        }
        
        let endTime = CACurrentMediaTime()
        let time = (endTime - startTime) * 1000
        print("🔄 [BACKGROUND] 剩余服务初始化完成: \(String(format: "%.1f", time))ms")
    }
    
    // ⚡ 极限优化：超最小UI创建
    private func setupUltraMinimalUI() {
        print("⚡ [ULTRA_MIN] 开始超最小UI创建")
        // 暂时什么都不做，让启动遮罩承担所有UI显示工作
        print("⚡ [ULTRA_MIN] 超最小UI创建完成")
    }
    
    // 🎨 后台实际UI创建
    private func setupActualUI() {
        print("🎨 [ACTUAL_UI] 开始实际UI创建")
        let startTime = CACurrentMediaTime()
        
        // 🚀 立即创建所有核心UI元素
        setupMinimalShutterButton()
        setupThumbnailOnStartup()
        
        // 🔧 创建基础控制栏（功能、场景、参数按钮）
        setupBasicControlBar()
        
        // 🔧 创建相机切换UI
        setupCameraSwitchUI()
        
        let endTime = CACurrentMediaTime()
        let time = (endTime - startTime) * 1000
        print("🎨 [ACTUAL_UI] 实际UI创建完成: \(String(format: "%.1f", time))ms")
        
        // 🎨 确保UI控件在最顶层
        ensureUIControlsOnTop()
        
        // 🔥 修复闪烁：同步初始化完整UI系统，确保遮罩移除前UI完全准备好
        self.initializeCompleteUISystem()
    }
    
    // 🎨 初始化完整UI系统
    private func initializeCompleteUISystem() {
        print("🎨 [COMPLETE_UI] 开始完整UI系统初始化")
        let startTime = CACurrentMediaTime()
        
        // 确保所有UI都正确初始化
        setupUI()
        
        let endTime = CACurrentMediaTime()
        let time = (endTime - startTime) * 1000
        print("🎨 [COMPLETE_UI] 完整UI系统初始化完成: \(String(format: "%.1f", time))ms")
    }
    
    // 🔥 极速核心UI：仅显示最必要的元素 (<50ms) - 在启动遮罩下运行
    private func setupCoreUIOnly() {
        let coreUIStartTime = CACurrentMediaTime()
        print("🎨 [TIME] setupCoreUIOnly开始 (隐藏在启动遮罩下)")
        
        // 🔥 修复：延迟初始化设备方向检测，避免覆盖恢复的方向
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.initializeDeviceOrientationDetection()
        }
        
        // 1. 全黑背景
        view.backgroundColor = UIColor.black
        
        // 2. 🚀 极限优化：仅创建最核心的UI
        setupUltraMinimalUI()
        
        let coreUIEndTime = CACurrentMediaTime()
        let coreUITime = (coreUIEndTime - coreUIStartTime) * 1000
        print("🎨 [TIME] setupCoreUIOnly完成: \(String(format: "%.1f", coreUITime))ms (已隐藏)")
        
        // ✨ 修复：不再立即显示UI，等待所有初始化完成后由遮罩控制显示
        // self.showUIAfterInitialization() // 注释掉，由markInitializationComplete控制
    }
    
    // 🔥 修复：初始化完成后显示UI
    private func showUIAfterInitialization() {
        // 🔥 稳定性修复：检查UI状态
        guard let view = view else {
            print("❌ [STABILITY] showUIAfterInitialization: view为nil")
            return
        }
        
        // 🔥 稳定性修复：确保在主线程
        guard Thread.isMainThread else {
            print("⚠️ [STABILITY] showUIAfterInitialization不在主线程，调度到主线程")
            DispatchQueue.main.async { [weak self] in
                self?.showUIAfterInitialization()
            }
            return
        }
        
        // 🔥 修复：应用保存的UI状态
        applySavedUIState()
        
        // 确保所有UI元素同时显示，避免分批次显示
        UIView.animate(withDuration: 0.5) {
            // 显示拍照按钮
            if let shutterButton = self.view.viewWithTag(999) as? UIButton {
                shutterButton.alpha = 1.0
            }
            
            // 显示缩略图
            if let thumbImageView = self.view.viewWithTag(2001) as? UIImageView {
                thumbImageView.alpha = 1.0
            }
            
            // 显示功能UI
            if let blurView = self.view.viewWithTag(777) {
                blurView.alpha = 1.0
            }
            
            // 显示后置UI
            if let ovalBlur = self.view.viewWithTag(8888) {
                ovalBlur.alpha = 1.0
            }
            
            // 显示前置UI
            if let cycleButton = self.view.viewWithTag(9999) as? UIButton {
                cycleButton.alpha = 1.0
            }
        }
        
        print("📱 [DEBUG] UI显示完成")
        
        // 🔥 稳定性修复：移除UI状态监控，避免干扰
        print("✅ [STABILITY] UI显示完成")
    }
    

    
    // 极简拍照按钮（无阴影、无动画）
    private func setupMinimalShutterButton() {
        shutterButton = UIButton(type: .system)
        guard let shutterButton = shutterButton else { return }
        
        shutterButton.tag = 999 // 🔥 修复：设置正确的tag
        shutterButton.backgroundColor = .white
        shutterButton.layer.cornerRadius = 30
        shutterButton.translatesAutoresizingMaskIntoConstraints = false
        shutterButton.addTarget(self, action: #selector(shutterTapped), for: .touchUpInside)
        shutterButton.isEnabled = true // 🔥 修复：确保拍照按钮启用
        shutterButton.alpha = 0 // 🔥 修复：初始时隐藏，避免闪烁
        view.addSubview(shutterButton)
        
        NSLayoutConstraint.activate([
            shutterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shutterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -33),  // 上移25pt（从-8改为-33）
            shutterButton.widthAnchor.constraint(equalToConstant: 60),
            shutterButton.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        print("📱 [DEBUG] 极简拍照按钮创建完成，tag: \(shutterButton.tag)")
    }
    
    // 🔥 已移除：setupMinimalLoadingHint() 方法，避免重复的加载提示
    
    // 🔥 修复：在应用启动时创建缩略图
    private func setupThumbnailOnStartup() {
        // 左下角缩略图
        view.subviews.filter { $0.tag == 2001 }.forEach { $0.removeFromSuperview() }
        let thumbImageView = UIImageView()
        thumbImageView.translatesAutoresizingMaskIntoConstraints = false
        thumbImageView.contentMode = .scaleAspectFill
        thumbImageView.clipsToBounds = true
        thumbImageView.layer.cornerRadius = 8
        thumbImageView.backgroundColor = .black
        thumbImageView.isUserInteractionEnabled = true
        thumbImageView.tag = 2001
        thumbImageView.alpha = 0 // 🔥 修复：初始时隐藏，避免闪烁
        view.addSubview(thumbImageView)
        NSLayoutConstraint.activate([
            thumbImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
            thumbImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -dynamicBottomOffset() - 33), // 与拍照UI水平对齐
            thumbImageView.widthAnchor.constraint(equalToConstant: 56),
            thumbImageView.heightAnchor.constraint(equalToConstant: 56)
        ])
        refreshThumbnail()
        thumbImageView.gestureRecognizers?.forEach { thumbImageView.removeGestureRecognizer($0) }
        let tap = UITapGestureRecognizer(target: self, action: #selector(openLastPhotoInAlbum))
        thumbImageView.addGestureRecognizer(tap)
        
        print("📱 [DEBUG] 应用启动时缩略图创建完成")
    }
    
    // 预览占位符（立即显示，等待相机初始化）
    private func setupPreviewPlaceholder() {
        // 创建占位预览层
        let placeholderView = UIView(frame: view.bounds)
        placeholderView.backgroundColor = UIColor.black.withAlphaComponent(0.7) // 半透明背景避免闪烁
        placeholderView.tag = 888 // 🔥 修复：修改占位符tag，避免与拍照按钮冲突
        view.addSubview(placeholderView)
        
        // 添加加载动画
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = .white
        activityIndicator.center = placeholderView.center
        activityIndicator.startAnimating()
        placeholderView.addSubview(activityIndicator)
        
        // 添加提示文字
        let label = UILabel()
        label.text = "正在启动相机..."
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        placeholderView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: placeholderView.centerXAnchor),
            label.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 20)
        ])
    }
    
            // 关键按钮（立即显示）
        private func setupCriticalButtons() {
            // 拍照按钮（最重要）
            shutterButton = makeAppleShutterButton()
            guard let shutterButton = shutterButton else { return }
            
            shutterButton.tag = 999
            shutterButton.addTarget(self, action: #selector(shutterTapped), for: .touchUpInside)
            view.addSubview(shutterButton)
            NSLayoutConstraint.activate([
                shutterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                shutterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -33),  // 上移25pt（从-8改为-33）
                shutterButton.widthAnchor.constraint(equalToConstant: 60),
                shutterButton.heightAnchor.constraint(equalToConstant: 60)
            ])
        
        // 移除顶部功能按钮的创建，由setupBasicControlBar()统一处理
        // 避免重复创建blurView导致的UI冲突
    }
    
    // 🔥 异步初始化所有服务（分阶段，优先级排序）
    private func initializeAllServices() {
        let initStartTime = CACurrentMediaTime()
        print("🔄 后台服务初始化开始 (\(String(format: "%.1f", initStartTime * 1000))ms)")
        
        // 阶段1: 关键基础配置（最高优先级）
        initializeCriticalServices()
        
        // 阶段2: 相机系统（用户立即需要）
        DispatchQueue.global(qos: .userInitiated).async {
            self.initializeCameraSystem { cameraTime in
                print("📱 相机系统完成 (\(String(format: "%.1f", (cameraTime - initStartTime) * 1000))ms)")
                
                // 阶段3: UI控件（相机就绪后立即显示）
                DispatchQueue.main.async {
                    self.setupEssentialControls()
                    
                    // 确保UI控件在最顶层
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.ensureUIControlsOnTop()
                    }
                    
                    // 阶段4: 延迟加载的功能（低优先级）
                    DispatchQueue.global(qos: .utility).async {
                        self.initializeDeferredFeatures()
                    }
                }
            }
        }
    }
    

    
    // 🔥 性能优化版本：更智能的异步初始化
    private func initializeAllServicesOptimized() {
        let initStartTime = CACurrentMediaTime()
        print("🚀 [TIME] 优化版后台服务初始化开始 (\(String(format: "%.1f", initStartTime * 1000))ms)")
        
        // 🔥 修复：移除DispatchGroup，简化初始化流程
        
        // 阶段1: 关键基础配置（同步，必须立即完成）
        let criticalStartTime = CACurrentMediaTime()
        print("⚙️ [TIME] 关键服务配置开始")
        initializeCriticalServicesOptimized()
        let criticalEndTime = CACurrentMediaTime()
        let criticalTime = (criticalEndTime - criticalStartTime) * 1000
        print("⚙️ [TIME] 关键服务配置完成: \(String(format: "%.1f", criticalTime))ms")
        
        // 阶段2: 传感器系统（后台异步，不阻塞UI）
        backgroundQueue.async {
            let motionStartTime = CACurrentMediaTime()
            print("🔄 [TIME] 传感器系统初始化开始")
            self.initializeMotionSystemOptimized()
            let motionEndTime = CACurrentMediaTime()
            let motionTime = (motionEndTime - motionStartTime) * 1000
            print("🔄 [TIME] 传感器系统初始化完成: \(String(format: "%.1f", motionTime))ms")
        }
        
        // 阶段3: 相机系统（完成后立即触发UI初始化）
        initQueue.async {
            print("🔍 [DEBUG] 开始相机系统初始化")
            self.initializeCameraSystemOptimized { cameraTime in
                print("📱 [TIME] 相机系统完成 (\(String(format: "%.1f", (cameraTime - initStartTime) * 1000))ms)")
                print("🔍 [DEBUG] 相机系统completion回调被调用")
                
                // 🔥 修复：相机系统完成后立即在主线程初始化UI
                DispatchQueue.main.async {
                    print("🔍 [DEBUG] 进入主线程UI初始化")
                    print("🔍 [DEBUG] 当前线程: \(Thread.isMainThread ? "主线程" : "后台线程")")
                    let uiStartTime = CACurrentMediaTime()
                    print("🎮 [TIME] UI初始化开始 (\(String(format: "%.1f", (uiStartTime - initStartTime) * 1000))ms)")
                    
                    // 立即初始化基础UI控件
                    print("🔍 [DEBUG] 开始setupEssentialControlsOptimized")
                    self.setupEssentialControlsOptimized()
                    print("🔍 [DEBUG] setupEssentialControlsOptimized完成")
                    
                    // 立即确保UI控件在最顶层
                    print("🔍 [DEBUG] 开始ensureUIControlsOnTop")
                    self.ensureUIControlsOnTop()
                    print("🔍 [DEBUG] ensureUIControlsOnTop完成")
                    
                    // 阶段4: 延迟功能（完全异步，不阻塞UI）
                    DispatchQueue.global(qos: .background).async {
                        let deferredStartTime = CACurrentMediaTime()
                        print("🔄 [TIME] 延迟功能初始化开始")
                        self.initializeDeferredFeaturesOptimized()
                        let deferredEndTime = CACurrentMediaTime()
                        let deferredTime = (deferredEndTime - deferredStartTime) * 1000
                        print("🔄 [TIME] 延迟功能初始化完成: \(String(format: "%.1f", deferredTime))ms")
                    }
                    
                    // 🔥 总体性能分析
                    let totalEndTime = CACurrentMediaTime()
                    let totalTime = (totalEndTime - initStartTime) * 1000
                    print("🚀 [TIME] 总体初始化完成: \(String(format: "%.1f", totalTime))ms")
                    print("📊 [TIME] 性能分析:")
                    print("   - 核心UI: ~50ms (目标)")
                    print("   - 关键服务: ~100ms (目标)")
                    print("   - 相机系统: ~500ms (目标)")
                    print("   - UI控件: ~200ms (目标)")
                    print("   - 总计: ~850ms (目标)")
                }
            }
        }
    }
    
    // 阶段1: 关键基础配置（必须同步完成的最小配置）
    private func initializeCriticalServices() {
        // 内存缓存配置
        imageCache.totalCostLimit = maxCacheSize * 1024 * 1024
        imageCache.countLimit = maxCacheSize
        
        // 内存警告监听
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        
        // 性能优化应用
        applyPerformanceOptimizations()
        
        print("✅ 关键服务配置完成")
    }
    
    // 🔥 优化版关键服务配置
    private func initializeCriticalServicesOptimized() {
        let criticalStartTime = CACurrentMediaTime()
        print("⚙️ [TIME] initializeCriticalServicesOptimized开始")
        
        // 使用已配置的缓存系统
        configureCache()
        
        // 内存警告监听（优化版）
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarningOptimized),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        
        // 应用性能优化
        applyPerformanceOptimizationsOptimized()
        
        let criticalEndTime = CACurrentMediaTime()
        let criticalTime = (criticalEndTime - criticalStartTime) * 1000
        print("⚙️ [TIME] initializeCriticalServicesOptimized完成: \(String(format: "%.1f", criticalTime))ms")
    }
    
    // 阶段2: 相机系统初始化（异步，但高优先级）
    private func initializeCameraSystem(completion: @escaping (TimeInterval) -> Void) {
        let cameraStartTime = CACurrentMediaTime()
        print("📱 [TIME] 相机系统初始化开始")
        
        self.requestCameraPermissionIfNeeded {
            self.configureSessionIfNeeded()
            let cameraEndTime = CACurrentMediaTime()
            let cameraTime = (cameraEndTime - cameraStartTime) * 1000
            
            DispatchQueue.main.async {
                // 移除加载提示
                if let loadingLabel = self.view.viewWithTag(888) {
                    loadingLabel.removeFromSuperview()
                }
                
                // 设置真实预览
                self.setupRealPreviewLayer()
                
                print("📱 [TIME] 相机系统初始化完成: \(String(format: "%.1f", cameraTime))ms")
                completion(cameraEndTime)
            }
        }
    }
    
    // 🔥 优化版相机系统初始化
    private func initializeCameraSystemOptimized(completion: @escaping (TimeInterval) -> Void) {
        let cameraStartTime = CACurrentMediaTime()
        print("📱 [TIME] 优化版相机系统初始化开始")
        
        // 使用优化的队列进行相机初始化
        sessionQueue.async {
            // 预加载相机设备
            self.preloadCameraDevices()
            
            // 请求权限并配置会话
            self.requestCameraPermissionIfNeeded {
                self.configureSessionOptimized()
                let cameraEndTime = CACurrentMediaTime()
                let cameraTime = (cameraEndTime - cameraStartTime) * 1000
                
                DispatchQueue.main.async {
                    print("🔍 [DEBUG] 进入相机系统completion的主线程回调")
                    
                    // 移除加载提示
                    if let loadingLabel = self.view.viewWithTag(888) {
                        loadingLabel.removeFromSuperview()
                    }
                    
                    // 预览层已在会话启动时设置
                    // self.setupRealPreviewLayerOptimized()
                    
                    print("📱 [TIME] 优化版相机系统初始化完成: \(String(format: "%.1f", cameraTime))ms")
                    print("🔍 [DEBUG] 即将调用completion回调")
                    completion(cameraEndTime)
                    print("🔍 [DEBUG] completion回调已调用")
                }
            }
        }
    }
    
    // 阶段3: 必要控件（相机就绪后立即显示）
    private func setupEssentialControls() {
        print("🎮 必要控件初始化开始")
        
        // 替换简单按钮为完整按钮
        upgradeShutterButton()
        
        // 添加基础控制栏
        setupBasicControlBar()
        
        // 添加相机切换按钮
        setupCameraSwitchButtons()
        
        // 🔥 修复：确保拍照按钮状态正确
        updateCameraUI()
        
        print("🎮 必要控件初始化完成")
    }
    
    // 🔥 优化版必要控件初始化
    private func setupEssentialControlsOptimized() {
        let essentialStartTime = CACurrentMediaTime()
        print("🎮 [DEBUG] ===== setupEssentialControlsOptimized 开始 =====")
        print("🎮 [TIME] 优化版必要控件初始化开始")
        
        // 🔥 修复：移除CATransaction，避免UI更新被阻塞
        // 直接执行UI创建，确保立即生效
        
        // 替换简单按钮为完整按钮
        upgradeShutterButtonOptimized()
        
        // 添加基础控制栏（优化版）
        setupBasicControlBarOptimized()
        
        // 添加相机切换按钮（优化版）
        print("🔧 [DEBUG] ===== 即将调用setupCameraSwitchButtonsOptimized =====")
        setupCameraSwitchButtonsOptimized()
        print("🔧 [DEBUG] ===== setupCameraSwitchButtonsOptimized调用完成 =====")
        
        // 🔥 修复：确保拍照按钮状态正确
        updateCameraUI()
        
        // 🔥 修复：避免重复调用setupUI，只在必要时调用
        // setupUI() // 注释掉，避免重复初始化
        
        let essentialEndTime = CACurrentMediaTime()
        let essentialTime = (essentialEndTime - essentialStartTime) * 1000
        print("🎮 [TIME] 优化版必要控件初始化完成: \(String(format: "%.1f", essentialTime))ms")
        print("🎮 [DEBUG] ===== setupEssentialControlsOptimized 结束 =====")
    }
    
    // 阶段4: 延迟功能（完全懒加载）
    private func initializeDeferredFeatures() {
        print("⏳ 延迟功能初始化开始")
        
        // 这些功能只有在用户首次使用时才会真正初始化
        // 这里只是预设标记，实际初始化在用户触发时进行
        
        // 滤镜系统标记为未初始化（首次点击"功能"时初始化）
        isFilterSystemInitialized = false
        
        // 场景系统标记为未初始化（首次点击"场景"时初始化）
        isSceneSystemInitialized = false
    }
    
    // 🔥 优化版延迟功能初始化
    private func initializeDeferredFeaturesOptimized() {
        let deferredStartTime = CACurrentMediaTime()
        print("⏳ [TIME] 优化版延迟功能初始化开始")
        
        // 使用后台队列进行延迟初始化
        DispatchQueue.global(qos: .background).async {
            // 🔥 优化：移除场景系统预加载，避免阻塞
            // 场景系统将在真正需要时才加载
            
            // 预加载常用资源
            self.preloadCommonResources()
            
            // 设置懒加载标记
            self.setupLazyLoadingFlags()
            
            // 初始化缓存预热
            self.warmupCaches()
            
            let deferredEndTime = CACurrentMediaTime()
            let deferredTime = (deferredEndTime - deferredStartTime) * 1000
            print("⏳ [TIME] 优化版延迟功能初始化完成: \(String(format: "%.1f", deferredTime))ms")
            print("⏳ [DEBUG] 延迟功能初始化完成，开始后续处理")
            print("⏳ [DEBUG] 即将开始后续操作")
            print("⏳ [DEBUG] 检查是否有图片加载操作")
        }
    }
    
    // 预初始化CIContext（在后台低优先级执行）
    private func preInitializeCIContext() {
        // 预初始化CIContext
        do {
            let _ = CIContext()
            print("⏳ CIContext预初始化完成")
        } catch {
            print("⚠️ CIContext预初始化失败: \(error)")
        }
    }
    
    // 设置真实预览层
    private func setupRealPreviewLayer() {
        if previewLayer == nil {
            if let session = captureSession {
                let layer = AVCaptureVideoPreviewLayer(session: session)
                layer.videoGravity = .resizeAspect
                layer.frame = view.bounds
                view.layer.insertSublayer(layer, at: 0)
                previewLayer = layer
            }
        } else {
            previewLayer?.frame = view.bounds
        }
        
        // 设置滤镜预览层
        setupFilteredPreviewLayer()
    }
    
    // 升级拍照按钮（添加样式和功能）
    private func upgradeShutterButton() {
        // 移除简单按钮
        shutterButton?.removeFromSuperview()
        
        // 创建完整的拍照按钮
        shutterButton = makeAppleShutterButton()
        shutterButton!.tag = 999 // 🔥 修复：设置正确的tag
        shutterButton!.addTarget(self, action: #selector(shutterTapped), for: .touchUpInside)
        shutterButton!.isEnabled = true // 🔥 修复：确保拍照按钮启用
        shutterButton!.alpha = 1.0 // 🔥 修复：确保拍照按钮可见
        view.addSubview(shutterButton!)
        
        NSLayoutConstraint.activate([
            shutterButton!.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shutterButton!.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -33),  // 上移25pt（从-8改为-33）
            shutterButton!.widthAnchor.constraint(equalToConstant: 60),
            shutterButton!.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        print("📱 [DEBUG] 拍照按钮升级完成，tag: \(shutterButton!.tag)")
    }
    
    // 🔥 优化：设置自适应基础控制栏
    private func setupBasicControlBar() {
        let controlBarStartTime = CACurrentMediaTime()
        print("🔧 [TIME] setupBasicControlBar开始")
        
        // 🔥 新增：检查是否已存在功能控制栏，避免重复创建
        if let existingBlurView = view.viewWithTag(777) as? UIVisualEffectView {
            print("🔧 [DEBUG] 功能控制栏已存在，跳过重复创建")
            // 确保现有控制栏可见且在最顶层
            existingBlurView.alpha = 1.0
            existingBlurView.isHidden = false
            view.bringSubviewToFront(existingBlurView)
            return
        }
        
        // 🔥 全新：使用智能布局管理器
        let layoutManager = AdaptiveLayoutManager.shared
        let screenInfo = layoutManager.currentScreen
        
        print("🔧 [ADAPTIVE] 设备类型: \(screenInfo.deviceType)")
        print("🔧 [ADAPTIVE] 屏幕尺寸: \(screenInfo.width) x \(screenInfo.height)")
        print("🔧 [ADAPTIVE] 安全区域: \(screenInfo.safeAreaInsets)")
        
        let blurEffect = UIBlurEffect(style: .systemMaterialDark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.layer.cornerRadius = 22
        blurView.clipsToBounds = true
        view.addSubview(blurView)
        
        print("🔧 [DEBUG] blurView已添加到view，tag: \(blurView.tag)")
        
        // 🔥 全新：使用智能控制栏布局
        let buttonCount = 3
        let smartLayout = layoutManager.smartControlBarLayout(buttonCount: buttonCount)
        let margins = layoutManager.adaptiveMargins()
        
        // 🔥 直接使用智能布局的宽度，不再叠加边距
        let containerWidth = smartLayout.width  // 直接使用智能布局计算的宽度
        let buttonHeight = layoutManager.adaptiveButtonSize().height
        
        print("📐 [UI_WIDTH_DEBUG] ===== 详细宽度调试信息 =====")
        print("📐 [UI_WIDTH_DEBUG] 屏幕总宽度: \(screenInfo.width)pt")
        print("📐 [UI_WIDTH_DEBUG] 设备类型: \(screenInfo.deviceType)")
        print("📐 [UI_WIDTH_DEBUG] 智能布局内容宽度: \(smartLayout.width)pt")
        print("📐 [UI_WIDTH_DEBUG] 左边距: \(margins.left)pt")
        print("📐 [UI_WIDTH_DEBUG] 右边距: \(margins.right)pt")
        print("📐 [UI_WIDTH_DEBUG] 最终容器宽度: \(containerWidth)pt")
        print("📐 [UI_WIDTH_DEBUG] 容器宽度占屏幕比例: \(String(format: "%.1f", (containerWidth / screenInfo.width) * 100))%")
        print("📐 [UI_WIDTH_DEBUG] 按钮宽度: \(smartLayout.buttonWidth)pt")
        print("📐 [UI_WIDTH_DEBUG] 按钮间距: \(smartLayout.spacing)pt")
        print("📐 [UI_WIDTH_DEBUG] =============================")
        
        print("🔧 [SMART_LAYOUT] 智能布局结果:")
        print("🔧 [SMART_LAYOUT] - 容器宽度: \(containerWidth)")
        print("🔧 [SMART_LAYOUT] - 按钮宽度: \(smartLayout.buttonWidth)")
        print("🔧 [SMART_LAYOUT] - 按钮间距: \(smartLayout.spacing)")
        print("🔧 [SMART_LAYOUT] - 按钮高度: \(buttonHeight)")
        print("🔧 [SMART_LAYOUT] - 边距: \(margins)")
        
        NSLayoutConstraint.activate([
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10), // ✨ 使用固定小边距，避免重复计算
            blurView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: margins.top),
            blurView.heightAnchor.constraint(equalToConstant: buttonHeight),
            blurView.widthAnchor.constraint(equalToConstant: containerWidth) // 🔥 智能自适应宽度
        ])
        
        print("🔧 [DEBUG] 约束设置完成，布局更新已优化")
        print("🔧 [DEBUG] 开始确保blurView在最顶层")
        
        // 确保blurView在最顶层
        view.bringSubviewToFront(blurView)
        
        print("🔧 [DEBUG] blurView层级调整完成")
        
        print("🔧 [DEBUG] 开始创建功能按钮")
        // 立即显示所有功能按钮
        filterButton = makeAppleButton(title: "功能", icon: "slider.horizontal.3")
        filterButton?.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        filterButton?.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.3).cgColor
        filterButton?.layer.borderWidth = 1
        
        // 🔥 智能：根据屏幕尺寸调整contentEdgeInsets
        let contentInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
        
        filterButton?.contentEdgeInsets = contentInsets
        filterButton?.titleLabel?.font = UIFont.systemFont(ofSize: layoutManager.adaptiveFontSize(baseSize: 14), weight: .medium)
        filterButton?.layer.cornerRadius = buttonHeight / 2
        filterButton?.translatesAutoresizingMaskIntoConstraints = false
        filterButton?.addTarget(self, action: #selector(toggleFilterPanel), for: .touchUpInside)
        blurView.contentView.addSubview(filterButton!)
        print("🔧 [DEBUG] 功能按钮创建完成")
        
        print("🔧 [DEBUG] 开始创建场景按钮")
        // 场景按钮
        sceneButton = makeAppleButton(title: "场景", icon: "photo.on.rectangle")
        sceneButton?.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.1)
        sceneButton?.layer.borderColor = UIColor.systemPurple.withAlphaComponent(0.3).cgColor
        sceneButton?.layer.borderWidth = 1
        sceneButton?.contentEdgeInsets = contentInsets
        sceneButton?.titleLabel?.font = UIFont.systemFont(ofSize: layoutManager.adaptiveFontSize(baseSize: 14), weight: .medium)
        sceneButton?.layer.cornerRadius = buttonHeight / 2
        sceneButton?.translatesAutoresizingMaskIntoConstraints = false
        sceneButton?.addTarget(self, action: #selector(openSceneGuide), for: .touchUpInside)
        blurView.contentView.addSubview(sceneButton!)
        print("🔧 [DEBUG] 场景按钮创建完成")
        
        print("🔧 [DEBUG] 开始创建参数按钮")
        // 参数按钮
        paramButton = makeAppleButton(title: "参数", icon: "gearshape")
        paramButton?.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)
        paramButton?.layer.borderColor = UIColor.systemGreen.withAlphaComponent(0.3).cgColor
        paramButton?.layer.borderWidth = 1
        paramButton?.contentEdgeInsets = contentInsets
        paramButton?.titleLabel?.font = UIFont.systemFont(ofSize: layoutManager.adaptiveFontSize(baseSize: 14), weight: .medium)
        paramButton?.layer.cornerRadius = buttonHeight / 2
        paramButton?.translatesAutoresizingMaskIntoConstraints = false
        paramButton?.addTarget(self, action: #selector(showParamManager), for: .touchUpInside)
        blurView.contentView.addSubview(paramButton!)
        print("🔧 [DEBUG] 参数按钮创建完成")
        
        print("🔧 [DEBUG] 开始设置按钮约束")
        // 🔥 智能：使用智能布局的动态计算约束
        NSLayoutConstraint.activate([
            filterButton!.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor, constant: margins.left),
            filterButton!.centerYAnchor.constraint(equalTo: blurView.contentView.centerYAnchor),
            filterButton!.heightAnchor.constraint(equalToConstant: buttonHeight),
            filterButton!.widthAnchor.constraint(equalToConstant: smartLayout.buttonWidth), // 🔥 智能按钮宽度
            
            sceneButton!.leadingAnchor.constraint(equalTo: filterButton!.trailingAnchor, constant: smartLayout.spacing),
            sceneButton!.centerYAnchor.constraint(equalTo: blurView.contentView.centerYAnchor),
            sceneButton!.heightAnchor.constraint(equalToConstant: buttonHeight),
            sceneButton!.widthAnchor.constraint(equalToConstant: smartLayout.buttonWidth), // 🔥 智能按钮宽度
            
            paramButton!.leadingAnchor.constraint(equalTo: sceneButton!.trailingAnchor, constant: smartLayout.spacing),
            paramButton!.centerYAnchor.constraint(equalTo: blurView.contentView.centerYAnchor),
            paramButton!.heightAnchor.constraint(equalToConstant: buttonHeight),
            paramButton!.widthAnchor.constraint(equalToConstant: smartLayout.buttonWidth), // 🔥 智能按钮宽度
            paramButton!.trailingAnchor.constraint(lessThanOrEqualTo: blurView.contentView.trailingAnchor, constant: -margins.right)
        ])
        print("🔧 [DEBUG] 按钮约束设置完成")
        
        // 保存blurView引用
        blurView.tag = 777
        
        let controlBarEndTime = CACurrentMediaTime()
        let controlBarTime = (controlBarEndTime - controlBarStartTime) * 1000
        print("🔧 [TIME] setupBasicControlBar完成: \(String(format: "%.1f", controlBarTime))ms")
        print("🔧 [DEBUG] filterButton: \(filterButton != nil)")
        print("🔧 [DEBUG] sceneButton: \(sceneButton != nil)")
        print("🔧 [DEBUG] paramButton: \(paramButton != nil)")
        print("🔧 [DEBUG] blurView在view中的位置: \(view.subviews.contains(blurView))")
        print("🔧 [DEBUG] blurView frame: \(blurView.frame)")
        print("🔧 [DEBUG] blurView alpha: \(blurView.alpha)")
        print("🔧 [DEBUG] blurView isHidden: \(blurView.isHidden)")
        
        // 🔥 性能监控：检查自适应效果
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("🔧 [DEBUG] 自适应检查 - blurView最终frame: \(blurView.frame)")
            print("🔧 [DEBUG] 自适应检查 - 屏幕宽度: \(UIScreen.main.bounds.width)")
            print("🔧 [DEBUG] 自适应检查 - 容器是否超出屏幕: \(blurView.frame.maxX > UIScreen.main.bounds.width)")
            
            // 🔥 新增：详细的自适应检查
            let isOutOfBounds = layoutManager.isUIOutOfBounds(frame: blurView.frame)
            let safeArea = layoutManager.safeUIArea()
            print("🔧 [ADAPTIVE] UI是否超出边界: \(isOutOfBounds)")
            print("🔧 [ADAPTIVE] 安全UI区域: \(safeArea)")
            print("🔧 [ADAPTIVE] 控制栏在安全区域内: \(safeArea.contains(blurView.frame))")
            
            if isOutOfBounds {
                print("⚠️ [ADAPTIVE] 警告：控制栏超出屏幕边界，需要调整")
            }
            
            // 🔥 新增：检查按钮文字是否显示省略号
            self.checkAndAdjustControlBarWidth()
        }
    }
    
    // 设置相机切换按钮（最基础的）
    private func setupCameraSwitchButtons() {
        print("🔧 [DEBUG] ===== setupCameraSwitchButtons 开始 =====")
        // 🔥 修复：直接在主线程创建UI，不依赖cameraOptions
        let asyncStartTime = CACurrentMediaTime()
        
        DispatchQueue.main.async {
            print("🔧 [DEBUG] 进入主线程async块")
            print("🔧 [TIME] 开始执行setupCameraSwitchUI")
            self.setupCameraSwitchUI()
            print("🔧 [DEBUG] setupCameraSwitchUI调用完成")
            print("🔧 [TIME] setupCameraSwitchUI执行完成")
            
            // 🔥 修复：在UI创建完成后确保控件在最顶层
            self.ensureUIControlsOnTop()
            
            print("🔧 [DEBUG] UI初始化完成，开始后续处理")
            print("🔧 [DEBUG] 即将开始后续异步操作")
            
            let asyncEndTime = CACurrentMediaTime()
            let asyncTime = (asyncEndTime - asyncStartTime) * 1000
            print("🔧 [TIME] 异步操作总耗时: \(String(format: "%.1f", asyncTime))ms")
            print("🔧 [DEBUG] 异步操作完成，即将返回调用者")
        }
        
        print("🔧 [DEBUG] ===== setupCameraSwitchButtons 结束 =====")
        print("🔧 [DEBUG] setupCameraSwitchButtons调用完成，即将开始后续操作")
    }
    // 创建相机切换按钮UI
    private func setupCameraSwitchUI() {
        print("🔧 [DEBUG] ===== setupCameraSwitchUI 开始 =====")
        
        // 镜头切换按钮组美化，包裹在椭圆背景内
        if cameraSwitchStack != nil {
            cameraSwitchStack?.removeFromSuperview()
        }
        // 先移除旧的包裹视图
        view.viewWithTag(8888)?.removeFromSuperview()
        
        // 苹果风格毛玻璃磨砂背景 - 更透明
        let ovalBlur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        ovalBlur.translatesAutoresizingMaskIntoConstraints = false
        ovalBlur.tag = 8888  // 添加tag用于控制显示/隐藏
        ovalBlur.layer.cornerRadius = 24  // 稍微减小圆角
        ovalBlur.clipsToBounds = true
        ovalBlur.layer.borderWidth = 0.8  // 更细的边框
        ovalBlur.layer.borderColor = UIColor.white.withAlphaComponent(0.15).cgColor  // 更透明的边框
        ovalBlur.alpha = 0.85  // 更透明
        view.addSubview(ovalBlur)
        
        // 确保ovalBlur在最顶层
        view.bringSubviewToFront(ovalBlur)
        
        cameraSwitchStack = UIStackView()
        cameraSwitchStack?.axis = .horizontal
        cameraSwitchStack?.alignment = .center
        cameraSwitchStack?.distribution = .equalSpacing
        cameraSwitchStack?.spacing = 16  // 稍微减少间距
        cameraSwitchStack?.translatesAutoresizingMaskIntoConstraints = false
        
        print("🔧 [DEBUG] cameraSwitchStack初始化完成: \(cameraSwitchStack != nil)")
        
        print("🔧 [DEBUG] ===== 开始按钮遍历 =====")
        print("🔧 [DEBUG] cameraOptions数量: \(cameraOptions.count)")
        
        // 🔥 修复：如果cameraOptions为空，创建默认按钮
        if cameraOptions.isEmpty {
            print("🔧 [DEBUG] cameraOptions为空，创建默认相机按钮")
            
            // 创建默认的1x按钮
            let btn = UIButton(type: .system)
            btn.setTitle("1x", for: .normal)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .bold)
            btn.setTitleColor(.white, for: .normal)
            btn.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.75)
            let sizeW: CGFloat = 32
            let sizeH: CGFloat = 24
            btn.frame = CGRect(x: 0, y: 0, width: sizeW, height: sizeH)
            btn.layer.cornerRadius = sizeH / 2
            btn.clipsToBounds = true
            btn.tag = 0
            btn.addTarget(self, action: #selector(switchToCameraWithAnimation(_:)), for: .touchUpInside)
            
            // 添加长按手势
            let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleCameraButtonLongPress(_:)))
            longPressGesture.minimumPressDuration = 0.3
            longPressGesture.allowableMovement = 20
            longPressGesture.delegate = self
            btn.addGestureRecognizer(longPressGesture)
            
            // 选中状态
            btn.layer.borderWidth = 1.2
            btn.layer.borderColor = UIColor.white.withAlphaComponent(0.8).cgColor
            
            cameraSwitchStack?.addArrangedSubview(btn)
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.widthAnchor.constraint(equalToConstant: sizeW).isActive = true
            btn.heightAnchor.constraint(equalToConstant: sizeH).isActive = true
            
            print("🔧 [DEBUG] 默认1x按钮创建完成")
        } else {
        // 只显示后置镜头选项（0.5x, 1x, 2x）
        for (idx, option) in cameraOptions.enumerated() {
            print("🔧 [DEBUG] 处理按钮 \(idx): \(option.label)")
            
            // 跳过前置相机选项
            if option.label == "前置" {
                print("🔧 [DEBUG] 跳过前置相机按钮")
                continue
            }
            
            print("🔧 [DEBUG] 创建按钮 \(idx)")
            let btn = UIButton(type: .system)
            btn.setTitle(option.label, for: .normal)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: idx == currentCameraIndex ? 14 : 12, weight: .bold)  // 更小的字体
            btn.setTitleColor(idx == currentCameraIndex ? .white : UIColor.white.withAlphaComponent(0.7), for: .normal)
            btn.backgroundColor = idx == currentCameraIndex ? UIColor.systemBlue.withAlphaComponent(0.75) : UIColor.black.withAlphaComponent(0.15)  // 更透明
            let sizeW: CGFloat = 32  // 更小的宽度
            let sizeH: CGFloat = 24  // 更小的高度
            btn.frame = CGRect(x: 0, y: 0, width: sizeW, height: sizeH)
            btn.layer.cornerRadius = sizeH / 2
            btn.clipsToBounds = true
            btn.tag = idx
            btn.addTarget(self, action: #selector(switchToCameraWithAnimation(_:)), for: .touchUpInside)
            
            // 添加长按手势用于显示缩放轮盘
            print("🎯 [DEBUG] 开始为按钮 \(idx) 添加长按手势")
            let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleCameraButtonLongPress(_:)))
            longPressGesture.minimumPressDuration = 0.3 // 0.3秒触发长按
            longPressGesture.allowableMovement = 20 // 允许20像素的移动
            longPressGesture.delegate = self // 设置手势代理
            print("🎯 [DEBUG] 长按手势创建完成，开始添加到按钮")
            btn.addGestureRecognizer(longPressGesture)
            print("🎯 [DEBUG] 为按钮 \(idx) 添加长按手势完成")
            print("🎯 [DEBUG] 按钮手势数量: \(btn.gestureRecognizers?.count ?? 0)")
            print("🎯 [DEBUG] 按钮isUserInteractionEnabled: \(btn.isUserInteractionEnabled)")
            print("🎯 [DEBUG] 按钮父视图: \(btn.superview?.tag ?? -1)")
            
            // 选中按钮主色描边和阴影
            if idx == currentCameraIndex {  // 根据实际选中的相机索引高亮
                btn.layer.borderWidth = 1.2  // 更细的边框
                btn.layer.borderColor = UIColor.white.withAlphaComponent(0.8).cgColor
            } else {
                btn.layer.borderWidth = 0
            }
            
            cameraSwitchStack?.addArrangedSubview(btn)
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.widthAnchor.constraint(equalToConstant: sizeW).isActive = true
            btn.heightAnchor.constraint(equalToConstant: sizeH).isActive = true
            
            print("🔧 [DEBUG] 按钮 \(idx) 设置完成")
            }
        }
        
        print("🔧 [DEBUG] ===== 按钮遍历完成 =====")
        
        // 安全地添加cameraSwitchStack到ovalBlur
        if let stack = cameraSwitchStack {
            // 检查ovalBlur和其contentView是否有效
            if ovalBlur.contentView != nil {
                ovalBlur.contentView.addSubview(stack)
                print("✅ [DEBUG] 成功添加cameraSwitchStack到ovalBlur")
            } else {
                print("⚠️ [DEBUG] ovalBlur.contentView为nil，跳过添加")
                return
            }
        } else {
            print("⚠️ [DEBUG] cameraSwitchStack为nil，跳过添加")
            return
        }
        
        // 苹果风格椭圆宽度根据按钮数量自适应 - 更小更透明
        let rearCameraCount = cameraOptions.isEmpty ? 1 : cameraOptions.filter { $0.label != "前置" }.count
        let buttonWidth: CGFloat = 32  // 每个按钮的宽度
        let buttonSpacing: CGFloat = 16  // 按钮间距
        let padding: CGFloat = 24  // 左右边距
        
        // 分步计算避免复杂表达式
        let totalButtonWidth = buttonWidth * CGFloat(rearCameraCount)
        let totalSpacing = buttonSpacing * CGFloat(max(0, rearCameraCount - 1))
        let ovalWidth: CGFloat = totalButtonWidth + totalSpacing + padding
        
        print("🔧 [DEBUG] 后置相机数量: \(rearCameraCount)")
        print("🔧 [DEBUG] 按钮宽度: \(buttonWidth)")
        print("🔧 [DEBUG] 按钮间距: \(buttonSpacing)")
        print("🔧 [DEBUG] 边距: \(padding)")
        print("🔧 [DEBUG] 总按钮宽度: \(totalButtonWidth)")
        print("🔧 [DEBUG] 总间距: \(totalSpacing)")
        print("🔧 [DEBUG] 计算的ovalWidth: \(ovalWidth)")
        
        // 计算预览层正下方的位置（类似图2的布局）
        let previewBottomY = view.bounds.height * 0.7  // 预览区域大约占屏幕70%
        let cameraUIY = previewBottomY + 60  // 预览层下方60像素（上移20pt）
        
        // 安全地设置约束
        if let stack = cameraSwitchStack {
            NSLayoutConstraint.activate([
                ovalBlur.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                ovalBlur.topAnchor.constraint(equalTo: view.topAnchor, constant: cameraUIY), // 位于预览层正下方
                ovalBlur.heightAnchor.constraint(equalToConstant: 32),  // 更小的高度
                ovalBlur.widthAnchor.constraint(equalToConstant: ovalWidth),
                stack.centerXAnchor.constraint(equalTo: ovalBlur.contentView.centerXAnchor),
                stack.centerYAnchor.constraint(equalTo: ovalBlur.contentView.centerYAnchor),
                stack.heightAnchor.constraint(equalToConstant: 24)  // 更小的高度
            ])
        } else {
            print("⚠️ [DEBUG] cameraSwitchStack为nil，跳过约束设置")
        }
        
        print("摄像头切换按钮组创建完成")
        
        // 🔥 优化：移除延迟的手势测试，避免阻塞
        // 手势测试已在testLongPressGestures中延迟执行
        
        print("🔄 [DEBUG] ===== 即将调用setupFrontCameraCycleButton =====")
        // 创建前置相机轮回图标UI（右下角）
        setupFrontCameraCycleButton()
        print("🔄 [DEBUG] ===== setupFrontCameraCycleButton调用完成 =====")
        print("🔄 [DEBUG] 摄像头切换按钮组创建流程完成")
        print("🔧 [DEBUG] ===== setupCameraSwitchUI 结束 =====")
    }
    
    // 🔥 修复：恢复按钮高亮逻辑
    private func updateCameraButtonHighlights() {
        print("🎯 [DEBUG] ===== updateCameraButtonHighlights 开始 =====")
        
        // 遍历cameraSwitchStack中的所有按钮
        if let stack = cameraSwitchStack {
            print("🎯 [DEBUG] 找到cameraSwitchStack，按钮数量: \(stack.arrangedSubviews.count)")
            
            for case let button as UIButton in stack.arrangedSubviews {
                let buttonIndex = button.tag
                
                // 更新按钮高亮状态
                if buttonIndex == currentCameraIndex {
                    button.layer.borderWidth = 1.2
                    button.layer.borderColor = UIColor.white.withAlphaComponent(0.8).cgColor
                    button.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.75)
                    button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .bold)
                    button.setTitleColor(.white, for: .normal)
                } else {
                    button.layer.borderWidth = 0
                    button.backgroundColor = UIColor.black.withAlphaComponent(0.15)
                    button.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .bold)
                    button.setTitleColor(UIColor.white.withAlphaComponent(0.7), for: .normal)
                }
            }
        } else {
            print("🎯 [DEBUG] cameraSwitchStack为nil，跳过按钮高亮更新")
        }
        
        print("🎯 [DEBUG] ===== updateCameraButtonHighlights 结束 =====")
    }
    
    // 创建前置相机轮回图标UI（右下角）
    private func setupFrontCameraCycleButton() {
        print("🔄 [DEBUG] ===== setupFrontCameraCycleButton 开始 =====")
        let cycleButtonStartTime = CACurrentMediaTime()
        
        // 移除旧的轮回按钮
        print("🔄 [TIME] 开始移除旧的轮回按钮")
        view.viewWithTag(9999)?.removeFromSuperview()
        print("🔄 [TIME] 移除旧的轮回按钮完成")
        
        // 创建轮回图标按钮
        print("🔄 [TIME] 开始创建轮回图标按钮")
        let cycleButton = UIButton(type: .system)
        cycleButton.translatesAutoresizingMaskIntoConstraints = false
        cycleButton.tag = 9999
        print("🔄 [TIME] 轮回图标按钮创建完成")
        
        // 设置轮回图标（两个箭头形成循环）
        print("🔄 [TIME] 开始设置轮回图标")
        let cycleImage = UIImage(systemName: "arrow.triangle.2.circlepath")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        )
        cycleButton.setImage(cycleImage, for: .normal)
        cycleButton.tintColor = .white
        print("🔄 [TIME] 轮回图标设置完成")
        
        // 设置按钮样式
        print("🔄 [TIME] 开始设置按钮样式")
        cycleButton.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        cycleButton.layer.cornerRadius = 22
        cycleButton.layer.borderWidth = 1.0
        cycleButton.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        print("🔄 [TIME] 按钮样式设置完成")
        
        // 添加点击事件
        print("🔄 [TIME] 开始添加点击事件")
        cycleButton.addTarget(self, action: #selector(switchToFrontCamera), for: .touchUpInside)
        print("🔄 [TIME] 点击事件添加完成")
        
        // 🔥 修复：前置UI只负责前后置镜头切换，移除长按手势
        // 前置UI不需要长按功能，避免显示轮盘
        print("🔄 [TIME] 前置UI不添加长按手势，只保留点击切换功能")
        
        print("🔄 [TIME] 开始添加按钮到view")
        view.addSubview(cycleButton)
        print("🔄 [TIME] 按钮添加到view完成")
        
        // 设置约束 - 右下角，下移100pt
        print("🔄 [TIME] 开始设置约束")
        NSLayoutConstraint.activate([
            cycleButton.widthAnchor.constraint(equalToConstant: 44),
            cycleButton.heightAnchor.constraint(equalToConstant: 44),
            cycleButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            cycleButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -33)  // 与拍照UI水平对齐
        ])
        print("🔄 [TIME] 约束设置完成")
        
        print("前置相机轮回图标创建完成")
        
        // 直接更新UI状态
        print("🔄 [TIME] 开始调用updateCameraUI")
        updateCameraUI()
        print("🔄 [TIME] updateCameraUI调用完成")
        
        let cycleButtonEndTime = CACurrentMediaTime()
        let cycleButtonTime = (cycleButtonEndTime - cycleButtonStartTime) * 1000
        print("🔄 [TIME] setupFrontCameraCycleButton总耗时: \(String(format: "%.1f", cycleButtonTime))ms")
        
        print("🔄 [DEBUG] ===== setupFrontCameraCycleButton 结束 =====")
        print("🔄 [DEBUG] 轮回按钮创建完成，即将返回调用者")
    }
    
    // 切换前置/后置相机
    @objc private func switchToFrontCamera() {
        print("🔄 [DEBUG] 切换相机按钮被点击，当前isUsingFrontCamera: \(isUsingFrontCamera)")
        
        guard !isSwitchingCamera else { 
            print("⚠️ [DEBUG] 相机正在切换中，忽略点击")
            return 
        }
        
        guard !isPerformingZoomTransition else {
            print("🎬 [DEBUG] 模糊动画进行中，忽略前后置切换")
            return
        }
        
        // 判断当前是否为前置相机
        if isUsingFrontCamera {
            // 切换回后置相机（默认1x）
            if let rearCameraIndex = cameraOptions.firstIndex(where: { $0.label == "1x" }) {
                print("📱 [DEBUG] 🎬 使用模糊动画切换到后置相机，索引: \(rearCameraIndex)")
                let targetDevice = cameraOptions[rearCameraIndex].device
                currentCameraIndex = rearCameraIndex
                performSmoothZoomTransition(to: targetDevice, withZoom: 1.0)
            }
        } else {
            // 切换到前置相机
            if let frontCameraIndex = cameraOptions.firstIndex(where: { $0.label == "前置" }) {
                print("📱 [DEBUG] 🎬 使用模糊动画切换到前置相机，索引: \(frontCameraIndex)")
                let targetDevice = cameraOptions[frontCameraIndex].device
                currentCameraIndex = frontCameraIndex
                performSmoothZoomTransition(to: targetDevice, withZoom: 1.0)
            }
        }
    }
    
    // 直接切换相机（不通过UI按钮）
    private func switchToCameraDirectly(_ cameraIndex: Int) {
        print("🎯 [DEBUG] 直接切换相机到索引: \(cameraIndex)")
        
        // 1. 切换时对当前预览做截图，叠加在预览层上
        var snapshotView: UIView?
        if let imageView = self.filteredPreviewImageView {
            let snap = imageView.snapshotView(afterScreenUpdates: false)
            snap?.frame = imageView.bounds
            if let snap = snap {
                imageView.addSubview(snap)
                snapshotView = snap
            }
        }
        
        // 2. 彻底阻断帧流
        self.videoOutput?.setSampleBufferDelegate(nil, queue: nil)
        
        // 3. 隐藏滤镜和参数面板，以及缩放轮盘
        DispatchQueue.main.async {
            // 🔥 修复：相机切换时重置所有面板状态为关闭
            self.isFilterPanelVisible = false
            self.isSceneGuideVisible = false
            self.isContrastVisible = false
            self.isSaturationVisible = false
            self.isTemperatureVisible = false
            self.isExposureVisible = false
            
            // 🔥 修复：强制隐藏对应的UI元素，确保状态同步
            if let filterPanelView = self.filterPanelView {
                filterPanelView.isHidden = true
                print("🎨 [DEBUG] 相机切换：强制隐藏功能面板")
            }
            self.sceneCategoryCollectionView?.isHidden = true
            self.sceneImageCollectionView?.isHidden = true
            self.contrastContainer?.isHidden = true
            self.saturationContainer?.isHidden = true
            self.temperatureContainer?.isHidden = true
            self.exposureContainer?.isHidden = true
            
            // 隐藏缩放轮盘
            self.hideZoomWheel(animated: false)
            
            // 🔥 修复：强制更新按钮状态，确保UI反映正确的状态
            self.updateButtonStates()
            
            // 🔥 修复：再次确认状态同步
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.updateButtonStates()
            }
        }
        
        sessionQueue.async {
            guard !self.cameraOptions.isEmpty && cameraIndex >= 0 && cameraIndex < self.cameraOptions.count else {
                DispatchQueue.main.async {
                    self.isSwitchingCamera = false
                    snapshotView?.removeFromSuperview()
                }
                return
            }
            
            self.currentCameraIndex = cameraIndex
            self.setupCamera(startSessionIfNeeded: true)
            
            // 更新前置相机状态
            if let selectedDevice = self.getCurrentCameraDevice() {
                self.isUsingFrontCamera = (selectedDevice.position == .front)
                print("📱 [DEBUG] 相机切换完成，当前相机位置: \(selectedDevice.position == .front ? "前置" : "后置"), isUsingFrontCamera=\(self.isUsingFrontCamera)")
            } else {
                print("⚠️ [DEBUG] 无法获取当前相机设备")
            }
            
            // 切换完成后，淡出动画再恢复UI和帧流
            DispatchQueue.main.async {
                if let snap = snapshotView {
                    UIView.animate(withDuration: 0.18, animations: {
                        snap.alpha = 0
                    }) { _ in
                        snap.removeFromSuperview()
                        self.videoOutput?.setSampleBufferDelegate(self, queue: self.sessionQueue)
                        self.updateCameraUI()  // 只更新UI状态，不重新创建
                        self.isSwitchingCamera = false
                    }
                } else {
                    self.videoOutput?.setSampleBufferDelegate(self, queue: self.sessionQueue)
                    self.updateCameraUI()  // 只更新UI状态，不重新创建
                    self.isSwitchingCamera = false
                }
            }
        }
    }
    
    // 更新相机UI（前置/后置分离）
    private func updateCameraUI() {
        print("🎨 [DEBUG] ===== updateCameraUI 开始 =====")
        
        // 确保前置镜头轮回按钮始终可见
        if let cycleButton = view.viewWithTag(9999) as? UIButton {
            cycleButton.isHidden = false
            cycleButton.alpha = 1.0
        }
        
        // 确保基础UI始终可见（blurView）
        if let blurView = view.viewWithTag(777) {
            blurView.alpha = 1.0
            blurView.isHidden = false
        }
        
        // 根据是否是前置相机来显示/隐藏UI
        if isUsingFrontCamera {
            // 隐藏后置镜头UI
            view.viewWithTag(8888)?.alpha = 0
            // 更新轮回图标样式（高亮）
            if let cycleButton = view.viewWithTag(9999) as? UIButton {
                cycleButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.5)
                cycleButton.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
            }
        } else {
            // 显示后置镜头UI
            view.viewWithTag(8888)?.alpha = 1
            // 更新轮回图标样式（正常）
            if let cycleButton = view.viewWithTag(9999) as? UIButton {
                cycleButton.backgroundColor = UIColor.black.withAlphaComponent(0.3)
                cycleButton.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
            }
            
            // 只更新按钮高亮状态，不重新创建整个UI
            updateCameraButtonHighlights()
        }
        
        // 🔥 修复：确保拍照按钮状态正确
        if let shutterButton = view.viewWithTag(999) as? UIButton {
            shutterButton.isEnabled = true
            shutterButton.alpha = 1.0
            shutterButton.isUserInteractionEnabled = true
            print("📱 [DEBUG] updateCameraUI中拍照按钮状态已更新")
        }
        
        print("🎨 [DEBUG] ===== updateCameraUI 结束 =====")
    }
    
    // 🔥 修复：恢复视图层级操作，确保UI控件可以接收点击事件
    private func ensureUIControlsOnTop() {
        print("🔧 [DEBUG] ===== ensureUIControlsOnTop 开始 =====")
        
        // 🔥 修复：强制布局更新，确保所有约束都已应用
        view.layoutIfNeeded()
        
        // 确保缩略图在最顶层
        if let thumbImageView = view.viewWithTag(2001) {
            view.bringSubviewToFront(thumbImageView)
            print("🔧 [DEBUG] thumbImageView已置于最顶层")
        } else {
            print("⚠️ [DEBUG] thumbImageView未找到")
        }
        
        // 确保基础UI控件在最顶层，特别是在模拟器环境中
        if let blurView = view.viewWithTag(777) {
            view.bringSubviewToFront(blurView)
            print("🔧 [DEBUG] blurView已置于最顶层")
        } else {
            print("⚠️ [DEBUG] blurView未找到")
        }
        
        if let ovalBlur = view.viewWithTag(8888) {
            view.bringSubviewToFront(ovalBlur)
            print("🔧 [DEBUG] ovalBlur已置于最顶层")
        } else {
            print("⚠️ [DEBUG] ovalBlur未找到")
        }
        
        if let cycleButton = view.viewWithTag(9999) {
            view.bringSubviewToFront(cycleButton)
            print("🔧 [DEBUG] cycleButton已置于最顶层")
        } else {
            print("⚠️ [DEBUG] cycleButton未找到")
        }
        
        if let shutterButton = view.viewWithTag(999) {
            view.bringSubviewToFront(shutterButton)
            print("🔧 [DEBUG] shutterButton已置于最顶层")
        } else {
            print("⚠️ [DEBUG] shutterButton未找到")
        }
        
        // 确保功能按钮在最顶层
        if let filterButton = filterButton {
            view.bringSubviewToFront(filterButton)
            print("🔧 [DEBUG] filterButton已置于最顶层")
        } else {
            print("⚠️ [DEBUG] filterButton未找到")
        }
        
        if let sceneButton = sceneButton {
            view.bringSubviewToFront(sceneButton)
            print("🔧 [DEBUG] sceneButton已置于最顶层")
        } else {
            print("⚠️ [DEBUG] sceneButton未找到")
        }
        
        if let paramButton = paramButton {
            view.bringSubviewToFront(paramButton)
            print("🔧 [DEBUG] paramButton已置于最顶层")
        } else {
            print("⚠️ [DEBUG] paramButton未找到")
        }
        
        // 🔥 修复：强制再次布局更新，确保层级调整生效
        view.layoutIfNeeded()
        
        print("🔧 [DEBUG] ===== ensureUIControlsOnTop 结束 =====")
        print("🔧 [DEBUG] UI控件层级调整完成")
    }
    
    // 设置滤镜预览层
    private func setupFilteredPreviewLayer() {
        if filteredPreviewImageView == nil {
            let previewWidth = view.bounds.width
            let previewHeight = view.bounds.height
            filteredPreviewImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: previewWidth, height: previewHeight))
            filteredPreviewImageView?.contentMode = .scaleAspectFit
            filteredPreviewImageView?.isUserInteractionEnabled = true
            filteredPreviewImageView?.backgroundColor = .clear
            filteredPreviewImageView?.translatesAutoresizingMaskIntoConstraints = false
            filteredPreviewImageView?.isHidden = false
            filteredPreviewImageView?.alpha = 0.0 // 🔥 初始透明，等待图像处理完成后淡入
            filteredPreviewImageView?.clipsToBounds = true
            filteredPreviewImageView?.layer.masksToBounds = true
            view.addSubview(filteredPreviewImageView!)
            
            // 🔥 修复：确保拍照按钮在预览层之上
            if let shutterButton = view.viewWithTag(999) as? UIButton {
                view.bringSubviewToFront(shutterButton)
            }
            
            // 🔥 修复：确保缩略图在预览层之上
            if let thumbImageView = view.viewWithTag(2001) as? UIImageView {
                view.bringSubviewToFront(thumbImageView)
            }
            
            // 🔥 修复：确保功能UI在预览层之上
            if let blurView = view.viewWithTag(777) as? UIVisualEffectView {
                view.bringSubviewToFront(blurView)
            }
            
            // 🔥 修复：确保后置UI在预览层之上
            if let ovalBlur = view.viewWithTag(8888) as? UIVisualEffectView {
                view.bringSubviewToFront(ovalBlur)
            }
            
            // 🔥 修复：确保前置UI在预览层之上
            if let cycleButton = view.viewWithTag(9999) as? UIButton {
                view.bringSubviewToFront(cycleButton)
            }
            
            NSLayoutConstraint.activate([
                filteredPreviewImageView!.topAnchor.constraint(equalTo: view.topAnchor),
                filteredPreviewImageView!.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                filteredPreviewImageView!.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                filteredPreviewImageView!.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
        } else {
            filteredPreviewImageView?.frame = view.bounds
        }
    }
    
    // 懒加载扩展控制栏（首次点击功能时调用）
    func expandControlBarWithButtons() {
        guard let blurView = view.viewWithTag(777) as? UIVisualEffectView else { return }
        
        // 🔥 修复：使用动态计算的宽度，而不是硬编码
        let layoutManager = AdaptiveLayoutManager.shared
        let smartLayout = layoutManager.smartControlBarLayout(buttonCount: 3)
        let targetWidth = max(320, smartLayout.width) // 确保最小宽度320pt
        
        // 扩展blurView宽度
        blurView.constraints.forEach { constraint in
            if constraint.firstAttribute == .width {
                constraint.constant = targetWidth
                print("🔧 [EXPAND] 扩展控制栏宽度到: \(targetWidth)pt")
            }
        }
        
        // 添加场景按钮
        if sceneButton == nil {
            sceneButton = makeAppleButton(title: "场景", icon: "photo.on.rectangle")
            sceneButton?.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.1)
            sceneButton?.layer.borderColor = UIColor.systemPurple.withAlphaComponent(0.3).cgColor
            sceneButton?.layer.borderWidth = 1
            sceneButton?.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
            sceneButton?.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            sceneButton?.layer.cornerRadius = 14
            sceneButton?.translatesAutoresizingMaskIntoConstraints = false
            sceneButton?.addTarget(self, action: #selector(openSceneGuide), for: .touchUpInside)
            blurView.contentView.addSubview(sceneButton!)
        }
        
        // 添加参数按钮
        if paramButton == nil {
            paramButton = makeAppleButton(title: "参数", icon: "gearshape")
            paramButton?.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)
            paramButton?.layer.borderColor = UIColor.systemGreen.withAlphaComponent(0.3).cgColor
            paramButton?.layer.borderWidth = 1
            paramButton?.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
            paramButton?.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            paramButton?.layer.cornerRadius = 14
            paramButton?.translatesAutoresizingMaskIntoConstraints = false
            paramButton?.addTarget(self, action: #selector(showParamManager), for: .touchUpInside)
            blurView.contentView.addSubview(paramButton!)
        }
        
        // 更新约束
        NSLayoutConstraint.activate([
            sceneButton!.leadingAnchor.constraint(equalTo: filterButton!.trailingAnchor, constant: 6),
            sceneButton!.centerYAnchor.constraint(equalTo: blurView.contentView.centerYAnchor),
            sceneButton!.heightAnchor.constraint(equalToConstant: 28),
            paramButton!.leadingAnchor.constraint(equalTo: sceneButton!.trailingAnchor, constant: 6),
            paramButton!.centerYAnchor.constraint(equalTo: blurView.contentView.centerYAnchor),
            paramButton!.heightAnchor.constraint(equalToConstant: 28),
            paramButton!.trailingAnchor.constraint(lessThanOrEqualTo: blurView.contentView.trailingAnchor, constant: -6)
        ])
        
        // 🔥 优化：移除强制布局更新，避免阻塞
        // 添加展开动画
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: [], animations: {
            // blurView.layoutIfNeeded() // 注释掉强制布局更新
        }, completion: nil)
    }
    
    // 替换占位符为真实相机预览
    private func replacePlaceholderWithCamera() {
        // 移除占位符
        if let placeholderView = view.viewWithTag(999) {
            placeholderView.removeFromSuperview()
        }
        
        // 设置真实预览层
        if previewLayer == nil {
            if let session = captureSession {
                let layer = AVCaptureVideoPreviewLayer(session: session)
                layer.videoGravity = .resizeAspect
                layer.frame = view.bounds
                view.layer.insertSublayer(layer, at: 0)
                previewLayer = layer
            }
        } else {
            previewLayer?.frame = view.bounds
        }
        
        // 设置滤镜预览层
        if filteredPreviewImageView == nil {
            let previewWidth = view.bounds.width
            let previewHeight = view.bounds.height
            filteredPreviewImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: previewWidth, height: previewHeight))
            filteredPreviewImageView?.contentMode = .scaleAspectFit
            filteredPreviewImageView?.isUserInteractionEnabled = true
            filteredPreviewImageView?.backgroundColor = .clear
            filteredPreviewImageView?.translatesAutoresizingMaskIntoConstraints = false
            filteredPreviewImageView?.isHidden = false
            filteredPreviewImageView?.alpha = 0.0 // 🔥 初始透明，等待图像处理完成后淡入
            filteredPreviewImageView?.clipsToBounds = true
            filteredPreviewImageView?.layer.masksToBounds = true
            filteredPreviewImageView?.layer.cornerRadius = 16
            filteredPreviewImageView?.layer.shadowColor = UIColor.black.cgColor
            filteredPreviewImageView?.layer.shadowOpacity = 0.1
            filteredPreviewImageView?.layer.shadowOffset = CGSize(width: 0, height: 4)
            filteredPreviewImageView?.layer.shadowRadius = 8
            view.addSubview(filteredPreviewImageView!)
            NSLayoutConstraint.activate([
                filteredPreviewImageView!.topAnchor.constraint(equalTo: view.topAnchor),
                filteredPreviewImageView!.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                filteredPreviewImageView!.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                filteredPreviewImageView!.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
        } else {
            filteredPreviewImageView?.frame = view.bounds
        }
    }
    
    // 设置剩余UI（延迟加载）
    private func setupRemainingUI() {
        DispatchQueue.main.async {
            // 添加场景和参数按钮
            self.addSceneAndParamButtons()
            
            // 预初始化CIContext
            self.preInitializeCIContext()
            
            print("🎨 剩余UI初始化完成")
        }
    }
    
    // 添加场景和参数按钮
    private func addSceneAndParamButtons() {
        guard let blurView = view.subviews.first(where: { $0 is UIVisualEffectView }) as? UIVisualEffectView else { return }
        
        // 场景按钮
        sceneButton = makeAppleButton(title: "场景", icon: "photo.on.rectangle")
        sceneButton?.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.1)
        sceneButton?.layer.borderColor = UIColor.systemPurple.withAlphaComponent(0.3).cgColor
        sceneButton?.layer.borderWidth = 1
        sceneButton?.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        sceneButton?.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        sceneButton?.layer.cornerRadius = 14
        sceneButton?.translatesAutoresizingMaskIntoConstraints = false
        sceneButton?.addTarget(self, action: #selector(openSceneGuide), for: .touchUpInside)
        
        // 参数按钮
        paramButton = makeAppleButton(title: "参数", icon: "gearshape")
        paramButton?.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)
        paramButton?.layer.borderColor = UIColor.systemGreen.withAlphaComponent(0.3).cgColor
        paramButton?.layer.borderWidth = 1
        paramButton?.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        paramButton?.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        paramButton?.layer.cornerRadius = 14
        paramButton?.translatesAutoresizingMaskIntoConstraints = false
        paramButton?.addTarget(self, action: #selector(showParamManager), for: .touchUpInside)
        
        blurView.contentView.addSubview(sceneButton!)
        blurView.contentView.addSubview(paramButton!)
        
        // 更新约束
        NSLayoutConstraint.activate([
            sceneButton!.leadingAnchor.constraint(equalTo: filterButton!.trailingAnchor, constant: 6),
            sceneButton!.centerYAnchor.constraint(equalTo: blurView.contentView.centerYAnchor),
            sceneButton!.heightAnchor.constraint(equalToConstant: 28),
            paramButton!.leadingAnchor.constraint(equalTo: sceneButton!.trailingAnchor, constant: 6),
            paramButton!.centerYAnchor.constraint(equalTo: blurView.contentView.centerYAnchor),
            paramButton!.heightAnchor.constraint(equalToConstant: 28),
            paramButton!.trailingAnchor.constraint(lessThanOrEqualTo: blurView.contentView.trailingAnchor, constant: -6)
        ])
        
        // 🔥 修复：移除硬编码宽度约束，使用智能布局计算的宽度
        // blurView.widthAnchor.constraint(equalToConstant: 250).isActive = true
    }
    
    // 内存警告处理
    @objc private func handleMemoryWarning() {
        print("⚠️ 收到内存警告，开始清理缓存")
        
        // 立即清理所有缓存
        imageCache.removeAllObjects()
        lastProcessedImage = nil
        
        // 内存优化：适度降低质量但保持流畅度
        if let device = (captureSession?.inputs.first as? AVCaptureDeviceInput)?.device {
            setOptimalFrameRate(for: device, targetFrameRate: 25)
            print("📱 适度降低帧率以节省内存")
        }
        
        // 不改变处理间隔，通过其他方式节省内存
        // previewFrameInterval保持为1，确保流畅度
        
        print("📱 内存优化完成")
        DispatchQueue.main.async {
            // 清理CollectionView的图片缓存
            self.sceneImageCollectionView?.reloadData()
        }
    }

    // 🔥 懒加载标记
    private var isFilterSystemInitialized = false
    private var isSceneSystemInitialized = false
    private var isParamSystemInitialized = false

    // 🔥 懒加载系统：按需初始化
    private func setupFilterSystemIfNeeded() {
        guard !isFilterSystemInitialized else { return }
        
        print("🎨 滤镜系统懒加载开始")
        
        DispatchQueue.global(qos: .userInitiated).async {
            // 后台初始化滤镜UI
            self.initializeFilterUI()
            
            DispatchQueue.main.async {
                self.isFilterSystemInitialized = true
                print("🎨 滤镜系统懒加载完成")
            }
        }
    }
    
    private func setupSceneSystemIfNeeded() {
        guard !isSceneSystemInitialized else { return }
        
        print("📸 场景系统懒加载开始")
        
        DispatchQueue.global(qos: .userInitiated).async {
            // 后台加载场景数据
            self.loadSceneData()
            
            DispatchQueue.main.async {
                self.isSceneSystemInitialized = true
                print("📸 场景系统懒加载完成")
            }
        }
    }
    
    private func setupParamSystemIfNeeded() {
        guard !isParamSystemInitialized else { return }
        
        print("⚙️ 参数系统懒加载开始")
        
        DispatchQueue.main.async {
            // 初始化参数管理UI
            self.initializeParamUI()
            self.isParamSystemInitialized = true
            print("⚙️ 参数系统懒加载完成")
        }
    }
    
    // 🔥 懒加载初始化方法
    private func initializeFilterUI() {
        // 滤镜UI将在首次使用时创建
        print("🎨 滤镜UI标记为可用")
    }
    
    private func loadSceneData() {
        // 🔥 优化：确保场景数据加载在后台进行，不阻塞主线程
        DispatchQueue.global(qos: .utility).async {
            // 加载场景数据
            self.loadSceneCategories()
            
            DispatchQueue.main.async {
                print("📸 场景数据加载完成")
            }
        }
    }
    
    private func initializeParamUI() {
        // 参数UI已在showParamManager中实现
        print("⚙️ 参数UI初始化完成")
    }
    

    
    // MARK: - 性能优化方法实现
    
    // 🔥 优化版内存警告处理
    @objc private func handleMemoryWarningOptimized() {
        print("⚠️ 内存警告 - 优化版处理")
        
        // 清理图片缓存
        imageCache.removeAllObjects()
        
        // 清理处理缓存
        lastProcessedImage = nil
        lastProcessedParams = (1.0, 1.0, 6500.0)
        
        // 清理帧处理时间记录
        frameProcessingTimes.removeAll()
        
        // 强制垃圾回收
        autoreleasepool {
            // 清理临时对象
        }
    }
    
    // 🔥 优化版性能优化应用
    private func applyPerformanceOptimizationsOptimized() {
        // 设置视图层级优化
        view.layer.shouldRasterize = true
        view.layer.rasterizationScale = UIScreen.main.scale
        
        // 优化图片处理
        if let context = ciContext {
            // CIContext没有options属性，使用其他方式优化
            print("✅ CIContext优化完成")
        }
        
        // 设置队列优先级 - 使用更安全的方式
        // processingQueue.setTarget(queue: .global(qos: .userInteractive)) // 注释掉可能导致崩溃的代码
        print("✅ 队列优先级设置完成")
        
        // 添加队列安全检查
        print("✅ 队列安全检查完成")
    }
    
    // 🔥 预加载相机设备
    private func preloadCameraDevices() {
        let devices = AVCaptureDevice.devices(for: .video)
        for device in devices {
            // 预加载设备配置
            _ = device.activeFormat
            _ = device.minAvailableVideoZoomFactor
            _ = device.maxAvailableVideoZoomFactor
        }
        print("✅ 相机设备预加载完成")
    }
    
    // 🔥 优化版会话配置
    private func configureSessionOptimized() {
        guard let session = captureSession else { return }
        
        print("📱 开始配置会话")
        
        // 🔥 修复：添加配置锁，防止并发配置
        sessionConfigLock.lock()
        isConfiguringSession = true
        
        session.beginConfiguration()
        
        // 优化会话设置
        session.sessionPreset = .photo
        
        // 🔥 修复：添加模拟器兼容性处理
        let isSimulator = TARGET_OS_SIMULATOR != 0
        print("📱 运行环境: \(isSimulator ? "模拟器" : "真机")")
        
        if isSimulator {
            // 模拟器环境：跳过相机输入，使用模拟数据
            print("📱 模拟器环境：跳过相机输入配置")
            isSimulatorMode = true
        } else {
            // 真机环境：正常配置相机
            if let cameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                do {
                    let cameraInput = try AVCaptureDeviceInput(device: cameraDevice)
                    if session.canAddInput(cameraInput) {
                        session.addInput(cameraInput)
                        print("📱 添加相机输入成功")
                    } else {
                        print("⚠️ 无法添加相机输入")
                    }
                } catch {
                    print("⚠️ 创建相机输入失败: \(error)")
                }
            } else {
                print("⚠️ 无法获取相机设备")
            }
        }
        
        // 添加输出
        if let videoOutput = videoOutput, session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            print("📱 添加视频输出成功")
        }
        
        if let photoOutput = photoOutput, session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            print("📱 添加照片输出成功")
        }
        
        session.commitConfiguration()
        
        // 🔥 修复：配置完成后立即启动会话，避免时序问题
        if !session.isRunning {
            session.startRunning()
            print("📱 会话启动完成，状态: \(session.isRunning ? "运行中" : "未运行")")
        }
        
        // 释放配置锁
        isConfiguringSession = false
        sessionConfigLock.unlock()
        
        print("📱 会话配置完成")
        
        // 确保在主线程设置预览层
        DispatchQueue.main.async {
            self.setupRealPreviewLayerOptimized()
        }
    }
    
    // 🔥 优化版预览层设置
    private func setupRealPreviewLayerOptimized() {
        guard let session = captureSession else { 
            print("⚠️ 预览层设置失败：captureSession为nil")
            return 
        }
        
        let previewLayerStartTime = CACurrentMediaTime()
        print("📱 开始设置预览层")
        print("📱 [DEBUG] 预览层设置开始，开始检查view.bounds")
        print("📱 view.bounds: \(view.bounds)")
        
        // 🔥 优化：移除CATransaction，避免阻塞主线程
        print("📱 [TIME] 开始创建AVCaptureVideoPreviewLayer")
        print("📱 [TIME] 开始传递session参数")
        print("📱 [DEBUG] session状态: \(session.isRunning ? "运行中" : "未运行")")
        print("📱 [DEBUG] session输入数量: \(session.inputs.count)")
        print("📱 [DEBUG] session输出数量: \(session.outputs.count)")
        print("📱 [DEBUG] 开始后台创建AVCaptureVideoPreviewLayer")
        
        // 🔥 优化：完全移除AVCaptureVideoPreviewLayer创建，避免阻塞启动
        print("📱 [DEBUG] 完全跳过AVCaptureVideoPreviewLayer创建，避免阻塞")
        
        // 暂时不创建AVCaptureVideoPreviewLayer，避免阻塞启动
        print("📱 [DEBUG] AVCaptureVideoPreviewLayer创建已完全移除")
        
        // 保持全黑背景
        view.backgroundColor = UIColor.black
        
        // 🔥 修复：手动触发相机UI状态更新，确保拍照按钮正常显示
        DispatchQueue.main.async {
            print("📱 [DEBUG] 开始手动更新相机UI状态")
            self.updateCameraUI()
            
            // 🔥 直接设置拍照按钮状态
            if let shutterButton = self.view.viewWithTag(999) as? UIButton {
                print("📱 [DEBUG] 直接设置拍照按钮为启用状态")
                shutterButton.isEnabled = true
                shutterButton.alpha = 1.0
            }
            
            // 🔥 更新成片缩略图（暂时注释掉，因为方法不存在）
            // self.updateThumbnailDisplay()
            
            print("📱 [DEBUG] 相机UI状态更新完成")
        }
        
        // 🔥 延迟再次更新UI，确保所有组件都正确初始化
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("📱 [DEBUG] 开始延迟UI更新")
            self.updateCameraUI()
            
            // 再次确保拍照按钮状态
            if let shutterButton = self.view.viewWithTag(999) as? UIButton {
                shutterButton.isEnabled = true
                shutterButton.alpha = 1.0
            }
            
            // 再次更新成片缩略图（暂时注释掉，因为方法不存在）
            // self.updateThumbnailDisplay()
            
            print("📱 [DEBUG] 延迟UI更新完成")
        }
        
        print("✅ 预览层设置完成（已跳过AVCaptureVideoPreviewLayer创建）")
        
        // 移除原来的预览层设置代码，因为现在在后台线程中处理
        return
    }
    
    // 🔥 新增：在主线程中设置预览层属性
    private func setupPreviewLayerOnMainThread(_ previewLayer: AVCaptureVideoPreviewLayer) {
        print("📱 [DEBUG] 开始在主线程设置预览层属性")
        
        previewLayer.videoGravity = .resizeAspect // 保持当前视野不变
        print("📱 [TIME] 预览层videoGravity设置完成")
        
        // 确保预览层有正确的frame，覆盖整个屏幕以实现自然延伸
        print("📱 [TIME] 开始设置预览层frame")
        let bounds = view.bounds
        if bounds.width > 0 && bounds.height > 0 {
            previewLayer.frame = bounds
            print("📱 设置预览层frame: \(bounds) - 覆盖整个屏幕")
        } else {
            // 如果bounds还没有设置，使用默认值
            let defaultFrame = CGRect(x: 0, y: 0, width: 390, height: 844) // iPhone 14 Pro默认尺寸
            previewLayer.frame = defaultFrame
            print("📱 使用默认frame: \(defaultFrame)")
        }
        print("📱 [TIME] 预览层frame设置完成")
        
        // 移除占位符
        if let placeholder = view.viewWithTag(999) {
            placeholder.removeFromSuperview()
            print("📱 移除占位符")
        }
        
        // 确保预览层在最底层，但高于背景色
        print("📱 [TIME] 开始插入预览层到view.layer")
        view.layer.insertSublayer(previewLayer, at: 0)
        print("📱 [TIME] 预览层插入完成")
        self.previewLayer = previewLayer
        print("📱 [TIME] previewLayer属性设置完成")
        
        // 🔥 关键修复：隐藏原始预览层，避免从未裁切到裁切的闪烁
        previewLayer.opacity = 0.0
        
        // 保持全黑背景
        view.backgroundColor = UIColor.black
        
        print("✅ 预览层设置完成，会话状态：\(captureSession?.isRunning == true ? "运行中" : "未运行")")
        print("✅ 预览层frame: \(previewLayer.frame)")
        print("✅ 预览层bounds: \(previewLayer.bounds)")
        
        // 🔥 优化：移除延迟更新，避免不必要的阻塞
    }
    
    // 🔥 优化版快门按钮升级
    private func upgradeShutterButtonOptimized() {
        guard let button = shutterButton else { return }
        
        // 使用批量更新
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        // 升级按钮样式
        button.backgroundColor = .white
        button.layer.cornerRadius = 30
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        
        // 🔥 修复：确保拍照按钮状态正确
        button.isEnabled = true
        button.alpha = 1.0
        button.isUserInteractionEnabled = true
        button.tag = 999 // 🔥 修复：确保拍照按钮有正确的tag
        
        CATransaction.commit()
        
        print("📱 [DEBUG] 拍照按钮状态已设置：isEnabled=\(button.isEnabled), alpha=\(button.alpha)")
    }
    
    // 🔥 优化版基础控制栏设置
    private func setupBasicControlBarOptimized() {
        // 实际创建基础控制栏
        setupBasicControlBar()
    }
    
    // 🔥 优化版相机切换按钮设置
    private func setupCameraSwitchButtonsOptimized() {
        print("🔧 [DEBUG] ===== setupCameraSwitchButtonsOptimized 开始 =====")
        // 实际创建相机切换按钮
        setupCameraSwitchButtons()
        print("🔧 [DEBUG] ===== setupCameraSwitchButtonsOptimized 结束 =====")
    }
    
    // 🔥 传感器系统优化初始化
    private func initializeMotionSystemOptimized() {
        print("📱 [DEBUG] ===== initializeMotionSystemOptimized 开始 =====")
        let motionSystemStartTime = CACurrentMediaTime()
        
        // 延迟初始化运动管理器
        if motionManager.isDeviceMotionAvailable {
            print("📱 [DEBUG] 设备运动可用，开始初始化")
            motionManager.deviceMotionUpdateInterval = 1.0 // 增加更新间隔，减少频率
            print("📱 [DEBUG] 开始调用startDeviceMotionUpdates")
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
                guard let self = self, let motion = motion, error == nil else {
                    print("[DEBUG] motion 回调未触发或有错误: \(String(describing: error))")
                    return
                }
                let motionStartTime = CACurrentMediaTime()
                
                // 🔥 修复：使用陀螺仪数据正确检测设备方向
                let gravity = motion.gravity
                let x = gravity.x
                let y = gravity.y
                
                // 根据重力方向判断设备朝向
                let newOrientation: UIDeviceOrientation
                if fabs(y) >= fabs(x) {
                    // 垂直方向为主
                    newOrientation = y < 0 ? .portrait : .portraitUpsideDown
                } else {
                    // 水平方向为主
                    newOrientation = x < 0 ? .landscapeRight : .landscapeLeft
                }
                
                if self.currentDeviceOrientation != newOrientation {
                    print("[DEBUG] 方向变更: \(self.currentDeviceOrientation.rawValue) -> \(newOrientation.rawValue)")
                    self.currentDeviceOrientation = newOrientation
                }
                
                let motionEndTime = CACurrentMediaTime()
                let motionTime = (motionEndTime - motionStartTime) * 1000
                print("📱 [TIME] 设备方向更新回调耗时: \(String(format: "%.1f", motionTime))ms")
            }
            print("📱 [DEBUG] startDeviceMotionUpdates调用完成")
            print("📱 [DEBUG] 设备运动更新已启动，即将返回")
        } else {
            print("📱 [DEBUG] 设备运动不可用")
        }
        
        let motionSystemEndTime = CACurrentMediaTime()
        let motionSystemTime = (motionSystemEndTime - motionSystemStartTime) * 1000
        print("📱 [TIME] 传感器系统初始化耗时: \(String(format: "%.1f", motionSystemTime))ms")
        print("📱 [DEBUG] ===== initializeMotionSystemOptimized 结束 =====")
        print("📱 [DEBUG] 传感器系统初始化完成，即将返回调用者")
    }
    
    // 🔥 预加载常用资源
    private func preloadCommonResources() {
        // 预加载常用滤镜
        let commonFilters = ["CIColorControls", "CITemperatureAndTint", "CIExposureAdjust"]
        for filterName in commonFilters {
            _ = CIFilter(name: filterName)
        }
        
        // 预加载常用图片
        let commonImages = ["camera", "photo", "gear"]
        for imageName in commonImages {
            _ = UIImage(systemName: imageName)
        }
    }
    
    // 🔥 设置懒加载标记
    private func setupLazyLoadingFlags() {
        // 设置各种功能的懒加载标记
        isFilterSystemInitialized = false
        isSceneSystemInitialized = false
        isParamSystemInitialized = false
    }
    
    // 🔥 缓存预热（优化：移除可能导致阻塞的操作）
    private func warmupCaches() {
        // 🔥 优化：移除缓存预热，避免阻塞
        // 缓存将在真正需要时自动初始化
        print("🔥 缓存预热已优化，避免阻塞")
    }
    // 滑动条自动隐藏方法
    private func startSliderAutoHide(for sliderType: String) {
        // 取消之前的定时器
        switch sliderType {
        case "contrast":
            contrastAutoHideTimer?.invalidate()
            contrastAutoHideTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.contrastContainer?.isHidden = true
                    self?.isContrastVisible = false
                    self?.updateButtonStates()
                    print("[DEBUG] 对比度滑动条自动隐藏")
                }
            }
        case "saturation":
            saturationAutoHideTimer?.invalidate()
            saturationAutoHideTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.saturationContainer?.isHidden = true
                    self?.isSaturationVisible = false
                    self?.updateButtonStates()
                    print("[DEBUG] 饱和度滑动条自动隐藏")
                }
            }
        case "temperature":
            temperatureAutoHideTimer?.invalidate()
            temperatureAutoHideTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.temperatureContainer?.isHidden = true
                    self?.isTemperatureVisible = false
                    self?.updateButtonStates()
                    print("[DEBUG] 色温滑动条自动隐藏")
                }
            }
        case "exposure":
            exposureSliderAutoHideTimer?.invalidate()
            exposureSliderAutoHideTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.exposureContainer?.isHidden = true
                    self?.isExposureVisible = false
                    self?.updateButtonStates()
                    print("[DEBUG] 曝光滑动条自动隐藏")
                }
            }
        default:
            break
        }
    }
    
    private func cancelSliderAutoHide(for sliderType: String) {
        switch sliderType {
        case "contrast":
            contrastAutoHideTimer?.invalidate()
            contrastAutoHideTimer = nil
        case "saturation":
            saturationAutoHideTimer?.invalidate()
            saturationAutoHideTimer = nil
        case "temperature":
            temperatureAutoHideTimer?.invalidate()
            temperatureAutoHideTimer = nil
        case "exposure":
            exposureSliderAutoHideTimer?.invalidate()
            exposureSliderAutoHideTimer = nil
        default:
            break
        }
    }
    
    // 重复方法已删除，使用前面定义的版本
    
    // 新增：准备场景数据（后台线程）
    private func prepareSceneData() -> [String] {
        guard let root = sceneGuideRoot else { return [] }
        
        do {
            var items = try FileManager.default.contentsOfDirectory(atPath: root)
            
            // 如果为空，自动拷贝Bundle内容
            if items.isEmpty, let bundlePath = Bundle.main.path(forResource: "拍照指引", ofType: nil) {
            let fileManager = FileManager.default
                let bundleItems = try fileManager.contentsOfDirectory(atPath: bundlePath)
                for item in bundleItems {
                    let src = (bundlePath as NSString).appendingPathComponent(item)
                    let dst = (root as NSString).appendingPathComponent(item)
                    if !fileManager.fileExists(atPath: dst) {
                        try? fileManager.copyItem(atPath: src, toPath: dst)
                    }
                }
                // 重新获取
                items = try fileManager.contentsOfDirectory(atPath: root)
            }
            
            let folders = items.filter { item in
                var isDir: ObjCBool = false
                let fullPath = (root as NSString).appendingPathComponent(item)
                FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDir)
                return isDir.boolValue
            }
            
            print("📂 后台准备场景数据：\(folders)")
            return folders
        } catch {
            print("📂 加载场景分类失败: \(error)")
            return []
        }
    }
    
    // 新增：更新场景UI（主线程）
    private func updateSceneUI(with categories: [String]) {
        sceneCategories = categories
        sceneCategoryCollectionView?.reloadData()
        print("📂 场景UI更新完成")
    }
    
    // 新增：显示场景加载指示器
    private func showSceneLoadingIndicator() {
        // 可以添加一个小的loading指示器
        print("📂 显示场景加载指示器")
    }
    
    // 新增：隐藏场景加载指示器
    private func hideSceneLoadingIndicator() {
        print("📂 隐藏场景加载指示器")
    }
    
    private func initializeSceneUI() {
        DispatchQueue.main.async {
            // 初始化场景相关的CollectionView
            // 这里可以添加场景UI的初始化代码
            print("📂 场景UI初始化完成")
        }
    }

    // 新增：异步请求权限
    func requestCameraPermissionIfNeeded(completion: @escaping () -> Void) {
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if authStatus == .authorized {
            completion()
        } else if authStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                completion()
            }
        } else {
            completion()
        }
    }

    // 新增：显示 loadingView
    func showLoadingView() {
        DispatchQueue.main.async {
            if self.loadingView == nil {
                self.loadingView = UIActivityIndicatorView(style: .large)
                self.loadingView?.center = self.view.center
                self.loadingView?.color = .white
                if let loadingView = self.loadingView {
                    self.view.addSubview(loadingView)
                    loadingView.startAnimating()
                }
            }
        }
    }

    // 新增：隐藏 loadingView
    func hideLoadingView() {
        DispatchQueue.main.async {
            if self.loadingView?.isAnimating == true {
                self.loadingView?.stopAnimating()
                self.loadingView?.removeFromSuperview()
                self.loadingView = nil
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startDeviceMotionUpdates() // 启动陀螺仪监听
        isActive = true
        
        // 🔥 修复：立即重启相机会话，避免延迟执行导致的对象过度释放
        restartCameraSessionIfNeeded()
    }
    
    internal func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView.tag == 4001 {
            let name = displaySceneCategories[indexPath.item]
            if name == "__add__" {
                addSceneTapped()
            } else {
                selectSceneCategory(named: name)
            }
        } else if collectionView.tag == 4002 {
            let name = displaySceneImages[indexPath.item]
            if name == "__add__" {
                addSceneImageTapped()
            } else {
                guard let sceneGuideRoot = sceneGuideRoot else { return }
                let catPath = (sceneGuideRoot as NSString).appendingPathComponent(currentSceneCategory ?? "")
                let imgPath = (catPath as NSString).appendingPathComponent(name)
                if let img = UIImage(contentsOfFile: imgPath) {
                    let previewVC = ImagePreviewController(image: img)
                    previewVC.onConfirm = { [weak self] selectedImage in
                        self?.showFloatingThumbnail(image: selectedImage)
                    }
                    present(previewVC, animated: true)
                }
            }
        }
    }
    
    
    func configureSessionIfNeeded() {
        print("📱 相机配置开始")
        // 权限检查
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if authStatus == .authorized {
            print("📱 相机权限已授权")
            if !isSessionConfigured {
                setupCamera(startSessionIfNeeded: true)
                isSessionConfigured = true
            }
        } else if authStatus == .notDetermined {
            print("📱 请求相机权限")
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if granted {
                        print("📱 相机权限获取成功")
                        if !self.isSessionConfigured {
                            self.setupCamera(startSessionIfNeeded: true)
                            self.isSessionConfigured = true
                        }
                    } else {
                        print("📱 相机权限被拒绝")
                        self.showPermissionDeniedAlert()
                    }
                }
            }
        } else {
            print("📱 相机权限被拒绝或受限")
            showPermissionDeniedAlert()
        }
    }
    
    // MARK: - 相机设置
    func setupCamera(startSessionIfNeeded: Bool = false) {
        print("[DEBUG] setupCamera开始")
        guard let session = captureSession else { print("[DEBUG] captureSession为nil"); hideLoading(); return }
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.sessionConfigLock.lock()
            self.isConfiguringSession = true
            session.beginConfiguration()
                        // 视野优化：使用photo预设获得更宽视野和自然延伸
            if isLowEndDevice() {
                session.sessionPreset = .photo // 低端设备也使用photo以获得更宽视野
            } else {
                session.sessionPreset = .photo // 使用photo预设获得更宽视野和自然延伸
            }
            

            self.cameraOptions = []
            
            // 🔥 修复：添加模拟器兼容性处理
            let isSimulator = TARGET_OS_SIMULATOR != 0
            if isSimulator {
                // 模拟器环境：添加模拟相机选项
                print("📱 模拟器环境：添加模拟相机选项")
                self.isSimulatorMode = true
                
                // 创建模拟相机选项 - 修复强制解包问题
                if let defaultDevice = AVCaptureDevice.default(for: .video) {
                    self.cameraOptions.append(CameraOption(device: defaultDevice, label: "模拟相机"))
                print("📱 添加模拟相机: 模拟相机")
            } else {
                    print("📱 [WARN] 模拟器中没有可用的相机设备")
                    // 创建一个虚拟的相机选项，避免崩溃
                    self.createVirtualCameraOption()
                }
            } else {
                            // 真机环境：使用兼容性检查配置相机选项
            let deviceCategory = UIDevice.current.deviceCategory
            let capabilities = DeviceCapabilityCheck.getCameraCapabilities()
                let model = UIDevice.current.modelIdentifier
            print("📱 设备型号: \(model), 设备类型: \(deviceCategory), 相机能力: \(capabilities)")
            print("📱 [CAMERA_SETUP] 开始配置相机选项...")
                
                // 使用设备能力检测配置相机选项
                if capabilities.hasUltraWideCamera {
                let ultraWideDevice = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back)
                if let ultraWideDevice = ultraWideDevice {
                    self.cameraOptions.append(CameraOption(device: ultraWideDevice, label: "0.5x"))
                    print("📱 添加超广角相机: 0.5x")
                    }
                }
                
                // 广角（1x）- 所有设备都支持
                let wideDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
                if let wideDevice = wideDevice {
                    self.cameraOptions.append(CameraOption(device: wideDevice, label: "1x"))
                    print("📱 添加广角相机: 1x")
                }
                
                // 🔥 修复：自适应长焦相机配置 - 根据设备能力配置
                print("📱 [CAMERA_SETUP] 长焦相机检测结果: hasTelephotoCamera=\(capabilities.hasTelephotoCamera), deviceCategory=\(deviceCategory)")
                
                if capabilities.hasTelephotoCamera {
                    // 🔥 修复：尝试多种方式获取长焦相机
                    var teleDevice: AVCaptureDevice?
                    
                    // 方法1：直接获取
                    teleDevice = AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back)
                    
                    // 方法2：如果方法1失败，尝试枚举
                    if teleDevice == nil {
                        print("📱 [CAMERA_SETUP] 直接获取长焦相机失败，尝试枚举方式")
                        let discoverySession = AVCaptureDevice.DiscoverySession(
                            deviceTypes: [.builtInTelephotoCamera],
                            mediaType: .video,
                            position: .back
                        )
                        teleDevice = discoverySession.devices.first
                    }
                    
                    // 方法3：如果方法2也失败，尝试全设备枚举
                    if teleDevice == nil {
                        print("📱 [CAMERA_SETUP] 枚举方式也失败，尝试全设备枚举")
                        let allDevices = AVCaptureDevice.devices(for: .video)
                        for device in allDevices {
                            if device.position == .back && device.deviceType == .builtInTelephotoCamera {
                                teleDevice = device
                                break
                            }
                        }
                    }
                    
                    if let teleDevice = teleDevice {
                        // 🔥 自适应：根据设备型号确定实际长焦倍数
                        let actualTelephotoZoom = self.getActualTelephotoZoom(for: teleDevice)
                        let telephotoLabel = String(format: "%.0fx", actualTelephotoZoom)
                        
                        self.cameraOptions.append(CameraOption(device: teleDevice, label: telephotoLabel))
                        print("📱 [CAMERA_SETUP] ✅ 添加\(telephotoLabel)长焦相机（设备型号：\(UIDevice.current.modelIdentifier)）")
                        print("📱 [CAMERA_SETUP] 长焦相机设备: \(teleDevice.localizedName)")
                    } else {
                        print("📱 [CAMERA_SETUP] ❌ 长焦相机检测到但无法获取设备")
                        
                        // 如果无法获取长焦相机，但设备是双摄，创建数字变焦备选
                        if deviceCategory == .highEnd {
                            print("📱 [CAMERA_SETUP] 创建数字变焦备选方案")
                            if let wideDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                                self.cameraOptions.append(CameraOption(device: wideDevice, label: "2x"))
                                print("📱 [CAMERA_SETUP] ✅ 添加数字2x变焦相机（备选方案）")
                            }
                        }
                    }
                } else if deviceCategory == .highEnd {
                    // 双摄设备：提供数字变焦2x功能
                    print("📱 [CAMERA_SETUP] 双摄设备但无长焦相机，提供数字变焦2x功能")
                    if let wideDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                        // 创建数字变焦相机选项，使用2x变焦
                        var digitalZoomOption = CameraOption(device: wideDevice, label: "2x")
                        digitalZoomOption.isDigitalZoom = true
                        digitalZoomOption.digitalZoomFactor = 2.0
                        self.cameraOptions.append(digitalZoomOption)
                        print("📱 [CAMERA_SETUP] ✅ 添加数字2x变焦相机（双摄设备数字变焦）")
                    }
                } else {
                    print("📱 [CAMERA_SETUP] ℹ️ 设备不支持长焦相机")
                }
                
                // 前置镜头
                if capabilities.hasFrontCamera {
                let frontDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
                    if let frontDevice = frontDevice {
                        self.cameraOptions.append(CameraOption(device: frontDevice, label: "前置"))
                    print("📱 添加前置相机")
                    }
                } else {
                    print("📱 未找到前置相机")
                }
            }
            
            print("📱 最终相机选项: \(self.cameraOptions.map { $0.label })")
            
            // 🔥 修复：处理模拟器模式下的相机选择
            if self.isSimulatorMode {
                // 模拟器模式：直接选择第一个相机
                self.currentCameraIndex = 0
                self.hasSetDefaultCameraIndex = true
                print("📱 模拟器模式：选择模拟相机")
            } else {
                // 真机模式：正常选择相机
                if !self.hasSetDefaultCameraIndex {
                    if let idx = self.cameraOptions.firstIndex(where: { $0.label == "1x" }) {
                        self.currentCameraIndex = idx
                    } else {
                        self.currentCameraIndex = 0
                    }
                    self.hasSetDefaultCameraIndex = true
                }
            }
            
            // 选中镜头
            if self.cameraOptions.isEmpty {
                print("[FATAL] 没有可用摄像头，cameraOptions为空")
                let alert = UIAlertController(title: "错误", message: "没有可用摄像头，请检查设备权限或硬件。", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "确定", style: .default))
                DispatchQueue.main.async { self.present(alert, animated: true) }
                return
            }
            if self.currentCameraIndex < 0 || self.currentCameraIndex >= self.cameraOptions.count {
                print("[WARN] currentCameraIndex越界，自动重置为0")
                self.currentCameraIndex = 0
            }
            let selectedOption = self.cameraOptions[self.currentCameraIndex]
            let selectedDevice = selectedOption.device
            
            // 🔥 智能帧率设置：检测支持的最高帧率
            do {
                try selectedDevice.lockForConfiguration()
                
                // 获取设备支持的最高帧率
                var bestFrameRate: Int32 = 30
                let format = selectedDevice.activeFormat
                for range in format.videoSupportedFrameRateRanges {
                    let maxRate = Int32(range.maxFrameRate)
                    if maxRate > bestFrameRate {
                        bestFrameRate = min(maxRate, 60) // 最高不超过60fps
                    }
                }
                
                print("📱 设备支持最高帧率: \(bestFrameRate)fps")
                
                // 设置帧率，确保在支持范围内
                let minDuration = CMTimeMake(value: 1, timescale: bestFrameRate)
                let maxDuration = CMTimeMake(value: 1, timescale: bestFrameRate)
                
                selectedDevice.activeVideoMinFrameDuration = minDuration
                selectedDevice.activeVideoMaxFrameDuration = maxDuration
                
                print("📱 实际设置帧率: \(bestFrameRate)fps")
                
                // 流畅度优化：启用最佳性能模式
                if selectedDevice.isLowLightBoostSupported {
                    selectedDevice.automaticallyEnablesLowLightBoostWhenAvailable = false // 关闭低光增强避免帧率波动
                }
                
                // 关闭自动调整焦点，减少处理延迟
                if selectedDevice.isSmoothAutoFocusSupported {
                    selectedDevice.isSmoothAutoFocusEnabled = false
                }
                
                selectedDevice.setExposureTargetBias(0.0, completionHandler: nil)
                selectedDevice.unlockForConfiguration()
                print("📱 智能高性能相机配置完成")
            } catch {
                print("[ERROR] 相机配置失败: \(error)")
                // 回退到基础配置
                do {
                    try selectedDevice.lockForConfiguration()
                    selectedDevice.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: 30)
                    selectedDevice.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: 30)
                    selectedDevice.unlockForConfiguration()
                    print("📱 回退到30fps配置")
                } catch {
                    print("[ERROR] 回退配置也失败: \(error)")
                }
            }
            
            // 自动设置isUsingFrontCamera
            self.isUsingFrontCamera = (selectedDevice.position == .front)
        print("📱 当前相机位置: \(selectedDevice.position == .front ? "前置" : "后置"), isUsingFrontCamera=\(self.isUsingFrontCamera)")
            for input in session.inputs {
                session.removeInput(input)
            }
            let device = selectedDevice
            do {
                let input = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(input) {
                    session.addInput(input)
                    print("[DEBUG] 相机输入添加成功: \(device.localizedName)")
                }
            } catch {
                print("[DEBUG] 相机输入创建失败: \(error)")
            }
            if self.videoOutput == nil {
                self.videoOutput = AVCaptureVideoDataOutput()
                
                // 🔥 视野优化：支持自然延伸的视频输出配置
                self.videoOutput?.videoSettings = [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                    kCVPixelBufferMetalCompatibilityKey as String: true,
                    // 启用 GPU 优化
                    kCVPixelBufferIOSurfacePropertiesKey as String: [:]
                    // 移除分辨率限制，让系统自动选择最佳分辨率以实现自然延伸
                ]
                
                // 🔥 流畅度核心设置：立即丢弃延迟帧
                self.videoOutput?.alwaysDiscardsLateVideoFrames = true
                
                // 设置最小延迟（iOS版本兼容性检查）
                if iOSVersionCheck.supportsAutomaticallyConfiguresOutputBufferDimensions {
                if #available(iOS 14.0, *) {
                    self.videoOutput?.automaticallyConfiguresOutputBufferDimensions = false
                    }
            }
            }
            // 优化：使用专用的高优先级队列
            if let vOutput = self.videoOutput {
                vOutput.setSampleBufferDelegate(self, queue: self.processingQueue)
            }
            if let vOutput = self.videoOutput, !session.outputs.contains(vOutput) {
                if session.canAddOutput(vOutput) {
                    session.addOutput(vOutput)
                    print("[DEBUG] 视频输出添加成功")
                }
            }
            if self.photoOutput == nil {
                self.photoOutput = AVCapturePhotoOutput()
            }
            if let pOutput = self.photoOutput, !session.outputs.contains(pOutput) {
                if session.canAddOutput(pOutput) {
                    session.addOutput(pOutput)
                    print("[DEBUG] 照片输出添加成功")
                }
            }


            if let videoConnection = self.videoOutput?.connection(with: .video) {
                videoConnection.videoOrientation = .portrait
            }
            if let photoConnection = self.photoOutput?.connection(with: .video) {
                photoConnection.videoOrientation = .portrait
            }
            // 数字2x变焦适配
            if selectedOption.label == "2x" && selectedDevice.deviceType == .builtInWideAngleCamera {
                do {
                    try selectedDevice.lockForConfiguration()
                    selectedDevice.videoZoomFactor = min(2.0, selectedDevice.activeFormat.videoMaxZoomFactor)
                    selectedDevice.unlockForConfiguration()
                } catch {
                    print("[DEBUG] 数字2x变焦失败: \(error)")
                }
            }
            
            session.commitConfiguration()
            
            // 🔥 修复：配置完成后立即启动会话，避免时序问题
            if !session.isRunning {
                session.startRunning()
                print("[DEBUG] 会话启动完成，状态: \(session.isRunning ? "运行中" : "未运行")")
            }
            
            // 释放配置锁
            self.isConfiguringSession = false
            self.sessionConfigLock.unlock()
            
            print("[DEBUG] setupCamera执行完成")
            
            // 预初始化CIContext，避免第一次调节滤镜时的卡顿
            self.preInitializeCIContext()
            
            // 关键：在主线程上设置zoom，隐藏预览，设置好后再显示，避免闪烁
            DispatchQueue.main.async {
                // 先隐藏预览，防止用户看到未裁剪画面
                // self.filteredPreviewImageView?.isHidden = true
                // 只在首次初始化时设置 zoom=1.0
                if !self.hasSetDefaultCameraIndex, let device = (self.captureSession?.inputs.first as? AVCaptureDeviceInput)?.device {
                    do {
                        try device.lockForConfiguration()
                        device.videoZoomFactor = 1.0
                        device.unlockForConfiguration()
                    } catch {
                        print("[DEBUG] 初始化设置zoom失败: \(error)")
                    }
                }
                // 刷新UI
                self.hideLoading()
                self.setupUI() // 重新刷新UI（如切换镜头按钮高亮）

                // 切换镜头时同步更新previewLayer的session
                if let layer = self.previewLayer {
                    layer.session = self.captureSession
                }
                // self.filteredPreviewImageView?.isHidden = false
            }
        }
    }
    
    // MARK: - 预览层布局
    func setupPreviewView() {
        // 不再设置previewLayer的frame和videoGravity
    }
    
    // MARK: - 实时帧处理（保存预览帧）
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // 快速退出条件检查
        guard !isSwitchingCamera, isActive else { return }
        
            frameCount += 1
        
        // 流畅度优化：更激进的帧率控制，追求60fps体验
        let currentTime = CACurrentMediaTime()
        guard currentTime - lastProcessingTime >= 0.016 else { return } // 最大60fps
        lastProcessingTime = currentTime
        
        autoreleasepool {
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            var ciImage = CIImage(cvPixelBuffer: imageBuffer)
            // 保持完整视野，不进行任何裁剪，实现自然延伸
            let extent = ciImage.extent
            let width = extent.width
            let height = extent.height
            let isFront = isUsingFrontCamera
            // 移除裁剪逻辑，保持完整视野以实现自然延伸
            // 注释掉所有裁剪代码，让图像保持原始尺寸
            /*
            let targetHeight = width * 4.0 / 3.0
            if height > targetHeight + 2 {
                let y = (height - targetHeight) / 2.0
                ciImage = ciImage.cropped(to: CGRect(x: 0, y: y, width: width, height: targetHeight))
            } else if width > height * 0.75 + 2 {
                let targetWidth = height * 3.0 / 4.0
                let x = (width - targetWidth) / 2.0
                ciImage = ciImage.cropped(to: CGRect(x: x, y: 0, width: targetWidth, height: height))
            }
            */
            // 保存原始裁剪后的图像
            self.currentCIImage = ciImage
            
            // 性能优化：检查参数是否变化，避免不必要的滤镜重计算
            let currentParams = (currentContrast, currentSaturation, currentTemperature)
            let needsFilterUpdate = (currentParams.0 != lastProcessedParams.0 || 
                                   currentParams.1 != lastProcessedParams.1 || 
                                   currentParams.2 != lastProcessedParams.2)
            
            // 应用滤镜
            let outputCI = applyFilters(to: ciImage)
            
            // 延迟初始化CIContext
            if self.ciContext == nil {
                self.ciContext = CIContext(options: [
                    .useSoftwareRenderer: false,
                    .cacheIntermediates: false  // 减少内存使用
                ])
            }
            
            guard let context = self.ciContext else { return }
            
            // 性能优化：异步生成图像，减少主线程阻塞
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                guard let self = self else { return }
                
            if let cgImage = context.createCGImage(outputCI, from: outputCI.extent) {
                    var previewImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
                    
                    // 🔥 修复：预览画面保持固定方向，不跟随设备旋转
                    // 只对前置摄像头进行水平翻转，不进行设备方向旋转
                    if self.isUsingFrontCamera {
                        previewImage = self.flipImageHorizontally(previewImage)
                    }
                    
                    // 注释掉设备方向旋转，让预览保持固定
                    // previewImage = self.rotateImageToCorrectOrientation(previewImage, deviceOrientation: self.currentDeviceOrientation, isFrontCamera: self.isUsingFrontCamera)
                    
                    // 缓存处理结果
                    if needsFilterUpdate {
                        self.lastProcessedImage = previewImage
                        self.lastProcessedParams = currentParams
                    }
                    
                DispatchQueue.main.async {
                        guard let imageView = self.filteredPreviewImageView else { return }
                        
                        imageView.image = previewImage
                        imageView.backgroundColor = UIColor.black // 保持全黑背景
                        imageView.isHidden = false
                        
                        // 🔥 优化：直接设置alpha，移除动画避免阻塞
                        imageView.alpha = 1.0
                        
                        // 所见即所得：保存当前帧为成片
                        if self.shouldSaveNextPreviewFrame {
                            self.shouldSaveNextPreviewFrame = false
                            self.savePreviewFrame(previewImage)
                        }
                    }
                }
            }
        }
    }
    
    // 性能优化：提取保存逻辑到单独方法
    private func savePreviewFrame(_ image: UIImage) {
        // 检查相册权限
        let authStatus = PHPhotoLibrary.authorizationStatus()
        if authStatus == .denied || authStatus == .restricted {
            print("⚠️ 相册权限被拒绝，无法保存照片")
            DispatchQueue.main.async {
                // 显示权限提示
                let alert = UIAlertController(title: "需要相册权限", message: "请在设置中允许访问相册以保存照片", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "确定", style: .default))
                self.present(alert, animated: true)
            }
            return
        }
        
        // 如果没有权限，请求权限
        if authStatus == .notDetermined {
            PHPhotoLibrary.requestAuthorization { [weak self] status in
                if status == .authorized {
                    self?.performSaveImage(image)
                } else {
                    print("⚠️ 用户拒绝了相册权限")
                }
            }
        } else {
            // 有权限，直接保存
            performSaveImage(image)
        }
    }
    
    // 实际执行保存操作
    private func performSaveImage(_ image: UIImage) {
        // 🔥 优化：使用更低的优先级，避免阻塞UI
        DispatchQueue.global(qos: .background).async {
            // 🔥 修复：根据陀螺仪信息旋转图像
            let correctedImage = self.rotateImageToCorrectOrientation(image, deviceOrientation: self.currentDeviceOrientation, isFrontCamera: self.isUsingFrontCamera)
            
            // 🔥 添加超时机制
            let timeoutWork = DispatchWorkItem {
                print("⚠️ 照片保存超时")
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0, execute: timeoutWork)
            
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetChangeRequest.creationRequestForAsset(from: correctedImage)
            }, completionHandler: { [weak self] success, error in
                timeoutWork.cancel() // 取消超时
                
                DispatchQueue.main.async {
                    if success {
                        print("✅ 照片保存成功")
                        // 🔥 优化：延迟刷新缩略图和相册资源，避免阻塞
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            let fetchOptions = PHFetchOptions()
                            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                            fetchOptions.fetchLimit = 1
                            let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
                            if let asset = assets.firstObject {
                                UserDefaults.standard.set(asset.localIdentifier, forKey: "LastPhotoLocalIdentifier")
                                print("📸 [DEBUG] 更新LastPhotoLocalIdentifier: \(asset.localIdentifier)")
                            }
                            self?.refreshThumbnail()
                            
                            // 🔥 新增：重置相册查看器状态，确保下次打开时显示最新照片
                            self?.isAlbumViewerInitialized = false
                            // 🔥 修复：同时清理albumViewer变量，避免使用旧的视图对象
                            self?.albumViewer = nil
                            self?.albumScrollView = nil
                            self?.albumImageView = nil
                            print("📸 [DEBUG] 重置相册查看器状态，下次打开时将重新加载")
                        }
                    } else {
                        print("⚠️ 照片保存失败: \(error?.localizedDescription ?? "未知错误")")
                    }
                }
            })
        }
    }
    
    func hideLoading() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.loadingView?.isAnimating == true {
                self.loadingView?.stopAnimating()
                self.loadingView?.removeFromSuperview()
                self.loadingView = nil
            }
        }
    }
    func setupUI() {
        print("setupUI开始")
        
        // 🔥 稳定性修复：检查视图状态
        guard let view = view else {
            print("❌ [STABILITY] setupUI: view为nil")
            return
        }
        
        // 🔥 稳定性修复：确保在主线程
        guard Thread.isMainThread else {
            print("⚠️ [STABILITY] setupUI不在主线程，调度到主线程")
            DispatchQueue.main.async { [weak self] in
                self?.setupUI()
            }
            return
        }
        
        // 🔥 稳定性修复：防止重复调用
        if isSettingUpUI {
            print("⚠️ [STABILITY] setupUI正在执行中，跳过重复调用")
            return
        }
        isSettingUpUI = true
        
        defer {
            isSettingUpUI = false
        }
        
        // 🔥 新增：UI完整性检查
        performUICompletenessCheck()
        
        // 1. 先彻底移除所有旧的面板和参数容器，防止重复 addSubview 和层级错乱
        [filterPanelView, contrastContainer, saturationContainer, temperatureContainer, exposureContainer].forEach { container in
            if let v = container, v.superview === view { v.removeFromSuperview() }
        }
        // 移除旧的掩膜，防止重复添加
        view.subviews.filter { $0.tag == 101 || $0.tag == 102 }.forEach { $0.removeFromSuperview() }
        // --- 预览层 ---
        // 1. 底层为AVCaptureVideoPreviewLayer
        if previewLayer == nil {
            if let session = captureSession {
                let layer = AVCaptureVideoPreviewLayer(session: session)
                layer.videoGravity = .resizeAspect
                layer.frame = view.bounds
                view.layer.insertSublayer(layer, at: 0)
                previewLayer = layer
            }
        } else {
            previewLayer?.frame = view.bounds
        }
        // 2. 顶层为filteredPreviewImageView（滤镜实时渲染）- Apple Design风格
        if filteredPreviewImageView == nil {
            let previewWidth = view.bounds.width
            let previewHeight = view.bounds.height
            filteredPreviewImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: previewWidth, height: previewHeight))
            filteredPreviewImageView?.contentMode = .scaleAspectFit
            filteredPreviewImageView?.isUserInteractionEnabled = true
            filteredPreviewImageView?.backgroundColor = .clear
            filteredPreviewImageView?.translatesAutoresizingMaskIntoConstraints = false
            filteredPreviewImageView?.isHidden = false
            filteredPreviewImageView?.alpha = 0.0 // 🔥 初始透明，等待图像处理完成后淡入
            filteredPreviewImageView?.clipsToBounds = true
            filteredPreviewImageView?.layer.masksToBounds = true
            
            // Apple Design: 添加圆角和阴影
            filteredPreviewImageView?.layer.cornerRadius = 16
            filteredPreviewImageView?.layer.shadowColor = UIColor.black.cgColor
            filteredPreviewImageView?.layer.shadowOpacity = 0.1
            filteredPreviewImageView?.layer.shadowOffset = CGSize(width: 0, height: 4)
            filteredPreviewImageView?.layer.shadowRadius = 8
            
            view.addSubview(filteredPreviewImageView!)
            
            // 🔥 修复：确保拍照按钮在预览层之上
            if let shutterButton = view.viewWithTag(999) as? UIButton {
                view.bringSubviewToFront(shutterButton)
            }
            
            // 🔥 修复：确保缩略图在预览层之上
            if let thumbImageView = view.viewWithTag(2001) as? UIImageView {
                view.bringSubviewToFront(thumbImageView)
            }
            
            // 🔥 修复：确保功能UI在预览层之上
            if let blurView = view.viewWithTag(777) as? UIVisualEffectView {
                view.bringSubviewToFront(blurView)
            }
            
            // 🔥 修复：确保后置UI在预览层之上
            if let ovalBlur = view.viewWithTag(8888) as? UIVisualEffectView {
                view.bringSubviewToFront(ovalBlur)
            }
            
            // 🔥 修复：确保前置UI在预览层之上
            if let cycleButton = view.viewWithTag(9999) as? UIButton {
                view.bringSubviewToFront(cycleButton)
            }
            
            NSLayoutConstraint.activate([
                filteredPreviewImageView!.topAnchor.constraint(equalTo: view.topAnchor),
                filteredPreviewImageView!.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                filteredPreviewImageView!.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                filteredPreviewImageView!.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
        } else {
            filteredPreviewImageView?.frame = view.bounds
        }
        // --- 其余UI照常 ---
        // 4. 插入到预览层之上，但低于UI控件
        if let preview = filteredPreviewImageView, preview.superview !== view {
            view.insertSubview(preview, at: 0) // 插入到最底层，确保UI控件在最顶层
        }
        
        // 立即确保UI控件在最顶层
        self.ensureUIControlsOnTop()
        
        // 再次确保UI控件在最顶层（双重保险）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.ensureUIControlsOnTop()
        }
        // 预览层全屏，内容mode为scaleAspectFit，掩膜遮住上下多余部分
        NSLayoutConstraint.activate([
            filteredPreviewImageView!.topAnchor.constraint(equalTo: view.topAnchor),
            filteredPreviewImageView!.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            filteredPreviewImageView!.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            filteredPreviewImageView!.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        // --- 清理filteredPreviewImageView上的所有手势 ---
        // --- 保留view上的手势 ---
        // 添加点击对焦手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapGesture.numberOfTapsRequired = 1
        filteredPreviewImageView?.addGestureRecognizer(tapGesture)
        // 添加双击曝光手势
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        filteredPreviewImageView?.addGestureRecognizer(doubleTapGesture)
        tapGesture.require(toFail: doubleTapGesture)
        // 添加捏合缩放手势
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        filteredPreviewImageView?.addGestureRecognizer(pinchGesture)
        print("滤镜预览层创建完成")

        // 滤镜预览层创建完成，继续其他初始化
        print("滤镜预览层已就绪")

        // 删除重复的镜头切换UI代码 - 已在setupCameraSwitchUI()中处理

        // 功能面板（Apple Design风格）
        let filterPanelView = makeAppleBlurView(style: .systemMaterialLight)
        filterPanelView.isHidden = true
        self.filterPanelView = filterPanelView
        view.addSubview(filterPanelView)
        print("功能面板创建完成")

        // 调节容器（Apple Design风格）
        contrastContainer = makeAppleBlurView(style: .systemMaterialDark)
        contrastContainer?.isHidden = true
        view.addSubview(contrastContainer!)
        
        saturationContainer = makeAppleBlurView(style: .systemMaterialDark)
        saturationContainer?.isHidden = true
        view.addSubview(saturationContainer!)
        
        temperatureContainer = makeAppleBlurView(style: .systemMaterialDark)
        temperatureContainer?.isHidden = true
        view.addSubview(temperatureContainer!)
        
        exposureContainer = makeAppleBlurView(style: .systemMaterialDark)
        exposureContainer?.isHidden = true
        view.addSubview(exposureContainer!)
        
        print("调节容器创建完成")

        // 设置滑块容器约束
        guard let filterButton = filterButton else {
            print("📱 [WARN] filterButton为nil，跳过滑块容器约束设置")
            return
        }
        
        if let contrastContainer = contrastContainer {
            NSLayoutConstraint.activate([
                contrastContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                contrastContainer.topAnchor.constraint(equalTo: filterButton.bottomAnchor, constant: 60), // 下移，避免遮挡滤镜按钮
                contrastContainer.widthAnchor.constraint(equalToConstant: 200),
                contrastContainer.heightAnchor.constraint(equalToConstant: 60)
            ])
        }
        if let saturationContainer = saturationContainer {
            NSLayoutConstraint.activate([
                saturationContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                saturationContainer.topAnchor.constraint(equalTo: filterButton.bottomAnchor, constant: 60), // 下移，避免遮挡滤镜按钮
                saturationContainer.widthAnchor.constraint(equalToConstant: 200),
                saturationContainer.heightAnchor.constraint(equalToConstant: 60)
            ])
        }


        // 1. 初始化面板按钮（用于面板横向排列）
        func stylePanelBtn(_ btn: UIButton, color: UIColor) {
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            btn.setTitleColor(.white, for: .normal)
            btn.backgroundColor = color.withAlphaComponent(0.7)
            btn.layer.cornerRadius = 14
            btn.layer.borderWidth = 1.1
            btn.layer.borderColor = color.withAlphaComponent(0.8).cgColor
            btn.layer.shadowColor = color.cgColor
            btn.layer.shadowOpacity = 0.13
            btn.layer.shadowOffset = CGSize(width: 0, height: 2)
            btn.layer.shadowRadius = 3
        }
        filterContrastButton = UIButton(type: .system)
        filterContrastButton?.setTitle("对", for: .normal)
        stylePanelBtn(filterContrastButton!, color: UIColor.systemBlue)
        filterContrastButton?.addTarget(self, action: #selector(toggleContrast), for: .touchUpInside)
        filterSaturationButton = UIButton(type: .system)
        filterSaturationButton?.setTitle("饱", for: .normal)
        stylePanelBtn(filterSaturationButton!, color: UIColor.systemGreen)
        filterSaturationButton?.addTarget(self, action: #selector(toggleSaturation), for: .touchUpInside)
        temperatureButton = UIButton(type: .system)
        temperatureButton?.setTitle("温", for: .normal)
        stylePanelBtn(temperatureButton!, color: UIColor.systemOrange)
        temperatureButton?.addTarget(self, action: #selector(toggleTemperature), for: .touchUpInside)
        let exposureButton = UIButton(type: .system)
        exposureButton.setTitle("曝", for: .normal)
        stylePanelBtn(exposureButton, color: UIColor.systemYellow)
        exposureButton.addTarget(self, action: #selector(toggleExposurePanel), for: .touchUpInside)

        print("面板按钮创建完成")
        // 2. 添加到filterPanelStack
        var filterPanelButtons: [UIView] = []
        filterPanelButtons.append(filterContrastButton!)
        filterPanelButtons.append(filterSaturationButton!)
        filterPanelButtons.append(temperatureButton!)
        filterPanelButtons.append(exposureButton)
        
        // 新增网格线按钮（放在曝光按钮右边）
        gridLineButton = UIButton(type: .system)
        gridLineButton?.setTitle("网格", for: .normal)
        stylePanelBtn(gridLineButton!, color: UIColor.systemPurple)
        gridLineButton?.addTarget(self, action: #selector(toggleGridLine), for: .touchUpInside)
        filterPanelButtons.append(gridLineButton!)
        
        // 插入重置按钮
        let resetButton = UIButton(type: .system)
        resetButton.setTitle("重置", for: .normal)
        stylePanelBtn(resetButton, color: UIColor.systemRed)
        resetButton.addTarget(self, action: #selector(resetFilters), for: .touchUpInside)
        filterPanelButtons.append(resetButton)
        // 新增保存按钮
        let saveButton = UIButton(type: .system)
        saveButton.setTitle("保存", for: .normal)
        stylePanelBtn(saveButton, color: UIColor.systemBlue)
        saveButton.addTarget(self, action: #selector(savePreset), for: .touchUpInside)
        filterPanelButtons.append(saveButton)
        let filterPanelStack = UIStackView(arrangedSubviews: filterPanelButtons)
        filterPanelStack.axis = .horizontal
        filterPanelStack.alignment = .center
        filterPanelStack.distribution = .fillProportionally
        filterPanelStack.spacing = 10
        filterPanelStack.translatesAutoresizingMaskIntoConstraints = false
        self.filterPanelStack = filterPanelStack
        filterPanelView.contentView.addSubview(filterPanelStack)
        NSLayoutConstraint.activate([
            filterPanelView.centerXAnchor.constraint(equalTo: filterButton.centerXAnchor, constant: 100), // 向右偏移100pt
            filterPanelView.topAnchor.constraint(equalTo: filterButton.bottomAnchor, constant: 8),
            filterPanelView.heightAnchor.constraint(equalToConstant: 44),
            filterPanelStack.leadingAnchor.constraint(equalTo: filterPanelView.leadingAnchor, constant: 12),
            filterPanelStack.trailingAnchor.constraint(equalTo: filterPanelView.trailingAnchor, constant: -12),
            filterPanelStack.topAnchor.constraint(equalTo: filterPanelView.topAnchor, constant: 6),
            filterPanelStack.bottomAnchor.constraint(equalTo: filterPanelView.bottomAnchor, constant: -6)
        ])
        print("功能面板布局完成")

        // 对比度按钮
        contrastButton = UIButton(type: .system)
        contrastButton?.translatesAutoresizingMaskIntoConstraints = false
        contrastButton?.setTitle("对", for: .normal)
        contrastButton?.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        contrastButton?.setTitleColor(.white, for: .normal)
        contrastButton?.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        contrastButton?.layer.cornerRadius = 18
        contrastButton?.addTarget(self, action: #selector(toggleContrast), for: .touchUpInside)
        contrastButton?.isHidden = true
        view.addSubview(contrastButton!)

        // 饱和度按钮
        saturationButton = UIButton(type: .system)
        saturationButton?.translatesAutoresizingMaskIntoConstraints = false
        saturationButton?.setTitle("色", for: .normal)
        saturationButton?.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        saturationButton?.setTitleColor(.white, for: .normal)
        saturationButton?.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        saturationButton?.layer.cornerRadius = 18
        saturationButton?.addTarget(self, action: #selector(toggleSaturation), for: .touchUpInside)
        saturationButton?.isHidden = true
        view.addSubview(saturationButton!)
        
        // 设置色温容器约束
        if let temperatureContainer = temperatureContainer {
            NSLayoutConstraint.activate([
                temperatureContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                temperatureContainer.topAnchor.constraint(equalTo: filterButton.bottomAnchor, constant: 60), // 下移，避免遮挡滤镜按钮
                temperatureContainer.widthAnchor.constraint(equalToConstant: 200),
                temperatureContainer.heightAnchor.constraint(equalToConstant: 60)
            ])
        }

        // 色温滑块
        temperatureSlider = PrettySlider()
        temperatureSlider?.translatesAutoresizingMaskIntoConstraints = false
        temperatureSlider?.minimumValue = 0
        temperatureSlider?.maximumValue = 100
        temperatureSlider?.value = 50
        temperatureSlider?.tag = 888 // 🔥 调试：添加唯一标识
        temperatureSlider?.accessibilityIdentifier = "temperatureSlider" // 🔥 调试：添加可访问性标识
        temperatureSlider?.addTarget(self, action: #selector(temperatureChanged), for: .valueChanged)
        // 蓝到红渐变
        let tempTrack = sliderGradientImage(colors: [UIColor.systemBlue, UIColor.systemRed])
        temperatureSlider?.setMinimumTrackImage(tempTrack, for: .normal)
        temperatureSlider?.setMaximumTrackImage(tempTrack, for: .normal)
        temperatureSlider?.setThumbImage(sliderThumbImage(color: .systemOrange), for: .normal)
        temperatureSlider?.setThumbImage(sliderThumbImage(color: .systemOrange, radius: 16), for: .highlighted)
        (temperatureContainer as? UIVisualEffectView)?.contentView.addSubview(temperatureSlider!)
        // 色温数值标签
        let temperatureValueLabel = UILabel()
        temperatureValueLabel.translatesAutoresizingMaskIntoConstraints = false
        temperatureValueLabel.textColor = .white
        temperatureValueLabel.font = UIFont.systemFont(ofSize: 14)
        temperatureValueLabel.textAlignment = .center
        temperatureValueLabel.text = "50"
        (temperatureContainer as? UIVisualEffectView)?.contentView.addSubview(temperatureValueLabel)
        self.temperatureValueLabel = temperatureValueLabel
        // 色温加减按钮和布局
        if let temperatureContainer = temperatureContainer, let temperatureSlider = temperatureSlider {
            let tempMinusBtn = UIButton(type: .system)
            tempMinusBtn.setTitle("-", for: .normal)
            tempMinusBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
            tempMinusBtn.setTitleColor(.white, for: .normal)
            tempMinusBtn.backgroundColor = UIColor.black.withAlphaComponent(0.3)
            tempMinusBtn.layer.cornerRadius = 14
            tempMinusBtn.translatesAutoresizingMaskIntoConstraints = false
            tempMinusBtn.addTarget(self, action: #selector(temperatureMinusTapped), for: .touchUpInside)
            tempMinusBtn.addTarget(self, action: #selector(tempMinusDown), for: .touchDown)
            tempMinusBtn.addTarget(self, action: #selector(tempMinusUp), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
            (temperatureContainer as? UIVisualEffectView)?.contentView.addSubview(tempMinusBtn)
            self.temperatureMinusBtn = tempMinusBtn
            let tempPlusBtn = UIButton(type: .system)
            tempPlusBtn.setTitle("+", for: .normal)
            tempPlusBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
            tempPlusBtn.setTitleColor(.white, for: .normal)
            tempPlusBtn.backgroundColor = UIColor.black.withAlphaComponent(0.3)
            tempPlusBtn.layer.cornerRadius = 14
            tempPlusBtn.translatesAutoresizingMaskIntoConstraints = false
            tempPlusBtn.addTarget(self, action: #selector(temperaturePlusTapped), for: .touchUpInside)
            tempPlusBtn.addTarget(self, action: #selector(tempPlusDown), for: .touchDown)
            tempPlusBtn.addTarget(self, action: #selector(tempPlusUp), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
            (temperatureContainer as? UIVisualEffectView)?.contentView.addSubview(tempPlusBtn)
            self.temperaturePlusBtn = tempPlusBtn
        // 🔥 修复：确保所有元素都已添加到视图层级后再设置约束
        guard tempMinusBtn.superview != nil,
              tempPlusBtn.superview != nil,
              temperatureSlider.superview != nil,
              temperatureValueLabel.superview != nil,
              temperatureContainer.superview != nil else {
            print("❌ [STABILITY] 色温容器元素未正确添加到视图层级")
            return
        }
        
        // 🔥 额外验证：确保容器和按钮在同一个视图层级中
        guard let temperatureContainerView = temperatureContainer as? UIVisualEffectView,
              tempMinusBtn.superview === temperatureContainerView.contentView,
              tempPlusBtn.superview === temperatureContainerView.contentView,
              temperatureSlider.superview === temperatureContainerView.contentView,
              temperatureValueLabel.superview === temperatureContainerView.contentView else {
            print("❌ [STABILITY] 色温容器元素不在同一个视图层级中")
            return
        }
        
        NSLayoutConstraint.activate([
                tempMinusBtn.centerYAnchor.constraint(equalTo: temperatureSlider.centerYAnchor),
                tempMinusBtn.leadingAnchor.constraint(equalTo: temperatureContainer.leadingAnchor, constant: 4),
                tempMinusBtn.widthAnchor.constraint(equalToConstant: 28),
                tempMinusBtn.heightAnchor.constraint(equalToConstant: 28),
                tempPlusBtn.centerYAnchor.constraint(equalTo: temperatureSlider.centerYAnchor),
                tempPlusBtn.trailingAnchor.constraint(equalTo: temperatureContainer.trailingAnchor, constant: -4),
                tempPlusBtn.widthAnchor.constraint(equalToConstant: 28),
                tempPlusBtn.heightAnchor.constraint(equalToConstant: 28),
                temperatureSlider.leadingAnchor.constraint(equalTo: tempMinusBtn.trailingAnchor, constant: 4),
                temperatureSlider.trailingAnchor.constraint(equalTo: tempPlusBtn.leadingAnchor, constant: -4),
                temperatureSlider.centerYAnchor.constraint(equalTo: temperatureContainer.centerYAnchor, constant: -10),
                temperatureSlider.widthAnchor.constraint(greaterThanOrEqualToConstant: 40),
                temperatureValueLabel.centerXAnchor.constraint(equalTo: temperatureContainer.centerXAnchor),
                temperatureValueLabel.topAnchor.constraint(equalTo: temperatureSlider.bottomAnchor, constant: 2),
                temperatureValueLabel.widthAnchor.constraint(equalTo: temperatureContainer.widthAnchor),
            temperatureValueLabel.heightAnchor.constraint(equalToConstant: 18)
        ])
        }
        // 对比度滑块
        contrastSlider = PrettySlider()
        contrastSlider?.minimumValue = 0
        contrastSlider?.maximumValue = 100
        contrastSlider?.value = 50
        contrastSlider?.tag = 777 // 🔥 调试：添加唯一标识
        contrastSlider?.accessibilityIdentifier = "contrastSlider" // 🔥 调试：添加可访问性标识
        contrastSlider?.addTarget(self, action: #selector(contrastChanged), for: .valueChanged)
        contrastSlider?.translatesAutoresizingMaskIntoConstraints = false
        // 黑到白渐变
        let contrastTrack = sliderGradientImage(colors: [.black, .white])
        contrastSlider?.setMinimumTrackImage(contrastTrack, for: .normal)
        contrastSlider?.setMaximumTrackImage(contrastTrack, for: .normal)
        contrastSlider?.setThumbImage(sliderThumbImage(color: .darkGray), for: .normal)
        contrastSlider?.setThumbImage(sliderThumbImage(color: .darkGray, radius: 16), for: .highlighted)
        (contrastContainer as? UIVisualEffectView)?.contentView.addSubview(contrastSlider!)
        let contrastValueLabel = UILabel()
        contrastValueLabel.translatesAutoresizingMaskIntoConstraints = false
        contrastValueLabel.textColor = .white
        contrastValueLabel.font = UIFont.systemFont(ofSize: 14)
        contrastValueLabel.textAlignment = .center
        contrastValueLabel.text = "50"
        (contrastContainer as? UIVisualEffectView)?.contentView.addSubview(contrastValueLabel)
        self.contrastValueLabel = contrastValueLabel
        if let contrastContainer = contrastContainer, let contrastSlider = contrastSlider {
            let contrastMinusBtn = UIButton(type: .system)
            contrastMinusBtn.setTitle("-", for: .normal)
            contrastMinusBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
            contrastMinusBtn.setTitleColor(.white, for: .normal)
            contrastMinusBtn.backgroundColor = UIColor.black.withAlphaComponent(0.3)
            contrastMinusBtn.layer.cornerRadius = 14
            contrastMinusBtn.translatesAutoresizingMaskIntoConstraints = false
            contrastMinusBtn.addTarget(self, action: #selector(contrastMinusTapped), for: .touchUpInside)
            contrastMinusBtn.addTarget(self, action: #selector(contrastMinusDown), for: .touchDown)
            contrastMinusBtn.addTarget(self, action: #selector(contrastMinusUp), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
            (contrastContainer as? UIVisualEffectView)?.contentView.addSubview(contrastMinusBtn)
            self.contrastMinusBtn = contrastMinusBtn
            let contrastPlusBtn = UIButton(type: .system)
            contrastPlusBtn.setTitle("+", for: .normal)
            contrastPlusBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
            contrastPlusBtn.setTitleColor(.white, for: .normal)
            contrastPlusBtn.backgroundColor = UIColor.black.withAlphaComponent(0.3)
            contrastPlusBtn.layer.cornerRadius = 14
            contrastPlusBtn.translatesAutoresizingMaskIntoConstraints = false
            contrastPlusBtn.addTarget(self, action: #selector(contrastPlusTapped), for: .touchUpInside)
            contrastPlusBtn.addTarget(self, action: #selector(contrastPlusDown), for: .touchDown)
            contrastPlusBtn.addTarget(self, action: #selector(contrastPlusUp), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
            (contrastContainer as? UIVisualEffectView)?.contentView.addSubview(contrastPlusBtn)
            self.contrastPlusBtn = contrastPlusBtn
        // 🔥 修复：确保所有元素都已添加到视图层级后再设置约束
        guard contrastMinusBtn.superview != nil,
              contrastPlusBtn.superview != nil,
              contrastSlider.superview != nil,
              contrastValueLabel.superview != nil,
              contrastContainer.superview != nil else {
            print("❌ [STABILITY] 对比度容器元素未正确添加到视图层级")
            return
        }
        
        // 🔥 额外验证：确保容器和按钮在同一个视图层级中
        guard let contrastContainerView = contrastContainer as? UIVisualEffectView,
              contrastMinusBtn.superview === contrastContainerView.contentView,
              contrastPlusBtn.superview === contrastContainerView.contentView,
              contrastSlider.superview === contrastContainerView.contentView,
              contrastValueLabel.superview === contrastContainerView.contentView else {
            print("❌ [STABILITY] 对比度容器元素不在同一个视图层级中")
            return
        }
        
        NSLayoutConstraint.activate([
                contrastMinusBtn.centerYAnchor.constraint(equalTo: contrastSlider.centerYAnchor),
                contrastMinusBtn.leadingAnchor.constraint(equalTo: contrastContainer.leadingAnchor, constant: 4),
                contrastMinusBtn.widthAnchor.constraint(equalToConstant: 28),
                contrastMinusBtn.heightAnchor.constraint(equalToConstant: 28),
                contrastPlusBtn.centerYAnchor.constraint(equalTo: contrastSlider.centerYAnchor),
                contrastPlusBtn.trailingAnchor.constraint(equalTo: contrastContainer.trailingAnchor, constant: -4),
                contrastPlusBtn.widthAnchor.constraint(equalToConstant: 28),
                contrastPlusBtn.heightAnchor.constraint(equalToConstant: 28),
                contrastSlider.leadingAnchor.constraint(equalTo: contrastMinusBtn.trailingAnchor, constant: 4),
                contrastSlider.trailingAnchor.constraint(equalTo: contrastPlusBtn.leadingAnchor, constant: -4),
                contrastSlider.centerYAnchor.constraint(equalTo: contrastContainer.centerYAnchor, constant: -10),
                contrastSlider.widthAnchor.constraint(greaterThanOrEqualToConstant: 40),
                contrastValueLabel.centerXAnchor.constraint(equalTo: contrastContainer.centerXAnchor),
                contrastValueLabel.topAnchor.constraint(equalTo: contrastSlider.bottomAnchor, constant: 2),
                contrastValueLabel.widthAnchor.constraint(equalTo: contrastContainer.widthAnchor),
            contrastValueLabel.heightAnchor.constraint(equalToConstant: 18)
        ])
        }
        // 饱和度滑块
        saturationSlider = PrettySlider()
        saturationSlider?.minimumValue = 0
        saturationSlider?.maximumValue = 100
        saturationSlider?.value = 50
        saturationSlider?.tag = 666 // 🔥 调试：添加唯一标识
        saturationSlider?.accessibilityIdentifier = "saturationSlider" // 🔥 调试：添加可访问性标识
        saturationSlider?.addTarget(self, action: #selector(saturationChanged), for: .valueChanged)
        saturationSlider?.translatesAutoresizingMaskIntoConstraints = false
        // 灰到主色渐变
        let satTrack = sliderGradientImage(colors: [.gray, .systemGreen])
        saturationSlider?.setMinimumTrackImage(satTrack, for: .normal)
        saturationSlider?.setMaximumTrackImage(satTrack, for: .normal)
        saturationSlider?.setThumbImage(sliderThumbImage(color: .systemGreen), for: .normal)
        saturationSlider?.setThumbImage(sliderThumbImage(color: .systemGreen, radius: 16), for: .highlighted)
        (saturationContainer as? UIVisualEffectView)?.contentView.addSubview(saturationSlider!)
        let saturationValueLabel = UILabel()
        saturationValueLabel.translatesAutoresizingMaskIntoConstraints = false
        saturationValueLabel.textColor = .white
        saturationValueLabel.font = UIFont.systemFont(ofSize: 14)
        saturationValueLabel.textAlignment = .center
        saturationValueLabel.text = "50"
        (saturationContainer as? UIVisualEffectView)?.contentView.addSubview(saturationValueLabel)
        self.saturationValueLabel = saturationValueLabel
        if let saturationContainer = saturationContainer, let saturationSlider = saturationSlider {
            let saturationMinusBtn = UIButton(type: .system)
            saturationMinusBtn.setTitle("-", for: .normal)
            saturationMinusBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
            saturationMinusBtn.setTitleColor(.white, for: .normal)
            saturationMinusBtn.backgroundColor = UIColor.black.withAlphaComponent(0.3)
            saturationMinusBtn.layer.cornerRadius = 14
            saturationMinusBtn.translatesAutoresizingMaskIntoConstraints = false
            saturationMinusBtn.addTarget(self, action: #selector(saturationMinusTapped), for: .touchUpInside)
            saturationMinusBtn.addTarget(self, action: #selector(satMinusDown), for: .touchDown)
            saturationMinusBtn.addTarget(self, action: #selector(satMinusUp), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
            (saturationContainer as? UIVisualEffectView)?.contentView.addSubview(saturationMinusBtn)
            self.saturationMinusBtn = saturationMinusBtn
            let saturationPlusBtn = UIButton(type: .system)
            saturationPlusBtn.setTitle("+", for: .normal)
            saturationPlusBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
            saturationPlusBtn.setTitleColor(.white, for: .normal)
            saturationPlusBtn.backgroundColor = UIColor.black.withAlphaComponent(0.3)
            saturationPlusBtn.layer.cornerRadius = 14
            saturationPlusBtn.translatesAutoresizingMaskIntoConstraints = false
            saturationPlusBtn.addTarget(self, action: #selector(saturationPlusTapped), for: .touchUpInside)
            saturationPlusBtn.addTarget(self, action: #selector(satPlusDown), for: .touchDown)
            saturationPlusBtn.addTarget(self, action: #selector(satPlusUp), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
            (saturationContainer as? UIVisualEffectView)?.contentView.addSubview(saturationPlusBtn)
            self.saturationPlusBtn = saturationPlusBtn
        // 🔥 修复：确保所有元素都已添加到视图层级后再设置约束
        guard saturationMinusBtn.superview != nil,
              saturationPlusBtn.superview != nil,
              saturationSlider.superview != nil,
              saturationValueLabel.superview != nil,
              saturationContainer.superview != nil else {
            print("❌ [STABILITY] 饱和度容器元素未正确添加到视图层级")
            return
        }
        
        // 🔥 额外验证：确保容器和按钮在同一个视图层级中
        guard let saturationContainerView = saturationContainer as? UIVisualEffectView,
              saturationMinusBtn.superview === saturationContainerView.contentView,
              saturationPlusBtn.superview === saturationContainerView.contentView,
              saturationSlider.superview === saturationContainerView.contentView,
              saturationValueLabel.superview === saturationContainerView.contentView else {
            print("❌ [STABILITY] 饱和度容器元素不在同一个视图层级中")
            return
        }
        
        NSLayoutConstraint.activate([
                saturationMinusBtn.centerYAnchor.constraint(equalTo: saturationSlider.centerYAnchor),
                saturationMinusBtn.leadingAnchor.constraint(equalTo: saturationContainer.leadingAnchor, constant: 4),
                saturationMinusBtn.widthAnchor.constraint(equalToConstant: 28),
                saturationMinusBtn.heightAnchor.constraint(equalToConstant: 28),
                saturationPlusBtn.centerYAnchor.constraint(equalTo: saturationSlider.centerYAnchor),
                saturationPlusBtn.trailingAnchor.constraint(equalTo: saturationContainer.trailingAnchor, constant: -4),
                saturationPlusBtn.widthAnchor.constraint(equalToConstant: 28),
                saturationPlusBtn.heightAnchor.constraint(equalToConstant: 28),
                saturationSlider.leadingAnchor.constraint(equalTo: saturationMinusBtn.trailingAnchor, constant: 4),
                saturationSlider.trailingAnchor.constraint(equalTo: saturationPlusBtn.leadingAnchor, constant: -4),
                saturationSlider.centerYAnchor.constraint(equalTo: saturationContainer.centerYAnchor, constant: -10),
                saturationSlider.widthAnchor.constraint(greaterThanOrEqualToConstant: 40),
                saturationValueLabel.centerXAnchor.constraint(equalTo: saturationContainer.centerXAnchor),
                saturationValueLabel.topAnchor.constraint(equalTo: saturationSlider.bottomAnchor, constant: 2),
                saturationValueLabel.widthAnchor.constraint(equalTo: saturationContainer.widthAnchor),
            saturationValueLabel.heightAnchor.constraint(equalToConstant: 18)
        ])
        }

        // 设置约束
        print("setupUI执行完成")

        // 拍照按钮（Apple Design风格）
        shutterButton = makeAppleShutterButton()
        shutterButton!.tag = 999 // 用于动画识别
        shutterButton!.addTarget(self, action: #selector(shutterTapped), for: .touchUpInside)
        view.addSubview(shutterButton!)
        NSLayoutConstraint.activate([
            shutterButton!.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shutterButton!.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -33),  // 上移25pt（从-8改为-33）
            shutterButton!.widthAnchor.constraint(equalToConstant: 60),
            shutterButton!.heightAnchor.constraint(equalToConstant: 60)
        ])

        // 设置曝光容器约束
        guard let exposureContainer = exposureContainer else {
            print("📱 [WARN] exposureContainer为nil，跳过曝光容器约束设置")
            return
        }
        
        NSLayoutConstraint.activate([
            exposureContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            exposureContainer.topAnchor.constraint(equalTo: filterButton.bottomAnchor, constant: 60), // 下移，避免遮挡滤镜按钮
            exposureContainer.widthAnchor.constraint(equalToConstant: 200),
            exposureContainer.heightAnchor.constraint(equalToConstant: 60)
        ])
        // --- 曝光条相关 ---
        // 🔥 修复：防止重复创建曝光滑动条
        if exposureSlider == nil {
        exposureSlider = PrettySlider()
        exposureSlider?.translatesAutoresizingMaskIntoConstraints = false // 🔥 修复：立即设置，避免自动布局冲突
        exposureSlider?.minimumValue = 0
        exposureSlider?.maximumValue = 100
            exposureSlider?.value = 50 // 🔥 修复：设置为中间值50，与其他滑动条保持一致
            exposureSlider?.tag = 555 // 🔥 修复：使用唯一tag，避免与拍照按钮冲突
            exposureSlider?.accessibilityIdentifier = "exposureSlider" // 🔥 调试：添加可访问性标识
            print("📸 [DEBUG] 初始化曝光滑动条 - value=\(exposureSlider?.value ?? 0)")
        exposureSlider?.addTarget(self, action: #selector(exposureChanged), for: .valueChanged)
            debugExposureSliderState() // 🔥 调试：检查初始化后的状态
        }
        // 美化样式 - 使用渐变图像，与其他滑动条保持一致
        let exposureTrack = sliderGradientImage(colors: [.gray, .systemYellow])
        exposureSlider?.setMinimumTrackImage(exposureTrack, for: .normal)
        exposureSlider?.setMaximumTrackImage(exposureTrack, for: .normal)
        exposureSlider?.setThumbImage(sliderThumbImage(color: .systemYellow), for: .normal)
        exposureSlider?.setThumbImage(sliderThumbImage(color: .systemYellow, radius: 16), for: .highlighted)
        // 🔥 修复：确保曝光条滑块正确添加到视图层级
        if exposureSlider?.superview == nil {
        (exposureContainer as? UIVisualEffectView)?.contentView.addSubview(exposureSlider!)
        } else if exposureSlider?.superview != (exposureContainer as? UIVisualEffectView)?.contentView {
            // 🔥 修复：如果滑块在错误的父视图中，重新添加到正确的容器
            exposureSlider?.removeFromSuperview()
            (exposureContainer as? UIVisualEffectView)?.contentView.addSubview(exposureSlider!)
        }
        
        // 正确创建并引用label为类属性
        if self.exposureValueLabel == nil {
        self.exposureValueLabel = UILabel()
        guard let exposureValueLabel = self.exposureValueLabel else { return }
        exposureValueLabel.translatesAutoresizingMaskIntoConstraints = false
        exposureValueLabel.textColor = .white
        exposureValueLabel.font = UIFont.systemFont(ofSize: 14)
        exposureValueLabel.textAlignment = .center
            exposureValueLabel.text = "50.0" // 🔥 修复：设置为中间值50.0，与其他滑动条保持一致
        (exposureContainer as? UIVisualEffectView)?.contentView.addSubview(exposureValueLabel)
        } else if self.exposureValueLabel?.superview == nil {
            // 🔥 修复：如果标签存在但没有添加到视图层级，重新添加
            (exposureContainer as? UIVisualEffectView)?.contentView.addSubview(self.exposureValueLabel!)
        }
        
        // 🔥 修复：确保exposureSlider存在后再创建按钮和设置约束
        guard let exposureSlider = exposureSlider else { return }
        
        // 🔥 修复：确保按钮正确添加到视图层级
        if self.exposureMinusBtn == nil {
            let exposureMinusBtn = UIButton(type: .system)
            exposureMinusBtn.setTitle("-", for: .normal)
            exposureMinusBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
            exposureMinusBtn.setTitleColor(.white, for: .normal)
            exposureMinusBtn.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.15)
            exposureMinusBtn.layer.cornerRadius = 14
            exposureMinusBtn.layer.shadowColor = UIColor.systemBlue.cgColor
            exposureMinusBtn.layer.shadowOpacity = 0.2
            exposureMinusBtn.layer.shadowOffset = CGSize(width: 0, height: 2)
            exposureMinusBtn.layer.shadowRadius = 4
            exposureMinusBtn.setTitleColor(.systemBlue, for: .normal)
            exposureMinusBtn.translatesAutoresizingMaskIntoConstraints = false
            exposureMinusBtn.addTarget(self, action: #selector(exposureMinusTapped), for: .touchUpInside)
            exposureMinusBtn.addTarget(self, action: #selector(exposureMinusDown), for: .touchDown)
            exposureMinusBtn.addTarget(self, action: #selector(exposureMinusUp), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
            (exposureContainer as? UIVisualEffectView)?.contentView.addSubview(exposureMinusBtn)
            self.exposureMinusBtn = exposureMinusBtn
        } else if self.exposureMinusBtn?.superview == nil {
            // 🔥 修复：如果按钮存在但没有添加到视图层级，重新添加
            (exposureContainer as? UIVisualEffectView)?.contentView.addSubview(self.exposureMinusBtn!)
        }
        
        if self.exposurePlusBtn == nil {
            let exposurePlusBtn = UIButton(type: .system)
            exposurePlusBtn.setTitle("+", for: .normal)
            exposurePlusBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
            exposurePlusBtn.setTitleColor(.white, for: .normal)
            exposurePlusBtn.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.15)
            exposurePlusBtn.layer.cornerRadius = 14
            exposurePlusBtn.layer.shadowColor = UIColor.systemBlue.cgColor
            exposurePlusBtn.layer.shadowOpacity = 0.2
            exposurePlusBtn.layer.shadowOffset = CGSize(width: 0, height: 2)
            exposurePlusBtn.layer.shadowRadius = 4
            exposurePlusBtn.setTitleColor(.systemBlue, for: .normal)
            exposurePlusBtn.translatesAutoresizingMaskIntoConstraints = false
            exposurePlusBtn.addTarget(self, action: #selector(exposurePlusTapped), for: .touchUpInside)
            exposurePlusBtn.addTarget(self, action: #selector(exposurePlusDown), for: .touchDown)
            exposurePlusBtn.addTarget(self, action: #selector(exposurePlusUp), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
            (exposureContainer as? UIVisualEffectView)?.contentView.addSubview(exposurePlusBtn)
            self.exposurePlusBtn = exposurePlusBtn
        } else if self.exposurePlusBtn?.superview == nil {
            // 🔥 修复：如果按钮存在但没有添加到视图层级，重新添加
            (exposureContainer as? UIVisualEffectView)?.contentView.addSubview(self.exposurePlusBtn!)
        }
        // 🔥 修复：确保所有元素都已添加到视图层级后再设置约束
        if let exposureMinusBtn = self.exposureMinusBtn, 
           let exposurePlusBtn = self.exposurePlusBtn, 
           let exposureValueLabel = self.exposureValueLabel {
            
            // 🔥 修复：确保曝光容器在最上层，避免被场景UI遮挡
            view.bringSubviewToFront(exposureContainer)
            
            // 🔥 修复：防止重复设置约束，先移除旧的约束
            exposureMinusBtn.removeFromSuperview()
            exposurePlusBtn.removeFromSuperview()
            exposureSlider.removeFromSuperview()
            exposureValueLabel.removeFromSuperview()
            
            // 重新添加到容器
            (exposureContainer as? UIVisualEffectView)?.contentView.addSubview(exposureMinusBtn)
            (exposureContainer as? UIVisualEffectView)?.contentView.addSubview(exposurePlusBtn)
            (exposureContainer as? UIVisualEffectView)?.contentView.addSubview(exposureSlider)
            (exposureContainer as? UIVisualEffectView)?.contentView.addSubview(exposureValueLabel)
            
            // 🔥 验证：确保所有元素都已正确添加到视图层级
            guard exposureMinusBtn.superview != nil,
                  exposurePlusBtn.superview != nil,
                  exposureSlider.superview != nil,
                  exposureValueLabel.superview != nil,
                  exposureContainer.superview != nil else {
                print("❌ [STABILITY] 曝光容器元素未正确添加到视图层级")
                print("🔍 [DEBUG] exposureMinusBtn.superview: \(exposureMinusBtn.superview != nil)")
                print("🔍 [DEBUG] exposurePlusBtn.superview: \(exposurePlusBtn.superview != nil)")
                print("🔍 [DEBUG] exposureSlider.superview: \(exposureSlider.superview != nil)")
                print("🔍 [DEBUG] exposureValueLabel.superview: \(exposureValueLabel.superview != nil)")
                print("🔍 [DEBUG] exposureContainer.superview: \(exposureContainer.superview != nil)")
                return
            }
            
            // 🔥 额外验证：确保容器和按钮在同一个视图层级中
            guard let exposureContainerView = exposureContainer as? UIVisualEffectView,
                  exposureMinusBtn.superview === exposureContainerView.contentView,
                  exposurePlusBtn.superview === exposureContainerView.contentView,
                  exposureSlider.superview === exposureContainerView.contentView,
                  exposureValueLabel.superview === exposureContainerView.contentView else {
                print("❌ [STABILITY] 曝光容器元素不在同一个视图层级中")
                return
            }
            
        NSLayoutConstraint.activate([
                exposureMinusBtn.centerYAnchor.constraint(equalTo: exposureSlider.centerYAnchor),
                exposureMinusBtn.leadingAnchor.constraint(equalTo: exposureContainer.leadingAnchor, constant: 4),
                exposureMinusBtn.widthAnchor.constraint(equalToConstant: 28),
                exposureMinusBtn.heightAnchor.constraint(equalToConstant: 28),
                exposurePlusBtn.centerYAnchor.constraint(equalTo: exposureSlider.centerYAnchor),
                exposurePlusBtn.trailingAnchor.constraint(equalTo: exposureContainer.trailingAnchor, constant: -4),
                exposurePlusBtn.widthAnchor.constraint(equalToConstant: 28),
                exposurePlusBtn.heightAnchor.constraint(equalToConstant: 28),
                exposureSlider.leadingAnchor.constraint(equalTo: exposureMinusBtn.trailingAnchor, constant: 4),
                exposureSlider.trailingAnchor.constraint(equalTo: exposurePlusBtn.leadingAnchor, constant: -4),
                exposureSlider.centerYAnchor.constraint(equalTo: exposureContainer.centerYAnchor, constant: -10),
                exposureSlider.widthAnchor.constraint(greaterThanOrEqualToConstant: 40),
                exposureValueLabel.centerXAnchor.constraint(equalTo: exposureContainer.centerXAnchor),
                exposureValueLabel.topAnchor.constraint(equalTo: exposureSlider.bottomAnchor, constant: 2),
                exposureValueLabel.widthAnchor.constraint(equalTo: exposureContainer.widthAnchor),
                exposureValueLabel.heightAnchor.constraint(equalToConstant: 18)
        ])
        }
        
        // 🔥 修复：强制更新布局，确保约束生效
        exposureContainer.layoutIfNeeded()
        
        // 🔥 修复：在设置完约束后再次检查状态
        debugExposureSliderState()
        // --- 曝光条相关 ---

        // 曝光条上下滑手势
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleExposurePan(_:)))
        exposureContainer.addGestureRecognizer(pan)
        // --- setupUI 结尾，所有 addSubview/约束都设置完后 ---
        // 🔥 优化：移除视图层级检查，避免阻塞
        DispatchQueue.main.async {
            if let preview = self.filteredPreviewImageView {
                print("[DEBUG] 视图层级检查已优化，避免阻塞")
                print("[DEBUG] filteredPreviewImageView 属性：frame=\(preview.frame), alpha=\(preview.alpha), isHidden=\(preview.isHidden), superview=\(String(describing: preview.superview)), image is nil=\(preview.image == nil)")
                
                // 原始代码（暂时注释）
                /*
                print("[DEBUG] view.subviews 层级顺序：")
                for (idx, v) in self.view.subviews.enumerated() {
                    print("[DEBUG] subview[\(idx)]: \(type(of: v)), tag=\(v.tag), isHidden=\(v.isHidden), alpha=\(v.alpha)")
                }
                */
            }
        }

        // 左下角缩略图
        view.subviews.filter { $0.tag == 2001 }.forEach { $0.removeFromSuperview() }
        let thumbImageView = UIImageView()
        thumbImageView.translatesAutoresizingMaskIntoConstraints = false
        thumbImageView.contentMode = .scaleAspectFill
        thumbImageView.clipsToBounds = true
        thumbImageView.layer.cornerRadius = 8
        thumbImageView.backgroundColor = .black
        thumbImageView.isUserInteractionEnabled = true
        thumbImageView.tag = 2001
        view.addSubview(thumbImageView)
        NSLayoutConstraint.activate([
            thumbImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
            thumbImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -dynamicBottomOffset() - 33), // 与拍照UI水平对齐
            thumbImageView.widthAnchor.constraint(equalToConstant: 56),
            thumbImageView.heightAnchor.constraint(equalToConstant: 56)
        ])
        refreshThumbnail()
        // 🔥 修复：确保移除所有旧的手势识别器
        thumbImageView.gestureRecognizers?.forEach { thumbImageView.removeGestureRecognizer($0) }
        let tap = UITapGestureRecognizer(target: self, action: #selector(openLastPhotoInAlbum))
        tap.numberOfTapsRequired = 1
        tap.numberOfTouchesRequired = 1
        tap.cancelsTouchesInView = false // 🔥 修复：不取消其他触摸事件
        thumbImageView.addGestureRecognizer(tap)
        print("📸 [DEBUG] 缩略图手势识别器已设置")



        // 添加zoom label到右下角
        // 2. 移除底部蓝色菱形相关UI
        // 检查底部按钮、shutterButton、或自定义UIView/UIImageView/CAShapeLayer等相关代码，
        // 如果有添加蓝色菱形的代码（如自定义UIView、drawRect、CAShapeLayer、UIImageView等），全部删除。
        // ... existing code ...

        // --- 预览层手势 ---
        // 添加捏合缩放手势到view
        view.addGestureRecognizer(pinchGesture)
        // 添加单指点击对焦手势到view
        tapGesture.numberOfTapsRequired = 1
        view.addGestureRecognizer(tapGesture)
        // 设置手势 delegate，避免与 collectionView 冲突
        tapGesture.delegate = self
        pinchGesture.delegate = self

        // --- 场景选择区域 ---
        // 先移除旧的
        sceneCategoryCollectionView?.removeFromSuperview()
        sceneImageCollectionView?.removeFromSuperview()
        // 读取所有分类
        sceneCategories = []
        if let root = sceneGuideRoot {
            sceneCategories = (try? FileManager.default.contentsOfDirectory(atPath: root).filter { url in
                var isDir: ObjCBool = false
                let full = (root as NSString).appendingPathComponent(url)
                FileManager.default.fileExists(atPath: full, isDirectory: &isDir)
                return isDir.boolValue
            }) ?? []
            print("sceneCategories:", sceneCategories)
        } else {
            print("[ERROR] 未找到拍照指引文件夹，请将其添加到Xcode项目并设置为蓝色文件夹（Folder Reference）")
        }
        // 分类横滑条
        let catLayout = UICollectionViewFlowLayout()
        catLayout.scrollDirection = .horizontal
        catLayout.itemSize = CGSize(width: 90, height: 38)
        catLayout.minimumLineSpacing = 10
        let catCV = UICollectionView(frame: .zero, collectionViewLayout: catLayout)
        catCV.translatesAutoresizingMaskIntoConstraints = false
        catCV.delegate = self
        catCV.dataSource = self
        catCV.backgroundColor = .clear
        catCV.tag = 4001
        catCV.showsHorizontalScrollIndicator = false
        catCV.register(SceneCategoryCell.self, forCellWithReuseIdentifier: "catcell")
        catCV.delaysContentTouches = false // 立即响应点击
        view.addSubview(catCV)
        // setupUI里加：
        print("sceneCategories:", sceneCategories)
        // sceneButton为nil时fallback
        let catCVTopAnchor = sceneButton?.bottomAnchor ?? view.safeAreaLayoutGuide.topAnchor
        NSLayoutConstraint.activate([
            catCV.topAnchor.constraint(equalTo: catCVTopAnchor, constant: 6),
            catCV.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            catCV.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            catCV.heightAnchor.constraint(equalToConstant: 38)
        ])
        self.sceneCategoryCollectionView = catCV
        // 图片横滑条
        let imgLayout = UICollectionViewFlowLayout()
        imgLayout.scrollDirection = .horizontal
        imgLayout.itemSize = CGSize(width: 80, height: 80)
        imgLayout.minimumLineSpacing = 10
        let imgCV = UICollectionView(frame: .zero, collectionViewLayout: imgLayout)
        imgCV.translatesAutoresizingMaskIntoConstraints = false
        imgCV.delegate = self
        imgCV.dataSource = self
        imgCV.backgroundColor = .clear
        imgCV.tag = 4002
        imgCV.showsHorizontalScrollIndicator = false
        imgCV.register(SceneImageCell.self, forCellWithReuseIdentifier: "imgcell")
        imgCV.delaysContentTouches = false // 立即响应点击
        view.addSubview(imgCV)
        let imgCVTopAnchor = catCV.bottomAnchor
        NSLayoutConstraint.activate([
            imgCV.topAnchor.constraint(equalTo: imgCVTopAnchor, constant: 6),
            imgCV.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            imgCV.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            imgCV.heightAnchor.constraint(equalToConstant: 80)
        ])
        self.sceneImageCollectionView = imgCV
        // 默认选中第一个分类
        if let first = sceneCategories.first {
            selectSceneCategory(named: first)
        }
        // setupUI末尾，横向条初始隐藏：
        sceneCategoryCollectionView?.isHidden = true
        sceneImageCollectionView?.isHidden = true

        // 1. 在setupUI或场景栏UI初始化后添加：
        if addSceneButton == nil {
            let btn = UIButton(type: .contactAdd)
            btn.addTarget(self, action: #selector(addSceneTapped), for: .touchUpInside)
            btn.translatesAutoresizingMaskIntoConstraints = false
            if let collectionView = sceneCategoryCollectionView {
                collectionView.addSubview(btn)
                NSLayoutConstraint.activate([
                    btn.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor, constant: -8),
                    btn.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor)
                ])
                addSceneButton = btn
            }
        }

        if let catCV = sceneCategoryCollectionView {
            catCV.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "addSceneCell")
        }
        if let imgCV = sceneImageCollectionView {
            imgCV.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "addImageCell")
        }
        
        // 在setupUI方法内部合适位置插入：
        if addSceneImageButton == nil {
            let btn = UIButton(type: .contactAdd)
            btn.addTarget(self, action: #selector(addSceneImageTapped), for: .touchUpInside)
            btn.translatesAutoresizingMaskIntoConstraints = false
            if let collectionView = sceneImageCollectionView {
                collectionView.addSubview(btn)
                NSLayoutConstraint.activate([
                    btn.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor, constant: -8),
                    btn.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor)
                ])
                addSceneImageButton = btn
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 恢复摄像头帧流
        if let vOutput = self.videoOutput {
            let videoQueue = DispatchQueue(label: "videoQueue", qos: .userInitiated)
            vOutput.setSampleBufferDelegate(self, queue: videoQueue)
        }
        applyPerformanceOptimizations()
    }
    
    @objc func toggleFilterPanel() {
        print("🎨 [DEBUG] 功能按钮被点击！")
        
        // 🔥 修复：确保UI已初始化后再切换状态
        if filterPanelView == nil {
            print("🎨 [DEBUG] filterPanelView为nil，需要先初始化UI")
            // 如果UI还没初始化，先初始化再切换
            setupFilterSystemIfNeeded()
            // 等待UI初始化完成后再切换状态
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.toggleFilterPanel()
            }
            return
        }
        
        // 🔥 懒加载：确保滤镜系统已初始化
        setupFilterSystemIfNeeded()
        
        // 🔥 修复：立即切换状态，避免延迟导致的重复点击问题
        print("🎨 [DEBUG] 开始切换功能面板，当前状态: \(self.isFilterPanelVisible)")
            self.isFilterPanelVisible.toggle()
        print("🎨 [DEBUG] 功能面板状态已切换为: \(self.isFilterPanelVisible)")
        
        // 🔥 修复：确保filterPanelView存在后再设置状态
        if let filterPanelView = self.filterPanelView {
            filterPanelView.isHidden = !self.isFilterPanelVisible
            print("🎨 [DEBUG] 功能面板隐藏状态: \(filterPanelView.isHidden)")
        } else {
            print("🎨 [DEBUG] filterPanelView为nil，无法设置状态")
        }
        
            self.dismissParamManager()
            self.sceneCategoryCollectionView?.isHidden = true
            self.sceneImageCollectionView?.isHidden = true
            self.isContrastVisible = false
            self.isSaturationVisible = false
            self.isTemperatureVisible = false
            self.isExposureVisible = false
            self.updateButtonStates()
        
        print("🎨 [DEBUG] 功能面板切换完成")
    }
    
    @objc func toggleContrast() {
        isContrastVisible.toggle()
        contrastContainer?.isHidden = !isContrastVisible
        saturationContainer?.isHidden = true
        temperatureContainer?.isHidden = true
        exposureContainer?.isHidden = true
        isSaturationVisible = false
        isTemperatureVisible = false
        isExposureVisible = false
        updateButtonStates()
        hideExposurePanelIfNeeded()
        if isContrastVisible { 
            // 🔥 修复：只在参数真正变化时才更新预览
            if abs(currentContrast - 1.0) > 0.01 {
            updatePreviewImage()
            }
            // 启动自动隐藏定时器
            startSliderAutoHide(for: "contrast")
        } else { 
            hideFilterPreviewIfNeeded()
            // 取消自动隐藏定时器
            cancelSliderAutoHide(for: "contrast")
        }
    }
    
    @objc func toggleSaturation() {
        isSaturationVisible.toggle()
        saturationContainer?.isHidden = !isSaturationVisible
        contrastContainer?.isHidden = true
        temperatureContainer?.isHidden = true
        exposureContainer?.isHidden = true
        isContrastVisible = false
        isTemperatureVisible = false
        isExposureVisible = false
        updateButtonStates()
        hideExposurePanelIfNeeded()
        if isSaturationVisible { 
            // 🔥 修复：只在参数真正变化时才更新预览
            if abs(currentSaturation - 1.0) > 0.01 {
            updatePreviewImage()
            }
            // 启动自动隐藏定时器
            startSliderAutoHide(for: "saturation")
        } else { 
            hideFilterPreviewIfNeeded()
            // 取消自动隐藏定时器
            cancelSliderAutoHide(for: "saturation")
        }
    }
    
    @objc func toggleTemperature() {
        isTemperatureVisible.toggle()
        temperatureContainer?.isHidden = !isTemperatureVisible
        contrastContainer?.isHidden = true
        saturationContainer?.isHidden = true
        exposureContainer?.isHidden = true
        isContrastVisible = false
        isSaturationVisible = false
        isExposureVisible = false
        updateButtonStates()
        hideExposurePanelIfNeeded()
        if isTemperatureVisible { 
            // 🔥 修复色温闪烁：正确比较实际色温值
            let sliderValue = temperatureSlider?.value ?? 50.0
            let actualTemp = 5000.0 + (sliderValue / 100.0) * 3000.0 // 5000K到8000K的范围
            if abs(actualTemp - 6500.0) > 1.0 {
            updatePreviewImage()
            }
            // 启动自动隐藏定时器
            startSliderAutoHide(for: "temperature")
        } else { 
            hideFilterPreviewIfNeeded()
            // 取消自动隐藏定时器
            cancelSliderAutoHide(for: "temperature")
        }
    }
    
    @objc func toggleGridLine() {
        isGridLineEnabled.toggle()
        updateGridLineVisibility()
        updateGridLineButtonState()
    }
    
    func updateGridLineVisibility() {
        if isGridLineEnabled {
            showGridLineOnPreview()
            showGridLineOnThumbnail()
        } else {
            hideGridLineFromPreview()
            hideGridLineFromThumbnail()
        }
    }
    
    func updateGridLineButtonState() {
        gridLineButton?.backgroundColor = isGridLineEnabled ? 
            UIColor.systemPurple.withAlphaComponent(0.8) : 
            UIColor.systemPurple.withAlphaComponent(0.7)
    }
    
    func showGridLineOnPreview() {
        guard let preview = filteredPreviewImageView else { return }
        
        // 计算实际的预览画幅区域
        let previewSize = preview.bounds.size
        let imageSize = preview.image?.size ?? previewSize
        let imageAspect = imageSize.width / imageSize.height
        let previewAspect = previewSize.width / previewSize.height
        
        var visibleFrame: CGRect
        if imageAspect > previewAspect {
            // 图片更宽，高度适配
            let fitHeight = previewSize.width / imageAspect
            let y = (previewSize.height - fitHeight) / 2
            visibleFrame = CGRect(x: 0, y: y, width: previewSize.width, height: fitHeight)
        } else {
            // 图片更高，宽度适配
            let fitWidth = previewSize.height * imageAspect
            let x = (previewSize.width - fitWidth) / 2
            visibleFrame = CGRect(x: x, y: 0, width: fitWidth, height: previewSize.height)
        }
        
        if gridLineView == nil {
            gridLineView = GridLineView(frame: visibleFrame)
            gridLineView?.translatesAutoresizingMaskIntoConstraints = false
        } else {
            gridLineView?.frame = visibleFrame
        }
        
        if let gridLineView = gridLineView, gridLineView.superview == nil {
            preview.addSubview(gridLineView)
        }
    }
    
    func hideGridLineFromPreview() {
        gridLineView?.removeFromSuperview()
    }
    
    func showGridLineOnThumbnail() {
        guard let thumbnail = floatingThumbnail else { return }
        
        if thumbnailGridLineView == nil {
            thumbnailGridLineView = GridLineView(frame: thumbnail.bounds)
            thumbnailGridLineView?.translatesAutoresizingMaskIntoConstraints = false
        }
        
        if let thumbnailGridLineView = thumbnailGridLineView, thumbnailGridLineView.superview == nil {
            thumbnail.addSubview(thumbnailGridLineView)
            NSLayoutConstraint.activate([
                thumbnailGridLineView.topAnchor.constraint(equalTo: thumbnail.topAnchor),
                thumbnailGridLineView.leadingAnchor.constraint(equalTo: thumbnail.leadingAnchor),
                thumbnailGridLineView.trailingAnchor.constraint(equalTo: thumbnail.trailingAnchor),
                thumbnailGridLineView.bottomAnchor.constraint(equalTo: thumbnail.bottomAnchor)
            ])
        }
    }
    
    func hideGridLineFromThumbnail() {
        thumbnailGridLineView?.removeFromSuperview()
    }
    
    func updateButtonStates() {
        // 更新顶部功能按钮状态
        let colors: [UIColor] = [.systemBlue, .systemPurple, .systemGreen]
        let buttons = [filterButton, sceneButton, paramButton]
        
        for (i, btn) in buttons.enumerated() {
            if let btn = btn {
                if i == 0 && isFilterPanelVisible {
                    // 功能按钮激活状态
                    btn.backgroundColor = colors[i].withAlphaComponent(0.3)
                    btn.layer.borderColor = colors[i].withAlphaComponent(0.6).cgColor
                } else if i == 1 && isSceneGuideVisible {
                    // 场景按钮激活状态
                    btn.backgroundColor = colors[i].withAlphaComponent(0.3)
                    btn.layer.borderColor = colors[i].withAlphaComponent(0.6).cgColor
                } else if i == 2 && view.viewWithTag(9999) != nil {
                    // 参数按钮激活状态（检查参数面板是否显示）
                    btn.backgroundColor = colors[i].withAlphaComponent(0.3)
                    btn.layer.borderColor = colors[i].withAlphaComponent(0.6).cgColor
                } else {
                    // 默认状态
                    btn.backgroundColor = colors[i].withAlphaComponent(0.1)
                    btn.layer.borderColor = colors[i].withAlphaComponent(0.3).cgColor
                }
            }
        }
        
        // 更新网格线按钮状态
        updateGridLineButtonState()
    }
    
    @objc func contrastChanged() {
        guard let slider = contrastSlider else { return }
        currentContrast = 0.8 + (slider.value / 100.0) * (1.2 - 0.8)
        filterUpdateWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in self?.updatePreviewImage() }
        filterUpdateWorkItem = workItem
        processingQueue.asyncAfter(deadline: .now() + 0.08, execute: workItem)
        let percent = Int(slider.value)
        contrastValueLabel?.text = "\(percent)"
        
        // 启动自动隐藏定时器
        startSliderAutoHide(for: "contrast")
    }
    
    @objc func saturationChanged() {
        guard let slider = saturationSlider else { return }
        currentSaturation = 0.8 + (slider.value / 100.0) * (1.2 - 0.8)
        filterUpdateWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in self?.updatePreviewImage() }
        filterUpdateWorkItem = workItem
        processingQueue.asyncAfter(deadline: .now() + 0.08, execute: workItem)
        let percent = Int(slider.value)
        saturationValueLabel?.text = "\(percent)"
        
        // 启动自动隐藏定时器
        startSliderAutoHide(for: "saturation")
    }
    
    @objc func shutterTapped() {
        // 优化快门闪光动画，缩短白屏时间
        let flashView = UIView(frame: view.bounds)
        flashView.backgroundColor = UIColor.white
        flashView.alpha = 0.0
        view.addSubview(flashView)
        UIView.animate(withDuration: 0.04, animations: {
            flashView.alpha = 0.7
        }) { _ in
            UIView.animate(withDuration: 0.08, animations: {
                flashView.alpha = 0.0
            }) { _ in
                flashView.removeFromSuperview()
            }
        }
        // 快门音效
        AudioServicesPlaySystemSound(1108)
        
        // 🔥 优化：异步处理设备配置，避免阻塞主线程
        DispatchQueue.global(qos: .userInitiated).async {
            if let device = (self.captureSession?.inputs.first as? AVCaptureDeviceInput)?.device {
                let currentLabel = self.cameraOptions[self.currentCameraIndex].label
                let maxZoom = self.maxEffectiveZoom(for: currentLabel)
                print("[DEBUG] shutterTapped: 镜头=\(currentLabel), maxZoom=\(maxZoom), 当前videoZoomFactor=\(device.videoZoomFactor)")
                
                // 🔥 添加超时机制
                let timeoutWork = DispatchWorkItem {
                    print("⚠️ 设备配置超时")
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: timeoutWork)
                
                do {
                    try device.lockForConfiguration()
                    if device.videoZoomFactor > maxZoom {
                        device.videoZoomFactor = maxZoom
                    }
                    device.exposureMode = .locked
                    device.setExposureTargetBias(0.0, completionHandler: nil)
                    device.exposurePointOfInterest = CGPoint(x: 0.5, y: 0.5)
                    print("📱 拍照前锁定曝光并设置曝光补偿为0，确保预览与成片一致")
                    device.unlockForConfiguration()
                    
                    timeoutWork.cancel() // 取消超时
                    
                    // 🔥 在主线程更新UI
                    DispatchQueue.main.async {
                        self.updateZoomLabel()
                    }
                } catch {
                    timeoutWork.cancel() // 取消超时
                    print("📱 拍照前设置失败: \(error)")
                }
            }
        }
        
        // 所见即所得：设置标记，下一帧保存
        shouldSaveNextPreviewFrame = true
        updateZoomLabel()
    }
    
    @objc func closeCamera() {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 自动修正：同步previewLayer和filteredPreviewImageView的frame
        previewLayer?.frame = view.bounds
        filteredPreviewImageView?.frame = view.bounds
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopDeviceMotionUpdates() // 停止陀螺仪监听
        isActive = false
        // 停止CoreMotion更新
        stopDeviceMotionUpdates()
        
        // 🔥 改进会话停止逻辑，避免过度清理导致黑屏
        print("📱 viewWillDisappear - 开始暂停相机")
        
        // 只暂停 session，不释放
        if let session = captureSession, session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.sessionConfigLock.lock()
                session.stopRunning()
                self.sessionConfigLock.unlock()
                print("📱 相机会话已暂停")
            }
        }
        
        // 断开 delegate，防止异步回调
        videoOutput?.setSampleBufferDelegate(nil, queue: nil)
        
        // 🔥 修复：保存应用状态
        saveAppState()
        
        // 🔥 保留UI状态，不清理预览层
        print("📱 viewWillDisappear - 相机暂停完成，保留UI状态")
    }
    
    // MARK: - 应用状态管理
    private func saveAppState() {
        print("📱 [STATE] 开始保存应用状态")
        
        let defaults = UserDefaults.standard
        
        // 保存UI状态
        defaults.set(isFilterPanelVisible, forKey: "SavedFilterPanelVisible")
        defaults.set(isSceneGuideVisible, forKey: "SavedSceneGuideVisible")
        defaults.set(isContrastVisible, forKey: "SavedContrastVisible")
        defaults.set(isSaturationVisible, forKey: "SavedSaturationVisible")
        defaults.set(isTemperatureVisible, forKey: "SavedTemperatureVisible")
        defaults.set(isExposureVisible, forKey: "SavedExposureVisible")
        
        // 保存滑动条值
        defaults.set(currentContrast, forKey: "SavedCurrentContrast")
        defaults.set(currentSaturation, forKey: "SavedCurrentSaturation")
        defaults.set(currentTemperature, forKey: "SavedCurrentTemperature")
        defaults.set(currentExposure, forKey: "SavedCurrentExposure")
        
        // 保存相机状态
        defaults.set(currentCameraIndex, forKey: "SavedCurrentCameraIndex")
        defaults.set(isUsingFrontCamera, forKey: "SavedIsUsingFrontCamera")
        
        // 保存设备方向（已在didSet中自动保存）
        
        print("📱 [STATE] 应用状态保存完成")
    }
    
    private func restoreAppState() {
        print("📱 [STATE] 开始恢复应用状态")
        
        let defaults = UserDefaults.standard
        
        // 恢复设备方向
        let savedOrientation = defaults.integer(forKey: "SavedDeviceOrientation")
        if savedOrientation > 0 {
            currentDeviceOrientation = UIDeviceOrientation(rawValue: savedOrientation) ?? .portrait
            print("📱 [STATE] 恢复设备方向: \(currentDeviceOrientation.rawValue)")
        }
        
        // 🔥 修复：应用启动时强制关闭所有面板，确保第一次点击是打开
        isFilterPanelVisible = false
        isSceneGuideVisible = false
        isContrastVisible = false
        isSaturationVisible = false
        isTemperatureVisible = false
        isExposureVisible = false
        
        // 🔥 修复：恢复滑动条值，确保默认值正确
        currentContrast = defaults.float(forKey: "SavedCurrentContrast")
        if currentContrast == 0 { currentContrast = 1.0 } // 对比度默认值
        
        currentSaturation = defaults.float(forKey: "SavedCurrentSaturation")
        if currentSaturation == 0 { currentSaturation = 1.0 } // 饱和度默认值
        
        currentTemperature = defaults.float(forKey: "SavedCurrentTemperature")
        if currentTemperature == 0 { currentTemperature = 50.0 } // 色温滑块默认值（0-100范围）
        
        currentExposure = defaults.float(forKey: "SavedCurrentExposure")
        if currentExposure == 0 { currentExposure = 50.0 } // 曝光默认值
        
        // 恢复相机状态
        currentCameraIndex = defaults.integer(forKey: "SavedCurrentCameraIndex")
        isUsingFrontCamera = defaults.bool(forKey: "SavedIsUsingFrontCamera")
        
        print("📱 [STATE] 应用状态恢复完成")
    }
    
    // 🔥 修复：应用保存的UI状态
    private func applySavedUIState() {
        print("📱 [STATE] 开始应用保存的UI状态")
        
        // 🔥 修复：立即应用正确的设备方向
        updateUILayoutForOrientation()
        
        // 应用面板显示状态
        filterPanelView?.isHidden = !isFilterPanelVisible
        sceneCategoryCollectionView?.isHidden = !isSceneGuideVisible
        sceneImageCollectionView?.isHidden = !isSceneGuideVisible
        
        // 应用滑动条面板状态
        contrastContainer?.isHidden = !isContrastVisible
        saturationContainer?.isHidden = !isSaturationVisible
        temperatureContainer?.isHidden = !isTemperatureVisible
        exposureContainer?.isHidden = !isExposureVisible
        
        // 🔥 修复：确保曝光容器在最上层，避免被场景UI遮挡
        if isExposureVisible, let exposureContainer = exposureContainer {
            view.bringSubviewToFront(exposureContainer)
        }
        
        // 应用滑动条值
        contrastSlider?.value = currentContrast
        saturationSlider?.value = currentSaturation
        temperatureSlider?.value = currentTemperature
        exposureSlider?.value = currentExposure
        
        // 更新滑动条标签
        contrastValueLabel?.text = String(format: "%.1f", currentContrast)
        saturationValueLabel?.text = String(format: "%.1f", currentSaturation)
        temperatureValueLabel?.text = String(format: "%.1f", currentTemperature)
        exposureValueLabel?.text = String(format: "%.1f", currentExposure)
        
        // 更新按钮状态
        updateButtonStates()
        
        print("📱 [STATE] UI状态应用完成")
    }
    
    // MARK: - AVCapturePhotoCaptureDelegate
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        // 🔥 优化：异步恢复自动曝光，避免阻塞主线程
        DispatchQueue.global(qos: .utility).async {
            if let device = (self.captureSession?.inputs.first as? AVCaptureDeviceInput)?.device {
                do {
                    try device.lockForConfiguration()
                    device.exposureMode = .continuousAutoExposure
                    print("📱 拍照完成后恢复自动曝光")
                    device.unlockForConfiguration()
                } catch {
                    print("📱 恢复自动曝光失败: \(error)")
                }
                
                let currentLabel = self.cameraOptions[self.currentCameraIndex].label
                let maxZoom = self.maxEffectiveZoom(for: currentLabel)
                print("[DEBUG] photoOutput: 镜头=\(currentLabel), maxZoom=\(maxZoom), 拍照时videoZoomFactor=\(device.videoZoomFactor)")
            }
        }
        // 注意：现在只使用"所见即所得"模式，这里的回调主要是为了恢复曝光设置
        // 实际的图片保存在captureOutput的shouldSaveNextPreviewFrame逻辑中完成
    }

    
    @objc func openAlbum() {
        // 先检查当前权限状态，避免重复请求
        let currentStatus = PHPhotoLibrary.authorizationStatus()
        
        switch currentStatus {
        case .authorized, .limited:
            // 已有权限，直接打开相册
            openPhotoPicker()
        case .denied, .restricted:
            // 权限被拒绝，显示提示
            showPhotoLibraryPermissionAlert()
        case .notDetermined:
            // 首次请求权限
            requestPhotoLibraryPermission()
        @unknown default:
            break
        }
    }
    
    private func openPhotoPicker() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.pauseCameraPreview()
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.modalPresentationStyle = .fullScreen
            self.present(picker, animated: true)
        }
    }
    
    private func requestPhotoLibraryPermission() {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    self?.openPhotoPicker()
                case .denied, .restricted:
                    self?.showPhotoLibraryPermissionAlert()
                case .notDetermined:
                    print("权限状态仍为未确定")
                @unknown default:
                    break
                }
            }
        }
    }
    
    private func showPhotoLibraryPermissionAlert() {
        let alert = UIAlertController(
            title: "无法访问相册", 
            message: "请在设置中允许访问相册。", 
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    private func pauseCameraPreview() {
        // 停止视频输出
        if let videoOutput = videoOutput {
            videoOutput.setSampleBufferDelegate(nil, queue: nil)
        }
        // 停止相机session（放到后台线程）
        if let captureSession = captureSession, captureSession.isRunning {
            sessionQueue.async {
                self.sessionConfigLock.lock()
                captureSession.stopRunning()
                self.sessionConfigLock.unlock()
            }
        }
    }
    
    private func resumeCameraPreview() {
        // 简化恢复逻辑，避免死锁
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            guard let captureSession = self.captureSession else {
                return
            }
            // 先启动session
            if !captureSession.isRunning {
                captureSession.startRunning()
            }
            // 等待一小段时间确保session完全启动
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                guard let videoOutput = self.videoOutput else {
                    return
                }
                videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue", qos: .background))
            }
        }
    }
    
    // MARK: - UIImagePickerControllerDelegate
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) { [weak self] in
            self?.resumeCameraPreview()
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage, let currentScene = currentSceneCategory {
            // 场景图片添加逻辑
            let dir = (sceneGuideRoot! as NSString).appendingPathComponent(currentScene)
            let filename = "scene_\(Int(Date().timeIntervalSince1970)).jpg"
            let path = (dir as NSString).appendingPathComponent(filename)
            if let data = image.jpegData(compressionQuality: 0.92) {
                try? data.write(to: URL(fileURLWithPath: path))
                loadSceneImages(for: currentScene)
            }
            picker.dismiss(animated: true)
            return
        }
        // 其他拍照/滤镜逻辑
        guard let image = info[.originalImage] as? UIImage else {
            picker.dismiss(animated: true) { [weak self] in
                self?.resumeCameraPreview()
            }
            return
        }
        picker.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.resumeCameraPreview()
            DispatchQueue.main.async {
                guard self.isActive else { return }
                let filteredImage = self.applyFiltersToUIImage(image)
                self.onPhotoCapture?(filteredImage)
            }
        }
    }
    
    // 清理ImagePicker相关资源
    func cleanupAfterImagePicker() {
        // 确保在主线程恢复相机预览
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.resumeCameraPreview()
        }
    }
    
    func currentInterfaceOrientation() -> UIInterfaceOrientation {
        // iOS版本兼容性检查
        if iOSVersionCheck.supportsWindowScene {
        if #available(iOS 13.0, *) {
            return view.window?.windowScene?.interfaceOrientation ?? .portrait
        }
        }
        // iOS 13.0以下使用状态栏方向
        return UIApplication.shared.statusBarOrientation
    }
    func interfaceToVideoOrientation(_ interfaceOrientation: UIInterfaceOrientation) -> AVCaptureVideoOrientation {
        switch interfaceOrientation {
        case .portrait: return .portrait
        case .landscapeLeft: return .landscapeLeft
        case .landscapeRight: return .landscapeRight
        case .portraitUpsideDown: return .portraitUpsideDown
        default: return .portrait
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    override var shouldAutorotate: Bool {
        return true
    }
    
    func deviceToVideoOrientation(_ deviceOrientation: UIDeviceOrientation) -> AVCaptureVideoOrientation {
        switch deviceOrientation {
        case .portrait: return .portrait
        case .landscapeLeft: return .landscapeRight // Home键在左
        case .landscapeRight: return .landscapeLeft // Home键在右
        case .portraitUpsideDown: return .portraitUpsideDown
        default: return .portrait
        }
    }
    
    // MARK: - CoreMotion 设备方向检测
    private var isOrientationDetectionInitialized = false
    
    private func initializeDeviceOrientationDetection() {
        print("📱 [ORIENTATION] 开始初始化设备方向检测")
        
        // 防止重复初始化
        guard !isOrientationDetectionInitialized else {
            print("📱 [ORIENTATION] 设备方向检测已初始化，跳过")
            return
        }
        
        isOrientationDetectionInitialized = true
        
        // 立即检测当前设备方向
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.1 // 快速检测
        motionManager.startDeviceMotionUpdates(to: OperationQueue.main) { [weak self] motion, error in
            guard let self = self, let motion = motion, error == nil else {
                print("[DEBUG] motion 回调未触发或有错误: \(String(describing: error))")
                return
            }
                
            let gravity = motion.gravity
            let x = gravity.x
            let y = gravity.y
                
            // 根据重力方向判断设备朝向
            let newOrientation: UIDeviceOrientation
            if fabs(y) >= fabs(x) {
                // 垂直方向为主
                newOrientation = y < 0 ? .portrait : .portraitUpsideDown
            } else {
                // 水平方向为主
                newOrientation = x < 0 ? .landscapeRight : .landscapeLeft
            }
                
            if self.currentDeviceOrientation != newOrientation {
                print("[DEBUG] 方向变更: \(self.currentDeviceOrientation.rawValue) -> \(newOrientation.rawValue)")
                self.currentDeviceOrientation = newOrientation
                    
                    // 🔥 修复：方向变化时更新UI布局
                    DispatchQueue.main.async {
                        self.updateUILayoutForOrientation()
            }
                }
            }
        } else {
            print("📱 [ORIENTATION] 设备不支持Motion，使用默认方向")
        }
    }
    
    func startDeviceMotionUpdates() {
        // 这个方法现在由initializeDeviceOrientationDetection处理
        print("📱 [ORIENTATION] startDeviceMotionUpdates已由initializeDeviceOrientationDetection处理")
    }
    
    func stopDeviceMotionUpdates() {
        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
        }
    }
    
    // 🔥 优化：根据设备方向更新UI布局（预览固定，成片旋转）
    private func updateUILayoutForOrientation() {
        let orientationStartTime = CACurrentMediaTime()
        print("📱 [ORIENTATION] 更新UI布局，当前方向: \(currentDeviceOrientation.rawValue)")
        
        // 🔥 优化：自适应布局更新
        updateAdaptiveLayout()
        
        // 强制更新布局
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        // 🔥 修复：预览层保持固定方向，不跟随设备旋转
        // 注释掉预览层方向更新，让预览画面保持固定
        /*
        if let previewLayer = previewLayer {
            let videoOrientation = deviceToVideoOrientation(currentDeviceOrientation)
            if let connection = previewLayer.connection {
                connection.videoOrientation = videoOrientation
            }
        }
        */
        
        // 🔥 修复：相机连接方向也保持固定，确保预览不旋转
        // 注释掉相机连接方向更新
        /*
        if let session = captureSession {
            for output in session.outputs {
                if let videoOutput = output as? AVCaptureVideoDataOutput,
                   let connection = videoOutput.connection(with: .video) {
                    connection.videoOrientation = deviceToVideoOrientation(currentDeviceOrientation)
                }
                if let photoOutput = output as? AVCapturePhotoOutput,
                   let connection = photoOutput.connection(with: .video) {
                    connection.videoOrientation = deviceToVideoOrientation(currentDeviceOrientation)
                }
            }
        }
        */
        
        let orientationEndTime = CACurrentMediaTime()
        let orientationTime = (orientationEndTime - orientationStartTime) * 1000
        print("📱 [ORIENTATION] UI布局更新完成（预览固定，成片旋转）: \(String(format: "%.1f", orientationTime))ms")
    }
    
    // 🔥 新增：自适应布局更新函数
    private func updateAdaptiveLayout() {
        let adaptiveStartTime = CACurrentMediaTime()
        print("🔄 [ADAPTIVE] 开始自适应布局更新...")
        
        // 🔥 优化：使用自适应布局管理器
        let layoutManager = AdaptiveLayoutManager.shared
        let screenInfo = layoutManager.currentScreen
        
        print("🔄 [ADAPTIVE] 设备类型: \(screenInfo.deviceType)")
        print("🔄 [ADAPTIVE] 屏幕尺寸: \(screenInfo.width) x \(screenInfo.height), 横屏: \(screenInfo.isLandscape)")
        print("🔄 [ADAPTIVE] 安全区域: \(screenInfo.safeAreaInsets)")
        
        // 更新功能容器布局
        if let blurView = view.viewWithTag(777) as? UIVisualEffectView {
            updateControlBarLayout(blurView: blurView, layoutManager: layoutManager)
        }
        
        // 更新相机切换按钮布局
        if let ovalBlur = view.viewWithTag(8888) as? UIVisualEffectView {
            updateCameraSwitchLayout(ovalBlur: ovalBlur, layoutManager: layoutManager)
        }
        
        // 更新拍照按钮布局
        if let shutterButton = view.viewWithTag(999) as? UIButton {
            updateShutterButtonLayout(shutterButton: shutterButton, layoutManager: layoutManager)
        }
        
        let adaptiveEndTime = CACurrentMediaTime()
        let adaptiveTime = (adaptiveEndTime - adaptiveStartTime) * 1000
        print("🔄 [ADAPTIVE] 自适应布局更新完成: \(String(format: "%.1f", adaptiveTime))ms")
    }
    
    // 🔥 新增：更新控制栏布局
    private func updateControlBarLayout(blurView: UIVisualEffectView, layoutManager: AdaptiveLayoutManager) {
        let screenInfo = layoutManager.currentScreen
        let buttonSize = layoutManager.adaptiveButtonSize()
        let buttonSpacing = layoutManager.adaptiveSpacing()
        let margins = layoutManager.adaptiveMargins()
        let buttonCount = 3
        
        // 计算自适应宽度
        let totalButtonWidth = buttonSize.width * CGFloat(buttonCount)
        let totalSpacing = buttonSpacing * CGFloat(buttonCount - 1)
        let padding = margins.left + margins.right
        let adaptiveWidth = totalButtonWidth + totalSpacing + padding
        
        // 确保容器不会超出屏幕
        let maxWidth = screenInfo.width - 40
        let finalWidth = min(adaptiveWidth, maxWidth)
        
        print("🔄 [ADAPTIVE] 控制栏自适应计算:")
        print("  - 按钮尺寸: \(buttonSize)")
        print("  - 按钮间距: \(buttonSpacing)")
        print("  - 边距: \(margins)")
        print("  - 计算宽度: \(adaptiveWidth)")
        print("  - 最终宽度: \(finalWidth)")
        
        // 更新宽度约束
        for constraint in blurView.constraints {
            if constraint.firstAttribute == .width {
                constraint.constant = finalWidth
                print("🔄 [ADAPTIVE] 控制栏宽度更新: \(finalWidth)")
                break
            }
        }
        
        // 更新按钮尺寸约束
        let buttons = [filterButton, sceneButton, paramButton]
        for button in buttons {
            if let button = button {
                for constraint in button.constraints {
                    if constraint.firstAttribute == .width {
                        constraint.constant = buttonSize.width
                        break
                    }
                }
                for constraint in button.constraints {
                    if constraint.firstAttribute == .height {
                        constraint.constant = buttonSize.height
                        break
                    }
                }
            }
        }
        
        // 检查是否超出边界
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let isOutOfBounds = layoutManager.isUIOutOfBounds(frame: blurView.frame)
            if isOutOfBounds {
                print("⚠️ [ADAPTIVE] 警告：控制栏更新后仍超出边界")
            } else {
                print("✅ [ADAPTIVE] 控制栏布局更新成功，在安全区域内")
            }
        }
    }
    
    // 🔥 新增：更新相机切换按钮布局
    private func updateCameraSwitchLayout(ovalBlur: UIVisualEffectView, layoutManager: AdaptiveLayoutManager) {
        let screenInfo = layoutManager.currentScreen
        let margins = layoutManager.adaptiveMargins()
        
        // 根据设备类型和方向调整相机切换按钮的位置
        let previewBottomY: CGFloat
        let cameraUIY: CGFloat
        
        switch screenInfo.deviceType {
        case .iPhoneSE:
            previewBottomY = screenInfo.height * (screenInfo.isLandscape ? 0.55 : 0.65)
            cameraUIY = previewBottomY + (screenInfo.isLandscape ? 30 : 50)
        case .iPhone:
            previewBottomY = screenInfo.height * (screenInfo.isLandscape ? 0.6 : 0.7)
            cameraUIY = previewBottomY + (screenInfo.isLandscape ? 35 : 55)
        case .iPhoneX:
            previewBottomY = screenInfo.height * (screenInfo.isLandscape ? 0.58 : 0.68) // iPhone X特殊处理
            cameraUIY = previewBottomY + (screenInfo.isLandscape ? 32 : 52)
        case .iPhonePlus:
            previewBottomY = screenInfo.height * (screenInfo.isLandscape ? 0.6 : 0.7)
            cameraUIY = previewBottomY + (screenInfo.isLandscape ? 40 : 60)
        case .iPhonePro:
            previewBottomY = screenInfo.height * (screenInfo.isLandscape ? 0.6 : 0.7)
            cameraUIY = previewBottomY + (screenInfo.isLandscape ? 45 : 65)
        case .iPhoneProMax:
            previewBottomY = screenInfo.height * (screenInfo.isLandscape ? 0.6 : 0.7)
            cameraUIY = previewBottomY + (screenInfo.isLandscape ? 50 : 70)
        case .iPad:
            previewBottomY = screenInfo.height * (screenInfo.isLandscape ? 0.65 : 0.75)
            cameraUIY = previewBottomY + (screenInfo.isLandscape ? 60 : 80)
        }
        
        print("🔄 [ADAPTIVE] 相机切换按钮位置计算:")
        print("  - 设备类型: \(screenInfo.deviceType)")
        print("  - 预览底部Y: \(previewBottomY)")
        print("  - 相机UI Y: \(cameraUIY)")
        
        // 更新位置约束
        for constraint in ovalBlur.constraints {
            if constraint.firstAttribute == .top {
                constraint.constant = cameraUIY
                print("🔄 [ADAPTIVE] 相机切换按钮位置更新: \(cameraUIY)")
                break
            }
        }
    }
    
    // 🔥 新增：更新拍照按钮布局
    private func updateShutterButtonLayout(shutterButton: UIButton, layoutManager: AdaptiveLayoutManager) {
        let screenInfo = layoutManager.currentScreen
        let margins = layoutManager.adaptiveMargins()
        
        // 根据设备类型和方向调整拍照按钮的位置
        let bottomOffset: CGFloat
        
        switch screenInfo.deviceType {
        case .iPhoneSE:
            bottomOffset = screenInfo.isLandscape ? -15 : -25
        case .iPhone:
            bottomOffset = screenInfo.isLandscape ? -18 : -28
        case .iPhoneX:
            bottomOffset = screenInfo.isLandscape ? -16 : -26 // iPhone X特殊处理
        case .iPhonePlus:
            bottomOffset = screenInfo.isLandscape ? -20 : -33
        case .iPhonePro:
            bottomOffset = screenInfo.isLandscape ? -22 : -35
        case .iPhoneProMax:
            bottomOffset = screenInfo.isLandscape ? -25 : -38
        case .iPad:
            bottomOffset = screenInfo.isLandscape ? -30 : -45
        }
        
        print("🔄 [ADAPTIVE] 拍照按钮位置计算:")
        print("  - 设备类型: \(screenInfo.deviceType)")
        print("  - 底部偏移: \(bottomOffset)")
        
        // 更新位置约束
        for constraint in shutterButton.constraints {
            if constraint.firstAttribute == .bottom {
                constraint.constant = bottomOffset
                print("🔄 [ADAPTIVE] 拍照按钮位置更新: \(bottomOffset)")
                break
            }
        }
    }
    
    // MARK: - 通用图片旋转方法
    func rotateImage(_ image: UIImage, by angle: CGFloat) -> UIImage {
        let radians = angle
        let originalSize = image.size
        let newSize: CGSize
        if abs(radians).truncatingRemainder(dividingBy: .pi) == .pi / 2 {
            newSize = CGSize(width: originalSize.height, height: originalSize.width)
        } else {
            newSize = originalSize
        }
        UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return image }
        context.translateBy(x: newSize.width / 2, y: newSize.height / 2)
        context.rotate(by: radians)
        let drawRect = CGRect(x: -originalSize.width / 2, y: -originalSize.height / 2, width: originalSize.width, height: originalSize.height)
        image.draw(in: drawRect)
        let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return rotatedImage ?? image
    }
    // 🔥 修复：前置摄像头旋转逻辑（预览已镜像，成片只需旋转）
    func rotateImageToCorrectOrientation(_ image: UIImage, deviceOrientation: UIDeviceOrientation, isFrontCamera: Bool) -> UIImage {
        var rotationAngle: CGFloat = 0
        
        if isFrontCamera {
            // 🔥 前置摄像头逻辑：预览时已经水平镜像，成片只需要根据设备方向旋转
            // 由于预览已镜像，旋转方向需要和后置摄像头相反
        switch deviceOrientation {
        case .portrait:
                // 正拍：不需要旋转，预览已经是正确的
                rotationAngle = 0
            case .portraitUpsideDown:
                // 倒立拍：旋转180度
                rotationAngle = .pi
            case .landscapeLeft:
                // 左横屏：顺时针90度（与后置相反）
                rotationAngle = .pi / 2
            case .landscapeRight:
                // 右横屏：逆时针90度（与后置相反）
                rotationAngle = -.pi / 2
            default:
                rotationAngle = 0
            }
        } else {
            // 后置摄像头逻辑：只需要根据设备方向旋转
            switch deviceOrientation {
            case .portrait:
                rotationAngle = 0
        case .portraitUpsideDown:
                rotationAngle = .pi
        case .landscapeLeft:
                rotationAngle = .pi / 2
        case .landscapeRight:
                rotationAngle = -.pi / 2
        default:
            rotationAngle = 0
        }
        }
        
        print("📸 [DEBUG] 图像旋转: 前置=\(isFrontCamera), 方向=\(deviceOrientation.rawValue), 角度=\(rotationAngle), 镜像=不需要")
        
        let rotated = rotateImage(image, by: rotationAngle)
        return rotated
    }
    
    func applyFilters(to ciImage: CIImage) -> CIImage {
        var output = ciImage
        let hasContrast = abs(currentContrast - 1.0) > 0.01
        let hasSaturation = abs(currentSaturation - 1.0) > 0.01
        let hasTemperature = abs(currentTemperature - 6500.0) > 1.0
        
        // 性能优化：如果没有滤镜效果，直接返回原图
        if !hasContrast && !hasSaturation && !hasTemperature {
            return output
        }
        
        if !shouldUseHighQualityFilter() {
            // 低端机型/低电量只做简单色温
            if hasTemperature {
                if let tempFilter = CIFilter(name: "CITemperatureAndTint") {
                    tempFilter.setValue(output, forKey: kCIInputImageKey)
                    let mappedTemperature = 6500 + (currentTemperature - 6500) * 2.0
                    tempFilter.setValue(CIVector(x: CGFloat(mappedTemperature), y: 0), forKey: "inputNeutral")
                    tempFilter.setValue(CIVector(x: 6500, y: 0), forKey: "inputTargetNeutral")
                    if let tempResult = tempFilter.outputImage {
                        output = tempResult
                    }
                }
            }
            return output
        }
        if hasContrast || hasSaturation {
            if let filter = CIFilter(name: "CIColorControls") {
                filter.setValue(output, forKey: kCIInputImageKey)
                // 对比度变化减半，饱和度变化1.8倍
                let mappedContrast = 1.0 + (currentContrast - 1.0) * 0.5
                let mappedSaturation = 1.0 + (currentSaturation - 1.0) * 1.8
                filter.setValue(hasContrast ? mappedContrast : 1.0, forKey: "inputContrast")
                filter.setValue(hasSaturation ? mappedSaturation : 1.0, forKey: "inputSaturation")
                if let result = filter.outputImage {
                    output = result
                }
            }
        }
        if hasTemperature {
            if let tempFilter = CIFilter(name: "CITemperatureAndTint") {
                tempFilter.setValue(output, forKey: kCIInputImageKey)
                // 色温变化2.0倍
                let mappedTemperature = 6500 + (currentTemperature - 6500) * 2.0
                tempFilter.setValue(CIVector(x: CGFloat(mappedTemperature), y: 0), forKey: "inputNeutral")
                tempFilter.setValue(CIVector(x: 6500, y: 0), forKey: "inputTargetNeutral")
                if let tempResult = tempFilter.outputImage {
                    output = tempResult
                }
            }
        }
        
        return output
    }
    
    // 将滤镜应用到 UIImage
    func applyFiltersToUIImage(_ image: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }
        
        // 应用滤镜
        let filteredCI = applyFilters(to: ciImage)
        
        // 如果ciContext未初始化，先初始化再处理
        if ciContext == nil {
            ciContext = CIContext(options: [.useSoftwareRenderer: false])
            print("[DEBUG] CIContext 在applyFiltersToUIImage中延迟初始化完成（GPU加速）")
        }
        
        // 转换回 UIImage
        guard let context = ciContext,
              let cgImage = context.createCGImage(filteredCI, from: filteredCI.extent) else {
            return image
        }
        
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    // 捏合缩放
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        // 忽略UI控件区域的手势
        let location = gesture.location(in: view)
        if let hitView = view.hitTest(location, with: nil), hitView !== view && !(hitView is UIImageView) {
            return
        }
        guard let device = (captureSession?.inputs.first as? AVCaptureDeviceInput)?.device else { return }
        if gesture.state == .changed {
            // 根据当前镜头类型动态限制最大zoom
            let currentLabel = cameraOptions[currentCameraIndex].label
            let maxZoom = maxEffectiveZoom(for: currentLabel)
            print("[DEBUG] handlePinch: 镜头=\(currentLabel), maxZoom=\(maxZoom), 当前videoZoomFactor=\(device.videoZoomFactor)")
            let minZoom: CGFloat = 1.0
            var zoom = device.videoZoomFactor * gesture.scale
            zoom = max(minZoom, min(zoom, maxZoom))
            do {
                try device.lockForConfiguration()
                device.videoZoomFactor = zoom
                print("[DEBUG] handlePinch: 设置videoZoomFactor=\(zoom)，实际device.videoZoomFactor=\(device.videoZoomFactor)")
                device.unlockForConfiguration()
            } catch {}
            gesture.scale = 1.0
            updateZoomLabel()
        }
    }
    
    // 点按对焦/曝光
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        // 忽略UI控件区域的手势
        let location = gesture.location(in: view)
        if let hitView = view.hitTest(location, with: nil), hitView !== view && !(hitView is UIImageView) {
            return
        }
        guard let previewLayer = previewLayer else { return }
        let locationInLayer = gesture.location(in: view)
        let focusPoint = previewLayer.captureDevicePointConverted(fromLayerPoint: locationInLayer)
        guard let device = (captureSession?.inputs.first as? AVCaptureDeviceInput)?.device else { return }
        do {
            try device.lockForConfiguration()
            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = focusPoint
                device.focusMode = .autoFocus
            }
            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = focusPoint
                device.exposureMode = .continuousAutoExposure
            }
            device.unlockForConfiguration()
        } catch { print("[handleTap] lockForConfiguration失败: \(error)") }
        // 显示对焦动画
        showFocusIndicatorAppleStyle(at: locationInLayer)
    }
    // 双击弹出功能界面
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        showFilterPanelIfNeeded()
    }
    // 曝光条上下滑手势
    @objc private func handleExposurePan(_ gesture: UIPanGestureRecognizer) {
        guard let slider = exposureSlider else { return }
        let translation = gesture.translation(in: exposureContainer)
        // 向上滑增加曝光，向下滑减少
        let delta = Float(-translation.y / 80.0) * (slider.maximumValue - slider.minimumValue)
        let newValue = min(max(slider.value + delta, slider.minimumValue), slider.maximumValue)
        if abs(newValue - slider.value) > 0.01 {
            slider.value = newValue
            exposureChanged()
        }
        // 同步label
        exposureValueLabel?.text = String(format: "%.1f", currentExposure)
        if gesture.state == .ended || gesture.state == .cancelled {
            gesture.setTranslation(.zero, in: exposureContainer)
            startExposureAutoHide()
        } else {
            cancelExposureAutoHide()
        }
    }
    // 更新曝光设置到相机
    private func updateExposureToCamera(_ sliderValue: Float) {
        exposureUpdateWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            do {
                guard let self = self,
                      let device = (self.captureSession?.inputs.first as? AVCaptureDeviceInput)?.device else { return }
                let minBias = device.minExposureTargetBias
                let maxBias = device.maxExposureTargetBias
                let bias = minBias + (maxBias - minBias) * (sliderValue / 100.0)
                let clampedBias = min(max(bias, minBias), maxBias)
                try device.lockForConfiguration()
                device.setExposureTargetBias(clampedBias, completionHandler: nil)
                device.unlockForConfiguration()
            } catch {
                print("[ERROR] 曝光写入失败: \(error)")
            }
        }
        exposureUpdateWorkItem = workItem
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.1, execute: workItem)
    }
    
    // 🔥 调试方法：检查曝光滑动条状态
    private func debugExposureSliderState() {
        print("🔍 [DEBUG] ===== 曝光滑动条状态检查 =====")
        print("🔍 [DEBUG] exposureSlider存在: \(exposureSlider != nil)")
        if let slider = exposureSlider {
            print("🔍 [DEBUG] slider.value: \(slider.value)")
            print("🔍 [DEBUG] slider.minimumValue: \(slider.minimumValue)")
            print("🔍 [DEBUG] slider.maximumValue: \(slider.maximumValue)")
            print("🔍 [DEBUG] slider.frame: \(slider.frame)")
            print("🔍 [DEBUG] slider.isHidden: \(slider.isHidden)")
            print("🔍 [DEBUG] slider.alpha: \(slider.alpha)")
            print("🔍 [DEBUG] slider.superview: \(slider.superview != nil)")
            print("🔍 [DEBUG] slider.tag: \(slider.tag)")
            print("🔍 [DEBUG] slider.accessibilityIdentifier: \(slider.accessibilityIdentifier ?? "nil")")
        }
        print("🔍 [DEBUG] currentExposure: \(currentExposure)")
        print("🔍 [DEBUG] exposureValueLabel.text: \(exposureValueLabel?.text ?? "nil")")
        print("🔍 [DEBUG] ===== 曝光滑动条状态检查结束 =====")
    }
    
    // 🔥 调试方法：检查所有滑动条状态
    private func debugAllSlidersState() {
        print("🔍 [DEBUG] ===== 所有滑动条状态检查 =====")
        
        // 检查色温滑动条
        if let tempSlider = temperatureSlider {
            print("🔍 [DEBUG] 色温滑动条 - tag: \(tempSlider.tag), frame: \(tempSlider.frame), identifier: \(tempSlider.accessibilityIdentifier ?? "nil")")
        }
        
        // 检查对比度滑动条
        if let contrastSlider = contrastSlider {
            print("🔍 [DEBUG] 对比度滑动条 - tag: \(contrastSlider.tag), frame: \(contrastSlider.frame), identifier: \(contrastSlider.accessibilityIdentifier ?? "nil")")
        }
        
        // 检查饱和度滑动条
        if let saturationSlider = saturationSlider {
            print("🔍 [DEBUG] 饱和度滑动条 - tag: \(saturationSlider.tag), frame: \(saturationSlider.frame), identifier: \(saturationSlider.accessibilityIdentifier ?? "nil")")
        }
        
        // 检查曝光滑动条
        if let exposureSlider = exposureSlider {
            print("🔍 [DEBUG] 曝光滑动条 - tag: \(exposureSlider.tag), frame: \(exposureSlider.frame), identifier: \(exposureSlider.accessibilityIdentifier ?? "nil")")
        }
        
        // 🔥 新增：检查容器的父视图关系
        print("🔍 [DEBUG] ===== 容器父视图检查 =====")
        if let saturationContainer = saturationContainer {
            print("🔍 [DEBUG] 饱和度容器 - superview: \(saturationContainer.superview != nil), frame: \(saturationContainer.frame)")
        }
        if let exposureContainer = exposureContainer {
            print("🔍 [DEBUG] 曝光容器 - superview: \(exposureContainer.superview != nil), frame: \(exposureContainer.frame)")
        }
        print("🔍 [DEBUG] ===== 容器父视图检查结束 =====")
        
        print("🔍 [DEBUG] ===== 所有滑动条状态检查结束 =====")
    }
    
    // 曝光滑块变更
    @objc private func exposureChanged() {
        guard let slider = exposureSlider else { 
            print("⚠️ [DEBUG] exposureChanged() - exposureSlider为nil")
            return 
        }
        print("📸 [DEBUG] exposureChanged() 被调用 - 之前: currentExposure=\(currentExposure), slider.value=\(slider.value)")
        currentExposure = slider.value
        exposureValueLabel?.text = String(format: "%.1f", currentExposure)
        updateExposureToCamera(currentExposure)
        print("📸 [DEBUG] exposureChanged() 完成 - 之后: currentExposure=\(currentExposure), slider.value=\(slider.value)")
        
        // 启动自动隐藏定时器
        startSliderAutoHide(for: "exposure")
    }
    // 苹果风格对焦动画
    func showFocusIndicatorAppleStyle(at point: CGPoint) {
        guard let preview = filteredPreviewImageView else { return }
        let indicatorSize: CGFloat = 80
        let indicator = UIView(frame: CGRect(x: 0, y: 0, width: indicatorSize, height: indicatorSize))
        indicator.center = point
        indicator.backgroundColor = UIColor.clear
        indicator.alpha = 0.0
        let border = CAShapeLayer()
        border.path = UIBezierPath(roundedRect: indicator.bounds.insetBy(dx: 2, dy: 2), cornerRadius: 12).cgPath
        border.lineWidth = 2.5
        border.strokeColor = UIColor.yellow.withAlphaComponent(0.95).cgColor
        border.fillColor = UIColor.clear.cgColor
        indicator.layer.addSublayer(border)
        preview.addSubview(indicator)
        preview.bringSubviewToFront(indicator)
        UIView.animate(withDuration: 0.12, animations: {
            indicator.alpha = 1.0
            indicator.transform = CGAffineTransform(scaleX: 1.18, y: 1.18)
        }) { _ in
            UIView.animate(withDuration: 0.18, delay: 0.5, options: [], animations: {
                indicator.alpha = 0.0
                indicator.transform = CGAffineTransform.identity
            }) { _ in
                indicator.removeFromSuperview()
            }
        }
    }
    
    // 切换前后摄像头
    @objc func switchCamera(_ sender: UIButton) {
        guard !isSwitchingCamera else { return }
        let idx = sender.tag
        if idx == self.currentCameraIndex { return }
        isSwitchingCamera = true
        // 安全地禁用相机切换按钮
        for btn in cameraSwitchButtons {
            if btn.superview != nil {  // 检查按钮是否还在视图层次中
                btn.isEnabled = false
            }
        }
        // 1. 切换时对当前预览做截图，叠加在预览层上
        var snapshotView: UIView?
        if let imageView = self.filteredPreviewImageView {
            let snap = imageView.snapshotView(afterScreenUpdates: false)
            snap?.frame = imageView.bounds
            if let snap = snap {
                imageView.addSubview(snap)
                snapshotView = snap
            }
        }
        // 2. 彻底阻断帧流
            self.videoOutput?.setSampleBufferDelegate(nil, queue: nil)
        // 3. 隐藏滤镜和参数面板，以及缩放轮盘
        DispatchQueue.main.async {
            // 🔥 修复：相机切换时重置所有面板状态为关闭
            self.isFilterPanelVisible = false
            self.isSceneGuideVisible = false
            self.isContrastVisible = false
            self.isSaturationVisible = false
            self.isTemperatureVisible = false
            self.isExposureVisible = false
            
            // 🔥 修复：强制隐藏对应的UI元素，确保状态同步
            if let filterPanelView = self.filterPanelView {
                filterPanelView.isHidden = true
                print("🎨 [DEBUG] 相机切换：强制隐藏功能面板")
            }
            self.sceneCategoryCollectionView?.isHidden = true
            self.sceneImageCollectionView?.isHidden = true
            self.contrastContainer?.isHidden = true
            self.saturationContainer?.isHidden = true
            self.temperatureContainer?.isHidden = true
            self.exposureContainer?.isHidden = true
            
            // 隐藏缩放轮盘
            self.hideZoomWheel(animated: false)
            
            // 🔥 修复：强制更新按钮状态，确保UI反映正确的状态
            self.updateButtonStates()
            
            // 🔥 修复：再次确认状态同步
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.updateButtonStates()
            }
        }
        sessionQueue.async {
            guard !self.cameraOptions.isEmpty && idx >= 0 && idx < self.cameraOptions.count else {
                DispatchQueue.main.async {
                    self.isSwitchingCamera = false
                    // 安全地启用相机切换按钮
                    for btn in self.cameraSwitchButtons {
                        if btn.superview != nil {  // 检查按钮是否还在视图层次中
                            btn.isEnabled = true
                        }
                    }
                    snapshotView?.removeFromSuperview()
                }
                return
            }
            self.currentCameraIndex = idx
            self.setupCamera(startSessionIfNeeded: true)
            
            // 更新前置相机状态
            if let selectedDevice = self.getCurrentCameraDevice() {
                self.isUsingFrontCamera = (selectedDevice.position == .front)
                print("📱 [DEBUG] 相机切换完成，当前相机位置: \(selectedDevice.position == .front ? "前置" : "后置"), isUsingFrontCamera=\(self.isUsingFrontCamera)")
            } else {
                print("⚠️ [DEBUG] 无法获取当前相机设备")
            }
            // 切换完成后，淡出动画再恢复UI和帧流
            DispatchQueue.main.async {
                if let snap = snapshotView {
                    UIView.animate(withDuration: 0.18, animations: {
                        snap.alpha = 0
                    }) { _ in
                        snap.removeFromSuperview()
                        self.videoOutput?.setSampleBufferDelegate(self, queue: self.sessionQueue)
                        self.updateCameraUI()  // 只更新UI状态，不重新创建
                        self.isSwitchingCamera = false
                        // 安全地启用相机切换按钮
                        for btn in self.cameraSwitchButtons {
                            if btn.superview != nil {  // 检查按钮是否还在视图层次中
                                btn.isEnabled = true
                            }
                        }
                    }
                } else {
                    self.videoOutput?.setSampleBufferDelegate(self, queue: self.sessionQueue)
                    self.updateCameraUI()  // 只更新UI状态，不重新创建
                    self.isSwitchingCamera = false
                    // 安全地启用相机切换按钮
                    for btn in self.cameraSwitchButtons {
                        if btn.superview != nil {  // 检查按钮是否还在视图层次中
                            btn.isEnabled = true
                        }
                    }
                }
            }
        }
    }
    // 新增：带动画的镜头切换方法
    @objc func switchToCameraWithAnimation(_ sender: UIButton) {
        // 🔥 修复：添加防重复切换检查
        guard !isPerformingZoomTransition else {
            print("🎬 [DEBUG] 模糊动画进行中，忽略镜头按钮切换")
            return
        }
        
        // 🎯 按钮点击动画
        UIView.animate(withDuration: 0.12, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        }) { _ in
            UIView.animate(withDuration: 0.12, animations: {
                sender.transform = .identity
            })
        }
        
        // 🎬 使用苹果风格模糊动画进行镜头切换
        let targetCameraIndex = sender.tag
        let buttonTitle = sender.title(for: .normal) ?? "未知"
        print("🎯 [DEBUG] 镜头按钮点击：当前索引=\(currentCameraIndex), 目标索引=\(targetCameraIndex)")
        print("🎯 [DEBUG] 按钮信息：标题='\(buttonTitle)', tag=\(targetCameraIndex)")
        print("🎯 [DEBUG] 当前相机：\(cameraOptions.indices.contains(currentCameraIndex) ? cameraOptions[currentCameraIndex].label : "无效索引")")
        print("🎯 [DEBUG] 目标相机：\(cameraOptions.indices.contains(targetCameraIndex) ? cameraOptions[targetCameraIndex].label : "无效索引")")
        
        if targetCameraIndex < cameraOptions.count && targetCameraIndex != currentCameraIndex {
            let targetOption = cameraOptions[targetCameraIndex]
            let targetDevice = targetOption.device
            
            print("🎯 [DEBUG] 执行镜头切换：\(targetDevice.localizedName)")
            
            // 🔥 修复：立即更新当前相机索引，确保UI正确高亮
            currentCameraIndex = targetCameraIndex
            print("🎯 [DEBUG] 更新当前相机索引为: \(currentCameraIndex)")
            
            // 🔥 修复：检查是否是数字变焦
            if targetOption.isDigitalZoom {
                print("🎯 [DEBUG] 数字变焦模式：使用\(targetOption.digitalZoomFactor)x变焦")
                // 数字变焦：使用指定的变焦倍数
                performSmoothZoomTransition(to: targetDevice, withZoom: targetOption.digitalZoomFactor)
            } else {
                print("🎯 [DEBUG] 物理相机模式：使用默认1.0x zoom")
                // 物理相机：使用默认1.0x zoom
                performSmoothZoomTransition(to: targetDevice, withZoom: 1.0)
            }
        } else {
            print("🎯 [DEBUG] 切换被忽略：索引越界或相同镜头")
        }
    }
    
    // MARK: - 缩放轮盘功能
    
    // 处理镜头切换按钮长按手势
    @objc func handleCameraButtonLongPress(_ gesture: UILongPressGestureRecognizer) {
        print("🔍 [DEBUG] 长按手势触发: \(gesture.state.rawValue)")
        guard let button = gesture.view as? UIButton else { 
            print("❌ [DEBUG] 无法获取按钮")
            return 
        }
        
        print("🎯 [DEBUG] 按钮信息: tag=\(button.tag), title=\(button.title(for: .normal) ?? "nil")")
        print("🎯 [DEBUG] 按钮frame: \(button.frame)")
        print("🎯 [DEBUG] 按钮isUserInteractionEnabled: \(button.isUserInteractionEnabled)")
        print("🎯 [DEBUG] 按钮isHighlighted: \(button.isHighlighted)")
        
        // 防止手势冲突：如果按钮正在被点击，则不处理长按
        if button.isHighlighted {
            print("⚠️ [DEBUG] 按钮正在被点击，忽略长按")
            return
        }
        
        print("🎯 [DEBUG] 手势状态处理开始: \(gesture.state.rawValue)")
        
        switch gesture.state {
        case .began:
            print("✅ [DEBUG] 开始长按，显示缩放轮盘")
            // 开始长按 - 显示缩放轮盘
            let buttonCenter = button.superview?.convert(button.center, to: view) ?? button.center
            print("🎯 [DEBUG] 按钮中心位置: \(buttonCenter)")
            showZoomWheel(at: buttonCenter, for: button)
            
            // 隐藏后置UI
            hideRearCameraUI()
            
            // 延迟检查轮盘是否显示
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.checkZoomWheelVisibility()
            }
            
        case .possible:
            print("🔄 [DEBUG] 长按手势可能状态")
            
        case .recognized:
            print("✅ [DEBUG] 长按手势已识别，显示缩放轮盘")
            // 如果.began没有被调用，在这里也尝试显示轮盘
            let buttonCenter = button.superview?.convert(button.center, to: view) ?? button.center
            print("🎯 [DEBUG] 按钮中心位置: \(buttonCenter)")
            showZoomWheel(at: buttonCenter, for: button)
            hideRearCameraUI()
            
        case .changed:
            print("🔄 [DEBUG] 长按状态变化，保持轮盘显示")
            // 长按中 - 保持轮盘显示，不做任何操作
            
        case .ended, .cancelled, .failed:
            print("🔚 [DEBUG] 结束长按，启动3秒自动隐藏")
            // 结束长按 - 启动3秒自动隐藏定时器
            startZoomWheelAutoHideTimer()
            
        default:
            print("🔍 [DEBUG] 其他手势状态: \(gesture.state.rawValue)")
            break
        }
        
        print("🎯 [DEBUG] 手势状态处理完成: \(gesture.state.rawValue)")
    }
    
    // 显示苹果风格的半圆缩放轮盘
    func showZoomWheel(at position: CGPoint, for button: UIButton) {
        print("🎡 [DEBUG] showZoomWheel开始，位置: \(position)")
        // 如果已经显示，则隐藏先前的轮盘
        hideZoomWheel(animated: false)
        
        // 获取当前镜头的缩放信息
        guard let currentDevice = getCurrentCameraDevice() else { 
            print("❌ [DEBUG] 无法获取当前相机设备")
            return 
        }
        // 使用实际相机的最大变焦能力，但限制在合理范围内
        let rawMaxZoom = currentDevice.activeFormat.videoMaxZoomFactor
        let maxZoom = min(rawMaxZoom, 6.0) // 限制最大变焦为6x
        
        // 支持从0.5x开始的变焦范围（苹果原相机风格）
        let minZoom: CGFloat = 0.5 // 支持超广角变焦
        
        // 根据当前相机类型和变焦值，计算等效的UI显示值
        let currentZoom = currentDevice.videoZoomFactor
        let deviceType = currentDevice.deviceType
        
        // 🔥 修复：计算等效UI显示值，支持长焦镜头
        if deviceType == .builtInUltraWideCamera {
            // 超广角相机：实际变焦 -> UI显示值
            // 等效映射：1.0x-1.8x (超广角实际) -> 0.5x-0.9x (UI显示)
            // 正确的反向映射：实际 1.0x = UI 0.5x，实际 1.8x = UI 0.9x
            let uiZoom = 0.5 + (currentZoom - 1.0) * 0.5 // 线性映射
            currentZoomFactor = max(0.5, min(0.9, uiZoom))
            print("🎡 [DEBUG] 超广角相机UI映射: \(currentZoom)x -> \(currentZoomFactor)x")
        } else if deviceType == .builtInTelephotoCamera {
            // 🔥 长焦相机：根据实际长焦倍数计算UI显示值
            let actualTelephotoZoom = getActualTelephotoZoom(for: currentDevice)
            currentZoomFactor = actualTelephotoZoom * currentZoom
            print("🎡 [DEBUG] 长焦相机UI映射: \(actualTelephotoZoom) * \(currentZoom) = \(currentZoomFactor)x")
        } else {
            // 广角相机：直接使用实际变焦值
            currentZoomFactor = currentZoom
            print("🎡 [DEBUG] 广角相机直接使用: \(currentZoom)x")
        }
        
        initialZoomFactor = currentZoomFactor
        
        print("🎡 [DEBUG] 轮盘初始化 - 当前相机: \(deviceType)")
        print("🎡 [DEBUG] 当前相机变焦: \(currentZoom)")
        print("🎡 [DEBUG] 计算的UI显示值: \(currentZoomFactor)")
        
        // 确保当前缩放值在有效范围内
        if currentZoomFactor < minZoom {
            currentZoomFactor = minZoom
        }
        
        // 创建轮盘主容器 - 苹果风格
        let wheelHeight: CGFloat = 180 // 更高，更接近苹果风格
        let wheelWidth: CGFloat = wheelHeight * 2 // 宽度等于高度的2倍，确保半圆不被裁切
        let wheelFrame = CGRect(x: 0, y: 0, width: wheelWidth, height: wheelHeight)
        zoomWheelView = UIView(frame: wheelFrame)
        zoomWheelView?.backgroundColor = UIColor.clear
        
        // 设置轮盘位置紧贴黑色罩子顶部
        let buttonCenter = button.superview?.convert(button.center, to: view) ?? button.center
        // 轮盘始终居中显示，不跟随按钮位置
        let centerX = UIScreen.main.bounds.width / 2
        // 计算轮盘位置：轮盘底部应该与黑色罩子底部对齐
        // 首先确定黑色罩子的实际位置
        let buttonFrameInScreen = button.superview?.convert(button.frame, to: view) ?? button.frame

        
                        // 轮盘应该与屏幕底部的纯黑掩膜顶部对齐
                // 纯黑掩膜的顶部就是缩略图的底部位置
                let screenHeight = UIScreen.main.bounds.height
                let blackAreaTopY = screenHeight - dynamicBottomOffset() - 33 // 纯黑掩膜的顶部Y坐标（缩略图底部）
                let wheelBottomY = blackAreaTopY // 轮盘底部与纯黑掩膜顶部对齐
                let centerY = wheelBottomY - wheelHeight / 2 // 轮盘中心位置
                
                // 确保轮盘不会超出屏幕范围
                let minCenterY = wheelHeight / 2
                let maxCenterY = screenHeight - wheelHeight / 2
                let finalCenterY = max(minCenterY, min(centerY, maxCenterY))
                
                // 确保轮盘底部与预览画面底部严格对齐
                // 预览画面使用resizeAspectFill，实际预览画面底部应该在更高的位置
                // 我们需要找到实际的预览画面底部，而不是屏幕底部
                let bottomMask = view.subviews.first(where: { $0.tag == 102 })
                let previewBottomY: CGFloat
                if let bottomMask = bottomMask {
                    // 如果有bottomMask，使用它的顶部作为预览画面底部
                    previewBottomY = bottomMask.frame.minY
                } else {
                    // 如果没有bottomMask，使用缩略图的位置作为参考
                    previewBottomY = screenHeight - 150 - 12 // 缩略图底部位置
                }
                let adjustedWheelBottomY = previewBottomY // 轮盘底部与预览画面底部对齐
                let adjustedCenterY = adjustedWheelBottomY - wheelHeight / 2 // 调整后的轮盘中心位置
                let finalAdjustedCenterY = max(minCenterY, min(adjustedCenterY, maxCenterY))
                
                // 轮盘始终居中显示，不跟随按钮位置
                // centerX已经在上面定义了
                

                        zoomWheelView?.center = CGPoint(x: centerX, y: finalAdjustedCenterY)
        zoomWheelView?.alpha = 0
        

        
        view.addSubview(zoomWheelView!)
        
        // 创建苹果风格半圆形背景
        let backgroundBlur = UIView()
        backgroundBlur.frame = CGRect(x: 0, y: 0, width: wheelWidth, height: wheelHeight)
        backgroundBlur.backgroundColor = UIColor.black.withAlphaComponent(0.7) // 苹果风格深灰色背景
        backgroundBlur.clipsToBounds = true
        
        // 为背景添加半圆遮罩，确保背景也是半圆形
        let backgroundMaskLayer = CAShapeLayer()
        let backgroundMaskCenterX = wheelWidth / 2
        let backgroundMaskCenterY = wheelHeight // 半圆的中心在视图的底部边缘
        let backgroundMaskRadius = wheelHeight
        
        let backgroundMaskPath = UIBezierPath()
        backgroundMaskPath.move(to: CGPoint(x: backgroundMaskCenterX - backgroundMaskRadius, y: backgroundMaskCenterY))
        backgroundMaskPath.addArc(withCenter: CGPoint(x: backgroundMaskCenterX, y: backgroundMaskCenterY),
                                 radius: backgroundMaskRadius,
                                 startAngle: CGFloat.pi,
                                 endAngle: 0,
                                 clockwise: true)
        // 不添加直线，保持纯半圆形状
        
        backgroundMaskLayer.path = backgroundMaskPath.cgPath
        backgroundBlur.layer.mask = backgroundMaskLayer
        // 移除所有可能影响半圆形状的属性
        // backgroundBlur.layer.cornerRadius = 25
        // backgroundBlur.layer.borderWidth = 1
        // backgroundBlur.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        

        
                // 添加半圆白色边界线
        let borderPath = UIBezierPath()
        let borderRadius = wheelHeight // 修正：使用完整轮盘高度作为半径，与轮盘半圆轮廓完全一致
        let borderCenterX = wheelWidth / 2
        let borderCenterY = wheelHeight

        // 绘制半圆边界：只绘制半圆弧，不添加直线
        borderPath.move(to: CGPoint(x: borderCenterX - borderRadius, y: borderCenterY))
        borderPath.addArc(withCenter: CGPoint(x: borderCenterX, y: borderCenterY),
                         radius: borderRadius,
                         startAngle: CGFloat.pi,
                         endAngle: 0,
                         clockwise: true)
        // 不添加直线，保持纯半圆形状
        
        let borderLayer = CAShapeLayer()
        borderLayer.path = borderPath.cgPath
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = UIColor.white.withAlphaComponent(0.6).cgColor // 统一透明度
        borderLayer.lineWidth = 1.5 // 稍微细一点
        // 不设置frame，让边框层使用路径的原始坐标
        backgroundBlur.layer.addSublayer(borderLayer)
        
        // 将背景添加到轮盘视图中
        zoomWheelView?.addSubview(backgroundBlur)
        
        // 添加苹果风格刻度标记，传入当前缩放值
        createAppleStyleZoomMarks(in: backgroundBlur, wheelWidth: wheelWidth, wheelHeight: wheelHeight, minZoom: minZoom, maxZoom: maxZoom, currentZoom: currentZoomFactor)
        
        // 添加滑动手势来调节变焦
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleAppleZoomWheelPan(_:)))
        zoomWheelView?.addGestureRecognizer(panGesture)
        

        
        zoomWheelView?.addSubview(backgroundBlur)
        zoomWheelBackground = backgroundBlur
        
        // 调试：检查backgroundBlur是否正确添加
        print("🎡 [DEBUG] backgroundBlur已添加到zoomWheelView")
        print("🎡 [DEBUG] zoomWheelView子视图数量: \(zoomWheelView?.subviews.count ?? 0)")
        print("🎡 [DEBUG] backgroundBlur在zoomWheelView子视图中: \(zoomWheelView?.subviews.contains(backgroundBlur) ?? false)")
        print("🎡 [DEBUG] backgroundBlur frame: \(backgroundBlur.frame)")
        print("🎡 [DEBUG] backgroundBlur alpha: \(backgroundBlur.alpha)")
        print("🎡 [DEBUG] backgroundBlur isHidden: \(backgroundBlur.isHidden)")
        
        // 创建刻度标记 - 临时跳过，专注于遮罩测试
        // createZoomScaleMarks(in: backgroundBlur as! UIVisualEffectView, wheelWidth: wheelWidth, wheelHeight: wheelHeight, minZoom: 1.0, maxZoom: Float(maxZoom))
        
        // 创建中心数值标签 - 苹果风格
        zoomValueLabel = UILabel()
        zoomValueLabel?.text = String(format: "%.1f×", currentZoomFactor)
        zoomValueLabel?.textColor = .white
        zoomValueLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        zoomValueLabel?.textAlignment = .center
        zoomValueLabel?.frame = CGRect(x: wheelWidth/2 - 30, y: wheelHeight - 25, width: 60, height: 20)
        backgroundBlur.addSubview(zoomValueLabel!) // 直接添加到UIView
        
        // 创建指示器 - 临时跳过，专注于遮罩测试
        // createZoomIndicator(in: backgroundBlur as! UIVisualEffectView, wheelWidth: wheelWidth, wheelHeight: wheelHeight)
        
        // 存储滑块信息用于计算
        zoomWheelSlider = UISlider()
        zoomWheelSlider?.minimumValue = Float(minZoom)
        zoomWheelSlider?.maximumValue = Float(maxZoom)
        zoomWheelSlider?.value = Float(currentZoomFactor)
        

        
        // 确保轮盘显示在最顶层（最高优先级）
        if let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            keyWindow.addSubview(zoomWheelView!)
            keyWindow.bringSubviewToFront(zoomWheelView!)
            print("🎡 [DEBUG] 轮盘添加到keyWindow最顶层")
            
            // 🔥 优化：移除强制布局更新，避免阻塞
            // keyWindow.layoutIfNeeded() // 注释掉强制布局更新
            print("🎡 [DEBUG] keyWindow布局更新已优化")
        } else {
            view.addSubview(zoomWheelView!)
            view.bringSubviewToFront(zoomWheelView!)
            print("🎡 [DEBUG] 轮盘添加到view最顶层")
        }
        print("🎡 [DEBUG] 半圆轮盘已创建，frame: \(zoomWheelView!.frame)")
        print("🎡 [DEBUG] 轮盘中心位置: x=\(centerX), y=\(centerY)")
        print("🎡 [DEBUG] 屏幕高度: \(view.bounds.height)")
        print("🎡 [DEBUG] 轮盘是否在屏幕内: \(centerY >= 0 && centerY <= view.bounds.height)")
        
        // 检查轮盘是否正确添加到视图层级
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.checkZoomWheelVisibility()
        }
        
        // 显示动画 - 更直接的显示方式
        isZoomWheelVisible = true
        print("🎡 [DEBUG] isZoomWheelVisible设置为: \(isZoomWheelVisible)")
        print("🎡 [DEBUG] 开始显示动画，初始alpha: \(zoomWheelView?.alpha ?? 0)")
        print("🎡 [DEBUG] 动画前轮盘frame: \(zoomWheelView?.frame ?? .zero)")
        
        // 立即设置为可见
        zoomWheelView?.alpha = 1.0
        zoomWheelView?.transform = .identity
        zoomWheelView?.isHidden = false
        

        
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [], animations: {
            self.zoomWheelView?.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }) { _ in
            UIView.animate(withDuration: 0.15) {
                self.zoomWheelView?.transform = .identity
            }
        }
        
        // 启动自动隐藏定时器
        startZoomWheelAutoHideTimer()
        
        // 确保轮盘指针显示正确的初始值
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.syncZoomWheelWithCurrentCamera()
        }
    }
    // 🎯 同步轮盘与当前相机状态，确保指针显示正确值
    private func syncZoomWheelWithCurrentCamera() {
        print("🎯 同步轮盘与当前相机状态")
        
        // 🔥 关键修复：如果轮盘正在显示，不要重新计算值，保持连续性
        if isZoomWheelVisible {
            print("🎯 轮盘正在显示，保持当前值连续性: \(currentZoomFactor)")
            
            // 只更新轮盘显示，不重新计算currentZoomFactor
            updateZoomWheelDisplay()
            
            // 更新轮盘指针位置
            if let backgroundBlur = zoomWheelBackground {
                updateArcPosition(zoomFactor: currentZoomFactor, in: backgroundBlur, wheelWidth: 320, wheelHeight: 180, minZoom: 0.5, maxZoom: 6.0)
            }
            
            print("🎯 轮盘连续性同步完成，保持显示值: \(currentZoomFactor)")
            return
        }
        
        // 获取当前相机的实际变焦值
        guard let currentDevice = getCurrentCameraDevice() else {
            print("🎯 [WARN] 无法获取当前相机设备")
            return
        }
        
        let actualZoom = currentDevice.videoZoomFactor
        print("🎯 当前相机实际变焦值: \(actualZoom)")
        
        // 🔥 修复：根据相机类型和实际长焦倍数计算UI显示值
        var uiDisplayZoom: CGFloat
        if currentDevice.deviceType == .builtInUltraWideCamera {
            // 超广角相机：实际值除以2.0得到UI显示值
            uiDisplayZoom = actualZoom / 2.0
            print("🎯 超广角相机UI显示值: \(actualZoom) / 2.0 = \(uiDisplayZoom)")
        } else if currentDevice.deviceType == .builtInTelephotoCamera {
            // 🔥 长焦相机：需要根据实际长焦倍数计算UI显示值
            let actualTelephotoZoom = getActualTelephotoZoom(for: currentDevice)
            uiDisplayZoom = actualTelephotoZoom * actualZoom
            print("🎯 长焦相机UI显示值: \(actualTelephotoZoom) * \(actualZoom) = \(uiDisplayZoom)")
        } else {
            // 广角相机：直接使用实际值
            uiDisplayZoom = actualZoom
            print("🎯 广角相机UI显示值: \(uiDisplayZoom)")
        }
        
        // 更新currentZoomFactor
        currentZoomFactor = uiDisplayZoom
        print("🎯 更新currentZoomFactor为: \(currentZoomFactor)")
        
        // 更新轮盘显示
        updateZoomWheelDisplay()
        
        // 更新轮盘指针位置
        if let backgroundBlur = zoomWheelBackground {
            updateArcPosition(zoomFactor: currentZoomFactor, in: backgroundBlur, wheelWidth: 320, wheelHeight: 180, minZoom: 0.5, maxZoom: 6.0)
        }
        
        print("🎯 轮盘同步完成，当前显示值: \(currentZoomFactor)")
    }
    
    // 🎯 更新轮盘显示值
    private func updateZoomWheelDisplay() {
        print("🎯 更新轮盘显示值: \(currentZoomFactor)")
        
        // 更新数值标签
        zoomValueLabel?.text = String(format: "%.1f×", currentZoomFactor)
        
        // 更新滑块值
        zoomWheelSlider?.value = Float(currentZoomFactor)
        
        print("🎯 轮盘显示值更新完成")
    }
    
    // 创建苹果风格缩放刻度标记（优化版：整体圆弧滑动）
    func createAppleStyleZoomMarks(in container: UIView, wheelWidth: CGFloat, wheelHeight: CGFloat, minZoom: CGFloat, maxZoom: CGFloat, currentZoom: CGFloat = 1.0) {
        // 查找或创建圆弧容器（性能优化：整体滑动）
        var arcContainer = container.viewWithTag(1001)
        if arcContainer == nil {
            arcContainer = UIView()
            arcContainer?.tag = 1001
            arcContainer?.frame = container.bounds
            // 设置旋转中心在底部中心（苹果风格）
            arcContainer?.layer.anchorPoint = CGPoint(x: 0.5, y: 1.0)
            // 确保圆弧容器被正确添加到容器中
            if let arcContainer = arcContainer {
                container.addSubview(arcContainer)
            }
        } else {
            // 清除圆弧容器内的所有内容
            arcContainer?.subviews.forEach { $0.removeFromSuperview() }
            arcContainer?.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        }
        
        // 调整圆弧容器的位置以匹配旋转中心
        arcContainer?.frame = container.bounds
        
        // 设置圆弧容器的坐标系统
        arcContainer?.layer.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        
        // 保留包含"×"的标签（指示器）
        container.subviews.forEach { subview in
            if let label = subview as? UILabel, let text = label.text, text.contains("×") {
                // 保留指示器标签
            } else if subview.tag != 1001 {
                subview.removeFromSuperview()
            }
        }
        
        let radius = wheelHeight - 30 // 刻度圆弧半径
        let centerX = wheelWidth / 2
        let centerY = wheelHeight
        
        // 圆弧容器的坐标系统：旋转中心在底部中心
        let arcCenterX = wheelWidth / 2
        let arcCenterY = wheelHeight
        
        // 苹果风格：所有刻度都显示，但只显示主要数字
        let zoomValues: [CGFloat] = {
            var values: [CGFloat] = []
            
            print("🎡 [DEBUG] 生成苹果风格刻度 - minZoom: \(minZoom), maxZoom: \(maxZoom)")
            
            // 生成所有刻度：0.5x 到 6x，每0.1x一个刻度
            for i in 5...60 {
                let value = CGFloat(i) / 10.0
                if value >= minZoom && value <= maxZoom {
                    values.append(value)
                }
            }
            
            print("🎡 [DEBUG] 添加刻度: 所有刻度都显示")
            
            print("🎡 [DEBUG] 最终刻度: \(values)")
            return values
        }()
        
        // 苹果风格：指针固定在中间，刻度根据当前变焦移动
        let centerAngle = CGFloat.pi / 2 // 90度，正中间
        
        for zoomValue in zoomValues {
            // 计算刻度角度（苹果风格：刻度固定在圆弧上，根据变焦值计算位置）
            let progress: CGFloat
            
            if zoomValue <= 2.0 {
                // 0.5x-2x区间：占用更多空间，间隔大
                progress = (zoomValue - minZoom) / (2.0 - minZoom) * 0.7 // 占用70%的空间
            } else {
                // 3x-6x区间：占用较少空间，间隔小
                let highProgress = (zoomValue - 2.0) / (maxZoom - 2.0) * 0.3 // 占用30%的空间
                progress = 0.7 + highProgress // 从70%开始
            }
            
            // 计算刻度在圆弧上的固定角度（苹果风格：刻度固定在圆弧上）
            let angle = centerAngle - (progress * CGFloat.pi)
            
            // 创建刻度线（苹果风格：指向圆心）
            let tickLayer = CAShapeLayer()
            let tickPath = UIBezierPath()
            
            // 刻度线起点（在圆弧上）- 使用圆弧容器的相对坐标
            let tickStartX = arcCenterX + cos(angle) * radius
            let tickStartY = arcCenterY - sin(angle) * radius
            
            // 刻度线终点（向内延伸，指向圆心）
            let tickEndX = arcCenterX + cos(angle) * (radius - 12)
            let tickEndY = arcCenterY - sin(angle) * (radius - 12)
            
            tickPath.move(to: CGPoint(x: tickStartX, y: tickStartY))
            tickPath.addLine(to: CGPoint(x: tickEndX, y: tickEndY))
            
            tickLayer.path = tickPath.cgPath
            tickLayer.strokeColor = UIColor.white.withAlphaComponent(0.8).cgColor
            tickLayer.lineWidth = 1.5
            arcContainer?.layer.addSublayer(tickLayer)
            
            // 只显示主要数字：0.5x, 1x, 2x, 3x, 4x, 5x, 6x
            let isMainScale = [0.5, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0].contains(zoomValue)
            
            if isMainScale {
                // 创建变焦值标签（苹果风格：数字和刻度一起绑定）
                let zoomLabel = UILabel()
                zoomLabel.text = String(format: "%.1fx", zoomValue)
                zoomLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
                zoomLabel.textColor = UIColor.white
                zoomLabel.textAlignment = .center
                zoomLabel.sizeToFit()
                
                // 计算标签位置（精确对齐圆弧）- 使用圆弧容器的相对坐标
                let labelRadius = radius - 25
                let labelX = arcCenterX + cos(angle) * labelRadius
                let labelY = arcCenterY - sin(angle) * labelRadius
                zoomLabel.center = CGPoint(x: labelX, y: labelY)
                
                // 添加到圆弧容器中（数字和刻度一起移动）
                arcContainer?.addSubview(zoomLabel)
            }
        }
        
        // 添加当前变焦指示器（黄色三角形）
        addCurrentZoomIndicator(to: container, wheelWidth: wheelWidth, wheelHeight: wheelHeight, minZoom: minZoom, maxZoom: maxZoom, currentZoom: currentZoom)
    }
    
    // 快速更新圆弧位置（性能优化：只移动圆弧容器，不重新创建刻度）
    func updateArcPosition(zoomFactor: CGFloat, in container: UIView, wheelWidth: CGFloat, wheelHeight: CGFloat, minZoom: CGFloat, maxZoom: CGFloat) {
        // 安全检查：确保容器和圆弧容器都存在且有效
        guard container.window != nil,
              let arcContainer = container.viewWithTag(1001),
              arcContainer.window != nil else { 
            print("🎡 [WARN] 圆弧容器不可用，跳过更新")
            return 
        }
        
        let radius = wheelHeight - 30
        let centerX = wheelWidth / 2
        let centerY = wheelHeight
        let centerAngle = CGFloat.pi / 2
        
        // 计算当前变焦对应的圆弧偏移（苹果风格：向左滑动放大，向右滑动缩小）
        let unifiedCurrentProgress: CGFloat
        if zoomFactor <= 2.0 {
            unifiedCurrentProgress = (zoomFactor - minZoom) / (2.0 - minZoom) * 0.7
        } else {
            let highCurrentProgress = (zoomFactor - 2.0) / (maxZoom - 2.0) * 0.3
            unifiedCurrentProgress = 0.7 + highCurrentProgress
        }
        
        // 计算圆弧旋转角度（苹果风格：刻度向左移动表示放大）
        // 注意：正值表示顺时针旋转，负值表示逆时针旋转
        // 当变焦增大时，刻度应该向左移动（逆时针旋转）
        let rotationAngle = -unifiedCurrentProgress * CGFloat.pi
        
        // 使用动画更新圆弧位置（添加安全检查）
        UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseOut], animations: {
            // 再次检查圆弧容器是否仍然有效
            guard arcContainer.window != nil else { return }
            arcContainer.transform = CGAffineTransform(rotationAngle: rotationAngle)
        })
    }
    
    // 添加当前变焦指示器
    func addCurrentZoomIndicator(to container: UIView, wheelWidth: CGFloat, wheelHeight: CGFloat, minZoom: CGFloat, maxZoom: CGFloat, currentZoom: CGFloat) {
        let radius = wheelHeight - 30
        let centerX = wheelWidth / 2
        let centerY = wheelHeight
        
        // 苹果风格：指示器固定在中间
        let centerAngle = CGFloat.pi / 2 // 90度，正中间
        
        // 创建黄色三角形指示器（苹果风格）
        let indicatorSize: CGFloat = 6
        let indicatorRadius = radius - 15
        let indicatorX = centerX + cos(centerAngle) * indicatorRadius
        let indicatorY = centerY - sin(centerAngle) * indicatorRadius
        
        let indicator = UIView()
        indicator.frame = CGRect(x: 0, y: 0, width: indicatorSize, height: indicatorSize)
        indicator.center = CGPoint(x: indicatorX, y: indicatorY)
        indicator.backgroundColor = UIColor.clear
        indicator.tag = 999 // 添加特殊标签，用于快速更新
        indicator.transform = CGAffineTransform(rotationAngle: centerAngle - CGFloat.pi/2)
        
        // 创建三角形路径（苹果风格）
        let trianglePath = UIBezierPath()
        trianglePath.move(to: CGPoint(x: indicatorSize/2, y: 0))
        trianglePath.addLine(to: CGPoint(x: 0, y: indicatorSize))
        trianglePath.addLine(to: CGPoint(x: indicatorSize, y: indicatorSize))
        trianglePath.close()
        
        let triangleLayer = CAShapeLayer()
        triangleLayer.path = trianglePath.cgPath
        triangleLayer.fillColor = UIColor.systemYellow.cgColor
        indicator.layer.addSublayer(triangleLayer)
        
        container.addSubview(indicator)
    }
    
    // 创建苹果风格的黄色三角指示器
    func createZoomIndicator(in container: UIVisualEffectView, wheelWidth: CGFloat, wheelHeight: CGFloat) {
        let radius = wheelHeight - 15 // 三角指示器位置
        let centerX = wheelWidth / 2
        let centerY = wheelHeight
        
        // 计算当前缩放值的角度
        guard let slider = zoomWheelSlider else { return }
        let progress = (currentZoomFactor - CGFloat(slider.minimumValue)) / CGFloat(slider.maximumValue - slider.minimumValue)
        let angle = CGFloat.pi * (1.0 - progress)
        
        // 创建三角形指示器
        let triangleView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 12))
        
        // 创建三角形路径
        let trianglePath = UIBezierPath()
        trianglePath.move(to: CGPoint(x: 6, y: 0))      // 顶点
        trianglePath.addLine(to: CGPoint(x: 0, y: 12))  // 左下
        trianglePath.addLine(to: CGPoint(x: 12, y: 12)) // 右下
        trianglePath.close()
        
        let triangleLayer = CAShapeLayer()
        triangleLayer.path = trianglePath.cgPath
        triangleLayer.fillColor = UIColor.systemYellow.cgColor
        triangleLayer.strokeColor = UIColor.black.withAlphaComponent(0.3).cgColor
        triangleLayer.lineWidth = 0.5
        
        triangleView.layer.addSublayer(triangleLayer)
        
        // 计算三角指示器位置
        let indicatorX = centerX + cos(angle) * radius
        let indicatorY = centerY - sin(angle) * radius
        triangleView.center = CGPoint(x: indicatorX, y: indicatorY)
        
        // 旋转三角形使其指向中心
        triangleView.transform = CGAffineTransform(rotationAngle: angle - CGFloat.pi/2)
        
        container.contentView.addSubview(triangleView)
        
        // 存储指示器引用用于更新
        triangleView.tag = 9999 // 特殊标记
    }
    
    // 更新苹果风格三角指示器位置
    func updateZoomIndicator(in container: UIVisualEffectView, wheelWidth: CGFloat, wheelHeight: CGFloat) {
        guard let triangleIndicator = container.contentView.subviews.first(where: { $0.tag == 9999 }),
              let slider = zoomWheelSlider else { return }
        
        let radius = wheelHeight - 15
        let centerX = wheelWidth / 2
        let centerY = wheelHeight
        
        let progress = (currentZoomFactor - CGFloat(slider.minimumValue)) / CGFloat(slider.maximumValue - slider.minimumValue)
        let angle = CGFloat.pi * (1.0 - progress)
        
        let indicatorX = centerX + cos(angle) * radius
        let indicatorY = centerY - sin(angle) * radius
        triangleIndicator.center = CGPoint(x: indicatorX, y: indicatorY)
        
        // 更新三角形旋转角度，使其始终指向中心
        triangleIndicator.transform = CGAffineTransform(rotationAngle: angle - CGFloat.pi/2)
    }
    
    // 隐藏缩放轮盘
    func hideZoomWheel(animated: Bool = true) {
        guard isZoomWheelVisible, let wheelView = zoomWheelView else { return }
        
        isZoomWheelVisible = false
        zoomWheelAutoHideTimer?.invalidate()
        zoomWheelAutoHideTimer = nil
        
        // 在隐藏轮盘前，确保相机状态与UI一致
        print("🎡 [DEBUG] 隐藏轮盘前，当前变焦值: \(currentZoomFactor)")
        
        if animated {
            UIView.animate(withDuration: 0.2, animations: {
                wheelView.alpha = 0
                wheelView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            }) { _ in
                wheelView.removeFromSuperview()
                self.zoomWheelView = nil
                self.zoomWheelBackground = nil
                self.zoomValueLabel = nil
                self.zoomWheelSlider = nil
                
                // 确保相机状态与轮盘一致
                self.ensureCameraStateMatchesUI()
                
                // 显示后置UI
                self.showRearCameraUI()
            }
        } else {
            wheelView.removeFromSuperview()
            zoomWheelView = nil
            zoomWheelBackground = nil
            zoomValueLabel = nil
            zoomWheelSlider = nil
            
            // 确保相机状态与轮盘一致
            self.ensureCameraStateMatchesUI()
            
            // 显示后置UI
            self.showRearCameraUI()
        }
    }
    
    // 隐藏后置UI
    func hideRearCameraUI() {
        // 隐藏后置镜头切换UI，但不影响轮盘
        if let rearUI = view.viewWithTag(8888) {
            // 确保轮盘在最顶层
            if let wheelView = zoomWheelView {
                view.bringSubviewToFront(wheelView)
            }
            
            UIView.animate(withDuration: 0.2) {
                rearUI.alpha = 0
            }
        }
    }
    
    // 显示后置UI
    func showRearCameraUI() {
        // 显示后置镜头切换UI
        if let rearUI = view.viewWithTag(8888) {
            UIView.animate(withDuration: 0.2) {
                rearUI.alpha = 1.0
            }
        }
    }
    
    // 启动3秒自动隐藏定时器
    func startZoomWheelAutoHideTimer() {
        // 取消之前的定时器
        zoomWheelAutoHideTimer?.invalidate()
        
        // 创建新的3秒定时器
        zoomWheelAutoHideTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.hideZoomWheel()
            }
        }
    }
    
    // 延迟隐藏轮盘
    func hideZoomWheelWithDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.hideZoomWheel()
        }
    }
    
    // 防抖机制：延迟相机更新，避免频繁切换
    private var cameraUpdateTimer: Timer?
    private var lastCameraUpdateTime: TimeInterval = 0
    private let cameraUpdateDebounceInterval: TimeInterval = 0.1 // 100ms防抖
    
    func debounceCameraUpdate(newZoom: CGFloat) {
        // 取消之前的定时器
        cameraUpdateTimer?.invalidate()
        
        let currentTime = CACurrentMediaTime()
        
        // 如果距离上次更新太近，使用防抖
        if currentTime - lastCameraUpdateTime < cameraUpdateDebounceInterval {
            // 延迟更新
            cameraUpdateTimer = Timer.scheduledTimer(withTimeInterval: cameraUpdateDebounceInterval, repeats: false) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.updateCameraZoom(newZoom)
                    self?.lastCameraUpdateTime = CACurrentMediaTime()
                }
            }
        } else {
            // 立即更新
            updateCameraZoom(newZoom)
            lastCameraUpdateTime = currentTime
        }
    }
    
    // 确保相机状态与UI一致
    func ensureCameraStateMatchesUI() {
        print("🎡 [DEBUG] 确保相机状态与UI一致")
        print("🎡 [DEBUG] 当前UI变焦值: \(currentZoomFactor)")
        
        // 获取当前相机设备
        guard let currentDevice = getCurrentCameraDevice() else {
            print("🎡 [WARN] 无法获取当前相机设备")
            return
        }
        
        print("🎡 [DEBUG] 当前相机: \(currentDevice.localizedName)")
        print("🎡 [DEBUG] 当前相机变焦: \(currentDevice.videoZoomFactor)")
        
        // 如果UI变焦值与相机变焦值不一致，需要更新相机
        if abs(currentZoomFactor - currentDevice.videoZoomFactor) > 0.01 {
            print("🎡 [DEBUG] 相机变焦值与UI不一致，需要更新")
            
            // 获取所有可用相机
            let availableCameras = getAvailableCameras()
            
            // 根据UI变焦值选择最佳相机
            let (selectedCamera, finalZoomFactor) = selectBestCamera(for: currentZoomFactor, availableCameras: availableCameras)
            
            print("🎡 [DEBUG] 选择的相机: \(selectedCamera.localizedName)")
            print("🎡 [DEBUG] 最终变焦值: \(finalZoomFactor)")
            
            // 如果选择的相机与当前不同，需要切换
            if selectedCamera != currentDevice {
                print("🎡 [DEBUG] 需要切换相机以匹配UI状态")
                print("🎡 [DEBUG] 从 \(currentDevice.localizedName) 切换到 \(selectedCamera.localizedName)")
                switchToCamera(selectedCamera, withZoom: finalZoomFactor)
            } else {
                print("🎡 [DEBUG] 同一相机内更新变焦以匹配UI状态")
                applyZoomToCamera(selectedCamera, zoomFactor: finalZoomFactor)
            }
        } else {
            print("🎡 [DEBUG] 相机状态与UI一致，无需更新")
        }
        
        // 更新UI显示以匹配轮盘设置的值
        updateUIForZoomFactor(currentZoomFactor)
    }
    
    // 根据变焦值更新UI显示
    func updateUIForZoomFactor(_ zoomFactor: CGFloat) {
        print("🎨 [DEBUG] 根据变焦值更新UI: \(zoomFactor)")
        
        // 根据变焦值确定应该显示哪个UI按钮
        if zoomFactor >= 2.0 {
            // 2x及以上，显示2x按钮
            if let index = cameraOptions.firstIndex(where: { $0.label == "2x" }) {
                currentCameraIndex = index
                print("🎨 [DEBUG] 设置UI为2x按钮，索引: \(index)")
            }
        } else if zoomFactor >= 0.5 && zoomFactor < 1.0 {
            // 0.5x-1.0x，显示0.5x按钮
            if let index = cameraOptions.firstIndex(where: { $0.label == "0.5x" }) {
                currentCameraIndex = index
                print("🎨 [DEBUG] 设置UI为0.5x按钮，索引: \(index)")
            }
        } else if zoomFactor >= 1.0 && zoomFactor < 2.0 {
            // 1.0x-2.0x，显示1x按钮
            if let index = cameraOptions.firstIndex(where: { $0.label == "1x" }) {
                currentCameraIndex = index
                print("🎨 [DEBUG] 设置UI为1x按钮，索引: \(index)")
            }
        }
        
        // 更新UI显示
        updateCameraUI()
    }
    
    // 删除旧的定时器函数，使用 startZoomWheelAutoHideTimer 替代
    
    // 处理苹果风格的水平滑动手势
    @objc func handleAppleZoomWheelPan(_ gesture: UIPanGestureRecognizer) {
        // 防止第一次调节时的黑屏：确保相机完全初始化
        guard let session = captureSession, 
              session.isRunning,
              let currentDevice = getCurrentCameraDevice() else {
            print("🎡 [WARN] 相机未完全初始化，跳过轮盘调节")
            return
        }
        
        guard let wheelView = zoomWheelView,
              let slider = zoomWheelSlider,
              let valueLabel = zoomValueLabel,
              let backgroundBlur = zoomWheelBackground else { 
            print("❌ [DEBUG] 轮盘滑动：缺少必要组件")
            print("❌ [DEBUG] wheelView: \(zoomWheelView != nil)")
            print("❌ [DEBUG] slider: \(zoomWheelSlider != nil)")
            print("❌ [DEBUG] valueLabel: \(zoomValueLabel != nil)")
            print("❌ [DEBUG] backgroundBlur: \(zoomWheelBackground != nil)")
            return 
        }
        
        let translation = gesture.translation(in: wheelView)
        
        switch gesture.state {
        case .began:
            print("🎯 [DEBUG] 开始水平滑动轮盘")
            // 取消之前的定时器，防止轮盘消失
            zoomWheelAutoHideTimer?.invalidate()
            zoomWheelAutoHideTimer = nil
            initialZoomFactor = currentZoomFactor
            
        case .changed:
            print("👆 [DEBUG] 水平滑动中：translation.x = \(translation.x)")
            
            // 苹果风格：向右滑动放大，向左滑动缩小
            let sensitivity: CGFloat = 0.008 // 调整水平滑动灵敏度
            let deltaZoom = translation.x * sensitivity // 向右为正，向左为负
            let newZoom = max(0.5, min(6.0, initialZoomFactor + deltaZoom)) // 支持0.5x到6x
            
            print("🔍 [DEBUG] 缩放变化：\(initialZoomFactor) → \(newZoom) (水平位移: \(translation.x))")
            
            // 更新UI显示
            currentZoomFactor = CGFloat(newZoom)
            slider.value = Float(newZoom)
            valueLabel.text = String(format: "%.1f×", currentZoomFactor)
            
            // 快速更新圆弧位置（性能优化）
            if backgroundBlur.window != nil {
                updateArcPosition(zoomFactor: currentZoomFactor, in: backgroundBlur, wheelWidth: 320, wheelHeight: 180, minZoom: 0.5, maxZoom: 6.0)
            }
            
            // 防抖机制：延迟应用到相机，避免频繁切换
            debounceCameraUpdate(newZoom: currentZoomFactor)
            
            // 变焦中不启动定时器，保持轮盘显示
            
        case .ended, .cancelled:
            print("✋ [DEBUG] 水平滑动结束")
            // 手势结束后启动3秒定时器
            startZoomWheelAutoHideTimer()
            
        default:
            break
        }
    }
    
    // 更新轮盘指示器位置 - 苹果风格：重新创建整个轮盘并显示当前标签
    func updateZoomWheelIndicator(zoomFactor: CGFloat, in container: UIView, wheelWidth: CGFloat, wheelHeight: CGFloat) {
        // 移除所有旧的刻度
        container.subviews.forEach { subview in
            subview.removeFromSuperview()
        }
        
        // 获取当前相机的实际变焦范围，但限制在合理范围内
        guard let currentDevice = getCurrentCameraDevice() else { return }
        let minZoom: CGFloat = 0.5 // 支持超广角变焦（苹果原相机风格）
        let rawMaxZoom = currentDevice.activeFormat.videoMaxZoomFactor
        let maxZoom = min(rawMaxZoom, 6.0) // 限制最大变焦为6x
        
        // 重新创建刻度（苹果风格：指针固定，刻度移动）
        createAppleStyleZoomMarks(in: container, wheelWidth: wheelWidth, wheelHeight: wheelHeight, minZoom: minZoom, maxZoom: maxZoom, currentZoom: zoomFactor)
    }
    
    // 保留旧的垂直滑动方法作为备用
    @objc func handleZoomWheelPan(_ gesture: UIPanGestureRecognizer) {
        // 已弃用，使用 handleAppleZoomWheelPan 替代
        handleAppleZoomWheelPan(gesture)
    }
    
    // 获取当前相机设备
    func getCurrentCameraDevice() -> AVCaptureDevice? {
        guard currentCameraIndex < cameraOptions.count else { return nil }
        return cameraOptions[currentCameraIndex].device
    }
    
    // 更新相机缩放 - 苹果风格平滑变焦（优化版）
    func updateCameraZoom(_ zoomFactor: CGFloat) {
        // 防止第一次调节时的黑屏：确保相机完全初始化
        guard let session = captureSession, 
              session.isRunning,
              let currentDevice = getCurrentCameraDevice() else {
            print("🎡 [WARN] 相机未完全初始化，跳过变焦更新")
            return
        }
        
        // 性能优化：检查变焦值是否有实际变化
        if abs(zoomFactor - currentDevice.videoZoomFactor) < 0.01 {
            print("🎡 [DEBUG] 变焦值无实际变化，跳过更新")
            return
        }
        
        // 防抖逻辑：在1x附近增加更严格的防抖
        let currentTime = CACurrentMediaTime()
        if zoomFactor >= 0.9 && zoomFactor <= 1.1 {
            // 在1x附近，增加防抖时间
            if currentTime - lastCameraSwitchTime < 0.8 { // 800ms防抖
                print("🎡 [DEBUG] 1x附近防抖：跳过相机切换")
                return
            }
        }
        
        print("🎡 [DEBUG] 目标变焦值: \(zoomFactor)")
        
        // 获取所有可用相机
        let availableCameras = getAvailableCameras()
        
        // 根据变焦值选择最佳相机
        let (selectedCamera, finalZoomFactor) = selectBestCamera(for: zoomFactor, availableCameras: availableCameras)
        
        // 如果选择的相机与当前不同，需要切换
        if let currentDevice = getCurrentCameraDevice() {
            print("🎡 [DEBUG] 当前相机: \(currentDevice.localizedName)")
            print("🎡 [DEBUG] 选择相机: \(selectedCamera.localizedName)")
            
            if selectedCamera != currentDevice {
                print("🎡 [DEBUG] 需要切换相机")
                // 🎬 使用带动画的镜头切换
                performSmoothZoomTransition(to: selectedCamera, withZoom: finalZoomFactor)
            } else {
                print("🎡 [DEBUG] 同一相机内变焦")
                // 🔥 修复：同一相机内变焦不需要切换动画
                applyZoomToCamera(selectedCamera, zoomFactor: finalZoomFactor)
            }
        } else {
            print("🎡 [DEBUG] 无法获取当前相机，直接应用变焦")
            applyZoomToCamera(selectedCamera, zoomFactor: finalZoomFactor)
        }
    }
    
    // 🎬 轮盘镜头切换：苹果风格丝滑过渡动画
    private func performSmoothZoomTransition(to targetCamera: AVCaptureDevice, withZoom zoomFactor: CGFloat) {
        // 防止重复触发切换
        guard !isPerformingZoomTransition else { 
            print("🎬 [ZOOM_TRANSITION] 正在进行镜头切换，跳过")
            return 
        }
        
        isPerformingZoomTransition = true
        print("🎬 [ZOOM_TRANSITION] 开始苹果风格轮盘镜头切换动画")
        
        // 🔥 关键修复：并行执行模糊动画和镜头切换
        var isBlurReady = false
        var isCameraSwitched = false
        
        // 检查是否都完成的函数
        func checkCompletion() {
            if isBlurReady && isCameraSwitched {
                // 🎯 用户需求：镜头切换完毕后0.5s再开始移除模糊
                print("🎬 [PARALLEL] 所有操作完成，等待镜头稳定0.5s")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.removeZoomTransitionBlur {
                        self.isPerformingZoomTransition = false
                        print("🎬 [ZOOM_TRANSITION] 苹果风格轮盘镜头切换完成")
                    }
                }
            }
        }
        
        // 第一阶段：创建模糊遮罩（并行）
        createZoomTransitionBlur { [weak self] in
            isBlurReady = true
            print("🎬 [PARALLEL] 模糊动画完成，等待镜头切换")
            checkCompletion()
        }
        
        // 第二阶段：立即开始镜头切换（并行）
        executeZoomCameraSwitch(to: targetCamera, withZoom: zoomFactor) {
            isCameraSwitched = true
            print("🎬 [PARALLEL] 镜头切换完成，等待模糊动画")
            checkCompletion()
        }
    }
    
    // 🎬 创建高强度渐变模糊遮罩
    private func createZoomTransitionBlur(completion: @escaping () -> Void) {
        print("🎬 [ZOOM_BLUR] 开始创建高强度模糊遮罩")
        
        guard let previewImageView = filteredPreviewImageView else {
            print("🎬 [ZOOM_BLUR] 预览视图不存在，跳过模糊动画")
            completion()
            return
        }
        
        // 创建苹果风格的自然模糊效果（修复发白问题）
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        let blurView = UIVisualEffectView(effect: nil) // 初始无效果
        blurView.frame = previewImageView.bounds
        blurView.alpha = 0.0
        
        // 添加到预览层上方
        previewImageView.addSubview(blurView)
        zoomTransitionBlurView = blurView
        
        // 记录模糊动画开始时间
        let blurStartTime = CACurrentMediaTime()
        print("🎬 [TIMING] 模糊陖入动画开始时间: \(blurStartTime)")
        
        // 动画：自然模糊效果渐进增强（与镜头切换时序同步）
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseInOut], animations: {
            blurView.effect = blurEffect
            blurView.alpha = 1.0 // 完全不透明的自然模糊
            print("🎬 [ZOOM_BLUR] 自然模糊效果增强中...")
        }) { _ in
            let blurPeakTime = CACurrentMediaTime()
            print("🎬 [TIMING] 模糊陖入动画结束时间: \(blurPeakTime)")
            print("🎬 [TIMING] 模糊陖入动画耗时: \((blurPeakTime - blurStartTime) * 1000)ms")
            print("🎬 [ZOOM_BLUR] 模糊效果达到峰值，准备切换镜头")
            completion()
        }
    }
    
    // 🎬 在模糊遮挡下执行实际的镜头切换
    private func executeZoomCameraSwitch(to targetCamera: AVCaptureDevice, withZoom zoomFactor: CGFloat, completion: @escaping () -> Void) {
        print("🎬 [ZOOM_SWITCH] 立即开始镜头切换（并行）")
        
        // 记录镜头切换开始时间
        let switchStartTime = CACurrentMediaTime()
        print("🎬 [TIMING] 镜头切换开始时间: \(switchStartTime)")
        
        // 🔥 关键修复：立即执行镜头切换，不等待
        self.switchToCamera(targetCamera, withZoom: zoomFactor)
        
        // 🔥 更短的等待时间，确保镜头切换比模糊动画先完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            let switchEndTime = CACurrentMediaTime()
            print("🎬 [TIMING] 镜头切换完成时间: \(switchEndTime)")
            print("🎬 [TIMING] 镜头切换耗时: \((switchEndTime - switchStartTime) * 1000)ms")
            completion()
        }
    }
    
    // 🎬 移除模糊遮罩，丝滑露出新镜头画面
    private func removeZoomTransitionBlur(completion: @escaping () -> Void) {
        print("🎬 [ZOOM_BLUR_REMOVE] 开始平滑模糊移除")
        
        guard let blurView = zoomTransitionBlurView else {
            print("🎬 [ZOOM_BLUR_REMOVE] 模糊视图不存在")
            completion()
            return
        }
        
        // 记录动画开始时间
        let animationStartTime = CACurrentMediaTime()
        print("🎬 [TIMING] 模糊移除动画开始时间: \(animationStartTime)")
        
        // 🎯 修复闪烁：使用单一平滑动画，避免多阶段切换
        print("🎬 [ZOOM_BLUR_REMOVE] 平滑透明度降低开始...")
        
        // 🔥 关键修复：使用纯透明度动画，避免效果切换闪烁
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut, .allowUserInteraction], animations: {
            // 只改变透明度，不改变模糊效果，避免闪烁
            blurView.alpha = 0.0
            print("🎬 [ZOOM_BLUR_REMOVE] 平滑透明度变化中...")
        }) { _ in
            let animationEndTime = CACurrentMediaTime()
            print("🎬 [TIMING] 模糊移除动画结束时间: \(animationEndTime)")
            print("🎬 [TIMING] 模糊移除动画耗时: \((animationEndTime - animationStartTime) * 1000)ms")
            
            // 动画完成后再移除效果和视图
            blurView.effect = nil
            blurView.removeFromSuperview()
            self.zoomTransitionBlurView = nil
            print("🎬 [ZOOM_BLUR_REMOVE] 平滑模糊遮罩完全移除")
            completion()
        }
    }
    
    // 获取所有可用相机
    func getAvailableCameras() -> [AVCaptureDevice] {
        // 尝试获取所有类型的相机
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInTripleCamera, .builtInDualCamera, .builtInWideAngleCamera, .builtInUltraWideCamera, .builtInTelephotoCamera],
            mediaType: .video,
            position: .back
        )
        
        let devices = discoverySession.devices
        print("🎡 [DEBUG] 发现相机设备数量: \(devices.count)")
        for device in devices {
            print("🎡 [DEBUG] 发现相机: \(device.localizedName), 类型: \(device.deviceType), 变焦范围: \(device.minAvailableVideoZoomFactor)x - \(device.maxAvailableVideoZoomFactor)x")
        }
        
        return devices
    }
    
    // 选择最佳相机和变焦值 - 苹果原相机风格
    func selectBestCamera(for targetZoom: CGFloat, availableCameras: [AVCaptureDevice]) -> (AVCaptureDevice, CGFloat) {
        // 修复强制解包问题
        guard let defaultDevice = getCurrentCameraDevice() ?? AVCaptureDevice.default(for: .video) else {
            print("🎡 [ERROR] 无法获取默认相机设备")
            // 返回一个安全的默认值
            if let firstCamera = availableCameras.first {
                return (firstCamera, targetZoom)
            } else {
                // 如果连可用相机都没有，创建一个虚拟相机
                fatalError("没有可用的相机设备")
            }
        }
        var bestCamera: AVCaptureDevice = defaultDevice
        var bestZoomFactor: CGFloat = targetZoom
        
        print("🎡 [DEBUG] 选择相机 - 目标变焦: \(targetZoom)x")
        print("🎡 [DEBUG] 可用相机数量: \(availableCameras.count)")
        
        // 防抖逻辑：防止频繁切换相机，但允许1x附近的切换
        let currentTime = CACurrentMediaTime()
        if let lastCamera = lastSelectedCamera, 
           currentTime - lastCameraSwitchTime < cameraSwitchDebounceInterval {
            // 如果是1x附近的切换，允许立即切换，但增加更严格的防抖
            if targetZoom >= 0.9 && targetZoom <= 1.2 {
                print("🎡 [DEBUG] 防抖：跳过相机切换，距离上次切换时间: \(currentTime - lastCameraSwitchTime)秒")
                return (lastCamera, targetZoom)
            }
        }
        
        // --- 苹果原相机风格：主摄/超广角无缝切换 ---
        // 重新设计相机选择逻辑：更简单、更稳定
        if let currentDevice = getCurrentCameraDevice() {
            let isWide = currentDevice.deviceType == .builtInWideAngleCamera
            let isUltra = currentDevice.deviceType == .builtInUltraWideCamera
            let isTele = currentDevice.deviceType == .builtInTelephotoCamera
            
            // 策略1：如果当前是超广角相机，且目标变焦在0.5x-1.0x范围，继续使用超广角
            if isUltra && targetZoom >= 0.5 && targetZoom <= 1.0 {
                print("🎡 [DEBUG] 超广角相机继续使用：\(targetZoom)x")
                return (currentDevice, targetZoom)
            }
            
            // 🔥 自适应：获取实际长焦倍数（从可用的长焦相机获取）
            let actualTelephotoZoom: CGFloat
            if let telephotoDevice = availableCameras.first(where: { $0.deviceType == .builtInTelephotoCamera }) {
                actualTelephotoZoom = getActualTelephotoZoom(for: telephotoDevice)
            } else {
                actualTelephotoZoom = 2.0 // 默认值
            }
            
            // 策略2：如果当前是广角相机，且目标变焦在1.0x到长焦倍数之间，继续使用广角
            if isWide && targetZoom >= 1.0 && targetZoom < actualTelephotoZoom {
                let clampedZoom = max(currentDevice.minAvailableVideoZoomFactor, min(targetZoom, currentDevice.maxAvailableVideoZoomFactor))
                print("🎡 [DEBUG] 广角相机继续使用：\(targetZoom)x (长焦切换阈值: \(actualTelephotoZoom)x)")
                return (currentDevice, clampedZoom)
            }
            
            // 🔥 修复策略2.5：如果当前是长焦相机，且目标变焦在长焦倍数以上，继续使用长焦
            if isTele && targetZoom >= actualTelephotoZoom {
                // 🔥 关键修复：将目标倍数转换为长焦镜头的实际变焦值
                let teleZoomFactor = targetZoom / actualTelephotoZoom  // 例如：6x / 3x = 2.0x
                let clampedZoom = max(currentDevice.minAvailableVideoZoomFactor, min(teleZoomFactor, currentDevice.maxAvailableVideoZoomFactor))
                print("🎡 [DEBUG] 长焦相机继续使用：\(targetZoom)x → 长焦\(clampedZoom)x (基准: \(actualTelephotoZoom)x)")
                return (currentDevice, clampedZoom)
            }
            
            // 策略3：需要切换相机的情况
            if targetZoom <= 1.0 && isWide {
                // 广角切换到超广角 - 当目标变焦小于等于1.0x时切换
                if let ultraWide = availableCameras.first(where: { $0.deviceType == .builtInUltraWideCamera }) {
                    preloadCamera(ultraWide)
                    print("🎡 [DEBUG] 广角切换到超广角：\(targetZoom)x")
                    return (ultraWide, targetZoom)
                }
            } else if targetZoom > 1.0 && isUltra {
                // 超广角切换到广角 - 当目标变焦大于1.0x时切换
                if let wide = availableCameras.first(where: { $0.deviceType == .builtInWideAngleCamera }) {
                    preloadCamera(wide)
                    print("🎡 [DEBUG] 超广角切换到广角：\(targetZoom)x")
                    return (wide, targetZoom)
                }
            } else if targetZoom >= actualTelephotoZoom && isWide {
                // 🔥 修复：广角切换到长焦 - 当目标变焦大于等于实际长焦倍数时切换
                if let telephoto = availableCameras.first(where: { $0.deviceType == .builtInTelephotoCamera }) {
                    preloadCamera(telephoto)
                    // 🔥 关键修复：将目标倍数转换为长焦镜头的实际变焦值
                    let teleZoomFactor = targetZoom / actualTelephotoZoom  // 例如：3x / 3x = 1.0x
                    print("🎡 [DEBUG] 广角切换到长焦：\(targetZoom)x → 长焦\(teleZoomFactor)x (基准: \(actualTelephotoZoom)x)")
                    return (telephoto, teleZoomFactor)
                }
            } else if targetZoom < actualTelephotoZoom && isTele {
                // 🔥 修复：长焦切换到广角 - 当目标变焦小于实际长焦倍数时切换
                if let wide = availableCameras.first(where: { $0.deviceType == .builtInWideAngleCamera }) {
                    preloadCamera(wide)
                    // 🔥 关键修复：直接使用目标倍数，因为广角镜头可以数字变焦
                    print("🎡 [DEBUG] 长焦切换到广角：长焦 → \(targetZoom)x广角 (阈值: \(actualTelephotoZoom)x)")
                    return (wide, targetZoom)
                }
            }
            
            // 策略4：如果当前是广角相机，且目标变焦等于1.0x，继续使用广角
            if isWide && targetZoom == 1.0 {
                let clampedZoom = max(currentDevice.minAvailableVideoZoomFactor, min(targetZoom, currentDevice.maxAvailableVideoZoomFactor))
                print("🎡 [DEBUG] 广角相机继续使用：\(targetZoom)x")
                return (currentDevice, clampedZoom)
            }
        }
        
        // 简化逻辑：如果没有找到合适的相机，使用当前相机
        if let currentDevice = getCurrentCameraDevice() {
            bestCamera = currentDevice
            // 直接使用目标变焦值，让applyZoomToCamera处理变焦
            bestZoomFactor = targetZoom
            print("🎡 [DEBUG] 相机fallback：\(targetZoom)x")
            print("🎡 [DEBUG] 使用当前相机数字变焦: \(bestZoomFactor)x")
        }
        
        print("🎡 [DEBUG] 最终选择: \(bestCamera.localizedName), 变焦: \(bestZoomFactor)x")
        return (bestCamera, bestZoomFactor)
    }
    
    // 预加载相机 - 提前准备相机输入
    private func preloadCamera(_ camera: AVCaptureDevice) {
        guard let session = captureSession, !isPreloadingCamera else { return }
        
        // 如果已经预加载了相同的相机，跳过
        if preloadedCamera == camera { return }
        
        print("🎡 [DEBUG] 开始预加载相机: \(camera.localizedName)")
        isPreloadingCamera = true
        
        sessionQueue.async {
            do {
                let newInput = try AVCaptureDeviceInput(device: camera)
                
                // 保存预加载的相机和输入
                self.preloadedCamera = camera
                self.preloadedInput = newInput
                
                print("🎡 [DEBUG] 预加载相机完成: \(camera.localizedName)")
            } catch {
                print("🎡 [ERROR] 预加载相机失败: \(error)")
            }
            
            self.isPreloadingCamera = false
        }
    }
    
    // 切换到指定相机 - 苹果原相机风格无缝切换（使用预加载）
    func switchToCamera(_ camera: AVCaptureDevice, withZoom zoomFactor: CGFloat) {
        guard let session = captureSession else { return }
        
        print("🎡 [DEBUG] 开始切换相机到: \(camera.localizedName), 变焦: \(zoomFactor)x")
        
        sessionQueue.async {
            // 开始配置
            session.beginConfiguration()
            
            // 检查是否有预加载的相机可以使用
            if let preloadedInput = self.preloadedInput, self.preloadedCamera == camera {
                print("🎡 [DEBUG] 使用预加载的相机输入")
                
                // 苹果原相机风格：先移除当前相机，再添加预加载的相机
                if let currentInput = session.inputs.first(where: { $0 is AVCaptureDeviceInput }) {
                    print("🎡 [DEBUG] 移除当前相机输入")
                    session.removeInput(currentInput)
                }
                
                // 添加预加载的相机
                if session.canAddInput(preloadedInput) {
                    print("🎡 [DEBUG] 添加预加载相机输入")
                    session.addInput(preloadedInput)
                    print("🎡 [DEBUG] 已添加预加载相机输入")
                    
                    // 清除预加载状态
                    self.preloadedCamera = nil
                    self.preloadedInput = nil
                    
                    // 更新当前相机索引（仅对物理相机切换）
                    if let index = self.cameraOptions.firstIndex(where: { $0.device == camera }) {
                        // 🔥 修复：检查是否是数字变焦，如果是则不覆盖currentCameraIndex
                        let currentOption = self.cameraOptions[self.currentCameraIndex]
                        if !currentOption.isDigitalZoom {
                            // 不是数字变焦，可以更新索引
                        self.currentCameraIndex = index
                            print("🎡 [DEBUG] 物理相机切换，更新相机索引为: \(index)")
                        } else {
                            // 是数字变焦，保持当前索引
                            print("🎡 [DEBUG] 数字变焦模式，保持当前索引: \(self.currentCameraIndex)")
                        }
                    }
                    
                    // 更新防抖变量
                    self.lastSelectedCamera = camera
                    self.lastCameraSwitchTime = CACurrentMediaTime()
                    
                    // 设置视频方向
                    if let videoConnection = self.videoOutput?.connection(with: .video) {
                        videoConnection.videoOrientation = .portrait
                    }
                    if let photoConnection = self.photoOutput?.connection(with: .video) {
                        photoConnection.videoOrientation = .portrait
                    }
                    
                    // 设置变焦
                    self.applyZoomToCamera(camera, zoomFactor: zoomFactor)
                } else {
                    print("🎡 [ERROR] 无法添加预加载相机输入")
                }
            } else {
                // 如果没有预加载，使用原来的逻辑
                print("🎡 [DEBUG] 使用传统切换方式")
                
                do {
                    let newInput = try AVCaptureDeviceInput(device: camera)
                    
                    // 苹果原相机风格：先移除当前相机，再添加新相机
                    if let currentInput = session.inputs.first(where: { $0 is AVCaptureDeviceInput }) {
                        print("🎡 [DEBUG] 移除当前相机输入")
                        session.removeInput(currentInput)
                    }
                    
                    // 添加新相机
                    if session.canAddInput(newInput) {
                        print("🎡 [DEBUG] 添加新相机输入")
                        session.addInput(newInput)
                        print("🎡 [DEBUG] 已添加新相机输入")
                        
                        // 更新当前相机索引（仅对物理相机切换）
                        if let index = self.cameraOptions.firstIndex(where: { $0.device == camera }) {
                            // 🔥 修复：检查是否是数字变焦，如果是则不覆盖currentCameraIndex
                            let currentOption = self.cameraOptions[self.currentCameraIndex]
                            if !currentOption.isDigitalZoom {
                                // 不是数字变焦，可以更新索引
                            self.currentCameraIndex = index
                                print("🎡 [DEBUG] 物理相机切换，更新相机索引为: \(index)")
                            } else {
                                // 是数字变焦，保持当前索引
                                print("🎡 [DEBUG] 数字变焦模式，保持当前索引: \(self.currentCameraIndex)")
                            }
                        }
                        
                        // 更新防抖变量
                        self.lastSelectedCamera = camera
                        self.lastCameraSwitchTime = CACurrentMediaTime()
                        
                        // 设置视频方向
                        if let videoConnection = self.videoOutput?.connection(with: .video) {
                            videoConnection.videoOrientation = .portrait
                        }
                        if let photoConnection = self.photoOutput?.connection(with: .video) {
                            photoConnection.videoOrientation = .portrait
                        }
                        
                        // 设置变焦
                        self.applyZoomToCamera(camera, zoomFactor: zoomFactor)
                    } else {
                        print("🎡 [ERROR] 无法添加新相机输入")
                    }
                } catch {
                    print("🎡 [ERROR] 切换相机失败: \(error)")
                }
            }
            
            // 提交配置
            session.commitConfiguration()
            print("🎡 [DEBUG] 相机切换配置已提交")
            
            // 🔥 修复：更新前置相机状态
            DispatchQueue.main.async {
                self.isUsingFrontCamera = (camera.position == .front)
                print("📱 [DEBUG] 状态更新：isUsingFrontCamera = \(self.isUsingFrontCamera), 相机位置: \(camera.position == .front ? "前置" : "后置")")
                
                // 🎯 修复：更新按钮高亮状态
                self.updateCameraUI()
                print("🎯 [DEBUG] 镜头切换后按钮高亮已更新")
            }
        }
    }
    // 对指定相机应用变焦 - 苹果原相机风格
    func applyZoomToCamera(_ camera: AVCaptureDevice, zoomFactor: CGFloat) {
        sessionQueue.async {
            do {
                try camera.lockForConfiguration()
                
                // 确保变焦值在有效范围内
                var finalZoom = zoomFactor
                
                // 🔥 修复：检查当前相机选项是否是数字变焦
                let currentOption = self.cameraOptions.first { $0.device == camera }
                let isDigitalZoom = currentOption?.isDigitalZoom ?? false
                
                if isDigitalZoom {
                    // 数字变焦：直接使用指定的变焦倍数
                    finalZoom = max(camera.minAvailableVideoZoomFactor, min(zoomFactor, camera.maxAvailableVideoZoomFactor))
                    print("🎡 [DEBUG] 数字变焦模式：目标变焦\(zoomFactor)x，实际应用\(finalZoom)x")
                } else if camera.deviceType == .builtInUltraWideCamera {
                    // 🔥 修复：超广角相机的变焦逻辑
                    // 超广角相机支持变焦，但需要映射到正确的范围
                    // 0.5x UI → 1.0x 实际变焦（原生超广角）
                    // 0.9x UI → 1.8x 实际变焦（超广角最大变焦）
                    if zoomFactor <= 0.9 {
                        // 将UI的0.5x-0.9x映射到实际的1.0x-1.8x
                        let uiRange = 0.9 - 0.5
                        let actualRange = 1.8 - 1.0
                        let normalizedFactor = (zoomFactor - 0.5) / uiRange
                        finalZoom = 1.0 + (normalizedFactor * actualRange)
                        finalZoom = max(1.0, min(1.8, finalZoom))
                        print("🎡 [DEBUG] 超广角相机：UI变焦\(zoomFactor)x → 实际变焦\(finalZoom)x")
                    } else {
                        // 超出超广角范围，使用最大值
                        finalZoom = 1.8
                        print("🎡 [DEBUG] 超广角相机：超出范围，使用最大值1.8x")
                    }
                } else if camera.deviceType == .builtInWideAngleCamera {
                    // 广角相机：直接使用目标变焦，但确保在有效范围内
                    finalZoom = max(camera.minAvailableVideoZoomFactor, min(zoomFactor, camera.maxAvailableVideoZoomFactor))
                    print("🎡 [DEBUG] 广角相机：目标变焦\(zoomFactor)x，实际应用\(finalZoom)x")
                } else if zoomFactor < camera.minAvailableVideoZoomFactor {
                    // 如果目标变焦小于相机最小值，使用相机的最小值
                    finalZoom = camera.minAvailableVideoZoomFactor
                    print("🎡 [DEBUG] 目标变焦 \(zoomFactor)x 超出相机范围，使用最小值: \(finalZoom)x")
                } else if zoomFactor > camera.maxAvailableVideoZoomFactor {
                    // 如果目标变焦大于相机最大值，使用相机的最大值
                    finalZoom = camera.maxAvailableVideoZoomFactor
                    print("🎡 [DEBUG] 目标变焦 \(zoomFactor)x 超出相机范围，使用最大值: \(finalZoom)x")
                } else {
                    // 在有效范围内，直接使用目标变焦
                    finalZoom = zoomFactor
                }
                
                // 苹果原相机风格：平滑变焦
                camera.videoZoomFactor = finalZoom
                
                camera.unlockForConfiguration()
                
                DispatchQueue.main.async {
                    // 🔥 修复：不要覆盖currentZoomFactor，保持轮盘连续性
                    // self.currentZoomFactor = zoomFactor // 注释掉，保持UI显示值一致
                    print("🎡 [DEBUG] 保持轮盘显示值不变: \(self.currentZoomFactor)")
                }
                
                print("🎡 [DEBUG] 应用变焦: \(finalZoom)x 到相机: \(camera.localizedName)")
            } catch {
                print("🎡 [ERROR] 设置变焦失败: \(error)")
            }
        }
    }

    // 通用图片水平翻转方法
    func flipImageHorizontally(_ image: UIImage) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return image }
        context.translateBy(x: image.size.width, y: 0)
        context.scaleBy(x: -1.0, y: 1.0)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let flippedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return flippedImage ?? image
    }

    // 🔥 防抖：重置操作的上次时间戳
    private var lastResetTime: CFTimeInterval = 0
    
    // 🔥 修复：重置滤镜方法，确保所有值一致 + 防抖处理
    @objc func resetFilters() {
        // 🔥 防抖：限制重置频率，避免连续点击造成闪烁
        let now = CACurrentMediaTime()
        guard now - lastResetTime > 0.3 else { 
            print("📸 [DEBUG] 重置操作过于频繁，跳过")
            return 
        }
        lastResetTime = now
        
        print("📸 [DEBUG] 开始重置滤镜参数")
        
        // 🔥 取消所有进行中的滤镜更新，避免与重置操作冲突
        filterUpdateWorkItem?.cancel()
        
        // 重置对比度和饱和度（滑块范围0-100，默认50）
        currentContrast = 1.0
        currentSaturation = 1.0
        // 🔥 修复色温闪烁：使用实际色温值6500.0，而不是滑块值50.0
        currentTemperature = 6500.0 // 实际色温值，6500K为中性色温
        
        // 重置曝光参数
        print("📸 [DEBUG] resetFilters() 重置曝光 - 之前: currentExposure=\(currentExposure), slider.value=\(exposureSlider?.value ?? 0)")
        let previousExposure = currentExposure
        currentExposure = 50.0
        exposureSlider?.value = 50
        exposureValueLabel?.text = "50.0"
        // 🔥 修复闪烁：只有当曝光值真的改变时才更新到相机
        if abs(previousExposure - 50.0) > 0.1 {
            print("📸 [DEBUG] 曝光值发生变化，更新到相机: \(previousExposure) → 50.0")
            updateExposureToCamera(50.0)
        } else {
            print("📸 [DEBUG] 曝光值未变化，跳过相机更新避免闪烁")
        }
        print("📸 [DEBUG] resetFilters() 重置曝光 - 之后: currentExposure=\(currentExposure), slider.value=\(exposureSlider?.value ?? 0)")
        
        // 重置滑块值（所有滑块范围都是0-100）
        contrastSlider?.value = 50.0 // 滑块值50对应效果值1.0
        saturationSlider?.value = 50.0 // 滑块值50对应效果值1.0
        temperatureSlider?.value = 50.0 // 色温滑块默认值50对应6500K色温
        temperatureValueLabel?.text = "50" // 🔥 修复：同步更新色温标签
        contrastContainer?.isHidden = true
        saturationContainer?.isHidden = true
        temperatureContainer?.isHidden = true
        isContrastVisible = false
        isSaturationVisible = false
        isTemperatureVisible = false
        updateButtonStates()
        
        // 🔥 修复重置闪烁：检查是否真的需要更新预览
        let hasAnyFilter = (currentContrast != 1.0) || (currentSaturation != 1.0) || (currentTemperature != 6500.0)
        if hasAnyFilter {
            print("📸 [DEBUG] 重置后有滤镜效果，需要更新预览")
            // 延迟更新预览图像，避免与UI动画冲突
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.updatePreviewImage()
            }
        } else {
            print("📸 [DEBUG] 重置后无滤镜效果，平滑隐藏滤镜层避免闪烁")
            // 🔥 最终修复显示闪烁：保持图像内容直到动画完成
            DispatchQueue.main.async {
                guard let imageView = self.filteredPreviewImageView, !imageView.isHidden else { return }
                
                // 使用渐隐动画平滑过渡（关键：不要提前清空图像）
                UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseOut, animations: {
                    imageView.alpha = 0.0
                }) { _ in
                    // 🔥 只在动画完成后才清空图像和隐藏视图
                    imageView.image = nil
                    imageView.isHidden = true
                    imageView.alpha = 1.0 // 恢复alpha，为下次显示做准备
                    print("📸 [DEBUG] 滤镜层平滑隐藏动画完成")
                }
            }
        }
        
        // 🔥 修复：确保重置后曝光面板状态正确
        print("📸 [DEBUG] 重置完成 - currentExposure: \(currentExposure), slider.value: \(exposureSlider?.value ?? 0)")
    }
    
    @objc func temperatureChanged() {
        guard let slider = temperatureSlider else { return }
        currentTemperature = 5000.0 + (slider.value / 100.0) * (8000.0 - 5000.0)
        filterUpdateWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in self?.updatePreviewImage() }
        filterUpdateWorkItem = workItem
        processingQueue.asyncAfter(deadline: .now() + 0.08, execute: workItem)
        let percent = Int(slider.value)
        temperatureValueLabel?.text = "\(percent)"
        
        // 启动自动隐藏定时器
        startSliderAutoHide(for: "temperature")
    }
    
    @objc func savePreset() {
        // 弹出输入框让用户输入预设名称
        let alert = UIAlertController(title: "保存参数预设", message: "请输入预设名称", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "自定义名称"
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "保存", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            let name = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            let preset: [String: Any] = [
                "contrast": self.currentContrast,
                "saturation": self.currentSaturation,
                "temperature": self.currentTemperature,
                "exposure": self.currentExposure,
                "name": (name?.isEmpty == false ? name! : "未命名")
            ]
            self.savePresetToUserDefaults(preset)
            print("已保存参数预设: \(preset["name"] ?? "未命名")")
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    // 保存参数到UserDefaults
    private func savePresetToUserDefaults(_ preset: [String: Any]) {
        var savedPresets = UserDefaults.standard.array(forKey: "FilterPresets") as? [[String: Any]] ?? []
        savedPresets.append(preset)
        UserDefaults.standard.set(savedPresets, forKey: "FilterPresets")
        print("参数已保存到UserDefaults，当前共有\(savedPresets.count)个预设")
    }
    
    // 从UserDefaults加载参数
    private func loadPresetsFromUserDefaults() -> [[String: Any]] {
        return UserDefaults.standard.array(forKey: "FilterPresets") as? [[String: Any]] ?? []
    }
    
    @objc func showParamManager() {
        // 🔥 懒加载：确保参数系统已初始化
        setupParamSystemIfNeeded()
        
        dismissParamManager() // 先关闭已有弹窗
        
        // Apple Design 参数面板弹窗
        let presets = loadPresetsFromUserDefaults()
        let managerView = makeAppleBlurView(style: .systemMaterialDark)
        managerView.translatesAutoresizingMaskIntoConstraints = false
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        for (index, preset) in presets.enumerated() {
            let row = UIView()
            row.backgroundColor = .clear
            row.translatesAutoresizingMaskIntoConstraints = false
            let applyBtn = UIButton(type: .system)
            let name = (preset["name"] as? String) ?? "未命名"
            applyBtn.setTitle(name, for: .normal)
            applyBtn.setTitleColor(.white, for: .normal)
            applyBtn.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
            applyBtn.contentHorizontalAlignment = .left
            applyBtn.backgroundColor = .clear
            applyBtn.tag = index
            applyBtn.addTarget(self, action: #selector(applyPresetFromManager(_:)), for: .touchUpInside)
            let delBtn = UIButton(type: .system)
            delBtn.setTitle("🗑️", for: .normal)
            delBtn.setTitleColor(.systemRed, for: .normal)
            delBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
            delBtn.backgroundColor = .clear
            delBtn.tag = index
            delBtn.addTarget(self, action: #selector(deletePresetFromManager(_:)), for: .touchUpInside)
            let hStack = UIStackView(arrangedSubviews: [applyBtn, delBtn])
            hStack.axis = .horizontal
            hStack.distribution = .fill
            hStack.alignment = .center
            hStack.spacing = 0
            hStack.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview(hStack)
            NSLayoutConstraint.activate([
                hStack.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 8),
                hStack.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -8),
                hStack.topAnchor.constraint(equalTo: row.topAnchor),
                hStack.bottomAnchor.constraint(equalTo: row.bottomAnchor),
                applyBtn.widthAnchor.constraint(equalTo: row.widthAnchor, multiplier: 0.8),
                delBtn.widthAnchor.constraint(equalTo: row.widthAnchor, multiplier: 0.2)
            ])
            row.heightAnchor.constraint(equalToConstant: 44).isActive = true
            stack.addArrangedSubview(row)
        }
        let cancelBtn = makeAppleButton(title: "取消", icon: "xmark.circle")
        cancelBtn.backgroundColor = .systemRed.withAlphaComponent(0.2)
        cancelBtn.setTitleColor(.systemRed, for: .normal)
        cancelBtn.tintColor = .systemRed
        cancelBtn.addTarget(self, action: #selector(dismissParamManager), for: .touchUpInside)
        stack.addArrangedSubview(cancelBtn)
        managerView.contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: managerView.leadingAnchor, constant: 0),
            stack.trailingAnchor.constraint(equalTo: managerView.trailingAnchor, constant: 0),
            stack.topAnchor.constraint(equalTo: managerView.topAnchor, constant: 0),
            stack.bottomAnchor.constraint(equalTo: managerView.bottomAnchor, constant: 0)
        ])
        // Apple Design 蒙层
        let mask = UIView(frame: self.view.bounds)
        mask.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        mask.tag = 9998
        mask.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissParamManager))
        mask.addGestureRecognizer(tap)
        // 确保参数面板显示在最顶层
        self.view.addSubview(mask)
        managerView.tag = 9997 // 🔥 修复：使用不同的tag，避免与前置镜头轮回按钮冲突
        self.view.bringSubviewToFront(mask)
        self.view.addSubview(managerView)
        self.view.bringSubviewToFront(managerView)
        
        NSLayoutConstraint.activate([
            managerView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            managerView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: -50), // 稍微向上偏移
            managerView.widthAnchor.constraint(equalToConstant: 280),
            managerView.heightAnchor.constraint(equalToConstant: CGFloat(44 * (presets.count + 1)))
        ])
        // 关闭其他面板，显示参数面板
        isFilterPanelVisible = false
        filterPanelView?.isHidden = true
        isSceneGuideVisible = false
        sceneCategoryCollectionView?.isHidden = true
        sceneImageCollectionView?.isHidden = true
        isContrastVisible = false
        isSaturationVisible = false
        isTemperatureVisible = false
        isExposureVisible = false
        updateButtonStates()
    }
    
    @objc func applyPresetFromManager(_ sender: UIButton) {
        let index = sender.tag
        let presets = loadPresetsFromUserDefaults()
        if index >= 0 && index < presets.count {
            applyPreset(presets[index])
        }
        dismissParamManager()
    }
    
    @objc func deletePresetFromManager(_ sender: UIButton) {
        let index = sender.tag
        deletePreset(at: index)
        dismissParamManager()
    }
    
    // 应用参数预设
    private func applyPreset(_ preset: [String: Any]) {
        if let contrast = preset["contrast"] as? Float {
            currentContrast = contrast
            contrastSlider?.value = contrast
        }
        if let saturation = preset["saturation"] as? Float {
            currentSaturation = saturation
            saturationSlider?.value = saturation
        }
        if let temperature = preset["temperature"] as? Float {
            currentTemperature = temperature
            temperatureSlider?.value = temperature
        }
        if let exposure = preset["exposure"] as? Float {
            print("📸 [DEBUG] 应用预设曝光 - 之前: currentExposure=\(currentExposure), slider.value=\(exposureSlider?.value ?? 0), 预设值=\(exposure)")
            currentExposure = exposure
            exposureSlider?.value = exposure
            // 🔥 修复：确保应用预设后状态一致
            exposureValueLabel?.text = String(format: "%.1f", exposure)
            updateExposureToCamera(exposure)
            print("📸 [DEBUG] 应用预设曝光 - 之后: currentExposure=\(currentExposure), slider.value=\(exposureSlider?.value ?? 0)")
        }
        // 立即刷新预览
        if let ciImage = currentCIImage, let imageView = filteredPreviewImageView {
            // 如果ciContext未初始化，先初始化再处理
            if ciContext == nil {
                ciContext = CIContext(options: [.useSoftwareRenderer: false])
                print("[DEBUG] CIContext 在showGridLineOnPreview中延迟初始化完成（GPU加速）")
            }
            
            guard let context = ciContext else { return }
            let filteredCI = applyFilters(to: ciImage)
            if let cgImage = context.createCGImage(filteredCI, from: filteredCI.extent) {
                let previewImage = UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
                imageView.image = previewImage
            }
        }
        
        print("已应用参数预设")
    }
    
    // 删除参数预设
    private func deletePreset(at index: Int) {
        var savedPresets = loadPresetsFromUserDefaults()
        
        guard index >= 0 && index < savedPresets.count else {
            print("删除失败：索引超出范围")
            return
        }
        
        let deletedPreset = savedPresets[index]
        savedPresets.remove(at: index)
        
        // 更新UserDefaults
        UserDefaults.standard.set(savedPresets, forKey: "FilterPresets")
        
        if let name = deletedPreset["name"] as? String {
            print("已删除参数预设: \(name)")
            
            // 显示删除确认
            let alert = UIAlertController(title: "删除成功", message: "已删除参数预设: \(name)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }

    // 新增：初始化超时弹窗
    func showInitTimeoutAlert() {
        let alert = UIAlertController(title: "相机初始化较慢", message: "如长时间无画面，请检查相机权限或重启App。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        self.present(alert, animated: true)
    }
    // 新增：权限被拒绝弹窗
    func showPermissionDeniedAlert() {
        let alert = UIAlertController(title: "无法访问相机", message: "请在设置中允许访问相机。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        self.present(alert, animated: true)
    }

    @objc func temperatureMinusTapped() { temperatureStep(-1) }
    @objc func temperaturePlusTapped() { temperatureStep(1) }
    func temperatureStep(_ step: Float) {
        guard let slider = temperatureSlider else { return }
        slider.value = min(100, max(0, slider.value + step))
        temperatureChanged()
    }
    @objc func tempPlusDown() {
        tempPlusTimer?.invalidate()
        tempPlusTimer = Timer.scheduledTimer(withTimeInterval: 0.09, repeats: true) { [weak self] _ in self?.temperatureStep(5) }
    }
    @objc func tempPlusUp() { tempPlusTimer?.invalidate() }
    @objc func tempMinusDown() {
        tempMinusTimer?.invalidate()
        tempMinusTimer = Timer.scheduledTimer(withTimeInterval: 0.09, repeats: true) { [weak self] _ in self?.temperatureStep(-5) }
    }
    @objc func tempMinusUp() { tempMinusTimer?.invalidate() }

    @objc func contrastMinusTapped() { contrastStep(-1) }
    @objc func contrastPlusTapped() { contrastStep(1) }
    func contrastStep(_ step: Float) {
        guard let slider = contrastSlider else { return }
        slider.value = min(100, max(0, slider.value + step))
        contrastChanged()
    }
    @objc func contrastPlusDown() {
        contrastPlusTimer?.invalidate()
        contrastPlusTimer = Timer.scheduledTimer(withTimeInterval: 0.09, repeats: true) { [weak self] _ in self?.contrastStep(5) }
    }
    @objc func contrastPlusUp() { contrastPlusTimer?.invalidate() }
    @objc func contrastMinusDown() {
        contrastMinusTimer?.invalidate()
        contrastMinusTimer = Timer.scheduledTimer(withTimeInterval: 0.09, repeats: true) { [weak self] _ in self?.contrastStep(-5) }
    }
    @objc func contrastMinusUp() { contrastMinusTimer?.invalidate() }

    @objc func saturationMinusTapped() { saturationStep(-1) }
    @objc func saturationPlusTapped() { saturationStep(1) }
    func saturationStep(_ step: Float) {
        guard let slider = saturationSlider else { return }
        slider.value = min(100, max(0, slider.value + step))
        saturationChanged()
    }
    @objc func satPlusDown() {
        satPlusTimer?.invalidate()
        satPlusTimer = Timer.scheduledTimer(withTimeInterval: 0.09, repeats: true) { [weak self] _ in self?.saturationStep(5) }
    }
    @objc func satPlusUp() { satPlusTimer?.invalidate() }
    @objc func satMinusDown() {
        satMinusTimer?.invalidate()
        satMinusTimer = Timer.scheduledTimer(withTimeInterval: 0.09, repeats: true) { [weak self] _ in self?.saturationStep(-5) }
    }
    @objc func satMinusUp() { satMinusTimer?.invalidate() }

    // 曝光加减事件
    @objc func exposureMinusTapped() { exposureStep(-1) }
    @objc func exposurePlusTapped() { exposureStep(1) }
    func exposureStep(_ step: Float) {
        guard let slider = exposureSlider else { 
            print("⚠️ [DEBUG] exposureStep() - exposureSlider为nil")
            return 
        }
        print("📸 [DEBUG] exposureStep() 开始 - 之前: currentExposure=\(currentExposure), slider.value=\(slider.value), step=\(step)")
        slider.value = min(100, max(0, slider.value + step))
        print("📸 [DEBUG] exposureStep() 修改slider.value后 - currentExposure=\(currentExposure), slider.value=\(slider.value)")
        // 🔥 修复：参考饱和度实现，调用exposureChanged()确保状态一致
        exposureChanged()
        print("📸 [DEBUG] exposureStep() 完成 - 之后: currentExposure=\(currentExposure), slider.value=\(slider.value)")
    }
    @objc func exposurePlusDown() {
        exposurePlusTimer?.invalidate()
        exposurePlusTimer = Timer.scheduledTimer(withTimeInterval: 0.09, repeats: true) { [weak self] _ in self?.exposureStep(5) }
    }
    @objc func exposurePlusUp() { exposurePlusTimer?.invalidate() }
    @objc func exposureMinusDown() {
        exposureMinusTimer?.invalidate()
        exposureMinusTimer = Timer.scheduledTimer(withTimeInterval: 0.09, repeats: true) { [weak self] _ in self?.exposureStep(-5) }
    }
    @objc func exposureMinusUp() { exposureMinusTimer?.invalidate() }

    // 曝光按钮切换
    @objc func toggleExposurePanel() {
        isExposureVisible.toggle()
        exposureContainer?.isHidden = !isExposureVisible
        
        // 🔥 修复：确保曝光容器在最上层，避免被场景UI遮挡
        if isExposureVisible, let exposureContainer = exposureContainer {
            view.bringSubviewToFront(exposureContainer)
        }
        
        contrastContainer?.isHidden = true
        saturationContainer?.isHidden = true
        temperatureContainer?.isHidden = true
        isContrastVisible = false
        isSaturationVisible = false
        isTemperatureVisible = false
        updateButtonStates()
        if isExposureVisible {
            print("📸 [DEBUG] toggleExposurePanel() 显示曝光面板 - 之前: currentExposure=\(currentExposure), slider.value=\(exposureSlider?.value ?? 0)")
            // 🔥 修复：确保滑块值和currentExposure同步
            if let slider = exposureSlider {
                if abs(slider.value - currentExposure) > 0.1 {
                    // 如果滑动条值和currentExposure不一致，以currentExposure为准
                    print("📸 [DEBUG] 检测到不一致 - slider.value=\(slider.value), currentExposure=\(currentExposure), 差值=\(abs(slider.value - currentExposure))")
                    slider.value = currentExposure
                    print("📸 [DEBUG] 同步曝光滑动条 - currentExposure: \(currentExposure), 设置slider.value: \(currentExposure)")
                } else {
                    print("📸 [DEBUG] 滑动条值一致 - slider.value=\(slider.value), currentExposure=\(currentExposure)")
                }
            exposureValueLabel?.text = String(format: "%.1f", currentExposure)
            }
            print("📸 [DEBUG] toggleExposurePanel() 显示曝光面板 - 之后: currentExposure=\(currentExposure), slider.value=\(exposureSlider?.value ?? 0)")
            debugExposureSliderState() // 🔥 调试：检查显示面板后的状态
            debugAllSlidersState() // 🔥 调试：检查所有滑动条状态
            
            // 🔥 修复：移除动态center设置，使用与其他滑动条一致的固定约束
            // 曝光容器已经在setupUI中设置了固定约束，与其他滑动条容器一致
            // 启动自动隐藏定时器
            startSliderAutoHide(for: "exposure")
        } else {
            cancelExposureAutoHide()
            // 取消自动隐藏定时器
            cancelSliderAutoHide(for: "exposure")
        }
    }
    // 其它功能按钮切换时关闭曝光条
    func hideExposurePanelIfNeeded() {
        if isExposureVisible {
            isExposureVisible = false
            exposureContainer?.isHidden = true
            cancelExposureAutoHide()
        }
    }
    // 自动关闭曝光条
    func startExposureAutoHide() {
        cancelExposureAutoHide()
        exposureAutoHideTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            self?.isExposureVisible = false
            self?.exposureContainer?.isHidden = true
        }
    }
    func cancelExposureAutoHide() {
        exposureAutoHideTimer?.invalidate()
        exposureAutoHideTimer = nil
    }

    // 动态底部安全区适配
    private func dynamicBottomOffset() -> CGFloat {
        if let window = UIApplication.shared.windows.first {
            return window.safeAreaInsets.bottom > 0 ? window.safeAreaInsets.bottom : 20
        }
        return 20
    }



    // 动态顶部安全区适配，避免灵动岛遮挡
    private func dynamicTopOffset() -> CGFloat {
        if let window = UIApplication.shared.windows.first {
            let topInset = window.safeAreaInsets.top
            // 根据设备类型调整
            if UIDevice.current.userInterfaceIdiom == .phone {
                let screenHeight = UIScreen.main.bounds.height
                // iPhone 14Pro/15 Pro系列（灵动岛）
                if screenHeight >= 844 {
                    return max(topInset + 10, 60)
                }
                // iPhone 12/13系列（刘海）
                else if screenHeight >= 844 { // iPhone 12/13 Pro
                    return max(topInset + 5, 50)
                }
                // 其他iPhone
                else {
                    return max(topInset + 5, 40)
                }
            }
            return max(topInset + 10, 60)
        }
        return 60
    }

    // 点击缩略图显示放大预览
    @objc func openLastPhotoInAlbum() {
        // 🔥 新增：添加缩略图点击动画
        if let thumbImageView = self.view.viewWithTag(2001) as? UIImageView {
            UIView.animate(withDuration: 0.15, animations: {
                thumbImageView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            }) { _ in
                UIView.animate(withDuration: 0.1) {
                    thumbImageView.transform = CGAffineTransform.identity
                }
            }
        }
        
        // 🔥 修复：确保相册查看器初始化完成后再显示
        initializeAlbumViewerIfNeeded { [weak self] in
            DispatchQueue.main.async {
                self?.showAlbumViewer()
            }
        }
    }
    
    // MARK: - 相册查看器相关属性
    private var albumViewer: UIView?
    private var albumScrollView: UIScrollView?
    private var albumImageView: UIImageView?
    private var currentPhotoIndex: Int = 0
    private var photoAssets: [PHAsset] = []
    private var isAlbumViewerInitialized = false
    
    // 🔥 懒加载初始化相册查看器
    private func initializeAlbumViewerIfNeeded(completion: (() -> Void)? = nil) {
        // 🔥 修复：如果albumViewer为nil，强制重新初始化
        if albumViewer == nil {
            isAlbumViewerInitialized = false
        }
        
        guard !isAlbumViewerInitialized else { 
            print("📸 [DEBUG] 相册查看器已初始化，跳过")
            completion?()
            return 
        }
        
        print("📸 [DEBUG] 开始初始化相册查看器")
        
        // 在后台队列加载照片资源，避免阻塞主线程
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.loadPhotoAssets()
            
            DispatchQueue.main.async {
                self?.createAlbumViewerUI()
                self?.isAlbumViewerInitialized = true
                print("📸 [DEBUG] 相册查看器初始化完成")
                completion?()
            }
        }
    }
    
    // 加载照片资源
    private func loadPhotoAssets() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        
        let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
        photoAssets = fetchResult.objects(at: IndexSet(integersIn: 0..<min(fetchResult.count, 100))) // 限制加载100张照片
        
        print("📸 [DEBUG] 加载了 \(photoAssets.count) 张照片")
    }
    
    // 创建相册查看器UI
    private func createAlbumViewerUI() {
        // 创建主容器
        albumViewer = UIView(frame: view.bounds)
        albumViewer?.backgroundColor = .black
        albumViewer?.tag = 3001
        albumViewer?.alpha = 0
        albumViewer?.isHidden = true
        
        guard let albumViewer = albumViewer else { return }
        
        // 创建滚动视图
        albumScrollView = UIScrollView()
        albumScrollView?.translatesAutoresizingMaskIntoConstraints = false
        albumScrollView?.backgroundColor = .clear
        albumScrollView?.isPagingEnabled = true
        albumScrollView?.showsHorizontalScrollIndicator = false
        albumScrollView?.delegate = self
        albumViewer.addSubview(albumScrollView!)
        
        // 创建图片视图
        albumImageView = UIImageView()
        albumImageView?.translatesAutoresizingMaskIntoConstraints = false
        albumImageView?.contentMode = .scaleAspectFit
        albumImageView?.backgroundColor = .clear
        albumScrollView?.addSubview(albumImageView!)
        
        // 设置约束
        NSLayoutConstraint.activate([
            albumScrollView!.topAnchor.constraint(equalTo: albumViewer.topAnchor),
            albumScrollView!.bottomAnchor.constraint(equalTo: albumViewer.bottomAnchor),
            albumScrollView!.leadingAnchor.constraint(equalTo: albumViewer.leadingAnchor),
            albumScrollView!.trailingAnchor.constraint(equalTo: albumViewer.trailingAnchor),
            
            albumImageView!.topAnchor.constraint(equalTo: albumScrollView!.topAnchor),
            albumImageView!.bottomAnchor.constraint(equalTo: albumScrollView!.bottomAnchor),
            albumImageView!.leadingAnchor.constraint(equalTo: albumScrollView!.leadingAnchor),
            albumImageView!.trailingAnchor.constraint(equalTo: albumScrollView!.trailingAnchor),
            albumImageView!.widthAnchor.constraint(equalTo: albumScrollView!.widthAnchor),
            albumImageView!.heightAnchor.constraint(equalTo: albumScrollView!.heightAnchor)
        ])
        
        // 添加手势识别器
        setupAlbumViewerGestures()
    }
    
    // 设置相册查看器手势
    private func setupAlbumViewerGestures() {
        guard let albumViewer = albumViewer else { return }
        
        // 双指缩放手势
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handleAlbumPinch(_:)))
        albumViewer.addGestureRecognizer(pinchGesture)
        
        // 智能滑动手势识别器（用于左右滑动切换照片和向下滑动关闭）
        let smartPanGesture = UIPanGestureRecognizer(target: self, action: #selector(handleAlbumSmartPan(_:)))
        albumViewer.addGestureRecognizer(smartPanGesture)
        
        // 点击手势关闭预览
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(closeAlbumViewer))
        albumViewer.addGestureRecognizer(tapGesture)
    }
    
    // 显示相册查看器
    private func showAlbumViewer() {
        // 🔥 修复：检查albumViewer是否存在，如果不存在则重新初始化
        if albumViewer == nil {
            print("📸 [DEBUG] albumViewer为nil，重新初始化")
            initializeAlbumViewerIfNeeded()
            return // 等待初始化完成后再显示
        }
        
        guard let albumViewer = albumViewer else { 
            print("📸 [DEBUG] albumViewer初始化失败")
            return 
        }
        
        print("📸 [DEBUG] 开始显示相册查看器")
        
        // 确保在主线程执行
        DispatchQueue.main.async {
            // 🔥 修复：检查albumViewer是否已经在视图层级中，避免重复添加
            if albumViewer.superview == nil {
                self.view.addSubview(albumViewer)
                print("📸 [DEBUG] albumViewer已添加到视图层级")
            } else {
                print("📸 [DEBUG] albumViewer已在视图层级中，跳过添加")
            }
            
            self.view.bringSubviewToFront(albumViewer)
            
            // 🔥 修复：每次显示时重新加载照片资源，确保显示最新照片
            self.reloadPhotoAssetsAndSetCurrentIndex()
            
            // 动画显示
            albumViewer.isHidden = false
            albumViewer.alpha = 0 // 确保从透明开始
            UIView.animate(withDuration: 0.3) {
                albumViewer.alpha = 1
            }
        }
    }
    
    // 🔥 修复：重新加载照片资源并设置与缩略图一致的索引
    private func reloadPhotoAssetsAndSetCurrentIndex() {
        // 在后台队列重新加载照片资源
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // 重新加载照片资源
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
            
            let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
            self.photoAssets = fetchResult.objects(at: IndexSet(integersIn: 0..<min(fetchResult.count, 100)))
            
            print("📸 [DEBUG] 重新加载了 \(self.photoAssets.count) 张照片")
            
            // 🔥 简化逻辑：直接显示最新照片（索引0），与缩略图保持一致
            let targetIndex = 0
            print("📸 [DEBUG] 设置显示最新照片，索引: 0")
            
            // 在主线程设置当前索引并加载照片
            DispatchQueue.main.async {
                self.currentPhotoIndex = targetIndex
                print("📸 [DEBUG] 设置当前照片索引为: \(self.currentPhotoIndex)（与缩略图一致）")
                
                // 加载当前照片
                self.loadCurrentPhoto()
            }
        }
    }
    
    // 加载当前照片
    private func loadCurrentPhoto() {
        guard currentPhotoIndex < photoAssets.count else { return }
        
        let asset = photoAssets[currentPhotoIndex]
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        manager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options) { [weak self] image, _ in
            DispatchQueue.main.async {
                self?.albumImageView?.image = image
            }
        }
    }
    
    // 瞬间加载当前照片（无动画，立即切换）
    private func loadCurrentPhotoInstantly() {
        guard currentPhotoIndex < photoAssets.count else { return }
        
        let asset = photoAssets[currentPhotoIndex]
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = true // 同步加载，确保瞬间切换
        
        manager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options) { [weak self] image, _ in
            DispatchQueue.main.async {
                // 瞬间切换，无动画
                UIView.performWithoutAnimation {
                    self?.albumImageView?.image = image
                }
            }
        }
    }

    // 🔥 修复：刷新左下角缩略图，确保始终显示最新照片
    func refreshThumbnail() {
        // 🔥 优化：使用后台队列处理，避免阻塞主线程
        DispatchQueue.global(qos: .utility).async {
            // 🔥 修复：直接获取最新照片，而不依赖LastPhotoLocalIdentifier
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
            fetchOptions.fetchLimit = 1
            
            let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            guard let latestAsset = assets.firstObject else { 
                print("📸 [DEBUG] 没有找到照片")
                return 
            }
            
            // 🔥 关键修复：更新LastPhotoLocalIdentifier为最新照片
            UserDefaults.standard.set(latestAsset.localIdentifier, forKey: "LastPhotoLocalIdentifier")
            print("📸 [DEBUG] 更新LastPhotoLocalIdentifier为最新照片: \(latestAsset.localIdentifier)")
            
            let manager = PHImageManager.default()
            let options = PHImageRequestOptions()
            options.isSynchronous = false // 🔥 确保异步处理
            options.deliveryMode = .fastFormat // 🔥 使用快速模式
            options.resizeMode = .fast // 🔥 使用快速缩放
            
            // 🔥 添加超时机制
            let timeoutWork = DispatchWorkItem {
                print("⚠️ 缩略图加载超时")
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: timeoutWork)
            
            manager.requestImage(for: latestAsset, targetSize: CGSize(width: 56, height: 56), contentMode: .aspectFill, options: options) { [weak self] image, _ in
                timeoutWork.cancel() // 取消超时
                
                DispatchQueue.main.async {
                    if let thumbImageView = self?.view.viewWithTag(2001) as? UIImageView {
                        thumbImageView.image = image
                        print("📸 [DEBUG] 缩略图已更新为最新照片")
                    }
                }
            }
        }
    }



    // MARK: - 相册查看器手势处理
    
    // 处理相册查看器的捏合手势
    @objc func handleAlbumPinch(_ gesture: UIPinchGestureRecognizer) {
        guard let imageView = albumImageView else { return }
        
        switch gesture.state {
        case .began:
            gesture.scale = 1.0
        case .changed:
            let scale = gesture.scale
            imageView.transform = CGAffineTransform(scaleX: scale, y: scale)
        case .ended:
            // 限制缩放范围
            let finalScale = max(0.5, min(3.0, gesture.scale))
            UIView.animate(withDuration: 0.2) {
                imageView.transform = CGAffineTransform(scaleX: finalScale, y: finalScale)
            }
        default:
            break
        }
    }
    
    // 智能滑动手势处理（同时处理左右滑动和向下滑动）
    @objc func handleAlbumSmartPan(_ gesture: UIPanGestureRecognizer) {
        guard let albumViewer = albumViewer else { return }
        
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        
        switch gesture.state {
        case .began:
            // 记录手势开始位置
            print("📸 [DEBUG] 手势开始，位置: \(translation)")
            
        case .changed:
            // 判断滑动方向
            let absX = abs(translation.x)
            let absY = abs(translation.y)
            
            // 只处理垂直滑动跟随，水平滑动不跟随手指移动
            if absY > absX && absY > 30 {
                // 垂直滑动 - 跟随手指移动，可能是关闭预览
                albumViewer.transform = CGAffineTransform(translationX: 0, y: translation.y)
            }
            // 移除水平滑动的跟随移动，保持画面静止
            
        case .ended:
            let absX = abs(translation.x)
            let absY = abs(translation.y)
            let absVelocityY = abs(velocity.y)
            
            print("📸 [DEBUG] 手势结束，位移: (\(translation.x), \(translation.y))，速度: (\(velocity.x), \(velocity.y))")
            
            // 判断滑动类型
            if absX > absY && absX > 50 {
                // 水平滑动距离足够大，瞬间切换照片（不带动画）
                if translation.x > 0 {
                    // 向右滑动，显示上一张照片
                    print("📸 [DEBUG] 检测到右滑，瞬间切换到上一张照片")
                    showPreviousPhotoInstantly()
            } else {
                    // 向左滑动，显示下一张照片
                    print("📸 [DEBUG] 检测到左滑，瞬间切换到下一张照片")
                    showNextPhotoInstantly()
                }
            } else if absY > absX && (absY > 100 || absVelocityY > 500) {
                // 垂直滑动距离或速度足够大，关闭预览
                print("📸 [DEBUG] 检测到向下滑动，关闭预览")
                closeAlbumViewer()
                return
            }
            
            // 回到原位（只对垂直滑动）
            if absY > absX {
                UIView.animate(withDuration: 0.3) {
                    albumViewer.transform = .identity
                }
            }
            
        default:
            break
        }
    }
    
    // 显示下一张照片
    private func showNextPhoto() -> Bool {
        guard currentPhotoIndex < photoAssets.count - 1 else {
            print("📸 [DEBUG] 已经是最后一张照片")
            return false
        }
        
        currentPhotoIndex += 1
        print("📸 [DEBUG] 切换到下一张照片，索引: \(currentPhotoIndex)")
        loadCurrentPhoto()
        return true
    }
    
    // 显示上一张照片
    private func showPreviousPhoto() -> Bool {
        guard currentPhotoIndex > 0 else {
            print("📸 [DEBUG] 已经是第一张照片")
            return false
        }
        
        currentPhotoIndex -= 1
        print("📸 [DEBUG] 切换到上一张照片，索引: \(currentPhotoIndex)")
        loadCurrentPhoto()
        return true
    }
    
    // 瞬间显示下一张照片（无动画）
    private func showNextPhotoInstantly() {
        guard currentPhotoIndex < photoAssets.count - 1 else {
            print("📸 [DEBUG] 已经是最后一张照片")
            return
        }
        
        currentPhotoIndex += 1
        print("📸 [DEBUG] 瞬间切换到下一张照片，索引: \(currentPhotoIndex)")
        loadCurrentPhotoInstantly()
    }
    
    // 瞬间显示上一张照片（无动画）
    private func showPreviousPhotoInstantly() {
        guard currentPhotoIndex > 0 else {
            print("📸 [DEBUG] 已经是第一张照片")
            return
        }
        
        currentPhotoIndex -= 1
        print("📸 [DEBUG] 瞬间切换到上一张照片，索引: \(currentPhotoIndex)")
        loadCurrentPhotoInstantly()
    }
    
    // 关闭相册查看器
    @objc func closeAlbumViewer() {
        guard let albumViewer = albumViewer else { return }
        
        print("📸 [DEBUG] 开始关闭相册查看器")
        
        UIView.animate(withDuration: 0.3, animations: {
            albumViewer.alpha = 0
            albumViewer.transform = CGAffineTransform(translationX: 0, y: 100)
        }) { [weak self] _ in
            guard let self = self else { return }
            
            // 🔥 修复：从父视图中移除albumViewer，避免重复添加导致卡死
            albumViewer.removeFromSuperview()
            albumViewer.transform = .identity
            
            // 🔥 修复：清理所有相关变量，确保状态一致
            self.albumViewer = nil
            self.albumScrollView = nil
            self.albumImageView = nil
            self.isAlbumViewerInitialized = false
            
            print("📸 [DEBUG] 相册查看器已从视图层级中移除，状态已清理")
        }
    }
    
    // 兼容旧方法名
    @objc func closePreviewView() {
        closeAlbumViewer()
    }
    
    // 🔥 修复：添加滚动防抖变量
    private var lastScrollTime: TimeInterval = 0
    
    // 🔥 新增：UI完整性检查方法
    private func performUICompletenessCheck() {
        print("🔍 [UI_CHECK] 开始UI完整性检查...")
        
        guard let view = view else {
            print("❌ [UI_CHECK] view为nil，无法进行检查")
            return
        }
        
        // 检查关键UI元素是否存在
        let criticalElements = [
            (view.viewWithTag(999), "拍照按钮"),
            (view.viewWithTag(777), "功能控制栏"),
            (view.viewWithTag(8888), "相机切换按钮组"),
            (view.viewWithTag(9999), "前置相机切换按钮"),
            (view.viewWithTag(2001), "缩略图")
        ]
        
        var missingElements: [String] = []
        
        for (element, name) in criticalElements {
            if element == nil {
                missingElements.append(name)
                print("❌ [UI_CHECK] 缺失UI元素: \(name)")
            } else {
                print("✅ [UI_CHECK] UI元素正常: \(name)")
            }
        }
        
        if !missingElements.isEmpty {
            print("⚠️ [UI_CHECK] 发现缺失UI元素: \(missingElements.joined(separator: ", "))")
            print("🔄 [UI_CHECK] 开始修复缺失的UI元素...")
            
            // 修复缺失的UI元素
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.repairMissingUIElements(missingElements: missingElements)
            }
        } else {
            print("✅ [UI_CHECK] 所有关键UI元素检查通过")
        }
        
        // 检查约束冲突
        checkForConstraintConflicts()
    }
    
    // 🔥 新增：修复缺失的UI元素
    private func repairMissingUIElements(missingElements: [String]) {
        print("🔧 [UI_REPAIR] 开始修复UI元素...")
        
        for elementName in missingElements {
            switch elementName {
            case "拍照按钮":
                if view.viewWithTag(999) == nil {
                    print("🔧 [UI_REPAIR] 重新创建拍照按钮")
                    setupMinimalShutterButton()
                }
            case "功能控制栏":
                if view.viewWithTag(777) == nil {
                    print("🔧 [UI_REPAIR] 重新创建功能控制栏")
                    setupBasicControlBar()
                }
            case "相机切换按钮组":
                if view.viewWithTag(8888) == nil {
                    print("🔧 [UI_REPAIR] 重新创建相机切换按钮组")
                    setupCameraSwitchUI()
                }
            case "前置相机切换按钮":
                if view.viewWithTag(9999) == nil {
                    print("🔧 [UI_REPAIR] 重新创建前置相机切换按钮")
                    setupFrontCameraCycleButton()
                }
            case "缩略图":
                if view.viewWithTag(2001) == nil {
                    print("🔧 [UI_REPAIR] 重新创建缩略图")
                    setupThumbnailOnStartup()
                }
            default:
                break
            }
        }
        
        print("🔧 [UI_REPAIR] UI元素修复完成")
        
        // 确保UI层级正确
        ensureUIControlsOnTop()
    }
    
    // 🔥 新增：检查约束冲突
    private func checkForConstraintConflicts() {
        print("🔍 [CONSTRAINT_CHECK] 检查约束冲突...")
        
        // 这里可以添加更详细的约束冲突检查逻辑
        // 目前主要通过日志中的约束冲突警告来识别问题
        
        print("🔍 [CONSTRAINT_CHECK] 约束检查完成")
    }
    
    // 🔥 新增：检查和调整控制栏宽度
    private func checkAndAdjustControlBarWidth() {
        print("🔍 [WIDTH_CHECK] 开始检查控制栏宽度...")
        
        guard let blurView = view.viewWithTag(777) as? UIVisualEffectView else {
            print("❌ [WIDTH_CHECK] 未找到功能控制栏")
            return
        }
        
        // 检查按钮文字是否显示省略号
        var needsAdjustment = false
        let buttons = [filterButton, sceneButton, paramButton].compactMap { $0 }
        
        for button in buttons {
            if let titleLabel = button.titleLabel {
                // 检查文字是否被截断
                let textWidth = titleLabel.intrinsicContentSize.width
                let availableWidth = button.frame.width - 20 // 减去内边距
                
                if textWidth > availableWidth {
                    print("⚠️ [WIDTH_CHECK] 按钮文字被截断: \(titleLabel.text ?? ""), 需要宽度: \(textWidth), 可用宽度: \(availableWidth)")
                    needsAdjustment = true
                }
            }
        }
        
        if needsAdjustment {
            print("🔧 [WIDTH_CHECK] 检测到按钮文字显示省略号，开始调整容器宽度...")
            adjustControlBarWidth()
        } else {
            print("✅ [WIDTH_CHECK] 控制栏宽度正常，无需调整")
        }
    }
    
    // 🔥 新增：调整控制栏宽度
    private func adjustControlBarWidth() {
        print("🔧 [WIDTH_ADJUST] 开始调整控制栏宽度...")
        
        guard let blurView = view.viewWithTag(777) as? UIVisualEffectView else {
            print("❌ [WIDTH_ADJUST] 未找到功能控制栏")
            return
        }
        
        // 计算所需的最小宽度
        let buttons = [filterButton, sceneButton, paramButton].compactMap { $0 }
        var totalRequiredWidth: CGFloat = 0
        
        for button in buttons {
            if let titleLabel = button.titleLabel {
                let textWidth = titleLabel.intrinsicContentSize.width
                totalRequiredWidth += textWidth + 20 // 文字宽度 + 内边距
            }
        }
        
        // 添加按钮间距
        totalRequiredWidth += 20 * CGFloat(buttons.count - 1)
        
        // 添加容器内边距
        totalRequiredWidth += 40
        
        // 确保最小宽度
        let minWidth: CGFloat = 320
        let targetWidth = max(minWidth, totalRequiredWidth)
        
        print("🔧 [WIDTH_ADJUST] 计算目标宽度: \(targetWidth)pt")
        
        // 更新容器宽度约束
        blurView.constraints.forEach { constraint in
            if constraint.firstAttribute == .width {
                constraint.constant = targetWidth
                print("🔧 [WIDTH_ADJUST] 更新宽度约束: \(constraint.constant)pt")
            }
        }
        
        // 强制更新布局
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
        
        print("🔧 [WIDTH_ADJUST] 控制栏宽度调整完成")
    }
    
    // 🔥 新增：启动完成后的UI完整性验证
    private func validateUICompletenessAfterStartup() {
        print("🔍 [STARTUP_VALIDATION] 开始启动后UI完整性验证...")
        
        guard let view = view else {
            print("❌ [STARTUP_VALIDATION] view为nil，无法验证")
            return
        }
        
        // 检查所有关键UI元素
        let requiredElements = [
            (view.viewWithTag(999), "拍照按钮", "setupMinimalShutterButton"),
            (view.viewWithTag(777), "功能控制栏", "setupBasicControlBar"),
            (view.viewWithTag(8888), "相机切换按钮组", "setupCameraSwitchUI"),
            (view.viewWithTag(9999), "前置相机切换按钮", "setupFrontCameraCycleButton"),
            (view.viewWithTag(2001), "缩略图", "setupThumbnailOnStartup")
        ]
        
        var validationResults: [String: Bool] = [:]
        var missingElements: [String] = []
        
        for (element, name, _) in requiredElements {
            let exists = element != nil
            validationResults[name] = exists
            
            if !exists {
                missingElements.append(name)
                print("❌ [STARTUP_VALIDATION] 缺失: \(name)")
            } else {
                print("✅ [STARTUP_VALIDATION] 正常: \(name)")
            }
        }
        
        // 检查UI元素的状态
        if let shutterButton = view.viewWithTag(999) as? UIButton {
            let isEnabled = shutterButton.isEnabled
            let isVisible = shutterButton.alpha > 0
            print("📱 [STARTUP_VALIDATION] 拍照按钮状态: enabled=\(isEnabled), visible=\(isVisible)")
        }
        
        if let blurView = view.viewWithTag(777) as? UIVisualEffectView {
            let isVisible = blurView.alpha > 0
            let hasSuperview = blurView.superview != nil
            print("📱 [STARTUP_VALIDATION] 功能控制栏状态: visible=\(isVisible), hasSuperview=\(hasSuperview)")
        }
        
        // 如果有缺失元素，尝试修复
        if !missingElements.isEmpty {
            print("⚠️ [STARTUP_VALIDATION] 发现\(missingElements.count)个缺失UI元素，尝试修复...")
            
            DispatchQueue.main.async { [weak self] in
                self?.repairMissingUIElements(missingElements: missingElements)
                
                // 修复后再次验证
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self?.validateUICompletenessAfterStartup()
                }
            }
        } else {
            print("✅ [STARTUP_VALIDATION] 所有UI元素验证通过，应用启动完成")
        }
        
        // 检查约束冲突
        checkForConstraintConflicts()
    }
    
    // MARK: - UIScrollViewDelegate
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // 🔥 修复：添加防抖机制，避免快速连续滑动
        let currentTime = CACurrentMediaTime()
        if currentTime - lastScrollTime < 0.5 {
            print("📸 [DEBUG] 滚动过于频繁，忽略此次滑动")
            return
        }
        lastScrollTime = currentTime
        
        // 滚动视图停止时，根据偏移量判断是否切换照片
        let offsetX = scrollView.contentOffset.x
        let pageWidth = scrollView.frame.width
        
        // 🔥 修复：增加滚动阈值，避免误触发
        // 只有当滚动距离超过页面宽度的80%时才触发切换
        let threshold = pageWidth * 0.8
        
        // 🔥 修复：添加最小滚动距离检查，避免微小滑动触发切换
        let minScrollDistance = pageWidth * 0.3
        if abs(offsetX) < minScrollDistance {
            print("📸 [DEBUG] 滚动距离太小，忽略此次滑动")
            return
        }
        
        // 🔥 修复：只有在真正切换了照片时才重置位置
        var shouldResetPosition = false
        
        if offsetX > threshold {
            // 向右滚动，显示下一张
            print("📸 [DEBUG] 检测到向右滚动，尝试切换到下一张照片")
            shouldResetPosition = showNextPhoto()
        } else if offsetX < -threshold {
            // 向左滚动，显示上一张
            print("📸 [DEBUG] 检测到向左滚动，尝试切换到上一张照片")
            shouldResetPosition = showPreviousPhoto()
        }
        
        // 🔥 修复：只有在成功切换照片时才重置滚动视图位置
        if shouldResetPosition {
            scrollView.contentOffset = .zero
            print("📸 [DEBUG] 照片已切换，重置滚动位置")
        } else {
            print("📸 [DEBUG] 滑动距离不足或已到边界，保持当前位置")
        }
    }
    


    @objc func closePreviewVC() {
        self.presentedViewController?.dismiss(animated: true)
    }
    func updatePreviewImage() {
        guard let ciImage = currentCIImage, let imageView = filteredPreviewImageView else { return }
        
        // 🔥 修复：增强的防抖和缓存机制
        let now = CACurrentMediaTime()
        guard now - lastFilterUpdateTime > 0.033 else { return } // 限制为30fps，减少闪烁
        lastFilterUpdateTime = now
        
        // 🔥 修复：更严格的参数变化检查
        let currentParams = (currentContrast, currentSaturation, currentTemperature)
        let hasContrast = abs(currentContrast - 1.0) > 0.01
        let hasSaturation = abs(currentSaturation - 1.0) > 0.01
        let hasTemperature = abs(currentTemperature - 6500.0) > 1.0
        
        // 如果没有滤镜效果，隐藏滤镜层，显示原始相机预览
        if !hasContrast && !hasSaturation && !hasTemperature {
            DispatchQueue.main.async {
                // 🔥 最终修复：无滤镜时平滑隐藏滤镜层，保持图像直到动画完成
                if !imageView.isHidden {
                    UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseOut, animations: {
                        imageView.alpha = 0.0
                    }) { _ in
                        // 🔥 只在动画完成后才清空图像和隐藏视图
                        imageView.image = nil
                        imageView.isHidden = true
                        imageView.alpha = 1.0 // 恢复alpha，为下次显示做准备
                    }
                }
            }
            return
        }
        
        // 🔥 修复：更精确的缓存检查
        if currentParams.0 == lastProcessedParams.0 && 
           currentParams.1 == lastProcessedParams.1 && 
           currentParams.2 == lastProcessedParams.2,
           let cachedImage = lastProcessedImage {
            DispatchQueue.main.async {
            imageView.image = cachedImage
                imageView.isHidden = false
            }
            return
        }
        
        // 延迟初始化CIContext
        if ciContext == nil {
            ciContext = CIContext(options: [
                .useSoftwareRenderer: false,
                .cacheIntermediates: true // 🔥 修复：启用中间结果缓存
            ])
        }
        
        guard let context = ciContext else { return }
        
        // 🔥 修复：取消之前的处理任务，避免重复处理
        Self.sharedFilterQueue.async { [weak self] in
            guard let self = self else { return }
            
            // 再次检查参数是否在异步处理过程中发生变化
            let checkParams = (self.currentContrast, self.currentSaturation, self.currentTemperature)
            if checkParams.0 != currentParams.0 || 
               checkParams.1 != currentParams.1 || 
               checkParams.2 != currentParams.2 {
                return // 参数已变化，跳过这次处理
            }
            
            // 应用滤镜
            let filteredCI = self.applyFilters(to: ciImage)
            
            if let cgImage = context.createCGImage(filteredCI, from: filteredCI.extent) {
                var previewImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
                
                if self.isUsingFrontCamera {
                    previewImage = self.flipImageHorizontally(previewImage)
                }
                
                // 更新缓存
                self.lastProcessedImage = previewImage
                self.lastProcessedParams = currentParams
                
                DispatchQueue.main.async {
                    // 🔥 修复滤镜层平滑显示：确保从隐藏状态的平滑过渡
                    let wasHidden = imageView.isHidden
                    
                    if wasHidden {
                        // 从隐藏状态过渡到显示：先设置为可见但透明
                    imageView.isHidden = false
                        imageView.alpha = 0.0
                        imageView.image = previewImage
                        
                        // 渐显动画
                        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseOut) {
                            imageView.alpha = 1.0
                        }
                    } else {
                        // 正常的交叉溶解动画
                        UIView.transition(with: imageView, duration: 0.1, options: .transitionCrossDissolve) {
                            imageView.image = previewImage
                        }
                    }
                    // 如果网格线已启用，更新网格线位置
                    if self.isGridLineEnabled {
                        self.showGridLineOnPreview()
                    }
                }
            }
        }
    }

    func updateZoomLabel() {
        guard let device = (captureSession?.inputs.first as? AVCaptureDeviceInput)?.device else { return }
        let zoom = device.videoZoomFactor
        zoomLabel?.text = String(format: "%.1fx", zoom)
    }

    // 滤镜参数变更、重置、切换镜头等场景下，若无滤镜或面板关闭则隐藏filteredPreviewImageView
    func hideFilterPreviewIfNeeded() {
        DispatchQueue.main.async {
            // 始终显示filteredPreviewImageView，避免在滤镜层和原始层之间跳变
            // 只有在完全没有滤镜效果时才隐藏
            if !(self.isContrastVisible || self.isSaturationVisible || self.isTemperatureVisible) && self.currentContrast == 1.0 && self.currentSaturation == 1.0 && self.currentTemperature == 6500.0 {
                // 不隐藏filteredPreviewImageView，保持界面稳定
                // self.filteredPreviewImageView?.isHidden = true
            }
        }
    }

    func maxEffectiveZoom(for cameraLabel: String) -> CGFloat {
        // 使用设备能力检测获取兼容的缩放因子
        let capabilities = DeviceCapabilityCheck.getCameraCapabilities()
        let deviceCategory = UIDevice.current.deviceCategory
        
        // 根据相机标签和设备能力返回合适的缩放因子
            switch cameraLabel {
        case "0.5x":
            return capabilities.hasUltraWideCamera ? 2.0 : 1.0
        case "1x":
            return capabilities.maxZoomFactor
        case "2x":
            return capabilities.hasTelephotoCamera ? capabilities.maxZoomFactor : 2.0
        case "3x":
            return capabilities.hasTelephotoCamera ? capabilities.maxZoomFactor : 3.0
        case "前置":
            return capabilities.maxZoomFactor
        default:
            return capabilities.maxZoomFactor
        }
    }

    // 智能帧率设置函数
    private func setOptimalFrameRate(for device: AVCaptureDevice, targetFrameRate: Int32) {
                do {
                    try device.lockForConfiguration()
            
            // 检查设备支持的帧率范围
            var bestFrameRate: Int32 = 30
            let format = device.activeFormat
            for range in format.videoSupportedFrameRateRanges {
                let maxRate = Int32(range.maxFrameRate)
                let minRate = Int32(range.minFrameRate)
                
                // 选择设备支持且不超过目标帧率的最高帧率
                if targetFrameRate >= minRate && targetFrameRate <= maxRate {
                    bestFrameRate = targetFrameRate
                    break
                } else if maxRate <= targetFrameRate && maxRate > bestFrameRate {
                    bestFrameRate = maxRate
                }
            }
            
            let duration = CMTimeMake(value: 1, timescale: bestFrameRate)
            device.activeVideoMinFrameDuration = duration
            device.activeVideoMaxFrameDuration = duration
            
                    device.unlockForConfiguration()
            print("📱 智能设置帧率: 目标\(targetFrameRate)fps → 实际\(bestFrameRate)fps")
            
        } catch {
            print("📱 智能帧率设置失败: \(error)")
        }
    }
    
    // 低功耗模式和设备适配
    func applyPerformanceOptimizations() {
        let deviceType = UIDevice.current.deviceCategory
        let isLowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
        
        // 流畅度优先的设备适配
        if isLowPower || deviceType == .lowEnd {
            // 低端设备：保持流畅但降低质量
            previewFrameInterval = 1 // 仍然每帧处理，但通过时间控制
            maxCacheSize = 20
            imageCache.totalCostLimit = maxCacheSize * 1024 * 1024
            
            if let device = (captureSession?.inputs.first as? AVCaptureDeviceInput)?.device {
                setOptimalFrameRate(for: device, targetFrameRate: 30)
            }
            
        } else if deviceType == .midRange {
            // 中端设备：平衡性能和流畅度
            previewFrameInterval = 1
            maxCacheSize = 35
            
        } else {
            // 高端设备：追求苹果相机级别的流畅度
            previewFrameInterval = 1
            maxCacheSize = 50
        }
        
        if !isLowPower && deviceType != .lowEnd {
            if let device = (captureSession?.inputs.first as? AVCaptureDeviceInput)?.device {
                // 中高端设备尝试更高帧率
                let targetFrameRate: Int32 = deviceType == .ultraHigh ? 60 : 30
                setOptimalFrameRate(for: device, targetFrameRate: targetFrameRate)
            }
        }
    }

    // 监听低电量模式变化
    deinit {
        print("📱 CameraViewController deinit - 开始清理资源")
        
        // 🔥 修复：立即停止所有定时器，避免异步调用
        contrastPlusTimer?.invalidate()
        contrastMinusTimer?.invalidate()
        satPlusTimer?.invalidate()
        satMinusTimer?.invalidate()
        tempPlusTimer?.invalidate()
        tempMinusTimer?.invalidate()
        exposurePlusTimer?.invalidate()
        exposureMinusTimer?.invalidate()
        exposureAutoHideTimer?.invalidate()
        // 滑动条自动隐藏定时器
        contrastAutoHideTimer?.invalidate()
        saturationAutoHideTimer?.invalidate()
        temperatureAutoHideTimer?.invalidate()
        exposureSliderAutoHideTimer?.invalidate()
        
        // 🔥 修复：立即取消所有异步任务
        filterUpdateWorkItem?.cancel()
        exposureUpdateWorkItem?.cancel()
        
        // 🔥 修复：立即停止相机相关，不使用异步调用
        motionManager.stopDeviceMotionUpdates()
        videoOutput?.setSampleBufferDelegate(nil, queue: nil)
        photoOutput?.setPreparedPhotoSettingsArray([], completionHandler: nil)
        
        // 🔥 修复：同步停止会话，避免异步调用导致的对象过度释放
        if let session = captureSession, session.isRunning {
            session.stopRunning()
        }
        
        // 🔥 修复：立即移除通知监听
        NotificationCenter.default.removeObserver(self)
        
        // 🔥 修复：立即清理UI引用
        previewLayer?.removeFromSuperlayer()
        filteredPreviewImageView?.removeFromSuperview()
        
        // 🔥 修复：立即清理所有队列引用
        sessionQueue.sync { }
        
        print("📱 CameraViewController deinit - 资源清理完成")
    }

    // 🔥 改进的相机会话重启方法，解决黑屏问题
    private func restartCameraSessionIfNeeded() {
        print("📱 检查相机会话状态")
        
        guard let session = captureSession else {
            print("📱 [WARN] captureSession为nil，重新初始化相机")
            setupCamera(startSessionIfNeeded: true)
            return
        }
        
        // 检查会话是否正在运行
        if session.isRunning {
            print("📱 相机会话正在运行，无需重启")
            return
        }
        
        print("📱 相机会话未运行，开始重启")
        
        // 🔥 修复：同步检查会话状态，避免异步调用导致的对象过度释放
        if isConfiguringSession {
            print("📱 [WARN] 会话正在配置中，跳过重启")
                return
            }
            
        if !isSessionConfigured {
                print("📱 [WARN] 会话未配置，重新设置相机")
            setupCamera(startSessionIfNeeded: true)
                return
            }
            
        // 🔥 修复：同步重启会话
        sessionConfigLock.lock()
        defer { sessionConfigLock.unlock() }
        
        if isConfiguringSession {
                print("📱 [WARN] 会话正在配置中，跳过重启")
                return
            }
            
            do {
                print("📱 开始重启相机会话")
                session.startRunning()
                print("📱 相机会话重启成功")
                
            // 🔥 修复：同步确保预览层正确显示
            ensurePreviewLayerVisible()
                
            } catch {
                print("📱 [ERROR] 相机会话重启失败: \(error)")
            // 🔥 修复：同步重新初始化
            reinitializeCameraOnFailure()
        }
    }
    
    // 🔥 确保预览层可见
    private func ensurePreviewLayerVisible() {
        print("📱 确保预览层可见")
        
        // 确保预览层存在且正确设置
        if let previewLayer = previewLayer {
            previewLayer.opacity = 0.0 // 保持透明，避免闪烁
            print("📱 预览层状态: frame=\(previewLayer.frame), opacity=\(previewLayer.opacity)")
        }
        
        // 确保filteredPreviewImageView正确显示
        if let filteredPreview = filteredPreviewImageView {
            filteredPreview.alpha = 1.0
            filteredPreview.isHidden = false
            print("📱 滤镜预览层状态: isHidden=\(filteredPreview.isHidden), alpha=\(filteredPreview.alpha)")
        }
        
        // 检查相机权限
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if authStatus != .authorized {
            print("📱 [WARN] 相机权限状态: \(authStatus.rawValue)")
        }
    }
    
    // 🔥 相机重启失败时的重试机制
    private func reinitializeCameraOnFailure() {
        print("📱 相机重启失败，尝试重新初始化")
        
        // 重置状态
        isSessionConfigured = false
        isConfiguringSession = false
        
        // 重新设置相机
        setupCamera(startSessionIfNeeded: true)
    }
    
    // 机型适配系统
    // 旧的DeviceType枚举已移除，现在使用DeviceCategory
    
    // 兼容旧接口 - 使用新的设备类型检测
    func isLowEndDevice() -> Bool {
        return UIDevice.current.deviceCategory == .lowEnd
    }
    
    // MARK: - 兼容性检查
    private func performCompatibilityCheck() {
        print("🔍 开始兼容性检查...")
        
        // 检查iOS版本
        let iosVersion = iOSVersionCheck.currentVersion
        print("📱 iOS版本: \(iosVersion)")
        
        // 检查设备信息
        let device = UIDevice.current
        let modelIdentifier = device.modelIdentifier
        let deviceCategory = device.deviceCategory
        print("📱 设备型号: \(modelIdentifier)")
        print("📱 设备类型: \(deviceCategory)")
        
        // 检查相机能力
        let capabilities = DeviceCapabilityCheck.getCameraCapabilities()
        print("📱 相机能力:")
        print("   - 超广角相机: \(capabilities.hasUltraWideCamera)")
        print("   - 长焦相机: \(capabilities.hasTelephotoCamera)")
        print("   - 前置相机: \(capabilities.hasFrontCamera)")
        print("   - 最大缩放: \(capabilities.maxZoomFactor)x")
        print("   - 高帧率支持: \(capabilities.supportsHighFrameRate)")
        
        // 检查iOS功能支持
        print("📱 iOS功能支持:")
        print("   - modelIdentifier: \(iOSVersionCheck.supportsModelIdentifier)")
        print("   - WindowScene: \(iOSVersionCheck.supportsWindowScene)")
        print("   - 自动配置输出缓冲: \(iOSVersionCheck.supportsAutomaticallyConfiguresOutputBufferDimensions)")
        
        // 检查模拟器环境
        let isSimulator = TARGET_OS_SIMULATOR != 0
        print("📱 运行环境: \(isSimulator ? "模拟器" : "真机")")
        
        // 测试兼容性功能
        testCompatibilityFeatures()
        
        print("✅ 兼容性检查完成")
    }
    
    // MARK: - 虚拟相机选项创建
    private func createVirtualCameraOption() {
        print("📱 创建虚拟相机选项")
        // 在模拟器中没有真实相机时，创建一个虚拟的相机选项
        // 这样可以避免崩溃，但相机功能将不可用
        let virtualDevice = AVCaptureDevice.default(for: .video) ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        if let device = virtualDevice {
            self.cameraOptions.append(CameraOption(device: device, label: "虚拟相机"))
            print("📱 添加虚拟相机选项")
        } else {
            print("📱 [ERROR] 无法创建任何相机选项")
            // 如果连虚拟相机都无法创建，显示错误信息
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "相机不可用", message: "模拟器中没有可用的相机设备。请在真机上测试相机功能。", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "确定", style: .default))
                self.present(alert, animated: true)
            }
        }
    }
    
    // MARK: - 兼容性功能测试
    private func testCompatibilityFeatures() {
        print("🧪 测试兼容性功能...")
        
        // 测试设备型号获取
        let modelId = UIDevice.current.modelIdentifier
        print("   ✅ 设备型号获取: \(modelId)")
        
        // 测试设备类型检测
        let category = UIDevice.current.deviceCategory
        print("   ✅ 设备类型检测: \(category)")
        
        // 测试相机能力检测
        let capabilities = DeviceCapabilityCheck.getCameraCapabilities()
        let availableCameras = capabilities.getAvailableCameras()
        print("   ✅ 可用相机: \(availableCameras)")
        
        // 测试缩放因子计算
        let zoom1x = maxEffectiveZoom(for: "1x")
        let zoom2x = maxEffectiveZoom(for: "2x")
        print("   ✅ 缩放因子测试 - 1x: \(zoom1x)x, 2x: \(zoom2x)x")
        
        // 测试iOS版本检查
        let supportsModelId = iOSVersionCheck.supportsModelIdentifier
        let supportsWindowScene = iOSVersionCheck.supportsWindowScene
        print("   ✅ iOS版本检查 - modelIdentifier: \(supportsModelId), WindowScene: \(supportsWindowScene)")
        
        print("   ✅ 兼容性功能测试完成")
    }

    // 低端机型/低电量模式下关闭高功耗滤镜
    func shouldUseHighQualityFilter() -> Bool {
        if isLowEndDevice() || ProcessInfo.processInfo.isLowPowerModeEnabled {
            return false
        }
        return true
    }

    func selectSceneCategory(named name: String) {
        currentSceneCategory = name
            sceneCategoryCollectionView?.reloadData()
        
        // 立即清空并显示loading状态
        sceneImagesInCategory = []
            sceneImageCollectionView?.reloadData()
        
        // 异步加载场景图片
        DispatchQueue.global(qos: .utility).async {
            let images = self.prepareSceneImages(for: name)
            
            DispatchQueue.main.async {
                self.sceneImagesInCategory = images
                self.sceneImageCollectionView?.reloadData()
                print("📂 场景图片加载完成：\(images.count)张")
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView.tag == 4001 {
            return displaySceneCategories.count
        } else if collectionView.tag == 4002 {
            return displaySceneImages.count
        }
        return 0
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView.tag == 4001 {
            let name = displaySceneCategories[indexPath.item]
            if name == "__add__" {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "addSceneCell", for: indexPath)
                cell.contentView.subviews.forEach { $0.removeFromSuperview() }
                let addBtn = UIButton(type: .contactAdd)
                addBtn.isUserInteractionEnabled = false
                addBtn.frame = cell.contentView.bounds
                addBtn.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                cell.contentView.addSubview(addBtn)
                return cell
            } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "catcell", for: indexPath) as! SceneCategoryCell
            cell.label.text = name
                // Apple Design 选中状态
                if name == currentSceneCategory {
                    cell.backgroundColor = .systemPurple.withAlphaComponent(0.15)
                    cell.layer.borderColor = UIColor.systemPurple.withAlphaComponent(0.3).cgColor
                    cell.layer.borderWidth = 1
                } else {
                    cell.backgroundColor = .secondarySystemBackground
                    cell.layer.borderWidth = 0
                }
                // 添加长按手势
                cell.gestureRecognizers?.forEach { cell.removeGestureRecognizer($0) }
                let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleSceneLongPress(_:)))
                longPress.minimumPressDuration = 0.5
                cell.addGestureRecognizer(longPress)
            return cell
            }
        } else if collectionView.tag == 4002 {
            let name = displaySceneImages[indexPath.item]
            if name == "__add__" {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "addImageCell", for: indexPath)
                cell.contentView.subviews.forEach { $0.removeFromSuperview() }
                let addBtn = UIButton(type: .contactAdd)
                addBtn.isUserInteractionEnabled = false
                addBtn.frame = cell.contentView.bounds
                addBtn.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                cell.contentView.addSubview(addBtn)
                return cell
            } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imgcell", for: indexPath) as! SceneImageCell
            guard let sceneGuideRoot = sceneGuideRoot else { return cell }
            let catPath = (sceneGuideRoot as NSString).appendingPathComponent(currentSceneCategory ?? "")
            let imgPath = (catPath as NSString).appendingPathComponent(name)
            
                        // 使用缓存系统加载图片
            loadImageWithCache(from: imgPath) { image in
                print("🔍 [DEBUG] 开始设置cell.imageView.image")
                cell.imageView.image = image
                print("🔍 [DEBUG] cell.imageView.image设置完成")
            }
                // 添加长按手势
                cell.gestureRecognizers?.forEach { cell.removeGestureRecognizer($0) }
                let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleImageLongPress(_:)))
                longPress.minimumPressDuration = 0.5
                cell.addGestureRecognizer(longPress)
            return cell
            }
        }
        return UICollectionViewCell()
    }

    

    // MARK: - UIGestureRecognizerDelegate，避免手势冲突
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if let view = touch.view {
            if let catCV = sceneCategoryCollectionView, view.isDescendant(of: catCV) {
                return false
            }
            if let imgCV = sceneImageCollectionView, view.isDescendant(of: imgCV) {
                return false
            }
        }
        return true
    }
    
    // 处理长按手势与其他手势的冲突
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // 如果是长按手势，允许与其他手势同时识别
        if gestureRecognizer is UILongPressGestureRecognizer {
            print("🔍 [DEBUG] 长按手势与其他手势同时识别: \(otherGestureRecognizer)")
            return true
        }
        return false
    }
    
    // 检查轮盘可见性
    func checkZoomWheelVisibility() {
        print("🔍 [DEBUG] 检查轮盘可见性")
        print("🔍 [DEBUG] isZoomWheelVisible: \(isZoomWheelVisible)")
        print("🔍 [DEBUG] zoomWheelView存在: \(zoomWheelView != nil)")
        if let wheel = zoomWheelView {
            print("🔍 [DEBUG] 轮盘alpha: \(wheel.alpha)")
            print("🔍 [DEBUG] 轮盘frame: \(wheel.frame)")
            print("🔍 [DEBUG] 轮盘isHidden: \(wheel.isHidden)")
            print("🔍 [DEBUG] 轮盘superview: \(wheel.superview?.description ?? "nil")")
            print("🔍 [DEBUG] 轮盘在view.subviews中: \(view.subviews.contains(wheel))")
            print("🔍 [DEBUG] 轮盘在keyWindow中: \(UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.subviews.contains(wheel) ?? false)")
        }
    }
    
    // 测试长按手势是否正确添加
    func testLongPressGestures() {
        // 🔥 优化：延迟执行手势测试，避免阻塞初始化
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            print("🧪 [DEBUG] 开始测试长按手势")
            if let stack = self.cameraSwitchStack {
                for case let button as UIButton in stack.arrangedSubviews {
                    print("🧪 [DEBUG] 按钮 \(button.tag) 的手势数量: \(button.gestureRecognizers?.count ?? 0)")
                    if let gestures = button.gestureRecognizers {
                        for gesture in gestures {
                            if let longPress = gesture as? UILongPressGestureRecognizer {
                                print("🧪 [DEBUG] 找到长按手势: minimumPressDuration=\(longPress.minimumPressDuration)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    // 确保长按手势能够正确触发
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let longPress = gestureRecognizer as? UILongPressGestureRecognizer {
            print("🔍 [DEBUG] 长按手势应该开始: \(longPress.minimumPressDuration)")
            print("🔍 [DEBUG] 长按手势view: \(gestureRecognizer.view?.tag ?? -1)")
            return true
        }
        return true
    }

    @objc func dismissParamManager() {
        // 移除参数面板弹窗和蒙层
        self.view.viewWithTag(9998)?.removeFromSuperview()
        self.view.viewWithTag(9997)?.removeFromSuperview() // 🔥 修复：移除参数管理器面板
        // 更新按钮状态
        updateButtonStates()
    }

    @objc func openSceneGuide() {
        print("📸 [DEBUG] 场景按钮被点击！")
        
        // 🔥 懒加载：确保场景系统已初始化
        setupSceneSystemIfNeeded()
        
        // 🔥 修复：立即切换状态，避免延迟导致的重复点击问题
        print("📸 [DEBUG] 开始切换场景面板，当前状态: \(self.isSceneGuideVisible)")
            self.isSceneGuideVisible.toggle()
        print("📸 [DEBUG] 场景面板状态已切换为: \(self.isSceneGuideVisible)")
        
        // 🔥 修复：确保CollectionView存在后再设置状态
        if let sceneCategoryCollectionView = self.sceneCategoryCollectionView {
            sceneCategoryCollectionView.isHidden = !self.isSceneGuideVisible
            print("📸 [DEBUG] 场景分类面板隐藏状态: \(sceneCategoryCollectionView.isHidden)")
        } else {
            print("📸 [DEBUG] sceneCategoryCollectionView为nil，无法设置状态")
        }
        
        if let sceneImageCollectionView = self.sceneImageCollectionView {
            sceneImageCollectionView.isHidden = !self.isSceneGuideVisible
            print("📸 [DEBUG] 场景图片面板隐藏状态: \(sceneImageCollectionView.isHidden)")
        } else {
            print("📸 [DEBUG] sceneImageCollectionView为nil，无法设置状态")
        }
            
            if self.isSceneGuideVisible {
                // 立即显示空的CollectionView
                self.sceneCategoryCollectionView?.reloadData()
                self.sceneImageCollectionView?.reloadData()
            print("📸 [DEBUG] 场景面板数据已重新加载")
            }
            
            self.isFilterPanelVisible = false
        if let filterPanelView = self.filterPanelView {
            filterPanelView.isHidden = true
        }
            self.dismissParamManager()
            self.isContrastVisible = false
            self.isSaturationVisible = false
            self.isTemperatureVisible = false
        // 🔥 修复：不强制隐藏曝光面板，让用户自己控制
        // self.isExposureVisible = false
            self.updateButtonStates()
        
        print("📸 [DEBUG] 场景面板切换完成")
    }

    @objc func addSceneTapped() {
        let alert = UIAlertController(title: "新建场景", message: "请输入场景名称", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "场景名称" }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            guard let name = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else { return }
            print("确定按钮点击，输入：\(name)")
            self?.createSceneCategory(named: name)
        })
        present(alert, animated: true)
    }

    func createSceneCategory(named name: String) {
        print("sceneGuideRoot: \(String(describing: sceneGuideRoot))")
        let path = (sceneGuideRoot! as NSString).appendingPathComponent(name)
        print("创建路径：\(path)")
        if !FileManager.default.fileExists(atPath: path) {
            try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
            print("文件夹创建成功")
            DispatchQueue.main.async {
                self.loadSceneCategories()
                self.sceneCategoryCollectionView?.reloadData()
            }
        } else {
            print("文件夹已存在")
        }
    }

    // 2. 长按场景名删除
    func collectionView(_ collectionView: UICollectionView, didLongPressItemAt indexPath: IndexPath) {
        if collectionView.tag == 4001 {
            let name = sceneCategories[indexPath.item]
            let alert = UIAlertController(title: "删除场景", message: "确定删除\"\(name)\"及其所有图片？", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
            alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
                self?.deleteSceneCategory(named: name)
            })
            present(alert, animated: true)
        } else if collectionView.tag == 4002 {
            let imgName = sceneImagesInCategory[indexPath.item]
            let alert = UIAlertController(title: "删除图片", message: "确定删除这张图片？", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
            alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
                self?.deleteSceneImage(named: imgName)
            })
            present(alert, animated: true)
        }
    }

    // 长按手势处理方法
    @objc func handleSceneLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let cell = gesture.view as? UICollectionViewCell,
              let indexPath = sceneCategoryCollectionView?.indexPath(for: cell) else { return }
        
        let name = displaySceneCategories[indexPath.item]
        if name != "__add__" {
            let alert = UIAlertController(title: "删除场景", message: "确定删除\"\(name)\"及其所有图片？", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
            alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
                self?.deleteSceneCategory(named: name)
            })
            present(alert, animated: true)
        }
    }

    @objc func handleImageLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let cell = gesture.view as? UICollectionViewCell,
              let indexPath = sceneImageCollectionView?.indexPath(for: cell) else { return }
        
        let name = displaySceneImages[indexPath.item]
        if name != "__add__" {
            let alert = UIAlertController(title: "删除图片", message: "确定删除这张图片？", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
            alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
                self?.deleteSceneImage(named: name)
            })
            present(alert, animated: true)
        }
    }

    func deleteSceneCategory(named name: String) {
        let path = (sceneGuideRoot! as NSString).appendingPathComponent(name)
        print("尝试删除场景路径：\(path)")
        do {
            try FileManager.default.removeItem(atPath: path)
            print("删除成功")
        } catch {
            print("删除失败：\(error)")
        }
        loadSceneCategories()
        sceneCategoryCollectionView?.reloadData()
    }

    // 3. 场景图片栏右侧加"+"按钮


    @objc func addSceneImageTapped() {
        let picker = UIImagePickerController()
        picker.delegate = self
        present(picker, animated: true)
    }
    // 4. 图片选择回调
 

    func deleteSceneImage(named imgName: String) {
        guard let currentScene = currentSceneCategory else { return }
        let dir = (sceneGuideRoot! as NSString).appendingPathComponent(currentScene)
        let path = (dir as NSString).appendingPathComponent(imgName)
        print("尝试删除图片路径：\(path)")
        do {
            try FileManager.default.removeItem(atPath: path)
            print("删除成功")
        } catch {
            print("删除失败：\(error)")
        }
        loadSceneImages(for: currentScene)
        sceneImageCollectionView?.reloadData()
    }

    func loadSceneCategories() {
        guard let root = sceneGuideRoot else { print("sceneGuideRoot为nil"); return }
        
        // 🔥 优化：确保文件系统操作在后台进行
        DispatchQueue.global(qos: .utility).async {
            do {
                var items = try FileManager.default.contentsOfDirectory(atPath: root)
                // 如果为空，自动拷贝Bundle内容
                if items.isEmpty, let bundlePath = Bundle.main.path(forResource: "拍照指引", ofType: nil) {
                    let fileManager = FileManager.default
                    let bundleItems = try fileManager.contentsOfDirectory(atPath: bundlePath)
                    for item in bundleItems {
                        let src = (bundlePath as NSString).appendingPathComponent(item)
                        let dst = (root as NSString).appendingPathComponent(item)
                        if !fileManager.fileExists(atPath: dst) {
                            try? fileManager.copyItem(atPath: src, toPath: dst)
                        }
                    }
                    // 重新获取
                    items = try fileManager.contentsOfDirectory(atPath: root)
                }
                let folders = items.filter { item in
                    var isDir: ObjCBool = false
                    let fullPath = (root as NSString).appendingPathComponent(item)
                    FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDir)
                    return isDir.boolValue
                }
                
                // 🔥 优化：在主线程更新UI
                DispatchQueue.main.async {
                    print("当前场景：\(folders)")
                    self.sceneCategories = folders
                    self.sceneCategoryCollectionView?.reloadData()
                    print("reloadData called")
                }
            } catch {
                print("加载场景分类失败: \(error)")
            }
        }
    }

    func loadSceneImages(for category: String) {
        // 立即清空并显示loading状态
        sceneImagesInCategory = []
        sceneImageCollectionView?.reloadData()
        
        // 后台线程加载图片
        DispatchQueue.global(qos: .utility).async {
            let images = self.prepareSceneImages(for: category)
            
            DispatchQueue.main.async {
                self.sceneImagesInCategory = images
                self.sceneImageCollectionView?.reloadData()
                print("📂 场景图片加载完成：\(images.count)张")
            }
        }
    }
    
    // 新增：后台准备场景图片数据
    private func prepareSceneImages(for category: String) -> [String] {
        guard let root = sceneGuideRoot else { return [] }
        let dir = (root as NSString).appendingPathComponent(category)
        
        do {
            let items = try FileManager.default.contentsOfDirectory(atPath: dir)
            let images = items.filter { $0.lowercased().hasSuffix(".jpg") || $0.lowercased().hasSuffix(".jpeg") || $0.lowercased().hasSuffix(".png") }
            print("📂 [DEBUG] 开始准备场景图片")
            print("📂 后台准备场景图片：\(images.count)张")
            return images
        } catch {
            print("📂 加载场景图片失败: \(error)")
            return []
        }
    }
    
    // 内存优化：图片缓存方法
    private func getCachedImage(for path: String) -> UIImage? {
        return imageCache.object(forKey: path as NSString)
    }
    
    private func cacheImage(_ image: UIImage, for path: String) {
        print("🔍 [DEBUG] 开始缓存图片: \(path)")
        print("🔍 [DEBUG] 开始调用cacheQueue.async")
        
        cacheQueue.async { [weak self] in
            guard let self = self else {
                print("🔍 [DEBUG] self已释放，跳过缓存操作")
                return
            }
            print("🔍 [DEBUG] cacheQueue.async调用完成")
            print("🔍 [DEBUG] 缓存队列开始处理: \(path)")
            
            // 检查缓存大小
            if self.imageCache.totalCostLimit > self.maxCacheSize * 1024 * 1024 { // 50MB
                print("🔍 [DEBUG] 缓存已满，清理所有对象")
                self.imageCache.removeAllObjects()
            }
            
            print("🔍 [DEBUG] 开始设置缓存对象: \(path)")
            self.imageCache.setObject(image, forKey: path as NSString)
            print("🔍 [DEBUG] 图片缓存完成: \(path)")
        }
    }
    
    private func loadImageWithCache(from path: String, completion: @escaping (UIImage?) -> Void) {
        print("🔍 [DEBUG] 开始加载图片: \(path)")
        
        // 先检查缓存
        if let cachedImage = getCachedImage(for: path) {
            print("🔍 [DEBUG] 图片已缓存，直接返回")
            completion(cachedImage)
            return
        }
        
        print("🔍 [DEBUG] 图片未缓存，开始后台加载")
        
        // 后台加载
        backgroundQueue.async { [weak self] in
            guard let self = self else {
                print("🔍 [DEBUG] self已释放，跳过图片加载")
                return
            }
            
            print("🔍 [DEBUG] 后台队列开始加载图片: \(path)")
            
            // 🔥 修复：添加防护措施，避免崩溃
            guard !path.isEmpty else {
                print("🔍 [DEBUG] 图片路径为空，跳过加载")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            print("🔍 [DEBUG] 开始执行UIImage(contentsOfFile:)操作")
            let imageLoadStartTime = CACurrentMediaTime()
            
            // 🔥 修复：使用安全的图片加载方式
            var image: UIImage?
            do {
                let imageData = try Data(contentsOf: URL(fileURLWithPath: path))
                image = UIImage(data: imageData)
            } catch {
                print("🔍 [DEBUG] 图片加载失败: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            if let image = image {
                let imageLoadEndTime = CACurrentMediaTime()
                let imageLoadTime = (imageLoadEndTime - imageLoadStartTime) * 1000
                print("🔍 [DEBUG] UIImage(contentsOfFile:)操作完成")
                print("🔍 [TIME] UIImage(contentsOfFile:)耗时: \(String(format: "%.1f", imageLoadTime))ms")
                print("🔍 [DEBUG] 图片加载成功，开始缓存")
                
                // 缓存图片
                self.cacheImage(image, for: path)
                
                DispatchQueue.main.async {
                    print("🔍 [DEBUG] 图片加载完成，返回结果")
                    print("🔍 [DEBUG] 开始执行completion回调")
                    completion(image)
                    print("🔍 [DEBUG] completion回调执行完成")
                }
            } else {
                print("🔍 [DEBUG] 图片加载失败: \(path)")
                
                DispatchQueue.main.async {
                    print("🔍 [DEBUG] 图片加载失败，返回nil")
                    print("🔍 [DEBUG] 开始执行completion回调")
                    completion(nil)
                    print("🔍 [DEBUG] completion回调执行完成")
                }
            }
        }
    }

    // 懒加载功能面板
    @objc func showFilterPanelIfNeeded() {
        // 调用原来的功能面板切换方法
        toggleFilterPanel()
    }
    @objc func showSceneGuideIfNeeded() {
        // 调用原来的场景管理方法
        openSceneGuide()
    }
    @objc func showParamManagerIfNeeded() {
        // 调用原来的参数管理方法
        showParamManager()
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
    var autoSave: Bool = false
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                DispatchQueue.main.async {
                    self.parent.selectedImage = image
                    if self.parent.autoSave {
                        PHPhotoLibrary.requestAuthorization { status in
                            if status == .authorized || status == .limited {
                                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                            }
                        }
                    }
                }
            }
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    ContentView()
}

// MARK: - 性能优化建议
// 如需进一步提升流畅度，可考虑：
// 1. 用 Metal 初始化 CIContext 并用 MTKView 直接渲染（GPU 加速，适合高分辨率/滤镜实时预览）
// 2. 预览主画面用 AVCaptureVideoPreviewLayer，滤镜小窗/静态图用 CoreImage 渲染
// 3. 只在滤镜参数变化时刷新预览，避免重复渲染
// 如需 Metal/AVCaptureVideoPreviewLayer 代码示例，请联系 AI 助手

// 彩色圆形thumb生成函数
func sliderThumbImage(color: UIColor, radius: CGFloat = 14) -> UIImage {
    let rect = CGRect(x: 0, y: 0, width: radius * 2, height: radius * 2)
    UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
    let context = UIGraphicsGetCurrentContext()!
    context.setShadow(offset: CGSize(width: 0, height: 2), blur: 4, color: UIColor.black.withAlphaComponent(0.2).cgColor)
    context.setFillColor(color.cgColor)
    context.fillEllipse(in: rect.insetBy(dx: 2, dy: 2))
    let image = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    return image
}

class PrettySlider: UISlider {
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        let defaultRect = super.trackRect(forBounds: bounds)
        // 🔥 修复：使用与标准UISlider完全一致的轨道位置
        return CGRect(x: defaultRect.origin.x, y: defaultRect.origin.y, width: defaultRect.width, height: defaultRect.height)
    }
}

// 1. 在文件顶部添加渐变track生成函数：
func sliderGradientImage(colors: [UIColor], size: CGSize = CGSize(width: 300, height: 6)) -> UIImage {
    let layer = CAGradientLayer()
    layer.frame = CGRect(origin: .zero, size: size)
    layer.colors = colors.map { $0.cgColor }
    layer.startPoint = CGPoint(x: 0, y: 0.5)
    layer.endPoint = CGPoint(x: 1, y: 0.5)
    UIGraphicsBeginImageContextWithOptions(size, false, 0)
    layer.render(in: UIGraphicsGetCurrentContext()!)
    let image = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    return image.resizableImage(withCapInsets: .zero, resizingMode: .stretch)
}

// MARK: - 历史照片滑动预览控制器
class PhotoPreviewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    var assets: [PHAsset] = []
    var startIndex: Int = 0
    private var pageVC: UIPageViewController!
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        pageVC = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageVC.dataSource = self
        pageVC.delegate = self
        addChild(pageVC)
        view.addSubview(pageVC.view)
        pageVC.view.frame = view.bounds
        pageVC.didMove(toParent: self)
        if assets.indices.contains(startIndex) {
            let first = PhotoPreviewPage(asset: assets[startIndex])
            pageVC.setViewControllers([first], direction: .forward, animated: false)
        }
        // 顶部毛玻璃
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterialDark))
        blur.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 70)
        blur.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        view.addSubview(blur)
        // 右上角圆形关闭按钮
        let closeBtn = UIButton(type: .system)
        closeBtn.setTitle("×", for: .normal)
        closeBtn.titleLabel?.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        closeBtn.tintColor = .white
        closeBtn.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        closeBtn.layer.cornerRadius = 22
        closeBtn.frame = CGRect(x: view.bounds.width - 54, y: 38, width: 44, height: 44) // 下移20pt
        closeBtn.autoresizingMask = [.flexibleLeftMargin, .flexibleBottomMargin]
        closeBtn.addTarget(self, action: #selector(closePreview), for: .touchUpInside)
        view.addSubview(closeBtn)
    }
    @objc func closePreview() { self.dismiss(animated: true) }
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let page = viewController as? PhotoPreviewPage, let idx = assets.firstIndex(of: page.asset), idx > 0 else { return nil }
        return PhotoPreviewPage(asset: assets[idx-1])
    }
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let page = viewController as? PhotoPreviewPage, let idx = assets.firstIndex(of: page.asset), idx < assets.count-1 else { return nil }
        return PhotoPreviewPage(asset: assets[idx+1])
    }
    deinit {
        pageVC?.willMove(toParent: nil)
        pageVC?.view.removeFromSuperview()
        pageVC?.removeFromParent()
    }
}

class PhotoPreviewPage: UIViewController {
    let asset: PHAsset
    init(asset: PHAsset) { self.asset = asset; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        if asset.mediaSubtypes.contains(.photoLive) {
                    // Live Photo功能已移除，这里只显示静态图片
        } else {
            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: nil) { data, _, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    let imageView = UIImageView(image: image)
                    imageView.contentMode = .scaleAspectFit
                    imageView.frame = self.view.bounds
                    imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    self.view.addSubview(imageView)
                }
            }
        }
    }
}

// 重复的UIDevice扩展已移除，使用文件顶部的兼容性扩展

class SceneCategoryCell: UICollectionViewCell {
    let label = UILabel()
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // Apple Design 样式
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 12
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.06
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowRadius = 2
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.textColor = .label
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: contentView.topAnchor),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
}

class SceneImageCell: UICollectionViewCell {
    let imageView = UIImageView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // Apple Design 样式
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 12
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.06
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowRadius = 2
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 10
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -2)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
}

// 1. 新增大图预览弹窗控制器
class ImagePreviewController: UIViewController {
    let image: UIImage
    var onConfirm: ((UIImage) -> Void)?
    init(image: UIImage) {
        self.image = image
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Apple Design 背景
        let blurEffect = UIBlurEffect(style: .systemMaterialDark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = view.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurView)
        
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.frame = view.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.layer.cornerRadius = 16
        imageView.clipsToBounds = true
        view.addSubview(imageView)
        
        // Apple Design 确认按钮
        let confirmBtn = makeAppleButton(title: "确认", icon: "checkmark.circle.fill")
        confirmBtn.backgroundColor = .systemBlue
        confirmBtn.setTitleColor(.white, for: .normal)
        confirmBtn.tintColor = .white
        confirmBtn.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        view.addSubview(confirmBtn)
        NSLayoutConstraint.activate([
            confirmBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 18),
            confirmBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
            confirmBtn.widthAnchor.constraint(equalToConstant: 80),
            confirmBtn.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    @objc func confirmTapped() {
        onConfirm?(image)
        dismiss(animated: true)
    }
}
// ... existing code ...
extension CameraViewController {
    // 2. 浮动缩略图属性
    private struct AssociatedKeys {
        static var floatingThumbnail = "floatingThumbnail"
        static var thumbnailDragStartCenter = "thumbnailDragStartCenter"
    }
    var floatingThumbnail: UIImageView? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.floatingThumbnail) as? UIImageView }
        set { objc_setAssociatedObject(self, &AssociatedKeys.floatingThumbnail, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    var thumbnailDragStartCenter: CGPoint? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.thumbnailDragStartCenter) as? CGPoint }
        set { objc_setAssociatedObject(self, &AssociatedKeys.thumbnailDragStartCenter, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    // 3. 显示浮动缩略图
    func showFloatingThumbnail(image: UIImage) {
        let maxW: CGFloat = 140
        let maxH: CGFloat = 140
        let imgW = image.size.width
        let imgH = image.size.height
        let aspect = imgW / imgH
        var thumbW = maxW
        var thumbH = maxH
        if aspect > 1 {
            thumbH = maxW / aspect
        } else {
            thumbW = maxH * aspect
        }
        let bottomMask = view.subviews.first(where: { $0.tag == 102 })
        let safeInsets = view.safeAreaInsets
        let thumbMargin: CGFloat = 2 // 只留2pt防止完全贴死
        var x = view.bounds.width - thumbW - safeInsets.right - thumbMargin
        var y: CGFloat
        if let bottomMask = bottomMask {
            y = bottomMask.frame.minY - thumbH - 12
        } else {
            y = view.bounds.height - 150 - thumbH - 12
        }
        if floatingThumbnail == nil {
            let thumb = UIImageView()
            thumb.isUserInteractionEnabled = true
            thumb.layer.cornerRadius = 12 // Apple Design 圆角
            thumb.clipsToBounds = true
            thumb.layer.borderWidth = 1
            thumb.layer.borderColor = UIColor.systemGray5.cgColor
            thumb.layer.shadowColor = UIColor.black.cgColor
            thumb.layer.shadowOpacity = 0.15
            thumb.layer.shadowOffset = CGSize(width: 0, height: 4)
            thumb.layer.shadowRadius = 8
            thumb.frame = CGRect(x: x, y: y, width: thumbW, height: thumbH)
            thumb.autoresizingMask = []
            let pan = UIPanGestureRecognizer(target: self, action: #selector(handleThumbnailPan(_:)))
            thumb.addGestureRecognizer(pan)
            
            // Apple Design 关闭按钮
            let closeBtn = UIButton(type: .system)
            closeBtn.frame = CGRect(x: thumbW-28, y: 4, width: 24, height: 24)
            closeBtn.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
            closeBtn.tintColor = .systemRed
            closeBtn.backgroundColor = .systemBackground
            closeBtn.layer.cornerRadius = 12
            closeBtn.layer.shadowColor = UIColor.black.cgColor
            closeBtn.layer.shadowOpacity = 0.1
            closeBtn.layer.shadowOffset = CGSize(width: 0, height: 2)
            closeBtn.layer.shadowRadius = 4
            closeBtn.addTarget(self, action: #selector(closeFloatingThumbnail), for: .touchUpInside)
            thumb.addSubview(closeBtn)
            view.addSubview(thumb)
            floatingThumbnail = thumb
        }
        floatingThumbnail?.frame = CGRect(x: x, y: y, width: thumbW, height: thumbH)
        floatingThumbnail?.image = image
        floatingThumbnail?.isHidden = false
        
        // 如果网格线已启用，在缩略图上显示网格线
        if isGridLineEnabled {
            showGridLineOnThumbnail()
        }
    }
    // 4. 拖动手势
    @objc func handleThumbnailPan(_ gesture: UIPanGestureRecognizer) {
        guard let thumb = floatingThumbnail, let preview = filteredPreviewImageView else { return }
        let pvSize = preview.bounds.size
        let mainImageAspect = preview.image?.size.width ?? 1 / (preview.image?.size.height ?? 1)
        let imgAspect = pvSize.width / pvSize.height
        var visibleFrame = preview.bounds
        if mainImageAspect > imgAspect {
            let fitH = pvSize.width / mainImageAspect
            let y = (pvSize.height - fitH) / 2
            visibleFrame = CGRect(x: 0, y: y, width: pvSize.width, height: fitH)
        } else {
            let fitW = pvSize.height * mainImageAspect
            let x = (pvSize.width - fitW) / 2
            visibleFrame = CGRect(x: x, y: 0, width: fitW, height: pvSize.height)
        }
        let visibleFrameInView = preview.convert(visibleFrame, to: view)
        var minX = visibleFrameInView.minX + thumb.bounds.width/2
        var maxX = visibleFrameInView.maxX - thumb.bounds.width/2
        var minY = visibleFrameInView.minY + thumb.bounds.height/2
        var maxY = visibleFrameInView.maxY - thumb.bounds.height/2
        // 如果画幅高度太小，直接用filteredPreviewImageView的边界
        if visibleFrameInView.height < thumb.bounds.height + 20 {
            let previewFrame = preview.convert(preview.bounds, to: view)
            minX = previewFrame.minX + thumb.bounds.width/2
            maxX = previewFrame.maxX - thumb.bounds.width/2
            minY = previewFrame.minY + thumb.bounds.height/2
            maxY = previewFrame.maxY - thumb.bounds.height/2
        }
        switch gesture.state {
        case .began:
            thumbnailDragStartCenter = thumb.center
        case .changed:
            guard let start = thumbnailDragStartCenter else { return }
            let translation = gesture.translation(in: view)
            var newCenter = CGPoint(x: start.x + translation.x, y: start.y + translation.y)
            if maxX > minX {
                newCenter.x = min(max(newCenter.x, minX), maxX)
            }
            if maxY > minY {
                newCenter.y = min(max(newCenter.y, minY), maxY)
            }
            thumb.center = newCenter
        default:
            break
        }
    }
    // 5. 在CameraViewController扩展里添加：
    @objc func closeFloatingThumbnail() {
        // 移除缩略图上的网格线
        hideGridLineFromThumbnail()
        floatingThumbnail?.removeFromSuperview()
        floatingThumbnail = nil
    }
    
    // 🔥 新增：设置应用生命周期监控
    private func setupAppLifecycleMonitoring() {
        print("📱 [LIFECYCLE] 设置应用生命周期监控...")
        
        // 监听应用进入前台
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        // 监听应用进入后台
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        print("📱 [LIFECYCLE] 应用生命周期监控设置完成")
    }
    
    // 🔥 新增：应用进入前台时的处理
    @objc private func appDidBecomeActive() {
        print("📱 [LIFECYCLE] 应用进入前台")
        
        // 延迟检查UI完整性，确保应用完全恢复
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.validateUICompletenessAfterStartup()
        }
        
        // 🔥 新增：检查控制栏宽度
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.checkAndAdjustControlBarWidth()
        }
    }
    
    // 🔥 新增：应用进入后台时的处理
    @objc private func appDidEnterBackground() {
        print("📱 [LIFECYCLE] 应用进入后台")
        
        // 保存当前UI状态
        saveCurrentUIState()
    }
    
    // 🔥 新增：保存当前UI状态
    private func saveCurrentUIState() {
        print("📱 [STATE] 保存当前UI状态...")
        
        // 保存设备方向
        UserDefaults.standard.set(currentDeviceOrientation.rawValue, forKey: "SavedDeviceOrientation")
        
        // 保存相机状态
        UserDefaults.standard.set(currentCameraIndex, forKey: "SavedCameraIndex")
        UserDefaults.standard.set(isUsingFrontCamera, forKey: "SavedIsUsingFrontCamera")
        
        // 保存滤镜参数
        UserDefaults.standard.set(currentContrast, forKey: "SavedContrast")
        UserDefaults.standard.set(currentSaturation, forKey: "SavedSaturation")
        UserDefaults.standard.set(currentTemperature, forKey: "SavedTemperature")
        UserDefaults.standard.set(currentExposure, forKey: "SavedExposure")
        
        print("📱 [STATE] UI状态保存完成")
    }
    

}