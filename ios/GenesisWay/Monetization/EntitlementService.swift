import Combine
import Foundation

// MARK: - Domain Types

/// The effective entitlement access state for the current user.
enum EntitlementState: Equatable {
    /// User has an active paid subscription.
    case activeSubscription
    /// User has redeemed an offer code granting full access.
    case offerCodeAccess
    /// User previously had access that has since expired.
    case expired
    /// User is browsing in preview mode — no active entitlement.
    case preview
}

/// Context that triggered the paywall, used to control sheet behavior.
enum PaywallContext {
    /// Triggered by "Begin the Journey" or "Skip to planner" during onboarding.
    /// The paywall is non-dismissible — the user must make an explicit choice.
    case onboarding
    /// Triggered by attempting a gated action (e.g. adding a task) in preview mode.
    /// The paywall can be dismissed to stay in preview mode.
    case featureGate
}

// MARK: - Protocol

/// Service that owns all entitlement and purchase logic.
/// Conforming types wrap StoreKit 2 via RevenueCat.
@MainActor
protocol EntitlementService: AnyObject {
    /// The current entitlement state. Changes should publish to observers.
    var entitlementState: EntitlementState { get }

    /// Type-erased publisher that fires whenever entitlement state changes.
    /// Use instead of `objectWillChange` so the protocol can be used as an existential.
    var objectWillChangePublisher: AnyPublisher<Void, Never> { get }

    /// Configure the underlying SDK. Must be called once before any purchase operation.
    func configure()

    /// Refresh entitlement from the vendor. Call on app foreground and after any purchase.
    func fetchEntitlement() async

    /// Purchase the $10/month base plan. Throws on cancellation or failure.
    func purchaseMonthly() async throws

    /// Purchase the yearly plan. Throws on cancellation or failure.
    func purchaseYearly() async throws

    /// Purchase the lifetime plan. Throws on cancellation or failure.
    func purchaseLifetime() async throws

    /// Restore previous purchases from the App Store.
    func restorePurchases() async throws

    /// Presents the native App Store offer-code redemption sheet.
    func presentOfferCodeRedemption()
}
