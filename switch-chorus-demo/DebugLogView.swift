//
//  DebugLogView.swift
//  switch-chorus-demo
//
//  Debug 日志视图 - 半透明可展开的文字日志展示
//

import UIKit

class DebugLogView: UIView {

    // MARK: - 子视图

    private let containerView = UIView()
    private let textView = UITextView()
    private let toggleButton = UIButton()

    // MARK: - 状态

    private var isExpanded = false
    private var logs: [String] = []
    private let maxLogs = 500

    // 折叠状态的大小和位置（吸附在右侧）
    private let collapsedWidth: CGFloat = 120
    private let collapsedHeight: CGFloat = 200

    // MARK: - 约束引用

    private var collapsedConstraints: [NSLayoutConstraint] = []
    private var expandedConstraints: [NSLayoutConstraint] = []

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

        // 容器视图 - 20% 不透明度
        containerView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        containerView.layer.cornerRadius = 8
        containerView.layer.borderColor = UIColor.gray.withAlphaComponent(0.3).cgColor
        containerView.layer.borderWidth = 1
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)

        // 切换按钮（用于展开/收起）- 放在最上层
        toggleButton.backgroundColor = .clear
        toggleButton.addTarget(self, action: #selector(toggleExpand), for: .touchUpInside)
        toggleButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(toggleButton)

        // 文字视图
        textView.backgroundColor = .clear
        textView.textColor = UIColor.green.withAlphaComponent(0.9)
        textView.font = UIFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        textView.isEditable = false
        textView.isSelectable = true
        textView.showsVerticalScrollIndicator = true
        textView.showsHorizontalScrollIndicator = false
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isUserInteractionEnabled = false // 让点击穿透到 toggleButton
        containerView.addSubview(textView)

        // 准备约束
        prepareConstraints()

        // 默认折叠状态
        showCollapsed()
    }

    private func prepareConstraints() {
        // 折叠状态约束
        collapsedConstraints = [
            // 容器视图 - 吸附在右侧，垂直居中
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: collapsedWidth),
            containerView.heightAnchor.constraint(equalToConstant: collapsedHeight)
        ]

        // 展开状态约束
        expandedConstraints = [
            // 容器视图 - 全屏（留一些边距）
            containerView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 20),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            containerView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ]

        // 内部视图约束（始终不变）
        NSLayoutConstraint.activate([
            // 切换按钮 - 始终填满容器
            toggleButton.topAnchor.constraint(equalTo: containerView.topAnchor),
            toggleButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            toggleButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            toggleButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            // 文字视图 - 始终填满容器（留出边距）
            textView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 4),
            textView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 4),
            textView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -4),
            textView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -4)
        ])
    }

    private func showCollapsed() {
        NSLayoutConstraint.deactivate(expandedConstraints)
        NSLayoutConstraint.activate(collapsedConstraints)
        containerView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        textView.font = UIFont.monospacedSystemFont(ofSize: 10, weight: .regular)
    }

    private func showExpanded() {
        NSLayoutConstraint.deactivate(collapsedConstraints)
        NSLayoutConstraint.activate(expandedConstraints)
        containerView.backgroundColor = UIColor.black.withAlphaComponent(0.95)
        textView.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    }

    /// 收起日志视图（如果处于展开状态）
    func collapseIfExpanded() {
        guard isExpanded else { return }
        toggleExpand()
    }

    // MARK: - 展开/收起

    @objc private func toggleExpand() {
        isExpanded.toggle()

        UIView.animate(withDuration: 0.3, animations: {
            if self.isExpanded {
                self.showExpanded()
            } else {
                self.showCollapsed()
            }
            self.layoutIfNeeded()
        }) { _ in
            self.scrollToBottom()
        }
    }

    // MARK: - 日志操作

    func addLog(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let timestamp = self.currentTimeString()
            let logEntry = "[\(timestamp)] \(message)"

            self.logs.append(logEntry)

            // 限制日志数量
            if self.logs.count > self.maxLogs {
                self.logs.removeFirst(self.logs.count - self.maxLogs)
            }

            // 更新文字视图
            self.textView.text = self.logs.joined(separator: "\n")

            // 自动滚动到底部
            self.scrollToBottom()
        }
    }

    func clearLogs() {
        DispatchQueue.main.async { [weak self] in
            self?.logs.removeAll()
            self?.textView.text = ""
        }
    }

    private func scrollToBottom() {
        let range = NSRange(location: textView.text.count, length: 0)
        textView.scrollRangeToVisible(range)
    }

    // MARK: - 点击穿透

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // 如果点击在 containerView 内，正常处理
        // 如果点击在 containerView 外，返回 nil 让事件穿透到下层视图
        let containerPoint = convert(point, to: containerView)
        if containerView.bounds.contains(containerPoint) {
            return super.hitTest(point, with: event)
        }
        return nil
    }

    private func currentTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: Date())
    }
}

// MARK: - 全局日志管理器

class DebugLogManager {
    static let shared = DebugLogManager()
    weak var logView: DebugLogView?

    func log(_ message: String) {
        print(message) // 同时输出到控制台
        logView?.addLog(message)
    }

    func clear() {
        logView?.clearLogs()
    }
}
