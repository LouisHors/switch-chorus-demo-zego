# ZegoMediaPlayer 伴奏播放器设计文档

## 基本信息

- **创建时间**: 2026-03-04
- **设计者**: Claude Code
- **状态**: 设计中
- **相关 Issue**: 用于 horspowers 功能验证

## 设计背景

在双人轮唱合唱场景中，用户点歌后需要播放伴奏音乐。本设计基于 ZegoExpressEngine SDK 提供的 `ZegoMediaPlayer` 类，封装一个完整的伴奏播放器，提供播放控制、进度回调等能力。

## 已验证的 SDK API

### 创建与销毁
```swift
// ZegoExpressEngine+MediaPlayer.h
let mediaPlayer = ZegoExpressEngine.shared().createMediaPlayer()  // 返回 nullable
ZegoExpressEngine.shared().destroyMediaPlayer(mediaPlayer)
```

### 核心播放控制
```swift
// ZegoExpressDefines.h:4603-4956
mediaPlayer.loadResource(path) { errorCode in }
mediaPlayer.loadResourceWithPosition(path, startPosition: 0) { errorCode in }
mediaPlayer.start()
mediaPlayer.pause()
mediaPlayer.resume()
mediaPlayer.stop()
mediaPlayer.seekTo(millisecond) { errorCode in }
```

### 进度与时间
```swift
mediaPlayer.setProgressInterval(100)  // 100ms 回调，默认 1000ms
mediaPlayer.totalDuration()     // UInt64, 单位毫秒
mediaPlayer.currentProgress()   // UInt64, 单位毫秒
```

### 音量与混音（合唱关键）
```swift
mediaPlayer.setVolume(60)       // 0-200，默认 60
mediaPlayer.setPlayVolume(60)   // 本地播放音量
mediaPlayer.setPublishVolume(60) // 推流音量
mediaPlayer.enableAux(true)     // 混入推流（重要！）
mediaPlayer.muteLocal(false)    // 本地是否静音
```

### 事件回调协议
```swift
// ZegoExpressEventHandler.h:1161-1260
protocol ZegoMediaPlayerEventHandler {
    func mediaPlayer(_ mediaPlayer: ZegoMediaPlayer, stateUpdate state: ZegoMediaPlayerState, errorCode: Int)
    func mediaPlayer(_ mediaPlayer: ZegoMediaPlayer, playingProgress millisecond: UInt64)
    func mediaPlayer(_ mediaPlayer: ZegoMediaPlayer, networkEvent: ZegoMediaPlayerNetworkEvent)
}
```

### 播放状态枚举
```swift
// ZegoExpressDefines.h:1404-1412
enum ZegoMediaPlayerState {
    case noPlay     = 0  // 未播放
    case playing    = 1  // 播放中
    case pausing    = 2  // 暂停中
    case playEnded  = 3  // 播放结束
}
```

## 架构设计

### 整体结构

```
┌─────────────────────────────────────────────────────────┐
│           AccompanimentPlayerController                 │
│                    (伴奏播放器控制器)                      │
├─────────────────────────────────────────────────────────┤
│  职责：                                                  │
│  • 管理 ZegoMediaPlayer 生命周期                         │
│  • 封装播放控制为 Swift-friendly API                     │
│  • 处理 SDK 事件回调并转换为闭包/Delegate                 │
│  • 维护播放状态机                                        │
│  • 自动 enableAux 混入推流                               │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│              PlayerControlView                          │
│         橙色渐变卡片 (参照 组队合唱.pen)                   │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────┐   │
│  │           歌曲名称标签 (18pt, 白色, 加粗)          │   │
│  ├─────────────────────────────────────────────────┤   │
│  │   00:01  ──────●──────────  03:30               │   │
│  │   当前时间  进度条滑块        总时长               │   │
│  ├─────────────────────────────────────────────────┤   │
│  │        [▶播放]  [⏭下一首]  [⏹停止]               │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### 状态机

```
                    ┌───────────┐
         ┌─────────│   Idle    │◄────────┐
         │         │  (未加载)  │         │
    load │         └─────┬─────┘         │ stop
         │               │ load          │
         ▼               ▼               │
    ┌───────────┐   ┌───────────┐        │
    │  Loading  │──►│  Ready    │────────┘
    │  (加载中)  │   │  (已就绪)  │
    └───────────┘   └─────┬─────┘
                          │ start
                          ▼
                   ┌───────────┐
              ┌───│  Playing  │◄────┐
              │   │  (播放中)  │     │
         pause│   └─────┬─────┘     │resume
              │         │ pause     │
              │         ▼           │
              └──►┌───────────┐     │
                  │  Paused   │─────┘
                  │  (已暂停)  │
                  └─────┬─────┘
                        │ finish
                        ▼
                   ┌───────────┐
                   │   Ended   │────► Idle (stop)
                   │  (已结束)  │
                   └───────────┘
```

## 接口设计

### AccompanimentPlayerController

```swift
protocol AccompanimentPlayerDelegate: AnyObject {
    func player(_ player: AccompanimentPlayerController, didUpdateState state: PlayerState)
    func player(_ player: AccompanimentPlayerController, didUpdateProgress currentTime: TimeInterval, totalTime: TimeInterval)
    func player(_ player: AccompanimentPlayerController, didEncounterError error: PlayerError)
}

class AccompanimentPlayerController: NSObject {
    // MARK: - 属性
    weak var delegate: AccompanimentPlayerDelegate?
    private(set) var currentState: PlayerState = .idle
    private(set) var currentSong: SongItem?

    // MARK: - 控制方法
    func loadSong(_ song: SongItem, completion: ((Result<Void, PlayerError>) -> Void)?)
    func play()
    func pause()
    func stop()
    func seek(to progress: TimeInterval)

    // MARK: - 查询方法
    var currentTime: TimeInterval { get }
    var totalTime: TimeInterval { get }
    var progress: Double { get }  // 0.0 ~ 1.0
}

enum PlayerState {
    case idle
    case loading
    case ready
    case playing
    case paused
    case ended
}

enum PlayerError: Error {
    case loadFailed(Int)
    case seekFailed(Int)
    case invalidState
}
```

### PlayerControlView

```swift
protocol PlayerControlViewDelegate: AnyObject {
    func playerControlViewDidTapPlay(_ view: PlayerControlView)
    func playerControlViewDidTapPause(_ view: PlayerControlView)
    func playerControlViewDidTapStop(_ view: PlayerControlView)
    func playerControlView(_ view: PlayerControlView, didSeekTo progress: Double)
}

class PlayerControlView: UIView {
    weak var delegate: PlayerControlViewDelegate?

    // MARK: - 更新方法
    func setSongName(_ name: String)
    func setCurrentTime(_ time: TimeInterval, totalTime: TimeInterval)
    func setProgress(_ progress: Double)  // 0.0 ~ 1.0
    func setPlayButtonState(_ isPlaying: Bool)
}
```

## 技术要点

### 1. 伴奏混入推流
```swift
// 播放器初始化后必须开启
mediaPlayer.enableAux(true)
```
这是合唱场景的关键：伴奏必须混入本地推流，对方才能听到伴奏。

### 2. 进度回调精度
```swift
// 设置 100ms 回调间隔，满足歌词同步需求
mediaPlayer.setProgressInterval(100)
```

### 3. 资源加载规范
- 使用 `loadResourceWithPosition` 支持从指定位置开始
- 加载前必须先 `stop` 当前播放
- 回调中处理加载结果错误码

### 4. 错误处理
- SDK 错误码通过回调返回
- 需要转换为业务友好的错误类型
- UI 层展示用户友好的错误提示

## 实施计划

### Phase 1: 控制器实现
1. 创建 `AccompanimentPlayerController.swift`
2. 实现 ZegoMediaPlayer 生命周期管理
3. 实现播放控制方法
4. 实现事件回调处理

### Phase 2: 视图实现
1. 创建 `PlayerControlView.swift`
2. 实现橙色渐变卡片 UI
3. 实现进度条和按钮交互
4. 实现委托回调

### Phase 3: 集成
1. 在 `TeamChorusViewController` 中集成播放器
2. 点歌后自动加载并播放
3. 处理播放器状态与合唱逻辑的协调

## 影响范围

- **新增文件**:
  - `switch-chorus-demo/AccompanimentPlayerController.swift`
  - `switch-chorus-demo/PlayerControlView.swift`

- **修改文件**:
  - `switch-chorus-demo/TeamChorusViewController.swift`（集成播放器）
  - `switch-chorus-demo/TeamChorusView.swift`（添加播放器视图）

## 相关文档

- [双人轮唱的合唱场景方案](./双人轮唱的合唱场景方案.md)
- ZegoExpressEngine SDK 头文件：`lib/ZegoExpressEngine.xcframework/Headers/ZegoExpressDefines.h`

## 备注

- 本实现用于验证 horspowers 的 brainstorming -> design -> plan -> implement 流程
- 保持代码简洁，专注于核心播放功能
- 不实现歌词同步功能（超出当前需求范围）
