# ZEGO 场景实现文档模板

> 使用说明：复制此模板，按场景需求填写各部分内容

---

## 1. 场景说明

<!-- 描述场景的业务背景和核心功能 -->
<!-- 示例：多个用户在一个房间内，分成两组轮流演唱同一首歌 -->

**场景名称**：

**业务背景**：

**核心功能**：

---

## 2. 核心需求

### 2.1 功能需求

| 需求项 | 描述 | 优先级 |
|--------|------|--------|
| | | P0/P1/P2 |

### 2.2 非功能需求

| 需求项 | 指标 | 说明 |
|--------|------|------|
| 延迟 | < 200ms | 端到端延迟 |
| 同步性 | | |
| 音质 | | |

---

## 3. 技术实现

### 3.1 整体流程

```
用户操作流程：
┌─────────┐    ┌─────────┐    ┌─────────┐
│  步骤1  │ ──▶│  步骤2  │ ──▶│  步骤3  │
└─────────┘    └─────────┘    └─────────┘
```

### 3.2 状态机（如适用）

```
┌───────┐     ┌───────┐     ┌───────┐
│ Idle  │ ──▶ │ Ready │ ──▶ │ Active│
└───────┘     └───────┘     └───────┘
    │                            │
    └────────────────────────────┘
```

### 3.3 API 调用时序

```
┌────────┐     ┌────────┐     ┌────────┐
│  App   │     │  SDK   │     │ Server │
└───┬────┘     └───┬────┘     └───┬────┘
    │              │              │
    │ createEngine │              │
    │─────────────▶│              │
    │              │              │
    │ loginRoom    │              │
    │─────────────▶│─────────────▶│
    │              │              │
    │ ...          │              │
    │              │              │
```

### 3.4 代码示例

<!-- 标注代码语言，便于 AI 转换 -->

#### 3.4.1 SDK 初始化配置

```Objective-C
// Objective-C 示例代码
// 注意：将被转换为 Swift

// 私有配置
engineConfig.advancedConfig.put("config_key", "config_value")

// 自定义音频配置
ZegoCustomAudioConfig *audioConfig = [[ZegoCustomAudioConfig alloc] init];
[self.engine enableCustomAudioIO:YES config:audioConfig channel:ZegoPublishChannelAux];
```

#### 3.4.2 推流配置

```Objective-C
// 推流代码示例
ZegoPublisherConfig *config = [[ZegoPublisherConfig alloc] init];
config.forceSynchronousNetworkTime = YES;
[self.engine startPublishingStream:@"stream_id" config:config channel:ZegoPublishChannelMain];
```

---

## 4. 参数配置

### 4.1 配置表引用

> 参考文件：`参数配置表.csv`
>
> 使用列：第 **X** 列（iOS 场景名）

### 4.2 关键配置项

| 接口 | 参数值 | 说明 | 来源（CSV行号） |
|------|--------|------|----------------|
| setAudioConfig | Low3, 128, Stereo | 音频编码配置 | 行 143-210 |
| setAudioDeviceMode | General | 音频设备模式 | 行 123-142 |
| enableAEC | true | 回声消除 | 行 220 |

### 4.3 私有配置（advancedConfig）

| 配置项 | 值 | 说明 |
|--------|-----|------|
| ultra_low_latency | true | 超低延迟模式 |
| music_detection_mode | 2 | 音乐检测模式 |
| | | |

---

## 5. 注意事项 / 坑点

### 5.1 API 注意事项

| API | 注意点 | 正确用法 |
|-----|--------|----------|
| ZegoExpressEngine.shared() | 返回非 Optional | `let engine = ZegoExpressEngine.shared()` |
| ZegoPublisherConfig | 无 streamID 属性 | streamID 通过 startPublishingStream 传递 |
| | | |

### 5.2 时序注意事项

```
⚠️ 必须在 createEngine 之前调用：
- setEngineConfig

⚠️ 必须在 startPublishingStream 之前调用：
- setAudioConfig
- setStreamAlignmentProperty
```

### 5.3 平台差异

| 平台 | 差异点 | 处理方式 |
|------|--------|----------|
| iOS | | |
| Android | | |

---

## 6. 测试检查清单

### 6.1 功能测试

- [ ] 单人场景正常
- [ ] 多人场景正常
- [ ] 进房/退房正常
- [ ] 推流/拉流正常
- [ ] 异常情况处理

### 6.2 性能测试

- [ ] 延迟达标
- [ ] 无明显卡顿
- [ ] 内存稳定

### 6.3 兼容性测试

- [ ] iOS 不同版本
- [ ] 不同机型
- [ ] 弱网环境

---

## 7. 变更记录

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|------|
| YYYY-MM-DD | v1.0 | 初始版本 | |

---

## 附录

### A. 相关文档链接

- ZEGO 官方文档：
- 设计稿：
- API 文档：

### B. 头文件索引

```
lib/ZegoExpressEngine.xcframework/ios-arm64/.../Headers/
├── ZegoExpressEngine.h
├── ZegoExpressEngine+XXX.h
└── ZegoExpressDefines.h
```
