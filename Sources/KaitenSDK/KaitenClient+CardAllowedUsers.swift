import Foundation
import OpenAPIRuntime

// MARK: - Card Allowed Users

extension KaitenClient {
  /// Lists users with access to a card.
  ///
  /// The documented `search`, `orderBy`, `limit` and `offset` parameters are accepted by the API
  /// but have no observed effect: the full list is returned regardless.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - type: The type of users to return. Documented values: `sd-owners` (company users with
  ///     access to service-desk), `virtual-users` (company virtual users), `mention`.
  ///   - search: Filter by full name, email or username.
  ///   - orderBy: The field to sort by.
  ///   - role: Filter by role.
  ///   - limit: Maximum amount of users in the response.
  ///   - offset: Number of records to skip.
  /// - Returns: An array of users allowed to access the card. Returns an empty array if the
  ///   response is empty.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other
  ///     undocumented HTTP status codes.
  public func listCardAllowedUsers(
    cardId: Int,
    type: String? = nil,
    search: String? = nil,
    orderBy: String? = nil,
    role: Int? = nil,
    limit: Int? = nil,
    offset: Int? = nil
  ) async throws(KaitenError) -> [Components.Schemas.AllowedUser] {
    guard
      let response = try await callList({
        try await client.retrieve_card_allowed_users(
          path: .init(card_id: cardId),
          query: .init(
            _type: type,
            search: search,
            orderBy: orderBy,
            role: role,
            limit: limit,
            offset: offset
          )
        )
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("card", cardId)) {
      try $0.json
    }
  }
}
