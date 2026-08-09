import Foundation
import OpenAPIRuntime

// MARK: - Typed Discriminators

// The document group access discriminator travels as a plain string (see the
// comment above `DocumentGroupAccess` in `Enums.swift`). This accessor gives the
// generated payload a typed surface without losing undocumented values.

extension Components.Schemas.DocumentGroup {
  /// The document group access type, or `nil` if the API omitted the field.
  public var documentGroupAccess: DocumentGroupAccess? {
    access.map(DocumentGroupAccess.init(rawValue:))
  }
}

/// The document group list endpoint answered with the shape belonging to the
/// other `version` of the request — an object where an array was expected, or
/// the other way around.
private struct UnexpectedDocumentGroupListShape: Error {}

// MARK: - Document Groups

extension KaitenClient {
  /// Lists document groups in the company.
  ///
  /// Calls the list endpoint without a `version`, which returns a plain array.
  /// Use ``searchDocumentGroups(query:condition:startPosition:role:offset:limit:)``
  /// for the `version=2` cursor-based search format.
  ///
  /// - Parameters:
  ///   - query: Search query string.
  ///   - role: Filter by minimum user role: 1 — reader, 2 — writer, 3 — admin.
  ///   - offset: Number of records to skip (default `0` on the API side).
  ///   - limit: Maximum number of records to return (default `100` on the API side).
  /// - Returns: An array of document groups. Returns an empty array when nothing matches.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for undocumented HTTP status codes.
  public func listDocumentGroups(
    query: String? = nil,
    role: Int? = nil,
    offset: Int? = nil,
    limit: Int? = nil
  ) async throws(KaitenError) -> [Components.Schemas.DocumentGroup] {
    guard
      let response = try await callList({
        try await client.list_document_groups(
          query: .init(query: query, offset: offset, limit: limit, role: role))
      })
    else {
      return []
    }
    let payload = try decodeResponse(response.toCase()) { try $0.json }
    guard let groups = payload.value1 else {
      throw .decodingError(underlying: UnexpectedDocumentGroupListShape())
    }
    return groups
  }

  /// Searches document groups via OpenSearch (the `version=2` list format).
  ///
  /// The response carries the matching groups in `result` and an opaque cursor
  /// in `position`; pass that cursor as `startPosition` to fetch the next page.
  ///
  /// - Parameters:
  ///   - query: Search query string.
  ///   - condition: Filter condition.
  ///   - startPosition: Search cursor — the `position` value from the previous response.
  ///   - role: Filter by minimum user role: 1 — reader, 2 — writer, 3 — admin.
  ///   - offset: Number of records to skip (default `0` on the API side).
  ///   - limit: Maximum number of records to return (default `100` on the API side).
  /// - Returns: The search response with matching document groups and the pagination cursor.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for undocumented HTTP status codes.
  public func searchDocumentGroups(
    query: String? = nil,
    condition: Int? = nil,
    startPosition: String? = nil,
    role: Int? = nil,
    offset: Int? = nil,
    limit: Int? = nil
  ) async throws(KaitenError) -> Components.Schemas.DocumentGroupSearchResponse {
    let response = try await call {
      try await client.list_document_groups(
        query: .init(
          query: query,
          offset: offset,
          limit: limit,
          version: 2,
          condition: condition,
          start_position: startPosition,
          role: role))
    }
    let payload = try decodeResponse(response.toCase()) { try $0.json }
    guard let result = payload.value2 else {
      throw .decodingError(underlying: UnexpectedDocumentGroupListShape())
    }
    return result
  }

  /// Retrieves a document group.
  ///
  /// - Parameters:
  ///   - uid: The document group UID.
  ///   - relations: Relations to include in the response. The API accepts
  ///     `documents`, `groups`, `parent` and `author`; the matching response
  ///     fields stay `nil` when their relation is not requested.
  /// - Returns: The document group.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403), not found (404)
  ///     or other undocumented HTTP status codes. A 404 is reported as `unexpectedResponse`
  ///     rather than ``KaitenError/notFound(resource:id:)`` because document groups are
  ///     addressed by string UID.
  public func getDocumentGroup(
    uid: String,
    relations: [String]? = nil
  ) async throws(KaitenError) -> Components.Schemas.DocumentGroup {
    let response = try await call {
      try await client.get_document_group(
        path: .init(document_group_uid: uid),
        query: .init(relations: relations.map { $0.joined(separator: ",") }))
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Creates a document group.
  ///
  /// - Parameters:
  ///   - title: The document group title (1–256 characters).
  ///   - parentEntityUid: The parent tree entity UID.
  ///   - forEveryoneAccessRoleId: The role id for everyone access.
  ///   - sortOrder: The sort order (must be greater than 0).
  ///   - key: A unique document group key within the company.
  /// - Returns: The created document group.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for validation errors (400),
  ///     unsupported tariff (402), forbidden (403), key conflicts (409) or other undocumented
  ///     HTTP status codes.
  public func createDocumentGroup(
    title: String,
    parentEntityUid: String? = nil,
    forEveryoneAccessRoleId: String? = nil,
    sortOrder: Double? = nil,
    key: String? = nil
  ) async throws(KaitenError) -> Components.Schemas.DocumentGroup {
    let response = try await call {
      try await client.create_document_group(
        body: .json(
          .init(
            title: title,
            parent_entity_uid: parentEntityUid,
            for_everyone_access_role_id: forEveryoneAccessRoleId,
            sort_order: sortOrder,
            key: key
          ))
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Updates a document group.
  ///
  /// - Parameters:
  ///   - uid: The document group UID.
  ///   - title: The updated title (1–256 characters).
  ///   - parentEntityUid: The parent tree entity UID. Moves the group in the tree.
  ///   - sortOrder: The sort order (must be greater than 0).
  ///   - access: The access type.
  ///   - forEveryoneAccessRoleId: The role id for everyone access.
  ///   - hostname: A custom hostname for the public site.
  ///   - redirectUrl: The redirect URL.
  ///   - key: A unique document group key within the company. Cannot be changed once set.
  ///   - iconType: The icon type.
  ///   - iconValue: The icon value (icon name for the `material_icon` type).
  ///   - iconColor: The icon color.
  ///   - hiddenOnPublicSite: Whether the group is hidden on the public site.
  ///   - newsFeed: Whether the group is marked as a news feed. Requires a hostname on
  ///     this folder or one of its parents.
  ///   - indexDocumentUid: UID of the document used as the home page for this folder.
  ///     Requires a hostname on this folder.
  /// - Returns: The updated document group.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for validation errors (400),
  ///     unsupported tariff (402), forbidden (403), not found (404), key or hostname conflicts
  ///     (409) or other undocumented HTTP status codes. A 404 is reported as
  ///     `unexpectedResponse` rather than ``KaitenError/notFound(resource:id:)`` because
  ///     document groups are addressed by string UID.
  public func updateDocumentGroup(
    uid: String,
    title: String? = nil,
    parentEntityUid: String? = nil,
    sortOrder: Double? = nil,
    access: DocumentGroupAccess? = nil,
    forEveryoneAccessRoleId: String? = nil,
    hostname: String? = nil,
    redirectUrl: String? = nil,
    key: String? = nil,
    iconType: String? = nil,
    iconValue: String? = nil,
    iconColor: Int? = nil,
    hiddenOnPublicSite: Bool? = nil,
    newsFeed: Bool? = nil,
    indexDocumentUid: String? = nil
  ) async throws(KaitenError) -> Components.Schemas.DocumentGroup {
    let response = try await call {
      try await client.update_document_group(
        path: .init(document_group_uid: uid),
        body: .json(
          .init(
            title: title,
            parent_entity_uid: parentEntityUid,
            sort_order: sortOrder,
            access: access?.rawValue,
            for_everyone_access_role_id: forEveryoneAccessRoleId,
            hostname: hostname,
            redirect_url: redirectUrl,
            key: key,
            icon_type: iconType,
            icon_value: iconValue,
            icon_color: iconColor,
            hidden_on_public_site: hiddenOnPublicSite,
            news_feed: newsFeed,
            index_document_uid: indexDocumentUid
          ))
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Removes a document group.
  ///
  /// The endpoint answers HTTP 400 while the group still has child tree
  /// entities — remove or move them first.
  ///
  /// - Parameter uid: The document group UID.
  /// - Returns: The removed document group stub, with `archived` set to `true`.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for child entities still present
  ///     (400), forbidden (403), not found (404) or other undocumented HTTP status codes.
  ///     A 404 is reported as `unexpectedResponse` rather than
  ///     ``KaitenError/notFound(resource:id:)`` because document groups are addressed by
  ///     string UID.
  public func deleteDocumentGroup(
    uid: String
  ) async throws(KaitenError) -> Components.Schemas.RemovedDocumentGroupResponse {
    let response = try await call {
      try await client.delete_document_group(path: .init(document_group_uid: uid))
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }
}
