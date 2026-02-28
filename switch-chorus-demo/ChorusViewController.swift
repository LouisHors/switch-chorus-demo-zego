//
//  ChorusViewController.swift
//  switch-chorus-demo
//
//  合唱 Demo 主界面
//

import UIKit
import ZegoExpressEngine

class ChorusViewController: UIViewController {

    // MARK: - 从 LoginPage 传入的属性
    /// 房间 ID（从登录页传入）
    var roomID: String = ""

    /// 用户 ID（从登录页传入）
    var userID: String = ""

    // MARK: - UI 组件

    /// 本地预览视图
    private lazy var localPreviewView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    /// 远端视图容器
    private lazy var remoteContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .darkGray
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    /// 角色选择分段
    private lazy var roleSegmentedControl: UISegmentedControl = {
        let items = ["观众", "合唱者", "点歌用户"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.addTarget(self, action: #selector(roleChanged(_:)), for: .valueChanged)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()

    /// 房间 ID 输入框
    private lazy var roomIDTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "请输入房间 ID"
        textField.borderStyle = .roundedRect
        textField.text = "chorus_room_001"
        textField.textAlignment = .center
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    /// 用户 ID 输入框
    private lazy var userIDTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "请输入用户 ID"
        textField.borderStyle = .roundedRect
        textField.text = "user_\(Int.random(in: 1000...9999))"
        textField.textAlignment = .center
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    /// 登录/登出按钮
    private lazy var loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("登录房间", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(loginButtonTapped(_:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    /// 开始/停止合唱按钮
    private lazy var chorusButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("开始合唱", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(chorusButtonTapped(_:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    /// 播放控制按钮
    private lazy var playControlStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    /// 暂停/恢复按钮
    private lazy var pauseResumeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("暂停", for: .normal)
        button.backgroundColor = .systemOrange
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(pauseResumeButtonTapped(_:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    /// 停止按钮
    private lazy var stopButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("停止", for: .normal)
        button.backgroundColor = .systemRed
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(stopButtonTapped(_:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    /// 状态标签
    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.text = "未连接"
        label.textColor = .gray
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 进度标签
    private lazy var progressLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00 / 00:00"
        label.textColor = .white
        label.textAlignment = .center
        label.font = .monospacedDigitSystemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 远端渲染视图字典 [streamID: ZegoCanvas]
    private var remoteViews: [String: UIView] = [:]

    // MARK: - 属性

    private let manager = ZegoChorusManager.shared
    private var currentRole: ChorusRole = .audience
    private var isChorusing: Bool = false

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupManager()

        // 如果从 LoginPage 传入了 roomID 和 userID，自动登录
        if !roomID.isEmpty && !userID.isEmpty {
            autoLoginFromLoginPage()
        }
    }

    /// 从 LoginPage 自动登录
    private func autoLoginFromLoginPage() {
        // 更新输入框显示
        roomIDTextField.text = roomID
        userIDTextField.text = userID

        // 自动登录房间
        manager.loginRoom(
            roomID: roomID,
            userID: userID,
            userName: userID,
            role: currentRole,
            token: ZegoAppConfig.token
        )

        // 隐藏登录相关控件（已从登录页登录）
        roomIDTextField.isHidden = true
        userIDTextField.isHidden = true
        loginButton.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            manager.stopPublishing()
            manager.logoutRoom()
        }
    }

    // MARK: - UI 设置

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "ZEGO 实时合唱 Demo"

        // 添加子视图
        view.addSubview(localPreviewView)
        view.addSubview(remoteContainerView)
        view.addSubview(roleSegmentedControl)
        view.addSubview(roomIDTextField)
        view.addSubview(userIDTextField)
        view.addSubview(loginButton)
        view.addSubview(chorusButton)
        view.addSubview(playControlStackView)
        view.addSubview(statusLabel)
        view.addSubview(progressLabel)

        // 播放控制按钮
        playControlStackView.addArrangedSubview(pauseResumeButton)
        playControlStackView.addArrangedSubview(stopButton)

        // 布局约束
        NSLayoutConstraint.activate([
            // 本地预览
            localPreviewView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            localPreviewView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            localPreviewView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            localPreviewView.heightAnchor.constraint(equalTo: localPreviewView.widthAnchor, multiplier: 0.75),

            // 远端容器
            remoteContainerView.topAnchor.constraint(equalTo: localPreviewView.bottomAnchor, constant: 16),
            remoteContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            remoteContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            remoteContainerView.heightAnchor.constraint(equalToConstant: 100),

            // 进度标签
            progressLabel.topAnchor.constraint(equalTo: remoteContainerView.bottomAnchor, constant: 8),
            progressLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // 角色选择
            roleSegmentedControl.topAnchor.constraint(equalTo: progressLabel.bottomAnchor, constant: 16),
            roleSegmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            roleSegmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // 房间 ID
            roomIDTextField.topAnchor.constraint(equalTo: roleSegmentedControl.bottomAnchor, constant: 16),
            roomIDTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            roomIDTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            roomIDTextField.heightAnchor.constraint(equalToConstant: 44),

            // 用户 ID
            userIDTextField.topAnchor.constraint(equalTo: roomIDTextField.bottomAnchor, constant: 12),
            userIDTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            userIDTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            userIDTextField.heightAnchor.constraint(equalToConstant: 44),

            // 登录按钮
            loginButton.topAnchor.constraint(equalTo: userIDTextField.bottomAnchor, constant: 16),
            loginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            loginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            loginButton.heightAnchor.constraint(equalToConstant: 50),

            // 合唱按钮
            chorusButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 12),
            chorusButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            chorusButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            chorusButton.heightAnchor.constraint(equalToConstant: 50),

            // 播放控制
            playControlStackView.topAnchor.constraint(equalTo: chorusButton.bottomAnchor, constant: 12),
            playControlStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            playControlStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            playControlStackView.heightAnchor.constraint(equalToConstant: 44),

            // 状态标签
            statusLabel.topAnchor.constraint(equalTo: playControlStackView.bottomAnchor, constant: 16),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])

        // 初始状态
        chorusButton.isEnabled = false
        playControlStackView.isHidden = true
    }

    private func setupManager() {
        manager.delegate = self
        manager.createEngine()
    }

    // MARK: - 按钮事件

    @objc private func roleChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            currentRole = .audience
        case 1:
            currentRole = .anchor
        case 2:
            currentRole = .songOwner
        default:
            currentRole = .audience
        }

        // 如果已登录，需要重新登录切换角色
        if manager.isLoggedIn {
            showAlert("提示", "切换角色需要重新登录房间")
        }
    }

    @objc private func loginButtonTapped(_ sender: UIButton) {
        if manager.isLoggedIn {
            // 登出
            manager.stopPublishing()
            manager.logoutRoom()
            loginButton.setTitle("登录房间", for: .normal)
            loginButton.backgroundColor = .systemBlue
            chorusButton.isEnabled = false
            statusLabel.text = "未连接"
            statusLabel.textColor = .gray
            isChorusing = false
            chorusButton.setTitle("开始合唱", for: .normal)
            chorusButton.backgroundColor = .systemGreen
            playControlStackView.isHidden = true
        } else {
            // 登录
            guard let roomID = roomIDTextField.text, !roomID.isEmpty else {
                showAlert("错误", "请输入房间 ID")
                return
            }

            guard let userID = userIDTextField.text, !userID.isEmpty else {
                showAlert("错误", "请输入用户 ID")
                return
            }

            manager.loginRoom(
                roomID: roomID,
                userID: userID,
                userName: userID,
                role: currentRole,
                token: ZegoAppConfig.token
            )
        }
    }

    @objc private func chorusButtonTapped(_ sender: UIButton) {
        if isChorusing {
            // 停止合唱
            manager.stopPlaying()
            manager.stopPublishing()

            if currentRole == .audience {
                manager.stopPlayingMixStream()
            }

            isChorusing = false
            chorusButton.setTitle("开始合唱", for: .normal)
            chorusButton.backgroundColor = .systemGreen
            playControlStackView.isHidden = true
            statusLabel.text = "已停止合唱"
        } else {
            // 开始合唱
            startChorus()
        }
    }

    @objc private func pauseResumeButtonTapped(_ sender: UIButton) {
        if manager.mediaPlayer?.currentState() == .playing {
            manager.pausePlaying()
            pauseResumeButton.setTitle("恢复", for: .normal)
            statusLabel.text = "已暂停"
        } else {
            manager.resumePlaying()
            pauseResumeButton.setTitle("暂停", for: .normal)
            statusLabel.text = "正在合唱..."
        }
    }

    @objc private func stopButtonTapped(_ sender: UIButton) {
        manager.stopPlaying()
        manager.stopPublishing()

        isChorusing = false
        chorusButton.setTitle("开始合唱", for: .normal)
        chorusButton.backgroundColor = .systemGreen
        playControlStackView.isHidden = true
        statusLabel.text = "合唱已结束"
        progressLabel.text = "00:00 / 00:00"
    }

    // MARK: - 合唱逻辑

    private func startChorus() {
        // 配置音频
        manager.configureAudioForKaraoke()
        manager.configureAudioProcessing(enableAEC: true, enableANS: true)

        // 设置混响效果
        manager.setReverbPreset(.concertHall)

        if currentRole == .audience {
            // 观众拉混流
            manager.startPlayingMixStream()
            statusLabel.text = "正在观看合唱..."
        } else if currentRole == .songOwner {
            // 点歌用户：发起合唱
            startAsSongOwner()
        } else {
            // 合唱者：等待同步
            statusLabel.text = "等待伴奏同步..."
        }

        isChorusing = true
        chorusButton.setTitle("停止合唱", for: .normal)
        chorusButton.backgroundColor = .systemRed
        playControlStackView.isHidden = false
    }

    private func startAsSongOwner() {
        // 初始化混流任务
        // 用新方案，还要改

        // TODO: 加载本地伴奏文件
        // manager.loadMediaResource("伴奏文件路径")

        // 获取 NTP 时间，约定 3 秒后开始播放
        let ntpTime = manager.getNetworkTimestamp()
        let startTime = ntpTime + ChorusConstants.playDelay

        // 发送播放控制消息
        manager.sendPlayControlMessage(
            behavior: .play,
            startTime: startTime,
            resourceID: "test_resource_id"
        )

        // 定时播放
        manager.startInFuture(startTime)

        statusLabel.text = "合唱即将开始..."

        // 3秒后更新状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.statusLabel.text = "正在合唱..."
        }
    }

    // MARK: - 辅助方法

    private func showAlert(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }

    private func formatTime(_ milliseconds: UInt64) -> String {
        let totalSeconds = Int(milliseconds / 1000)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func updateProgress(_ progress: UInt64, duration: UInt64) {
        let progressStr = formatTime(progress)
        let durationStr = formatTime(duration)
        progressLabel.text = "\(progressStr) / \(durationStr)"
    }
}

// MARK: - ZegoChorusManagerDelegate
extension ChorusViewController: ZegoChorusManagerDelegate {

    func chorusManager(_ manager: ZegoChorusManager, roomStateUpdate state: ZegoRoomState, errorCode: Int, roomID: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if state == .connected && errorCode == 0 {
                self.loginButton.setTitle("登出房间", for: .normal)
                self.loginButton.backgroundColor = .systemRed
                self.chorusButton.isEnabled = true
                self.statusLabel.text = "已连接到房间: \(roomID)"
                self.statusLabel.textColor = .systemGreen
            } else if state == .disconnected {
                self.statusLabel.text = "连接断开"
                self.statusLabel.textColor = .systemRed
            } else if errorCode != 0 {
                self.statusLabel.text = "连接失败: \(errorCode)"
                self.statusLabel.textColor = .systemRed
            }
        }
    }

    func chorusManager(_ manager: ZegoChorusManager, userJoined userID: String, streamID: String) {
        DispatchQueue.main.async {
            print("[ChorusViewController] 用户加入: \(userID), 流ID: \(streamID)")

            // 如果是合唱者角色，自动拉流
            if manager.role != .audience {
                manager.startPlayingStream(streamID)
            }
        }
    }

    func chorusManager(_ manager: ZegoChorusManager, userLeft streamID: String) {
        DispatchQueue.main.async { [weak self] in
            print("[ChorusViewController] 用户离开: \(streamID)")
            manager.stopPlayingStream(streamID)

            // 移除远端视图
            self?.remoteViews[streamID]?.removeFromSuperview()
            self?.remoteViews.removeValue(forKey: streamID)
        }
    }

    func chorusManager(_ manager: ZegoChorusManager, receivedSEI data: Data, streamID: String) {
        guard let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }

        // 处理 SEI 消息
        if manager.role == .anchor {
            // 合唱者：处理伴奏同步和进度对齐
            handleSEIForAnchor(dict)
        } else if manager.role == .audience {
            // 观众：同步歌词进度
            handleSEIForAudience(dict, streamID: streamID)
        }
    }

    private func handleSEIForAnchor(_ dict: [String: Any]) {
        guard let progress = dict[SEIMessageKey.progress] as? Int64,
              let pointTime = dict[SEIMessageKey.pointTime] as? Int64 else {
            return
        }

        // 计算延迟并同步伴奏
        let currentNtpTime = manager.getNetworkTimestamp()
        let currentProgress = Int64(manager.currentProgress)

        let latency = currentNtpTime - pointTime - (currentProgress - progress)

        if latency > ChorusConstants.accompanySyncThreshold {
            manager.conformAccompanyWithLatency(latency)
        }
    }

    private func handleSEIForAudience(_ dict: [String: Any], streamID: String) {
        // 只处理混流的 SEI
        guard streamID == manager.mixStreamID else { return }

        guard let role = dict[SEIMessageKey.role] as? Int,
              role == ChorusRole.songOwner.rawValue,
              let progress = dict[SEIMessageKey.progress] as? Int64,
              let total = dict[SEIMessageKey.totalTime] as? Int64 else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.updateProgress(UInt64(progress), duration: UInt64(total))
        }
    }

    func chorusManager(_ manager: ZegoChorusManager, mediaPlayerProgress progress: UInt64, duration: UInt64) {
        DispatchQueue.main.async { [weak self] in
            self?.updateProgress(progress, duration: duration)
        }
    }

    func chorusManager(_ manager: ZegoChorusManager, mixerTaskResult errorCode: Int) {
        DispatchQueue.main.async {
            if errorCode == 0 {
                print("[ChorusViewController] 混流任务成功")
            } else {
                print("[ChorusViewController] 混流任务失败: \(errorCode)")
            }
        }
    }

    func chorusManager(_ manager: ZegoChorusManager, remoteStreamAdded streams: [ZegoStream]) {
        DispatchQueue.main.async {
            for stream in streams {
                // 观众自动拉混流
                if manager.role == .audience && stream.streamID == manager.mixStreamID {
                    manager.startPlayingMixStream()
                }
            }
        }
    }

    func chorusManager(_ manager: ZegoChorusManager, remoteStreamDeleted streams: [ZegoStream]) {
        for stream in streams {
            manager.stopPlayingStream(stream.streamID)
        }
    }
}
