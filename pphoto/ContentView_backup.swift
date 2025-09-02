//
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
    static let sharedSession = AVCaptureSession()
    static let sharedCIContext = CIContext()
    var captureSession: AVCaptureSession? = CameraViewController.sharedSession
    var ciContext: CIContext? = CameraViewController.sharedCIContext
    var videoOutput: AVCaptureVideoDataOutput?
    var photoOutput: AVCapturePhotoOutput?
    var previewImageView: UIImageView?
    var currentCIImage: CIImage?
    var onPhotoCapture: ((UIImage) -> Void)?
    
    // CoreMotion相关
    private let motionManager = CMMotionManager()
    var currentDeviceOrientation: UIDeviceOrientation = .portrait
    
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
    var currentTemperature: Float = 6500.0 // 色温，单位K，默认6500K
    
    var isContrastVisible = false
    var isSaturationVisible = false
    var isTemperatureVisible = false
    var isFilterPanelVisible = false
    
    var lastUpdateTime: TimeInterval = 0
    var isActive = true
    
    var albumButton: UIButton?
    
    var loadingView: UIActivityIndicatorView?
    
    // 添加帧计数器用于控制预览帧率
    private var frameCount = 0
    private let previewFrameInterval = 1 // 优化：每帧都处理，提升流畅度
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
    }
    var cameraOptions: [CameraOption] = []
    var currentCameraIndex: Int = 0
    var cameraSwitchStack: UIStackView?
    
    private let sessionConfigLock = NSLock()
    
    var filterButton: UIButton?
    var paramButton: UIButton?
    var shutterButton: UIButton?
    
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
    var currentExposure: Float = 0.0 // 曝光补偿值
    
    // 新增：曝光自动关闭定时器
    var exposureAutoHideTimer: Timer?
    
    // 添加会话配置锁，防止begin/commit之间调用startRunning
    private var isConfiguringSession = false
    
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
    
    // Live Photo开关
    var livePhotoEnabled: Bool = false
    var livePhotoButton: UIButton?
    var livePhotoMovieURL: URL?
    
    // 用于缓存Live Photo静态图数据
    var lastLivePhotoData: Data?
    var lastLivePhotoUniqueID: Int64?
    
    // 实时滤镜处理队列和节流
    let processingQueue = DispatchQueue(label: "filter.processing", qos: .userInitiated)
    var filterUpdateWorkItem: DispatchWorkItem?
    var lastFilterUpdateTime: TimeInterval = 0
    
    // 新增：zoom显示label
    var zoomLabel: UILabel?
    
    // 新增：AVCaptureVideoPreviewLayer
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    let processInterval = 2 // 每2帧处理一次
    
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
        performanceMetrics.appLaunchTime = Date().timeIntervalSince1970
        print("viewDidLoad开始 - 优化初始化流程")
        
        // 1. 立即初始化必要UI（主线程，快速完成）
        setupEssentialUI()
        
        // 2. 异步初始化相机和权限（后台线程）
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.initializeCameraAsync()
        }
    }
    
    // MARK: - 异步相机初始化
    private func initializeCameraAsync() {
        print("开始异步相机初始化")
        let startTime = Date().timeIntervalSince1970
        
        // 1. 请求相机权限
        requestCameraPermissionIfNeeded { [weak self] in
            guard let self = self else { return }
            
            // 2. 配置相机会话
            self.configureSessionIfNeeded()
            
            // 3. 启动相机
            self.sessionQueue.async {
                if let session = self.captureSession, !session.isRunning {
                    self.sessionConfigLock.lock()
                    session.startRunning()
                    self.sessionConfigLock.unlock()
                    
                    // 记录相机启动时间
                    self.performanceMetrics.cameraStartTime = Date().timeIntervalSince1970 - startTime
                    print("相机启动完成 - 耗时: \(String(format: "%.2f", self.performanceMetrics.cameraStartTime))s")
                    
                    // 延迟记录首帧时间
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.performanceMetrics.firstFrameTime = Date().timeIntervalSince1970 - startTime
                        self.logPerformanceMetrics()
                    }
                }
            }
            
            // 4. 延迟初始化其他UI组件
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.setupLazyUI()
            }
        }
    }

    // 新增：只初始化主预览和关键按钮
    func setupMinimalUI() {
        // 只初始化 filteredPreviewImageView、shutterButton、switchButton、albumButton 等主UI
        // 其它面板/滤镜/调节等延后加载
        // ... 你的主UI初始化代码 ...
    }

    // 新增：延迟加载面板/滤镜/调节等
    func setupRestUI() {
        // 初始化 filterPanelView、contrastContainer、saturationContainer、temperatureContainer、exposureContainer 等
        // ... 你的面板/滤镜/调节UI初始化代码 ...
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
        if let session = captureSession, !session.isRunning {
            sessionQueue.async {
                if self.isConfiguringSession {
                    print("[DEBUG] 配置中，跳过startRunning(viewWillAppear)")
                    return
                }
                self.sessionConfigLock.lock()
                session.startRunning()
                self.sessionConfigLock.unlock()
            }
        }
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
                let catPath = (sceneGuideRoot! as NSString).appendingPathComponent(currentSceneCategory ?? "")
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
        print("[DEBUG] configureSessionIfNeeded called")
        
        // 避免重复配置
        guard !isSessionConfigured else {
            print("[DEBUG] Session already configured, skipping")
            return
        }
        
        // 权限检查
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if authStatus == .authorized {
            print("[DEBUG] Camera authorized")
            setupCamera(startSessionIfNeeded: true)
            isSessionConfigured = true
        } else if authStatus == .notDetermined {
            print("[DEBUG] Camera not determined, requesting access")
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard let self = self else { return }
                if granted {
                    print("[DEBUG] Camera access granted")
                    if !self.isSessionConfigured {
                        self.setupCamera(startSessionIfNeeded: true)
                        self.isSessionConfigured = true
                    }
                } else {
                    print("[DEBUG] Camera access denied")
                    DispatchQueue.main.async {
                        self.showPermissionDeniedAlert()
                    }
                }
            }
        } else {
            print("[DEBUG] Camera denied or restricted")
            DispatchQueue.main.async {
                self.showPermissionDeniedAlert()
            }
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
            if isLowEndDevice() {
                session.sessionPreset = .high
            } else {
            session.sessionPreset = .photo
            }
            self.cameraOptions = []
            // 超广角
            let ultraWideDevice = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back)
            if ultraWideDevice != nil {
                self.cameraOptions.append(CameraOption(device: ultraWideDevice!, label: "0.5x"))
            }
            // 广角
            let wideDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
            if wideDevice != nil {
                self.cameraOptions.append(CameraOption(device: wideDevice!, label: "1x"))
            }
            // 长焦（2x）
            let teleDevice = AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back)
            if teleDevice != nil {
                self.cameraOptions.append(CameraOption(device: teleDevice!, label: "2x"))
            } else if wideDevice != nil {
                self.cameraOptions.append(CameraOption(device: wideDevice!, label: "2x"))
            }
            // 前置镜头
            let frontDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
            if frontDevice != nil {
                self.cameraOptions.append(CameraOption(device: frontDevice!, label: "前置"))
            }
            // 只在首次填充后自动切换到1x
            if !self.hasSetDefaultCameraIndex {
                if let idx = self.cameraOptions.firstIndex(where: { $0.label == "1x" }) {
                    self.currentCameraIndex = idx
                } else {
                    self.currentCameraIndex = 0
                }
                self.hasSetDefaultCameraIndex = true
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
            // 自动设置isUsingFrontCamera
            self.isUsingFrontCamera = (selectedDevice.position == .front)
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
                self.videoOutput?.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
                self.videoOutput?.alwaysDiscardsLateVideoFrames = true
            }
            // 始终设置delegate，防止切换后黑屏
            if let vOutput = self.videoOutput {
                let videoQueue = DispatchQueue(label: "videoQueue", qos: .userInitiated)
                vOutput.setSampleBufferDelegate(self, queue: videoQueue)
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
            // 主动设置Live Photo支持
            if let pOutput = self.photoOutput, pOutput.isLivePhotoCaptureSupported {
                pOutput.isLivePhotoCaptureEnabled = true
            }
            if let videoConnection = self.videoOutput?.connection(with: .video) {
                videoConnection.videoOrientation = .portrait
            }
            if let photoConnection = self.photoOutput?.connection(with: .video) {
                photoConnection.videoOrientation = .portrait
            }
            // 数字2x变焦适配
            if selectedOption.label == "2x" && selectedDevice.deviceType == .builtInWideAngleCamera && teleDevice == nil {
                do {
                    try selectedDevice.lockForConfiguration()
                    selectedDevice.videoZoomFactor = min(2.0, selectedDevice.activeFormat.videoMaxZoomFactor)
                    selectedDevice.unlockForConfiguration()
                } catch {
                    print("[DEBUG] 数字2x变焦失败: \(error)")
                }
            }
            
            session.commitConfiguration()
            self.isConfiguringSession = false
            // commitConfiguration之后再启动session（只调用一次）
            if !session.isRunning {
                session.startRunning()
            }
            print("[DEBUG] setupCamera执行完成")
            // 关键：在主线程上设置zoom，隐藏预览，设置好后再显示，避免闪烁
            DispatchQueue.main.async {
                // 先隐藏预览，防止用户看到未裁剪画面
                self.filteredPreviewImageView?.isHidden = true
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
                // Live Photo按钮支持性
                if let pOutput = self.photoOutput, let btn = self.livePhotoButton {
                    if !pOutput.isLivePhotoCaptureSupported || !pOutput.isLivePhotoCaptureEnabled {
                        btn.isEnabled = false
                        btn.alpha = 0.4
                    } else {
                        btn.isEnabled = true
                        btn.alpha = 1.0
                    }
                }
                // 切换镜头时同步更新previewLayer的session
                if let layer = self.previewLayer {
                    layer.session = self.captureSession
                }
                self.filteredPreviewImageView?.isHidden = false
            }
            self.sessionConfigLock.unlock()
        }
    }
    
    // MARK: - 预览层布局
    func setupPreviewView() {
        // 不再设置previewLayer的frame和videoGravity
    }
    
    // MARK: - 实时帧处理（优化性能）
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if isSwitchingCamera { return } // 切换期间不更新预览
        
        frameCount += 1
        if frameCount % processInterval != 0 { return }
        
        // 使用后台队列处理图像
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self else { return }
            
            autoreleasepool {
                guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
                var ciImage = CIImage(cvPixelBuffer: imageBuffer)
                
                // 统一裁剪为4:3区域
                let extent = ciImage.extent
                let width = extent.width
                let height = extent.height
                let isFront = self.isUsingFrontCamera
                
                if isFront {
                    // 前置镜头：以高为基准裁剪为4:3
                    let targetWidth = height * 3.0 / 4.0
                    if width > targetWidth + 2 {
                        let x = (width - targetWidth) / 2.0
                        ciImage = ciImage.cropped(to: CGRect(x: x, y: 0, width: targetWidth, height: height))
                    }
                } else {
                    // 后置镜头：以宽为基准裁剪为4:3
                    let targetHeight = width * 4.0 / 3.0
                    if height > targetHeight + 2 {
                        let y = (height - targetHeight) / 2.0
                        ciImage = ciImage.cropped(to: CGRect(x: 0, y: y, width: width, height: targetHeight))
                    } else {
                        let targetWidth = height * 3.0 / 4.0
                        if width > targetWidth + 2 {
                            let x = (width - targetWidth) / 2.0
                            ciImage = ciImage.cropped(to: CGRect(x: x, y: 0, width: targetWidth, height: height))
                        }
                    }
                }
                
                // 保存原始裁剪后的图像
                self.currentCIImage = ciImage
                
                // 应用滤镜（后台处理）
                let outputCI = self.applyFilters(to: ciImage)
                guard let context = self.ciContext else { return }
                
                if let cgImage = context.createCGImage(outputCI, from: outputCI.extent) {
                    var previewImage = UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
                    
                    if self.isUsingFrontCamera {
                        previewImage = self.flipImageHorizontally(previewImage)
                    }
                    
                    // 主线程更新UI
                    DispatchQueue.main.async {
                        if let imageView = self.filteredPreviewImageView, !imageView.isHidden {
                            imageView.image = previewImage
                            imageView.alpha = 1.0
                            imageView.backgroundColor = .black
                            
                            // 减少调试输出频率
                            if self.frameCount % 60 == 0 {
                                print("[DEBUG] 实时预览更新 - 帧: \(self.frameCount)")
                            }
                        }
                    }
                }
            }
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
    
    // MARK: - 懒加载标记
    private var isEssentialUIInitialized = false
    private var isFilterUIInitialized = false
    private var isSceneUIInitialized = false
    private var isParamUIInitialized = false
    
    func setupUI() {
        print("setupUI开始 - 只初始化必要UI")
        setupEssentialUI()
    }
    
    // MARK: - 必要UI初始化（相机预览、基础按钮）
    private func setupEssentialUI() {
        guard !isEssentialUIInitialized else { return }
        
        print("初始化必要UI组件")
        
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
                layer.videoGravity = .resizeAspectFill
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
            filteredPreviewImageView?.isHidden = true
            filteredPreviewImageView?.clipsToBounds = true
            filteredPreviewImageView?.layer.masksToBounds = true
            
            // Apple Design: 添加圆角和阴影
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
        // --- 其余UI照常 ---
        // 4. 始终插入最底层
        if let preview = filteredPreviewImageView, preview.superview !== view {
            view.insertSubview(preview, at: 0)
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

        // 功能按钮和参数按钮放在屏幕上方，靠左对齐
        let blurEffect = UIBlurEffect(style: .systemMaterialDark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.layer.cornerRadius = 22
        blurView.clipsToBounds = true
        view.addSubview(blurView)
        NSLayoutConstraint.activate([
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            blurView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            blurView.heightAnchor.constraint(equalToConstant: 32),
            blurView.widthAnchor.constraint(equalToConstant: 280)
        ])
        // 1. 创建Apple Design风格按钮
        filterButton = makeAppleButton(title: "功能", icon: "slider.horizontal.3")
        sceneButton = makeAppleButton(title: "场景", icon: "photo.on.rectangle")
        paramButton = makeAppleButton(title: "参数", icon: "gearshape")

        // 2. 设置Apple Design属性
        let buttons = [filterButton, sceneButton, paramButton]
        let colors: [UIColor] = [.systemBlue, .systemPurple, .systemGreen]
        for (i, btn) in buttons.enumerated() {
            btn?.backgroundColor = colors[i].withAlphaComponent(0.1)
            btn?.layer.borderColor = colors[i].withAlphaComponent(0.3).cgColor
            btn?.layer.borderWidth = 1
            btn?.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
            btn?.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            btn?.layer.cornerRadius = 14
            btn?.translatesAutoresizingMaskIntoConstraints = false
        }
        // 恢复点击事件绑定
        filterButton?.addTarget(self, action: #selector(toggleFilterPanel), for: .touchUpInside)
        sceneButton?.addTarget(self, action: #selector(openSceneGuide), for: .touchUpInside)
        paramButton?.addTarget(self, action: #selector(showParamManager), for: .touchUpInside)

        // 3. 添加到视图
        blurView.contentView.addSubview(filterButton!)
        blurView.contentView.addSubview(sceneButton!)
        blurView.contentView.addSubview(paramButton!)

        // 4. 设置约束（更小的按钮尺寸）
        NSLayoutConstraint.activate([
            filterButton!.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor, constant: 6),
            filterButton!.centerYAnchor.constraint(equalTo: blurView.contentView.centerYAnchor),
            filterButton!.heightAnchor.constraint(equalToConstant: 28),
            sceneButton!.leadingAnchor.constraint(equalTo: filterButton!.trailingAnchor, constant: 6),
            sceneButton!.centerYAnchor.constraint(equalTo: blurView.contentView.centerYAnchor),
            sceneButton!.heightAnchor.constraint(equalToConstant: 28),
            paramButton!.leadingAnchor.constraint(equalTo: sceneButton!.trailingAnchor, constant: 6),
            paramButton!.centerYAnchor.constraint(equalTo: blurView.contentView.centerYAnchor),
            paramButton!.heightAnchor.constraint(equalToConstant: 28),
            paramButton!.trailingAnchor.constraint(lessThanOrEqualTo: blurView.contentView.trailingAnchor, constant: -6)
        ])
        print("功能按钮创建完成")
        
        // 标记必要UI已初始化
        isEssentialUIInitialized = true
        
        // 异步初始化其他UI组件
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.setupLazyUI()
        }

        // 镜头切换按钮组美化，包裹在椭圆背景内
        if cameraSwitchStack != nil {
            cameraSwitchStack?.removeFromSuperview()
        }
        // 先移除旧的包裹视图
        view.viewWithTag(8888)?.removeFromSuperview()
        // 毛玻璃磨砂背景
        let ovalBlur = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterialDark))
        ovalBlur.translatesAutoresizingMaskIntoConstraints = false
        ovalBlur.layer.cornerRadius = 26
        ovalBlur.clipsToBounds = true
        // 渐变叠加
        let ovalGradient = CAGradientLayer()
        ovalGradient.colors = [UIColor.systemBlue.withAlphaComponent(0.13).cgColor, UIColor.black.withAlphaComponent(0.18).cgColor]
        ovalGradient.startPoint = CGPoint(x: 0, y: 0.5)
        ovalGradient.endPoint = CGPoint(x: 1, y: 0.5)
        ovalBlur.layer.insertSublayer(ovalGradient, at: 0)
        ovalBlur.layer.borderWidth = 1.5
        ovalBlur.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.5).cgColor
        ovalBlur.layer.shadowColor = UIColor.systemBlue.cgColor
        ovalBlur.layer.shadowOpacity = 0.18
        ovalBlur.layer.shadowOffset = CGSize(width: 0, height: 2)
        ovalBlur.layer.shadowRadius = 8
        view.addSubview(ovalBlur)
        cameraSwitchStack = UIStackView()
        cameraSwitchStack?.axis = .horizontal
        cameraSwitchStack?.alignment = .center
        cameraSwitchStack?.distribution = .equalSpacing
        cameraSwitchStack?.spacing = 20
        cameraSwitchStack?.translatesAutoresizingMaskIntoConstraints = false
        for (idx, option) in cameraOptions.enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle(option.label, for: .normal)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: idx == currentCameraIndex ? 16 : 14, weight: .bold)
            btn.setTitleColor(idx == currentCameraIndex ? .white : UIColor.white.withAlphaComponent(0.7), for: .normal)
            btn.backgroundColor = idx == currentCameraIndex ? UIColor.systemBlue.withAlphaComponent(0.82) : UIColor.black.withAlphaComponent(0.18)
            let sizeW: CGFloat = 44
            let sizeH: CGFloat = 32
            btn.frame = CGRect(x: 0, y: 0, width: sizeW, height: sizeH)
            btn.layer.cornerRadius = sizeH / 2
            btn.clipsToBounds = true
            btn.tag = idx
            btn.addTarget(self, action: #selector(switchToCameraWithAnimation(_:)), for: .touchUpInside)
            // 选中按钮主色描边和阴影
            if idx == currentCameraIndex {
                btn.layer.borderWidth = 1.5
                btn.layer.borderColor = UIColor.white.withAlphaComponent(0.9).cgColor
                btn.layer.shadowColor = UIColor.systemBlue.cgColor
                btn.layer.shadowOpacity = 0.25
                btn.layer.shadowOffset = CGSize(width: 0, height: 2)
                btn.layer.shadowRadius = 6
            } else {
                btn.layer.borderWidth = 0
                btn.layer.shadowOpacity = 0
            }
            cameraSwitchStack?.addArrangedSubview(btn)
            // 设置宽高约束
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.widthAnchor.constraint(equalToConstant: sizeW).isActive = true
            btn.heightAnchor.constraint(equalToConstant: sizeH).isActive = true
        }
        ovalBlur.contentView.addSubview(cameraSwitchStack!)
        // 椭圆宽度根据按钮数量自适应
        let ovalWidth: CGFloat = CGFloat(44 * cameraOptions.count + 20 * (cameraOptions.count - 1)) + 24
        NSLayoutConstraint.activate([
            ovalBlur.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            ovalBlur.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -dynamicBottomOffset()),
            ovalBlur.heightAnchor.constraint(equalToConstant: 52),
            ovalBlur.widthAnchor.constraint(equalToConstant: ovalWidth),
            cameraSwitchStack!.centerXAnchor.constraint(equalTo: ovalBlur.contentView.centerXAnchor),
            cameraSwitchStack!.centerYAnchor.constraint(equalTo: ovalBlur.contentView.centerYAnchor),
            cameraSwitchStack!.heightAnchor.constraint(equalToConstant: 32)
        ])
        print("摄像头切换按钮组创建完成")

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
        if let contrastContainer = contrastContainer {
            NSLayoutConstraint.activate([
                contrastContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                contrastContainer.topAnchor.constraint(equalTo: filterButton!.bottomAnchor, constant: 60), // 下移，避免遮挡滤镜按钮
                contrastContainer.widthAnchor.constraint(equalToConstant: 200),
                contrastContainer.heightAnchor.constraint(equalToConstant: 60)
            ])
        }
        if let saturationContainer = saturationContainer {
            NSLayoutConstraint.activate([
                saturationContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                saturationContainer.topAnchor.constraint(equalTo: filterButton!.bottomAnchor, constant: 60), // 下移，避免遮挡滤镜按钮
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
            filterPanelView.centerXAnchor.constraint(equalTo: filterButton!.centerXAnchor, constant: 100), // 向右偏移100pt
            filterPanelView.topAnchor.constraint(equalTo: filterButton!.bottomAnchor, constant: 8),
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
                temperatureContainer.topAnchor.constraint(equalTo: filterButton!.bottomAnchor, constant: 60), // 下移，避免遮挡滤镜按钮
                temperatureContainer.widthAnchor.constraint(equalToConstant: 200),
                temperatureContainer.heightAnchor.constraint(equalToConstant: 60)
            ])
        }

        // 色温滑块
        temperatureSlider = UISlider()
        temperatureSlider?.translatesAutoresizingMaskIntoConstraints = false
        temperatureSlider?.minimumValue = 0
        temperatureSlider?.maximumValue = 100
        temperatureSlider?.value = 50
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
    }
    
    // MARK: - 懒加载UI组件
    private func setupLazyUI() {
        print("开始懒加载UI组件")
        
        // 异步初始化滤镜UI
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.setupFilterUI()
        }
        
        // 异步初始化场景UI
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.setupSceneUI()
        }
        
        // 异步初始化参数UI
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.setupParamUI()
        }
    }
    
    // MARK: - 滤镜UI懒加载
    private func setupFilterUI() {
        guard !isFilterUIInitialized else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            print("初始化滤镜UI组件")
            
            // 新增：滤镜功能面板
            let filterPanelView = makeAppleBlurView(style: .systemMaterialDark)
            filterPanelView.isHidden = true
            filterPanelView.translatesAutoresizingMaskIntoConstraints = false
            self.filterPanelView = filterPanelView
            self.view.addSubview(filterPanelView)
            
            // 设置滤镜面板约束
            NSLayoutConstraint.activate([
                filterPanelView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                filterPanelView.topAnchor.constraint(equalTo: self.filterButton!.bottomAnchor, constant: 20),
                filterPanelView.widthAnchor.constraint(equalToConstant: 320),
                filterPanelView.heightAnchor.constraint(equalToConstant: 50)
            ])
            
            // 调节容器（Apple Design风格）
            self.contrastContainer = makeAppleBlurView(style: .systemMaterialDark)
            self.contrastContainer?.isHidden = true
            self.view.addSubview(self.contrastContainer!)
            
            self.saturationContainer = makeAppleBlurView(style: .systemMaterialDark)
            self.saturationContainer?.isHidden = true
            self.view.addSubview(self.saturationContainer!)
            
            self.temperatureContainer = makeAppleBlurView(style: .systemMaterialDark)
            self.temperatureContainer?.isHidden = true
            self.view.addSubview(self.temperatureContainer!)
            
            self.exposureContainer = makeAppleBlurView(style: .systemMaterialDark)
            self.exposureContainer?.isHidden = true
            self.view.addSubview(self.exposureContainer!)
            
            // 设置滑块容器约束
            if let contrastContainer = self.contrastContainer {
                NSLayoutConstraint.activate([
                    contrastContainer.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                    contrastContainer.topAnchor.constraint(equalTo: self.filterButton!.bottomAnchor, constant: 60),
                    contrastContainer.widthAnchor.constraint(equalToConstant: 200),
                    contrastContainer.heightAnchor.constraint(equalToConstant: 60)
                ])
            }
            
            // 继续初始化其他滤镜组件...
            self.setupFilterComponents()
            
            self.isFilterUIInitialized = true
            print("滤镜UI初始化完成")
        }
    }
    
    // MARK: - 场景UI懒加载
    private func setupSceneUI() {
        guard !isSceneUIInitialized else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            print("初始化场景UI组件")
            
            // 场景相关的UI初始化
            self.loadSceneCategories()
            
            self.isSceneUIInitialized = true
            print("场景UI初始化完成")
        }
    }
    
    // MARK: - 参数UI懒加载
    private func setupParamUI() {
        guard !isParamUIInitialized else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            print("初始化参数UI组件")
            
            // 参数相关的UI初始化
            // 这里可以预加载参数预设等
            
            self.isParamUIInitialized = true
            print("参数UI初始化完成")
        }
    }
    
    // MARK: - 滤镜组件初始化
    private func setupFilterComponents() {
        // 这里包含原来setupUI中的滤镜相关组件初始化代码
        // 为了保持代码简洁，这里只标记需要移动的部分
        print("滤镜组件初始化中...")
    }
    
    // MARK: - 性能监控
    private var performanceMetrics = PerformanceMetrics()
    
    private struct PerformanceMetrics {
        var appLaunchTime: TimeInterval = 0
        var cameraStartTime: TimeInterval = 0
        var firstFrameTime: TimeInterval = 0
        var filterProcessingTime: TimeInterval = 0
        var memoryUsage: UInt64 = 0
    }
    
    private func logPerformanceMetrics() {
        let totalLaunchTime = Date().timeIntervalSince1970 - performanceMetrics.appLaunchTime
        print("🚀 性能指标:")
        print("   应用启动时间: \(String(format: "%.2f", totalLaunchTime))s")
        print("   相机启动时间: \(String(format: "%.2f", performanceMetrics.cameraStartTime))s")
        print("   首帧显示时间: \(String(format: "%.2f", performanceMetrics.firstFrameTime))s")
        print("   滤镜处理时间: \(String(format: "%.3f", performanceMetrics.filterProcessingTime))s")
        
        // 内存使用情况
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        if kerr == KERN_SUCCESS {
            let memoryUsageMB = Double(info.resident_size) / 1024.0 / 1024.0
            print("   内存使用: \(String(format: "%.1f", memoryUsageMB))MB")
        }
    }

        // 拍照按钮（Apple Design风格）
        shutterButton = makeAppleShutterButton()
        shutterButton!.tag = 999 // 用于动画识别
        shutterButton!.addTarget(self, action: #selector(shutterTapped), for: .touchUpInside)
        view.addSubview(shutterButton!)
        NSLayoutConstraint.activate([
            shutterButton!.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shutterButton!.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -58),
            shutterButton!.widthAnchor.constraint(equalToConstant: 60),
            shutterButton!.heightAnchor.constraint(equalToConstant: 60)
        ])

        // 设置曝光容器约束
        NSLayoutConstraint.activate([
            exposureContainer!.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            exposureContainer!.topAnchor.constraint(equalTo: filterButton!.bottomAnchor, constant: 60), // 下移，避免遮挡滤镜按钮
            exposureContainer!.widthAnchor.constraint(equalToConstant: 200),
            exposureContainer!.heightAnchor.constraint(equalToConstant: 60)
        ])
        // --- 曝光条相关 ---
        exposureSlider = PrettySlider()
        exposureSlider?.minimumValue = 0
        exposureSlider?.maximumValue = 100
        exposureSlider?.value = 50
        exposureSlider?.addTarget(self, action: #selector(exposureChanged), for: .valueChanged)
        exposureSlider?.translatesAutoresizingMaskIntoConstraints = false
        // 美化样式
        exposureSlider?.minimumTrackTintColor = UIColor.systemBlue.withAlphaComponent(0.8)
        exposureSlider?.maximumTrackTintColor = UIColor.white.withAlphaComponent(0.2)
        exposureSlider?.setThumbImage(sliderThumbImage(color: .systemBlue), for: .normal)
        exposureSlider?.setThumbImage(sliderThumbImage(color: .systemBlue, radius: 16), for: .highlighted)
        (exposureContainer as? UIVisualEffectView)?.contentView.addSubview(exposureSlider!)
        
        // 正确创建并引用label为类属性
        self.exposureValueLabel = UILabel()
        guard let exposureValueLabel = self.exposureValueLabel else { return }
        exposureValueLabel.translatesAutoresizingMaskIntoConstraints = false
        exposureValueLabel.textColor = .white
        exposureValueLabel.font = UIFont.systemFont(ofSize: 14)
        exposureValueLabel.textAlignment = .center
        exposureValueLabel.text = String(format: "%.1f", currentExposure)
        (exposureContainer as? UIVisualEffectView)?.contentView.addSubview(exposureValueLabel)
        // 约束也用 exposureValueLabel
        if let exposureContainer = exposureContainer, let exposureSlider = exposureSlider {
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
        // --- 曝光条相关 ---

        // 曝光条上下滑手势
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleExposurePan(_:)))
        exposureContainer?.addGestureRecognizer(pan)
        // --- setupUI 结尾，所有 addSubview/约束都设置完后 ---
        DispatchQueue.main.async {
            if let preview = self.filteredPreviewImageView {
                print("[DEBUG] view.subviews 层级顺序：")
                for (idx, v) in self.view.subviews.enumerated() {
                    print("[DEBUG] subview[\(idx)]: \(type(of: v)), tag=\(v.tag), isHidden=\(v.isHidden), alpha=\(v.alpha)")
                }
                print("[DEBUG] filteredPreviewImageView 属性：frame=\(preview.frame), alpha=\(preview.alpha), isHidden=\(preview.isHidden), superview=\(String(describing: preview.superview)), image is nil=\(preview.image == nil)")
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
            thumbImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -dynamicBottomOffset() - 48), // 向上移30pt
            thumbImageView.widthAnchor.constraint(equalToConstant: 56),
            thumbImageView.heightAnchor.constraint(equalToConstant: 56)
        ])
        refreshThumbnail()
        thumbImageView.gestureRecognizers?.forEach { thumbImageView.removeGestureRecognizer($0) }
        let tap = UITapGestureRecognizer(target: self, action: #selector(openLastPhotoInAlbum))
        thumbImageView.addGestureRecognizer(tap)

        // 右上角Live Photo按钮
        if let oldBtn = livePhotoButton { oldBtn.removeFromSuperview() }
        let liveBtn = UIButton(type: .system)
        liveBtn.translatesAutoresizingMaskIntoConstraints = false
        liveBtn.setTitle("LIVE", for: .normal)
        liveBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        liveBtn.setTitleColor(livePhotoEnabled ? .systemYellow : .white, for: .normal)
        liveBtn.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        liveBtn.layer.cornerRadius = 18
        liveBtn.layer.borderWidth = 1.2
        liveBtn.layer.borderColor = (livePhotoEnabled ? UIColor.systemYellow : UIColor.white).withAlphaComponent(0.7).cgColor
        liveBtn.layer.shadowColor = UIColor.systemYellow.cgColor
        liveBtn.layer.shadowOpacity = livePhotoEnabled ? 0.18 : 0.08
        liveBtn.layer.shadowOffset = CGSize(width: 0, height: 2)
        liveBtn.layer.shadowRadius = 4
        liveBtn.addTarget(self, action: #selector(toggleLivePhoto), for: .touchUpInside)
        view.addSubview(liveBtn)
        NSLayoutConstraint.activate([
            liveBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
            liveBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 18),
            liveBtn.widthAnchor.constraint(equalToConstant: 64),
            liveBtn.heightAnchor.constraint(equalToConstant: 36)
        ])
        self.livePhotoButton = liveBtn

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
        applyLowPowerModeIfNeeded()
    }
    
    @objc func toggleFilterPanel() {
        isFilterPanelVisible.toggle()
        filterPanelView?.isHidden = !isFilterPanelVisible
        dismissParamManager()
        sceneCategoryCollectionView?.isHidden = true
        sceneImageCollectionView?.isHidden = true
        isContrastVisible = false
        isSaturationVisible = false
        isTemperatureVisible = false
        isExposureVisible = false
        updateButtonStates()
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
        if isContrastVisible { updatePreviewImage() } else { hideFilterPreviewIfNeeded() }
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
        if isSaturationVisible { updatePreviewImage() } else { hideFilterPreviewIfNeeded() }
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
        if isTemperatureVisible { updatePreviewImage() } else { hideFilterPreviewIfNeeded() }
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
        // 拍照前强制限制zoom
        if let device = (captureSession?.inputs.first as? AVCaptureDeviceInput)?.device {
            let currentLabel = cameraOptions[currentCameraIndex].label
            let maxZoom = maxEffectiveZoom(for: currentLabel)
            print("[DEBUG] shutterTapped: 镜头=\(currentLabel), maxZoom=\(maxZoom), 当前videoZoomFactor=\(device.videoZoomFactor)")
            if device.videoZoomFactor > maxZoom {
                do {
                    try device.lockForConfiguration()
                    device.videoZoomFactor = maxZoom
                    device.unlockForConfiguration()
                } catch {}
            }
            // 无论是否调整，都同步刷新UI
            updateZoomLabel()
        }
        // Live Photo or 静态图
        if livePhotoEnabled, let output = photoOutput, output.isLivePhotoCaptureSupported, output.isLivePhotoCaptureEnabled {
            let tempDir = NSTemporaryDirectory()
            let movieFileName = UUID().uuidString + ".mov"
            let movieURL = URL(fileURLWithPath: tempDir).appendingPathComponent(movieFileName)
            livePhotoMovieURL = movieURL
            let settings: AVCapturePhotoSettings
            if output.availablePhotoCodecTypes.contains(.hevc) {
                settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            } else {
                settings = AVCapturePhotoSettings()
            }
            if output.isHighResolutionCaptureEnabled {
                settings.isHighResolutionPhotoEnabled = true
            }
            settings.livePhotoMovieFileURL = movieURL
            output.capturePhoto(with: settings, delegate: self)
        } else {
        let settings = AVCapturePhotoSettings()
            if let output = photoOutput, output.isHighResolutionCaptureEnabled {
                settings.isHighResolutionPhotoEnabled = true
            }
        photoOutput?.capturePhoto(with: settings, delegate: self)
        }
        // 拍照后也刷新一次UI zoom label，确保同步
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
        // 只暂停 session，不释放
        if let session = captureSession, session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.sessionConfigLock.lock()
                session.stopRunning()
                self.sessionConfigLock.unlock()
            }
        }
        // 断开 delegate，防止异步回调
        videoOutput?.setSampleBufferDelegate(nil, queue: nil)
        // 其它 UI/资源保留，不做释放
        for subview in view.subviews {
            if let livePhotoView = subview as? PHLivePhotoView {
                livePhotoView.stopPlayback()
            }
        }
    }
    
    // MARK: - AVCapturePhotoCaptureDelegate
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let device = (self.captureSession?.inputs.first as? AVCaptureDeviceInput)?.device {
            let currentLabel = cameraOptions[currentCameraIndex].label
            let maxZoom = maxEffectiveZoom(for: currentLabel)
            print("[DEBUG] photoOutput: 镜头=\(currentLabel), maxZoom=\(maxZoom), 拍照时videoZoomFactor=\(device.videoZoomFactor)")
        }
        guard let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) else { return }
        if livePhotoEnabled {
            // 只缓存主图原始数据，不做任何处理，保证与视频帧一致
            if let uniqueID = photo.resolvedSettings.uniqueID as Int64? {
                lastLivePhotoData = imageData
                lastLivePhotoUniqueID = uniqueID
            }
        } else {
            // 只在Live Photo关闭时对图片做滤镜/方向处理后保存
        let corrected = rotateImageToCorrectOrientation(image, deviceOrientation: self.currentDeviceOrientation, isFrontCamera: self.isUsingFrontCamera)
            let filteredImage = applyFiltersToUIImage(corrected)
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetChangeRequest.creationRequestForAsset(from: filteredImage)
            }, completionHandler: { success, error in
                if success {
                    let fetchOptions = PHFetchOptions()
                    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                    fetchOptions.fetchLimit = 1
                    let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
                    if let asset = assets.firstObject {
                        UserDefaults.standard.set(asset.localIdentifier, forKey: "LastPhotoLocalIdentifier")
                        self.refreshThumbnail()
                    }
                }
            })
        }
    }
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingLivePhotoToMovieFileAt outputFileURL: URL, duration: CMTime, photoDisplayTime: CMTime, resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        guard livePhotoEnabled, let liveURL = livePhotoMovieURL else { return }
        // 只在uniqueID匹配时保存Live Photo
        if let photoData = lastLivePhotoData, let uniqueID = lastLivePhotoUniqueID, uniqueID == resolvedSettings.uniqueID {
            PHPhotoLibrary.shared().performChanges({
                let req = PHAssetCreationRequest.forAsset()
                let options = PHAssetResourceCreationOptions()
                req.addResource(with: .photo, data: photoData, options: options)
                req.addResource(with: .pairedVideo, fileURL: liveURL, options: nil)
            }, completionHandler: { success, error in
                if success {
                    let fetchOptions = PHFetchOptions()
                    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                    fetchOptions.fetchLimit = 1
                    let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
                    if let asset = assets.firstObject {
                        UserDefaults.standard.set(asset.localIdentifier, forKey: "LastPhotoLocalIdentifier")
                        self.refreshThumbnail()
                    }
                }
                // 删除临时视频
                try? FileManager.default.removeItem(at: liveURL)
            })
            lastLivePhotoData = nil
            lastLivePhotoUniqueID = nil
        }
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
        if #available(iOS 13.0, *) {
            return view.window?.windowScene?.interfaceOrientation ?? .portrait
        } else {
            return UIApplication.shared.statusBarOrientation
        }
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
    func startDeviceMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            print("[DEBUG] 设备不支持Motion")
            return
        }
        motionManager.deviceMotionUpdateInterval = 1.0 // 降低到1Hz，进一步减少CPU占用
        motionManager.startDeviceMotionUpdates(to: OperationQueue.main) { [weak self] motion, error in
            guard let self = self, let motion = motion, error == nil else {
                print("[DEBUG] motion 回调未触发或有错误: \(String(describing: error))")
                return
            }
            let gravity = motion.gravity
            let x = gravity.x
            let y = gravity.y
            print("[DEBUG] motion update: gravity.x=\(x), gravity.y=\(y)")
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
        }
    }
    
    func stopDeviceMotionUpdates() {
        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
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

    // 优化后的方向旋转方法，支持后置横屏180度
    func rotateImageToCorrectOrientation(_ image: UIImage, deviceOrientation: UIDeviceOrientation, isFrontCamera: Bool) -> UIImage {
        var rotationAngle: CGFloat = 0
        var needFlip = false
        switch deviceOrientation {
        case .portrait:
            if isFrontCamera {
                rotationAngle = 0
                needFlip = true // 正拍水平镜像
            } else {
                rotationAngle = 0
            }
        case .portraitUpsideDown:
            if isFrontCamera {
                rotationAngle = .pi
                needFlip = true // 倒立拍水平镜像
            } else {
                rotationAngle = .pi
            }
        case .landscapeLeft:
            if isFrontCamera {
                rotationAngle = -.pi / 2 // 逆时针90度
                needFlip = true
            } else {
                rotationAngle = .pi / 2
            }
        case .landscapeRight:
            if isFrontCamera {
                rotationAngle = .pi / 2 // 顺时针90度
                needFlip = true
            } else {
                rotationAngle = -.pi / 2
            }
        default:
            rotationAngle = 0
        }
        var rotated = rotateImage(image, by: rotationAngle)
        if needFlip {
            rotated = flipImageHorizontally(rotated)
        }
        return rotated
    }
    
    // MARK: - 滤镜缓存优化
    private var lastFilterParams: (contrast: Float, saturation: Float, temperature: Float) = (1.0, 1.0, 6500.0)
    private var filterCache: [String: CIImage] = [:]
    private let filterCacheQueue = DispatchQueue(label: "filter.cache", qos: .userInteractive)
    
    func applyFilters(to ciImage: CIImage) -> CIImage {
        // 检查参数是否变化
        let currentParams = (currentContrast, currentSaturation, currentTemperature)
        let paramsChanged = currentParams != (lastFilterParams.contrast, lastFilterParams.saturation, lastFilterParams.temperature)
        
        // 如果参数没有变化且没有滤镜效果，直接返回原图
        let hasContrast = abs(currentContrast - 1.0) > 0.01
        let hasSaturation = abs(currentSaturation - 1.0) > 0.01
        let hasTemperature = abs(currentTemperature - 6500.0) > 1.0
        
        if !hasContrast && !hasSaturation && !hasTemperature {
            return ciImage
        }
        
        // 检查缓存
        let cacheKey = "\(currentContrast)_\(currentSaturation)_\(currentTemperature)"
        if !paramsChanged, let cached = filterCache[cacheKey] {
            return cached
        }
        
        var output = ciImage
        
        // 低端机型优化
        if !shouldUseHighQualityFilter() {
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
        } else {
            // 高质量滤镜处理
            if hasContrast || hasSaturation {
                if let filter = CIFilter(name: "CIColorControls") {
                    filter.setValue(output, forKey: kCIInputImageKey)
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
                    let mappedTemperature = 6500 + (currentTemperature - 6500) * 2.0
                    tempFilter.setValue(CIVector(x: CGFloat(mappedTemperature), y: 0), forKey: "inputNeutral")
                    tempFilter.setValue(CIVector(x: 6500, y: 0), forKey: "inputTargetNeutral")
                    if let tempResult = tempFilter.outputImage {
                        output = tempResult
                    }
                }
            }
        }
        
        // 更新缓存
        lastFilterParams = (currentContrast, currentSaturation, currentTemperature)
        filterCacheQueue.async {
            // 限制缓存大小
            if self.filterCache.count > 10 {
                self.filterCache.removeAll()
            }
            self.filterCache[cacheKey] = output
        }
        
        return output
    }
    
    // 将滤镜应用到 UIImage
    func applyFiltersToUIImage(_ image: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }
        
        // 应用滤镜
        let filteredCI = applyFilters(to: ciImage)
        
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
    // 双击弹出曝光调节
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        toggleExposurePanel()
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
    // 曝光滑块变更
    @objc private func exposureChanged() {
        guard let slider = exposureSlider else { return }
        currentExposure = slider.value
        exposureValueLabel?.text = String(format: "%.1f", currentExposure)
        exposureUpdateWorkItem?.cancel()
        let sliderValue = currentExposure // 0~100
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
        for btn in cameraSwitchButtons { btn.isEnabled = false }
        // 1. 先彻底阻断帧流
        self.videoOutput?.setSampleBufferDelegate(nil, queue: nil)
        // 2. 立即黑屏并强制刷新
        if let imageView = self.filteredPreviewImageView {
            let blackImage = UIImage(color: UIColor.black, size: imageView.bounds.size)
            imageView.image = blackImage
            imageView.alpha = 1.0
            imageView.isHidden = false
            imageView.setNeedsDisplay()
            CATransaction.flush()
        }
        sessionQueue.async {
            // ...原有切换逻辑...
            guard idx >= 0 && idx < self.cameraOptions.count else {
                DispatchQueue.main.async {
                    self.isSwitchingCamera = false
                    for btn in self.cameraSwitchButtons { btn.isEnabled = true }
                }
                return
            }
            self.currentCameraIndex = idx
            self.setupCamera(startSessionIfNeeded: true)
            DispatchQueue.main.async {
                self.filteredPreviewImageView?.isHidden = false
                self.videoOutput?.setSampleBufferDelegate(self, queue: self.sessionQueue)
                self.setupUI()
                self.isSwitchingCamera = false
                for btn in self.cameraSwitchButtons { btn.isEnabled = true }
            }
        }
    }
    // 新增：带动画的镜头切换方法
    @objc func switchToCameraWithAnimation(_ sender: UIButton) {
        UIView.animate(withDuration: 0.12, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        }) { _ in
            UIView.animate(withDuration: 0.12, animations: {
                sender.transform = .identity
            })
        }
        self.switchCamera(sender)
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

    // 新增重置滤镜方法
    @objc func resetFilters() {
        currentContrast = 1.0
        currentSaturation = 1.0
        currentTemperature = 6500.0
        // 重置曝光参数
        currentExposure = 0.0
        exposureSlider?.value = 50
        exposureChanged()
        contrastSlider?.value = 50
        saturationSlider?.value = 50
        temperatureSlider?.value = 50
        contrastContainer?.isHidden = true
        saturationContainer?.isHidden = true
        temperatureContainer?.isHidden = true
        isContrastVisible = false
        isSaturationVisible = false
        isTemperatureVisible = false
        updateButtonStates()
        // 只刷新滤镜预览
        updatePreviewImage()
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
        managerView.tag = 9999
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
            currentExposure = exposure
            exposureSlider?.value = exposure
            exposureChanged()
        }
        // 立即刷新预览
        if let ciImage = currentCIImage, let context = ciContext, let imageView = filteredPreviewImageView {
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
        guard let slider = exposureSlider else { return }
        slider.value = min(100, max(0, slider.value + step))
        exposureChanged()
        // 同步label
        exposureValueLabel?.text = String(format: "%.1f", currentExposure)
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
        contrastContainer?.isHidden = true
        saturationContainer?.isHidden = true
        temperatureContainer?.isHidden = true
        isContrastVisible = false
        isSaturationVisible = false
        isTemperatureVisible = false
        isExposureVisible = false
        updateButtonStates()
        if isExposureVisible {
            // 居中显示在功能面板下方
            let panelFrame = filterPanelView?.frame ?? CGRect(x: 0, y: 0, width: 0, height: 0)
            let x = panelFrame.midX
            let y = panelFrame.maxY + 38
            exposureContainer?.center = CGPoint(x: x, y: y)
        } else {
            cancelExposureAutoHide()
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

    // 点击缩略图跳转系统相册首页
    @objc func openLastPhotoInAlbum() {
        // 获取最近20张照片，找到当前缩略图索引
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 20
        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        guard assets.count > 0 else { return }
        guard let localId = UserDefaults.standard.string(forKey: "LastPhotoLocalIdentifier") else { return }
        let idx = (0..<assets.count).first(where: { assets.object(at: $0).localIdentifier == localId }) ?? 0
        let previewVC = PhotoPreviewController()
        previewVC.assets = (0..<assets.count).map { assets.object(at: $0) }
        previewVC.startIndex = idx
        previewVC.modalPresentationStyle = .fullScreen
        self.present(previewVC, animated: true)
    }

    // 刷新左下角缩略图
    func refreshThumbnail() {
        DispatchQueue.main.async {
            if let thumbImageView = self.view.viewWithTag(2001) as? UIImageView,
               let localId = UserDefaults.standard.string(forKey: "LastPhotoLocalIdentifier") {
                let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localId], options: nil)
                if let asset = assets.firstObject {
                    let manager = PHImageManager.default()
                    manager.requestImage(for: asset, targetSize: CGSize(width: 56, height: 56), contentMode: .aspectFill, options: nil) { image, _ in
                        thumbImageView.image = image
                    }
                }
            }
        }
    }

    @objc func toggleLivePhoto() {
        livePhotoEnabled.toggle()
        livePhotoButton?.setTitleColor(livePhotoEnabled ? .systemYellow : .white, for: .normal)
        livePhotoButton?.layer.borderColor = (livePhotoEnabled ? UIColor.systemYellow : UIColor.white).withAlphaComponent(0.7).cgColor
        livePhotoButton?.layer.shadowOpacity = livePhotoEnabled ? 0.18 : 0.08
    }

    @objc func closePreviewVC() {
        self.presentedViewController?.dismiss(animated: true)
    }

    func updatePreviewImage() {
        // 实时滤镜处理放到后台队列，主线程只刷新UI
        guard let ciImage = currentCIImage, let context = ciContext, let imageView = filteredPreviewImageView else { return }
        processingQueue.async {
            let filteredCI = self.applyFilters(to: ciImage)
            if let cgImage = context.createCGImage(filteredCI, from: filteredCI.extent) {
                var previewImage = UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
                if self.isUsingFrontCamera {
                    previewImage = self.flipImageHorizontally(previewImage)
                }
                DispatchQueue.main.async {
                    imageView.image = previewImage
                    imageView.isHidden = false // 显示滤镜层
                    
                    // 如果网格线已启用，更新网格线位置
                    if self.isGridLineEnabled {
                        self.showGridLineOnPreview()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    imageView.isHidden = true // 无滤镜时隐藏
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
            if !(self.isContrastVisible || self.isSaturationVisible || self.isTemperatureVisible) && self.currentContrast == 1.0 && self.currentSaturation == 1.0 && self.currentTemperature == 6500.0 {
                self.filteredPreviewImageView?.isHidden = true
            }
        }
    }

    func maxEffectiveZoom(for cameraLabel: String) -> CGFloat {
        let model = UIDevice.current.modelIdentifier
        switch model {
        // iPhone 15 Pro/Pro Max
        case "iPhone16,1", "iPhone16,2":
            switch cameraLabel {
            case "0.5x": return 2.0
            case "1x", "2x", "3x", "前置": return 4.3
            default: return 4.3
            }
        // iPhone 15/15 Plus
        case "iPhone15,4", "iPhone15,5":
            switch cameraLabel {
            case "0.5x": return 2.0
            case "1x", "前置": return 4.3
            default: return 4.3
            }
        // iPhone 14 Pro/Pro Max
        case "iPhone15,2", "iPhone15,3":
            switch cameraLabel {
            case "0.5x": return 2.0
            case "1x", "2x", "3x", "前置": return 4.3
            default: return 4.3
            }
        // iPhone 14/14 Plus
        case "iPhone14,7", "iPhone14,8":
            switch cameraLabel {
            case "0.5x": return 2.0
            case "1x", "前置": return 4.3
            default: return 4.3
            }
        // iPhone 13 Pro/Pro Max
        case "iPhone14,2", "iPhone14,3":
            switch cameraLabel {
            case "0.5x": return 2.0
            case "1x", "2x", "3x", "前置": return 4.3
            default: return 4.3
            }
        // iPhone 13/13 mini
        case "iPhone14,4", "iPhone14,5":
            switch cameraLabel {
            case "0.5x": return 2.0
            case "1x", "前置": return 4.3
            default: return 4.3
            }
        // iPhone 12 Pro/Pro Max
        case "iPhone13,3", "iPhone13,4":
            switch cameraLabel {
            case "0.5x": return 2.0
            case "1x", "2x", "前置": return 4.3
            default: return 4.3
            }
        // iPhone 12/12 mini
        case "iPhone13,1", "iPhone13,2":
            switch cameraLabel {
            case "0.5x": return 2.0
            case "1x", "前置": return 4.3
            default: return 4.3
            }
        // iPhone 11 Pro/Pro Max
        case "iPhone12,3", "iPhone12,5":
            switch cameraLabel {
            case "0.5x": return 2.0
            case "1x", "2x", "前置": return 4.3
            default: return 4.3
            }
        // iPhone 11
        case "iPhone12,1":
            switch cameraLabel {
            case "0.5x": return 2.0
            case "1x", "前置": return 4.3
            default: return 4.3
            }
        // iPhone SE (2nd/3rd gen)
        case "iPhone12,8", "iPhone14,6":
            switch cameraLabel {
            case "1x", "前置": return 3.0
            default: return 3.0
            }
        // 其他/未知
        default:
            switch cameraLabel {
            case "0.5x": return 2.0
            case "1x", "2x", "3x", "前置": return 4.3
            default: return 4.3
            }
        }
    }

    // 低功耗模式适配
    func applyLowPowerModeIfNeeded() {
        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            // 降低帧率
            if let device = (captureSession?.inputs.first as? AVCaptureDeviceInput)?.device {
                do {
                    try device.lockForConfiguration()
                    device.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: 20)
                    device.unlockForConfiguration()
                } catch {}
            }
            // 可选：关闭高功耗滤镜
            // ...
        } else {
            if let device = (captureSession?.inputs.first as? AVCaptureDeviceInput)?.device {
                do {
                    try device.lockForConfiguration()
                    device.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: 30)
                    device.unlockForConfiguration()
                } catch {}
            }
        }
    }
    


    // 低端机型判断
    func isLowEndDevice() -> Bool {
        let lowEndModels = ["iPhone12,8", "iPhone14,6", "iPhone10,1", "iPhone10,4", "iPhone9,1", "iPhone9,3", "iPhone8,1", "iPhone7,2"]
        return lowEndModels.contains(UIDevice.current.modelIdentifier)
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
        let catPath = (sceneGuideRoot! as NSString).appendingPathComponent(name)
        sceneImagesInCategory = (try? FileManager.default.contentsOfDirectory(atPath: catPath).filter { $0.lowercased().hasSuffix(".jpg") || $0.lowercased().hasSuffix(".png") }) ?? []
        sceneImageCollectionView?.reloadData()
        // selectSceneCategory里加：
        print("sceneImagesInCategory:", sceneImagesInCategory)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView.tag == 4001 {
            return displaySceneCategories.count
        } else if collectionView.tag == 4002 {
            return displaySceneImages.count
        }
        return 0
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
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
                let catPath = (sceneGuideRoot! as NSString).appendingPathComponent(currentSceneCategory ?? "")
                let imgPath = (catPath as NSString).appendingPathComponent(name)
                if let img = UIImage(contentsOfFile: imgPath) {
                    cell.imageView.image = img
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

    @objc func dismissParamManager() {
        // 移除参数面板弹窗和蒙层
        self.view.viewWithTag(9998)?.removeFromSuperview()
        self.view.viewWithTag(9999)?.removeFromSuperview()
        // 更新按钮状态
        updateButtonStates()
    }

    @objc func openSceneGuide() {
        isSceneGuideVisible.toggle()
        sceneCategoryCollectionView?.isHidden = !isSceneGuideVisible
        sceneImageCollectionView?.isHidden = !isSceneGuideVisible
        if isSceneGuideVisible {
            sceneCategoryCollectionView?.reloadData()
            sceneImageCollectionView?.reloadData()
        }
        isFilterPanelVisible = false
        filterPanelView?.isHidden = true
        dismissParamManager()
        isContrastVisible = false
        isSaturationVisible = false
        isTemperatureVisible = false
        isExposureVisible = false
        updateButtonStates()
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
            print("当前场景：\(folders)")
            sceneCategories = folders
            sceneCategoryCollectionView?.reloadData()
            print("reloadData called")
        } catch {
            print("加载场景分类失败: \(error)")
        }
    }

    func loadSceneImages(for category: String) {
        let dir = (sceneGuideRoot! as NSString).appendingPathComponent(category)
        do {
            let items = try FileManager.default.contentsOfDirectory(atPath: dir)
            let images = items.filter { $0.lowercased().hasSuffix(".jpg") || $0.lowercased().hasSuffix(".jpeg") || $0.lowercased().hasSuffix(".png") }
            sceneImagesInCategory = images
            sceneImageCollectionView?.reloadData()
        } catch {
            print("加载场景图片失败: \(error)")
        }
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
        return CGRect(x: defaultRect.origin.x, y: defaultRect.origin.y + defaultRect.height/2 - 3, width: defaultRect.width, height: 6)
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
            let livePhotoView = PHLivePhotoView(frame: view.bounds)
            livePhotoView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            livePhotoView.contentMode = .scaleAspectFit
            view.addSubview(livePhotoView)
            PHImageManager.default().requestLivePhoto(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: nil) { livePhoto, _ in
                livePhotoView.livePhoto = livePhoto
                livePhotoView.startPlayback(with: .full)
            }
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

extension UIDevice {
    var modelIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}

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
}
// ... existing code ...
// 5. 修改 collectionView(_:didSelectItemAt:) 图片cell点击逻辑

// ... existing code ...
