import Foundation
import OpenAPIRuntime

// MARK: - Service Desk Services

extension KaitenClient {
  /// Lists all service desk services in the company.
  ///
  /// Requires a token with access to the service desk; without it the API answers HTTP 403.
  ///
  /// - Returns: An array of services. Returns an empty array if the company has no services.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func listServiceDeskServices() async throws(KaitenError) -> [Components.Schemas
    .ServiceDeskService]
  {
    guard
      let response = try await callList({
        try await client.list_service_desk_services()
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }
}
