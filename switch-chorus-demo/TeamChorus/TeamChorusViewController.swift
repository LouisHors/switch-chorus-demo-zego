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

    /// 伴奏播放器控制器
    private let accompanimentPlayer = AccompanimentPlayerController()

    /// SEI 同步管理器
    private lazy var seiSyncManager = ChorusSEISyncManager(zego: zego, channel: .main)

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
        setupPlayer()
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

    // MARK: - 播放器设置

    private func setupPlayer() {
        accompanimentPlayer.delegate = self
        chorusView.playerControlView.delegate = self
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
        let config = ZegoPublisherConfig()
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

        // 10. 配置 SEI 同步管理器
        seiSyncManager.setTeam(team)
        seiSyncManager.setSong(currentSong)
        seiSyncManager.setIsSinging(accompanimentPlayer.currentState == .playing)

        print("[TeamChorus] 上麦成功，队伍: \(team.rawValue)")
    }

    private func stopPublishing() {
        // API 来源: ZegoExpressEngine+Publisher.h:109, 124
        zego.stopPublishingStream()
        zego.stopPublishingStream(.aux)

        isPublishing = false
        myTeam = nil

        // 停止播放并重置播放器
        accompanimentPlayer.stop()
        chorusView.playerControlView.resetUI()

        // 重置 SEI 同步管理器（包括切换状态）
        seiSyncManager.reset()
        localPickSongTimestamp = 0
        effectiveSong = nil
        isMutedByCompetition = false

        chorusView.updateMicUpButtonUI(isPublishing: false)
        chorusView.setPickSongButtonEnabled(false)
        chorusView.hideAllTeamAvatars()

        print("[TeamChorus] 下麦成功")
    }

    // MARK: - 拉流逻辑

    /// 点歌时间戳（毫秒）- 本地点歌时间，用于竞争判断
    private var localPickSongTimestamp: UInt64 = 0

    /// 当前生效的歌曲（经过竞争判断后的）
    private var effectiveSong: SongItem?

    /// 是否因点歌竞争失败而静音
    private var isMutedByCompetition = false

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

        // 1. 配置拉流对齐（全局设置，对所有拉流生效）
        // 与推流端的 setStreamAlignmentProperty 成对使用
        // API 来源: ZegoExpressEngine+Player.h:420
        zego.setPlayStreamsAlignmentProperty(.try)

        // 2. 开始拉流
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
        // 1. 解析 SEI 数据
        guard let seiData = ChorusSEIParser.parse(data) else {
            print("[SEI] 解析 SEI 数据失败: \(streamID)")
            return
        }

        // 临时日志：打印接收到的 SEI 内容
        print("[SEI] ⬅️ 接收 from \(streamID): song=\(seiData.currentSong), progress=\(seiData.currentProgress)ms, total=\(seiData.totalDuration)ms, isSinging=\(seiData.isSinging), team=\(seiData.currentTeam), pickTS=\(seiData.pickSongTimestamp), switchTS=\(seiData.switchTimeStamp)")

        // 2. 判断当前角色：推流用户 vs 观众
        if isPublishing {
            handleSEIForPublisher(seiData, fromStreamID: streamID)
        } else {
            handleSEIForAudience(seiData, fromStreamID: streamID)
        }
    }

    // MARK: - SEI 处理（推流用户）

    /// 处理推流用户收到的 SEI
    /// 主要逻辑：点歌竞争判断、进度对齐、切换时间戳同步
    private func handleSEIForPublisher(_ seiData: ChorusSEIData, fromStreamID: String) {
        // 1. 点歌竞争判断
        // 如果对方点歌时间戳更早，且歌曲不同，则需要切换到对方的歌曲
        if seiData.pickSongTimestamp > 0 &&
           seiData.pickSongTimestamp < localPickSongTimestamp &&
           seiData.currentSong != effectiveSong?.name {

            print("[SEI] 点歌竞争失败，切换到对方歌曲: \(seiData.currentSong)")

            // 取消本地点歌，切换到对方歌曲
            handleLostSongCompetition(seiData: seiData)
            return
        }

        // 2. 同步切换时间戳（以 isSinging=true 的用户为准）
        // 如果对方正在唱歌且设置了切换时间戳，则采用对方的切换时间戳
        if seiData.isSinging &&
           seiData.switchTimeStamp > 0 &&
           seiSyncManager.switchTimeStamp == 0 {
            print("[SEI] 同步切换时间戳: \(seiData.switchTimeStamp)ms")
            seiSyncManager.setSwitchTimeStamp(seiData.switchTimeStamp)
        }

        // 3. 如果歌曲一致，进行进度对齐
        if seiData.currentSong == effectiveSong?.name {
            alignPlaybackProgress(seiData: seiData)
        }
    }

    /// 处理点歌竞争失败
    private func handleLostSongCompetition(seiData: ChorusSEIData) {
        // 1. 静音两个通道（因为当前不是唱歌的人）
        if !isMutedByCompetition {
            zego.mutePublishStreamAudio(true)
            zego.mutePublishStreamAudio(true, channel: .aux)
            isMutedByCompetition = true
            seiSyncManager.setIsSinging(false)
            print("[SEI] 竞争失败，已静音")
        }

        // 2. 更新 SEI 管理器的歌曲信息（保持同步）
        seiSyncManager.setIsSinging(false)
    }

    /// 对齐播放进度
    private func alignPlaybackProgress(seiData: ChorusSEIData) {
        let localProgressMs = UInt64(accompanimentPlayer.currentTime * 1000)
        let remoteProgressMs = seiData.currentProgress

        // 如果进度差超过 100ms，进行对齐
        if ChorusSEIParser.needsAlignment(
            localProgress: localProgressMs,
            remoteProgress: remoteProgressMs,
            threshold: 100
        ) {
            let targetTime = TimeInterval(remoteProgressMs) / 1000.0
            print("[SEI] 进度对齐: 本地 \(localProgressMs)ms -> 远程 \(remoteProgressMs)ms")
            accompanimentPlayer.seek(to: targetTime)
        }
    }

    // MARK: - 队伍切换逻辑

    /// 检查并执行队伍切换
    /// - Parameter currentProgressMs: 当前播放进度（毫秒）
    private func checkAndPerformTeamSwitch(currentProgressMs: UInt64) {
        // 只有推流用户才需要处理切换
        guard isPublishing else { return }

        // 检查是否需要切换
        guard seiSyncManager.shouldSwitch(currentProgress: currentProgressMs) else { return }

        print("[Switch] 到达切换时间点: \(currentProgressMs)ms >= \(seiSyncManager.switchTimeStamp)ms")

        // 执行切换：切换 isSinging 状态和 mute 状态
        performTeamSwitch()
    }

    /// 执行队伍切换
    private func performTeamSwitch() {
        // 1. 切换 isSinging 状态
        seiSyncManager.toggleSingingState()
        let newIsSinging = seiSyncManager.isSinging

        // 2. 根据 isSinging 状态更新 mute 状态
        // isSinging: true -> mute: false (不静音，正常推流)
        // isSinging: false -> mute: true (静音)
        zego.mutePublishStreamAudio(!newIsSinging)
        zego.mutePublishStreamAudio(!newIsSinging, channel: .aux)

        print("[Switch] 队伍切换完成: isSinging=\(newIsSinging), mute=\(!newIsSinging)")

        // 3. 标记切换已完成（确保只切换一次）
        seiSyncManager.markAsSwitched()
    }

    // MARK: - SEI 处理（观众）

    /// 处理观众收到的 SEI
    /// 主要逻辑：判断谁在唱歌，同步歌曲信息和进度
    private func handleSEIForAudience(_ seiData: ChorusSEIData, fromStreamID: String) {
        // 观众端只处理 isSinging 为 true 的 SEI
        guard seiData.isSinging else { return }

        // 1. 同步歌曲信息
        if seiData.currentSong != effectiveSong?.name {
            print("[SEI] 观众同步歌曲: \(seiData.currentSong)")
            // 更新本地歌曲显示（UI 层）
            DispatchQueue.main.async { [weak self] in
                self?.chorusView.playerControlView.setSongName(seiData.currentSong)
            }
        }

        // 2. 同步进度显示（观众本地可以显示进度，但不实际播放音频）
        let currentTime = TimeInterval(seiData.currentProgress) / 1000.0
        let totalTime = TimeInterval(seiData.totalDuration) / 1000.0

        DispatchQueue.main.async { [weak self] in
            self?.chorusView.playerControlView.setCurrentTime(currentTime, totalTime: totalTime)
        }

        // 3. 同步切换时间戳（以 isSinging=true 的用户为准）
        if seiData.switchTimeStamp > 0 && seiSyncManager.switchTimeStamp == 0 {
            print("[SEI] 观众同步切换时间戳: \(seiData.switchTimeStamp)ms")
            seiSyncManager.setSwitchTimeStamp(seiData.switchTimeStamp)
        }

        // 4. 记录当前生效的歌曲
        effectiveSong = SongItem(name: seiData.currentSong, filePath: "")
    }
}

// MARK: - AccompanimentPlayerDelegate

extension TeamChorusViewController: AccompanimentPlayerDelegate {

    func player(_ player: AccompanimentPlayerController, didUpdateState state: PlayerState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            switch state {
            case .playing:
                self.chorusView.playerControlView.setButtonStates(isPlaying: true)
                self.seiSyncManager.setIsSinging(true)
            case .paused, .idle, .ended:
                self.chorusView.playerControlView.setButtonStates(isPlaying: false)
                self.seiSyncManager.setIsSinging(false)
                // 停止时重置进度显示
                if state == .idle || state == .ended {
                    self.chorusView.playerControlView.resetUI()
                }
            default:
                break
            }
        }
    }

    func player(_ player: AccompanimentPlayerController, didUpdateProgress currentTime: TimeInterval, totalTime: TimeInterval) {
        chorusView.playerControlView.setCurrentTime(currentTime, totalTime: totalTime)

        let currentProgressMs = UInt64(currentTime * 1000)

        // 检查并执行队伍切换（仅在推流中状态下）
        if isPublishing {
            checkAndPerformTeamSwitch(currentProgressMs: currentProgressMs)
        }

        // 发送 SEI 进度同步（仅在推流中状态下）
        if isPublishing {
            seiSyncManager.syncWithPlayer(player)
        }
    }

    func player(_ player: AccompanimentPlayerController, didEncounterError error: PlayerError) {
        print("[TeamChorus] 播放器错误: \(error)")
    }
}

// MARK: - PlayerControlViewDelegate

extension TeamChorusViewController: PlayerControlViewDelegate {

    func playerControlViewDidTapPlay(_ view: PlayerControlView) {
        switch accompanimentPlayer.currentState {
        case .idle, .ended:
            // 重新加载并播放
            if let song = currentSong {
                accompanimentPlayer.loadSong(song) { [weak self] result in
                    switch result {
                    case .success:
                        self?.accompanimentPlayer.play()
                    case .failure(let error):
                        print("[TeamChorus] 加载歌曲失败: \(error)")
                    }
                }
            }
        case .ready:
            accompanimentPlayer.play()
        case .paused:
            // 修复：从暂停状态恢复时调用 resume
            accompanimentPlayer.resume()
        case .playing:
            break
        case .loading:
            break
        }
    }

    func playerControlViewDidTapPause(_ view: PlayerControlView) {
        accompanimentPlayer.pause()
    }

    func playerControlViewDidTapStop(_ view: PlayerControlView) {
        accompanimentPlayer.stop()
    }

    func playerControlView(_ view: PlayerControlView, didSeekTo progress: Double) {
        // 使用缓存的总时长计算目标时间
        let targetTime = progress * accompanimentPlayer.cachedTotalTime
        accompanimentPlayer.seek(to: targetTime)
    }
}

// MARK: - SongPickerDelegate

extension TeamChorusViewController: SongPickerDelegate {

    func songPicker(_ picker: SongPickerViewController, didSelectSong song: SongItem, timestamp: UInt64) {
        print("[TeamChorus] 选中歌曲: \(song.name), 时间戳: \(timestamp)")
        print("[TeamChorus] 文件路径: \(song.filePath)")

        // 1. 记录本地点歌时间戳
        localPickSongTimestamp = timestamp

        // 2. 设置当前歌曲
        currentSong = song
        effectiveSong = song

        // 3. 更新 SEI 同步管理器的歌曲信息和点歌时间戳
        seiSyncManager.setSong(song)
        seiSyncManager.setPickSongTimestamp(timestamp)

        // 4. 重置竞争静音状态
        isMutedByCompetition = false

        // 5. 更新 UI
        chorusView.playerControlView.setSongName(song.name)

        // 6. 自动加载歌曲
        accompanimentPlayer.loadSong(song) { [weak self] result in
            switch result {
            case .success:
                print("[TeamChorus] 歌曲加载成功: \(song.name)")

                // 生成切换时间戳（总时长/2 ± 10000ms 随机偏移）
                let totalDurationMs = UInt64(self?.accompanimentPlayer.cachedTotalTime ?? 0) * 1000
                if totalDurationMs > 0 {
                    let switchTime = self?.seiSyncManager.generateSwitchTimeStamp(totalDuration: totalDurationMs)
                    print("[TeamChorus] 生成切换时间戳: \(switchTime ?? 0)ms")
                }

                // 如果已在推流状态，自动开始播放
                if self?.isPublishing == true {
                    self?.accompanimentPlayer.play()
                }
            case .failure(let error):
                print("[TeamChorus] 歌曲加载失败: \(error)")
            }
        }
    }
}
