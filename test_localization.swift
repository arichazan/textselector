#!/usr/bin/env swift

import Foundation

print("SnapText Localization Test")
print("==========================")
print("")

// Test localized strings availability
let testKeys = [
    "menu.captureText",
    "menu.preferences",
    "menu.quit",
    "preferences.title",
    "toast.copied",
    "error.noText",
    "language.english",
    "language.chineseSimplified"
]

print("Testing localized string keys:")
for key in testKeys {
    let localized = NSLocalizedString(key, comment: "Test")
    let isLocalized = localized != key
    let status = isLocalized ? "✅" : "❌"
    print("  \(status) \(key): \"\(localized)\"")
}

print("")
print("Testing number and date formatting:")

// Create formatters with different locales
let testLocales = [
    Locale(identifier: "en_US"),
    Locale(identifier: "es_ES"),
    Locale(identifier: "fr_FR"),
    Locale(identifier: "de_DE"),
    Locale(identifier: "it_IT"),
    Locale(identifier: "zh_Hans_CN"),
    Locale(identifier: "zh_Hant_TW")
]

let testNumber = 1234567.89
let testDate = Date()

for locale in testLocales {
    print("")
    print("Locale: \(locale.identifier)")

    // Number formatting
    let numberFormatter = NumberFormatter()
    numberFormatter.numberStyle = .decimal
    numberFormatter.locale = locale
    let formattedNumber = numberFormatter.string(from: NSNumber(value: testNumber)) ?? "N/A"
    print("  Number: \(formattedNumber)")

    // Currency formatting
    let currencyFormatter = NumberFormatter()
    currencyFormatter.numberStyle = .currency
    currencyFormatter.locale = locale
    let formattedCurrency = currencyFormatter.string(from: NSNumber(value: 99.99)) ?? "N/A"
    print("  Currency: \(formattedCurrency)")

    // Date formatting
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .short
    dateFormatter.locale = locale
    let formattedDate = dateFormatter.string(from: testDate)
    print("  Date: \(formattedDate)")

    // Percentage formatting
    let percentFormatter = NumberFormatter()
    percentFormatter.numberStyle = .percent
    percentFormatter.locale = locale
    let formattedPercent = percentFormatter.string(from: NSNumber(value: 0.75)) ?? "N/A"
    print("  Percentage: \(formattedPercent)")
}

print("")
print("Testing plural strings:")

for count in [0, 1, 2, 5] {
    let pluralString = String.localizedStringWithFormat(
        NSLocalizedString("ocr.linesProcessed", comment: "Lines processed"),
        count
    )
    print("  \(count): \(pluralString)")
}

print("")
print("✅ Localization test completed!")
print("")
print("Available localization files:")

let fm = FileManager.default
let resourcesPath = "Resources"

if fm.fileExists(atPath: resourcesPath) {
    do {
        let contents = try fm.contentsOfDirectory(atPath: resourcesPath)
        let lprojDirs = contents.filter { $0.hasSuffix(".lproj") }

        for dir in lprojDirs.sorted() {
            print("  📁 \(dir)")

            let dirPath = "\(resourcesPath)/\(dir)"
            let dirContents = try fm.contentsOfDirectory(atPath: dirPath)

            for file in dirContents.sorted() {
                print("    📄 \(file)")
            }
        }
    } catch {
        print("❌ Could not read Resources directory: \(error)")
    }
} else {
    print("❌ Resources directory not found")
}

print("")
print("To test different languages:")
print("1. Set LANG environment variable: LANG=es_ES.UTF-8 swift run")
print("2. Or use Xcode scheme language settings")
print("3. Or change macOS system language in System Settings")
print("")