# SnapText for Mac

## Product Requirements Document (PRD)

**Owner:** Ari  
**Version:** Draft v1.0  

---

## 1. Overview
SnapText is a lightweight macOS utility that lets users instantly capture text from any portion of their screen and copy it to the clipboard. The app runs locally, prioritizes speed and privacy, and integrates with macOS system features (hotkeys, menu bar, clipboard).

Goal: reduce the process of extracting text from an image, video, PDF, or any app on screen to a single keyboard shortcut.

---

## 2. Objectives & Success Criteria

- **Primary Objective:** Enable users to capture text from any on-screen source in under 3 seconds.  
- **Secondary Objectives:**  
  - No internet required (local OCR).  
  - Minimal system resource usage.  
  - Seamless integration with macOS UX.  

**Success Metrics:**  
- OCR capture time < 2 seconds.  
- Accuracy ≥ 95% for English text on clean screenshots.  
- ≤ 5% CPU usage when idle.  
- < 100 MB memory footprint.  

---

## 3. Key Features

### Core
- Screen area OCR capture via global hotkey.  
- Drag rectangle to select screen area.  
- Captured text automatically copied to clipboard.  
- Menu bar app with preferences: hotkey mapping, OCR language, notifications, launch at startup.  
- Offline OCR engine (macOS Vision framework, fallback Tesseract).  

### Secondary (Phase 2)
- History of past captures.  
- Export as plain text, markdown, or PDF.  
- Smart cleanup (remove line breaks, fix hyphenation).  
- Multi-language auto-detect.  

---

## 4. User Stories

- Student grabs text from a YouTube video lecture to paste into notes.  
- Developer copies text from a non-selectable error dialog.  
- Researcher extracts citations from scanned PDFs.  
- Casual user copies phone numbers or addresses from an image.  

---

## 5. Technical Requirements

- **Platform:** macOS 14+ (Sonoma, Sequoia).  
- **Language:** Swift/SwiftUI.  
- **OCR Engine:** macOS Vision framework (preferred), fallback Tesseract.  
- **Performance:** OCR < 2s for 1080p screen area.  
- **Privacy:** 100% local OCR, no cloud dependency.  
- **Distribution:** Mac App Store + direct dmg.  

---

## 6. UI/UX

- **Activation:** Global hotkey triggers dark overlay → drag to select region → OCR runs instantly.  
- **Menu Bar:** Minimalist dropdown with “Capture Text,” Preferences, optional recent captures.  
- **Feedback:** Silent copy by default; optional toast “Copied to Clipboard.”  

---

## 7. Timeline (MVP)

- Week 1–2: OCR prototype, Vision framework integration.  
- Week 3–4: Capture overlay + hotkey system.  
- Week 5–6: Clipboard + menu bar app.  
- Week 7: Preferences + polish.  
- Week 8: QA, bug fixes, App Store submission.  
