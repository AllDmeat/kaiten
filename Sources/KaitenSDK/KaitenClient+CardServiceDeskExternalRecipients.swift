import Foundation
import OpenAPIRuntime

// MARK: - Service Desk External Recipients

extension KaitenClient {
  /// Adds an external recipient to a card's service desk request.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - email: The recipient email. Kaiten accepts 1 to 128 characters.
  /// - Returns: The added recipient.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for validation errors (400),
  ///     unsupported tariff (402), forbidden (403) or other undocumented HTTP status codes.
  public func addServiceDeskExternalRecipient(cardId: Int, email: String)
    async throws(KaitenError) -> Components.Schemas.ServiceDeskExternalRecipient
  {
    let response = try await call {
      try await client.add_sd_external_recipient(
        path: .init(card_id: cardId),
        body: .json(.init(email: email))
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("card", cardId)) { try $0.json }
  }

  /// Removes an external recipient from a card's service desk request.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - email: The recipient email.
  /// - Returns: The removed recipient.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for validation errors (400),
  ///     forbidden (403) or other undocumented HTTP status codes.
  public func removeServiceDeskExternalRecipient(cardId: Int, email: String)
    async throws(KaitenError) -> Components.Schemas.ServiceDeskExternalRecipient
  {
    let response = try await call {
      try await client.remove_sd_external_recipient(
        path: .init(card_id: cardId, email: email)
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("card", cardId)) { try $0.json }
  }
}
