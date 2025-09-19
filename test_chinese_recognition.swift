import CoreGraphics
import Vision
import AppKit

enum OCRLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case chineseSimplified = "zh-Hans"
    case chineseTraditional = "zh-Hant"
    case japanese = "ja"
    case korean = "ko"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case italian = "it"
    case portuguese = "pt"
    case russian = "ru"
    case arabic = "ar"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .chineseSimplified:
            return "Chinese (Simplified)"
        case .chineseTraditional:
            return "Chinese (Traditional)"
        case .japanese:
            return "Japanese"
        case .korean:
            return "Korean"
        case .spanish:
            return "Spanish"
        case .french:
            return "French"
        case .german:
            return "German"
        case .italian:
            return "Italian"
        case .portuguese:
            return "Portuguese"
        case .russian:
            return "Russian"
        case .arabic:
            return "Arabic"
        }
    }

    var visionRecognitionLanguage: String {
        switch self {
        case .english:
            return "en-US"
        case .chineseSimplified:
            return "zh-Hans"
        case .chineseTraditional:
            return "zh-Hant"
        case .japanese:
            return "ja-JP"
        case .korean:
            return "ko-KR"
        case .spanish:
            return "es-ES"
        case .french:
            return "fr-FR"
        case .german:
            return "de-DE"
        case .italian:
            return "it-IT"
        case .portuguese:
            return "pt-BR"
        case .russian:
            return "ru-RU"
        case .arabic:
            return "ar-SA"
        }
    }
}

func testChineseOCR() {
    let imagePath = "/Users/ari/Dropbox/Devel/textselector/chinese_test_image.png"

    guard let image = NSImage(contentsOfFile: imagePath),
          let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        print("❌ Failed to load image from: \(imagePath)")
        return
    }

    print("✅ Image loaded successfully")
    print("📐 Image size: \(cgImage.width) x \(cgImage.height)")

    let request = VNRecognizeTextRequest { request, error in
        if let error = error {
            print("❌ OCR Error: \(error)")
            return
        }

        guard let results = request.results as? [VNRecognizedTextObservation] else {
            print("❌ No text observations found")
            return
        }

        print("📝 Found \(results.count) text observations")

        let textLines: [String] = results.compactMap { observation in
            let candidate = observation.topCandidates(1).first
            print("🔍 Text candidate: '\(candidate?.string ?? "nil")' confidence: \(candidate?.confidence ?? 0)")
            return candidate?.string
        }

        let output = textLines.joined(separator: "\n")
        print("\n🎯 Final OCR Output:")
        print("==================")
        print(output)
        print("==================")

        // Expected: 金秋里 听历史的声息拂过耳畔
        let expectedText = "金秋里 听历史的声息拂过耳畔"
        let containsExpected = output.contains("金秋里") && output.contains("听历史的声息拂过耳畔")

        if containsExpected {
            print("✅ SUCCESS: Chinese characters recognized correctly!")
        } else {
            print("⚠️  WARNING: Expected text not found exactly")
            print("Expected: \(expectedText)")
            print("Got: \(output)")
        }
    }

    let language = OCRLanguage.chineseSimplified
    print("🌐 Using language: \(language.displayName) (\(language.visionRecognitionLanguage))")

    request.recognitionLanguages = [language.visionRecognitionLanguage]
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = false

    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    do {
        try handler.perform([request])
    } catch {
        print("❌ Handler error: \(error)")
    }
}

print("🚀 Starting Chinese OCR test...")
testChineseOCR()

RunLoop.main.run(until: Date(timeIntervalSinceNow: 5))