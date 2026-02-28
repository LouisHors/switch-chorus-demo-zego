//
//  LoginPage.swift
//  switch-chorus-demo
//
//  登录页面 - 基于 Login Frame 设计
//  实现 ZegoExpressEngine SDK 初始化和房间登录功能
//

import UIKit
import ZegoExpressEngine

// MARK: - 登录页面
class LoginPage: UIViewController {

    // MARK: - UI 组件

    /// 标题标签
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "语聊房"
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = AppColors.textPrimary
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 副标题标签
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "输入房间号，加入聊天"
        label.font = .systemFont(ofSize: 14)
        label.textColor = AppColors.textTertiary
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 房间号输入框标签
    private let inputLabel: UILabel = {
        let label = UILabel()
        label.text = "房间号"
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = AppColors.textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 房间号输入框
    private let roomInputField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "请输入房间号"
        textField.font = .systemFont(ofSize: 15)
        textField.textColor = AppColors.textPrimary
        textField.backgroundColor = AppColors.bgElevated
        textField.layer.cornerRadius = 14
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 48))
        textField.leftViewMode = .always
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    /// 进入房间按钮
    private let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("进入房间", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        button.setTitleColor(AppColors.textOnAccent, for: .normal)
        button.backgroundColor = AppColors.accentTerracotta
        button.layer.cornerRadius = 14
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    /// 输入容器
    private let inputContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    /// 加载指示器
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = AppColors.textOnAccent
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    // MARK: - 属性

    /// 是否已完成 SDK 初始化
    private var isSDKInitialized = false

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        initializeZegoSDK()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 隐藏键盘
        view.endEditing(true)
    }

    // MARK: - UI 布局

    private func setupUI() {
        view.backgroundColor = AppColors.bgPage

        // 添加子视图
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(inputContainerView)

        inputContainerView.addSubview(inputLabel)
        inputContainerView.addSubview(roomInputField)
        inputContainerView.addSubview(loginButton)

        loginButton.addSubview(loadingIndicator)

        // 设置约束
        NSLayoutConstraint.activate([
            // 标题
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 120),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // 副标题
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // 输入容器
            inputContainerView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 80),
            inputContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            inputContainerView.widthAnchor.constraint(equalToConstant: 300),

            // 输入框标签
            inputLabel.topAnchor.constraint(equalTo: inputContainerView.topAnchor),
            inputLabel.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor),
            inputLabel.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor),

            // 房间号输入框
            roomInputField.topAnchor.constraint(equalTo: inputLabel.bottomAnchor, constant: 8),
            roomInputField.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor),
            roomInputField.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor),
            roomInputField.heightAnchor.constraint(equalToConstant: 48),

            // 进入房间按钮
            loginButton.topAnchor.constraint(equalTo: roomInputField.bottomAnchor, constant: 16),
            loginButton.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor),
            loginButton.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor),
            loginButton.heightAnchor.constraint(equalToConstant: 48),
            loginButton.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor),

            // 加载指示器
            loadingIndicator.centerXAnchor.constraint(equalTo: loginButton.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: loginButton.centerYAnchor)
        ])

        // 设置输入框代理
        roomInputField.delegate = self
        roomInputField.returnKeyType = .done

        // 添加键盘事件
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    private func setupActions() {
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
    }

    // MARK: - ZEGO SDK 初始化

    /// 初始化 ZEGO Express SDK
    private func initializeZegoSDK() {

        // 1. 配置超低延迟模式（必须在创建引擎前配置）
        let engineConfig = ZegoEngineConfig()
        engineConfig.advancedConfig = [
            "ultra_low_latency": "true",
            "enforce_audio_loopback_in_sync": "true"
        ]
        ZegoExpressEngine.setEngineConfig(engineConfig)

        // 2. 创建引擎
        let profile = ZegoEngineProfile()
        profile.appID = ZegoAppConfig.appID
        profile.appSign = ZegoAppConfig.appSign
        profile.scenario = ZegoScenario.general

        ZegoExpressEngine.createEngine(with: profile, eventHandler: self)

        isSDKInitialized = true
        print("[LoginPage] ZEGO SDK 初始化完成, AppID: \(ZegoAppConfig.appID)")
    }

    // MARK: - 登录逻辑

    @objc private func loginButtonTapped() {
        guard let roomID = roomInputField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !roomID.isEmpty else {
            showAlert(title: "提示", message: "请输入房间号")
            return
        }

        // 隐藏键盘
        view.endEditing(true)

        // 开始加载状态
        setLoadingState(true)

        // 使用持久化的用户 ID
        let userID = ZegoAppConfig.userID
        let userName = "用户\(userID)"

        // 登录房间
        loginRoom(roomID: roomID, userID: userID, userName: userName)
        self.navigateToChorusPage(roomID: roomID, userID: ZegoAppConfig.userID)
    }

    /// 登录房间
    private func loginRoom(roomID: String, userID: String, userName: String) {
        guard isSDKInitialized else {
            setLoadingState(false)
            showAlert(title: "错误", message: "SDK 未初始化，请重试")
            initializeZegoSDK()
            return
        }

        let user = ZegoUser(userID: userID, userName: userName)
        let config = ZegoRoomConfig()
        config.isUserStatusNotify = true

        ZegoExpressEngine.shared().loginRoom(roomID, user: user, config: config)
        print("[LoginPage] 正在登录房间: \(roomID), 用户: \(userID)")
    }

    /// 设置加载状态
    private func setLoadingState(_ isLoading: Bool) {
        loginButton.isEnabled = !isLoading
        roomInputField.isEnabled = !isLoading

        if isLoading {
            loginButton.setTitle("", for: .normal)
            loadingIndicator.startAnimating()
        } else {
            loginButton.setTitle("进入房间", for: .normal)
            loadingIndicator.stopAnimating()
        }
    }

    /// 显示提示框
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }

    /// 跳转到合唱页面
    private func navigateToChorusPage(roomID: String, userID: String) {
        // 使用 ZegoChorusManager 进行后续管理
        initializeZegoSDK()

        let chorusVC = TeamChorusViewController()
        chorusVC.roomID = roomID

        navigationController?.pushViewController(chorusVC, animated: true)

        setLoadingState(false)
    }

    // MARK: - 键盘处理

    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

        let keyboardHeight = keyboardFrame.height
        UIView.animate(withDuration: 0.3) {
            self.view.transform = CGAffineTransform(translationX: 0, y: -keyboardHeight / 3)
        }
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        UIView.animate(withDuration: 0.3) {
            self.view.transform = .identity
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UITextFieldDelegate
extension LoginPage: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        loginButtonTapped()
        return true
    }
}

// MARK: - ZegoEventHandler
extension LoginPage: ZegoEventHandler {

    func onRoomStateUpdate(_ state: ZegoRoomState, errorCode: Int32, extendedData: [AnyHashable: Any]?, roomID: String) {
        print("[LoginPage] 房间状态更新: state=\(state.rawValue), errorCode=\(errorCode)")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            switch state {
            case .connected:
                if errorCode == 0 {
                    // 登录成功
                    print("[LoginPage] 登录房间成功")
                } else {
                    // 登录失败
                    self.setLoadingState(false)
                    self.showAlert(title: "登录失败", message: "错误码: \(errorCode)")
                }

            case .disconnected:
                print("[LoginPage] 正在断开连接")

            case .connecting:
                print("[LoginPage] 正在连接")

            @unknown default:
                break
            }
        }
    }

    func onRoomUserUpdate(_ updateType: ZegoUpdateType, userList: [ZegoUser], roomID: String) {
        print("[LoginPage] 用户更新: \(updateType.rawValue), 数量=\(userList.count)")
    }

    func onRoomStreamUpdate(_ updateType: ZegoUpdateType, streamList: [ZegoStream], extendedData: [AnyHashable: Any]?, roomID: String) {
        print("[LoginPage] 流更新: \(updateType.rawValue), 数量=\(streamList.count)")
    }
}
