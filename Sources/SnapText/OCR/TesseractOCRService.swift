import CoreGraphics

#if canImport(TesseractOCR)
import TesseractOCR
#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage
#endif

final class TesseractOCRService {
    func recognize(image: CGImage, language: OCRLanguage, completion: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let tesseract = G8Tesseract(language: language.rawValue) else {
                DispatchQueue.main.async {
                    completion(.failure(TesseractError.initializationFailed))
                }
                return
            }

            tesseract.engineMode = .tesseractOnly
            tesseract.pageSegmentationMode = .auto
            tesseract.maximumRecognitionTime = 2.0
#if canImport(UIKit)
            let platformImage = PlatformImage(cgImage: image)
            tesseract.image = platformImage
#elseif canImport(AppKit)
            let size = NSSize(width: CGFloat(image.width), height: CGFloat(image.height))
            let platformImage = PlatformImage(cgImage: image, size: size)
            tesseract.image = platformImage
#endif
            tesseract.recognize()

            let text = tesseract.recognizedText ?? ""
            DispatchQueue.main.async {
                if text.isEmpty {
                    completion(.failure(TesseractError.noTextFound))
                } else {
                    completion(.success(text))
                }
            }
        }
    }
}

enum TesseractError: Error {
    case initializationFailed
    case noTextFound
}

#else

final class TesseractOCRService {
    func recognize(image: CGImage, language: OCRLanguage, completion: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.main.async {
            completion(.failure(TesseractUnavailableError.missingDependency))
        }
    }
}

enum TesseractUnavailableError: Error {
    case missingDependency
}

#endif
