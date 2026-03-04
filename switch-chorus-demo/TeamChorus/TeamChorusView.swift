//
//  TeamChorusView.swift
//  switch-chorus-demo
//
//  组队合唱页面 - 视图层
//  负责所有 UI 组件的定义和布局
//

import UIKit

// MARK: - 颜色配置
struct AppColors {
    static let bgPage = UIColor(hex: "#FAFAF9")
    static let bgElevated = UIColor.white
    static let bgCard = UIColor(hex: "#F1F1F1")
    static let accentTerracotta = UIColor(hex: "#EA580C")
    static let textPrimary = UIColor(hex: "#292524")
    static let textSecondary = UIColor(hex: "#78716C")
    static let textTertiary = UIColor(hex: "#A8A29E")
    static let textOnAccent = UIColor.white
    static let borderSubtle = UIColor(hex: "#E7E5E4")
    static let borderStrong = UIColor(hex: "#D6D3D1")
}

// MARK: - 主视图
class TeamChorusView: UIView {

    // MARK: - 回调闭包
    var onBackButtonTapped: (() -> Void)?
    var onMicButtonTapped: (() -> Void)?
    var onPickSongButtonTapped: (() -> Void)?
    var onMicUpButtonTapped: (() -> Void)?
    var onLeaveButtonTapped: (() -> Void)?

    // MARK: - UI 组件

    /// 顶部导航栏
    let headerView = UIView()

    /// 返回按钮
    let backButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let image = UIImage(systemName: "chevron.left", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = AppColors.textPrimary
        return button
    }()

    /// 房间标题
    let roomTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "组队合唱"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = AppColors.textPrimary
        label.textAlignment = .center
        return label
    }()

    /// 播放器区域
    let playerSectionView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 20
        view.clipsToBounds = true
        return view
    }()

    /// 播放器渐变背景
    let playerGradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor(hex: "#EA580C").cgColor,
            UIColor(hex: "#D97706").cgColor
        ]
        layer.startPoint = CGPoint(x: 0, y: 0)
        layer.endPoint = CGPoint(x: 1, y: 1)
        return layer
    }()

    /// 区域标题
    let sectionTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "合唱队伍"
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = AppColors.textPrimary
        return label
    }()

    /// 用户列表容器
    let userListContainerView = UIView()

    /// 左侧用户列
    let leftColumnView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.bgCard
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = AppColors.borderSubtle.cgColor
        return view
    }()

    /// 右侧用户列
    let rightColumnView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#FEF3EC")
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = AppColors.borderSubtle.cgColor
        return view
    }()

    /// 左侧"待上麦"提示标签
    let leftWaitingLabel: UILabel = {
        let label = UILabel()
        label.text = "待上麦"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = AppColors.textTertiary
        label.textAlignment = .center
        return label
    }()

    /// 右侧"待上麦"提示标签
    let rightWaitingLabel: UILabel = {
        let label = UILabel()
        label.text = "待上麦"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = AppColors.textTertiary
        label.textAlignment = .center
        return label
    }()

    /// 左侧队伍头像（TeamA）
    let leftTeamImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "teamA")
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 5
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = AppColors.borderStrong.cgColor
        imageView.backgroundColor = AppColors.bgElevated
        imageView.isHidden = true
        return imageView
    }()

    /// 右侧队伍头像（TeamB）
    let rightTeamImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "teamB")
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 5
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = AppColors.borderStrong.cgColor
        imageView.backgroundColor = AppColors.bgElevated
        imageView.isHidden = true
        return imageView
    }()

    /// 底部控制栏
    let bottomBarView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.bgElevated
        view.layer.cornerRadius = 20
        return view
    }()

    /// 麦克风按钮
    let micButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = AppColors.accentTerracotta
        button.layer.cornerRadius = 12
        let micOnImage = UIImage(systemName: "mic.fill")?.withRenderingMode(.alwaysTemplate)
        button.setImage(micOnImage, for: .normal)
        let micOffImage = UIImage(systemName: "mic.slash.fill")?.withRenderingMode(.alwaysTemplate)
        button.setImage(micOffImage, for: .selected)
        button.tintColor = AppColors.textOnAccent
        return button
    }()

    /// 点歌按钮
    let pickSongButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("点歌", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.setTitleColor(AppColors.accentTerracotta, for: .normal)
        button.setTitleColor(AppColors.textTertiary, for: .disabled)
        button.backgroundColor = AppColors.bgCard
        button.layer.cornerRadius = 12
        button.isEnabled = false
        return button
    }()

    /// 上麦按钮
    let micUpButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("上麦", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.setTitleColor(AppColors.accentTerracotta, for: .normal)
        button.backgroundColor = AppColors.bgCard
        button.layer.cornerRadius = 12
        return button
    }()

    /// 离开按钮
    let leaveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("离开", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.setTitleColor(AppColors.textOnAccent, for: .normal)
        button.backgroundColor = UIColor(hex: "#DC2626")
        button.layer.cornerRadius = 22
        return button
    }()

    // MARK: - 初始化

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupActions()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupActions()
    }

    // MARK: - UI 布局

    private func setupUI() {
        backgroundColor = AppColors.bgPage

        // 禁用 autoresizing（UIView 类型）
        let views: [UIView] = [
            headerView, backButton, roomTitleLabel, playerSectionView,
            sectionTitleLabel, userListContainerView, leftColumnView, rightColumnView,
            leftWaitingLabel, rightWaitingLabel, leftTeamImageView, rightTeamImageView,
            bottomBarView, micButton, pickSongButton, micUpButton, leaveButton
        ]
        views.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        // 添加子视图
        addSubview(headerView)
        addSubview(playerSectionView)
        addSubview(sectionTitleLabel)
        addSubview(userListContainerView)
        addSubview(bottomBarView)

        headerView.addSubview(backButton)
        headerView.addSubview(roomTitleLabel)

        playerSectionView.layer.addSublayer(playerGradientLayer)

        userListContainerView.addSubview(leftColumnView)
        userListContainerView.addSubview(rightColumnView)

        leftColumnView.addSubview(leftWaitingLabel)
        leftColumnView.addSubview(leftTeamImageView)

        rightColumnView.addSubview(rightWaitingLabel)
        rightColumnView.addSubview(rightTeamImageView)

        bottomBarView.addSubview(micButton)
        bottomBarView.addSubview(pickSongButton)
        bottomBarView.addSubview(micUpButton)
        bottomBarView.addSubview(leaveButton)

        // 设置约束
        NSLayoutConstraint.activate([
            // 顶部导航栏
            headerView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 56),

            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            roomTitleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            roomTitleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            // 播放器区域
            playerSectionView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 8),
            playerSectionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            playerSectionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            playerSectionView.heightAnchor.constraint(equalToConstant: 180),

            // 区域标题
            sectionTitleLabel.topAnchor.constraint(equalTo: playerSectionView.bottomAnchor, constant: 16),
            sectionTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),

            // 用户列表容器
            userListContainerView.topAnchor.constraint(equalTo: sectionTitleLabel.bottomAnchor, constant: 12),
            userListContainerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            userListContainerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            userListContainerView.bottomAnchor.constraint(equalTo: bottomBarView.topAnchor, constant: -12),

            // 左侧列
            leftColumnView.topAnchor.constraint(equalTo: userListContainerView.topAnchor),
            leftColumnView.leadingAnchor.constraint(equalTo: userListContainerView.leadingAnchor),
            leftColumnView.bottomAnchor.constraint(equalTo: userListContainerView.bottomAnchor),
            leftColumnView.widthAnchor.constraint(equalTo: userListContainerView.widthAnchor, multiplier: 0.5),

            // 右侧列
            rightColumnView.topAnchor.constraint(equalTo: userListContainerView.topAnchor),
            rightColumnView.trailingAnchor.constraint(equalTo: userListContainerView.trailingAnchor),
            rightColumnView.bottomAnchor.constraint(equalTo: userListContainerView.bottomAnchor),
            rightColumnView.widthAnchor.constraint(equalTo: userListContainerView.widthAnchor, multiplier: 0.5),

            // 左侧待上麦标签
            leftWaitingLabel.centerXAnchor.constraint(equalTo: leftColumnView.centerXAnchor),
            leftWaitingLabel.centerYAnchor.constraint(equalTo: leftColumnView.centerYAnchor),

            // 右侧待上麦标签
            rightWaitingLabel.centerXAnchor.constraint(equalTo: rightColumnView.centerXAnchor),
            rightWaitingLabel.centerYAnchor.constraint(equalTo: rightColumnView.centerYAnchor),

            // 左侧队伍头像
            leftTeamImageView.centerXAnchor.constraint(equalTo: leftColumnView.centerXAnchor),
            leftTeamImageView.centerYAnchor.constraint(equalTo: leftColumnView.centerYAnchor),
            leftTeamImageView.widthAnchor.constraint(equalToConstant: 60),
            leftTeamImageView.heightAnchor.constraint(equalToConstant: 60),

            // 右侧队伍头像
            rightTeamImageView.centerXAnchor.constraint(equalTo: rightColumnView.centerXAnchor),
            rightTeamImageView.centerYAnchor.constraint(equalTo: rightColumnView.centerYAnchor),
            rightTeamImageView.widthAnchor.constraint(equalToConstant: 60),
            rightTeamImageView.heightAnchor.constraint(equalToConstant: 60),

            // 底部控制栏
            bottomBarView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            bottomBarView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            bottomBarView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -8),
            bottomBarView.heightAnchor.constraint(equalToConstant: 76),

            // 麦克风按钮
            micButton.leadingAnchor.constraint(equalTo: bottomBarView.leadingAnchor, constant: 24),
            micButton.centerYAnchor.constraint(equalTo: bottomBarView.centerYAnchor),
            micButton.widthAnchor.constraint(equalToConstant: 44),
            micButton.heightAnchor.constraint(equalToConstant: 44),

            // 点歌按钮
            pickSongButton.leadingAnchor.constraint(equalTo: micButton.trailingAnchor, constant: 12),
            pickSongButton.centerYAnchor.constraint(equalTo: bottomBarView.centerYAnchor),
            pickSongButton.widthAnchor.constraint(equalToConstant: 64),
            pickSongButton.heightAnchor.constraint(equalToConstant: 44),

            // 上麦按钮
            micUpButton.leadingAnchor.constraint(equalTo: pickSongButton.trailingAnchor, constant: 12),
            micUpButton.centerYAnchor.constraint(equalTo: bottomBarView.centerYAnchor),
            micUpButton.widthAnchor.constraint(equalToConstant: 64),
            micUpButton.heightAnchor.constraint(equalToConstant: 44),

            // 离开按钮
            leaveButton.trailingAnchor.constraint(equalTo: bottomBarView.trailingAnchor, constant: -24),
            leaveButton.centerYAnchor.constraint(equalTo: bottomBarView.centerYAnchor),
            leaveButton.widthAnchor.constraint(equalToConstant: 70),
            leaveButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // 更新渐变层 frame
        playerGradientLayer.frame = playerSectionView.bounds
    }

    // MARK: - 按钮事件绑定

    private func setupActions() {
        backButton.addTarget(self, action: #selector(backButtonAction), for: .touchUpInside)
        micButton.addTarget(self, action: #selector(micButtonAction), for: .touchUpInside)
        pickSongButton.addTarget(self, action: #selector(pickSongButtonAction), for: .touchUpInside)
        micUpButton.addTarget(self, action: #selector(micUpButtonAction), for: .touchUpInside)
        leaveButton.addTarget(self, action: #selector(leaveButtonAction), for: .touchUpInside)
    }

    @objc private func backButtonAction() { onBackButtonTapped?() }
    @objc private func micButtonAction() { onMicButtonTapped?() }
    @objc private func pickSongButtonAction() { onPickSongButtonTapped?() }
    @objc private func micUpButtonAction() { onMicUpButtonTapped?() }
    @objc private func leaveButtonAction() { onLeaveButtonTapped?() }

    // MARK: - UI 更新方法

    /// 更新上麦按钮 UI
    func updateMicUpButtonUI(isPublishing: Bool) {
        if isPublishing {
            micUpButton.setTitle("下麦", for: .normal)
            micUpButton.backgroundColor = AppColors.accentTerracotta
            micUpButton.setTitleColor(AppColors.textOnAccent, for: .normal)
        } else {
            micUpButton.setTitle("上麦", for: .normal)
            micUpButton.backgroundColor = AppColors.bgCard
            micUpButton.setTitleColor(AppColors.accentTerracotta, for: .normal)
        }
    }

    /// 更新麦克风按钮 UI
    func updateMicButtonUI(isMuted: Bool) {
        micButton.isSelected = isMuted
    }

    /// 显示 TeamA 头像
    func showTeamA() {
        leftWaitingLabel.isHidden = true
        leftTeamImageView.isHidden = false
        leftTeamImageView.image = UIImage(named: "teamA")
    }

    /// 显示 TeamB 头像
    func showTeamB() {
        rightWaitingLabel.isHidden = true
        rightTeamImageView.isHidden = false
        rightTeamImageView.image = UIImage(named: "teamB")
    }

    /// 隐藏 TeamA 头像
    func hideTeamA() {
        leftTeamImageView.isHidden = true
        leftWaitingLabel.isHidden = false
    }

    /// 隐藏 TeamB 头像
    func hideTeamB() {
        rightTeamImageView.isHidden = true
        rightWaitingLabel.isHidden = false
    }

    /// 隐藏所有队伍头像（恢复初始状态）
    func hideAllTeamAvatars() {
        leftTeamImageView.isHidden = true
        rightTeamImageView.isHidden = true
        leftWaitingLabel.isHidden = false
        rightWaitingLabel.isHidden = false
    }

    /// 设置点歌按钮是否可用
    func setPickSongButtonEnabled(_ enabled: Bool) {
        pickSongButton.isEnabled = enabled
    }
}
