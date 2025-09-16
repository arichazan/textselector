import CoreGraphics
import Vision

final class VisionOCRService {
    private let queue = DispatchQueue(label: "com.snaptext.ocr.vision", qos: .userInitiated)

    func recognize(image: CGImage, language: OCRLanguage, completion: @escaping (Result<OCRResult, Error>) -> Void) {
        queue.async { [weak self] in
            self?.detectBarcode(image: image) { barcodeResult in
                switch barcodeResult {
                case let .success(result):
                    DispatchQueue.main.async {
                        completion(.success(result))
                    }
                case .failure:
                    self?.recognizeText(image: image, language: language, completion: completion)
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
                    let detectionType: DetectionType = barcode.symbology == .QR ? .qrCode : .barcode
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

    private func recognizeText(image: CGImage, language: OCRLanguage, completion: @escaping (Result<OCRResult, Error>) -> Void) {
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
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
                completion(.success(OCRResult(text: output, engine: .vision, detectionType: .text)))
            }
        }

        request.recognitionLanguages = [language.visionRecognitionLanguage]
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

enum OCRProcessingError: Error {
    case noTextFound
    case noBarcodeFound
}
