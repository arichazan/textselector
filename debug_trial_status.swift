#!/usr/bin/env swift

import Foundation

print("🔍 Debugging GrabDab Trial Status")
print("==================================")
print()

// Check the main GrabDab domain
print("📊 GrabDab domain settings:")
if let grabDabSettings = UserDefaults.standard.persistentDomain(forName: "GrabDab") {
    for (key, value) in grabDabSettings {
        print("   • \(key): \(value)")
    }
} else {
    print("   ❌ No GrabDab domain found")
}
print()

// Check standard UserDefaults for trial settings
print("🔍 Standard UserDefaults trial settings:")
let standardDefaults = UserDefaults.standard
let trialKeys = ["trialStartDate", "isPremium", "hasShownTrialExpired"]

for key in trialKeys {
    if let value = standardDefaults.object(forKey: key) {
        print("   • \(key): \(value)")
    } else {
        print("   • \(key): ❌ Not set")
    }
}
print()

// Calculate trial status
print("📅 Trial Status Calculation:")
if let trialStartDate = standardDefaults.object(forKey: "trialStartDate") as? Date {
    let daysSinceStart = Date().timeIntervalSince(trialStartDate) / (24 * 60 * 60)
    let isPremium = standardDefaults.bool(forKey: "isPremium")
    let hasShownExpired = standardDefaults.bool(forKey: "hasShownTrialExpired")

    print("   • Trial started: \(trialStartDate)")
    print("   • Days since start: \(String(format: "%.1f", daysSinceStart))")
    print("   • Is premium: \(isPremium)")
    print("   • Has shown expired: \(hasShownExpired)")

    if isPremium {
        print("   🎯 Status: PREMIUM")
    } else if daysSinceStart <= 7 {
        print("   🎯 Status: TRIAL (\(String(format: "%.1f", 7 - daysSinceStart)) days left)")
    } else {
        print("   🎯 Status: FREE (Trial expired)")
        if !hasShownExpired {
            print("   ⚠️  Should show upgrade sheet on next capture!")
        } else {
            print("   ✅ Upgrade sheet already shown")
        }
    }
} else {
    print("   ❌ No trial start date found")
    print("   🎯 Status: FRESH INSTALL (Trial not started)")
}
print()

print("💡 To fix: Use 'defaults write GrabDab' for commands when running via 'swift run'")