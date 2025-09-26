import SwiftUI

struct UpgradeView: View {
    @StateObject private var purchaseManager = PurchaseManager.shared
    @Environment(\.dismiss) private var dismiss

    let context: UpgradeContext

    var body: some View {
        VStack(spacing: 24) {
            headerSection

            featuresSection

            pricingSection

            buttonSection

            footerSection
        }
        .padding(32)
        .frame(width: 480, height: 600)
        .background(Color(.windowBackgroundColor))
        .task {
            await purchaseManager.loadProducts()
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.viewfinder")
                .font(.system(size: 48))
                .foregroundColor(.blue)

            Text("upgrade.title", bundle: .module)
                .font(.title)
                .fontWeight(.bold)

            Text(contextMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var contextMessage: String {
        switch context {
        case .trialExpired:
            return localizedString("upgrade.context.trialExpired", comment: "Trial expired message")
        case .multiLineBlocked:
            return localizedString("upgrade.context.multiLineBlocked", comment: "Multi-line blocked message")
        case .qrCodeBlocked:
            return localizedString("upgrade.context.qrCodeBlocked", comment: "QR code blocked message")
        case .barcodeBlocked:
            return localizedString("upgrade.context.barcodeBlocked", comment: "Barcode blocked message")
        case .general:
            return localizedString("upgrade.context.general", comment: "General upgrade message")
        }
    }

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("upgrade.features.title", bundle: .module)
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(
                    icon: "text.alignleft",
                    title: localizedString("upgrade.features.unlimitedText", comment: "Unlimited text feature"),
                    description: localizedString("upgrade.features.unlimitedText.description", comment: "Unlimited text description"),
                    isUnlocked: true
                )

                FeatureRow(
                    icon: "qrcode",
                    title: localizedString("upgrade.features.qrCodes", comment: "QR codes feature"),
                    description: localizedString("upgrade.features.qrCodes.description", comment: "QR codes description"),
                    isUnlocked: true
                )

                FeatureRow(
                    icon: "barcode",
                    title: localizedString("upgrade.features.barcodes", comment: "Barcodes feature"),
                    description: localizedString("upgrade.features.barcodes.description", comment: "Barcodes description"),
                    isUnlocked: true
                )

                FeatureRow(
                    icon: "infinity",
                    title: localizedString("upgrade.features.noLimits", comment: "No limits feature"),
                    description: localizedString("upgrade.features.noLimits.description", comment: "No limits description"),
                    isUnlocked: true
                )
            }
        }
    }

    private var pricingSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("upgrade.price.full", bundle: .module)
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("upgrade.price.subtitle", bundle: .module)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("$4.99")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(12)
        }
    }

    private var buttonSection: some View {
        VStack(spacing: 12) {
            Button(action: handlePurchase) {
                HStack {
                    if purchaseManager.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }

                    Text("upgrade.button.purchase", bundle: .module)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(purchaseManager.isLoading)

            HStack(spacing: 16) {
                Button(action: handleRestore) {
                    Text("upgrade.button.restore", bundle: .module)
                }
                .buttonStyle(.borderless)
                .disabled(purchaseManager.isLoading)

                Button(action: handleContinueFree) {
                    Text("upgrade.button.continueFree", bundle: .module)
                }
                .buttonStyle(.borderless)
            }
        }
    }

    private var footerSection: some View {
        VStack(spacing: 8) {
            Text("upgrade.footer.oneTime", bundle: .module)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Button(action: {}) {
                    Text("upgrade.footer.privacy", bundle: .module)
                }
                .buttonStyle(.plain)
                .font(.caption)

                Button(action: {}) {
                    Text("upgrade.footer.terms", bundle: .module)
                }
                .buttonStyle(.plain)
                .font(.caption)
            }
        }
    }

    private func handlePurchase() {
        Task {
            let success = await purchaseManager.purchase()
            if success {
                dismiss()
            }
        }
    }

    private func handleRestore() {
        Task {
            let success = await purchaseManager.restorePurchances()
            if success {
                dismiss()
            }
        }
    }

    private func handleContinueFree() {
        dismiss()
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let isUnlocked: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(isUnlocked ? .blue : .secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
    }
}

enum UpgradeContext {
    case trialExpired
    case multiLineBlocked
    case qrCodeBlocked
    case barcodeBlocked
    case general
}

struct UpgradeView_Previews: PreviewProvider {
    static var previews: some View {
        UpgradeView(context: .trialExpired)
            .previewDisplayName("Trial Expired")

        UpgradeView(context: .multiLineBlocked)
            .previewDisplayName("Multi-line Blocked")
    }
}