import UIKit

class ContentView: UIViewController {

    // MARK: - Properties
    private var filterContrastButton: UIButton?
    private var filterSaturationButton: UIButton?
    private var temperatureButton: UIButton?
    private var filterPanelStack: UIStackView?
    var exposureValueLabel: UILabel?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - Setup UI
    private func setupUI() {
        print("[启动优化] 开始创建UI组件")
        // 1. 初始化滤镜功能按钮
        filterContrastButton = UIButton(type: .system)
        filterContrastButton.setTitle("对", for: .normal)
        filterContrastButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        filterContrastButton.setTitleColor(.white, for: .normal)
        filterContrastButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        filterContrastButton.layer.cornerRadius = 16
        filterContrastButton.addTarget(self, action: #selector(toggleContrast), for: .touchUpInside)
        
        filterSaturationButton = UIButton(type: .system)
        filterSaturationButton.setTitle("饱", for: .normal)
        filterSaturationButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        filterSaturationButton.setTitleColor(.white, for: .normal)
        filterSaturationButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        filterSaturationButton.layer.cornerRadius = 16
        filterSaturationButton.addTarget(self, action: #selector(toggleSaturation), for: .touchUpInside)
        
        temperatureButton = UIButton(type: .system)
        temperatureButton?.setTitle("温", for: .normal)
        temperatureButton?.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        temperatureButton?.setTitleColor(.white, for: .normal)
        temperatureButton?.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        temperatureButton?.layer.cornerRadius = 16
        temperatureButton?.addTarget(self, action: #selector(toggleTemperature), for: .touchUpInside)
        
        // 2. 添加到filterPanelStack
        var filterPanelButtons: [UIView] = []
        if let filterContrastButton = filterContrastButton { filterPanelButtons.append(filterContrastButton) }
        if let filterSaturationButton = filterSaturationButton { filterPanelButtons.append(filterSaturationButton) }
        if let temperatureButton = temperatureButton { filterPanelButtons.append(temperatureButton) }
        let filterPanelStack = UIStackView(arrangedSubviews: filterPanelButtons)
        filterPanelStack.axis = .horizontal
        filterPanelStack.alignment = .center
        filterPanelStack.distribution = .equalSpacing
        filterPanelStack.spacing = 16
        filterPanelStack.translatesAutoresizingMaskIntoConstraints = false
        self.filterPanelStack = filterPanelStack
        filterPanelView.addSubview(filterPanelStack)
    }

    // MARK: - Actions
    @objc private func toggleContrast() {
        // Implementation of toggleContrast
    }

    @objc private func toggleSaturation() {
        // Implementation of toggleSaturation
    }

    @objc private func toggleTemperature() {
        // Implementation of toggleTemperature
    }
} 