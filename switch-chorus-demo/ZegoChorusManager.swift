//
//  ZegoChorusManager.swift
//  switch-chorus-demo
//
//  ZEGO 实时合唱管理器
//  实现标准合唱方案的核心功能
//

import UIKit
import ZegoExpressEngine

// MARK: - 合唱管理器代理协议
protocol ZegoChorusManagerDelegate: AnyObject {
    /// 房间状态更新
    func chorusManager(_ manager: ZegoChorusManager, roomStateUpdate state: ZegoRoomState, errorCode: Int, roomID: String)

    /// 用户加入
    func chorusManager(_ manager: ZegoChorusManager, userJoined userID: String, streamID: String)

    /// 用户离开
    func chorusManager(_ manager: ZegoChorusManager, userLeft streamID: String)

    /// 收到 SEI 消息
    func chorusManager(_ manager: ZegoChorusManager, receivedSEI data: Data, streamID: String)

    /// 媒体播放器进度更新
    func chorusManager(_ manager: ZegoChorusManager, mediaPlayerProgress progress: UInt64, duration: UInt64)

    /// 混流任务结果
    func chorusManager(_ manager: ZegoChorusManager, mixerTaskResult errorCode: Int)

    /// 远端流添加
    func chorusManager(_ manager: ZegoChorusManager, remoteStreamAdded streams: [ZegoStream])

    /// 远端流删除
    func chorusManager(_ manager: ZegoChorusManager, remoteStreamDeleted streams: [ZegoStream])
}

// 提供默认实现，使代理方法可选
extension ZegoChorusManagerDelegate {
    func chorusManager(_ manager: ZegoChorusManager, roomStateUpdate state: ZegoRoomState, errorCode: Int, roomID: String) {}
    func chorusManager(_ manager: ZegoChorusManager, userJoined userID: String, streamID: String) {}
    func chorusManager(_ manager: ZegoChorusManager, userLeft streamID: String) {}
    func chorusManager(_ manager: ZegoChorusManager, receivedSEI data: Data, streamID: String) {}
    func chorusManager(_ manager: ZegoChorusManager, mediaPlayerProgress progress: UInt64, duration: UInt64) {}
    func chorusManager(_ manager: ZegoChorusManager, mixerTaskResult errorCode: Int) {}
    func chorusManager(_ manager: ZegoChorusManager, remoteStreamAdded streams: [ZegoStream]) {}
    func chorusManager(_ manager: ZegoChorusManager, remoteStreamDeleted streams: [ZegoStream]) {}
}

// MARK: - 合唱管理器
class ZegoChorusManager: NSObject {

    // MARK: - 单例
    static let shared = ZegoChorusManager()

    // MARK: - 属性
    weak var delegate: ZegoChorusManagerDelegate?

    /// 当前用户 ID
    private(set) var userID: String = ""

    /// 当前房间 ID
    private(set) var roomID: String = ""

    /// 当前角色
    private(set) var role: ChorusRole = .audience

    /// 媒体播放器
    private(set) var mediaPlayer: ZegoMediaPlayer?

    /// 混流任务
    private var mixerTask: ZegoMixerTask?

    /// 混流 ID
    private(set) var mixStreamID: String = ""

    /// 正在播放的流 ID 列表
    private var playingStreamIDs: Set<String> = []

    /// 是否已登录房间
    private(set) var isLoggedIn: Bool = false

    /// 是否已推流
    private(set) var isPublishing: Bool = false

    /// 当前伴奏进度 (ms)
    private(set) var currentProgress: UInt64 = 0

    /// 当前伴奏进度对应的 NTP 时间
    private var currentProgressNtpTime: Int64 = 0

    /// 当前播放资源 ID
    private var resourceID: String = ""

    /// 歌曲总时长 (ms)
    private var songDuration: UInt64 = 0

    // MARK: - 初始化
    private override init() {
        super.init()
    }

    // MARK: - 公开方法

    /// 创建引擎（含超低延迟配置）
    func createEngine() {
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

        // 3. 创建媒体播放器
        setupMediaPlayer()

        print("[ZegoChorusManager] 引擎创建完成")
    }

    /// 销毁引擎
    func destroyEngine() {
        mediaPlayer?.stop()
        mediaPlayer = nil
        ZegoExpressEngine.destroy()
        print("[ZegoChorusManager] 引擎已销毁")
    }

    /// 登录房间
    /// - Parameters:
    ///   - roomID: 房间 ID
    ///   - userID: 用户 ID
    ///   - userName: 用户名
    ///   - role: 角色
    ///   - token: Token（可选，如无 Token 可传空）
    func loginRoom(roomID: String, userID: String, userName: String, role: ChorusRole, token: String = "") {
        self.roomID = roomID
        self.userID = userID
        self.role = role
        self.mixStreamID = "mix_\(roomID)"

        let user = ZegoUser(userID: userID, userName: userName)
        let config = ZegoRoomConfig()
        config.isUserStatusNotify = true
        if !token.isEmpty {
            config.token = token
        }

        ZegoExpressEngine.shared().loginRoom(roomID, user: user, config: config)
        print("[ZegoChorusManager] 登录房间: \(roomID), 用户: \(userID), 角色: \(role)")
    }

    /// 登出房间
    func logoutRoom() {
        ZegoExpressEngine.shared().logoutRoom(roomID)
        isLoggedIn = false
        isPublishing = false
        playingStreamIDs.removeAll()
        print("[ZegoChorusManager] 登出房间")
    }

    /// 开始推流
    func startPublishing() {
        guard isLoggedIn else {
            print("[ZegoChorusManager] 请先登录房间")
            return
        }

        let config = ZegoPublisherConfig()
        config.roomID = roomID
        config.forceSynchronousNetworkTime = 1

        // 推人声流
        let streamID = getStreamID()
        ZegoExpressEngine.shared().startPublishingStream(streamID, config: config, channel: .main)

        // 如果是点歌用户，额外推伴奏流
        if role == .songOwner {
            let accompanimentStreamID = streamID + StreamIDSuffix.accompaniment
            ZegoExpressEngine.shared().startPublishingStream(accompanimentStreamID, config: config, channel: .aux)
        }

        isPublishing = true
        print("[ZegoChorusManager] 开始推流, streamID: \(streamID)")
    }

    /// 停止推流
    func stopPublishing() {
        ZegoExpressEngine.shared().stopPublishingStream()
        isPublishing = false
        print("[ZegoChorusManager] 停止推流")
    }

    /// 开始拉流
    /// - Parameters:
    ///   - streamID: 流 ID
    ///   - canvas: 渲染画布（可选）
    func startPlayingStream(_ streamID: String, canvas: ZegoCanvas? = nil) {
        guard !playingStreamIDs.contains(streamID) else { return }

        ZegoExpressEngine.shared().startPlayingStream(streamID, canvas: canvas)

        // 设置 jitterBuffer
        let range: ClosedRange<Int> = role == .audience ?
            ChorusConstants.audienceJitterBufferRange :
            ChorusConstants.anchorJitterBufferRange
        ZegoExpressEngine.shared().setPlayStreamBufferIntervalRange(streamID, min: UInt32(range.lowerBound), max: UInt32(range.upperBound))

        playingStreamIDs.insert(streamID)
        print("[ZegoChorusManager] 开始拉流: \(streamID), jitterBuffer: \(range)")
    }

    /// 停止拉流
    func stopPlayingStream(_ streamID: String) {
        ZegoExpressEngine.shared().stopPlayingStream(streamID)
        playingStreamIDs.remove(streamID)
        print("[ZegoChorusManager] 停止拉流: \(streamID)")
    }

    /// 拉混流（观众用）
    func startPlayingMixStream(canvas: ZegoCanvas? = nil) {
        startPlayingStream(mixStreamID, canvas: canvas)
    }

    /// 停止拉混流
    func stopPlayingMixStream() {
        stopPlayingStream(mixStreamID)
    }

    /// 配置音频（K歌场景）
    func configureAudioForKaraoke() {
        // 1. 设置伴奏流音源为媒体播放器
        let audioConfig = ZegoCustomAudioConfig()
        audioConfig.sourceType = .mediaPlayer
        ZegoExpressEngine.shared().enableCustomAudioIO(true, config: audioConfig, channel: .aux)

        // 2. 设置人声流音频配置
        let voiceConfig = ZegoAudioConfig(preset: .highQuality)
        voiceConfig.channel = .mono
        voiceConfig.codecID = .low3
        voiceConfig.bitrate = Int32(ChorusConstants.voiceAudioBitrate)
        ZegoExpressEngine.shared().setAudioConfig(voiceConfig, channel: .main)

        // 3. 设置伴奏流音频配置
        let accompanimentConfig = ZegoAudioConfig()
        accompanimentConfig.channel = .stereo
        accompanimentConfig.codecID = .low3
        accompanimentConfig.bitrate = Int32(ChorusConstants.accompanimentAudioBitrate)
        ZegoExpressEngine.shared().setAudioConfig(accompanimentConfig, channel: .aux)

        // 4. 设置流对齐模式
        ZegoExpressEngine.shared().setStreamAlignmentProperty(1, channel: .main)
        ZegoExpressEngine.shared().setStreamAlignmentProperty(1, channel: .aux)

        print("[ZegoChorusManager] K歌音频配置完成")
    }

    /// 设置音频前处理（AEC/ANS/AGC）
    func configureAudioProcessing(enableAEC: Bool = true, enableANS: Bool = true, enableAGC: Bool = false) {
        ZegoExpressEngine.shared().setAECMode(.medium)
        ZegoExpressEngine.shared().enableAEC(enableAEC)

        ZegoExpressEngine.shared().setANSMode(.medium)
        ZegoExpressEngine.shared().enableANS(enableANS)

        ZegoExpressEngine.shared().enableAGC(enableAGC)

        print("[ZegoChorusManager] 音频前处理配置: AEC=\(enableAEC), ANS=\(enableANS), AGC=\(enableAGC)")
    }

    /// 设置混响效果
    func setReverbPreset(_ preset: ZegoReverbPreset) {
        ZegoExpressEngine.shared().setReverbPreset(preset)
    }

    // MARK: - 媒体播放器相关

    private func setupMediaPlayer() {
        mediaPlayer = ZegoExpressEngine.shared().createMediaPlayer()

        // 设置进度回调间隔
        mediaPlayer?.setProgressInterval(ChorusConstants.mediaPlayerProgressInterval)

        // 设置代理
        mediaPlayer?.setEventHandler(self)

        print("[ZegoChorusManager] 媒体播放器创建完成")
    }

    /// 加载本地音乐资源
    func loadMediaResource(_ filePath: String) {
        mediaPlayer?.loadResource(filePath)
        print("[ZegoChorusManager] 加载音乐资源: \(filePath)")
    }

    /// 在未来指定时间点播放（用于伴奏同步）
    func startInFuture(_ ntpTimestamp: Int64) {
//        mediaPlayer?.startInFuture(ntpTimestamp)
        print("[ZegoChorusManager] 定时播放: NTP时间=\(ntpTimestamp)")
    }

    /// 开始播放
    func startPlaying() {
        mediaPlayer?.start()
    }

    /// 暂停播放
    func pausePlaying() {
        mediaPlayer?.pause()
    }

    /// 恢复播放
    func resumePlaying() {
        mediaPlayer?.resume()
    }

    /// 停止播放
    func stopPlaying() {
        mediaPlayer?.stop()
        currentProgress = 0
        currentProgressNtpTime = 0
    }

    /// 跳转到指定位置
    func seekTo(_ millisecond: UInt64) {
        mediaPlayer?.seek(to: millisecond) { errorCode in
            print("[ZegoChorusManager] 跳转结果: \(errorCode)")
        }
    }

    /// 伴奏同步（中途加入合唱用）
    func conformAccompany(resourceID: String, progress: UInt64, pointTime: Int64) {
        // TODO: 加载伴奏
        
        // 计算需要跳转的位置
        let currentNtpTime = getNetworkTimestamp()
        let seekProgress = currentNtpTime - pointTime + Int64(progress)

        seekTo(UInt64(seekProgress))
        startPlaying()
    }

    /// 伴奏进度对齐（根据延迟调整）
    func conformAccompanyWithLatency(_ latency: Int64) {
        guard latency > ChorusConstants.accompanySyncThreshold else { return }

        let newProgress = currentProgress + UInt64(latency)
        seekTo(newProgress)
        print("[ZegoChorusManager] 伴奏进度对齐: 延迟=\(latency)ms, 新进度=\(newProgress)")
    }

    // MARK: - SEI 消息

    /// 发送 SEI 消息
    func sendSEI(_ data: Data) {
        ZegoExpressEngine.shared().sendSEI(data, channel: .main)
    }

    /// 发送伴奏进度 SEI
    func sendProgressSEI() {
        guard role == .songOwner else { return }

        let ntpTime = getNetworkTimestamp()
        currentProgressNtpTime = ntpTime

        let messageDict: [String: Any] = [
            SEIMessageKey.role: role.rawValue,
            SEIMessageKey.progress: currentProgress,
            SEIMessageKey.pointTime: ntpTime,
            SEIMessageKey.resourceID: resourceID,
            SEIMessageKey.totalTime: songDuration,
            SEIMessageKey.state: mediaPlayer?.currentState().rawValue ?? 0
        ]

        if let data = try? JSONSerialization.data(withJSONObject: messageDict) {
            sendSEI(data)
        }
    }

    /// 发送播放控制消息（用于同步播放）
    func sendPlayControlMessage(behavior: MediaPlayerBehavior, startTime: Int64, resourceID: String? = nil) {
        var messageDict: [String: Any] = [
            SEIMessageKey.message: StreamExtraMessage.mediaplayerStartInFuture,
            SEIMessageKey.behaviorType: behavior.rawValue,
            SEIMessageKey.startTime: startTime
        ]

        if let resourceID = resourceID {
            messageDict[SEIMessageKey.resourceID] = resourceID
        }

        if let data = try? JSONSerialization.data(withJSONObject: messageDict) {
            // 通过流附加消息发送
            ZegoExpressEngine.shared().setStreamExtraInfo(String(data: data, encoding: .utf8) ?? "") { errorCode in
                print("[ZegoChorusManager] 发送播放控制消息: \(errorCode)")
            }
        }
    }

    // MARK: - 辅助方法

    /// 获取当前用户的流 ID
    func getStreamID() -> String {
        return userID
    }

    /// 获取网络时间（NTP）
    func getNetworkTimestamp() -> Int64 {
        return Int64(ZegoExpressEngine.shared().getNetworkTimeInfo().timestamp)
    }

    /// 设置歌曲总时长
    func setSongDuration(_ duration: UInt64) {
        self.songDuration = duration
    }
}

// MARK: - ZegoEventHandler
extension ZegoChorusManager: ZegoEventHandler {

    func onRoomStateUpdate(_ state: ZegoRoomState, errorCode: Int32, extendedData: [AnyHashable: Any]?, roomID: String) {
        isLoggedIn = (state == .connected && errorCode == 0)
        delegate?.chorusManager(self, roomStateUpdate: state, errorCode: Int(errorCode), roomID: roomID)
        print("[ZegoChorusManager] 房间状态更新: state=\(state.rawValue), errorCode=\(errorCode)")

        // 登录成功后自动开始推流（主播角色）
        if isLoggedIn && (role == .anchor || role == .songOwner) {
            startPublishing()
        }
    }

    func onRoomUserUpdate(_ updateType: ZegoUpdateType, userList: [ZegoUser], roomID: String) {
        print("[ZegoChorusManager] 用户更新: \(updateType.rawValue), 数量=\(userList.count)")
    }

    func onRoomStreamUpdate(_ updateType: ZegoUpdateType, streamList: [ZegoStream], extendedData: [AnyHashable: Any]?, roomID: String) {
        if updateType == .add {
            delegate?.chorusManager(self, remoteStreamAdded: streamList)
            for stream in streamList {
                // 过滤伴奏流
                if !stream.streamID.contains(StreamIDSuffix.accompaniment) {
                    delegate?.chorusManager(self, userJoined: stream.user.userID, streamID: stream.streamID)
                }
            }
        } else if updateType == .delete {
            delegate?.chorusManager(self, remoteStreamDeleted: streamList)
            for stream in streamList {
                delegate?.chorusManager(self, userLeft: stream.streamID)
            }
        }
    }

    func onRoomStreamExtraInfoUpdate(_ streamList: [ZegoStream], roomID: String) {
        // 处理流附加消息（播放控制）
        for stream in streamList {
            guard let data = stream.extraInfo.data(using: .utf8),
                  let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                continue
            }

            if let message = dict[SEIMessageKey.message] as? String,
               message == StreamExtraMessage.mediaplayerStartInFuture {
                // 处理播放控制消息
                handlePlayControlMessage(dict)
            }
        }
    }

    func onPlayerRecvSEI(_ data: Data, streamID: String) {
        delegate?.chorusManager(self, receivedSEI: data, streamID: streamID)
    }

    // 收到 SEI 以后媒体播放器的动作同步，不需要混流操作了，等会改逻辑
    private func handlePlayControlMessage(_ dict: [String: Any]) {
        guard let behaviorValue = dict[SEIMessageKey.behaviorType] as? Int,
              let behavior = MediaPlayerBehavior(rawValue: behaviorValue),
              let startTime = dict[SEIMessageKey.startTime] as? Int64 else {
            return
        }

        switch behavior {
        case .play, .resume:
            startInFuture(startTime)
        case .stop:
            stopPlaying()
        case .pause:
            pausePlaying()
        }
    }
}

// MARK: - ZegoMediaPlayerEventHandler
extension ZegoChorusManager: ZegoMediaPlayerEventHandler {

    func onMediaPlayerStateUpdate(_ mediaPlayer: ZegoMediaPlayer, state: ZegoMediaPlayerState, errorCode: Int32) {
        print("[ZegoChorusManager] 播放器状态更新: state=\(state.rawValue), errorCode=\(errorCode)")
    }

    func onMediaPlayerNetworkEvent(_ mediaPlayer: ZegoMediaPlayer, event: ZegoMediaPlayerNetworkEvent) {
        print("[ZegoChorusManager] 播放器网络事件: \(event.rawValue)")
    }

    func onMediaPlayerPlayingProgress(_ mediaPlayer: ZegoMediaPlayer, progress: UInt64) {
        currentProgress = progress
        delegate?.chorusManager(self, mediaPlayerProgress: progress, duration: songDuration)

        // 点歌用户发送 SEI 进度
        if role == .songOwner {
            sendProgressSEI()
        }
    }
}
