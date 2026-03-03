# verify-zego-api

验证 ZegoExpressEngine API 调用，确保基于真实头文件而非"猜测"。

---

## SDK 版本信息

| 字段 | 值 | 来源 |
|------|-----|------|
| **版本号** | 3.23.1 | Info.plist → CFBundleShortVersionString |
| **Build 号** | 47919 | Info.plist → CFBundleVersion |
| **路径** | `lib/ZegoExpressEngine.xcframework/ios-arm64/ZegoExpressEngine.framework/` |

> ⚠️ **版本检查逻辑**：每次使用此 Skill 时，先对比当前 SDK 版本号。如果版本号变化，需要重新扫描头文件更新白名单。

---

## 工作流程

```
┌─────────────────────────────────────────┐
│  1. 检查 SDK 版本号                      │
│     读取 Info.plist 中的版本信息         │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  2. 版本对比                             │
│     当前缓存: 3.23.1 (47919)             │
└──────────────┬──────────────────────────┘
               │
       ┌───────┴───────┐
       │               │
       ▼               ▼
   版本相同         版本变化
       │               │
       ▼               ▼
┌─────────────┐  ┌─────────────────┐
│ 3. 查白名单  │  │ 重新扫描头文件   │
│    直接使用  │  │ 更新白名单       │
└─────────────┘  └─────────────────┘
```

---

## 已验证 API 白名单

> 📋 **说明**：以下 API 已从头文件验证，可直接使用。
> 格式：`Swift 方法签名` | 返回类型 | 头文件位置

### 一、ZegoExpressEngine（主类）

| Swift 方法 | 返回类型 | 头文件 | 说明 |
|------------|---------|--------|------|
| `ZegoExpressEngine.shared()` | `ZegoExpressEngine` (非Optional) | ZegoExpressEngine.h:47 | 获取单例 |
| `ZegoExpressEngine.createEngine(with: eventHandler:)` | `ZegoExpressEngine` | ZegoExpressEngine.h:25-26 | 创建引擎 |
| `ZegoExpressEngine.destroyEngine(_:)` | `Void` | ZegoExpressEngine.h:37 | 销毁引擎 |
| `ZegoExpressEngine.setEngineConfig(_:)` | `Void` | ZegoExpressEngine.h:57 | 设置引擎配置 |
| `engine.setEventHandler(_:)` | `Void` | ZegoExpressEngine.h:175 | 设置事件回调 |
| `engine.setRoomScenario(_:)` | `Void` | ZegoExpressEngine.h:191 | 设置房间场景 |
| `engine.uploadLog()` | `Void` | ZegoExpressEngine.h:201 | 上传日志 |
| `engine.enableDebugAssistant(_:)` | `Void` | ZegoExpressEngine.h:236 | 启用调试助手 |
| `engine.callExperimentalAPI(_:)` | `String` | ZegoExpressEngine.h:246 | 实验性 API |
| `ZegoExpressEngine.getVersion()` | `String` | ZegoExpressEngine.h:140 | 获取版本 |

### 二、ZegoExpressEngine+Room（房间）

| Swift 方法 | 返回类型 | 头文件 | 说明 |
|------------|---------|--------|------|
| `engine.loginRoom(_:user:config:)` | `Void` | ZegoExpressEngine+Room.h | 登录房间 |
| `engine.loginRoom(_:user:config:callback:)` | `Void` | ZegoExpressEngine+Room.h | 登录房间(带回调) |
| `engine.logoutRoom()` | `Void` | ZegoExpressEngine+Room.h | 登出房间 |
| `engine.logoutRoom(_:callback:)` | `Void` | ZegoExpressEngine+Room.h | 登出指定房间 |
| `engine.switchRoom(_:config:)` | `Void` | ZegoExpressEngine+Room.h | 切换房间 |
| `engine.renewToken(_:)` | `Void` | ZegoExpressEngine+Room.h | 更新 Token |
| `engine.setRoomExtraInfo(_:key:value:callback:)` | `Void` | ZegoExpressEngine+Room.h | 设置房间额外信息 |

### 三、ZegoExpressEngine+Publisher（推流）

| Swift 方法 | 返回类型 | 头文件 | 说明 |
|------------|---------|--------|------|
| `engine.setAudioConfig(_:)` | `Void` | ZegoExpressEngine+Publisher.h:330 | 设置音频配置 |
| `engine.setAudioConfig(_:channel:)` | `Void` | ZegoExpressEngine+Publisher.h:343 | 设置音频配置(指定通道) |
| `engine.getAudioConfig()` | `ZegoAudioConfig` | ZegoExpressEngine+Publisher.h:355 | 获取音频配置 |
| `engine.startPublishingStream(_:)` | `Void` | ZegoExpressEngine+Publisher.h | 开始推流 |
| `engine.startPublishingStream(_:config:)` | `Void` | ZegoExpressEngine+Publisher.h | 开始推流(带配置) |
| `engine.startPublishingStream(_:config:channel:)` | `Void` | ZegoExpressEngine+Publisher.h | 开始推流(带配置和通道) |
| `engine.stopPublishingStream()` | `Void` | ZegoExpressEngine+Publisher.h | 停止推流 |
| `engine.stopPublishingStream(channel:)` | `Void` | ZegoExpressEngine+Publisher.h | 停止推流(指定通道) |
| `engine.mutePublishStreamAudio(_:)` | `Void` | ZegoExpressEngine+Publisher.h | 静音推流音频 |
| `engine.mutePublishStreamAudio(_:channel:)` | `Void` | ZegoExpressEngine+Publisher.h | 静音指定通道 |
| `engine.setStreamExtraInfo(_:callback:)` | `Void` | ZegoExpressEngine+Publisher.h:137 | 设置流额外信息 |
| `engine.setStreamAlignmentProperty(_:channel:)` | `Void` | ZegoExpressEngine+Publisher.h:509 | 设置流对齐属性 |

| Swift 方法 | 返回类型 | 头文件 | 说明 |
|------------|---------|--------|------|
| `engine.startPublishingStream(_:)` | `Void` | ZegoExpressEngine+Publisher.h | 开始推流 |
| `engine.startPublishingStream(_:config:)` | `Void` | ZegoExpressEngine+Publisher.h | 开始推流(带配置) |
| `engine.stopPublishingStream()` | `Void` | ZegoExpressEngine+Publisher.h | 停止推流 |
| `engine.setPublishStreamVideoKey(_:streamID:)` | `Void` | ZegoExpressEngine+Publisher.h | 设置视频加密Key |
| `engine.mutePublishStreamAudio(_:)` | `Void` | ZegoExpressEngine+Publisher.h | 静音推流音频 |
| `engine.mutePublishStreamAudio(_:channel:)` | `Void` | ZegoExpressEngine+Publisher.h | 静音指定通道 |
| `engine.mutePublishStreamVideo(_:)` | `Void` | ZegoExpressEngine+Publisher.h | 静音推流视频 |
| `engine.setStreamExtraInfo(_:callback:)` | `Void` | ZegoExpressEngine+Publisher.h | 设置流额外信息 |
| `engine.setStreamExtraInfo(_:channel:callback:)` | `Void` | ZegoExpressEngine+Publisher.h | 设置流额外信息(指定通道) |

### 四、ZegoExpressEngine+Player（拉流）

| Swift 方法 | 返回类型 | 头文件 | 说明 |
|------------|---------|--------|------|
| `engine.startPlayingStream(_:)` | `Void` | ZegoExpressEngine+Player.h:62 | 开始拉流(纯音频) |
| `engine.startPlayingStream(_:canvas:)` | `Void` | ZegoExpressEngine+Player.h:29 | 开始拉流 |
| `engine.startPlayingStream(_:canvas:config:)` | `Void` | ZegoExpressEngine+Player.h:46-48 | 开始拉流(带配置) |
| `engine.startPlayingStream(_:config:)` | `Void` | ZegoExpressEngine+Player.h:77 | 开始拉流(纯音频+配置) |
| `engine.stopPlayingStream(_:)` | `Void` | ZegoExpressEngine+Player.h:148 | 停止拉流 |
| `engine.setPlayVolume(_:streamID:)` | `Void` | ZegoExpressEngine+Player.h:202 | 设置播放音量 |
| `engine.setAllPlayStreamVolume(_:)` | `Void` | ZegoExpressEngine+Player.h:214 | 设置所有流音量 |
| `engine.mutePlayStreamAudio(_:streamID:)` | `Void` | ZegoExpressEngine+Player.h:271 | 静音拉流音频 |
| `engine.mutePlayStreamVideo(_:streamID:)` | `Void` | ZegoExpressEngine+Player.h:289 | 静音拉流视频 |
| `engine.muteAllPlayStreamAudio(_:)` | `Void` | ZegoExpressEngine+Player.h:301 | 静音所有拉流音频 |
| `engine.muteAllPlayStreamVideo(_:)` | `Void` | ZegoExpressEngine+Player.h:328 | 静音所有拉流视频 |
| `engine.setPlayStreamBufferIntervalRange(_:min:max:)` | `Void` | ZegoExpressEngine+Player.h:241-243 | 设置缓冲区间 |
| `engine.setPlayStreamsAlignmentProperty(_:)` | `Void` | ZegoExpressEngine+Player.h:420 | 设置流对齐属性 |

### 五、ZegoExpressEngine+MediaPlayer（媒体播放器）

| Swift 方法 | 返回类型 | 头文件 | 说明 |
|------------|---------|--------|------|
| `engine.createMediaPlayer()` | `ZegoMediaPlayer?` | ZegoExpressEngine+MediaPlayer.h:26 | 创建播放器 |
| `engine.destroyMediaPlayer(_:)` | `Void` | ZegoExpressEngine+MediaPlayer.h:35 | 销毁播放器 |

### 六、ZegoExpressEngine+CustomAudioIO（自定义音频IO）

| Swift 方法 | 返回类型 | 头文件 | 说明 |
|------------|---------|--------|------|
| `engine.enableCustomAudioCaptureProcessing(_:config:)` | `Void` | ZegoExpressEngine+CustomAudioIO.h | 启用自定义音频前处理 |
| `engine.enableCustomAudioIO(_:config:channel:)` | `Void` | ZegoExpressEngine+CustomAudioIO.h | 启用自定义音频IO |
| `engine.setAudioSource(_:channel:)` | `Void` | ZegoExpressEngine+CustomAudioIO.h | 设置音频源 |
| `engine.sendCustomAudioCaptureAAudioData(_:dataLength:param:referenceTimeMillisecond:)` | `Void` | ZegoExpressEngine+CustomAudioIO.h | 发送自定义音频数据 |

### 七、ZegoExpressEngine+Device（设备）

| Swift 方法 | 返回类型 | 头文件 | 说明 |
|------------|---------|--------|------|
| `engine.enableCamera(_:)` | `Void` | ZegoExpressEngine+Device.h:249 | 开关摄像头 |
| `engine.enableCamera(_:channel:)` | `Void` | ZegoExpressEngine+Device.h:263 | 开关摄像头(指定通道) |
| `engine.setAudioDeviceMode(_:)` | `Void` | ZegoExpressEngine+Device.h:172 | 设置音频设备模式 |
| `engine.muteMicrophone(_:)` | `Void` | ZegoExpressEngine+Device.h:26 | 静音麦克风 |
| `engine.isMicrophoneMuted` | `Bool` | ZegoExpressEngine+Device.h:37 | 检查麦克风是否静音 |
| `engine.muteSpeaker(_:)` | `Void` | ZegoExpressEngine+Device.h:48 | 静音扬声器 |
| `engine.isSpeakerMuted` | `Bool` | ZegoExpressEngine+Device.h:59 | 检查扬声器是否静音 |

### 八、ZegoExpressEngine+Preprocess（音频前处理）

| Swift 方法 | 返回类型 | 头文件 | 说明 |
|------------|---------|--------|------|
| `engine.enableAEC(_:)` | `Void` | ZegoExpressEngine+Preprocess.h:66 | 启用回声消除 |
| `engine.enableHeadphoneAEC(_:)` | `Void` | ZegoExpressEngine+Preprocess.h:81 | 耳机回声消除 |
| `engine.setAECMode(_:)` | `Void` | ZegoExpressEngine+Preprocess.h:93 | 设置AEC模式 |
| `engine.enableAGC(_:)` | `Void` | ZegoExpressEngine+Preprocess.h:105 | 启用自动增益 |
| `engine.enableANS(_:)` | `Void` | ZegoExpressEngine+Preprocess.h:118 | 启用噪声抑制 |
| `engine.enableTransientANS(_:)` | `Void` | ZegoExpressEngine+Preprocess.h:131 | 启用瞬态噪声抑制 |
| `engine.setANSMode(_:)` | `Void` | ZegoExpressEngine+Preprocess.h:143 | 设置ANS模式 |
| `engine.enableSpeechEnhance(_:level:)` | `Void` | ZegoExpressEngine+Preprocess.h:158 | 启用语音增强 |
| `engine.enableAudioMixing(_:)` | `Void` | ZegoExpressEngine+Preprocess.h:172 | 启用音频混音 |
| `engine.setAudioMixingHandler(_:)` | `Void` | ZegoExpressEngine+Preprocess.h:184 | 设置混音回调 |
| `engine.setAudioMixingVolume(_:)` | `Void` | ZegoExpressEngine+Preprocess.h:209 | 设置混音音量 |
| `engine.setAudioMixingVolume(_:type:)` | `Void` | ZegoExpressEngine+Preprocess.h:222 | 设置混音音量(指定类型) |

---

## ZegoEventHandler 回调白名单

### 房间回调

| Swift 方法 | 头文件 | 说明 |
|------------|--------|------|
| `onRoomStateUpdate(_:errorCode:extendedData:roomID:)` | ZegoExpressEventHandler.h:83-86 | 房间状态更新 |
| `onRoomStateChanged(_:errorCode:extendedData:roomID:)` | ZegoExpressEventHandler.h:104-107 | 房间状态变化(带原因) |
| `onRoomUserUpdate(_:userList:roomID:)` | ZegoExpressEventHandler.h:125-127 | 用户列表更新 |
| `onRoomOnlineUserCountUpdate(_:roomID:)` | ZegoExpressEventHandler.h:140 | 在线用户数更新 |
| `onRoomStreamUpdate(_:streamList:extendedData:roomID:)` | ZegoExpressEventHandler.h:158-161 | 流列表更新 |
| `onRoomStreamExtraInfoUpdate(_:roomID:)` | ZegoExpressEventHandler.h:175 | 流额外信息更新 |
| `onRoomExtraInfoUpdate(_:roomID:)` | ZegoExpressEventHandler.h:188-189 | 房间额外信息更新 |
| `onRoomTokenWillExpire(_:)` | ZegoExpressEventHandler.h:200+ | Token 即将过期 |

### 推流回调

| Swift 方法 | 头文件 | 说明 |
|------------|--------|------|
| `onPublisherStateUpdate(_:errorCode:extendedData:streamID:)` | ZegoExpressEventHandler.h | 推流状态更新 |
| `onPublisherQualityUpdate(_:quality:)` | ZegoExpressEventHandler.h | 推流质量更新 |
| `onPublisherRecvSEI(_:)` | ZegoExpressEventHandler.h | 收到 SEI |

### 拉流回调

| Swift 方法 | 头文件 | 说明 |
|------------|--------|------|
| `onPlayerStateUpdate(_:errorCode:extendedData:streamID:)` | ZegoExpressEventHandler.h | 拉流状态更新 |
| `onPlayerQualityUpdate(_:quality:)` | ZegoExpressEventHandler.h | 拉流质量更新 |
| `onPlayerMediaEvent(_:event:)` | ZegoExpressEventHandler.h | 播放媒体事件 |
| `onPlayerSyncRecvSEI(_:streamID:)` | ZegoExpressEventHandler.h | 同步收到 SEI |

---

## 枚举类型白名单

### 音频相关

| Swift 枚举 | 原始值 | 头文件 |
|-----------|--------|--------|
| `ZegoAudioChannel.mono` | `ZegoAudioChannelMono = 1` | ZegoExpressDefines.h:764 |
| `ZegoAudioChannel.stereo` | `ZegoAudioChannelStereo = 2` | ZegoExpressDefines.h:766 |
| `ZegoAudioSampleRate.rate44K` | `ZegoAudioSampleRate44K` | ZegoExpressDefines.h |
| `ZegoAudioSampleRate.rate48K` | `ZegoAudioSampleRate48K` | ZegoExpressDefines.h |

### 音频编解码

| Swift 枚举 | 原始值 | 头文件 |
|-----------|--------|--------|
| `ZegoAudioCodecID.default` | `ZegoAudioCodecIDDefault = 0` | ZegoExpressDefines.h:790 |
| `ZegoAudioCodecID.normal` | `ZegoAudioCodecIDNormal = 1` | ZegoExpressDefines.h:792 |
| `ZegoAudioCodecID.normal2` | `ZegoAudioCodecIDNormal2 = 2` | ZegoExpressDefines.h:794 |
| `ZegoAudioCodecID.low3` | `ZegoAudioCodecIDLow3 = 6` | ZegoExpressDefines.h:802 |

### 音频设备模式

| Swift 枚举 | 原始值 | 头文件 |
|-----------|--------|--------|
| `ZegoAudioDeviceMode.communication` | `ZegoAudioDeviceModeCommunication = 1` | ZegoExpressDefines.h:1212 |
| `ZegoAudioDeviceMode.general` | `ZegoAudioDeviceModeGeneral = 2` | ZegoExpressDefines.h:1214 |
| `ZegoAudioDeviceMode.auto` | `ZegoAudioDeviceModeAuto = 3` | ZegoExpressDefines.h:1216 |
| `ZegoAudioDeviceMode.communication2` | `ZegoAudioDeviceModeCommunication2 = 4` | ZegoExpressDefines.h:1218 |
| `ZegoAudioDeviceMode.communication3` | `ZegoAudioDeviceModeCommunication3 = 5` | ZegoExpressDefines.h:1220 |

### 回声消除模式

| Swift 枚举 | 原始值 | 头文件 |
|-----------|--------|--------|
| `ZegoAECMode.aggressive` | `ZegoAECModeAggressive = 0` | ZegoExpressDefines.h:844 |
| `ZegoAECMode.medium` | `ZegoAECModeMedium = 1` | ZegoExpressDefines.h:846 |
| `ZegoAECMode.soft` | `ZegoAECModeSoft = 2` | ZegoExpressDefines.h:848 |
| `ZegoAECMode.ai` | `ZegoAECModeAI = 3` | ZegoExpressDefines.h:850 |

### 噪声抑制模式

| Swift 枚举 | 原始值 | 头文件 |
|-----------|--------|--------|
| `ZegoANSMode.soft` | `ZegoANSModeSoft = 0` | ZegoExpressDefines.h:860 |
| `ZegoANSMode.medium` | `ZegoANSModeMedium = 1` | ZegoExpressDefines.h:862 |
| `ZegoANSMode.aggressive` | `ZegoANSModeAggressive = 2` | ZegoExpressDefines.h:864 |

### 推流通道

| Swift 枚举 | 原始值 | 头文件 |
|-----------|--------|--------|
| `ZegoPublishChannel.main` | `ZegoPublishChannelMain` | ZegoExpressDefines.h |
| `ZegoPublishChannel.aux` | `ZegoPublishChannelAux` | ZegoExpressDefines.h |

### 音频源类型

| Swift 枚举 | 原始值 | 头文件 |
|-----------|--------|--------|
| `ZegoAudioSourceType.default` | `ZegoAudioSourceTypeDefault` | ZegoExpressDefines.h |
| `ZegoAudioSourceType.custom` | `ZegoAudioSourceTypeCustom` | ZegoExpressDefines.h |
| `ZegoAudioSourceType.file` | `ZegoAudioSourceTypeFile` | ZegoExpressDefines.h |
| `ZegoAudioSourceType.mediaPlayer` | `ZegoAudioSourceTypeMediaPlayer` | ZegoExpressDefines.h |

### 房间状态

| Swift 枚举 | 原始值 | 头文件 |
|-----------|--------|--------|
| `ZegoRoomState.disconnected` | `ZegoRoomStateDisconnected` | ZegoExpressDefines.h |
| `ZegoRoomState.connecting` | `ZegoRoomStateConnecting` | ZegoExpressDefines.h |
| `ZegoRoomState.connected` | `ZegoRoomStateConnected` | ZegoExpressDefines.h |

### 更新类型

| Swift 枚举 | 原始值 | 头文件 |
|-----------|--------|--------|
| `ZegoUpdateType.add` | `ZegoUpdateTypeAdd` | ZegoExpressDefines.h |
| `ZegoUpdateType.delete` | `ZegoUpdateTypeDelete` | ZegoExpressDefines.h |

### 场景类型

| Swift 枚举 | 原始值 | 头文件 |
|-----------|--------|--------|
| `ZegoScenario.general` | `ZegoScenarioGeneral` | ZegoExpressDefines.h |
| `ZegoScenario.highQualityChatroom` | `ZegoScenarioHighQualityChatroom` | ZegoExpressDefines.h |

---

## 配置类白名单

| Swift 类 | 头文件 | 主要属性 |
|---------|--------|---------|
| `ZegoEngineConfig()` | ZegoExpressDefines.h | `advancedConfig: [String: String]` |
| `ZegoEngineProfile()` | ZegoExpressDefines.h | `appID`, `appSign`, `scenario` |
| `ZegoRoomConfig()` | ZegoExpressDefines.h | `isUserStatusNotify`, `maxMemberCount` |
| `ZegoUser(userID: userName:)` | ZegoExpressDefines.h | `userID`, `userName` |
| `ZegoStream()` | ZegoExpressDefines.h | `streamID`, `extraInfo` |
| `ZegoPublisherConfig()` | ZegoExpressDefines.h:2594 | `roomID`, `forceSynchronousNetworkTime` **(无 streamID!)** |
| `ZegoPlayerConfig()` | ZegoExpressDefines.h | `roomID`, `resourceMode` |
| `ZegoCustomAudioProcessConfig()` | ZegoExpressDefines.h | `channel`, `sampleRate`, `samples` |
| `ZegoCustomAudioConfig()` | ZegoExpressDefines.h | `sourceType` |

---

## 头文件索引

```
lib/ZegoExpressEngine.xcframework/ios-arm64/ZegoExpressEngine.framework/Headers/
├── ZegoExpressEngine.h              # 主类
├── ZegoExpressEngine+Room.h         # 房间
├── ZegoExpressEngine+Publisher.h    # 推流
├── ZegoExpressEngine+Player.h       # 拉流
├── ZegoExpressEngine+MediaPlayer.h  # 媒体播放器
├── ZegoExpressEngine+CustomAudioIO.h  # 自定义音频IO
├── ZegoExpressEngine+Preprocess.h   # 音频前处理
├── ZegoExpressEngine+Device.h       # 设备
├── ZegoExpressEngine+IM.h           # 即时消息
├── ZegoExpressDefines.h             # 类型定义
└── ZegoExpressEventHandler.h        # 回调协议
```

---

## 使用示例

```swift
// ✅ 正确：基于白名单调用
// 来源: ZegoExpressEngine+CustomAudioIO.h
let engine = ZegoExpressEngine.shared()  // 非Optional
engine.enableCustomAudioCaptureProcessing(true, config: customConfig)

// ✅ 正确：基于白名单调用
// 来源: ZegoExpressEngine+Player.h:62
engine.startPlayingStream(streamID)

// ❌ 错误：不在白名单中，需要先验证
// engine.someMethodNotInWhitelist()  // 禁止使用
```

---

## 更新日志

| 日期 | SDK 版本 | 更新内容 |
|------|---------|---------|
| 2026-03-03 | 3.23.1 (47919) | 初始版本，扫描所有头文件生成白名单 |
