// 🎯 滑动条格式统一修复代码
// 将此代码添加到您的 CameraViewController 中

// MARK: - 滑动条格式统一修复方法

extension CameraViewController {
    
    /// 统一所有滑动条格式，确保都有加减按钮
    func unifySliderFormats() {
        print("🎨 开始统一滑动条格式...")
        
        // 1. 确保容器存在
        ensureContainersExist()
        
        // 2. 创建统一格式的滑动条
        createUnifiedContrastSlider()
        createUnifiedSaturationSlider()
        createUnifiedTemperatureSlider()  // 重新创建以确保一致性
        createUnifiedExposureSlider()
        
        print("🎨 滑动条格式统一完成！")
        print("   ✅ 对比度：UISlider + 加减按钮 + 数值标签")
        print("   ✅ 饱和度：UISlider + 加减按钮 + 数值标签") 
        print("   ✅ 色温：UISlider + 加减按钮 + 数值标签")
        print("   ✅ 曝光：UISlider + 加减按钮 + 数值标签")
    }
    
    /// 确保所有容器都存在
    private func ensureContainersExist() {
        if contrastContainer == nil {
            contrastContainer = makeAppleBlurView(style: .systemMaterialDark)
            contrastContainer?.isHidden = true
            view.addSubview(contrastContainer!)
            setupContainerConstraints(container: contrastContainer!, yOffset: 60)
        }
        
        if saturationContainer == nil {
            saturationContainer = makeAppleBlurView(style: .systemMaterialDark)
            saturationContainer?.isHidden = true
            view.addSubview(saturationContainer!)
            setupContainerConstraints(container: saturationContainer!, yOffset: 60)
        }
        
        if temperatureContainer == nil {
            temperatureContainer = makeAppleBlurView(style: .systemMaterialDark)
            temperatureContainer?.isHidden = true
            view.addSubview(temperatureContainer!)
            setupContainerConstraints(container: temperatureContainer!, yOffset: 60)
        }
        
        if exposureContainer == nil {
            exposureContainer = makeAppleBlurView(style: .systemMaterialDark)
            exposureContainer?.isHidden = true
            view.addSubview(exposureContainer!)
            setupContainerConstraints(container: exposureContainer!, yOffset: 60)
        }
    }
    
    /// 设置容器约束
    private func setupContainerConstraints(container: UIView, yOffset: CGFloat) {
        guard let filterButton = filterButton else { return }
        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            container.topAnchor.constraint(equalTo: filterButton.bottomAnchor, constant: yOffset),
            container.widthAnchor.constraint(equalToConstant: 200),
            container.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    /// 创建统一格式的对比度滑动条
    private func createUnifiedContrastSlider() {
        guard let container = contrastContainer else { return }
        
        // 清理旧元素
        contrastSlider?.removeFromSuperview()
        contrastMinusBtn?.removeFromSuperview()
        contrastPlusBtn?.removeFromSuperview()
        contrastValueLabel?.removeFromSuperview()
        
        // 创建滑动条
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 100
        slider.value = 50
        slider.addTarget(self, action: #selector(contrastChanged), for: .valueChanged)
        slider.translatesAutoresizingMaskIntoConstraints = false
        
        // 设置渐变轨道
        let track = sliderGradientImage(colors: [.black, .white])
        slider.setMinimumTrackImage(track, for: .normal)
        slider.setMaximumTrackImage(track, for: .normal)
        slider.setThumbImage(sliderThumbImage(color: .darkGray), for: .normal)
        slider.setThumbImage(sliderThumbImage(color: .darkGray, radius: 16), for: .highlighted)
        
        // 创建数值标签
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        label.text = "50"
        
        // 创建减号按钮
        let minusBtn = createStandardButton(title: "-", action: #selector(contrastMinusTapped))
        minusBtn.addTarget(self, action: #selector(contrastMinusDown), for: .touchDown)
        minusBtn.addTarget(self, action: #selector(contrastMinusUp), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
        
        // 创建加号按钮
        let plusBtn = createStandardButton(title: "+", action: #selector(contrastPlusTapped))
        plusBtn.addTarget(self, action: #selector(contrastPlusDown), for: .touchDown)
        plusBtn.addTarget(self, action: #selector(contrastPlusUp), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
        
        // 添加到容器
        let contentView = (container as? UIVisualEffectView)?.contentView ?? container
        contentView.addSubview(slider)
        contentView.addSubview(label)
        contentView.addSubview(minusBtn)
        contentView.addSubview(plusBtn)
        
        // 设置约束
        setupSliderConstraints(container: container, slider: slider, label: label, minusBtn: minusBtn, plusBtn: plusBtn)
        
        // 保存引用
        self.contrastSlider = slider
        self.contrastValueLabel = label
        self.contrastMinusBtn = minusBtn
        self.contrastPlusBtn = plusBtn
    }
    
    /// 创建统一格式的饱和度滑动条
    private func createUnifiedSaturationSlider() {
        guard let container = saturationContainer else { return }
        
        // 清理旧元素
        saturationSlider?.removeFromSuperview()
        saturationMinusBtn?.removeFromSuperview()
        saturationPlusBtn?.removeFromSuperview()
        saturationValueLabel?.removeFromSuperview()
        
        // 创建滑动条
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 100
        slider.value = 50
        slider.addTarget(self, action: #selector(saturationChanged), for: .valueChanged)
        slider.translatesAutoresizingMaskIntoConstraints = false
        
        // 设置渐变轨道
        let track = sliderGradientImage(colors: [.gray, .systemPink])
        slider.setMinimumTrackImage(track, for: .normal)
        slider.setMaximumTrackImage(track, for: .normal)
        slider.setThumbImage(sliderThumbImage(color: .systemPink), for: .normal)
        slider.setThumbImage(sliderThumbImage(color: .systemPink, radius: 16), for: .highlighted)
        
        // 创建数值标签
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        label.text = "50"
        
        // 创建减号按钮
        let minusBtn = createStandardButton(title: "-", action: #selector(saturationMinusTapped))
        minusBtn.addTarget(self, action: #selector(satMinusDown), for: .touchDown)
        minusBtn.addTarget(self, action: #selector(satMinusUp), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
        
        // 创建加号按钮
        let plusBtn = createStandardButton(title: "+", action: #selector(saturationPlusTapped))
        plusBtn.addTarget(self, action: #selector(satPlusDown), for: .touchDown)
        plusBtn.addTarget(self, action: #selector(satPlusUp), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
        
        // 添加到容器
        let contentView = (container as? UIVisualEffectView)?.contentView ?? container
        contentView.addSubview(slider)
        contentView.addSubview(label)
        contentView.addSubview(minusBtn)
        contentView.addSubview(plusBtn)
        
        // 设置约束
        setupSliderConstraints(container: container, slider: slider, label: label, minusBtn: minusBtn, plusBtn: plusBtn)
        
        // 保存引用
        self.saturationSlider = slider
        self.saturationValueLabel = label
        self.saturationMinusBtn = minusBtn
        self.saturationPlusBtn = plusBtn
    }
    
    /// 创建统一格式的色温滑动条
    private func createUnifiedTemperatureSlider() {
        guard let container = temperatureContainer else { return }
        
        // 清理旧元素
        temperatureSlider?.removeFromSuperview()
        temperatureMinusBtn?.removeFromSuperview()
        temperaturePlusBtn?.removeFromSuperview()
        temperatureValueLabel?.removeFromSuperview()
        
        // 创建滑动条
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 100
        slider.value = 50
        slider.addTarget(self, action: #selector(temperatureChanged), for: .valueChanged)
        slider.translatesAutoresizingMaskIntoConstraints = false
        
        // 设置渐变轨道
        let track = sliderGradientImage(colors: [.systemBlue, .systemOrange])
        slider.setMinimumTrackImage(track, for: .normal)
        slider.setMaximumTrackImage(track, for: .normal)
        slider.setThumbImage(sliderThumbImage(color: .systemOrange), for: .normal)
        slider.setThumbImage(sliderThumbImage(color: .systemOrange, radius: 16), for: .highlighted)
        
        // 创建数值标签
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        label.text = "50"
        
        // 创建减号按钮
        let minusBtn = createStandardButton(title: "-", action: #selector(temperatureMinusTapped))
        minusBtn.addTarget(self, action: #selector(tempMinusDown), for: .touchDown)
        minusBtn.addTarget(self, action: #selector(tempMinusUp), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
        
        // 创建加号按钮
        let plusBtn = createStandardButton(title: "+", action: #selector(temperaturePlusTapped))
        plusBtn.addTarget(self, action: #selector(tempPlusDown), for: .touchDown)
        plusBtn.addTarget(self, action: #selector(tempPlusUp), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
        
        // 添加到容器
        let contentView = (container as? UIVisualEffectView)?.contentView ?? container
        contentView.addSubview(slider)
        contentView.addSubview(label)
        contentView.addSubview(minusBtn)
        contentView.addSubview(plusBtn)
        
        // 设置约束
        setupSliderConstraints(container: container, slider: slider, label: label, minusBtn: minusBtn, plusBtn: plusBtn)
        
        // 保存引用
        self.temperatureSlider = slider
        self.temperatureValueLabel = label
        self.temperatureMinusBtn = minusBtn
        self.temperaturePlusBtn = plusBtn
    }
    
    /// 创建统一格式的曝光滑动条
    private func createUnifiedExposureSlider() {
        guard let container = exposureContainer else { return }
        
        // 清理旧元素
        exposureSlider?.removeFromSuperview()
        exposureMinusBtn?.removeFromSuperview()
        exposurePlusBtn?.removeFromSuperview()
        exposureValueLabel?.removeFromSuperview()
        
        // 创建滑动条
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 100
        slider.value = 50
        slider.addTarget(self, action: #selector(exposureChanged), for: .valueChanged)
        slider.translatesAutoresizingMaskIntoConstraints = false
        
        // 设置渐变轨道
        let track = sliderGradientImage(colors: [.black, .systemYellow])
        slider.setMinimumTrackImage(track, for: .normal)
        slider.setMaximumTrackImage(track, for: .normal)
        slider.setThumbImage(sliderThumbImage(color: .systemYellow), for: .normal)
        slider.setThumbImage(sliderThumbImage(color: .systemYellow, radius: 16), for: .highlighted)
        
        // 创建数值标签
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        label.text = "0.0"
        
        // 创建减号按钮
        let minusBtn = createStandardButton(title: "-", action: #selector(exposureMinusTapped))
        minusBtn.addTarget(self, action: #selector(exposureMinusDown), for: .touchDown)
        minusBtn.addTarget(self, action: #selector(exposureMinusUp), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
        
        // 创建加号按钮
        let plusBtn = createStandardButton(title: "+", action: #selector(exposurePlusTapped))
        plusBtn.addTarget(self, action: #selector(exposurePlusDown), for: .touchDown)
        plusBtn.addTarget(self, action: #selector(exposurePlusUp), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
        
        // 添加到容器
        let contentView = (container as? UIVisualEffectView)?.contentView ?? container
        contentView.addSubview(slider)
        contentView.addSubview(label)
        contentView.addSubview(minusBtn)
        contentView.addSubview(plusBtn)
        
        // 设置约束
        setupSliderConstraints(container: container, slider: slider, label: label, minusBtn: minusBtn, plusBtn: plusBtn)
        
        // 保存引用
        self.exposureSlider = slider
        self.exposureValueLabel = label
        self.exposureMinusBtn = minusBtn
        self.exposurePlusBtn = plusBtn
    }
    
    /// 创建标准格式的加减按钮
    private func createStandardButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        button.layer.cornerRadius = 14
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
    
    /// 设置滑动条约束布局
    private func setupSliderConstraints(container: UIView, slider: UISlider, label: UILabel, minusBtn: UIButton, plusBtn: UIButton) {
        NSLayoutConstraint.activate([
            // 减号按钮
            minusBtn.centerYAnchor.constraint(equalTo: slider.centerYAnchor),
            minusBtn.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
            minusBtn.widthAnchor.constraint(equalToConstant: 28),
            minusBtn.heightAnchor.constraint(equalToConstant: 28),
            
            // 加号按钮
            plusBtn.centerYAnchor.constraint(equalTo: slider.centerYAnchor),
            plusBtn.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -4),
            plusBtn.widthAnchor.constraint(equalToConstant: 28),
            plusBtn.heightAnchor.constraint(equalToConstant: 28),
            
            // 滑动条
            slider.leadingAnchor.constraint(equalTo: minusBtn.trailingAnchor, constant: 4),
            slider.trailingAnchor.constraint(equalTo: plusBtn.leadingAnchor, constant: -4),
            slider.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: -10),
            slider.widthAnchor.constraint(greaterThanOrEqualToConstant: 40),
            
            // 数值标签
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: 2),
            label.widthAnchor.constraint(equalTo: container.widthAnchor),
            label.heightAnchor.constraint(equalToConstant: 18)
        ])
    }
}