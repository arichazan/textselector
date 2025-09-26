#!/usr/bin/env swift

import Foundation

print("🧪 GrabDab Freemium Feature Test")
print("================================")
print()

let defaults = UserDefaults.standard

// Test 1: Fresh Install (No trial started)
print("1️⃣ Fresh Install Simulation:")
defaults.removeObject(forKey: "trialStartDate")
defaults.removeObject(forKey: "hasShownTrialExpired")
defaults.removeObject(forKey: "isPremium")
print("   ✅ Trial not started - User gets full trial features")
print("   📝 Status: TRIAL (7 days available)")
print()

// Test 2: Active Trial (Started 3 days ago)
print("2️⃣ Active Trial Simulation:")
let threeDaysAgo = Date().addingTimeInterval(-3 * 24 * 60 * 60)
defaults.set(threeDaysAgo, forKey: "trialStartDate")
defaults.set(false, forKey: "hasShownTrialExpired")
defaults.set(false, forKey: "isPremium")
print("   ✅ Trial active - 4 days remaining")
print("   📝 Status: TRIAL (4 days left)")
print()

// Test 3: Trial Expired (Started 8 days ago)
print("3️⃣ Trial Expired Simulation:")
let eightDaysAgo = Date().addingTimeInterval(-8 * 24 * 60 * 60)
defaults.set(eightDaysAgo, forKey: "trialStartDate")
defaults.set(false, forKey: "hasShownTrialExpired")
defaults.set(false, forKey: "isPremium")
print("   ✅ Trial expired - Upgrade sheet should appear on capture")
print("   📝 Status: FREE (Trial expired)")
print()

// Test 4: Premium User
print("4️⃣ Premium User Simulation:")
defaults.set(eightDaysAgo, forKey: "trialStartDate")
defaults.set(true, forKey: "isPremium")
print("   ✅ Premium user - All features unlocked")
print("   📝 Status: PREMIUM")
print()

print("🎯 Testing Scenarios:")
print("   • QR Code Scan: Shows upgrade sheet for free users")
print("   • Long Text (>144 chars): Shows upgrade sheet when truncated")
print("   • Trial Expired: Shows upgrade sheet on first capture after expiry")
print()
print("💡 To test: Run GrabDab after each simulation and try capturing text/QR codes")
print("🔄 Reset: defaults delete com.example.grabdab")