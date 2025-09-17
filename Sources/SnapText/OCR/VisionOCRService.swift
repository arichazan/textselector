import CoreGraphics
import Vision

final class VisionOCRService {
    private let queue = DispatchQueue(label: "com.snaptext.ocr.vision", qos: .userInitiated)

    func recognize(image: CGImage, language: OCRLanguage, completion: @escaping (Result<String, Error>) -> Void) {
        queue.async {
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }

                guard let results = request.results as? [VNRecognizedTextObservation] else {
                    DispatchQueue.main.async {
                        completion(.failure(OCRProcessingError.noTextFound))
                    }
                    return
                }

                let textLines: [String] = results.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }

                let output = textLines.joined(separator: "\n")
                DispatchQueue.main.async {
                    completion(.success(output))
                }
            }

            request.recognitionLanguages = [language.visionRecognitionLanguage]
            request.usesCPUOnly = false
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}

enum OCRProcessingError: Error {
    case noTextFound
}
