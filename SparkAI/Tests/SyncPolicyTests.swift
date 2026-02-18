import CoreSync
import XCTest

final class SyncPolicyTests: XCTestCase {
    func testBackoffPolicyGrowsExponentiallyAndCaps() {
        XCTAssertEqual(SyncService.backoffSeconds(retryCount: 0), 1)
        XCTAssertEqual(SyncService.backoffSeconds(retryCount: 1), 2)
        XCTAssertEqual(SyncService.backoffSeconds(retryCount: 2), 4)
        XCTAssertEqual(SyncService.backoffSeconds(retryCount: 6), 64)
        XCTAssertEqual(SyncService.backoffSeconds(retryCount: 10), 64)
    }
}
