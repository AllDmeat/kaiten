import Foundation
import OpenAPIRuntime

// MARK: - Company Tags

extension KaitenClient {
  /// Lists tags in the company.
  ///
  /// - Parameters:
  ///   - limit: Maximum number of tags (default 100, max 100).
  ///   - offset: Number of records to skip.
  ///   - spaceId: Filter by space ID.
  ///   - ids: Comma-separated tag IDs to filter by.
  ///   - query: Tag name contains text search filter.
  /// - Returns: An array of tags. Returns an empty array if no tags match the filters.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func listTags(
    limit: Int? = nil,
    offset: Int? = nil,
    spaceId: Int? = nil,
    ids: String? = nil,
    query: String? = nil
  ) async throws(KaitenError) -> [Components.Schemas.Tag] {
    guard
      let response = try await callList({
        try await client.retrieve_list_of_tags(
          query: .init(
            limit: limit,
            offset: offset,
            space_id: spaceId,
            ids: ids,
            query: query
          )
        )
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Creates a tag in the company.
  ///
  /// The Kaiten documentation lists the same filter query parameters on this endpoint as on
  /// the list endpoint; their effect on creation is unverified.
  ///
  /// - Parameters:
  ///   - name: The tag name (1 to 128 characters).
  ///   - ids: Comma-separated IDs, documented as "list of comma separated ids to sort by".
  ///   - query: Documented as "filter by name".
  ///   - spaceId: Documented as "filter by space id".
  ///   - limit: Documented as "maximum amount of tags" (default 100, max 100).
  ///   - offset: Documented as "number of records to skip".
  /// - Returns: The created tag.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for validation error (400), forbidden (403) or other undocumented HTTP status codes.
  public func addTag(
    name: String,
    ids: String? = nil,
    query: String? = nil,
    spaceId: Int? = nil,
    limit: Int? = nil,
    offset: Int? = nil
  ) async throws(KaitenError) -> Components.Schemas.Tag {
    let response = try await call {
      try await client.add_tag(
        query: .init(
          ids: ids,
          query: query,
          space_id: spaceId,
          limit: limit,
          offset: offset
        ),
        body: .json(.init(name: name))
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }
}

// MARK: - Card Tags

extension KaitenClient {
  /// Lists all tags on a card.
  ///
  /// - Parameter cardId: The card identifier.
  /// - Returns: An array of card tags.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func listCardTags(cardId: Int) async throws(KaitenError) -> [Components.Schemas.CardTag] {
    guard
      let response = try await callList({
        try await client.list_card_tags(path: .init(card_id: cardId))
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("card", cardId)) {
      try $0.json
    }
  }

  /// Adds a tag to a card.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - name: The tag name.
  /// - Returns: The created tag.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func addCardTag(cardId: Int, name: String) async throws(KaitenError)
    -> Components
    .Schemas.Tag
  {
    let response = try await call {
      try await client.add_card_tag(
        path: .init(card_id: cardId),
        body: .json(.init(name: name))
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("card", cardId)) {
      try $0.json
    }
  }

  /// Removes a tag from a card.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - tagId: The tag identifier.
  /// - Returns: The deleted tag ID.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card or tag does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func removeCardTag(cardId: Int, tagId: Int) async throws(KaitenError) -> Int {
    let response = try await call {
      try await client.remove_card_tag(
        path: .init(card_id: cardId, tag_id: tagId)
      )
    }
    let body = try decodeResponse(response.toCase(), notFoundResource: ("tag", tagId)) {
      try $0.json
    }
    return body.id
  }
}
