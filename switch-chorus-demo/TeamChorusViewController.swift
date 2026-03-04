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

    /// 流列表
    var roomStreamList: Set<ZegoStream> = []

    /// 我的队伍（A队/B队）
    var myTeam: ChorusTeam?

    /// 推流状态
    var isPublishing = false

    /// 是否能推流（基于队伍逻辑）
    /// - 0 条流 → 可以上麦（A队）
    /// - 1 条流 → 检查是否已标记 A队，可以上麦（B队）
    /// - 2 条流 → 不能上麦
    var canPublish: Bool {
        let streamCount = roomStreamList.count
        if streamCount == 0 {
            return true  // 可以作为 A队上麦
        } else if streamCount == 1 {
            // 检查已有的流是否标记了 A队
            return hasTeamAMarked()
        } else {
            return false  // 2条流，不能上麦
        }
    }

    /// 检查流列表中是否已有 A队标记
    private func hasTeamAMarked() -> Bool {
        // API 来源: ZegoExpressDefines.h:2491 - extraInfo 是非 Optional 的 NSString
        for stream in roomStreamList {
            if stream.extraInfo.contains("team:A") {
                return true
            }
        }
        return false
    }

    /// 根据当前流列表判断应该加入哪个队伍
    private func determineMyTeam() -> ChorusTeam? {
        let streamCount = roomStreamList.count
        if streamCount == 0 {
            return .teamA  // 第一个上麦的是 A队
        } else if streamCount == 1 && hasTeamAMarked() {
            return .teamB  // 已有 A队，第二个是 B队
        }
        return nil  // 不能上麦
    }
    
    
    
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

        // 配置音频参数（合唱场景）
        setupAudioConfig()

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

    // MARK: - 音频配置

    /// 配置音频参数（合唱场景）
    /// 参考: 会玩KTV单唱场景参数配置表.csv - 第14列 (iOS合唱主播)
    private func setupAudioConfig() {
        // 1. 设置音频编码配置
        // 基于 ZegoExpressEngine+Publisher.h:330
        // 参数: Low3 (OPUS), 128kbps, Stereo
        let audioConfig = ZegoAudioConfig()
        audioConfig.codecID = .low3
        audioConfig.bitrate = 128
        audioConfig.channel = .stereo
        zego.setAudioConfig(audioConfig)

        // 2. 设置音频设备模式
        // 基于 ZegoExpressEngine+Device.h:172
        // General 模式: 不使用系统回声消除，适用于 KTV 场景
        zego.setAudioDeviceMode(.general)

        // 3. 启用回声消除
        // 基于 ZegoExpressEngine+Preprocess.h:66
        zego.enableAEC(true)

        // 4. 设置回声消除模式
        // 基于 ZegoExpressEngine+Preprocess.h:93
        // Soft 模式: 音质最好，适用于音乐场景
        zego.setAECMode(.soft)

        // 5. 启用噪声抑制
        // 基于 ZegoExpressEngine+Preprocess.h:118
        zego.enableANS(true)

        // 6. 设置噪声抑制模式
        // 基于 ZegoExpressEngine+Preprocess.h:143
        // Medium 模式: 平衡音质和降噪效果
        zego.setANSMode(.medium)

        // 7. 关闭耳机回声消除
        // 基于 ZegoExpressEngine+Preprocess.h:81
        // 音乐场景需要关闭，保证音质
        zego.enableHeadphoneAEC(false)

        print("[TeamChorus] 音频配置完成 - 合唱场景")
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
    /// 参考: docs/双人轮唱的合唱场景方案.md - 同时推两路流与进度对齐配置
    @objc private func micUpButtonTapped(_ sender: UIButton) {
        // 已经在推流中，执行下麦逻辑
        if isPublishing {
            stopPublishing()
            return
        }

        // 判断能不能推流
        guard let team = determineMyTeam() else {
            print("[TeamChorus] 当前房间内麦位已饱和或队伍分配异常，无法上麦")
            return
        }

        // 开始推流
        startPublishing(team: team)
    }

    /// 开始推流
    /// - Parameter team: 队伍（A队/B队）
    private func startPublishing(team: ChorusTeam) {
        // 记录队伍
        myTeam = team

        // 生成流 ID
        let userID = ZegoAppConfig.userID
        let mainStreamID = "\(userID)_\(roomID)_chorus"  // 主路流：伴奏+人声混音
        let auxStreamID = "\(userID)_\(roomID)_voice"    // 辅路流：纯人声

        // 1. 开启主路流推流对齐能力
        // 基于 ZegoExpressEngine+Publisher.h:509
        // ZegoStreamAlignmentModeTry = 1
        zego.setStreamAlignmentProperty(1, channel: .main)

        // 2. 主路推流配置
        // 基于 ZegoExpressEngine+Publisher.h
        // ZegoPublisherConfig 没有 streamID 属性，streamID 通过 startPublishingStream 传递
        let mainConfig = ZegoPublisherConfig()
        mainConfig.forceSynchronousNetworkTime = 1  // 强制同步网络时间

        // 3. 开始推主路流
        zego.startPublishingStream(mainStreamID, config: mainConfig, channel: .main)
        print("[TeamChorus] 主路流开始推流: \(mainStreamID)")

        // 4. 开启辅路流推流对齐能力
        zego.setStreamAlignmentProperty(1, channel: .aux)

        // 5. 辅路推流配置
        let auxConfig = ZegoPublisherConfig()
        auxConfig.forceSynchronousNetworkTime = 1

        // 6. 开始推辅路流
        zego.startPublishingStream(auxStreamID, config: auxConfig, channel: .aux)
        print("[TeamChorus] 辅路流开始推流: \(auxStreamID)")

        // 7. 设置流的额外信息（标记队伍）
        // 基于 ZegoExpressEngine+Publisher.h:137
        // 格式: team:A 或 team:B
        let extraInfo = "team:\(team.rawValue)"
        zego.setStreamExtraInfo(extraInfo) { errorCode in
            if errorCode == 0 {
                print("[TeamChorus] 流额外信息设置成功: \(extraInfo)")
            } else {
                print("[TeamChorus] 流额外信息设置失败: \(errorCode)")
            }
        }

        // 8. 更新推流状态
        isPublishing = true

        // 9. 更新 UI
        updateMicUpButtonUI(isPublishing: true)
        print("[TeamChorus] 上麦成功，队伍: \(team.rawValue)")
    }

    /// 停止推流（下麦）
    private func stopPublishing() {
        // API 来源: ZegoExpressEngine+Publisher.h:109, 124
        zego.stopPublishingStream()      // 停止主通道
        zego.stopPublishingStream(.aux)  // 停止辅通道（人声复用）

        isPublishing = false
        myTeam = nil

        updateMicUpButtonUI(isPublishing: false)
        print("[TeamChorus] 下麦成功")
    }

    /// 更新上麦按钮 UI
    private func updateMicUpButtonUI(isPublishing: Bool) {
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

    /// 离开按钮点击 - 退出房间
    @objc private func leaveButtonTapped(_ sender: UIButton) {
        zego.logoutRoom()
        navigationController?.popViewController(animated: true)
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
        if updateType == .add {
            if roomStreamList.count > 2 {
                print("当前房间内已经记录过两条流，不做其他操作，可能出现了其他问题\n")
                print("")
                return
            }
            streamList.forEach { stream in
                roomStreamList.insert(stream)
            }
        }else {
            streamList.forEach { stream in
                roomStreamList.remove(stream)
            }
        }
    }
    
    func onRoomStreamExtraInfoUpdate(_ streamList: [ZegoStream], roomID: String) {
        
    }
    
    func onPlayerSyncRecvSEI(_ data: Data, streamID: String) {
        
    }
}
