import Foundation
import StoreKit

// MARK: - Purchase Status

enum PurchaseStatus {
    case trial(daysRemaining: Int)
    case freeLimited
    case unlocked
}

enum FeatureAccess {
    case allowed
    case trialRequired
    case purchaseRequired
}

// MARK: - Purchase Manager

@MainActor
final class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()

    // MARK: - Published Properties
    @Published var purchaseStatus: PurchaseStatus = .freeLimited
    @Published var isLoading = false
    @Published var purchaseError: Error?

    // MARK: - Constants
    private let productID = "com.snaptext.unlock_full"
    private let trialDurationDays = 7

    // MARK: - Private Properties
    private let trialTracker = TrialTracker()
    private var products: [Product] = []
    private var updateListenerTask: Task<Void, Error>?

    // MARK: - Initialization

    private init() {
        updateListenerTask = listenForTransactions()
        Task {
            await refreshPurchaseStatus()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Public Interface

    var isFullVersionUnlocked: Bool {
        switch purchaseStatus {
        case .trial, .unlocked:
            return true
        case .freeLimited:
            return false
        }
    }

    var isTrialActive: Bool {
        if case .trial = purchaseStatus {
            return true
        }
        return false
    }

    var trialDaysRemaining: Int {
        if case .trial(let days) = purchaseStatus {
            return days
        }
        return 0
    }

    func checkFeatureAccess(for feature: CaptureFeature) -> FeatureAccess {
        switch feature {
        case .singleLineText:
            return .allowed // Always free
        case .multiLineText:
            return isFullVersionUnlocked ? .allowed : .purchaseRequired
        case .qrCode, .barcode:
            return isFullVersionUnlocked ? .allowed : .purchaseRequired
        }
    }

    // MARK: - Trial Management

    func startTrialIfNeeded() {
        guard !trialTracker.hasTrialStarted else {
            print("Trial already started, not starting again")
            return
        }

        print("Starting trial...")
        trialTracker.startTrial()
        Task {
            await refreshPurchaseStatus()
        }

        print("Trial started: 7 days of full access")
    }

    // MARK: - Purchase Flow

    func loadProducts() async {
        do {
            isLoading = true
            products = try await Product.products(for: [productID])
            isLoading = false
        } catch {
            isLoading = false
            purchaseError = error
            print("Failed to load products: \(error)")
        }
    }

    func purchase() async -> Bool {
        // Get product, loading if necessary
        let productToPurchase: Product
        if let product = products.first {
            productToPurchase = product
        } else {
            await loadProducts()
            guard let product = products.first else {
                purchaseError = PurchaseError.productNotFound
                return false
            }
            productToPurchase = product
        }

        do {
            isLoading = true
            let result = try await productToPurchase.purchase()
            isLoading = false

            switch result {
            case .success(let verificationResult):
                if case .verified(let transaction) = verificationResult {
                    await transaction.finish()
                    await refreshPurchaseStatus()
                    return true
                } else {
                    purchaseError = PurchaseError.verificationFailed
                    return false
                }
            case .userCancelled:
                return false
            case .pending:
                // Handle pending purchases (family sharing, etc.)
                return false
            @unknown default:
                purchaseError = PurchaseError.unknownResult
                return false
            }
        } catch {
            isLoading = false
            purchaseError = error
            return false
        }
    }

    func restorePurchases() async -> Bool {
        do {
            isLoading = true
            try await AppStore.sync()
            await refreshPurchaseStatus()
            isLoading = false
            return isFullVersionUnlocked
        } catch {
            isLoading = false
            purchaseError = error
            return false
        }
    }

    // MARK: - Private Methods

    private func refreshPurchaseStatus() async {
        // Check if user has purchased
        if await checkPurchaseStatus() {
            purchaseStatus = .unlocked
            print("Purchase status: unlocked")
            return
        }

        // Check trial status
        let trialStatus = trialTracker.getTrialStatus()
        switch trialStatus {
        case .notStarted, .expired:
            purchaseStatus = .freeLimited
            print("Purchase status: freeLimited (trial \(trialStatus))")
        case .active(let daysRemaining):
            purchaseStatus = .trial(daysRemaining: daysRemaining)
            print("Purchase status: trial (\(daysRemaining) days remaining)")
        }
    }

    private func checkPurchaseStatus() async -> Bool {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == productID {
                return true
            }
        }
        return false
    }

    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self.refreshPurchaseStatus()
                }
            }
        }
    }
}

// MARK: - Purchase Errors

enum PurchaseError: LocalizedError {
    case productNotFound
    case verificationFailed
    case unknownResult

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return localizedString("purchase.error.productNotFound", comment: "Product not found error")
        case .verificationFailed:
            return localizedString("purchase.error.verificationFailed", comment: "Verification failed error")
        case .unknownResult:
            return localizedString("purchase.error.unknown", comment: "Unknown purchase error")
        }
    }
}

// MARK: - Capture Features

enum CaptureFeature {
    case singleLineText
    case multiLineText
    case qrCode
    case barcode
}