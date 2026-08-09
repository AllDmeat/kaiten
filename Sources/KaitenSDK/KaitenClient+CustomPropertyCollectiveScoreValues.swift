import Foundation
import OpenAPIRuntime

// MARK: - Custom Property Collective Score Values

extension KaitenClient {
  /// Lists collective score values of a custom property on a card.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - propertyId: The custom property identifier.
  /// - Returns: An array of collective score values. Returns an empty array if the property has
  ///   no score values on the card.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card or custom property does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func listCollectiveScoreValues(
    cardId: Int,
    propertyId: Int
  ) async throws(KaitenError) -> [Components.Schemas.CollectiveScoreValue] {
    guard
      let response = try await callList({
        try await client.get_list_of_collective_score_values(
          path: .init(card_id: cardId, property_id: propertyId)
        )
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("card", cardId)) { try $0.json }
  }

  /// Creates a collective score value for a custom property on a card.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - propertyId: The custom property identifier.
  ///   - value: The score value. Kaiten accepts 1 to 512 characters.
  /// - Returns: The created collective score value.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card or custom property does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for validation error (400),
  ///     unsupported tariff (402), forbidden (403) or other undocumented HTTP status codes.
  public func createCollectiveScoreValue(
    cardId: Int,
    propertyId: Int,
    value: String
  ) async throws(KaitenError) -> Components.Schemas.CollectiveScoreValue {
    let response = try await call {
      try await client.create_collective_score_value(
        path: .init(card_id: cardId, property_id: propertyId),
        body: .json(.init(value: value))
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("card", cardId)) { try $0.json }
  }

  /// Updates a collective score value of a custom property on a card.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - propertyId: The custom property identifier.
  ///   - scoreValueId: The score value identifier.
  ///   - value: The updated score value. Kaiten accepts 1 to 512 characters. Pass `.some(nil)`
  ///     to clear the value (sends an explicit JSON `null`); pass `nil` to leave it unchanged.
  /// - Returns: The updated collective score value.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card, custom property or score value does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for validation error (400),
  ///     unsupported tariff (402), forbidden (403) or other undocumented HTTP status codes.
  public func updateCollectiveScoreValue(
    cardId: Int,
    propertyId: Int,
    scoreValueId: Int,
    value: String?? = nil
  ) async throws(KaitenError) -> Components.Schemas.CollectiveScoreValue {
    let response = try await call {
      try await client.update_collective_score_value(
        path: .init(card_id: cardId, property_id: propertyId, id: scoreValueId),
        body: .json(
          .init(
            // Map String?? → ExplicitNullString?:
            //   nil          → nil          (field omitted from JSON, server leaves value unchanged)
            //   .some(nil)   → .some(.null) (field sent as JSON null, server clears the value)
            //   .some("x")   → .some(.value("x")) (field sent as string, server sets the value)
            value: value.map { $0.map(ExplicitNullString.value) ?? .null }
          ))
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("scoreValue", scoreValueId)) {
      try $0.json
    }
  }
}
