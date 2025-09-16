import AppKit
import CoreGraphics

final class CaptureController {
    private let settings: UserSettings
    private let overlayController = SelectionOverlayWindowController()
    private let ocrService: OCRServicing
    private let processingQueue = DispatchQueue(label: "com.snaptext.capture", qos: .userInitiated)

    init(settings: UserSettings, ocrService: OCRServicing = OCRService()) {
        self.settings = settings
        self.ocrService = ocrService
    }

    func beginCapture(completion: @escaping (Result<OCRResult, CaptureError>) -> Void) {
        overlayController.beginSelection { [weak self] outcome in
            guard let self else { return }
            switch outcome {
            case .cancelled:
                completion(.failure(.cancelled))
            case let .selected(rect, screen):
                self.capture(rect: rect, screen: screen) { imageResult in
                    switch imageResult {
                    case let .success(image):
                        self.recognize(image: image, completion: completion)
                    case .failure:
                        completion(.failure(.screenshotFailed))
                    }
                }
            }
        }
    }

    private func capture(rect: CGRect, screen: NSScreen, completion: @escaping (Result<CGImage, Error>) -> Void) {
        processingQueue.async {
            guard let displayID = screen.displayID,
                  let fullImage = CGDisplayCreateImage(displayID) else {
                DispatchQueue.main.async {
                    completion(.failure(CaptureError.screenshotFailed))
                }
                return
            }

            let captureRect = self.convertToCaptureRect(rect: rect, screen: screen)
            let bounds = CGRect(x: 0, y: 0, width: CGFloat(fullImage.width), height: CGFloat(fullImage.height))
            let clampedRect = captureRect.intersection(bounds)
            guard !clampedRect.isNull,
                  let cropped = fullImage.cropping(to: clampedRect) else {
                DispatchQueue.main.async {
                    completion(.failure(CaptureError.screenshotFailed))
                }
                return
            }

            let optimizedImage = self.downscaleIfNeeded(image: cropped)
            DispatchQueue.main.async {
                completion(.success(optimizedImage))
            }
        }
    }

    private func recognize(image: CGImage, completion: @escaping (Result<OCRResult, CaptureError>) -> Void) {
        ocrService.recognizeText(in: image, language: settings.ocrLanguage) { result in
            switch result {
            case let .success(ocrResult):
                completion(.success(ocrResult))
            case let .failure(error):
                completion(.failure(.ocrFailed(error)))
            }
        }
    }

    private func downscaleIfNeeded(image: CGImage) -> CGImage {
        let maxDimension: CGFloat = 2000
        let width = CGFloat(image.width)
        let height = CGFloat(image.height)
        let largestDimension = max(width, height)
        guard largestDimension > maxDimension else { return image }

        let scale = maxDimension / largestDimension
        let newSize = CGSize(width: width * scale, height: height * scale)

        guard let colorSpace = image.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: nil,
                width: Int(newSize.width),
                height: Int(newSize.height),
                bitsPerComponent: image.bitsPerComponent,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            return image
        }

        context.interpolationQuality = .high
        context.draw(image, in: CGRect(origin: .zero, size: newSize))
        return context.makeImage() ?? image
    }

    private func convertToCaptureRect(rect: CGRect, screen: NSScreen) -> CGRect {
        let scale = screen.backingScaleFactor
        let relativeX = rect.origin.x - screen.frame.origin.x
        let relativeY = rect.origin.y - screen.frame.origin.y
        let flippedY = screen.frame.height - relativeY - rect.height

        return CGRect(
            x: relativeX * scale,
            y: flippedY * scale,
            width: rect.width * scale,
            height: rect.height * scale
        ).integral
    }
}

enum CaptureError: Error {
    case cancelled
    case screenshotFailed
    case ocrFailed(Error)
}
