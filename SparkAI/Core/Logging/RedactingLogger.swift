import Foundation
import os

public struct RedactingLogger: Sendable {
    private let logger: Logger

    public init(subsystem: String = "com.sparkai.app", category: String) {
        self.logger = Logger(subsystem: subsystem, category: category)
    }

    public func info(_ message: String, metadata: [String: String] = [:]) {
        logger.info("\(redact("\(message) \(metadata.description)"), privacy: .public)")
    }

    public func error(_ message: String, metadata: [String: String] = [:]) {
        logger.error("\(redact("\(message) \(metadata.description)"), privacy: .public)")
    }

    public func debug(_ message: String, metadata: [String: String] = [:], enabled: Bool) {
        guard enabled else { return }
        logger.debug("\(redact("\(message) \(metadata.description)"), privacy: .public)")
    }

    public func redact(_ input: String) -> String {
        var output = input
        let patterns = [
            #"(?i)(authorization:\s*bearer\s+)[a-zA-Z0-9\-\._~\+/=]+"#,
            #"(?i)(api[_-]?key["'=:\s]+)[a-zA-Z0-9\-\._~\+/=]+"#,
            #"(?i)(token["'=:\s]+)[a-zA-Z0-9\-\._~\+/=]+"#,
            #"(?i)(cookie["'=:\s]+)[^;\s]+"#
        ]
        for pattern in patterns {
            output = output.replacingOccurrences(
                of: pattern,
                with: "$1[REDACTED]",
                options: .regularExpression
            )
        }
        return output
    }
}
