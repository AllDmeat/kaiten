import Foundation
import OpenAPIRuntime

// MARK: - Card Blockers

extension KaitenClient {
  /// Lists all blockers on a card.
  ///
  /// - Parameter cardId: The card identifier.
  /// - Returns: An array of card blockers. Returns an empty array if the card has no blockers.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func listCardBlockers(cardId: Int) async throws(KaitenError) -> [Components.Schemas
    .CardBlocker]
  {
    guard
      let response = try await callList({
        try await client.list_card_blockers(path: .init(card_id: cardId))
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("card", cardId)) {
      try $0.json
    }
  }

  /// Creates a blocker on a card.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - reason: The reason for the blocker.
  ///   - blockerCardId: The identifier of the blocking card.
  /// - Returns: The created card blocker.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func createCardBlocker(cardId: Int, reason: String? = nil, blockerCardId: Int? = nil)
    async throws(KaitenError) -> Components.Schemas.CardBlocker
  {
    let response = try await call {
      try await client.create_card_blocker(
        path: .init(card_id: cardId),
        body: .json(.init(reason: reason, blocker_card_id: blockerCardId))
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("card", cardId)) {
      try $0.json
    }
  }

  /// Updates a card blocker.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - blockerId: The blocker identifier.
  ///   - reason: The updated reason for the blocker.
  ///   - blockerCardId: The updated identifier of the blocking card.
  ///   - dueDate: The block deadline in ISO 8601 format. Pass `.some(nil)` to clear it;
  ///     `nil` leaves it unchanged.
  ///   - dueDateTimePresent: Whether the deadline is specified up to hours and minutes.
  /// - Returns: The updated card blocker.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the blocker does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func updateCardBlocker(
    cardId: Int, blockerId: Int, reason: String? = nil, blockerCardId: Int? = nil,
    dueDate: String?? = .none, dueDateTimePresent: Bool? = nil
  ) async throws(KaitenError) -> Components.Schemas.CardBlocker {
    let response = try await call {
      try await client.update_card_blocker(
        path: .init(card_id: cardId, id: blockerId),
        body: .json(
          .init(
            reason: reason,
            blocker_card_id: blockerCardId,
            due_date: dueDate.map { $0.map(ExplicitNullString.value) ?? .null },
            due_date_time_present: dueDateTimePresent
          ))
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("blocker", blockerId)) {
      try $0.json
    }
  }

  /// Deletes a card blocker.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - blockerId: The blocker identifier.
  /// - Returns: The deleted card blocker.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the blocker does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func deleteCardBlocker(cardId: Int, blockerId: Int) async throws(KaitenError)
    -> Components.Schemas.CardBlocker
  {
    let response = try await call {
      try await client.delete_card_blocker(
        path: .init(card_id: cardId, id: blockerId)
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("blocker", blockerId)) {
      try $0.json
    }
  }
}
