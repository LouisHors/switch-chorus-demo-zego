//
//  AccompanimentPlayerController.swift
//  switch-chorus-demo
//
//  伴奏播放器控制器 - 封装 ZegoMediaPlayer SDK
//

import Foundation
import ZegoExpressEngine

// MARK: - 播放状态枚举
enum PlayerState {
    case idle
    case loading
    case ready
    case playing
    case paused
    case ended
}

// MARK: - 错误类型
enum PlayerError: Error {
    case loadFailed(Int32)
    case seekFailed(Int32)
    case invalidState
}

// MARK: - 委托协议
protocol AccompanimentPlayerDelegate: AnyObject {
    func player(_ player: AccompanimentPlayerController, didUpdateState state: PlayerState)
    func player(_ player: AccompanimentPlayerController, didUpdateProgress currentTime: TimeInterval, totalTime: TimeInterval)
    func player(_ player: AccompanimentPlayerController, didEncounterError error: PlayerError)
}

// MARK: - 伴奏播放器控制器
class AccompanimentPlayerController: NSObject {

    // MARK: - 属性
    weak var delegate: AccompanimentPlayerDelegate?
    private(set) var currentState: PlayerState = .idle
    private var mediaPlayer: ZegoMediaPlayer?
    private var currentSong: SongItem?

    // MARK: - 生命周期
    override init() {
        super.init()
        createMediaPlayer()
    }

    deinit {
        destroyMediaPlayer()
    }

    // MARK: - 私有方法
    private func createMediaPlayer() {
        mediaPlayer = ZegoExpressEngine.shared().createMediaPlayer()
        mediaPlayer?.setEventHandler(self)
        mediaPlayer?.setProgressInterval(100) // 100ms 回调
        mediaPlayer?.enableAux(true) // 重要：让对方听到伴奏
    }

    private func destroyMediaPlayer() {
        if let player = mediaPlayer {
            player.stop()
            ZegoExpressEngine.shared().destroy(player)
            mediaPlayer = nil
        }
    }
}

// MARK: - 播放控制方法
extension AccompanimentPlayerController {

    func loadSong(_ song: SongItem, completion: ((Result<Void, PlayerError>) -> Void)? = nil) {
        guard let player = mediaPlayer else {
            completion?(.failure(.invalidState))
            return
        }

        currentSong = song
        updateState(.loading)

        // 先停止当前播放
        player.stop()

        // 加载资源
        player.loadResource(song.filePath) { [weak self] errorCode in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if errorCode == 0 {
                    self.updateState(.ready)
                    completion?(.success(()))
                } else {
                    self.updateState(.idle)
                    completion?(.failure(.loadFailed(errorCode)))
                }
            }
        }
    }

    func play() {
        guard let player = mediaPlayer else { return }
        player.start()
        updateState(.playing)
    }

    func pause() {
        guard let player = mediaPlayer else { return }
        player.pause()
        updateState(.paused)
    }

    func resume() {
        guard let player = mediaPlayer else { return }
        player.resume()
        updateState(.playing)
    }

    func stop() {
        guard let player = mediaPlayer else { return }
        player.stop()
        updateState(.idle)
    }

    func seek(to progress: TimeInterval) {
        guard let player = mediaPlayer else { return }
        let milliseconds = UInt64(progress * 1000)
        player.seek(to: milliseconds) { [weak self] errorCode in
            if errorCode != 0 {
                self?.delegate?.player(self!, didEncounterError: .seekFailed(errorCode))
            }
        }
    }
}

// MARK: - 查询属性
extension AccompanimentPlayerController {

    var currentTime: TimeInterval {
        guard let player = mediaPlayer else { return 0 }
        return TimeInterval(player.currentProgress()) / 1000.0
    }

    var totalTime: TimeInterval {
        guard let player = mediaPlayer else { return 0 }
        return TimeInterval(player.totalDuration()) / 1000.0
    }

    var progress: Double {
        let total = totalTime
        guard total > 0 else { return 0 }
        return currentTime / total
    }

    private func updateState(_ newState: PlayerState) {
        currentState = newState
        delegate?.player(self, didUpdateState: newState)
    }
}

// MARK: - SDK 事件回调
extension AccompanimentPlayerController: ZegoMediaPlayerEventHandler {

    func mediaPlayer(_ mediaPlayer: ZegoMediaPlayer, stateUpdate state: ZegoMediaPlayerState, errorCode: Int32) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            switch state {
            case .noPlay:
                self.updateState(.idle)
            case .playing:
                self.updateState(.playing)
            case .pausing:
                self.updateState(.paused)
            case .playEnded:
                self.updateState(.ended)
            @unknown default:
                break
            }
        }
    }

    func mediaPlayer(_ mediaPlayer: ZegoMediaPlayer, playingProgress millisecond: UInt64) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let current = TimeInterval(millisecond) / 1000.0
            let total = self.totalTime
            self.delegate?.player(self, didUpdateProgress: current, totalTime: total)
        }
    }
}
