import Foundation
import OpenAPIRuntime

// MARK: - Card Blocker Users

extension KaitenClient {
  /// Lists the users assigned to a card blocker.
  ///
  /// - Parameter blockerId: The blocker identifier.
  /// - Returns: An array of blocker users. Returns an empty array if the blocker has no
  ///   assigned users.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for undocumented HTTP status codes.
  public func listCardBlockerUsers(blockerId: Int) async throws(KaitenError) -> [Components
    .Schemas.CardBlockerUser]
  {
    guard
      let response = try await callList({
        try await client.list_card_blocker_users(path: .init(blocker_id: blockerId))
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Adds a user to a card blocker.
  ///
  /// - Parameters:
  ///   - blockerId: The blocker identifier.
  ///   - userId: The identifier of the user to add.
  /// - Returns: The added blocker user.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for undocumented HTTP status codes.
  public func addCardBlockerUser(blockerId: Int, userId: Int) async throws(KaitenError)
    -> Components.Schemas.CardBlockerUser
  {
    let response = try await call {
      try await client.add_card_blocker_user(
        path: .init(blocker_id: blockerId),
        body: .json(.init(user_id: userId))
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Removes a user from a card blocker.
  ///
  /// - Parameters:
  ///   - blockerId: The blocker identifier.
  ///   - userId: The identifier of the user to remove.
  /// - Returns: The removal confirmation carrying the removed user identifier.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for undocumented HTTP status codes.
  public func removeCardBlockerUser(blockerId: Int, userId: Int) async throws(KaitenError)
    -> Components.Schemas.RemovedCardBlockerUserResponse
  {
    let response = try await call {
      try await client.remove_card_blocker_user(
        path: .init(blocker_id: blockerId, user_id: userId)
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Retrieves the cards blocked on the current user.
  ///
  /// The documentation declares the response as an object, but a live instance returns an
  /// empty JSON array when the current user has no blockers. That shape is mapped to an
  /// empty result: `blocked_cards` is an empty array and `summary` is `nil`.
  ///
  /// - Returns: The blocked cards and their summary.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for undocumented HTTP status codes.
  public func getCurrentUserBlockers() async throws(KaitenError)
    -> Components.Schemas.CurrentUserBlockersList
  {
    let response = try await call {
      try await client.retrieve_current_user_blockers()
    }
    let payload = try decodeResponse(response.toCase()) { try $0.json }
    return payload.value1 ?? .init(blocked_cards: [], summary: nil)
  }
}
