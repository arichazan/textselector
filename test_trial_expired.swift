#!/usr/bin/env swift

import Foundation

// This script simulates trial expiration by modifying UserDefaults

let defaults = UserDefaults(suiteName: "com.example.grabdab")!

// Set trial start date to 8 days ago (1 day past 7-day trial)
let eightDaysAgo = Date().addingTimeInterval(-8 * 24 * 60 * 60)
defaults.set(eightDaysAgo, forKey: "trialStartDate")

// Reset the "has shown expired" flag so it will show again
defaults.set(false, forKey: "hasShownTrialExpired")

print("✅ Trial expired simulation set up!")
print("   Trial start date: \(eightDaysAgo)")
print("   Current date: \(Date())")
print("   Trial should be expired by: \(Date().timeIntervalSince(eightDaysAgo) / (24 * 60 * 60)) days")
print("")
print("Now run GrabDab and try capturing text - you should see the upgrade sheet!")
print("To reset to fresh trial, delete the app's preferences or run: defaults delete com.example.grabdab")