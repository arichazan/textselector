import SwiftUI

struct CaptureResultView: View {
    let result: OCRResult
    let onOK: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(.blue)
                    .font(.title2)

                Text(titleText)
                    .font(.headline)
                    .fontWeight(.medium)

                Spacer()
            }

            ScrollView {
                Text(result.text)
                    .textSelection(.enabled)
                    .padding()
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 200)

            HStack {
                Spacer()

                Button("OK") {
                    onOK()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 400)
        .frame(minHeight: 150)
    }

    private var iconName: String {
        switch result.detectionType {
        case .qrCode:
            return "qrcode"
        case .barcode:
            return "barcode"
        case .text:
            return "text.alignleft"
        }
    }

    private var titleText: String {
        switch result.detectionType {
        case .qrCode:
            return localizedString("result.qrCode", comment: "QR Code result title")
        case .barcode:
            return localizedString("result.barcode", comment: "Barcode result title")
        case .text:
            return localizedString("result.text", comment: "Text result title")
        }
    }
}

struct CaptureResultView_Previews: PreviewProvider {
    static var previews: some View {
        CaptureResultView(
            result: OCRResult(
                text: "Sample captured text that might be quite long and need scrolling to see all of it properly.",
                engine: .vision,
                detectionType: .text
            ),
            onOK: {}
        )
        .previewDisplayName("Text Result")

        CaptureResultView(
            result: OCRResult(
                text: "https://example.com/qr-code-content",
                engine: .vision,
                detectionType: .qrCode
            ),
            onOK: {}
        )
        .previewDisplayName("QR Code Result")
    }
}