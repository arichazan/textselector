#!/usr/bin/env swift

import Foundation
import AppKit
import Vision

print("🚀 Chinese OCR Test with Real Content")
print("This test will take a screenshot and test OCR on it")
print("Please have some Chinese text visible on your screen")

// Take a screenshot of the main display
guard let screen = NSScreen.main else {
    print("❌ No main screen found")
    exit(1)
}

let rect = screen.frame
guard let cgImage = CGWindowListCreateImage(rect, .optionOnScreenOnly, kCGNullWindowID, .bestResolution) else {
    print("❌ Failed to capture screenshot")
    exit(1)
}

print("✅ Screenshot captured: \(cgImage.width)x\(cgImage.height)")

// Test different language configurations
let semaphore = DispatchSemaphore(value: 0)

func testOCR(language: String?, description: String) {
    print("\n" + String(repeating: "=", count: 50))
    print("Testing: \(description)")
    print(String(repeating: "=", count: 50))

    let request = VNRecognizeTextRequest { request, error in
        defer { semaphore.signal() }

        if let error = error {
            print("❌ Error: \(error)")
            return
        }

        let results = request.results as? [VNRecognizedTextObservation] ?? []
        print("✅ Found \(results.count) text observations")

        if results.isEmpty {
            print("ℹ️  No text detected")
            return
        }

        print("\n📝 Detected text:")
        for (i, result) in results.enumerated() {
            if let candidate = result.topCandidates(1).first {
                let confidence = String(format: "%.2f", candidate.confidence)
                print("  \(i+1): '\(candidate.string)' (confidence: \(confidence))")
            }
        }

        // Show all text combined
        let allText = results.compactMap { result in
            result.topCandidates(1).first?.string
        }.joined(separator: "\n")

        if !allText.isEmpty {
            print("\n🎯 Combined text:")
            print("---")
            print(allText)
            print("---")
        }
    }

    if let language = language {
        request.recognitionLanguages = [language]
        print("🌐 Language: \(language)")
    } else {
        print("🌐 Language: Auto-detect")
    }

    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = false

    let handler = VNImageRequestHandler(cgImage: cgImage)
    do {
        try handler.perform([request])
        semaphore.wait()
    } catch {
        print("❌ OCR error: \(error)")
        semaphore.signal()
    }
}

// Test 1: Auto-detect
testOCR(language: nil, description: "Auto-detect")

// Test 2: English
testOCR(language: "en-US", description: "English")

// Test 3: Chinese Simplified
testOCR(language: "zh-Hans", description: "Chinese Simplified")

// Test 4: Alternative Chinese codes
testOCR(language: "zh-CN", description: "Chinese (zh-CN)")
testOCR(language: "zh", description: "Chinese (zh)")

print("\n✅ All tests complete!")
print("💡 If you see Chinese text detected, the OCR is working correctly.")
print("💡 If not, the issue might be with language support or text clarity.")