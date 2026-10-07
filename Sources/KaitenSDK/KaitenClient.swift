import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

/// Main entry point for the Kaiten SDK.
///
/// Accepts explicit `baseURL` and `token` parameters.
public struct KaitenClient: Sendable {
  let client: Client

  // MARK: - Initialization

  /// Creates a new Kaiten API client.
  ///
  /// - Parameters:
  ///   - baseURL: Full Kaiten API base URL (e.g. `https://mycompany.kaiten.ru/api/latest`).
  ///   - token: API bearer token.
  ///   - transport: Custom `ClientTransport` implementation.
  ///     Defaults to `URLSessionTransport()` which uses `URLSession.shared`.
  ///     Pass a custom transport to use a different `URLSession`
  ///     (e.g. one configured with Replay for HTTP record/playback testing).
  /// - Throws: ``KaitenError/invalidURL(_:)`` if `baseURL` cannot be parsed.
  public init(
    baseURL: String,
    token: String,
    transport: any ClientTransport = URLSessionTransport()
  ) throws(KaitenError) {
    guard
      let url = URL(string: baseURL),
      url.scheme?.lowercased() == "https"
    else {
      throw KaitenError.invalidURL(baseURL)
    }
    let gate = RateLimitGate()
    self.client = Client(
      serverURL: url,
      transport: transport,
      middlewares: [
        ExplicitNullFieldsMiddleware(),
        AuthenticationMiddleware(token: token),
        RetryMiddleware(gate: gate),
      ]
    )
  }

  // MARK: - Internal Helpers

  /// Executes an API call, wrapping non-KaitenError into `.networkError`.
  func call<T>(_ operation: () async throws -> T) async throws(KaitenError) -> T {
    do {
      return try await operation()
    } catch let error as KaitenError {
      throw error
    } catch {
      throw .networkError(underlying: error)
    }
  }

  /// Executes an API call for list endpoints.
  /// Returns `nil` when Kaiten returns HTTP 200 with an empty body (no JSON),
  /// allowing callers to fall back to an empty array.
  /// Propagates decoding errors instead of silently returning nil.
  func callList<T>(_ operation: () async throws -> T) async throws(KaitenError) -> T? {
    do {
      return try await operation()
    } catch let error as ClientError where error.response?.status == .ok {
      // If the underlying error is a schema mismatch (typeMismatch or
      // keyNotFound), the body was valid JSON but didn't match the
      // expected schema — propagate instead of hiding.
      // Other DecodingErrors (dataCorrupted from empty/invalid body)
      // are treated as "no data" only for truly empty bodies.
      if let decodingError = error.underlyingError as? DecodingError {
        switch decodingError {
        case .typeMismatch, .keyNotFound, .valueNotFound:
          throw .decodingError(underlying: error)
        case .dataCorrupted:
          if await isEmptyBody(error.responseBody) {
            return nil
          }
          throw .decodingError(underlying: error)
        @unknown default:
          throw .decodingError(underlying: error)
        }
      }
      if await isEmptyBody(error.responseBody) {
        return nil
      }
      throw .networkError(underlying: error)
    } catch let error as KaitenError {
      throw error
    } catch {
      throw .networkError(underlying: error)
    }
  }

  /// Decodes a value, wrapping errors into `.decodingError`.
  func decode<T>(_ extract: () throws -> T) throws(KaitenError) -> T {
    do {
      return try extract()
    } catch {
      throw .decodingError(underlying: error)
    }
  }

  func validatePagination(offset: Int, limit: Int, maxLimit: Int = 100) throws(KaitenError) {
    guard offset >= 0, (1...maxLimit).contains(limit) else {
      throw .invalidPaginationRange(offset: offset, limit: limit)
    }
  }

  /// Checks whether the response body is empty (nil or zero bytes).
  ///
  /// The `catch` block handles two iteration behaviors of `HTTPBody`:
  /// - `.multiple` bodies (e.g. from `HTTPBody(data:)`): re-readable, works normally.
  /// - `.single` bodies already consumed: throws `TooManyIterationsError`.
  ///
  /// Returning `false` on error means "treat as non-empty", so the caller
  /// propagates the original decoding error rather than silently swallowing it.
  private func isEmptyBody(_ body: HTTPBody?) async -> Bool {
    guard let body else { return true }

    do {
      for try await chunk in body {
        if !chunk.isEmpty { return false }
      }
      return true
    } catch {
      return false
    }
  }

  /// Standard response case from an OpenAPI-generated Output enum.
  /// Standard response case from an OpenAPI-generated Output enum.
  enum ResponseCase<OKBody> {
    case ok(OKBody)
    case unauthorized
    case forbidden
    case notFound
    case undocumented(statusCode: Int)
  }

  /// Backwards-compatible alias so `KaitenClient.CardFilter` still resolves.
  public typealias CardFilter = KaitenSDK.CardFilter

  /// Convenience: handle response, decode JSON body.
  func decodeResponse<OKBody, T: Sendable>(
    _ responseCase: ResponseCase<OKBody>,
    notFoundResource: (name: String, id: Int)? = nil,
    json: (OKBody) throws -> T
  ) throws(KaitenError) -> T {
    switch responseCase {
    case .ok(let body):
      return try decode { try json(body) }
    case .unauthorized:
      throw .unauthorized
    case .forbidden:
      throw .unexpectedResponse(statusCode: 403)
    case .notFound:
      if let res = notFoundResource {
        throw .notFound(resource: res.name, id: res.id)
      }
      throw .unexpectedResponse(statusCode: 404)
    case .undocumented(let code):
      throw .unexpectedResponse(statusCode: code)
    }
  }
}
