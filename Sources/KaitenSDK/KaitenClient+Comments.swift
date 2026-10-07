import Foundation
import OpenAPIRuntime

// MARK: - Comments

extension KaitenClient {
  /// Creates a comment on a card.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - text: Comment text (markdown).
  /// - Returns: The created comment.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func createComment(cardId: Int, text: String) async throws(KaitenError)
    -> Components.Schemas.Comment
  {
    let response = try await call {
      try await client.create_card_comment(
        path: .init(card_id: cardId),
        body: .json(.init(text: text))
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("card", cardId)) { try $0.json }
  }

  /// Updates a comment on a card.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - commentId: The comment identifier.
  ///   - text: New comment text (markdown).
  /// - Returns: The updated comment.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card or comment does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func updateComment(cardId: Int, commentId: Int, text: String) async throws(KaitenError)
    -> Components.Schemas.Comment
  {
    let response = try await call {
      try await client.update_card_comment(
        path: .init(card_id: cardId, comment_id: commentId),
        body: .json(.init(text: text))
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("comment", commentId)) {
      try $0.json
    }
  }

  /// Fetches comments on a card, one page at a time.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - limit: Maximum number of comments to return (1–100). The API returns 100 when omitted.
  ///   - offset: Number of comments to skip.
  /// - Returns: An array of comments. Returns an empty array if the card has no comments.
  /// - Throws:
  ///   - ``KaitenError/invalidPaginationRange(offset:limit:)`` if pagination parameters are out of range.
  ///   - ``KaitenError/notFound(resource:id:)`` if the card does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func getCardComments(
    cardId: Int,
    limit: Int? = nil,
    offset: Int? = nil
  ) async throws(KaitenError) -> [Components.Schemas.Comment] {
    try validatePagination(offset: offset ?? 0, limit: limit ?? 100)
    guard
      let response = try await callList({
        try await client.retrieve_card_comments(
          path: .init(card_id: cardId), query: .init(limit: limit, offset: offset))
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("card", cardId)) { try $0.json }
  }

  /// Deletes a comment from a card.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - commentId: The comment identifier.
  /// - Returns: The deleted comment ID.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card or comment does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func deleteComment(cardId: Int, commentId: Int) async throws(KaitenError) -> Int {
    let response = try await call {
      try await client.delete_card_comment(
        path: .init(card_id: cardId, comment_id: commentId))
    }
    let result: Components.Schemas.DeletedCommentResponse = try decodeResponse(
      response.toCase(), notFoundResource: ("comment", commentId)
    ) { try $0.json }
    return result.id
  }
}
