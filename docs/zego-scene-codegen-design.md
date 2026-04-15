# ZegoExpressEngine AI 场景代码生成器

## 设计文档 v1.0

---

## 一、背景与问题

### 1.1 当前工作模式

作为 ZegoExpressEngine SDK 的维护者，当前为客户提供的交付物包括：
- 流程图
- 关键实现示例代码
- 文字描述的技术方案

### 1.2 存在的 Gap

1. **理解偏差**
   - 客户可能缺乏音视频背景知识
   - SDK 技术名词（推流/拉流/SEI/对齐）需要学习成本
   - 方案文档是"给人读的"，不是"给机器执行的"

2. **信息丢失**
   - 概念 → 思路 → 代码 多次转换中信息衰减
   - 客户实现的代码与方案设计存在偏差

3. **重复劳动**
   - 每个客户都要重新学习 SDK 概念
   - 相似场景的代码重复编写

### 1.3 核心洞察

**Code is Code** —— 让可运行的代码代替文档，让客户直接参考 Demo 代码，而非学习成本高的文档。

---

## 二、方案目标

设计一个 **AI 场景代码生成器**，通过以下方式桥接 Gap：

| 层级 | 目标 | 使用者 |
|------|------|--------|
| 可视化编辑器 | 搭积木式场景编排 | Zego 方案设计者（你） |
| 方案描述语言 (SDL) | 结构化的场景定义 | AI / 机器 |
| 接口契约层 (ICL) | SDK API 的精确描述 | AI 的知识库 |
| 代码生成器 | 输出可运行的 Demo | 客户参考 |

---

## 三、架构设计

### 3.1 整体架构

```
┌─────────────────────────────────────────────────────────────────┐
│                     可视化编辑器 (Scene Builder)                   │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐          │
│  │  积木箱      │    │    画布      │    │  属性面板    │          │
│  │  (能力积木)   │───▶│  (流程编排)  │◀──▶│  (参数配置)  │          │
│  └─────────────┘    └──────┬──────┘    └─────────────┘          │
└────────────────────────────┼────────────────────────────────────┘
                             │ 导出/导入
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                     方案描述语言 (SDL)                            │
│              YAML/JSON 格式的结构化场景定义                        │
└────────────────────────────┬────────────────────────────────────┘
                             │ 解析
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                     接口契约层 (ICL)                              │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐          │
│  │  API 签名    │    │  参数校验    │    │  调用顺序    │          │
│  │  返回值类型   │    │  默认值      │    │  前置条件    │          │
│  └─────────────┘    └─────────────┘    └─────────────┘          │
└────────────────────────────┬────────────────────────────────────┘
                             │ 查询/验证
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                     代码生成器                                    │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐          │
│  │  模板引擎    │───▶│  静态校验    │───▶│  输出代码    │          │
│  │  (按平台)    │    │  (语法/约束) │    │  (可运行Demo)│          │
│  └─────────────┘    └─────────────┘    └─────────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 核心概念

#### 3.2.1 元能力积木

不是映射单个 SDK API，而是映射一个**业务意图**：

| 积木 | 意图 | 内部封装的 SDK 调用 |
|------|------|---------------------|
| **初始化引擎** | 创建 SDK 实例 | `createEngine` + 基础配置 |
| **配置引擎** | 设置高级参数 | `setEngineConfig` |
| **进房** | 登录房间 | `loginRoom` |
| **推流** | 发送音视频 | `startPublishingStream` |
| **拉流** | 接收音视频 | `startPlayingStream` |

#### 3.2.2 角色

场景中的参与方：

| 角色 | 描述 | 典型能力 |
|------|------|----------|
| **主播** | 发送音视频 | 推流 |
| **观众** | 接收音视频 | 拉流 |
| **连麦者** | 既发又收 | 推流 + 拉流 |

---

## 四、最小原型设计

### 4.1 选择基础直播场景

**为什么选择直播？**
- 最简单的实时音视频场景
- 只有 2 个角色：主播、观众
- 核心能力：推流、拉流
- 是其他所有场景的基石

**场景描述：**
```
主播：创建房间 → 初始化 SDK → 推流
观众：进入房间 → 初始化 SDK → 拉流（观看主播）
```

### 4.2 积木设计（最小集合）

#### 4.2.1 能力积木（蓝色）

```
┌─────────────────┐
│    初始化引擎    │
├─────────────────┤
│  输入:          │
│    appID        │
│    appSign      │
│    scenario     │
├─────────────────┤
│  输出:          │
│    engine       │
└─────────────────┘

┌─────────────────┐
│      进房       │
├─────────────────┤
│  输入:          │
│    roomID       │
│    userID       │
│    token        │
├─────────────────┤
│  输出:          │
│    roomState    │
└─────────────────┘

┌─────────────────┐
│      推流       │
├─────────────────┤
│  输入:          │
│    streamID     │
│    camera       │
│    microphone   │
├─────────────────┤
│  输出:          │
│    publishState │
└─────────────────┘

┌─────────────────┐
│      拉流       │
├─────────────────┤
│  输入:          │
│    streamID     │
│    view         │
├─────────────────┤
│  输出:          │
│    playState    │
└─────────────────┘
```

#### 4.2.2 角色积木（绿色）

```
┌─────────────────┐
│      主播       │
├─────────────────┤
│  能力:          │
│    初始化引擎    │
│    进房         │
│    推流         │
└─────────────────┘

┌─────────────────┐
│      观众       │
├─────────────────┤
│  能力:          │
│    初始化引擎    │
│    进房         │
│    拉流         │
└─────────────────┘
```

### 4.3 场景编排（基础直播）

```
┌─────────────────────────────────────────────────────────┐
│                    基础直播场景                          │
├─────────────────────────────────────────────────────────┤
│                                                          │
│   ┌─────────────────┐      ┌─────────────────┐          │
│   │      主播        │      │      观众        │          │
│   │  ┌───────────┐  │      │  ┌───────────┐  │          │
│   │  │ 初始化引擎 │  │      │  │ 初始化引擎 │  │          │
│   │  └─────┬─────┘  │      │  └─────┬─────┘  │          │
│   │        ▼        │      │        ▼        │          │
│   │  ┌───────────┐  │      │  ┌───────────┐  │          │
│   │  │   进房    │◀─┼──────┼──▶│   进房    │  │          │
│   │  └─────┬─────┘  │      │  └─────┬─────┘  │          │
│   │        ▼        │      │        ▼        │          │
│   │  ┌───────────┐  │      │  ┌───────────┐  │          │
│   │  │   推流    │──┼──────┼──▶│   拉流    │  │          │
│   │  └───────────┘  │      │  └───────────┘  │          │
│   │                 │      │                 │          │
│   └─────────────────┘      └─────────────────┘          │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### 4.4 SDL 输出示例

```yaml
# scene-live-basic.yaml
version: "1.0"
schema: "zego-scene/v1"

scene:
  name: "基础直播"
  description: "最简单的直播场景：主播推流，观众拉流"

  sdk:
    name: ZegoExpressEngine
    minVersion: "3.0.0"

  roles:
    - id: "host"
      name: "主播"
      capabilities:
        - init_engine
        - join_room
        - publish_stream

    - id: "audience"
      name: "观众"
      capabilities:
        - init_engine
        - join_room
        - play_stream

  flows:
    # 主播流程
    - role: "host"
      steps:
        - block: "init_engine"
          params:
            appID: "${APP_ID}"
            appSign: "${APP_SIGN}"
            scenario: "live"

        - block: "join_room"
          params:
            roomID: "${ROOM_ID}"
            userID: "${HOST_USER_ID}"
            token: "${TOKEN}"

        - block: "publish_stream"
          params:
            streamID: "${HOST_USER_ID}_${ROOM_ID}_main"
            camera: true
            microphone: true

    # 观众流程
    - role: "audience"
      steps:
        - block: "init_engine"
          params:
            appID: "${APP_ID}"
            appSign: "${APP_SIGN}"
            scenario: "live"

        - block: "join_room"
          params:
            roomID: "${ROOM_ID}"
            userID: "${AUDIENCE_USER_ID}"
            token: "${TOKEN}"

        - block: "play_stream"
          params:
            streamID: "${HOST_USER_ID}_${ROOM_ID}_main"
```

### 4.5 ICL 契约示例（最小集合）

```yaml
# contract-zego-ios.yaml
version: "1.0"
platform: ios
language: swift

api:
  ZegoExpressEngine:
    createEngine:
      signature: "(with: ZegoEngineProfile, eventHandler: ZegoEventHandler?) -> ZegoExpressEngine"
      preconditions:
        - "全局只能调用一次"
        - "必须在任何其他操作之前"
      params:
        profile.appID:
          type: UInt32
          required: true
        profile.appSign:
          type: String
          required: true
        profile.scenario:
          type: ZegoScenario
          default: ".general"

    loginRoom:
      signature: "(roomID: String, user: ZegoUser, config: ZegoRoomConfig?) -> Void"
      preconditions:
        - "必须先 createEngine"
      params:
        roomID:
          type: String
          required: true
          constraints:
            maxLength: 128
        user.userID:
          type: String
          required: true
        token:
          type: String
          required: true

    startPublishingStream:
      signature: "(streamID: String, channel: ZegoPublishChannel) -> Void"
      preconditions:
        - "必须先 loginRoom"
      params:
        streamID:
          type: String
          required: true
        channel:
          type: ZegoPublishChannel
          default: ".main"

    startPlayingStream:
      signature: "(streamID: String, canvas: ZegoCanvas?) -> Void"
      preconditions:
        - "必须先 loginRoom"
      params:
        streamID:
          type: String
          required: true
        canvas.view:
          type: UIView
          required: true

enums:
  ZegoScenario:
    general: ".general"
    broadcast: ".broadcast"
    communication: ".communication"

  ZegoPublishChannel:
    main: ".main"
    aux: ".aux"
```

### 4.6 代码生成示例

基于上述 SDL 和 ICL，生成的 iOS Demo 代码结构：

```
LiveDemo-iOS/
├── AppDelegate.swift
├── SceneDelegate.swift
├── ViewController.swift          # 主入口
├── EngineManager.swift           # SDK 初始化
├── RoomManager.swift             # 房间管理
├── LiveHostViewController.swift  # 主播页面
├── LiveAudienceViewController.swift # 观众页面
└── Config.swift                  # 配置常量
```

关键代码片段：

```swift
// LiveHostViewController.swift
import UIKit
import ZegoExpressEngine

class LiveHostViewController: UIViewController {

    // MARK: - Config
    private let appID: UInt32 = Config.appID
    private let appSign = Config.appSign
    private let roomID: String
    private let userID: String
    private let streamID: String

    // MARK: - UI
    private let previewView = UIView()
    private let startButton = UIButton()

    // MARK: - Init
    init(roomID: String, userID: String) {
        self.roomID = roomID
        self.userID = userID
        self.streamID = "\(userID)_\(roomID)_main"
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        initializeEngine()
    }

    // MARK: - Step 1: 初始化引擎 (对应积木: 初始化引擎)
    private func initializeEngine() {
        let profile = ZegoEngineProfile(
            appID: appID,
            appSign: appSign,
            scenario: .general
        )

        ZegoExpressEngine.createEngine(with: profile, eventHandler: self)

        // 继续下一步
        joinRoom()
    }

    // MARK: - Step 2: 进房 (对应积木: 进房)
    private func joinRoom() {
        let user = ZegoUser(userID: userID)
        let config = ZegoRoomConfig()
        config.token = Config.generateToken(roomID: roomID, userID: userID)

        ZegoExpressEngine.shared().loginRoom(roomID, user: user, config: config)
    }

    // MARK: - Step 3: 推流 (对应积木: 推流)
    private func startPublishing() {
        let canvas = ZegoCanvas(view: previewView)
        ZegoExpressEngine.shared().startPreview(canvas)
        ZegoExpressEngine.shared().startPublishingStream(streamID)
    }
}

// MARK: - ZegoEventHandler
extension LiveHostViewController: ZegoEventHandler {

    func onRoomStateUpdate(_ state: ZegoRoomState, errorCode: Int32, extendedData: [AnyHashable : Any]?, roomID: String) {
        if state == .connected {
            // 进房成功，开始推流
            startPublishing()
        }
    }

    func onPublisherStateUpdate(_ state: ZegoPublisherState, errorCode: Int32, extendedData: [AnyHashable : Any]?, streamID: String) {
        if state == .publishing {
            print("推流成功: \(streamID)")
        }
    }
}
```

---

## 五、SDL 设计规范

### 5.1 核心原则

1. **声明式优于命令式** —— 描述"要什么"而非"怎么做"
2. **角色分离** —— 每个参与方独立定义其行为
3. **积木抽象** —— 高层业务意图，底层 SDK 实现
4. **可验证** —— 能被机器解析和校验

### 5.2 Schema 定义

```yaml
# scene-schema.json (简化版)
type: object
required: [version, scene]
properties:
  version:
    type: string
    pattern: "^\d+\.\d+$"

  scene:
    type: object
    required: [name, roles, flows]
    properties:
      name:
        type: string

      description:
        type: string

      sdk:
        type: object
        properties:
          name:
            type: string
            enum: [ZegoExpressEngine]
          minVersion:
            type: string

      roles:
        type: array
        items:
          type: object
          required: [id, name, capabilities]
          properties:
            id:
              type: string
            name:
              type: string
            capabilities:
              type: array
              items:
                type: string
                enum: [init_engine, join_room, publish_stream, play_stream, ...]

      flows:
        type: array
        items:
          type: object
          required: [role, steps]
          properties:
            role:
              type: string
            steps:
              type: array
              items:
                type: object
                required: [block, params]
                properties:
                  block:
                    type: string
                  params:
                    type: object
```

---

## 六、ICL 设计规范

### 6.1 核心原则

1. **精确性** —— API 签名、参数类型必须准确
2. **前置条件** —— 明确每个 API 的调用前提
3. **平台差异** —— 不同平台的语法差异显式声明
4. **可验证** —— 生成的代码能通过静态检查

### 6.2 契约来源

ICL 数据从以下渠道维护：

| 渠道 | 方式 | 优先级 |
|------|------|--------|
| SDK 头文件 | 自动解析 | P0 |
| 官方文档 | 人工校对 | P1 |
| 示例代码 | 验证测试 | P2 |

---

## 七、实施步骤

### Phase 1: 最小原型验证（当前项目）

**目标**：跑通"基础直播场景"的端到端流程

| 任务 | 内容 | 产出 |
|------|------|------|
| 1 | 定义基础直播的 SDL Schema | `scene-live-basic.yaml` |
| 2 | 提取 Zego SDK 核心 API 契约 | `contract-zego-ios.yaml` |
| 3 | 编写 iOS 代码模板 | `templates/ios/*.swift` |
| 4 | 实现代码生成器 | `generator/` |
| 5 | 生成可运行的 iOS Demo | `LiveDemo-iOS/` |
| 6 | 验证编译运行 | 真机/模拟器测试通过 |

### Phase 2: 可视化编辑器（新项目）

**目标**：搭积木式场景编排

| 任务 | 内容 | 技术选型 |
|------|------|----------|
| 1 | 设计编辑器 UI/UX | Figma |
| 2 | 实现画布核心功能 | React + ReactFlow |
| 3 | 积木拖拽系统 | 自定义或 Blockly |
| 4 | SDL 双向绑定 | YAML ↔ Canvas |
| 5 | 与代码生成服务对接 | REST API |

### Phase 3: 场景扩展

基于基础直播场景，逐步扩展：

| 场景 | 新增积木 | 复杂度 |
|------|----------|--------|
| 连麦直播 | 连麦申请、连麦接受 | 低 |
| 多人视频通话 | 多角色、多路流 | 中 |
| 语聊房 | 音频模式、上麦/下麦 | 中 |
| 双人轮唱 | SEI同步、切换逻辑、两路流 | 高 |

---

## 八、关键设计决策

### 8.1 为什么用 YAML 而非 JSON？

| YAML | JSON |
|------|------|
| 支持注释 | 不支持 |
| 人类可读性更好 | 机器友好 |
| 支持多行字符串 | 较繁琐 |
| 是 SDL 的首选 | 用于 ICL（API 定义）|

### 8.2 积木 vs 直接 API？

| 积木 | 直接 API |
|------|----------|
| 封装业务意图 | 映射单个函数 |
| 内部包含多个 SDK 调用 | 一对一 |
| 带默认配置 | 需完整参数 |
| 适合方案设计者 | 适合开发者 |

**决策**：积木用于 SDL（方案层），API 用于 ICL（实现层）

### 8.3 为什么选择 iOS 作为首个平台？

- 当前验证项目已是 iOS
- Swift 类型系统强，便于静态验证
- SDK 使用 Objective-C，有明确头文件

后续扩展：Android (Kotlin)、Web (TypeScript)、Flutter (Dart)

---

## 九、风险与缓解

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| SDK API 变更 | 高 | ICL 版本化，与 SDK 版本绑定 |
| 生成代码质量差 | 中 | 模板化 + 静态验证 + 人工 review |
| 场景复杂度爆炸 | 中 | 模块化设计，积木可组合 |
| AI 理解偏差 | 低 | 严格的 Schema 和契约约束 |

---

## 十、附录

### 10.1 术语表

| 术语 | 含义 |
|------|------|
| SDL | Spec Description Language，方案描述语言 |
| ICL | Interface Contract Layer，接口契约层 |
| 积木 | 可视化的能力单元 |
| 元能力 | 最小可复用的业务意图 |

### 10.2 参考项目

- 当前验证项目：`switch-chorus-demo`
- 新项目待创建

---

**文档版本**: v1.0
**创建日期**: 2026-03-06
**作者**: Claude + Zego SDK Team
