//
//  PlayerControlView.swift
//  switch-chorus-demo
//
//  播放器控制视图
//  橙色渐变卡片 UI，包含歌曲信息、进度条和控制按钮
//

import UIKit

// MARK: - 委托协议
protocol PlayerControlViewDelegate: AnyObject {
    func playerControlViewDidTapPlay(_ view: PlayerControlView)
    func playerControlViewDidTapPause(_ view: PlayerControlView)
    func playerControlViewDidTapStop(_ view: PlayerControlView)
    func playerControlView(_ view: PlayerControlView, didSeekTo progress: Double)
}

// MARK: - 播放器控制视图
class PlayerControlView: UIView {

    weak var delegate: PlayerControlViewDelegate?

    // MARK: - 子视图
    private let containerView = UIView()
    private let gradientLayer = CAGradientLayer()
    private let songNameLabel = UILabel()
    private let timeLabel = UILabel()
    private let progressSlider = UISlider()
    private let playButton = UIButton()
    private let pauseButton = UIButton()
    private let stopButton = UIButton()

    // MARK: - 状态
    private var isDraggingSlider = false
    private var currentTotalTime: TimeInterval = 0

    // MARK: - 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - UI 设置
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

    // MARK: - 子视图设置
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
        progressSlider.isExclusiveTouch = true // 修复：防止滑动时触发其他按钮
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
        // 播放按钮
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playButton.tintColor = .white
        playButton.backgroundColor = .white.withAlphaComponent(0.15)
        playButton.layer.cornerRadius = 20
        playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        containerView.addSubview(playButton)

        // 暂停按钮
        pauseButton.translatesAutoresizingMaskIntoConstraints = false
        pauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        pauseButton.tintColor = .white
        pauseButton.backgroundColor = .white.withAlphaComponent(0.15)
        pauseButton.layer.cornerRadius = 20
        pauseButton.addTarget(self, action: #selector(pauseButtonTapped), for: .touchUpInside)
        containerView.addSubview(pauseButton)

        // 停止按钮
        stopButton.translatesAutoresizingMaskIntoConstraints = false
        stopButton.setImage(UIImage(systemName: "stop.fill"), for: .normal)
        stopButton.tintColor = .white
        stopButton.backgroundColor = .white.withAlphaComponent(0.15)
        stopButton.layer.cornerRadius = 20
        stopButton.addTarget(self, action: #selector(stopButtonTapped), for: .touchUpInside)
        containerView.addSubview(stopButton)

        NSLayoutConstraint.activate([
            // 播放按钮 - 左侧
            playButton.topAnchor.constraint(equalTo: progressSlider.bottomAnchor, constant: 16),
            playButton.trailingAnchor.constraint(equalTo: containerView.centerXAnchor, constant: -30),
            playButton.widthAnchor.constraint(equalToConstant: 40),
            playButton.heightAnchor.constraint(equalToConstant: 40),

            // 暂停按钮 - 中间
            pauseButton.topAnchor.constraint(equalTo: progressSlider.bottomAnchor, constant: 16),
            pauseButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            pauseButton.widthAnchor.constraint(equalToConstant: 40),
            pauseButton.heightAnchor.constraint(equalToConstant: 40),

            // 停止按钮 - 右侧
            stopButton.topAnchor.constraint(equalTo: progressSlider.bottomAnchor, constant: 16),
            stopButton.leadingAnchor.constraint(equalTo: containerView.centerXAnchor, constant: 30),
            stopButton.widthAnchor.constraint(equalToConstant: 40),
            stopButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    // MARK: - 事件处理
    @objc private func playButtonTapped() {
        delegate?.playerControlViewDidTapPlay(self)
    }

    @objc private func pauseButtonTapped() {
        delegate?.playerControlViewDidTapPause(self)
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
        let currentSeconds = Int(progress * currentTotalTime)
        let totalSeconds = Int(currentTotalTime)

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
        currentTotalTime = totalTime

        guard !isDraggingSlider else { return }

        let progress = totalTime > 0 ? currentTime / totalTime : 0
        progressSlider.value = Float(progress)

        let currentFormatted = formatTime(Int(currentTime))
        let totalFormatted = formatTime(Int(totalTime))
        timeLabel.text = "\(currentFormatted) - \(totalFormatted)"
    }

    func setButtonStates(isPlaying: Bool) {
        // 根据播放状态显示/隐藏按钮
        playButton.isHidden = isPlaying
        pauseButton.isHidden = !isPlaying
    }

    func resetUI() {
        // 重置所有UI到初始状态
        songNameLabel.text = "请选择歌曲"
        progressSlider.value = 0
        timeLabel.text = "00:00 - 00:00"
        currentTotalTime = 0
        setButtonStates(isPlaying: false)
    }
}
