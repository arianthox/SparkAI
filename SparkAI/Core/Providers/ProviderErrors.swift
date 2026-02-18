import Foundation

public enum ProviderError: Error, Equatable {
    case auth(String)
    case network(String)
    case rateLimit(String)
    case parse(String)
    case unsupported(String)
}
