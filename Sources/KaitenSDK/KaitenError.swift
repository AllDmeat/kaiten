import Foundation

/// Errors thrown by the Kaiten SDK.
public enum KaitenError: Error, Sendable {
  /// A required configuration value is missing.
  case missingConfiguration(String)
  /// The provided URL is invalid.
  case invalidURL(String)
  /// The API returned 401 Unauthorized.
  case unauthorized
  /// The requested resource was not found.
  case notFound(resource: String, id: Int)
  /// The API rate limit has been exceeded.
  case rateLimited(retryAfter: TimeInterval?)
  /// The server returned a 5xx error.
  case serverError(statusCode: Int, body: String?)
  /// A network-level error occurred.
  case networkError(underlying: any Error)
  /// A decoding error occurred while parsing the response.
  case decodingError(underlying: any Error)
  /// Invalid pagination parameters were provided.
  case invalidPagination(pageSize: Int)
  /// Invalid pagination range was provided.
  case invalidPaginationRange(offset: Int, limit: Int)
  /// Two arguments that cannot be combined were both provided; no request was sent.
  case conflictingArguments(String, String)
  /// The API returned an unexpected HTTP status code.
  case unexpectedResponse(statusCode: Int, body: String? = nil)
}

// MARK: - LocalizedError

extension KaitenError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .missingConfiguration(let key):
      "Missing required configuration: \(key)"
    case .invalidURL(let url):
      "Invalid URL: \(url)"
    case .unauthorized:
      "Unauthorized – check your API token"
    case .notFound(let resource, let id):
      "\(resource) with id \(id) not found"
    case .rateLimited(let retryAfter):
      if let retryAfter {
        "Rate limited – retry after \(Int(retryAfter))s"
      } else {
        "Rate limited – retry later"
      }
    case .serverError(let statusCode, let body):
      "Server error \(statusCode)" + (body.map { ": \($0)" } ?? "")
    case .networkError(let underlying):
      "Network error: \(underlying.localizedDescription)"
    case .decodingError(let underlying):
      "Decoding error: \(underlying.localizedDescription)"
    case .invalidPagination(let pageSize):
      "Invalid pageSize: \(pageSize). pageSize must be greater than 0"
    case .invalidPaginationRange(let offset, let limit):
      "Invalid pagination: offset=\(offset), limit=\(limit). offset must be >= 0 and limit must be between 1 and the endpoint's documented cap"
    case .conflictingArguments(let first, let second):
      "Conflicting arguments: \(first) and \(second) cannot be combined"
    case .unexpectedResponse(let statusCode, let body):
      "Unexpected HTTP response: \(statusCode)" + (body.map { ": \($0)" } ?? "")
    }
  }
}
