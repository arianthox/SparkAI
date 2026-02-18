import CoreProviders
import Foundation
import SharedContracts
import XCTest

final class ProviderNormalizationTests: XCTestCase {
    func testOpenAINormalizationComputesBattery() throws {
        let adapter = OpenAIAdapter()
        let now = Date()
        let window = try UsageWindow(type: .monthly, start: now.addingTimeInterval(-1_000), end: now)
        let raw = RawUsagePayload(
            accountId: UUID(),
            provider: .openai,
            window: window,
            used: 25,
            limit: 100,
            unit: "credits",
            source: .officialApi,
            confidence: .exact
        )

        let snapshot = try adapter.normalize(raw: raw)
        XCTAssertEqual(snapshot.remainingValue, 75, accuracy: 0.001)
        XCTAssertEqual(snapshot.batteryPercent, 75, accuracy: 0.001)
    }
}
