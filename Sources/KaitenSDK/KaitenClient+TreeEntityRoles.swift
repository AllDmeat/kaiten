import Foundation
import OpenAPIRuntime

// MARK: - Tree Entity Roles

extension KaitenClient {
  /// Lists tree entity roles of the company.
  ///
  /// The Kaiten documentation marks this endpoint as under active development,
  /// so its response format is subject to change.
  ///
  /// - Returns: An array of tree entity roles. Returns an empty array if the company has none.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func listTreeEntityRoles() async throws(KaitenError) -> [Components.Schemas
    .TreeEntityRole]
  {
    guard
      let response = try await callList({
        try await client.list_tree_entity_roles()
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }
}
