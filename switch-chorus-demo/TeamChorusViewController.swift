//
//  TeamChorusViewController.swift
//  switch-chorus-demo
//
//  组队合唱页面 - 基于 Voice Chat Room-init 设计
//

import UIKit
import ZegoExpressEngine

class TeamChorusViewController: UIViewController {

    
    // MARK: - 逻辑属性
    /// zego 实例
    let zego = ZegoExpressEngine.shared()
    
    /// 当前
    
    
    // MARK: - UI 组件
    /// 顶部导航栏
    private lazy var headerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    /// 返回按钮
    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let image = UIImage(systemName: "chevron.left", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = AppColors.textPrimary
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    /// 房间标题
    private lazy var roomTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "组队合唱"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = AppColors.textPrimary
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 播放器区域
    private lazy var playerSectionView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 20
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    /// 播放器渐变背景
    private lazy var playerGradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor(hex: "#EA580C").cgColor,
            UIColor(hex: "#D97706").cgColor
        ]
        layer.startPoint = CGPoint(x: 0, y: 0)
        layer.endPoint = CGPoint(x: 1, y: 1)
        return layer
    }()

    /// 合唱队伍标题
    private lazy var sectionTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "合唱队伍"
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = AppColors.textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 用户列表容器
    private lazy var userListContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    /// 左侧用户列
    private lazy var leftColumnView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.bgCard
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = AppColors.borderSubtle.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    /// 右侧用户列
    private lazy var rightColumnView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#FEF3EC")
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = AppColors.borderSubtle.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    /// 底部控制栏
    private lazy var bottomBarView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.bgElevated
        view.layer.cornerRadius = 20
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    /// 麦克风按钮
    private lazy var micButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = AppColors.accentTerracotta
        button.layer.cornerRadius = 12
        // 正常状态：麦克风开启
        let micOnImage = UIImage(systemName: "mic.fill")?.withRenderingMode(.alwaysTemplate)
        button.setImage(micOnImage, for: .normal)
        // 选中状态：麦克风禁用
        let micOffImage = UIImage(systemName: "mic.slash.fill")?.withRenderingMode(.alwaysTemplate)
        button.setImage(micOffImage, for: .selected)
        // 图标必须是白色才能在橙色背景上显示
        button.tintColor = AppColors.textOnAccent
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    /// 点歌按钮
    private lazy var pickSongButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("点歌", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.setTitleColor(AppColors.accentTerracotta, for: .normal)
        button.backgroundColor = AppColors.bgCard
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    /// 上麦按钮
    private lazy var micUpButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("上麦", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.setTitleColor(AppColors.accentTerracotta, for: .normal)
        button.backgroundColor = AppColors.bgCard
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    /// 离开按钮
    private lazy var leaveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("离开", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.setTitleColor(AppColors.textOnAccent, for: .normal)
        button.backgroundColor = UIColor(hex: "#DC2626")
        button.layer.cornerRadius = 22
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - 属性

    var roomID: String = ""

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        zego.setEventHandler(self)
        setupUI()
        setupActions()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 更新渐变层 frame
        playerGradientLayer.frame = playerSectionView.bounds
    }

    // MARK: - UI 布局

    private func setupUI() {
        view.backgroundColor = AppColors.bgPage

        // 添加子视图
        view.addSubview(headerView)
        view.addSubview(playerSectionView)
        view.addSubview(sectionTitleLabel)
        view.addSubview(userListContainerView)
        view.addSubview(bottomBarView)

        headerView.addSubview(backButton)
        headerView.addSubview(roomTitleLabel)

        playerSectionView.layer.addSublayer(playerGradientLayer)

        userListContainerView.addSubview(leftColumnView)
        userListContainerView.addSubview(rightColumnView)

        // 设置用户头像
        setupUserAvatars()

        bottomBarView.addSubview(micButton)
        bottomBarView.addSubview(pickSongButton)
        bottomBarView.addSubview(micUpButton)
        bottomBarView.addSubview(leaveButton)

        // 布局约束
        NSLayoutConstraint.activate([
            // 顶部导航栏
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 56),

            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 24),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            roomTitleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            roomTitleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            // 播放器区域
            playerSectionView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 8),
            playerSectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            playerSectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            playerSectionView.heightAnchor.constraint(equalToConstant: 180),

            // 合唱队伍标题
            sectionTitleLabel.topAnchor.constraint(equalTo: playerSectionView.bottomAnchor, constant: 16),
            sectionTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            // 用户列表容器
            userListContainerView.topAnchor.constraint(equalTo: sectionTitleLabel.bottomAnchor, constant: 12),
            userListContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            userListContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            userListContainerView.bottomAnchor.constraint(equalTo: bottomBarView.topAnchor, constant: -16),

            // 左侧列（占容器宽度的一半）
            leftColumnView.topAnchor.constraint(equalTo: userListContainerView.topAnchor),
            leftColumnView.leadingAnchor.constraint(equalTo: userListContainerView.leadingAnchor),
            leftColumnView.bottomAnchor.constraint(equalTo: userListContainerView.bottomAnchor),
            leftColumnView.widthAnchor.constraint(equalTo: userListContainerView.widthAnchor, multiplier: 0.5),

            // 右侧列（占容器宽度的一半）
            rightColumnView.topAnchor.constraint(equalTo: userListContainerView.topAnchor),
            rightColumnView.trailingAnchor.constraint(equalTo: userListContainerView.trailingAnchor),
            rightColumnView.bottomAnchor.constraint(equalTo: userListContainerView.bottomAnchor),
            rightColumnView.widthAnchor.constraint(equalTo: userListContainerView.widthAnchor, multiplier: 0.5),

            // 底部控制栏
            bottomBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            bottomBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            bottomBarView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
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

    /// 设置用户头像（每列单个头像）
    private func setupUserAvatars() {
        // 左侧列头像
        let leftAvatar = createAvatarView()
        leftColumnView.addSubview(leftAvatar)
        NSLayoutConstraint.activate([
            leftAvatar.centerXAnchor.constraint(equalTo: leftColumnView.centerXAnchor),
            leftAvatar.centerYAnchor.constraint(equalTo: leftColumnView.centerYAnchor),
        ])

        // 右侧列头像
        let rightAvatar = createAvatarView()
        rightColumnView.addSubview(rightAvatar)
        NSLayoutConstraint.activate([
            rightAvatar.centerXAnchor.constraint(equalTo: rightColumnView.centerXAnchor),
            rightAvatar.centerYAnchor.constraint(equalTo: rightColumnView.centerYAnchor),
        ])
    }

    /// 创建单个头像视图（60x60，圆角5）
    private func createAvatarView() -> UIView {
        let avatarView = UIView()
        avatarView.backgroundColor = AppColors.bgElevated
        avatarView.layer.cornerRadius = 5
        avatarView.layer.borderWidth = 2
        avatarView.layer.borderColor = AppColors.borderStrong.cgColor
        avatarView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            avatarView.widthAnchor.constraint(equalToConstant: 60),
            avatarView.heightAnchor.constraint(equalToConstant: 60),
        ])

        return avatarView
    }

    // MARK: - 按钮事件绑定

    private func setupActions() {
        backButton.addTarget(self, action: #selector(backButtonTapped(_:)), for: .touchUpInside)
        micButton.addTarget(self, action: #selector(micButtonTapped(_:)), for: .touchUpInside)
        pickSongButton.addTarget(self, action: #selector(pickSongButtonTapped(_:)), for: .touchUpInside)
        micUpButton.addTarget(self, action: #selector(micUpButtonTapped(_:)), for: .touchUpInside)
        leaveButton.addTarget(self, action: #selector(leaveButtonTapped(_:)), for: .touchUpInside)
    }

    // MARK: - 按钮响应事件

    /// 返回按钮点击
    @objc private func backButtonTapped(_ sender: UIButton) {
        zego.logoutRoom()
        navigationController?.popViewController(animated: true)
    }

    /// 麦克风按钮点击 - 开关麦克风
    @objc private func micButtonTapped(_ sender: UIButton) {
        if !sender.isSelected {
            sender.tintColor = AppColors.accentTerracotta
        }else {
            sender.tintColor = AppColors.textOnAccent
        }
        sender.isSelected = !sender.isSelected
        // 更新图标颜色（selected 状态也需要白色才能在橙色背景上显示）
//        sender.tintColor = AppColors.textOnAccent
        
        // demo 里仅做演示，因此仅一个人唱，且为主唱，所以简单粗暴
        zego.mutePublishStreamAudio(!sender.isSelected)
        zego.mutePublishStreamAudio(!sender.isSelected, channel: .aux)
    }

    /// 点歌按钮点击 - 打开点歌弹窗
    @objc private func pickSongButtonTapped(_ sender: UIButton) {
        // TODO: 待完成
        
    }

    /// 上麦按钮点击 - 开始推流
    @objc private func micUpButtonTapped(_ sender: UIButton) {
        // 要先判断能不能推流，即当前房间有几条流，0,1 都可以推流，2 不可以推流
        
        // 上麦只推主路流，点歌以后再推第二路流
        
        // 还有 UI 变化
    }

    /// 离开按钮点击 - 退出房间
    @objc private func leaveButtonTapped(_ sender: UIButton) {

    }
}

extension TeamChorusViewController: ZegoEventHandler {
    
    func onRoomStateUpdate(_ state: ZegoRoomState, errorCode: Int32, extendedData: [AnyHashable : Any]?, roomID: String) {
        
    }
    
    func onPublisherStateUpdate(_ state: ZegoPublisherState, errorCode: Int32, extendedData: [AnyHashable : Any]?, streamID: String) {
        
    }
    
    func onPlayerStateUpdate(_ state: ZegoPlayerState, errorCode: Int32, extendedData: [AnyHashable : Any]?, streamID: String) {
        
    }
    
    func onRoomStreamUpdate(_ updateType: ZegoUpdateType, streamList: [ZegoStream], extendedData: [AnyHashable : Any]?, roomID: String) {
        
    }
    
    func onRoomStreamExtraInfoUpdate(_ streamList: [ZegoStream], roomID: String) {
        
    }
    
    func onPlayerSyncRecvSEI(_ data: Data, streamID: String) {
        
    }
}
