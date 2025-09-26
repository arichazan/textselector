# SnapText

SnapText is a native macOS menu bar utility that captures on-screen text with a single hotkey. It layers a lightweight selection overlay on top of the current display, performs on-device OCR, and copies the recognized text to the clipboard with optional toast feedback. The MVP prioritises speed (<2s OCR on 1080p selections) and local processing for privacy.

## Highlights
- **Instant capture:** Default shortcut `⌘⇧2` launches a drag-to-select overlay; Escape or right-click cancels silently.
- **On-device OCR:** Uses the macOS Vision framework first and automatically falls back to Tesseract when available. Failure messaging is intentionally engine-agnostic.
- **Clipboard ready:** Successful captures write directly to the clipboard and can surface an optional confirmation toast.
- **Menu bar presence:** Status item with quick “Capture Text/QR/Bar Code”, Preferences, and Quit entries keeps the utility discoverable without a Dock icon.
- **Configurable preferences:** Users can remap the shortcut (modifier combos only), toggle the confirmation toast, select the OCR language (English for MVP), and opt into launch at login.

## Project Structure
```
Package.swift
Sources/
  SnapText/
    Application/        // App lifecycle, status item, and global hotkey wiring
    Capture/            // Selection overlay windows and screenshot pipeline
    Clipboard/          // Clipboard manager
    OCR/                // Vision + Tesseract OCR services and result models
    Permissions/        // Screen recording permission helper
    Preferences/        // Preferences view + view model
    Settings/           // User defaults-backed settings model
    UI/                 // Toast presenter, hotkey recorder, reusable views
    Utilities/          // Login item manager, NSScreen helpers
    Resources/          // Info.plist for the menu bar app bundle
prd.md
planning.md
```

## Getting Started
1. Open the repository in Xcode 15+ (macOS 14 SDK).
2. Use `File > Open...` and select `Package.swift` to generate an executable scheme for the SwiftUI app.
3. Ensure [Tesseract OCR](https://github.com/tesseract-ocr/tesseract) and the `TesseractOCRiOS`/macOS bindings are available if you want fallback OCR at runtime. Without it, SnapText logs a warning and surfaces the generic failure toast when Vision also fails.
4. Build & run the `SnapText` scheme. Grant screen recording permission when prompted.

## Usage Notes
- Press `⌘⇧2` (or your remapped shortcut) to invoke capture mode.
- Drag to highlight the region that contains text; SnapText auto-downscales large selections to preserve the <2s performance target.
- On success, text is copied to the clipboard and the optional toast reads “Copied to Clipboard.” Failures render the non-specific toast “Text could not be captured.”
- Preferences (⌘,) let you toggle the toast, adjust the hotkey, choose OCR language, and control launch-at-login behaviour.

## Permissions & Privacy
- SnapText requires the macOS **Screen Recording** entitlement to read pixels. A single in-app explainer precedes the standard system dialog.
- OCR is processed entirely on-device. No capture data leaves the user’s Mac.

## Testing
Automated tests are not included for the MVP; manual verification against known samples is recommended per the PRD. When running locally, validate:
- OCR speed on 1080p selections (<2 seconds target).
- Idle resource usage (≤5% CPU, <100 MB RAM) via Activity Monitor.
- Shortcut conflicts on Apple Silicon MacBook Pro/Air and one Intel Mac, across Retina, 4K, and 1080p displays.

## Roadmap
Future phases (see `planning.md`) add multilingual OCR, capture history, export formats, and richer notification options while keeping the MVP minimal.
