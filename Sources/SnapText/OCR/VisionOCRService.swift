import CoreGraphics
import Vision
import Foundation

final class VisionOCRService {
    private let queue = DispatchQueue(label: "com.snaptext.ocr.vision", qos: .userInitiated)

    // Recognition thresholds (dynamically read from settings)
    private var minAcceptConfidence: Float {
        return UserSettings.shared.minAcceptConfidence
    }

    private var reconsiderConfidence: Float {
        return UserSettings.shared.reconsiderConfidence
    }

    // Language sets for dual recognition
    private let latinLanguages = ["en-US", "es-ES", "fr-FR", "de-DE", "it-IT", "pt-BR", "nl-NL"]
    private let cjkLanguages = ["zh-Hans", "zh-Hant", "ja-JP", "ko-KR"]

    func recognize(image: CGImage, language: OCRLanguage, completion: @escaping (Result<OCRResult, Error>) -> Void) {
        queue.async { [weak self] in
            self?.detectBarcode(image: image) { barcodeResult in
                switch barcodeResult {
                case let .success(result):
                    DispatchQueue.main.async {
                        completion(.success(result))
                    }
                case .failure:
                    self?.recognizeTextWithDualLanguage(image: image, language: language, completion: completion)
                }
            }
        }
    }

    private func detectBarcode(image: CGImage, completion: @escaping (Result<OCRResult, Error>) -> Void) {
        let request = VNDetectBarcodesRequest { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let results = request.results as? [VNBarcodeObservation] else {
                completion(.failure(OCRProcessingError.noBarcodeFound))
                return
            }

            for barcode in results {
                if let payloadString = barcode.payloadStringValue {
                    let detectionType: DetectionType = barcode.symbology == .qr ? .qrCode : .barcode
                    let result = OCRResult(text: payloadString, engine: .vision, detectionType: detectionType)
                    completion(.success(result))
                    return
                }
            }

            completion(.failure(OCRProcessingError.noBarcodeFound))
        }

        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try handler.perform([request])
        } catch {
            completion(.failure(error))
        }
    }

    private func recognizeTextWithDualLanguage(image: CGImage, language: OCRLanguage, completion: @escaping (Result<OCRResult, Error>) -> Void) {
        // Check if user explicitly selected a Latin-only mode
        let isLatinOnlyMode = UserSettings.shared.latinOnlyMode

        // First detect text regions (lines)
        detectTextRegions(image: image) { [weak self] regions in
            guard let self = self, !regions.isEmpty else {
                DispatchQueue.main.async {
                    completion(.failure(OCRProcessingError.noTextFound))
                }
                return
            }

            let message = String(format: localizedString("debug.regionDetection", comment: "Debug message for region detection"), regions.count)
            print("VisionOCR: \(message)")

            // Process each line with dual language recognition
            self.processTextRegions(image: image, regions: regions, isLatinOnlyMode: isLatinOnlyMode, language: language, completion: completion)
        }
    }

    private func detectTextRegions(image: CGImage, completion: @escaping ([VNTextObservation]) -> Void) {
        let request = VNDetectTextRectanglesRequest { request, error in
            if let error = error {
                print("VisionOCR: Text region detection error: \(error)")
                completion([])
                return
            }

            guard let results = request.results as? [VNTextObservation] else {
                print("VisionOCR: No text regions found")
                completion([])
                return
            }

            completion(results)
        }

        request.reportCharacterBoxes = false

        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("VisionOCR: Region detection handler error: \(error)")
            completion([])
        }
    }

    private func processTextRegions(image: CGImage, regions: [VNTextObservation], isLatinOnlyMode: Bool, language: OCRLanguage, completion: @escaping (Result<OCRResult, Error>) -> Void) {
        let group = DispatchGroup()
        var lineResults: [(index: Int, text: String)] = []
        let resultsQueue = DispatchQueue(label: "com.snaptext.ocr.results")

        for (index, region) in regions.enumerated() {
            group.enter()

            processLineRegion(image: image, region: region, lineIndex: index, isLatinOnlyMode: isLatinOnlyMode, language: language) { result in
                resultsQueue.async {
                    lineResults.append((index: index, text: result))
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            let sortedResults = lineResults.sorted { $0.index < $1.index }
            let finalText = sortedResults.map { $0.text }.joined(separator: "\n")

            let message = String(format: localizedString("debug.finalOutput", comment: "Debug message for final output"), finalText)
            print("VisionOCR: \(message)")
            completion(.success(OCRResult(text: finalText, engine: .vision, detectionType: .text)))
        }
    }

    private func processLineRegion(image: CGImage, region: VNTextObservation, lineIndex: Int, isLatinOnlyMode: Bool, language: OCRLanguage, completion: @escaping (String) -> Void) {
        // Extract line region from full image
        guard let lineImage = cropImageToRegion(image: image, region: region) else {
            print("VisionOCR: Failed to crop line \(lineIndex)")
            completion("")
            return
        }

        if isLatinOnlyMode {
            // Latin-only mode: use single language
            performSingleLanguageRecognition(image: lineImage, languages: latinLanguages, lineIndex: lineIndex, completion: completion)
        } else {
            // Dual language mode: try both Latin and CJK
            performDualLanguageRecognition(image: lineImage, lineIndex: lineIndex, completion: completion)
        }
    }

    private func performDualLanguageRecognition(image: CGImage, lineIndex: Int, completion: @escaping (String) -> Void) {
        let group = DispatchGroup()
        var latinResult: (text: String, confidence: Float)?
        var cjkResult: (text: String, confidence: Float)?

        group.enter()
        recognizeWithLanguages(image: image, languages: latinLanguages, usesCorrection: false) { result in
            latinResult = result
            group.leave()
        }

        group.enter()
        recognizeWithLanguages(image: image, languages: cjkLanguages, usesCorrection: false) { result in
            cjkResult = result
            group.leave()
        }

        group.notify(queue: queue) { [weak self] in
            self?.selectBestResult(latinResult: latinResult, cjkResult: cjkResult, lineIndex: lineIndex, originalImage: image, completion: completion)
        }
    }

    private func performSingleLanguageRecognition(image: CGImage, languages: [String], lineIndex: Int, completion: @escaping (String) -> Void) {
        recognizeWithLanguages(image: image, languages: languages, usesCorrection: true) { result in
            let text = result?.text ?? ""
            print("VisionOCR: Line \(lineIndex) single-lang result: '\(text)' confidence: \(result?.confidence ?? 0)")
            completion(text)
        }
    }

    private func selectBestResult(latinResult: (text: String, confidence: Float)?, cjkResult: (text: String, confidence: Float)?, lineIndex: Int, originalImage: CGImage, completion: @escaping (String) -> Void) {
        let latinConf = latinResult?.confidence ?? 0.0
        let cjkConf = cjkResult?.confidence ?? 0.0
        let latinText = latinResult?.text ?? ""
        let cjkText = cjkResult?.text ?? ""

        var chosenSet: String
        var finalText: String
        var finalConfidence: Float

        // Initial selection based on confidence
        if latinConf > cjkConf {
            chosenSet = "latin"
            finalText = latinText
            finalConfidence = latinConf
        } else {
            chosenSet = "cjk"
            finalText = cjkText
            finalConfidence = cjkConf
        }

        // Apply heuristics
        let asciiRatio = calculateAsciiRatio(text: finalText)
        let isUrlLike = isUrlOrCodeLike(text: finalText)

        // ASCII ratio gate for Latin results
        if chosenSet == "latin" && asciiRatio < 0.5 && !isUrlLike {
            if cjkConf + 0.05 > latinConf {
                chosenSet = "cjk"
                finalText = cjkText
                finalConfidence = cjkConf
            }
        }

        // URL/digit bias toward Latin
        if isUrlLike && chosenSet == "cjk" && latinConf + 0.05 >= cjkConf {
            chosenSet = "latin"
            finalText = latinText
            finalConfidence = latinConf
        }

        let isLowConfidence = finalConfidence < reconsiderConfidence

        // If confidence is too low, try rotation
        if isLowConfidence {
            tryRotationRecognition(image: originalImage, lineIndex: lineIndex) { [weak self] rotationResult in
                if let rotResult = rotationResult, rotResult.confidence > finalConfidence {
                    self?.logRecognitionDecision(lineIndex: lineIndex, latinConf: latinConf, cjkConf: cjkConf, chosenSet: "rotation", asciiRatio: asciiRatio, urlLike: isUrlLike, rotated: true, finalConfidence: rotResult.confidence, lowConfidence: rotResult.confidence < self?.minAcceptConfidence ?? 0.70, refineApplied: false)
                    completion(rotResult.text)
                } else {
                    self?.logRecognitionDecision(lineIndex: lineIndex, latinConf: latinConf, cjkConf: cjkConf, chosenSet: chosenSet, asciiRatio: asciiRatio, urlLike: isUrlLike, rotated: false, finalConfidence: finalConfidence, lowConfidence: finalConfidence < self?.minAcceptConfidence ?? 0.70, refineApplied: false)
                    completion(finalText)
                }
            }
            return
        }

        logRecognitionDecision(lineIndex: lineIndex, latinConf: latinConf, cjkConf: cjkConf, chosenSet: chosenSet, asciiRatio: asciiRatio, urlLike: isUrlLike, rotated: false, finalConfidence: finalConfidence, lowConfidence: finalConfidence < minAcceptConfidence, refineApplied: false)
        completion(finalText)
    }

    private func recognizeWithLanguages(image: CGImage, languages: [String], usesCorrection: Bool, completion: @escaping ((text: String, confidence: Float)?) -> Void) {
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("VisionOCR: Recognition error: \(error)")
                completion(nil)
                return
            }

            guard let results = request.results as? [VNRecognizedTextObservation],
                  let topObservation = results.first,
                  let candidate = topObservation.topCandidates(1).first else {
                completion(nil)
                return
            }

            completion((text: candidate.string, confidence: candidate.confidence))
        }

        request.recognitionLanguages = languages
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = usesCorrection

        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("VisionOCR: Handler error: \(error)")
            completion(nil)
        }
    }

    private func tryRotationRecognition(image: CGImage, lineIndex: Int, completion: @escaping ((text: String, confidence: Float)?) -> Void) {
        let group = DispatchGroup()
        var bestResult: (text: String, confidence: Float)?

        // Try ±90 degree rotations
        for angle in [90.0, -90.0] {
            group.enter()

            if let rotatedImage = rotateImage(image: image, degrees: angle) {
                performDualLanguageRecognitionSync(image: rotatedImage, lineIndex: lineIndex) { result in
                    if let result = result {
                        if bestResult == nil || result.confidence > bestResult!.confidence {
                            bestResult = result
                        }
                    }
                    group.leave()
                }
            } else {
                group.leave()
            }
        }

        group.notify(queue: queue) {
            completion(bestResult)
        }
    }

    private func performDualLanguageRecognitionSync(image: CGImage, lineIndex: Int, completion: @escaping ((text: String, confidence: Float)?) -> Void) {
        let group = DispatchGroup()
        var latinResult: (text: String, confidence: Float)?
        var cjkResult: (text: String, confidence: Float)?

        group.enter()
        recognizeWithLanguages(image: image, languages: latinLanguages, usesCorrection: false) { result in
            latinResult = result
            group.leave()
        }

        group.enter()
        recognizeWithLanguages(image: image, languages: cjkLanguages, usesCorrection: false) { result in
            cjkResult = result
            group.leave()
        }

        group.notify(queue: queue) {
            let latinConf = latinResult?.confidence ?? 0.0
            let cjkConf = cjkResult?.confidence ?? 0.0

            if latinConf > cjkConf {
                completion(latinResult)
            } else {
                completion(cjkResult)
            }
        }
    }

    private func cropImageToRegion(image: CGImage, region: VNTextObservation) -> CGImage? {
        let imageWidth = CGFloat(image.width)
        let imageHeight = CGFloat(image.height)

        // Convert normalized coordinates to image coordinates
        let x = region.boundingBox.origin.x * imageWidth
        let y = (1.0 - region.boundingBox.origin.y - region.boundingBox.height) * imageHeight
        let width = region.boundingBox.width * imageWidth
        let height = region.boundingBox.height * imageHeight

        let cropRect = CGRect(x: x, y: y, width: width, height: height)

        return image.cropping(to: cropRect)
    }

    private func rotateImage(image: CGImage, degrees: Double) -> CGImage? {
        let radians = degrees * Double.pi / 180.0
        let rotatedSize = CGSize(
            width: abs(cos(radians)) * Double(image.width) + abs(sin(radians)) * Double(image.height),
            height: abs(sin(radians)) * Double(image.width) + abs(cos(radians)) * Double(image.height)
        )

        guard let colorSpace = image.colorSpace,
              let context = CGContext(data: nil,
                                    width: Int(rotatedSize.width),
                                    height: Int(rotatedSize.height),
                                    bitsPerComponent: image.bitsPerComponent,
                                    bytesPerRow: 0,
                                    space: colorSpace,
                                    bitmapInfo: image.bitmapInfo.rawValue) else {
            return nil
        }

        context.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        context.rotate(by: CGFloat(radians))
        context.translateBy(x: -CGFloat(image.width) / 2, y: -CGFloat(image.height) / 2)
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))

        return context.makeImage()
    }

    private func calculateAsciiRatio(text: String) -> Float {
        guard !text.isEmpty else { return 1.0 }

        let asciiCount = text.unicodeScalars.count { $0.isASCII }
        return Float(asciiCount) / Float(text.unicodeScalars.count)
    }

    private func isUrlOrCodeLike(text: String) -> Bool {
        let lowercased = text.lowercased()

        // URL patterns
        if lowercased.contains("http") || lowercased.contains("www.") || lowercased.contains(".com") || lowercased.contains(".org") || lowercased.contains("@") {
            return true
        }

        // Code-like patterns
        if text.contains("()") || text.contains("{}") || text.contains("[]") || text.contains("=") || text.contains(";") {
            return true
        }

        // Mostly digits
        let digitCount = text.unicodeScalars.count { CharacterSet.decimalDigits.contains($0) }
        let totalCount = text.unicodeScalars.count

        return totalCount > 0 && Float(digitCount) / Float(totalCount) > 0.7
    }

    private func logRecognitionDecision(lineIndex: Int, latinConf: Float, cjkConf: Float, chosenSet: String, asciiRatio: Float, urlLike: Bool, rotated: Bool, finalConfidence: Float, lowConfidence: Bool, refineApplied: Bool) {
        print("VisionOCR: Line \(lineIndex) - Latin: \(String(format: "%.3f", latinConf)), CJK: \(String(format: "%.3f", cjkConf)), Chosen: \(chosenSet), ASCII: \(String(format: "%.2f", asciiRatio)), URL: \(urlLike), Rotated: \(rotated), Final: \(String(format: "%.3f", finalConfidence)), LowConf: \(lowConfidence), Refined: \(refineApplied)")
    }
}

enum OCRProcessingError: Error {
    case noTextFound
    case noBarcodeFound
}
