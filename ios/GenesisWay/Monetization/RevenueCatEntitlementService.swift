import Foundation
import RevenueCat
import StoreKit
import UIKit

// MARK: - Errors

enum MonetizationError: LocalizedError {
    case productUnavailable
    case purchaseCancelled

    var errorDescription: String? {
        switch self {
        case .productUnavailable:
            return "The product could not be loaded. Check your connection and try again."
        case .purchaseCancelled:
            return "Purchase was cancelled."
        }
    }
}

// MARK: - Service

/// Live EntitlementService backed by RevenueCat + StoreKit 2.
///
/// One-time Xcode setup:
/// 1. File → Add Package Dependencies → https://github.com/RevenueCat/purchases-ios-spm.git
///    Choose "Up to Next Major Version" from 5.x.x.
///    Add both `RevenueCat` and `RevenueCatUI` targets to GenesisWay.
/// 2. Set `MonetizationConfig.revenueCatAPIKey` to your RevenueCat public Apple key.
///    (already set — swap test_ key for production key before App Store submission)
/// 3. In App Store Connect, create products:
///    - `com.genesisway.monthly`  — Auto-Renewable Subscription, $9.99/month
///    - `com.genesisway.yearly`   — Auto-Renewable Subscription, $79.99/year
///    - `com.genesisway.lifetime` — Non-Consumable, $149.99
/// 4. In RevenueCat dashboard:
///    - Create entitlement: `pro`
///    - Import and attach all three products to `pro`
///    - Create a Current Offering with monthly, yearly, and lifetime packages
///    - Create offer codes BETA@26 (time-boxed) and INTEST@26 (unlimited) in
///      App Store Connect → Pricing & Availability → Offer Codes, then attach to `pro`
@MainActor
final class RevenueCatEntitlementService: ObservableObject, EntitlementService {
    @Published private(set) var entitlementState: EntitlementState = .preview

    // MARK: - EntitlementService

    func configure() {
        Purchases.configure(withAPIKey: MonetizationConfig.revenueCatAPIKey)
        Purchases.logLevel = .warn
        // Forward StoreKit 2 transaction updates to RevenueCat automatically.
        Purchases.shared.delegate = PurchaseDelegate.shared
    }

    func fetchEntitlement() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            entitlementState = Self.deriveState(from: info)
        } catch {
            // Preserve current state on failure — don't drop users to preview mid-session.
            print("[Monetization] fetchEntitlement error: \(error.localizedDescription)")
        }
    }

    func purchaseMonthly() async throws {
        try await purchasePackage(identifier: "$rc_monthly")
    }

    func purchaseYearly() async throws {
        try await purchasePackage(identifier: "$rc_annual")
    }

    func purchaseLifetime() async throws {
        try await purchasePackage(identifier: "$rc_lifetime")
    }

    func restorePurchases() async throws {
        let info = try await Purchases.shared.restorePurchases()
        entitlementState = Self.deriveState(from: info)
    }

    func presentOfferCodeRedemption() {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else { return }
        Task {
            do {
                try await AppStore.presentOfferCodeRedeemSheet(in: windowScene)
                await fetchEntitlement()
            } catch {
                print("[Monetization] presentOfferCodeRedemption error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Private

    private func purchasePackage(identifier: String) async throws {
        let offerings = try await Purchases.shared.offerings()
        guard let package = offerings.current?.package(identifier: identifier) else {
            throw MonetizationError.productUnavailable
        }
        let result = try await Purchases.shared.purchase(package: package)
        guard !result.userCancelled else { throw MonetizationError.purchaseCancelled }
        entitlementState = Self.deriveState(from: result.customerInfo)
    }

    private static func deriveState(from info: CustomerInfo) -> EntitlementState {
        guard let entitlement = info.entitlements[MonetizationConfig.entitlementID],
              entitlement.isActive else {
            return info.allPurchasedProductIdentifiers.isEmpty ? .preview : .expired
        }
        return .activeSubscription
    }
}

// MARK: - Delegate

/// Forwards RevenueCat background transaction updates back to the service.
private final class PurchaseDelegate: NSObject, PurchasesDelegate {
    static let shared = PurchaseDelegate()

    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            NotificationCenter.default.post(
                name: .genesisEntitlementUpdated,
                object: customerInfo
            )
        }
    }
}

extension Notification.Name {
    static let genesisEntitlementUpdated = Notification.Name("genesisEntitlementUpdated")
}
