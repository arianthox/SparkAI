import Foundation
import SharedContracts

public struct RawUsagePayload: Sendable {
    public let accountId: UUID
    public let provider: Provider
    public let window: UsageWindow
    public let used: Double
    public let limit: Double
    public let unit: String
    public let source: UsageSource
    public let confidence: UsageConfidence

    public init(
        accountId: UUID,
        provider: Provider,
        window: UsageWindow,
        used: Double,
        limit: Double,
        unit: String,
        source: UsageSource,
        confidence: UsageConfidence
    ) {
        self.accountId = accountId
        self.provider = provider
        self.window = window
        self.used = used
        self.limit = limit
        self.unit = unit
        self.source = source
        self.confidence = confidence
    }
}

public protocol ProviderAdapter: Sendable {
    var provider: Provider { get }
    func validateCredentials(account: Account, credential: String?) async throws
    func fetchUsage(account: Account, window: UsageWindow, credential: String?) async throws -> RawUsagePayload
    func normalize(raw: RawUsagePayload) throws -> UsageSnapshot
}
