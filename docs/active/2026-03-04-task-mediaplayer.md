# 任务: 实现 ZegoMediaPlayer 伴奏播放器

## 任务描述

基于 ZegoExpressEngine SDK 的 ZegoMediaPlayer 实现完整的伴奏播放器，包含控制器层、视图层和集成层。

## 相关文档

- **计划文档**: [../plans/2026-03-04-implement-mediaplayer.md](../plans/2026-03-04-implement-mediaplayer.md)
- **设计文档**: [../plans/2026-03-04-design-mediaplayer.md](../plans/2026-03-04-design-mediaplayer.md)
- **Beads Epic**: switch-chorus-demo-m67

## 实施计划

### Task 1: 创建 AccompanimentPlayerController
- [ ] 创建文件 `AccompanimentPlayerController.swift`
- [ ] 实现播放状态枚举和错误类型
- [ ] 实现播放器生命周期管理（创建/销毁）
- [ ] 实现播放控制方法（play/pause/stop/seek）
- [ ] 实现 SDK 事件回调处理
- [ ] Commit

### Task 2: 创建 PlayerControlView
- [ ] 创建文件 `PlayerControlView.swift`
- [ ] 实现橙色渐变卡片 UI
- [ ] 实现歌曲名称标签
- [ ] 实现进度条和时间显示
- [ ] 实现播放/暂停/停止按钮
- [ ] Commit

### Task 3: 集成到合唱页面
- [ ] 修改 `TeamChorusView.swift` 添加播放器视图
- [ ] 修改 `TeamChorusViewController.swift` 添加控制器
- [ ] 实现播放器委托回调
- [ ] 实现视图委托回调
- [ ] 更新选歌回调，自动加载歌曲
- [ ] Commit

## 验收标准

- [ ] AccompanimentPlayerController 封装完整，状态机工作正常
- [ ] PlayerControlView UI 与设计一致，橙色渐变效果正确
- [ ] 播放器控制功能正常（播放/暂停/停止/进度跳转）
- [ ] 进度回调准确，时间显示更新及时
- [ ] 点歌后自动加载，上麦后自动播放
- [ ] 代码无编译警告，内存无泄漏

## 进展记录

- **2026-03-04**: 任务创建，设计文档完成，计划文档完成
- **2026-03-04**: Task 1 完成 - AccompanimentPlayerController 实现并编译通过
- **2026-03-04**: Task 2 完成 - PlayerControlView 实现并编译通过
- **2026-03-04**: Task 3 完成 - 集成到 TeamChorusViewController 并编译通过
- **2026-03-04**: 修复播放器控制按钮和交互问题（5个bug）
- **2026-03-04**: 修复下麦后歌曲名称重置问题
- **2026-03-04**: 全部任务完成，最终编译验证通过

## 检查点

- 批次: 1 (全部完成)
- 完成时间: 2026-03-04
- 状态: ✅ 已完成

## Bug 修复记录

| Issue | 描述 | 状态 |
|-------|------|------|
| switch-chorus-demo-m67.4 | 修复播放器控制按钮和交互问题（5个bug） | ✅ 已关闭 |
| switch-chorus-demo-m67.5 | 修复下麦后重置歌曲名称 | ✅ 已关闭 |

### switch-chorus-demo-m67.4 修复内容
1. 播放按钮与暂停按钮分开
2. 修复恢复播放失败问题（区分 play 和 resume）
3. 停止按钮点击后进度条归零
4. 下麦时停止播放并重置 UI
5. 进度条设置 isExclusiveTouch 防止冲突
