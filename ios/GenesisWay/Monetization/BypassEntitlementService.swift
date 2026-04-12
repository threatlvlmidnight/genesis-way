import Foundation

/// A no-op EntitlementService used while `MonetizationConfig.useRevenueCat` is `false`.
/// Grants every user full active-subscription access without hitting RevenueCat or StoreKit.
/// To re-enable real monetization:
///   1. Set `MonetizationConfig.revenueCatAPIKey` to your production `appl_…` key.
///   2. Flip `MonetizationConfig.useRevenueCat` to `true`.
@MainActor
final class BypassEntitlementService: ObservableObject, EntitlementService {
    @Published private(set) var entitlementState: EntitlementState = .activeSubscription

    func configure() {}
    func fetchEntitlement() async {}
    func purchaseMonthly() async throws {}
    func restorePurchases() async throws {}
    func presentOfferCodeRedemption() {}
}
