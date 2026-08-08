import Foundation
import OpenAPIRuntime

// MARK: - Custom Property Tree Entities

extension KaitenClient {
  /// Lists the tree entities attached to a custom property.
  ///
  /// - Parameter propertyId: The custom property identifier.
  /// - Returns: An array of tree entities. Returns an empty array if the custom property has none.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for unsupported tariff (402),
  ///     forbidden (403) or other undocumented HTTP status codes.
  public func listCustomPropertyTreeEntities(propertyId: Int) async throws(KaitenError)
    -> [Components.Schemas.CustomPropertyTreeEntity]
  {
    guard
      let response = try await callList({
        try await client.list_custom_property_tree_entities(path: .init(property_id: propertyId))
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Adds a tree entity to a custom property.
  ///
  /// - Parameters:
  ///   - propertyId: The custom property identifier.
  ///   - treeEntityUid: The UID of the tree entity to attach.
  /// - Returns: The identifier of the custom property the entity was attached to.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for bad request (400), unsupported
  ///     tariff (402), forbidden (403) or other undocumented HTTP status codes.
  public func addCustomPropertyTreeEntity(
    propertyId: Int,
    treeEntityUid: String
  ) async throws(KaitenError) -> Components.Schemas.CustomPropertyIdResponse {
    let response = try await call {
      try await client.add_custom_property_tree_entity(
        path: .init(property_id: propertyId),
        body: .json(.init(tree_entity_uid: treeEntityUid))
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Deletes a tree entity from a custom property.
  ///
  /// - Parameters:
  ///   - propertyId: The custom property identifier.
  ///   - uid: The UID of the tree entity to detach.
  /// - Returns: The identifier of the custom property the entity was detached from.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for unsupported tariff (402),
  ///     forbidden (403) or other undocumented HTTP status codes.
  public func deleteCustomPropertyTreeEntity(
    propertyId: Int,
    uid: String
  ) async throws(KaitenError) -> Components.Schemas.CustomPropertyIdResponse {
    let response = try await call {
      try await client.delete_custom_property_tree_entity(
        path: .init(property_id: propertyId, uid: uid))
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }
}
