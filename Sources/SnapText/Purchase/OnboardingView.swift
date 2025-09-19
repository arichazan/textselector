import SwiftUI

struct OnboardingView: View {
    @StateObject private var purchaseManager = PurchaseManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var currentPage = 0
    private let totalPages = 3

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                welcomePage
                    .tag(0)

                featuresPage
                    .tag(1)

                trialPage
                    .tag(2)
            }
            .tabViewStyle(.automatic)

            bottomSection
        }
        .frame(width: 520, height: 640)
        .background(Color(.windowBackgroundColor))
    }

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "text.viewfinder")
                .font(.system(size: 64))
                .foregroundColor(.blue)

            VStack(spacing: 12) {
                Text("onboarding.welcome.title", bundle: .module)
                    .font(.title)
                    .fontWeight(.bold)

                Text("onboarding.welcome.subtitle", bundle: .module)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding(40)
    }

    private var featuresPage: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Text("onboarding.features.title", bundle: .module)
                    .font(.title2)
                    .fontWeight(.bold)

                Text("onboarding.features.subtitle", bundle: .module)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 20) {
                OnboardingFeature(
                    icon: "text.alignleft",
                    title: localizedString("onboarding.features.text.title", comment: "Text OCR feature title"),
                    description: localizedString("onboarding.features.text.description", comment: "Text OCR feature description"),
                    color: .blue
                )

                OnboardingFeature(
                    icon: "qrcode",
                    title: localizedString("onboarding.features.qr.title", comment: "QR code feature title"),
                    description: localizedString("onboarding.features.qr.description", comment: "QR code feature description"),
                    color: .green
                )

                OnboardingFeature(
                    icon: "barcode",
                    title: localizedString("onboarding.features.barcode.title", comment: "Barcode feature title"),
                    description: localizedString("onboarding.features.barcode.description", comment: "Barcode feature description"),
                    color: .orange
                )
            }

            Spacer()
        }
        .padding(40)
    }

    private var trialPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "gift")
                .font(.system(size: 48))
                .foregroundColor(.purple)

            VStack(spacing: 12) {
                Text("onboarding.trial.title", bundle: .module)
                    .font(.title2)
                    .fontWeight(.bold)

                Text("onboarding.trial.subtitle", bundle: .module)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 16) {
                TrialBenefit(
                    icon: "checkmark.circle.fill",
                    text: localizedString("onboarding.trial.benefit1", comment: "Full access benefit"),
                    color: .green
                )

                TrialBenefit(
                    icon: "calendar",
                    text: localizedString("onboarding.trial.benefit2", comment: "7 days benefit"),
                    color: .blue
                )

                TrialBenefit(
                    icon: "hand.raised.fill",
                    text: localizedString("onboarding.trial.benefit3", comment: "No commitment benefit"),
                    color: .orange
                )
            }

            Spacer()
        }
        .padding(40)
    }

    private var bottomSection: some View {
        VStack(spacing: 16) {
            // Page indicator
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.blue : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }

            // Buttons
            HStack(spacing: 12) {
                if currentPage > 0 {
                    Button(action: previousPage) {
                        Text("onboarding.button.back", bundle: .module)
                    }
                    .buttonStyle(.borderless)
                }

                Spacer()

                if currentPage < totalPages - 1 {
                    Button(action: nextPage) {
                        Text("onboarding.button.next", bundle: .module)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button(action: startTrial) {
                        Text("onboarding.button.startTrial", bundle: .module)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }

            // Skip button
            if currentPage < totalPages - 1 {
                Button(action: skipOnboarding) {
                    Text("onboarding.button.skip", bundle: .module)
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(24)
    }

    private func nextPage() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentPage = min(currentPage + 1, totalPages - 1)
        }
    }

    private func previousPage() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentPage = max(currentPage - 1, 0)
        }
    }

    private func startTrial() {
        dismiss()
    }

    private func skipOnboarding() {
        dismiss()
    }
}

struct OnboardingFeature: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

struct TrialBenefit: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)

            Text(text)
                .font(.subheadline)

            Spacer()
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}