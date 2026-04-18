import RevenueCat
import RevenueCatUI
import SwiftUI

/// Wraps RevenueCat's native PaywallView.
/// Layout and copy are configured entirely in the RevenueCat dashboard — no code changes needed
/// to update pricing, plans, or marketing copy.
struct GWPaywallView: View {
    @EnvironmentObject private var store: GenesisStore
    @Environment(\.dismiss) private var dismiss

    private var isDismissible: Bool {
        store.paywallContext == .featureGate
    }

    var body: some View {
        // RevenueCatUI.PaywallView renders your Current Offering from the RC dashboard.
        // It handles purchase, restore, and offer code redemption automatically.
        RevenueCatUI.PaywallView()
            .onPurchaseCompleted { customerInfo in
                store.handlePurchaseCompleted(customerInfo)
                dismiss()
            }
            .onRestoreCompleted { customerInfo in
                store.handlePurchaseCompleted(customerInfo)
                if store.isEntitled { dismiss() }
            }
            .interactiveDismissDisabled(!isDismissible)
    }
}
