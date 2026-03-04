# ZegoMediaPlayer 伴奏播放器实施计划

> **For Claude:** REQUIRED SUB-SKILL: Use horspowers:executing-plans to implement this plan task-by-task.

**日期**: 2026-03-04
**关联设计文档**: [2026-03-04-design-mediaplayer.md](./2026-03-04-design-mediaplayer.md)
**关联 Epic**: switch-chorus-demo-m67

## 目标

基于已验证的 ZegoMediaPlayer SDK API，实现完整的伴奏播放器，包含控制器层、视图层和集成层。

## 架构方案

采用 MVC 分层架构：
- **AccompanimentPlayerController**: 封装 SDK 调用，管理播放状态机，处理事件回调
- **PlayerControlView**: 橙色渐变卡片 UI，包含进度条和控制按钮
- **TeamChorusViewController**: 集成播放器，处理业务逻辑协调

## 技术栈

- Swift 5.0
- UIKit
- ZegoExpressEngine SDK (ZegoMediaPlayer)

---

## Task 1: 创建 AccompanimentPlayerController

**Files:**
- Create: `switch-chorus-demo/AccompanimentPlayerController.swift`

**实现步骤：**

### Step 1: 创建文件并添加协议定义

```swift
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
```

### Step 2: 实现控制器类骨架

```swift
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
    }

    private func destroyMediaPlayer() {
        if let player = mediaPlayer {
            player.stop()
            ZegoExpressEngine.shared().destroyMediaPlayer(player)
            mediaPlayer = nil
        }
    }
}
```

### Step 3: 实现播放控制方法

```swift
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
        player.seekTo(milliseconds) { [weak self] errorCode in
            if errorCode != 0 {
                self?.delegate?.player(self!, didEncounterError: .seekFailed(errorCode))
            }
        }
    }
}
```

### Step 4: 实现查询属性

```swift
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
```

### Step 5: 实现 SDK 事件回调

```swift
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
```

**Step 6: Commit**

```bash
git add switch-chorus-demo/AccompanimentPlayerController.swift
git commit -m "feat: 创建 AccompanimentPlayerController 控制器

- 封装 ZegoMediaPlayer SDK 调用
- 实现播放状态机管理
- 实现播放控制方法 (play/pause/stop/seek)
- 实现进度回调处理"
```

---

## Task 2: 创建 PlayerControlView

**Files:**
- Create: `switch-chorus-demo/PlayerControlView.swift`

### Step 1: 创建协议和类骨架

```swift
import UIKit

protocol PlayerControlViewDelegate: AnyObject {
    func playerControlViewDidTapPlay(_ view: PlayerControlView)
    func playerControlViewDidTapPause(_ view: PlayerControlView)
    func playerControlViewDidTapStop(_ view: PlayerControlView)
    func playerControlView(_ view: PlayerControlView, didSeekTo progress: Double)
}

class PlayerControlView: UIView {

    weak var delegate: PlayerControlViewDelegate?

    // MARK: - 子视图
    private let containerView = UIView()
    private let gradientLayer = CAGradientLayer()
    private let songNameLabel = UILabel()
    private let timeLabel = UILabel()
    private let progressSlider = UISlider()
    private let playButton = UIButton()
    private let stopButton = UIButton()

    // MARK: - 状态
    private var isPlaying = false
    private var isDraggingSlider = false
}
```

### Step 2: 实现初始化方法

```swift
extension PlayerControlView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .clear

        // 容器视图
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.layer.cornerRadius = 20
        containerView.layer.masksToBounds = true
        addSubview(containerView)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 180)
        ])

        // 设置渐变背景
        setupGradientBackground()

        // 设置子视图
        setupSongNameLabel()
        setupTimeLabel()
        setupProgressSlider()
        setupButtons()
    }

    private func setupGradientBackground() {
        gradientLayer.colors = [
            UIColor(red: 0.918, green: 0.345, blue: 0.047, alpha: 1).cgColor,  // #EA580C
            UIColor(red: 0.851, green: 0.467, blue: 0.024, alpha: 1).cgColor   // #D97706
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.locations = [0, 1]
        containerView.layer.insertSublayer(gradientLayer, at: 0)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = containerView.bounds
    }
}
```

### Step 3: 实现子视图设置

```swift
extension PlayerControlView {

    private func setupSongNameLabel() {
        songNameLabel.translatesAutoresizingMaskIntoConstraints = false
        songNameLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        songNameLabel.textColor = .white
        songNameLabel.textAlignment = .center
        songNameLabel.text = "请选择歌曲"
        containerView.addSubview(songNameLabel)

        NSLayoutConstraint.activate([
            songNameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            songNameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            songNameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24)
        ])
    }

    private func setupTimeLabel() {
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .medium)
        timeLabel.textColor = .white.withAlphaComponent(0.9)
        timeLabel.text = "00:00 - 00:00"
        containerView.addSubview(timeLabel)

        NSLayoutConstraint.activate([
            timeLabel.topAnchor.constraint(equalTo: songNameLabel.bottomAnchor, constant: 12),
            timeLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor)
        ])
    }

    private func setupProgressSlider() {
        progressSlider.translatesAutoresizingMaskIntoConstraints = false
        progressSlider.minimumTrackTintColor = .white
        progressSlider.maximumTrackTintColor = .white.withAlphaComponent(0.3)
        progressSlider.thumbTintColor = .white
        progressSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        progressSlider.addTarget(self, action: #selector(sliderTouchBegan), for: .touchDown)
        progressSlider.addTarget(self, action: #selector(sliderTouchEnded), for: [.touchUpInside, .touchUpOutside])
        containerView.addSubview(progressSlider)

        NSLayoutConstraint.activate([
            progressSlider.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 8),
            progressSlider.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            progressSlider.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24)
        ])
    }

    private func setupButtons() {
        // 播放/暂停按钮
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playButton.tintColor = .white
        playButton.backgroundColor = .white.withAlphaComponent(0.15)
        playButton.layer.cornerRadius = 20
        playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        containerView.addSubview(playButton)

        // 停止按钮
        stopButton.translatesAutoresizingMaskIntoConstraints = false
        stopButton.setImage(UIImage(systemName: "stop.fill"), for: .normal)
        stopButton.tintColor = .white
        stopButton.backgroundColor = .white.withAlphaComponent(0.15)
        stopButton.layer.cornerRadius = 20
        stopButton.addTarget(self, action: #selector(stopButtonTapped), for: .touchUpInside)
        containerView.addSubview(stopButton)

        NSLayoutConstraint.activate([
            playButton.topAnchor.constraint(equalTo: progressSlider.bottomAnchor, constant: 16),
            playButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 40),
            playButton.heightAnchor.constraint(equalToConstant: 40),

            stopButton.topAnchor.constraint(equalTo: progressSlider.bottomAnchor, constant: 16),
            stopButton.leadingAnchor.constraint(equalTo: playButton.trailingAnchor, constant: 20),
            stopButton.widthAnchor.constraint(equalToConstant: 40),
            stopButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
}
```

### Step 4: 实现事件处理和更新方法

```swift
extension PlayerControlView {

    @objc private func playButtonTapped() {
        if isPlaying {
            delegate?.playerControlViewDidTapPause(self)
        } else {
            delegate?.playerControlViewDidTapPlay(self)
        }
    }

    @objc private func stopButtonTapped() {
        delegate?.playerControlViewDidTapStop(self)
    }

    @objc private func sliderValueChanged() {
        let progress = Double(progressSlider.value)
        updateTimeLabel(progress: progress)
    }

    @objc private func sliderTouchBegan() {
        isDraggingSlider = true
    }

    @objc private func sliderTouchEnded() {
        isDraggingSlider = false
        let progress = Double(progressSlider.value)
        delegate?.playerControlView(self, didSeekTo: progress)
    }

    private func updateTimeLabel(progress: Double) {
        let totalSeconds = Int(progress * 300) // 临时计算，实际需要传入总时长
        let currentSeconds = Int(progress * Double(totalSeconds))

        let currentFormatted = formatTime(currentSeconds)
        let totalFormatted = formatTime(totalSeconds)
        timeLabel.text = "\(currentFormatted) - \(totalFormatted)"
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

// MARK: - 公开更新方法
extension PlayerControlView {

    func setSongName(_ name: String) {
        songNameLabel.text = name
    }

    func setCurrentTime(_ currentTime: TimeInterval, totalTime: TimeInterval) {
        guard !isDraggingSlider else { return }

        let progress = totalTime > 0 ? currentTime / totalTime : 0
        progressSlider.value = Float(progress)

        let currentFormatted = formatTime(Int(currentTime))
        let totalFormatted = formatTime(Int(totalTime))
        timeLabel.text = "\(currentFormatted) - \(totalFormatted)"
    }

    func setPlayButtonState(_ isPlaying: Bool) {
        self.isPlaying = isPlaying
        let imageName = isPlaying ? "pause.fill" : "play.fill"
        playButton.setImage(UIImage(systemName: imageName), for: .normal)
    }
}
```

**Step 5: Commit**

```bash
git add switch-chorus-demo/PlayerControlView.swift
git commit -m "feat: 创建 PlayerControlView 播放器 UI 组件

- 实现橙色渐变卡片设计
- 添加歌曲名称标签
- 实现进度条滑块和时间显示
- 添加播放/暂停/停止按钮"
```

---

## Task 3: 在 TeamChorusViewController 中集成播放器

**Files:**
- Modify: `switch-chorus-demo/TeamChorus/TeamChorusViewController.swift`
- Modify: `switch-chorus-demo/TeamChorus/TeamChorusView.swift`

### Step 1: 在 TeamChorusView 中添加播放器视图

```swift
// 在 TeamChorusView 中添加
class TeamChorusView: UIView {

    // ... 现有代码 ...

    /// 播放器控制视图
    let playerControlView = PlayerControlView()

    private func setupUI() {
        // ... 现有代码 ...

        // 添加播放器视图（放在合唱队伍区域上方）
        playerControlView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(playerControlView)

        NSLayoutConstraint.activate([
            playerControlView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            playerControlView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            playerControlView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])

        // 调整 userList 的 topAnchor
        // userList.topAnchor.constraint(equalTo: playerControlView.bottomAnchor, constant: 16)
    }
}
```

### Step 2: 在 TeamChorusViewController 中添加播放器控制器

```swift
// 在 TeamChorusViewController 中添加属性
class TeamChorusViewController: UIViewController {

    // ... 现有代码 ...

    /// 伴奏播放器控制器
    private let accompanimentPlayer = AccompanimentPlayerController()
}
```

### Step 3: 在 viewDidLoad 中设置播放器

```swift
extension TeamChorusViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCallbacks()
        setupAudioConfig()
        setupPlayer() // 新增
    }

    private func setupPlayer() {
        accompanimentPlayer.delegate = self
        chorusView.playerControlView.delegate = self
    }
}
```

### Step 4: 实现播放器委托

```swift
// MARK: - AccompanimentPlayerDelegate
extension TeamChorusViewController: AccompanimentPlayerDelegate {

    func player(_ player: AccompanimentPlayerController, didUpdateState state: PlayerState) {
        DispatchQueue.main.async { [weak self] in
            switch state {
            case .playing:
                self?.chorusView.playerControlView.setPlayButtonState(true)
            case .paused, .idle, .ended:
                self?.chorusView.playerControlView.setPlayButtonState(false)
            default:
                break
            }
        }
    }

    func player(_ player: AccompanimentPlayerController, didUpdateProgress currentTime: TimeInterval, totalTime: TimeInterval) {
        DispatchQueue.main.async { [weak self] in
            self?.chorusView.playerControlView.setCurrentTime(currentTime, totalTime: totalTime)
        }
    }

    func player(_ player: AccompanimentPlayerController, didEncounterError error: PlayerError) {
        DispatchQueue.main.async { [weak self] in
            // 简单显示错误，可以后续优化
            print("[Player] Error: \(error)")
        }
    }
}
```

### Step 5: 实现播放器视图委托

```swift
// MARK: - PlayerControlViewDelegate
extension TeamChorusViewController: PlayerControlViewDelegate {

    func playerControlViewDidTapPlay(_ view: PlayerControlView) {
        switch accompanimentPlayer.currentState {
        case .ready, .paused:
            accompanimentPlayer.play()
        case .idle, .ended:
            // 如果有已选歌曲，重新加载播放
            if let song = currentSong {
                accompanimentPlayer.loadSong(song) { [weak self] result in
                    if case .success = result {
                        self?.accompanimentPlayer.play()
                    }
                }
            }
        default:
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
        accompanimentPlayer.seek(to: progress)
    }
}
```

### Step 6: 更新选歌回调

```swift
// MARK: - SongPickerDelegate
extension TeamChorusViewController: SongPickerDelegate {

    func songPicker(_ picker: SongPickerViewController, didSelectSong song: SongItem) {
        print("[TeamChorus] 选中歌曲: \(song.name)")
        currentSong = song

        // 更新 UI
        chorusView.playerControlView.setSongName(song.name)

        // 自动加载歌曲
        accompanimentPlayer.loadSong(song) { [weak self] result in
            switch result {
            case .success:
                print("[TeamChorus] 歌曲加载成功")
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
```

**Step 7: Commit**

```bash
git add switch-chorus-demo/TeamChorus/TeamChorusViewController.swift
git add switch-chorus-demo/TeamChorus/TeamChorusView.swift
git commit -m "feat: 集成伴奏播放器到合唱页面

- 在 TeamChorusView 中添加 PlayerControlView
- 在 TeamChorusViewController 中创建 AccompanimentPlayerController
- 实现播放器委托回调，同步 UI 状态
- 点歌后自动加载歌曲"
```

---

## 测试验证

### 手动测试步骤

1. **编译检查**
   ```bash
   xcodebuild -project switch-chorus-demo.xcodeproj -scheme switch-chorus-demo -configuration Debug
   ```

2. **功能测试**
   - 运行 App，进入合唱页面
   - 点击"点歌"按钮，选择一首歌曲
   - 验证歌曲名称显示在播放器卡片中
   - 点击播放按钮，验证音乐播放
   - 拖动进度条，验证跳转功能
   - 点击暂停/停止按钮，验证控制功能

3. **集成测试**
   - 上麦推流后，验证伴奏自动播放
   - 验证对方能听到伴奏（需要两台设备）

### 预期行为

- 点歌后自动加载歌曲
- 播放状态与按钮图标同步
- 进度条实时更新（100ms 间隔）
- 时间显示格式为 "01:23 - 04:56"

---

## 风险与注意事项

1. **SDK 版本兼容性**
   - ZegoMediaPlayer API 在 SDK 2.1.0+ 可用
   - 确保项目使用的 SDK 版本符合要求

2. **伴奏混入推流**
   - 需要调用 `enableAux(true)` 才能让对方听到伴奏
   - 这应该在播放器创建后立即执行

3. **资源释放**
   - 页面退出时需要停止播放器并释放资源
   - 已在 `deinit` 中处理

---

## 验收标准

- [ ] AccompanimentPlayerController 封装完整，状态机工作正常
- [ ] PlayerControlView UI 与设计一致，橙色渐变效果正确
- [ ] 播放器控制功能正常（播放/暂停/停止/进度跳转）
- [ ] 进度回调准确，时间显示更新及时
- [ ] 点歌后自动加载，上麦后自动播放
- [ ] 代码无编译警告，内存无泄漏
