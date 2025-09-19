#!/usr/bin/env swift

import Foundation
import AppKit
import Vision

print("🚀 Starting Simple Chinese OCR Test")

// Create a simple test image
let width = 400
let height = 200
let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
    print("❌ Failed to create context")
    exit(1)
}

// Fill with white background
context.setFillColor(CGColor.white)
context.fill(CGRect(x: 0, y: 0, width: width, height: height))

guard let testImage = context.makeImage() else {
    print("❌ Failed to create test image")
    exit(1)
}

print("✅ Created test image: \(testImage.width)x\(testImage.height)")

// Test Vision OCR capabilities
let semaphore = DispatchSemaphore(value: 0)

print("\n📋 Testing supported languages...")
if #available(macOS 13.0, *) {
    print("macOS 13+ - checking new API")
} else {
    do {
        let supportedLangs = try VNRecognizeTextRequest.supportedRecognitionLanguages(for: .accurate, revision: VNRecognizeTextRequestRevision1)
        print("Supported languages: \(supportedLangs)")

        let chineseSupported = supportedLangs.contains("zh-Hans") || supportedLangs.contains("zh_CN") || supportedLangs.contains("zh")
        print("Chinese supported: \(chineseSupported)")
    } catch {
        print("Error getting supported languages: \(error)")
    }
}

print("\n📝 Testing OCR with different language settings...")

// Test 1: Auto-detect (no language specified)
print("\nTest 1: Auto-detect")
let request1 = VNRecognizeTextRequest { request, error in
    defer { semaphore.signal() }

    if let error = error {
        print("❌ Auto-detect error: \(error)")
        return
    }

    let results = request.results as? [VNRecognizedTextObservation] ?? []
    print("✅ Auto-detect found \(results.count) observations")

    for (i, result) in results.enumerated() {
        if let candidate = result.topCandidates(1).first {
            print("  \(i+1): '\(candidate.string)' confidence: \(candidate.confidence)")
        }
    }
}

request1.recognitionLevel = .accurate
let handler1 = VNImageRequestHandler(cgImage: testImage)

do {
    try handler1.perform([request1])
    semaphore.wait()
} catch {
    print("❌ Auto-detect perform error: \(error)")
}

// Test 2: English
print("\nTest 2: English (en-US)")
let request2 = VNRecognizeTextRequest { request, error in
    defer { semaphore.signal() }

    if let error = error {
        print("❌ English error: \(error)")
        return
    }

    let results = request.results as? [VNRecognizedTextObservation] ?? []
    print("✅ English found \(results.count) observations")

    for (i, result) in results.enumerated() {
        if let candidate = result.topCandidates(1).first {
            print("  \(i+1): '\(candidate.string)' confidence: \(candidate.confidence)")
        }
    }
}

request2.recognitionLanguages = ["en-US"]
request2.recognitionLevel = .accurate
let handler2 = VNImageRequestHandler(cgImage: testImage)

do {
    try handler2.perform([request2])
    semaphore.wait()
} catch {
    print("❌ English perform error: \(error)")
}

// Test 3: Chinese (zh-Hans)
print("\nTest 3: Chinese Simplified (zh-Hans)")
let request3 = VNRecognizeTextRequest { request, error in
    defer { semaphore.signal() }

    if let error = error {
        print("❌ Chinese error: \(error)")
        return
    }

    let results = request.results as? [VNRecognizedTextObservation] ?? []
    print("✅ Chinese found \(results.count) observations")

    for (i, result) in results.enumerated() {
        if let candidate = result.topCandidates(1).first {
            print("  \(i+1): '\(candidate.string)' confidence: \(candidate.confidence)")
        }
    }
}

request3.recognitionLanguages = ["zh-Hans"]
request3.recognitionLevel = .accurate
let handler3 = VNImageRequestHandler(cgImage: testImage)

do {
    try handler3.perform([request3])
    semaphore.wait()
} catch {
    print("❌ Chinese perform error: \(error)")
}

print("\n✅ OCR Test Complete!")