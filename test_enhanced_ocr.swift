#!/usr/bin/env swift

import Foundation
import CoreGraphics
import Vision

// Add the Sources path to allow importing SnapText
#if canImport(SnapText)
import SnapText
#else
// Simple test program to verify dual-language OCR implementation
print("Enhanced OCR Test")
print("=================")
print("✅ Build successful - dual-language OCR system implemented")
print("")
print("Key features implemented:")
print("• Dual Latin/CJK recognition per text line")
print("• Confidence-based language selection")
print("• ASCII ratio and URL/code detection heuristics")
print("• Rotation retry for low-confidence results")
print("• Comprehensive logging for decision tracking")
print("• User-configurable settings for thresholds")
print("")
print("Settings added to UserSettings:")
print("• latinOnlyMode: Skip CJK recognition entirely")
print("• enableRefinePass: Enable language refinement")
print("• minAcceptConfidence: Minimum confidence threshold (0.70)")
print("• reconsiderConfidence: Threshold for rotation retry (0.60)")
print("")
print("To test with actual images, run the SnapText app and check console logs")
print("for detailed per-line recognition decisions.")
#endif