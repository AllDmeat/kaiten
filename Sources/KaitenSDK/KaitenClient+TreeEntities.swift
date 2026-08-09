import Foundation
import OpenAPIRuntime

// MARK: - Typed Discriminators

// The tree entity type travels as a plain string (see the comment above the
// tree entity enum in `Enums.swift`). This accessor gives the generated
// payload a typed surface without losing undocumented values.

extension Components.Schemas.TreeEntity {
  /// The entity type, or `nil` if the API omitted the field.
  public var treeEntityType: TreeEntityType? {
    entity_type.map(TreeEntityType.init(rawValue:))
  }
}

// MARK: - Tree Entities

extension KaitenClient {
  /// Returns a page of company tree entities (spaces, documents, document groups
  /// and story maps).
  ///
  /// Kaiten documents this endpoint as under active development: parameters,
  /// attributes and response formats are subject to change. Each entity type
  /// carries its own extra fields beyond the common ones.
  ///
  /// - Parameters:
  ///   - parentEntityUid: Return entities nested in the entity with this UID (optional).
  ///   - levelsCount: Maximum depth level, up to `2` (optional).
  ///   - offset: Number of entities to skip (default `0`).
  ///   - limit: Maximum number of entities to return (default `500`, max `500`).
  /// - Returns: A ``Page`` of tree entities. Returns an empty page when nothing matches.
  /// - Throws:
  ///   - ``KaitenError/invalidPaginationRange(offset:limit:)`` if pagination parameters are out of range.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other
  ///     undocumented HTTP status codes.
  public func listTreeEntities(
    parentEntityUid: String? = nil,
    levelsCount: Int? = nil,
    offset: Int = 0,
    limit: Int = 500
  ) async throws(KaitenError) -> Page<Components.Schemas.TreeEntity> {
    guard offset >= 0, (1...500).contains(limit) else {
      throw .invalidPaginationRange(offset: offset, limit: limit)
    }
    let query = Operations.list_tree_entities.Input.Query(
      limit: limit,
      offset: offset,
      parent_entity_uid: parentEntityUid,
      levels_count: levelsCount
    )
    guard
      let response = try await callList({
        try await client.list_tree_entities(query: query)
      })
    else {
      return Page(items: [], offset: offset, limit: limit)
    }
    let items: [Components.Schemas.TreeEntity] = try decodeResponse(response.toCase()) {
      try $0.json
    }
    return Page(items: items, offset: offset, limit: limit)
  }
}
