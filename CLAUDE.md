# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Personal Rules

- Always respond with **Simplified-Chinese/中文**

## Beads 任务追踪 - 全自动化工作流

**核心原则：beads 是 AI 的内部工具，对用户完全透明。用户只需说"做什么"，AI 负责所有管理工作。**

### 完整自动化流程

```
用户需求→ AI 分析拆分→ 自动创建任务→ 自动分配→ 并行执行→ 自动关闭
```

### 1. 任务拆分（自动）

当用户提出需求时，AI 必须：
1. 分析需求复杂度
2. 如果需要多个步骤，自动拆分成子任务
3. 创建 Epic（大需求）或 Task（小需求）
4. 设置任务依赖关系

```bash
# 示例：用户说"实现歌词同步功能"
# AI 自动执行：
bd create --title="集成 ZegoKTV 歌词组件" --type=task
bd create --title="实现歌词进度同步" --type=task
bd create --title="添加歌词 UI 展示" --type=task
bd dep add 歌词UI 组件集成  # UI 依赖组件集成
```

### 2. 任务分配（自动）

AI 必须判断：
- 哪些任务可以**并行**（无依赖）
- 哪些任务必须**串行**（有依赖）
- 使用 subagent 并行处理独立任务

```bash
# 并行任务：使用 Task tool 启动多个 subagent
# 串行任务：按依赖顺序执行
```

### 3. 任务执行（自动）

| 时机 | 自动操作 |
|------|----------|
| 开始实现功能前 | `bd update <id> --status=in_progress` |
| 发现新的子任务时 | `bd create` 创建并设置依赖 |
| 完成功能后 | `bd close <id>` |
| 会话开始时 | 分析 git history，校准 beads 状态 |

### 4. 状态校准逻辑

```
1. 获取 bd list --status=open
2. 获取 git log --since="7 days ago"
3. 对比提交信息与任务描述：
   - 提交内容涵盖任务 → 关闭任务
   - 部分完成 → 标记 in_progress
   - 未开始 → 保持 open
4. 无需用户确认，直接执行
```

### 5. 用户视角

- 用户只负责：告诉 AI 做什么
- AI 负责：分析、拆分、创建、分配、执行、关闭
- 用户查看：`bd list` 或 `/bd-kanban`

### 6. 强制规则

- **禁止**询问用户是否创建/关闭任务
- **禁止**等待用户确认后才操作 beads
- **必须**主动分析并自动执行所有 beads 操作

### 7. Horspowers + Beads 整合

| Horspowers Skill | 产出物 | Beads 操作 |
|------------------|--------|------------|
| `/horspowers:brainstorming` | design 文档 | 创建/更新 Epic，填充 design 字段 |
| `/horspowers:writing-plans` | plan + tasks | 创建 Tasks，设置依赖关系 |
| `/horspowers:executing-plans` | 更新 task 文档 | 同步更新 Task 状态 |
| `/horspowers:systematic-debugging` | debug 报告 | 创建 Bug issue |
| `/horspowers:code-review` | review 报告 | 创建 Review task |

**自动化流程：**
```
用户需求→ /brainstorming → bd create epic + design
                  ↓
         /writing-plans → bd create tasks + deps
                  ↓
        /executing-plans → bd update status
                  ↓
               完成→ bd close
```

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
