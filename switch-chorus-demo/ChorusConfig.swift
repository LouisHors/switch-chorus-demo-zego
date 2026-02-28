//
//  ChorusConfig.swift
//  switch-chorus-demo
//
//  合唱 Demo 配置文件
//

import Foundation
import UIKit

// MARK: - ZEGO App 配置
/// 请替换为您在 ZEGO 控制台申请的 AppID 和 AppSign
struct ZegoAppConfig {

    // MARK: - UserDefaults Key
    private static let kZegoUserID = "kZegoUserID"

    // MARK: - SDK 配置

    /// ZEGO AppID (从 ZEGO 控制台获取)
    static let appID: UInt32 = 0  // TODO: 替换为您的 AppID

    /// ZEGO AppSign (从 ZEGO 控制台获取，服务端生成 Token 用)
    static let appSign: String = ""  // TODO: 替换为您的 AppSign

    /// Token (建议从服务端获取，这里仅用于测试)
    static var token: String = ""  // TODO: 从服务端获取 Token

    // MARK: - 用户 ID

    /// 用户 ID（自动生成并持久化存储）
    /// - 从 UserDefaults 读取，如果为空则生成新的并存储
    static var userID: String {
        get {
            // 尝试从 UserDefaults 读取
            if let savedUserID = UserDefaults.standard.string(forKey: kZegoUserID),
               !savedUserID.isEmpty {
                return savedUserID
            }

            // 生成新的 5 位随机字符串（英文+数字）
            let newUserID = generateRandomUserID()

            // 存储到 UserDefaults
            UserDefaults.standard.set(newUserID, forKey: kZegoUserID)
            UserDefaults.standard.synchronize()

            return newUserID
        }
    }

    /// 生成 5 位随机用户 ID（英文+数字组合）
    private static func generateRandomUserID() -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<5).map { _ in characters.randomElement()! })
    }
}

// MARK: - 角色定义
/// 用户角色枚举
enum ChorusRole: Int {
    case audience = 0    // 观众
    case anchor = 1      // 合唱者（主播）
    case songOwner = 2   // 点歌用户（主唱，额外推伴奏流）
}

// MARK: - 流 ID 后缀
struct StreamIDSuffix {
    /// 伴奏流后缀
    static let accompaniment = "_mv"
    /// 人声流后缀
    static let voiceSuffix = "_voice"
}

// MARK: - 媒体播放器行为类型
enum MediaPlayerBehavior: Int {
    case play = 0    // 播放
    case pause = 1   // 暂停
    case resume = 2  // 恢复
    case stop = 3    // 停止
}

// MARK: - SEI 消息 Key
struct SEIMessageKey {
    static let message = "message"
    static let progress = "kProgressKey"
    static let totalTime = "kTotalKey"
    static let pointTime = "kPointTimeKey"
    static let role = "kRole"
    static let state = "kState"
    static let resourceID = "kResourceID"
    static let behaviorType = "kBehaviorType"
    static let startTime = "kStartTime"
    // 用于业务切换
    static let switchTime = "kSwitchTime"
}

// MARK: - 流附加消息
struct StreamExtraMessage {
    static let mediaplayerStartInFuture = "Mediaplayer-StartInFuture"
    static let leaveRoom = "LeaveRoom"
}

// MARK: - 合唱常量配置
struct ChorusConstants {
    /// 观众拉流 jitterBuffer 范围 (ms)
    static let audienceJitterBufferRange: ClosedRange<Int> = 500...3000

    /// 合唱者拉流 jitterBuffer 范围 (ms)
    static let anchorJitterBufferRange: ClosedRange<Int> = 30...30

    /// 伴奏同步延迟阈值 (ms)
    static let accompanySyncThreshold: Int = 30

    /// 伴奏播放延迟时间 (ms) - 约定在未来某个时间点开始播放
    static let playDelay: Int64 = 5000

    /// 媒体播放器进度回调间隔 (ms)
    static let mediaPlayerProgressInterval: UInt64 = 60

    /// 人声流音频配置
    static let voiceAudioBitrate: UInt = 64

    /// 伴奏流音频配置
    static let accompanimentAudioBitrate: UInt = 128
}

// MARK: - 设计颜色常量
struct AppColors {
    static let bgPage = UIColor(hex: "#FAFAF9")
    static let bgCard = UIColor(hex: "#F1F1F1")
    static let bgElevated = UIColor(hex: "#FFFFFF")
    static let textPrimary = UIColor(hex: "#292524")
    static let textSecondary = UIColor(hex: "#78716C")
    static let textTertiary = UIColor(hex: "#A8A29E")
    static let accentTerracotta = UIColor(hex: "#EA580C")
    static let textOnAccent = UIColor(hex: "#FFFFFF")
    static let borderStrong = UIColor(hex: "#D6D3D1")
    static let borderSubtle = UIColor(hex: "#E7E5E4")
}

// MARK: - UIColor 扩展（支持十六进制颜色）
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}
