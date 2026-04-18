import Foundation

/// Static configuration for the monetization layer.
/// Update product IDs and entitlement ID to match your App Store Connect + RevenueCat dashboard.
enum MonetizationConfig {
    // MARK: - Feature flag

    /// Set to `true` once you have a production RevenueCat key and are ready to
    /// enforce subscriptions. While `false`, `BypassEntitlementService` is used
    /// and all users receive full access automatically.
    static let useRevenueCat = false

    // MARK: - RevenueCat

    /// RevenueCat public SDK key (Apple / sandbox).
    /// Replace the test_ key with your production `appl_…` key from the
    /// RevenueCat dashboard before flipping `useRevenueCat` to `true`.
    static let revenueCatAPIKey = "test_REOWGjxZupzpyxgHkadLqokBpcM"

    /// RevenueCat entitlement identifier granting full app access.
    /// Must match exactly what is set in RevenueCat Dashboard → Entitlements.
    static let entitlementID = "Coach: with Dan Holland Pro"

    // MARK: - App Store Connect Product IDs
    // Must match exactly what is configured in App Store Connect > In-App Purchases.

    static let monthlyProductID  = "com.genesisway.monthly"
    static let yearlyProductID   = "com.genesisway.yearly"
    static let lifetimeProductID = "com.genesisway.lifetime"
}
