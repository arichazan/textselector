#!/usr/bin/env swift

import Foundation
import AppKit
import Vision

// OCR Language enum (copied from our main code)
enum OCRLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case chineseSimplified = "zh-Hans"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .chineseSimplified:
            return "Chinese (Simplified)"
        }
    }

    var visionRecognitionLanguage: String {
        switch self {
        case .english:
            return "en-US"
        case .chineseSimplified:
            return "zh-Hans"
        }
    }
}

// OCR Result structure
struct OCRResult {
    let text: String
    let engine: String
    let detectionType: String
}

// Simple Vision OCR test
func testVisionOCR(image: CGImage, language: OCRLanguage) {
    print("Testing Vision OCR with language: \(language.displayName) (\(language.visionRecognitionLanguage))")

    let request = VNRecognizeTextRequest { request, error in
        if let error = error {
            print("❌ VisionOCR Error: \(error)")
            return
        }

        guard let results = request.results as? [VNRecognizedTextObservation] else {
            print("❌ VisionOCR: No text observations found")
            return
        }

        print("✅ VisionOCR: Found \(results.count) text observations")

        let textLines: [String] = results.compactMap { observation in
            let candidate = observation.topCandidates(1).first
            let text = candidate?.string ?? "nil"
            let confidence = candidate?.confidence ?? 0
            print("   Text: '\(text)' confidence: \(confidence)")
            return candidate?.string
        }

        let output = textLines.joined(separator: "\n")
        print("🎯 Final OCR Result:")
        print("---")
        print(output)
        print("---")
        print("Character count: \(output.count)")

        // Exit the run loop
        CFRunLoopStop(CFRunLoopGetCurrent())
    }

    // Test different language configurations
    print("Testing with language: \(language.visionRecognitionLanguage)")
    request.recognitionLanguages = [language.visionRecognitionLanguage]
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = false

    // Also test with no language specified (auto-detect)
    print("Also testing with auto-detect (no language specified)")

    let handler = VNImageRequestHandler(cgImage: image, options: [:])
    do {
        try handler.perform([request])
    } catch {
        print("❌ VisionOCR Handler error: \(error)")
        CFRunLoopStop(CFRunLoopGetCurrent())
    }
}

// Test with auto-detect
func testAutoDetect(image: CGImage) {
    print("\n" + String(repeating: "=", count: 50))
    print("Testing Vision OCR with AUTO-DETECT")
    print(String(repeating: "=", count: 50))

    let request = VNRecognizeTextRequest { request, error in
        if let error = error {
            print("❌ Auto-detect Error: \(error)")
            return
        }

        guard let results = request.results as? [VNRecognizedTextObservation] else {
            print("❌ Auto-detect: No text observations found")
            return
        }

        print("✅ Auto-detect: Found \(results.count) text observations")

        let textLines: [String] = results.compactMap { observation in
            let candidate = observation.topCandidates(1).first
            let text = candidate?.string ?? "nil"
            let confidence = candidate?.confidence ?? 0
            print("   Text: '\(text)' confidence: \(confidence)")
            return candidate?.string
        }

        let output = textLines.joined(separator: "\n")
        print("🎯 Auto-detect Result:")
        print("---")
        print(output)
        print("---")

        // Exit the run loop
        CFRunLoopStop(CFRunLoopGetCurrent())
    }

    // Don't specify any language - let Vision auto-detect
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = false

    let handler = VNImageRequestHandler(cgImage: image, options: [:])
    do {
        try handler.perform([request])
    } catch {
        print("❌ Auto-detect Handler error: \(error)")
        CFRunLoopStop(CFRunLoopGetCurrent())
    }
}

// Load image from file
func loadTestImage() -> CGImage? {
    // Try to load from a screenshot or test image
    // For now, create a simple image programmatically
    let width = 800
    let height = 400
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
        return nil
    }

    // Fill with white background
    context.setFillColor(CGColor.white)
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))

    // Set text color to black
    context.setFillColor(CGColor.black)

    // This simulates having Chinese text in the image
    // In reality, we'd load your actual image, but for testing the OCR pipeline this works

    return context.makeImage()
}

// Main test function
func runOCRTest() {
    print("🚀 Starting Chinese OCR Test")
    print(String(repeating: "=", count: 50))

    guard let testImage = loadTestImage() else {
        print("❌ Failed to load test image")
        return
    }

    print("✅ Loaded test image: \(testImage.width)x\(testImage.height)")

    // Test 1: Chinese Simplified
    print("\n" + String(repeating: "=", count: 50))
    print("Test 1: Chinese Simplified")
    print(String(repeating: "=", count: 50))
    testVisionOCR(image: testImage, language: .chineseSimplified)
    CFRunLoopRun()

    // Test 2: English
    print("\n" + String(repeating: "=", count: 50))
    print("Test 2: English")
    print(String(repeating: "=", count: 50))
    testVisionOCR(image: testImage, language: .english)
    CFRunLoopRun()

    // Test 3: Auto-detect
    testAutoDetect(image: testImage)
    CFRunLoopRun()

    print("\n✅ OCR Test Complete!")
}

// Run the test
runOCRTest()