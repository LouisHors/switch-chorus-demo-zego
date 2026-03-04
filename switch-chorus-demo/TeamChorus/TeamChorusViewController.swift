//
//  TeamChorusViewController.swift
//  switch-chorus-demo
//
//  组队合唱页面 - 控制器层
//  负责业务逻辑、SDK 调用、事件处理
//

import UIKit
import ZegoExpressEngine

class TeamChorusViewController: UIViewController {

    // MARK: - 属性

    /// 自定义视图
    private var chorusView: TeamChorusView {
        return view as! TeamChorusView
    }

    /// ZEGO 引擎实例
    private let zego = ZegoExpressEngine.shared()

    /// 房间 ID
    private var roomID: String

    /// 流列表
    private var roomStreamList: Set<ZegoStream> = []

    /// 我的队伍
    private var myTeam: ChorusTeam?

    /// 是否正在推流
    private var isPublishing = false

    /// 当前选中的歌曲
    private var currentSong: SongItem?

    // MARK: - 初始化

    init(roomID: String) {
        self.roomID = roomID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 生命周期

    override func loadView() {
        view = TeamChorusView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCallbacks()
        setupAudioConfig()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 确保渐变层尺寸正确
        chorusView.layoutIfNeeded()
    }

    // MARK: - 回调设置

    private func setupCallbacks() {
        chorusView.onBackButtonTapped = { [weak self] in
            self?.handleBackButton()
        }
        chorusView.onMicButtonTapped = { [weak self] in
            self?.handleMicButton()
        }
        chorusView.onPickSongButtonTapped = { [weak self] in
            self?.handlePickSongButton()
        }
        chorusView.onMicUpButtonTapped = { [weak self] in
            self?.handleMicUpButton()
        }
        chorusView.onLeaveButtonTapped = { [weak self] in
            self?.handleLeaveButton()
        }
    }

    // MARK: - 音频配置

    private func setupAudioConfig() {
        // 参考: 参数配置表.csv - 合唱场景配置
        // API 来源: ZegoExpressDefines.h:3691, 3694, 3697
        let audioConfig = ZegoAudioConfig()
        audioConfig.bitrate = 128
        audioConfig.channel = .stereo
        audioConfig.codecID = .low3  // 属性名是 codecID，不是 codec
        zego.setAudioConfig(audioConfig)

        // 音频设备模式
        zego.setAudioDeviceMode(.general)

        // 3A 配置
        zego.enableAEC(true)
        zego.setAECMode(.soft)
        zego.enableANS(true)
        zego.setANSMode(.medium)
        zego.enableHeadphoneAEC(false)
    }

    // MARK: - 按钮处理

    private func handleBackButton() {
        navigationController?.popViewController(animated: true)
    }

    private func handleMicButton() {
        isMuted.toggle()
        zego.mutePublishStreamAudio(isMuted)
        zego.mutePublishStreamAudio(isMuted, channel: .aux)
        chorusView.updateMicButtonUI(isMuted: isMuted)
    }

    private var isMuted = false

    private func handlePickSongButton() {
        let picker = SongPickerViewController()
        picker.delegate = self
        picker.modalPresentationStyle = .pageSheet

        if let sheet = picker.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }

        present(picker, animated: true)
    }

    private func handleMicUpButton() {
        if isPublishing {
            stopPublishing()
        } else {
            tryStartPublishing()
        }
    }

    private func handleLeaveButton() {
        zego.logoutRoom()
        navigationController?.popViewController(animated: true)
    }

    // MARK: - 推流逻辑

    private var canPublish: Bool {
        let streamCount = roomStreamList.count
        if streamCount == 0 {
            return true
        } else if streamCount == 1 {
            return hasTeamAMarked()
        }
        return false
    }

    private func hasTeamAMarked() -> Bool {
        for stream in roomStreamList {
            if stream.extraInfo.contains("team:A") {
                return true
            }
        }
        return false
    }

    private func determineMyTeam() -> ChorusTeam? {
        let streamCount = roomStreamList.count
        if streamCount == 0 {
            return .teamA
        } else if streamCount == 1 && hasTeamAMarked() {
            return .teamB
        }
        return nil
    }

    private func tryStartPublishing() {
        guard let team = determineMyTeam() else {
            print("[TeamChorus] 无法上麦：房间已满")
            return
        }

        startPublishing(team: team)
    }

    private func startPublishing(team: ChorusTeam) {
        // 1. 设置流对齐属性
        // API 来源: ZegoExpressEngine+Publisher.h:509
        zego.setStreamAlignmentProperty(1, channel: .main)
        zego.setStreamAlignmentProperty(1, channel: .aux)

        // 2. 配置推流参数
        var config = ZegoPublisherConfig()
        config.forceSynchronousNetworkTime = 1

        // 3. 生成流 ID
        let mainStreamID = "chorus_\(roomID)_\(team.rawValue)_main_\(UUID().uuidString.prefix(8))"
        let auxStreamID = "chorus_\(roomID)_\(team.rawValue)_aux_\(UUID().uuidString.prefix(8))"

        // 4. 开始推流（主通道）
        zego.startPublishingStream(mainStreamID, config: config, channel: .main)

        // 5. 开始推流（辅通道 - 人声复用）
        zego.startPublishingStream(auxStreamID, config: config, channel: .aux)

        // 6. 设置流额外信息，标记队伍
        let extraInfo = "team:\(team == .teamA ? "A" : "B")"
        zego.setStreamExtraInfo(extraInfo) { errorCode in
            print("[TeamChorus] 设置流额外信息: \(errorCode == 0 ? "成功" : "失败")")
        }

        // 7. 更新状态
        myTeam = team
        isPublishing = true

        // 8. 更新 UI
        chorusView.updateMicUpButtonUI(isPublishing: true)
        chorusView.setPickSongButtonEnabled(true)

        // 9. 更新队伍头像
        if team == .teamA {
            chorusView.showTeamA()
        } else {
            chorusView.showTeamB()
        }

        print("[TeamChorus] 上麦成功，队伍: \(team.rawValue)")
    }

    private func stopPublishing() {
        // API 来源: ZegoExpressEngine+Publisher.h:109, 124
        zego.stopPublishingStream()
        zego.stopPublishingStream(.aux)

        isPublishing = false
        myTeam = nil

        chorusView.updateMicUpButtonUI(isPublishing: false)
        chorusView.setPickSongButtonEnabled(false)
        chorusView.hideAllTeamAvatars()

        print("[TeamChorus] 下麦成功")
    }

    // MARK: - 拉流逻辑

    private func getTeamFromStream(_ stream: ZegoStream) -> ChorusTeam? {
        let extraInfo = stream.extraInfo
        if extraInfo.contains("team:A") {
            return .teamA
        } else if extraInfo.contains("team:B") {
            return .teamB
        }
        return nil
    }

    private func startPlayingStream(_ stream: ZegoStream, forTeam team: ChorusTeam) {
        let streamID = stream.streamID

        // API 来源: ZegoExpressEngine+Player.h:62
        zego.startPlayingStream(streamID)

        // 更新 UI
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if team == .teamA {
                self.chorusView.showTeamA()
            } else {
                self.chorusView.showTeamB()
            }
            print("[TeamChorus] 拉流成功: \(team) (\(streamID))")
        }
    }

    private func stopPlayingStream(_ stream: ZegoStream, forTeam team: ChorusTeam) {
        let streamID = stream.streamID

        // API 来源: ZegoExpressEngine+Player.h:148
        zego.stopPlayingStream(streamID)

        // 更新 UI
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if team == .teamA {
                self.chorusView.hideTeamA()
            } else {
                self.chorusView.hideTeamB()
            }
            print("[TeamChorus] 停止拉流: \(team) (\(streamID))")
        }
    }
}

// MARK: - ZegoEventHandler

extension TeamChorusViewController: ZegoEventHandler {

    func onRoomStateUpdate(_ state: ZegoRoomState, errorCode: Int32, extendedData: [AnyHashable: Any]?, roomID: String) {
        print("[TeamChorus] 房间状态更新: \(state.rawValue), 错误码: \(errorCode)")
    }

    func onPublisherStateUpdate(_ state: ZegoPublisherState, errorCode: Int32, extendedData: [AnyHashable: Any]?, streamID: String) {
        print("[TeamChorus] 推流状态更新: \(state.rawValue), 流ID: \(streamID)")
    }

    func onPlayerStateUpdate(_ state: ZegoPlayerState, errorCode: Int32, extendedData: [AnyHashable: Any]?, streamID: String) {
        print("[TeamChorus] 拉流状态更新: \(state.rawValue), 流ID: \(streamID)")
    }

    func onRoomStreamUpdate(_ updateType: ZegoUpdateType, streamList: [ZegoStream], extendedData: [AnyHashable: Any]?, roomID: String) {
        switch updateType {
        case .add:
            if roomStreamList.count >= 2 {
                print("[TeamChorus] 房间内已有 2 条流，忽略新增流")
                return
            }

            for stream in streamList {
                guard let team = getTeamFromStream(stream) else {
                    print("[TeamChorus] 流 \(stream.streamID) 的 extraInfo 不合法")
                    continue
                }

                roomStreamList.insert(stream)
                startPlayingStream(stream, forTeam: team)
            }

        case .delete:
            for stream in streamList {
                roomStreamList.remove(stream)

                if let team = getTeamFromStream(stream) {
                    stopPlayingStream(stream, forTeam: team)
                }
            }

        default:
            break
        }
    }

    func onRoomStreamExtraInfoUpdate(_ streamList: [ZegoStream], roomID: String) {
        print("[TeamChorus] 流额外信息更新")
    }

    func onPlayerSyncRecvSEI(_ data: Data, streamID: String) {
        // SEI 进度同步（待实现）
    }
}

// MARK: - SongPickerDelegate

extension TeamChorusViewController: SongPickerDelegate {

    func songPicker(_ picker: SongPickerViewController, didSelectSong song: SongItem) {
        print("[TeamChorus] 选中歌曲: \(song.name)")
        print("[TeamChorus] 文件路径: \(song.filePath)")
        currentSong = song
    }
}
