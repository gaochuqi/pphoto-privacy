import Foundation
import AVFoundation

// 🔍 相机初始化调试测试
class CameraDebugTest {
    
    static func runDiagnostics() {
        print("🔍 开始相机诊断测试...")
        
        // 1. 检查权限状态
        checkPermissionStatus()
        
        // 2. 检查设备可用性
        checkDeviceAvailability()
        
        // 3. 测试会话创建
        testSessionCreation()
        
        // 4. 性能基准测试
        runPerformanceBenchmark()
    }
    
    // 检查权限状态
    private static func checkPermissionStatus() {
        print("\n📱 权限状态检查:")
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch authStatus {
        case .authorized:
            print("✅ 相机权限已授权")
        case .denied:
            print("❌ 相机权限被拒绝")
        case .restricted:
            print("⚠️ 相机权限受限")
        case .notDetermined:
            print("❓ 相机权限未确定")
        @unknown default:
            print("❓ 未知权限状态")
        }
    }
    
    // 检查设备可用性
    private static func checkDeviceAvailability() {
        print("\n📱 设备可用性检查:")
        
        let devices = AVCaptureDevice.devices(for: .video)
        print("发现 \(devices.count) 个视频设备:")
        
        for device in devices {
            print("  - \(device.localizedName) (位置: \(device.position.rawValue))")
            
            // 检查设备是否可用
            do {
                let input = try AVCaptureDeviceInput(device: device)
                print("    ✅ 设备可用")
            } catch {
                print("    ❌ 设备不可用: \(error)")
            }
        }
    }
    
    // 测试会话创建
    private static func testSessionCreation() {
        print("\n📱 会话创建测试:")
        
        let session = AVCaptureSession()
        session.sessionPreset = .medium
        
        // 测试添加输入
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            do {
                let input = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(input) {
                    session.addInput(input)
                    print("✅ 成功添加相机输入")
                } else {
                    print("❌ 无法添加相机输入")
                }
            } catch {
                print("❌ 创建相机输入失败: \(error)")
            }
        } else {
            print("❌ 未找到后置相机")
        }
        
        // 测试添加输出
        let videoOutput = AVCaptureVideoDataOutput()
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            print("✅ 成功添加视频输出")
        } else {
            print("❌ 无法添加视频输出")
        }
        
        print("会话配置完成 - 输入: \(session.inputs.count), 输出: \(session.outputs.count)")
    }
    
    // 性能基准测试
    private static func runPerformanceBenchmark() {
        print("\n📱 性能基准测试:")
        
        let startTime = CACurrentMediaTime()
        
        // 创建会话
        let session = AVCaptureSession()
        session.sessionPreset = .medium
        
        // 配置会话
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            do {
                let input = try AVCaptureDeviceInput(device: device)
                session.addInput(input)
                
                let videoOutput = AVCaptureVideoDataOutput()
                session.addOutput(videoOutput)
                
                session.commitConfiguration()
                
                let endTime = CACurrentMediaTime()
                let duration = (endTime - startTime) * 1000
                
                print("✅ 会话配置完成")
                print("⏱️ 配置耗时: \(String(format: "%.1f", duration))ms")
                
                if duration < 100 {
                    print("🚀 性能优秀 (< 100ms)")
                } else if duration < 500 {
                    print("✅ 性能良好 (100-500ms)")
                } else {
                    print("⚠️ 性能较慢 (> 500ms)")
                }
                
            } catch {
                print("❌ 性能测试失败: \(error)")
            }
        }
    }
}

// 使用示例
// CameraDebugTest.runDiagnostics() 