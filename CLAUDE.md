# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SnapText is a native macOS menu bar utility for on-screen text capture using OCR. It's built as a Swift Package Manager executable targeting macOS 14+ using SwiftUI.

## Architecture

The codebase follows a modular architecture organized into distinct functional areas:

- **Application/**: App lifecycle management with `SnapTextApp` (SwiftUI entry point), `SnapTextAppDelegate` (menu bar setup), and `StatusItemController` for the status bar item
- **Capture/**: Core capture functionality with `SelectionOverlayWindowController` for the selection UI and `CaptureController` for screenshot pipeline
- **OCR/**: Text recognition services with `VisionOCRService` (primary) and `TesseractOCRService` (fallback)
- **Settings/**: User preferences backed by `UserDefaults` via `UserSettings`
- **Preferences/**: SwiftUI preferences interface with MVVM pattern (`PreferencesView` + `PreferencesViewModel`)
- **UI/**: Reusable UI components including `ToastPresenter` for notifications and `HotkeyRecorderView` for shortcut configuration
- **Permissions/**: Screen recording permission handling via `ScreenPermissionManager`
- **Application/Hotkeys/**: Global hotkey system with `GlobalHotkeyManager`, `HotkeyConfiguration`, and `KeyCodeTranslator`
- **Utilities/**: Helper classes for login items and display management

## Development Commands

### Building
```bash
# Debug build
swift build

# Release build
swift build -c release

# Create distributable app bundle
./build_release.sh
```

### Running
```bash
# Run from command line (debug)
swift run

# Open in Xcode (recommended for development)
# Use File > Open and select Package.swift
```

### Development Notes
- Requires macOS 14+ SDK (Xcode 15+)
- Uses SwiftUI for UI with AppKit integration for menu bar and overlays
- No automated tests included in MVP - manual verification recommended
- Screen recording permission required for functionality
- Optional Tesseract dependency for OCR fallback (logs warning if unavailable)

## Key Development Patterns

- **Settings Management**: All user preferences flow through `UserSettings.shared` singleton
- **OCR Pipeline**: Vision framework first, automatic fallback to Tesseract on failure
- **Window Management**: Overlay windows use `NSPanel` with specific level settings for capture mode
- **Hotkey System**: Carbon-based global hotkey registration with SwiftUI configuration interface
- **Toast Notifications**: Centralized via `ToastPresenter` with configurable display

## Performance Targets
- OCR processing: <2 seconds for 1080p selections
- Idle resource usage: ≤5% CPU, <100MB RAM
- Large selections auto-downscaled to maintain performance