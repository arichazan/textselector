
import Foundation
import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()

    @Published var isLoading = false
    @Published var purchaseError: Error?

    private let productID = "com.grabdab.unlock_full"
    private var products: [Product] = []
    private var updateListenerTask: Task<Void, Error>?

    private init() {
        updateListenerTask = listenForTransactions()
        Task {
            // Ensure products are loaded on launch
            await loadProducts()
            // Sync with App Store to check for existing purchases
            _ = await restorePurchances()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    func loadProducts() async {
        guard products.isEmpty else { return }
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
        guard !isLoading else { return false }
        
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
                    // Purchase successful
                    await transaction.finish()
                    
                    // Unlock features
                    UserSettings.shared.isPremium = true
                    
                    // Notify user and system
                    ToastPresenter.shared.show(message: "Thank you for upgrading!")
                    NotificationCenter.default.post(name: .didPurchaseUpgrade, object: nil)
                    
                    return true
                } else {
                    purchaseError = PurchaseError.verificationFailed
                    return false
                }
            case .userCancelled:
                return false
            case .pending:
                // Handle pending purchases if necessary
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

    func restorePurchances() async -> Bool {
        do {
            isLoading = true
            try await AppStore.sync()

            var foundPurchase = false
            // Iterate through current entitlements to check for the premium product
            for await result in Transaction.currentEntitlements {
                if case .verified(let transaction) = result, transaction.productID == productID {
                    print("Found existing purchase, restoring access.")
                    UserSettings.shared.isPremium = true
                    foundPurchase = true
                    // Optionally, show a "Restored" message
                    // ToastPresenter.shared.show(message: "Your previous purchase has been restored.")
                    break // Exit after finding the relevant purchase
                }
            }
            isLoading = false
            return foundPurchase
        } catch {
            isLoading = false
            purchaseError = error
            print("Failed to restore purchases: \(error)")
            return false
        }
    }

    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    // A transaction update (e.g., from Family Sharing) came in.
                    // Mark as purchased and finish the transaction.
                    await transaction.finish()
                    if transaction.productID == self.productID {
                         await MainActor.run {
                            UserSettings.shared.isPremium = true
                         }
                    }
                }
            }
        }
    }
}

// MARK: - Notification Name
extension Notification.Name {
    static let didPurchaseUpgrade = Notification.Name("com.grabdab.didPurchaseUpgrade")
}


// MARK: - Purchase Errors
enum PurchaseError: LocalizedError {
    case productNotFound
    case verificationFailed
    case unknownResult

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "The product could not be found on the App Store."
        case .verificationFailed:
            return "The purchase could not be verified."
        case .unknownResult:
            return "An unknown error occurred during purchase."
        }
    }
}
