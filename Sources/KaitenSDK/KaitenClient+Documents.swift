import Foundation
import OpenAPIRuntime

// MARK: - Typed Discriminators

// Document discriminators travel as plain strings (see the comment above the
// document enums in `Enums.swift`). These accessors give the generated
// payloads a typed surface without losing undocumented values.

extension Components.Schemas.Document {
  /// The document access type, or `nil` if the API omitted the field.
  public var documentAccess: DocumentAccess? {
    access.map(DocumentAccess.init(rawValue:))
  }

  /// The document icon type, or `nil` if the API omitted the field or returned JSON `null`.
  public var documentIconType: DocumentIconType? {
    icon_type.map(DocumentIconType.init(rawValue:))
  }
}

extension Components.Schemas.DocumentListItem {
  /// The document access type, or `nil` if the API omitted the field.
  public var documentAccess: DocumentAccess? {
    access.map(DocumentAccess.init(rawValue:))
  }

  /// The document icon type, or `nil` if the API omitted the field or returned JSON `null`.
  public var documentIconType: DocumentIconType? {
    icon_type.map(DocumentIconType.init(rawValue:))
  }
}

extension Components.Schemas.DocumentSearchResult {
  /// The document access type, or `nil` if the API omitted the field.
  public var documentAccess: DocumentAccess? {
    access.map(DocumentAccess.init(rawValue:))
  }

  /// The document icon type, or `nil` if the API omitted the field or returned JSON `null`.
  public var documentIconType: DocumentIconType? {
    icon_type.map(DocumentIconType.init(rawValue:))
  }
}

// MARK: - Documents

extension KaitenClient {
  /// Returns a page of documents in the company.
  ///
  /// Calls `GET /documents` with the default search version (1), which answers with a plain
  /// array of documents. For the version=2 OpenSearch format use
  /// ``searchDocuments(query:condition:fields:startPosition:includeSearchPreview:offset:limit:)``.
  ///
  /// - Parameters:
  ///   - query: Search query string (optional).
  ///   - offset: Number of documents to skip (default `0`).
  ///   - limit: Maximum number of documents to return (default `100`).
  /// - Returns: A ``Page`` of documents. Returns an empty page when no documents match.
  /// - Throws:
  ///   - ``KaitenError/invalidPaginationRange(offset:limit:)`` if pagination parameters are out of range.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for undocumented HTTP status codes.
  public func listDocuments(
    query: String? = nil,
    offset: Int = 0,
    limit: Int = 100
  ) async throws(KaitenError) -> Page<Components.Schemas.DocumentListItem> {
    guard offset >= 0, limit >= 1 else {
      throw .invalidPaginationRange(offset: offset, limit: limit)
    }
    guard
      let response = try await callList({
        try await client.list_documents(
          query: .init(query: query, offset: offset, limit: limit)
        )
      })
    else {
      return Page(items: [], offset: offset, limit: limit)
    }
    let payload = try decodeResponse(response.toCase()) { try $0.json }
    guard let items = payload.value1 else {
      throw .decodingError(
        underlying: DecodingError.dataCorrupted(
          .init(
            codingPath: [],
            debugDescription:
              "GET /documents without version=2 did not answer with an array of documents")))
    }
    return Page(items: items, offset: offset, limit: limit)
  }

  /// Searches documents via OpenSearch (version=2).
  ///
  /// Calls `GET /documents` with `version=2`, which answers with an object carrying `result`
  /// and an opaque `position` cursor. Pass the returned ``Components/Schemas/DocumentSearchResponse/position``
  /// as `startPosition` to fetch the next page.
  ///
  /// - Parameters:
  ///   - query: Search query string (optional).
  ///   - condition: Filter condition (optional).
  ///   - fields: Comma-separated list of fields to search in, e.g. `"data"` (optional).
  ///   - startPosition: Search cursor from the previous response (optional).
  ///   - includeSearchPreview: Include the `preview` object in each search result. Only
  ///     effective together with `fields: "data"` (default `false` on the server).
  ///   - offset: Number of documents to skip (default `0`).
  ///   - limit: Maximum number of documents to return (default `100`).
  /// - Returns: The search response. Returns an empty result list when no documents match.
  /// - Throws:
  ///   - ``KaitenError/invalidPaginationRange(offset:limit:)`` if pagination parameters are out of range.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for undocumented HTTP status codes.
  public func searchDocuments(
    query: String? = nil,
    condition: Int? = nil,
    fields: String? = nil,
    startPosition: String? = nil,
    includeSearchPreview: Bool? = nil,
    offset: Int = 0,
    limit: Int = 100
  ) async throws(KaitenError) -> Components.Schemas.DocumentSearchResponse {
    guard offset >= 0, limit >= 1 else {
      throw .invalidPaginationRange(offset: offset, limit: limit)
    }
    guard
      let response = try await callList({
        try await client.list_documents(
          query: .init(
            query: query,
            offset: offset,
            limit: limit,
            version: 2,
            condition: condition,
            fields: fields,
            start_position: startPosition,
            include_search_preview: includeSearchPreview
          )
        )
      })
    else {
      return .init(result: [], position: nil)
    }
    let payload = try decodeResponse(response.toCase()) { try $0.json }
    guard let searchResponse = payload.value2 else {
      throw .decodingError(
        underlying: DecodingError.dataCorrupted(
          .init(
            codingPath: [],
            debugDescription:
              "GET /documents with version=2 did not answer with a result/position object")))
    }
    return searchResponse
  }

  /// Returns a single document, including its content.
  ///
  /// - Parameter uid: The document UID.
  /// - Returns: The document. Its `data` field carries the ProseMirror content — live
  ///   responses return it as a JSON-encoded string even though the documentation declares
  ///   an object, so both shapes decode.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403), not found
  ///     (404) or other undocumented HTTP status codes. A 404 is reported as
  ///     `unexpectedResponse` rather than ``KaitenError/notFound(resource:id:)`` because
  ///     documents are addressed by string UID, which that case cannot represent.
  public func getDocument(uid: String) async throws(KaitenError) -> Components.Schemas.Document {
    let response = try await call {
      try await client.get_document(path: .init(document_uid: uid))
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Creates a document.
  ///
  /// - Parameters:
  ///   - sortOrder: Document sort order. Must be greater than 0.
  ///   - title: Title of the document (up to 256 characters).
  ///   - parentEntityUid: Parent tree entity UID.
  ///   - forEveryoneAccessRoleId: Role id for everyone access.
  ///   - cloneUid: UID of a document to copy.
  ///   - cloneVersion: Version of the document to copy.
  ///   - key: Unique key for the document, used in API and web interface. Must be unique
  ///     across the entire company.
  /// - Returns: The created document.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for validation errors (400),
  ///     unsupported tariff (402), forbidden (403), a key conflict (409) or other
  ///     undocumented HTTP status codes.
  public func createDocument(
    sortOrder: Double,
    title: String? = nil,
    parentEntityUid: String? = nil,
    forEveryoneAccessRoleId: String? = nil,
    cloneUid: String? = nil,
    cloneVersion: Double? = nil,
    key: String? = nil
  ) async throws(KaitenError) -> Components.Schemas.Document {
    let response = try await call {
      try await client.create_document(
        body: .json(
          .init(
            title: title,
            sort_order: sortOrder,
            parent_entity_uid: parentEntityUid,
            for_everyone_access_role_id: forEveryoneAccessRoleId,
            clone_uid: cloneUid,
            clone_version: cloneVersion,
            key: key
          ))
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Updates a document.
  ///
  /// - Parameters:
  ///   - uid: The document UID.
  ///   - title: Updated title (up to 256 characters).
  ///   - sortOrder: Updated sort order. Must be greater than 0.
  ///   - publishDate: Publication date in ISO 8601 format.
  ///   - data: Document content in ProseMirror JSON format.
  ///   - access: Document access type.
  ///   - parentEntityUid: Parent tree entity UID.
  ///   - forEveryoneAccessRoleId: Role id for everyone access.
  ///   - isPublic: Whether the document is publicly available (legacy field).
  ///   - redirectUrl: Redirect URL.
  ///   - hiddenOnPublicSite: Whether the document is hidden on the public site.
  ///   - settings: Document appearance settings. The server merges shallowly: only the keys
  ///     sent are changed, other existing settings are preserved.
  ///   - backupVersion: Document version to restore.
  ///   - publishedVersion: Version to publish on the public site — a number, or the string
  ///     `"current"` to publish the current version.
  ///   - key: Unique key for the document. Must be unique across the entire company.
  ///   - iconType: Icon type.
  ///   - iconValue: Icon value — an emoji character or a material icon name (up to 100
  ///     characters).
  ///   - iconColor: Icon color index (1–17).
  ///   - notificationPeriodStart: Notification period start date.
  ///   - notificationPeriodEnd: Notification period end date.
  ///   - slug: Human-readable URL slug — lowercase latin letters, digits and hyphens only.
  ///     Must be unique within the public site subtree.
  /// - Returns: The updated document.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for validation errors (400),
  ///     unsupported tariff (402), forbidden (403), not found (404), a key conflict (409) or
  ///     other undocumented HTTP status codes. A 404 is reported as `unexpectedResponse`
  ///     rather than ``KaitenError/notFound(resource:id:)`` because documents are addressed
  ///     by string UID, which that case cannot represent.
  public func updateDocument(
    uid: String,
    title: String? = nil,
    sortOrder: Double? = nil,
    publishDate: String? = nil,
    data: Components.Schemas.UpdateDocumentRequest.dataPayload? = nil,
    access: DocumentAccess? = nil,
    parentEntityUid: String? = nil,
    forEveryoneAccessRoleId: String? = nil,
    isPublic: Bool? = nil,
    redirectUrl: String? = nil,
    hiddenOnPublicSite: Bool? = nil,
    settings: Components.Schemas.DocumentSettings? = nil,
    backupVersion: Double? = nil,
    publishedVersion: Components.Schemas.UpdateDocumentRequest.published_versionPayload? = nil,
    key: String? = nil,
    iconType: DocumentIconType? = nil,
    iconValue: String? = nil,
    iconColor: Int? = nil,
    notificationPeriodStart: String? = nil,
    notificationPeriodEnd: String? = nil,
    slug: String? = nil
  ) async throws(KaitenError) -> Components.Schemas.Document {
    let response = try await call {
      try await client.update_document(
        path: .init(document_uid: uid),
        body: .json(
          .init(
            title: title,
            sort_order: sortOrder,
            publish_date: publishDate,
            data: data,
            access: access?.rawValue,
            parent_entity_uid: parentEntityUid,
            for_everyone_access_role_id: forEveryoneAccessRoleId,
            _public: isPublic,
            redirect_url: redirectUrl,
            hidden_on_public_site: hiddenOnPublicSite,
            settings: settings,
            backup_version: backupVersion,
            published_version: publishedVersion,
            key: key,
            icon_type: iconType?.rawValue,
            icon_value: iconValue,
            icon_color: iconColor,
            notification_period_start: notificationPeriodStart,
            notification_period_end: notificationPeriodEnd,
            slug: slug
          ))
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Removes a document.
  ///
  /// A document that still has child tree entities cannot be removed — the API answers
  /// HTTP 400 until they are removed or moved.
  ///
  /// - Parameter uid: The document UID.
  /// - Returns: The removed document, with `archived` set to `true`.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for a document with child tree
  ///     entities (400), forbidden (403), not found (404) or other undocumented HTTP status
  ///     codes. A 404 is reported as `unexpectedResponse` rather than
  ///     ``KaitenError/notFound(resource:id:)`` because documents are addressed by string
  ///     UID, which that case cannot represent.
  public func deleteDocument(uid: String) async throws(KaitenError) -> Components.Schemas.Document {
    let response = try await call {
      try await client.delete_document(path: .init(document_uid: uid))
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }
}
