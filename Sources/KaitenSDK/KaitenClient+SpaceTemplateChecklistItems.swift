import Foundation
import OpenAPIRuntime

// MARK: - Space Template Checklist Items

extension KaitenClient {
  /// Creates an item in a space template checklist.
  ///
  /// - Parameters:
  ///   - spaceUid: The space UID.
  ///   - templateChecklistUid: The template checklist UID.
  ///   - text: Content of the checklist item (1–4096 characters).
  ///   - sortOrder: Position (must be > 0).
  /// - Returns: The created template checklist item.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for not found (404) or other
  ///     undocumented HTTP status codes. A 404 is reported as `unexpectedResponse` rather than
  ///     ``KaitenError/notFound(resource:id:)`` because the space and the template checklist are
  ///     addressed by string UIDs and the response does not say which one is missing.
  public func createSpaceTemplateChecklistItem(
    spaceUid: String,
    templateChecklistUid: String,
    text: String,
    sortOrder: Double? = nil
  ) async throws(KaitenError) -> Components.Schemas.SpaceTemplateChecklistItem {
    let response = try await call {
      try await client.create_space_template_checklist_item(
        path: .init(space_uid: spaceUid, template_checklist_uid: templateChecklistUid),
        body: .json(.init(text: text, sort_order: sortOrder))
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Updates an item in a space template checklist.
  ///
  /// All body parameters are optional — only provided values are changed.
  ///
  /// - Parameters:
  ///   - spaceUid: The space UID.
  ///   - templateChecklistUid: The template checklist UID.
  ///   - itemUid: The template checklist item UID.
  ///   - text: Content of the checklist item (1–4096 characters).
  ///   - sortOrder: Position (must be > 0).
  /// - Returns: The updated template checklist item.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for not found (404) or other
  ///     undocumented HTTP status codes. A 404 is reported as `unexpectedResponse` rather than
  ///     ``KaitenError/notFound(resource:id:)`` because the space, the template checklist and the
  ///     item are addressed by string UIDs and the response does not say which one is missing.
  public func updateSpaceTemplateChecklistItem(
    spaceUid: String,
    templateChecklistUid: String,
    itemUid: String,
    text: String? = nil,
    sortOrder: Double? = nil
  ) async throws(KaitenError) -> Components.Schemas.SpaceTemplateChecklistItem {
    let response = try await call {
      try await client.update_space_template_checklist_item(
        path: .init(
          space_uid: spaceUid,
          template_checklist_uid: templateChecklistUid,
          item_uid: itemUid
        ),
        body: .json(.init(text: text, sort_order: sortOrder))
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Removes an item from a space template checklist.
  ///
  /// - Parameters:
  ///   - spaceUid: The space UID.
  ///   - templateChecklistUid: The template checklist UID.
  ///   - itemUid: The template checklist item UID.
  /// - Returns: The deleted template checklist item UID.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for not found (404) or other
  ///     undocumented HTTP status codes. A 404 is reported as `unexpectedResponse` rather than
  ///     ``KaitenError/notFound(resource:id:)`` because the space, the template checklist and the
  ///     item are addressed by string UIDs and the response does not say which one is missing.
  public func removeSpaceTemplateChecklistItem(
    spaceUid: String,
    templateChecklistUid: String,
    itemUid: String
  ) async throws(KaitenError) -> String {
    let response = try await call {
      try await client.remove_space_template_checklist_item(
        path: .init(
          space_uid: spaceUid,
          template_checklist_uid: templateChecklistUid,
          item_uid: itemUid
        )
      )
    }
    let body = try decodeResponse(response.toCase()) { try $0.json }
    return body.uid
  }
}
