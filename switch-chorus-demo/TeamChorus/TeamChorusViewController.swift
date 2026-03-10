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
        setupEventHandler()
    }

    /// 设置 ZegoEventHandler
    private func setupEventHandler() {
        zego.setEventHandler(self)
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

    /// 更新播放控制按钮的显示状态
    /// 规则：只有推流用户且 isSinging 为 true 时才显示控制按钮
    private func updatePlayerControlVisibility() {
        let shouldShowControls = isPublishing && seiSyncManager.isSinging
        chorusView.playerControlView.setControlsHidden(!shouldShowControls)
        print("[UI] 播放控制按钮: \(shouldShowControls ? "显示" : "隐藏") (isPublishing=\(isPublishing), isSinging=\(seiSyncManager.isSinging))")
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

    /// 获取房间内所有合法的队伍集合
    private var teamsInRoom: Set<ChorusTeam> {
        var teams: Set<ChorusTeam> = []
        for stream in roomStreamList {
            if let team = getTeamFromStream(stream) {
                teams.insert(team)
            }
        }
        return teams
    }

    /// 是否可以推流
    /// 规则：
    /// 1. 房间内没有流 -> 可以推流
    /// 2. 房间内有合法流，且只有一队 -> 可以推流
    /// 3. 房间内有合法流，且有两队 -> 不可以推流
    private var canPublish: Bool {
        let teams = teamsInRoom
        return teams.count < 2
    }

    /// 确定我的队伍
    /// 规则：
    /// 1. 房间内没有流 -> 作为 TeamA
    /// 2. 只有 TeamA -> 作为 TeamB
    /// 3. 只有 TeamB -> 作为 TeamA
    private func determineMyTeam() -> ChorusTeam? {
        let teams = teamsInRoom
        if teams.isEmpty {
            return .teamA
        } else if teams.count == 1 {
            return teams.contains(.teamA) ? .teamB : .teamA
        }
        return nil
    }

    private func tryStartPublishing() {
        guard let team = determineMyTeam() else {
            print("[TeamChorus] 无法上麦：房间已满")
            return
        }

        // 检查单队上麦限制：如果对方正在播放，需要等待
        let teams = teamsInRoom
        if teams.count == 1 {
            // 房间内已有一队，检查是否有歌曲正在播放
            // 通过是否有有效歌曲来判断（收到SEI后会设置effectiveSong）
            if effectiveSong != nil {
                print("[TeamChorus] 无法上麦：当前歌曲演唱完才能上麦")
                showAlert(title: "提示", message: "当前歌曲演唱完才能上麦")
                return
            }
        }

        startPublishing(team: team)
    }

    /// 显示提示框
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
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

        // 6. 设置流额外信息，标记队伍（主路和辅路都需要设置）
        let extraInfo = "team:\(team == .teamA ? "A" : "B")"
        zego.setStreamExtraInfo(extraInfo, channel: .main) { errorCode in
            print("[TeamChorus] 设置主路流额外信息: \(errorCode == 0 ? "成功" : "失败")")
        }
        zego.setStreamExtraInfo(extraInfo, channel: .aux) { errorCode in
            print("[TeamChorus] 设置辅路流额外信息: \(errorCode == 0 ? "成功" : "失败")")
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

        // 11. 更新播放控制按钮可见性
        updatePlayerControlVisibility()

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

        // 更新播放控制按钮可见性（观众隐藏按钮）
        updatePlayerControlVisibility()

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

    /// 判断流是否为主路流（_main_ 标记）
    private func isMainStream(_ streamID: String) -> Bool {
        return streamID.contains("_main_")
    }

    /// 判断流是否为辅路流（_aux_ 标记）
    private func isAuxStream(_ streamID: String) -> Bool {
        return streamID.contains("_aux_")
    }

    /// 是否应该拉取这条流
    /// 规则：
    /// - 主播（正在推流）：只拉辅路流（_aux_ 标记，纯人声）
    /// - 观众（未推流）：只拉主路流（_main_ 标记，人声+伴奏）
    private func shouldPlayStream(_ stream: ZegoStream) -> Bool {
        let streamID = stream.streamID
        if isPublishing {
            // 主播只拉辅路流
            return isAuxStream(streamID)
        } else {
            // 观众只拉主路流
            return isMainStream(streamID)
        }
    }

    private func startPlayingStream(_ stream: ZegoStream, forTeam team: ChorusTeam) {
        let streamID = stream.streamID

        // 1. 根据角色判断是否拉取此流
        guard shouldPlayStream(stream) else {
            print("[TeamChorus] 跳过拉流: \(streamID) (当前角色: \(isPublishing ? "主播" : "观众"))")
            return
        }

        // 2. 配置拉流对齐（全局设置，对所有拉流生效）
        // 与推流端的 setStreamAlignmentProperty 成对使用
        // API 来源: ZegoExpressEngine+Player.h:420
        zego.setPlayStreamsAlignmentProperty(.try)

        // 3. 开始拉流
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
            for stream in streamList {
                guard let team = getTeamFromStream(stream) else {
                    print("[TeamChorus] 流 \(stream.streamID) 的 extraInfo 不合法，跳过")
                    continue
                }

                roomStreamList.insert(stream)
                startPlayingStream(stream, forTeam: team)
            }

        case .delete:
            for stream in streamList {
                // 根据 streamID 删除（因为 ZegoStream 是 OC 对象，直接 remove 可能不匹配）
                let streamID = stream.streamID
                if let existingStream = roomStreamList.first(where: { $0.streamID == streamID }) {
                    roomStreamList.remove(existingStream)
                    print("[TeamChorus] 删除流: \(streamID)")
                }

                if let team = getTeamFromStream(stream) {
                    stopPlayingStream(stream, forTeam: team)
                }
            }
            // 打印删除后的队伍信息
            let remainingTeams = teamsInRoom
            print("[TeamChorus] 流删除后，当前队伍: \(remainingTeams)")

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
    /// 主要逻辑：点歌竞争判断、进度对齐、切换时间戳同步、歌曲同步
    private func handleSEIForPublisher(_ seiData: ChorusSEIData, fromStreamID: String) {
        // 1. 判断播放是否结束（进度 >= 总时长）
        if seiData.totalDuration > 0 && seiData.currentProgress >= seiData.totalDuration {
            print("[SEI] 播放结束，清空播放信息")
            clearPlaybackInfo()
            return
        }

        // 2. 如果对方正在唱歌，同步歌曲信息（无论是否竞争）
        // 这是为了确保后上麦或后点歌的用户能同步到当前歌曲
        if seiData.isSinging && seiData.currentSong != effectiveSong?.name {
            print("[SEI] 推流用户同步歌曲: \(seiData.currentSong)")
            syncSongFromSEI(seiData)
        }

        // 2. 点歌竞争判断（仅当双方都点了歌时）
        // 如果对方点歌时间戳更早，且歌曲不同，则需要切换到对方的歌曲
        if seiData.pickSongTimestamp > 0 &&
           localPickSongTimestamp > 0 &&
           seiData.pickSongTimestamp < localPickSongTimestamp &&
           seiData.currentSong != effectiveSong?.name {

            print("[SEI] 点歌竞争失败，切换到对方歌曲: \(seiData.currentSong)")

            // 取消本地点歌，切换到对方歌曲
            handleLostSongCompetition(seiData: seiData)
            return
        }

        // 3. 同步切换时间戳（以 isSinging=true 的用户为准）
        // 如果对方正在唱歌且设置了切换时间戳，则采用对方的切换时间戳
        if seiData.isSinging &&
           seiData.switchTimeStamp > 0 &&
           seiSyncManager.switchTimeStamp == 0 {
            print("[SEI] 同步切换时间戳: \(seiData.switchTimeStamp)ms")
            seiSyncManager.setSwitchTimeStamp(seiData.switchTimeStamp)
        }

        // 4. 如果歌曲一致，进行进度对齐
        if seiData.currentSong == effectiveSong?.name {
            alignPlaybackProgress(seiData: seiData)
        }
    }

    /// 从 SEI 同步歌曲信息（用于推流用户之间同步）
    /// 本地需要加载歌曲并播放（音量为0），以确保进度回调和seek操作正常工作
    private func syncSongFromSEI(_ seiData: ChorusSEIData) {
        // 如果 SEI 中的歌曲名为空，不同步（避免被旧的空 SEI 重置）
        guard !seiData.currentSong.isEmpty else {
            print("[SEI] 收到空的歌曲名，不同步")
            return
        }

        // 更新本地歌曲信息
        effectiveSong = SongItem(name: seiData.currentSong, filePath: "")
        currentSong = effectiveSong

        // 更新 SEI 管理器的歌曲
        seiSyncManager.setSong(currentSong)

        // 同步点歌时间戳（采用对方的，确保竞争逻辑正确）
        if seiData.pickSongTimestamp > 0 {
            localPickSongTimestamp = seiData.pickSongTimestamp
            seiSyncManager.setPickSongTimestamp(seiData.pickSongTimestamp)
        }

        // 更新 UI
        DispatchQueue.main.async { [weak self] in
            self?.chorusView.playerControlView.setSongName(seiData.currentSong)
        }

        // 本地加载歌曲并播放（音量为0，仅用于同步进度）
        // 注意：由于无法通过 SEI 获取文件路径，这里假设歌曲在 bundle 中
        // 实际项目中可能需要通过其他方式获取文件路径
        loadAndPlaySongSilently(songName: seiData.currentSong, progress: seiData.currentProgress)
    }

    /// 静默加载并播放歌曲（用于 SEI 同步场景）
    /// - Parameters:
    ///   - songName: 歌曲名称
    ///   - progress: 起始播放进度（毫秒）
    private func loadAndPlaySongSilently(songName: String, progress: UInt64) {
        // 根据歌曲名称获取文件路径（从点歌列表中查找）
        guard let song = findSongByName(songName) else {
            print("[SEI] 无法找到歌曲: \(songName)")
            return
        }

        // 加载歌曲
        accompanimentPlayer.loadSong(song) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                print("[SEI] 歌曲加载成功: \(songName)")

                // 设置本地音量为0（静音播放，只用于同步进度）
                self.accompanimentPlayer.setLocalVolume(0)
                // 推流音量保持默认60（SDK默认值，让其他人能听到）
                self.accompanimentPlayer.setPublishVolume(60)

                // 播放
                self.accompanimentPlayer.play()

                // seek 到当前进度
                let targetTime = TimeInterval(progress) / 1000.0
                self.accompanimentPlayer.seek(to: targetTime)

                print("[SEI] 开始静默播放，进度: \(progress)ms")

            case .failure(let error):
                print("[SEI] 歌曲加载失败: \(error)")
            }
        }
    }

    /// 根据歌曲名称查找歌曲（从 bundle 中）
    private func findSongByName(_ name: String) -> SongItem? {
        // 方式1: 尝试从 resources 文件夹获取
        if let resourcesURL = Bundle.main.url(forResource: "resources", withExtension: nil),
           let files = try? FileManager.default.contentsOfDirectory(at: resourcesURL, includingPropertiesForKeys: nil) {
            if let url = files.first(where: { $0.pathExtension == "mp3" && $0.deletingPathExtension().lastPathComponent == name }) {
                return SongItem(name: name, filePath: url.path)
            }
        }

        // 方式2: 直接在 Bundle 中搜索
        if let path = Bundle.main.path(forResource: name, ofType: "mp3") {
            return SongItem(name: name, filePath: path)
        }

        return nil
    }

    /// 清空播放信息（播放结束时调用）
    private func clearPlaybackInfo() {
        // 清空歌曲信息
        effectiveSong = nil
        currentSong = nil
        localPickSongTimestamp = 0

        // 重置 SEI 同步管理器
        seiSyncManager.reset()

        // 停止播放器
        accompanimentPlayer.stop()

        // 重置 UI
        DispatchQueue.main.async { [weak self] in
            self?.chorusView.playerControlView.resetUI()
        }

        print("[SEI] 播放信息已清空")
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

        // 2. 本地播放器音量设为0（静音播放，仅同步进度）
        accompanimentPlayer.setLocalVolume(0)
        print("[SEI] 竞争失败，本地音量设为0")

        // 3. 更新 SEI 管理器的歌曲信息（保持同步）
        seiSyncManager.setIsSinging(false)

        // 4. 更新播放控制按钮可见性（竞争失败者隐藏按钮）
        updatePlayerControlVisibility()
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

        // 仅当房间内有两队时才执行切换逻辑
        let teams = teamsInRoom
        guard teams.count == 2 else {
            print("[Switch] 房间内只有一队，不执行切换逻辑")
            return
        }

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

        // 2. 重置竞争静音状态（切换时需要恢复声音）
        // 如果之前因为竞争失败被静音，现在切换后要恢复
        if isMutedByCompetition && newIsSinging {
            isMutedByCompetition = false
            print("[Switch] 重置竞争静音状态，恢复推流")
        }

        // 3. 根据 isSinging 状态更新 mute 状态
        // isSinging: true -> mute: false (不静音，正常推流)
        // isSinging: false -> mute: true (静音)
        zego.mutePublishStreamAudio(!newIsSinging)
        zego.mutePublishStreamAudio(!newIsSinging, channel: .aux)

        // 4. 调整播放器音量
        // isSinging: true -> 本地音量60（SDK默认值，自己能听到）
        // isSinging: false -> 本地音量0（静音，仅同步进度）
        if newIsSinging {
            accompanimentPlayer.setLocalVolume(60)
            print("[Switch] 切换为演唱者，恢复本地音量60")
        } else {
            accompanimentPlayer.setLocalVolume(0)
            print("[Switch] 切换为等待者，静音本地播放")
        }

        print("[Switch] 队伍切换完成: isSinging=\(newIsSinging), mute=\(!newIsSinging)")

        // 5. 更新播放控制按钮可见性
        updatePlayerControlVisibility()

        // 6. 标记切换已完成（确保只切换一次）
        seiSyncManager.markAsSwitched()
    }

    // MARK: - SEI 处理（观众）

    /// 处理观众收到的 SEI
    /// 主要逻辑：判断谁在唱歌，同步歌曲信息和进度
    private func handleSEIForAudience(_ seiData: ChorusSEIData, fromStreamID: String) {
        // 1. 判断播放是否结束（进度 >= 总时长）
        if seiData.totalDuration > 0 && seiData.currentProgress >= seiData.totalDuration {
            print("[SEI] 播放结束，清空播放信息")
            clearPlaybackInfo()
            return
        }

        // 2. 观众端只处理 isSinging 为 true 的 SEI
        guard seiData.isSinging else { return }

        // 3. 同步歌曲信息
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
                self.seiSyncManager.setIsSinging(true)
                self.updatePlayerControlVisibility()
            case .paused, .idle, .ended:
                self.seiSyncManager.setIsSinging(false)
                self.updatePlayerControlVisibility()
                // 停止时重置进度显示
                // 注意：.idle 状态可能是加载新歌时调用 stop() 触发的，需要判断是否正在加载
                print("[Player] 状态变化: \(state), isLoadingSong: \(self.accompanimentPlayer.isLoadingSong)")
                if state == .ended {
                    // 播放结束，确定重置
                    print("[Player] 播放结束，重置 UI")
                    self.chorusView.playerControlView.resetUI()
                } else if state == .idle {
                    if self.accompanimentPlayer.isLoadingSong {
                        print("[Player] 加载期间忽略 idle 状态，不重置 UI")
                    } else {
                        // 仅在非加载期间的重置才更新 UI
                        print("[Player] 非加载期间的 idle，重置 UI")
                        self.chorusView.playerControlView.resetUI()
                    }
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
