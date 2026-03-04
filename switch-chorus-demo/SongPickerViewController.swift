//
//  SongPickerViewController.swift
//  switch-chorus-demo
//
//  点歌弹窗 - 底部弹出的歌曲选择器
//  设计来源: 组队合唱.pen - Song Pick Modal
//

import UIKit

// MARK: - 歌曲模型
struct SongItem {
    let name: String
    let filePath: String
}

// MARK: - 歌曲选择代理
protocol SongPickerDelegate: AnyObject {
    func songPicker(_ picker: SongPickerViewController, didSelectSong song: SongItem)
}

// MARK: - 歌曲选择器控制器
class SongPickerViewController: UIViewController {

    // MARK: - 属性
    weak var delegate: SongPickerDelegate?
    private var songs: [SongItem] = []

    // MARK: - UI 组件
    /// 拖拽指示器
    private lazy var dragHandleView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.borderSubtle
        view.layer.cornerRadius = 2
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    /// 标题
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "选择歌曲"
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = AppColors.textPrimary
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 歌曲列表
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SongCell.self, forCellReuseIdentifier: "SongCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadSongs()
    }

    // MARK: - UI 设置
    private func setupUI() {
        view.backgroundColor = AppColors.bgElevated

        // 圆角（仅顶部）
        view.layer.cornerRadius = 24
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        // 添加子视图
        view.addSubview(dragHandleView)
        view.addSubview(titleLabel)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            // 拖拽指示器
            dragHandleView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            dragHandleView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dragHandleView.widthAnchor.constraint(equalToConstant: 40),
            dragHandleView.heightAnchor.constraint(equalToConstant: 4),

            // 标题
            titleLabel.topAnchor.constraint(equalTo: dragHandleView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // 歌曲列表
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
        ])
    }

    // MARK: - 加载歌曲
    private func loadSongs() {
        var loadedSongs: [SongItem] = []

        // 方式1: 尝试获取 resources 文件夹引用 (folder reference)
        if let resourcesURL = Bundle.main.url(forResource: "resources", withExtension: nil),
           let files = try? FileManager.default.contentsOfDirectory(at: resourcesURL, includingPropertiesForKeys: nil) {
            loadedSongs = files
                .filter { $0.pathExtension == "mp3" }
                .map { url in
                    let name = url.deletingPathExtension().lastPathComponent
                    return SongItem(name: name, filePath: url.path)
                }
        }

        // 方式2: 直接在 Bundle 中搜索 mp3 文件 (如果文件是单独添加的)
        if loadedSongs.isEmpty {
            let resourcePath = Bundle.main.resourcePath ?? ""
            if let files = try? FileManager.default.contentsOfDirectory(atPath: resourcePath) {
                loadedSongs = files
                    .filter { $0.hasSuffix(".mp3") }
                    .compactMap { fileName -> SongItem? in
                        guard let path = Bundle.main.path(forResource: (fileName as NSString).deletingPathExtension, ofType: "mp3") else {
                            return nil
                        }
                        let name = (fileName as NSString).deletingPathExtension
                        return SongItem(name: name, filePath: path)
                    }
            }
        }

        songs = loadedSongs
        print("[SongPicker] 加载了 \(songs.count) 首歌曲")
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource
extension SongPickerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath) as! SongCell
        let song = songs[indexPath.row]
        cell.configure(with: song)
        cell.onConfirmTapped = { [weak self] in
            guard let self = self else { return }
            self.delegate?.songPicker(self, didSelectSong: song)
            self.dismiss(animated: true)
        }
        return cell
    }
}

// MARK: - UITableViewDelegate
extension SongPickerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }
}

// MARK: - 歌曲单元格
class SongCell: UITableViewCell {

    // MARK: - 属性
    var onConfirmTapped: (() -> Void)?

    // MARK: - UI 组件
    private lazy var songNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = AppColors.textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var confirmButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("确定", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.setTitleColor(AppColors.textOnAccent, for: .normal)
        button.backgroundColor = AppColors.accentTerracotta
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - 初始化
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI 设置
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(songNameLabel)
        contentView.addSubview(confirmButton)

        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            songNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            songNameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            confirmButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            confirmButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            confirmButton.widthAnchor.constraint(equalToConstant: 60),
            confirmButton.heightAnchor.constraint(equalToConstant: 32),
        ])
    }

    // MARK: - 配置
    func configure(with song: SongItem) {
        songNameLabel.text = song.name
    }

    // MARK: - 动作
    @objc private func confirmTapped() {
        onConfirmTapped?()
    }
}
