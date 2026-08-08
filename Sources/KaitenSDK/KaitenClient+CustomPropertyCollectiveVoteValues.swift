import Foundation
import OpenAPIRuntime

// MARK: - Custom Property Collective Vote Values

extension KaitenClient {
  /// Lists collective vote values on a card for a vote-type custom property.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - propertyId: The custom property identifier.
  /// - Returns: An array of vote values. Returns an empty array if nobody has voted.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card or property does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func listCollectiveVoteValues(
    cardId: Int,
    propertyId: Int
  ) async throws(KaitenError) -> [Components.Schemas.CollectiveVoteValue] {
    guard
      let response = try await callList({
        try await client.get_list_of_vote_values(
          path: .init(card_id: cardId, property_id: propertyId))
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("card", cardId)) { try $0.json }
  }

  /// Creates a vote value on a card for a vote-type custom property.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - propertyId: The custom property identifier.
  ///   - numberVote: The vote value for a property of the scale or rating variant.
  ///   - emojiVote: The vote emoji for a property of the emoji-set variant (1...12 characters).
  /// - Returns: The created vote value.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card or property does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for validation error (400),
  ///     forbidden (403) or other undocumented HTTP status codes.
  public func createCollectiveVoteValue(
    cardId: Int,
    propertyId: Int,
    numberVote: Int? = nil,
    emojiVote: String? = nil
  ) async throws(KaitenError) -> Components.Schemas.CollectiveVoteValue {
    let response = try await call {
      try await client.create_vote_value(
        path: .init(card_id: cardId, property_id: propertyId),
        body: .json(.init(emoji_vote: emojiVote, number_vote: numberVote))
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("card", cardId)) { try $0.json }
  }

  /// Updates a vote value on a card.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - propertyId: The custom property identifier.
  ///   - voteValueId: The vote value identifier.
  ///   - numberVote: The updated vote value for a property of the scale or rating variant.
  ///     Pass `.some(nil)` to clear the vote, or `nil` to leave it unchanged.
  /// - Returns: The updated vote value.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card, property or vote value does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for validation error (400),
  ///     forbidden (403) or other undocumented HTTP status codes.
  public func updateCollectiveVoteValue(
    cardId: Int,
    propertyId: Int,
    voteValueId: Int,
    numberVote: Double?? = nil
  ) async throws(KaitenError) -> Components.Schemas.CollectiveVoteValue {
    let response = try await call {
      try await client.update_vote_value(
        path: .init(card_id: cardId, property_id: propertyId, id: voteValueId),
        body: .json(
          .init(number_vote: numberVote.map { $0.map(ExplicitNullNumber.value) ?? .null }))
      )
    }
    return try decodeResponse(
      response.toCase(), notFoundResource: ("collectiveVoteValue", voteValueId)
    ) {
      try $0.json
    }
  }

  /// Removes a vote value from a card.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - propertyId: The custom property identifier.
  ///   - voteValueId: The vote value identifier.
  ///   - emojiVote: The emoji to remove, for a property of the emoji-set variant (1...12 characters).
  /// - Returns: The removed vote value.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card, property or vote value does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for validation error (400),
  ///     forbidden (403) or other undocumented HTTP status codes.
  public func deleteCollectiveVoteValue(
    cardId: Int,
    propertyId: Int,
    voteValueId: Int,
    emojiVote: String? = nil
  ) async throws(KaitenError) -> Components.Schemas.CollectiveVoteValue {
    let response = try await call {
      try await client.delete_vote_value(
        path: .init(card_id: cardId, property_id: propertyId, id: voteValueId),
        body: emojiVote.map { .json(.init(emoji_vote: $0)) }
      )
    }
    return try decodeResponse(
      response.toCase(), notFoundResource: ("collectiveVoteValue", voteValueId)
    ) {
      try $0.json
    }
  }
}
