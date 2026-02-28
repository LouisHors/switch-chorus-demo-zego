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
