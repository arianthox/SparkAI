import Foundation
import SharedContracts
import XCTest

final class SharedContractsTests: XCTestCase {
    func testAccountValidationRejectsEmptyName() {
        XCTAssertThrowsError(try Account(provider: .openai, displayName: " ", authType: .apiKey))
    }

    func testUsageSnapshotBatteryPercentMustBeInBounds() {
        let now = Date()
        XCTAssertThrowsError(
            try UsageSnapshot(
                accountId: UUID(),
                provider: .openai,
                windowType: .daily,
                windowStart: now,
                windowEnd: now,
                usedValue: 10,
                usedUnit: "credits",
                limitValue: 100,
                limitUnit: "credits",
                remainingValue: 90,
                batteryPercent: 140,
                confidence: .exact,
                source: .officialApi
            )
        )
    }
}
