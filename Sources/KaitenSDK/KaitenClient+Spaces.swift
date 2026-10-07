import Foundation
import OpenAPIRuntime

// MARK: - Spaces

extension KaitenClient {
  /// Lists spaces visible to the authenticated user, one page at a time.
  ///
  /// - Parameters:
  ///   - limit: Maximum number of spaces to return (1–100). The API returns 100 when omitted.
  ///   - offset: Number of spaces to skip.
  /// - Returns: An array of spaces. Returns an empty array if no spaces are available.
  /// - Throws:
  ///   - ``KaitenError/invalidPaginationRange(offset:limit:)`` if pagination parameters are out of range.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for undocumented HTTP status codes.
  public func listSpaces(
    limit: Int? = nil,
    offset: Int? = nil
  ) async throws(KaitenError) -> [Components.Schemas.Space] {
    try validatePagination(offset: offset ?? 0, limit: limit ?? 100)
    guard
      let response = try await callList({
        try await client.retrieve_list_of_spaces(query: .init(limit: limit, offset: offset))
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Creates a new space.
  ///
  /// - Parameters:
  ///   - title: The space title.
  ///   - externalId: An optional external identifier.
  ///   - parentEntityUid: An optional parent entity UID.
  ///   - sortOrder: An optional sort order.
  /// - Returns: The created space.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for bad request (400), forbidden (403), or other undocumented HTTP status codes.
  public func createSpace(
    title: String,
    externalId: String? = nil,
    parentEntityUid: String? = nil,
    sortOrder: Double? = nil
  ) async throws(KaitenError) -> Components.Schemas.Space {
    let response = try await call {
      try await client.create_space(
        body: .json(
          .init(
            title: title,
            external_id: externalId,
            parent_entity_uid: parentEntityUid,
            sort_order: sortOrder
          )))
    }
    return try decodeResponse(response.toCase()) {
      try $0.json
    }
  }

  /// Gets a space by ID.
  ///
  /// - Parameter id: The space identifier.
  /// - Returns: The space.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the space does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func getSpace(
    id: Int
  ) async throws(KaitenError) -> Components.Schemas.Space {
    let response = try await call {
      try await client.retrieve_space(path: .init(space_id: id))
    }
    return try decodeResponse(
      response.toCase(), notFoundResource: ("space", id)
    ) { try $0.json }
  }

  /// Updates a space.
  ///
  /// - Parameters:
  ///   - id: The space identifier.
  ///   - title: The updated title.
  ///   - externalId: The updated external identifier.
  ///   - sortOrder: The updated sort order.
  ///   - access: The updated access level.
  ///   - parentEntityUid: The updated parent entity UID.
  /// - Returns: The updated space.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the space does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for bad request (400), forbidden (403), or other undocumented HTTP status codes.
  public func updateSpace(
    id: Int,
    title: String? = nil,
    externalId: String? = nil,
    sortOrder: Double? = nil,
    access: String? = nil,
    parentEntityUid: String? = nil
  ) async throws(KaitenError) -> Components.Schemas.Space {
    let response = try await call {
      try await client.update_space(
        path: .init(space_id: id),
        body: .json(
          .init(
            title: title,
            external_id: externalId,
            sort_order: sortOrder,
            access: access,
            parent_entity_uid: parentEntityUid
          )))
    }
    return try decodeResponse(
      response.toCase(), notFoundResource: ("space", id)
    ) { try $0.json }
  }
}
