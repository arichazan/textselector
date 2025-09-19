import Foundation

/// Utility function for localized strings from the correct bundle
func localizedString(_ key: String, comment: String = "") -> String {
    return NSLocalizedString(key, bundle: .module, comment: comment)
}

/// Utility class for localized formatting of dates, numbers, and other locale-sensitive data
final class LocalizationUtilities {
    static let shared = LocalizationUtilities()

    private init() {}

    // MARK: - Date Formatting

    func formatDate(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }

    func formatDateTime(_ date: Date, dateStyle: DateFormatter.Style = .medium, timeStyle: DateFormatter.Style = .short) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }

    func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale.current
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    // MARK: - Number Formatting

    func formatNumber(_ number: NSNumber, style: NumberFormatter.Style = .decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = style
        formatter.locale = Locale.current
        return formatter.string(from: number) ?? number.stringValue
    }

    func formatInteger(_ integer: Int) -> String {
        return formatNumber(NSNumber(value: integer), style: .decimal)
    }

    func formatDouble(_ double: Double, fractionDigits: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: double)) ?? String(double)
    }

    func formatPercentage(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: value)) ?? "\(value * 100)%"
    }

    func formatCurrency(_ amount: Double, currencyCode: String? = nil) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current

        if let currencyCode = currencyCode {
            formatter.currencyCode = currencyCode
        }

        return formatter.string(from: NSNumber(value: amount)) ?? String(amount)
    }

    // MARK: - File Size Formatting

    func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    // MARK: - OCR Confidence Formatting

    func formatConfidence(_ confidence: Float) -> String {
        return formatPercentage(Double(confidence))
    }

    // MARK: - Processing Time Formatting

    func formatProcessingTime(_ timeInterval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.second, .nanosecond]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: timeInterval) ?? "\(timeInterval)s"
    }

    // MARK: - Plural Strings

    func formatLinesProcessed(_ count: Int) -> String {
        return String.localizedStringWithFormat(
            NSLocalizedString("ocr.linesProcessed", comment: "Lines processed plural"),
            count
        )
    }

    func formatRegionsFound(_ count: Int) -> String {
        return String.localizedStringWithFormat(
            NSLocalizedString("ocr.regionsFound", comment: "Regions found plural"),
            count
        )
    }

    func formatCharactersRecognized(_ count: Int) -> String {
        return String.localizedStringWithFormat(
            NSLocalizedString("ocr.charactersRecognized", comment: "Characters recognized plural"),
            count
        )
    }
}

// MARK: - Extension for SwiftUI compatibility

#if canImport(SwiftUI)
import SwiftUI

@available(macOS 12.0, *)
extension LocalizationUtilities {
    /// Format date using the new iOS 15+ formatting
    func formatDateModern(_ date: Date) -> String {
        return date.formatted(.dateTime.year().month().day().locale(Locale.current))
    }

    /// Format number using the new iOS 15+ formatting
    func formatNumberModern(_ number: Double) -> String {
        return number.formatted(.number.locale(Locale.current))
    }
}
#endif