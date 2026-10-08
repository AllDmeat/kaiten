import Foundation
import OpenAPIRuntime

// MARK: - External Links

extension KaitenClient {
  /// Lists all external links on a card.
  ///
  /// - Parameter cardId: The card identifier.
  /// - Returns: An array of external links. Returns an empty array if the card has no external links.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func listExternalLinks(cardId: Int) async throws(KaitenError) -> [Components.Schemas
    .ExternalLink]
  {
    guard
      let response = try await callList({
        try await client.list_card_external_links(path: .init(card_id: cardId))
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("card", cardId)) { try $0.json }
  }

  /// Creates an external link on a card.
  ///
  /// When `url` points to another card in the same Kaiten company, Kaiten also adds a link
  /// back to this card on that card, so linking two cards needs one call, not two.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - url: The external link URL.
  ///   - description: An optional description for the link.
  /// - Returns: The created external link.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func createExternalLink(cardId: Int, url: String, description: String? = nil)
    async throws(KaitenError) -> Components.Schemas.ExternalLink
  {
    let response = try await call {
      try await client.create_card_external_link(
        path: .init(card_id: cardId),
        body: .json(.init(url: url, description: description))
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("card", cardId)) { try $0.json }
  }

  /// Updates an external link on a card.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - linkId: The external link identifier.
  ///   - url: The updated URL.
  ///   - description: The updated description.
  /// - Returns: The updated external link.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the external link does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func updateExternalLink(
    cardId: Int, linkId: Int, url: String? = nil, description: String? = nil
  )
    async throws(KaitenError) -> Components.Schemas.ExternalLink
  {
    let response = try await call {
      try await client.update_card_external_link(
        path: .init(card_id: cardId, id: linkId),
        body: .json(.init(url: url, description: description))
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("externalLink", linkId)) {
      try $0.json
    }
  }

  /// Removes an external link from a card.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - linkId: The external link identifier.
  /// - Returns: The deleted external link ID.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the external link does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func removeExternalLink(cardId: Int, linkId: Int) async throws(KaitenError) -> Int {
    let response = try await call {
      try await client.remove_card_external_link(path: .init(card_id: cardId, id: linkId))
    }
    let result: Components.Schemas.DeletedExternalLinkResponse = try decodeResponse(
      response.toCase(), notFoundResource: ("externalLink", linkId)
    ) { try $0.json }
    return result.id
  }
}
