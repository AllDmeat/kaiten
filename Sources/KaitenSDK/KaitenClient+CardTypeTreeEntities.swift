import Foundation
import OpenAPIRuntime

// MARK: - Card Type Tree Entities

extension KaitenClient {
  /// Lists the tree entities attached to a card type.
  ///
  /// - Parameter typeId: The card type identifier.
  /// - Returns: An array of tree entities. Returns an empty array if the card type has none.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for unsupported tariff (402),
  ///     forbidden (403) or other undocumented HTTP status codes.
  public func listCardTypeTreeEntities(typeId: Int) async throws(KaitenError) -> [Components
    .Schemas.CardTypeTreeEntity]
  {
    guard
      let response = try await callList({
        try await client.list_card_type_tree_entities(path: .init(type_id: typeId))
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Adds a tree entity to a card type.
  ///
  /// - Parameters:
  ///   - typeId: The card type identifier.
  ///   - treeEntityUid: The UID of the tree entity to attach.
  /// - Returns: The identifier of the card type the entity was attached to.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for bad request (400), unsupported
  ///     tariff (402), forbidden (403) or other undocumented HTTP status codes.
  public func addCardTypeTreeEntity(
    typeId: Int,
    treeEntityUid: String
  ) async throws(KaitenError) -> Components.Schemas.CardTypeIdResponse {
    let response = try await call {
      try await client.add_card_type_tree_entity(
        path: .init(type_id: typeId),
        body: .json(.init(tree_entity_uid: treeEntityUid))
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Deletes a tree entity from a card type.
  ///
  /// - Parameters:
  ///   - typeId: The card type identifier.
  ///   - uid: The UID of the tree entity to detach.
  /// - Returns: The identifier of the card type the entity was detached from.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for unsupported tariff (402),
  ///     forbidden (403) or other undocumented HTTP status codes.
  public func deleteCardTypeTreeEntity(
    typeId: Int,
    uid: String
  ) async throws(KaitenError) -> Components.Schemas.CardTypeIdResponse {
    let response = try await call {
      try await client.delete_card_type_tree_entity(path: .init(type_id: typeId, uid: uid))
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }
}
