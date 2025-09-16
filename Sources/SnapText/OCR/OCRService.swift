import CoreGraphics

struct OCRResult {
    let text: String
    let engine: OCREngine
    let detectionType: DetectionType
}

enum OCREngine {
    case vision
    case tesseract
}

enum DetectionType {
    case text
    case qrCode
    case barcode
}

protocol OCRServicing {
    func recognizeText(in image: CGImage, language: OCRLanguage, completion: @escaping (Result<OCRResult, Error>) -> Void)
}

final class OCRService: OCRServicing {
    private let visionService: VisionOCRService
    private let tesseractService: TesseractOCRService

    init(visionService: VisionOCRService = VisionOCRService(), tesseractService: TesseractOCRService = TesseractOCRService()) {
        self.visionService = visionService
        self.tesseractService = tesseractService
    }

    func recognizeText(in image: CGImage, language: OCRLanguage, completion: @escaping (Result<OCRResult, Error>) -> Void) {
        visionService.recognize(image: image, language: language) { [weak self] result in
            switch result {
            case let .success(result):
                completion(.success(result))
            case let .failure(error):
                self?.attemptFallback(image: image, language: language, primaryError: error, completion: completion)
            }
        }
    }

    private func attemptFallback(
        image: CGImage,
        language: OCRLanguage,
        primaryError: Error,
        completion: @escaping (Result<OCRResult, Error>) -> Void
    ) {
        tesseractService.recognize(image: image, language: language) { fallbackResult in
            switch fallbackResult {
            case let .success(text):
                completion(.success(OCRResult(text: text, engine: .tesseract, detectionType: .text)))
            case let .failure(fallbackError):
                completion(.failure(OCRFailure.primaryAndFallbackFailed(primary: primaryError, fallback: fallbackError)))
            }
        }
    }
}

enum OCRFailure: Error {
    case primaryAndFallbackFailed(primary: Error, fallback: Error)
}
