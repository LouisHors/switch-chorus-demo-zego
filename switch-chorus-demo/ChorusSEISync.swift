//
//  ChorusSEISync.swift
//  switch-chorus-demo
//
//  SEI 进度同步管理器 - 负责组装和发送同步信息
//

import Foundation
import ZegoExpressEngine

// MARK: - SEI 数据模型
/// 合唱进度同步的 SEI 数据结构
struct ChorusSEIData: Codable {
    /// 当前歌曲总时长，毫秒 ms
    let totalDuration: UInt64

    /// 当前进度，毫秒 ms
    let currentProgress: UInt64

    /// 是否正在唱歌
    let isSinging: Bool

    /// 切换队伍的时间点，毫秒 ms
    let switchTimeStamp: UInt64

    /// 当前所属队伍
    let currentTeam: String

    /// 当前播放的歌曲
    let currentSong: String

    /// 点歌时间戳（毫秒）- 用于解决同时点歌的竞争问题，更早点歌的人生效
    let pickSongTimestamp: UInt64

    /// 初始化方法
    init(totalDuration: UInt64 = 0,
         currentProgress: UInt64 = 0,
         isSinging: Bool = false,
         switchTimeStamp: UInt64 = 0,
         currentTeam: String = "",
         currentSong: String = "",
         pickSongTimestamp: UInt64 = 0) {
        self.totalDuration = totalDuration
        self.currentProgress = currentProgress
        self.isSinging = isSinging
        self.switchTimeStamp = switchTimeStamp
        self.currentTeam = currentTeam
        self.currentSong = currentSong
        self.pickSongTimestamp = pickSongTimestamp
    }

    /// 转换为 JSON Data
    func toJSONData() -> Data? {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys // 确保输出稳定
            return try encoder.encode(self)
        } catch {
            print("[SEISync] JSON 编码失败: \(error)")
            return nil
        }
    }

    /// 从 JSON Data 解析
    static func fromJSONData(_ data: Data) -> ChorusSEIData? {
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(ChorusSEIData.self, from: data)
        } catch {
            print("[SEISync] JSON 解码失败: \(error)")
            return nil
        }
    }
}

// MARK: - SEI 同步管理器
/// 负责在播放过程中定时发送 SEI 同步信息
class ChorusSEISyncManager {

    // MARK: - 属性

    /// ZEGO 引擎实例
    private let zego: ZegoExpressEngine

    /// 发送通道（默认主通道）
    private let channel: ZegoPublishChannel

    /// 当前 SEI 数据
    private var currentSEIData = ChorusSEIData()

    /// 最小发送间隔（毫秒）- 限制每秒不超过30次，约33ms
    private let minSendInterval: UInt64 = 100 // 使用 100ms 更稳妥

    /// 上次发送时间（毫秒）
    private var lastSendTime: UInt64 = 0

    /// 当前所属队伍
    private(set) var team: ChorusTeam?

    /// 当前歌曲
    private(set) var song: SongItem?

    /// 切换时间点（毫秒）
    private(set) var switchTimeStamp: UInt64 = 0

    /// 是否正在唱歌（播放中）
    private(set) var isSinging: Bool = false

    /// 点歌时间戳（毫秒）- 用于解决点歌竞争
    private(set) var pickSongTimestamp: UInt64 = 0

    /// 切换是否已经发生（确保只切换一次）
    private(set) var hasSwitched: Bool = false

    // MARK: - 初始化

    init(zego: ZegoExpressEngine, channel: ZegoPublishChannel = .main) {
        self.zego = zego
        self.channel = channel
    }

    // MARK: - 配置方法

    /// 设置当前队伍
    func setTeam(_ team: ChorusTeam?) {
        self.team = team
        updateSEIData()
    }

    /// 设置当前歌曲
    func setSong(_ song: SongItem?) {
        self.song = song
        updateSEIData()
    }

    /// 设置切换时间点（毫秒）
    func setSwitchTimeStamp(_ timestamp: UInt64) {
        self.switchTimeStamp = timestamp
        updateSEIData()
    }

    /// 设置是否正在唱歌
    func setIsSinging(_ singing: Bool) {
        self.isSinging = singing
        updateSEIData()
    }

    /// 设置点歌时间戳（毫秒）
    func setPickSongTimestamp(_ timestamp: UInt64) {
        self.pickSongTimestamp = timestamp
        updateSEIData()
    }

    /// 重置所有状态
    func reset() {
        team = nil
        song = nil
        switchTimeStamp = 0
        isSinging = false
        pickSongTimestamp = 0
        hasSwitched = false
        lastSendTime = 0
        currentSEIData = ChorusSEIData()
    }

    /// 生成切换时间戳
    /// 规则：总时长/2 ± 10000ms 的随机偏移
    /// - Parameter totalDuration: 歌曲总时长（毫秒）
    /// - Returns: 生成的切换时间戳（毫秒）
    func generateSwitchTimeStamp(totalDuration: UInt64) -> UInt64 {
        let halfDuration = totalDuration / 2
        // 生成 -10000 到 +10000 的随机偏移
        let randomOffset = Int64.random(in: -10000...10000)
        let switchTime: UInt64
        if randomOffset < 0 {
            switchTime = halfDuration - UInt64(-randomOffset)
        } else {
            switchTime = halfDuration + UInt64(randomOffset)
        }
        // 确保切换时间在有效范围内（不小于0，不大于总时长）
        switchTimeStamp = min(max(switchTime, 1000), totalDuration - 1000)
        updateSEIData()
        print("[SEISync] 生成切换时间戳: \(switchTimeStamp)ms (总时长: \(totalDuration)ms, 中点: \(halfDuration)ms)")
        return switchTimeStamp
    }

    /// 检查是否需要切换
    /// - Parameter currentProgress: 当前播放进度（毫秒）
    /// - Returns: 是否需要切换
    func shouldSwitch(currentProgress: UInt64) -> Bool {
        // 只有当切换时间戳已设置、未切换过、且进度超过切换点时，才需要切换
        guard switchTimeStamp > 0,
              !hasSwitched,
              currentProgress >= switchTimeStamp else {
            return false
        }
        return true
    }

    /// 标记切换已完成
    func markAsSwitched() {
        hasSwitched = true
        print("[SEISync] 切换已完成，标记 hasSwitched = true")
    }

    /// 切换 isSinging 状态
    func toggleSingingState() {
        isSinging = !isSinging
        updateSEIData()
        print("[SEISync] 切换 isSinging 状态: \(isSinging)")
    }

    // MARK: - SEI 发送

    /// 更新当前 SEI 数据（不发送）
    private func updateSEIData() {
        currentSEIData = ChorusSEIData(
            totalDuration: currentSEIData.totalDuration,
            currentProgress: currentSEIData.currentProgress, // 保持当前进度
            isSinging: isSinging,
            switchTimeStamp: switchTimeStamp,
            currentTeam: team?.rawValue ?? "",
            currentSong: song?.name ?? "",
            pickSongTimestamp: pickSongTimestamp
        )
    }

    /// 发送进度同步 SEI
    /// - Parameters:
    ///   - currentProgress: 当前进度（毫秒）
    ///   - totalDuration: 总时长（毫秒）
    ///   - force: 是否强制发送（忽略时间间隔限制）
    func sendProgressSync(currentProgress: UInt64, totalDuration: UInt64, force: Bool = false) {
        let currentTime = currentTimestamp()

        // 检查发送间隔
        if !force && (currentTime - lastSendTime) < minSendInterval {
            return
        }

        // 更新当前进度和总时长
        currentSEIData = ChorusSEIData(
            totalDuration: totalDuration,
            currentProgress: currentProgress,
            isSinging: isSinging,
            switchTimeStamp: switchTimeStamp,
            currentTeam: team?.rawValue ?? "",
            currentSong: song?.name ?? "",
            pickSongTimestamp: pickSongTimestamp
        )

        // 转换为 JSON 并发送
        guard let data = currentSEIData.toJSONData() else {
            print("[SEISync] SEI 数据编码失败")
            return
        }

        // 临时日志：打印发送的 SEI 内容
        print("[SEI] ➡️ 发送: song=\(currentSEIData.currentSong), progress=\(currentSEIData.currentProgress)ms, total=\(currentSEIData.totalDuration)ms, isSinging=\(currentSEIData.isSinging), team=\(currentSEIData.currentTeam), pickTS=\(currentSEIData.pickSongTimestamp), switchTS=\(currentSEIData.switchTimeStamp), hasSwitched=\(hasSwitched)")

        // 发送 SEI 到主通道（观众拉主路，需要收到SEI）
        zego.sendSEI(data, channel: .main)
        // 发送 SEI 到辅通道（主播拉辅路，需要收到SEI）
        zego.sendSEI(data, channel: .aux)
        lastSendTime = currentTime

        // 调试日志（每5秒打印一次）
        if currentProgress % 5000 < 100 {
            print("[SEISync] 发送 SEI: progress=\(currentProgress)ms, team=\(team?.rawValue ?? "none"), singing=\(isSinging)")
        }
    }

    /// 获取当前 Unix 时间戳（毫秒）
    private func currentTimestamp() -> UInt64 {
        return UInt64(Date().timeIntervalSince1970 * 1000)
    }
}

// MARK: - 便捷扩展

extension ChorusSEISyncManager {
    /// 从播放器状态发送进度同步
    /// - Parameters:
    ///   - player: 伴奏播放器控制器
    ///   - force: 是否强制发送
    func syncWithPlayer(_ player: AccompanimentPlayerController, force: Bool = false) {
        let progressMs = UInt64(player.currentTime * 1000)
        // 使用缓存的总时长，避免频繁调用同步耗时方法
        let totalMs = UInt64(player.cachedTotalTime * 1000)
        sendProgressSync(currentProgress: progressMs, totalDuration: totalMs, force: force)
    }
}

// MARK: - SEI 解析器
/// 负责解析接收到的 SEI 数据
enum ChorusSEIParser {

    /// 解析 SEI Data
    /// - Parameter data: 接收到的 SEI 数据
    /// - Returns: 解析后的 SEI 数据模型
    static func parse(_ data: Data) -> ChorusSEIData? {
        return ChorusSEIData.fromJSONData(data)
    }

    /// 进度差异检查
    /// - Parameters:
    ///   - localProgress: 本地进度（毫秒）
    ///   - remoteProgress: 远程进度（毫秒）
    ///   - threshold: 阈值（毫秒），默认 100ms
    /// - Returns: 是否需要对齐（差异超过阈值）
    static func needsAlignment(localProgress: UInt64, remoteProgress: UInt64, threshold: UInt64 = 100) -> Bool {
        let diff = localProgress > remoteProgress ? localProgress - remoteProgress : remoteProgress - localProgress
        return diff > threshold
    }
}