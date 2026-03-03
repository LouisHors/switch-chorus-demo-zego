# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Personal Rules

- Always respond with **Simplified-Chinese/中文**

## Project Overview

This is an iOS application built with Swift 5.0 and UIKit, targeting iOS 18.5+.

- **Bundle Identifier**: `im.zego.switch-chorus-demo`
- **Development Team**: Y98YBP7T6D
- **Language**: Swift 5.0
- **UI Framework**: UIKit with Storyboards
- **Architecture**: Uses SceneDelegate (iOS 13+ multi-scene support)

## Building and Running

```bash
# Build the project from command line
xcodebuild -project switch-chorus-demo.xcodeproj -scheme switch-chorus-demo -configuration Debug

# Build for testing
xcodebuild test -project switch-chorus-demo.xcodeproj -scheme switch-chorus-demo -destination 'platform=iOS Simulator,name=iPhone 16'

# Clean build
xcodebuild clean -project switch-chorus-demo.xcodeproj -scheme switch-chorus-demo
```

For development, open `switch-chorus-demo.xcodeproj` in Xcode 16.4+ and use Cmd+R to run.

## Project Structure

```
switch-chorus-demo/
├── switch-chorus-demo/
│   ├── AppDelegate.swift          # App lifecycle entry point (@main)
│   ├── SceneDelegate.swift        # Scene lifecycle management
│   ├── ViewController.swift       # Root view controller
│   ├── Info.plist                 # App configuration
│   ├── Assets.xcassets/           # Images, colors, app icons
│   └── Base.lproj/                # Storyboards (Main, LaunchScreen)
└── switch-chorus-demo.xcodeproj/  # Xcode project file
```

## Architecture Notes

- This is a standard UIKit-based iOS app using the Model-View-Controller (MVC) pattern
- The app uses storyboards for UI layout (Main.storyboard, LaunchScreen.storyboard)
- SceneDelegate handles window and scene management for iOS 13+ multi-window support
- Code signing is set to Automatic using the configured development team

## Git Configuration

- **Remote**: `git@gl.zego.im:playground/weplay-switch-chorus-demo.git`
- **Default branch**: `main`

## ZegoExpressEngine SDK 使用规范

### SDK 位置
```
switch-chorus-demo/lib/ZegoExpressEngine.xcframework/
├── ios-arm64/ZegoExpressEngine.framework/Headers/      # 真机头文件
└── ios-arm64_x86_64-simulator/ZegoExpressEngine.framework/Headers/  # 模拟器头文件
```

### 重要注意事项

#### ⚠️ 强制规则：调用任何 Zego API 前必须先验证

**使用 `/verify-zego-api` Skill 验证所有 Zego API 调用**

工作流程：
1. 查询 Skill 中的【已验证 API 缓存】
2. 如果缓存中有 → 直接使用
3. 如果缓存中没有 → 查头文件验证 → 更新缓存 → 使用

**禁止行为：**
- ❌ 猜测 API 名称或参数
- ❌ 基于其他语言 SDK 推测
- ❌ 假设返回类型

**正确做法：**
- ✅ 先查缓存，再查头文件
- ✅ 代码中标注 API 来源
- ✅ 验证新 API 后更新缓存

#### 1. `ZegoExpressEngine.shared()` 返回非 Optional
```swift
// ❌ 错误 - 会导致编译错误
guard let engine = ZegoExpressEngine.shared() else { return }

// ✅ 正确 - 直接使用
let engine = ZegoExpressEngine.shared()
```
SDK 头文件定义：`+ (ZegoExpressEngine *)sharedEngine;` 返回非 nullable 类型。

#### 2. 使用 SDK 前先查看头文件
SDK 是 Objective-C 编写，在 Swift 环境下使用时：
- 先查看 `lib/ZegoExpressEngine.xcframework/ios-arm64/.../Headers/` 下的头文件
- 确认方法签名、返回类型、参数类型
- 枚举值在 Swift 中使用 `.xxx` 简写形式

#### 3. Objective-C 到 Swift 常见映射
| Objective-C | Swift |
|-------------|-------|
| `ZegoAudioChannelMono` | `.mono` |
| `ZegoAudioSampleRate48K` | `.rate48K` |
| `ZegoPublishChannelAux` | `.aux` |
| `[obj method:YES]` | `obj.method(true)` |

### 技术方案文档
核心合唱场景方案见 `docs/双人轮唱的合唱场景方案.md`
