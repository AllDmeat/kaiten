import Foundation
import OpenAPIRuntime

// MARK: - Card Time Logs

extension KaitenClient {
  /// Fetches time logs on a card.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - forDate: Filter by the `for_date` attribute (`YYYY-MM-DD`).
  ///   - personal: When `true`, returns only the current user's time logs.
  /// - Returns: An array of time logs. Returns an empty array if the card has no time logs.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func getCardTimeLogs(
    cardId: Int,
    forDate: String? = nil,
    personal: Bool? = nil
  ) async throws(KaitenError) -> [Components.Schemas.CardTimeLog] {
    guard
      let response = try await callList({
        try await client.get_card_time_logs(
          path: .init(card_id: cardId),
          query: .init(for_date: forDate, personal: personal)
        )
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("card", cardId)) { try $0.json }
  }

  /// Adds a time log to a card.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - roleId: The role identifier. The predefined role `-1` is Employee.
  ///   - timeSpent: Minutes to log. Kaiten requires at least 1.
  ///   - forDate: Log date in `YYYY-MM-DD` format.
  ///   - comment: Optional comment for the time log. Kaiten accepts up to 4096 characters.
  /// - Returns: The created time log.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for validation error (400),
  ///     unsupported tariff (402), forbidden (403) or other undocumented HTTP status codes.
  public func createCardTimeLog(
    cardId: Int,
    roleId: Int,
    timeSpent: Int,
    forDate: String,
    comment: String? = nil
  ) async throws(KaitenError) -> Components.Schemas.CardTimeLog {
    let response = try await call {
      try await client.create_card_time_log(
        path: .init(card_id: cardId),
        body: .json(
          .init(role_id: roleId, time_spent: timeSpent, for_date: forDate, comment: comment))
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("card", cardId)) { try $0.json }
  }

  /// Updates a time log on a card.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - timeLogId: The time log identifier.
  ///   - roleId: The updated role identifier. The predefined role `-1` is Employee.
  ///   - timeSpent: Updated minutes to log. Kaiten requires at least 1.
  ///   - forDate: Updated log date in `YYYY-MM-DD` format.
  ///   - comment: Updated comment. Kaiten accepts up to 4096 characters.
  /// - Returns: The updated time log.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card or time log does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for validation error (400),
  ///     unsupported tariff (402), forbidden (403) or other undocumented HTTP status codes.
  public func updateCardTimeLog(
    cardId: Int,
    timeLogId: Int,
    roleId: Int? = nil,
    timeSpent: Int? = nil,
    forDate: String? = nil,
    comment: String? = nil
  ) async throws(KaitenError) -> Components.Schemas.CardTimeLog {
    let response = try await call {
      try await client.update_card_time_log(
        path: .init(card_id: cardId, id: timeLogId),
        body: .json(
          .init(role_id: roleId, time_spent: timeSpent, for_date: forDate, comment: comment))
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("timeLog", timeLogId)) {
      try $0.json
    }
  }

  /// Removes a time log from a card.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - timeLogId: The time log identifier.
  /// - Returns: The deleted time log ID.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card or time log does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for unsupported tariff (402),
  ///     forbidden (403) or other undocumented HTTP status codes.
  public func deleteCardTimeLog(cardId: Int, timeLogId: Int) async throws(KaitenError) -> Int {
    let response = try await call {
      try await client.delete_card_time_log(path: .init(card_id: cardId, id: timeLogId))
    }
    let result: Components.Schemas.DeletedTimeLogResponse = try decodeResponse(
      response.toCase(), notFoundResource: ("timeLog", timeLogId)
    ) { try $0.json }
    return result.id
  }
}
