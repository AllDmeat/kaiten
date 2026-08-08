import Foundation
import OpenAPIRuntime

// MARK: - Space Template Checklists

extension KaitenClient {
  /// Lists all template checklists in a space.
  ///
  /// - Parameter spaceUid: The space UID.
  /// - Returns: An array of template checklists. Returns an empty array if the space has no
  ///   template checklists.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for not found (404) or other
  ///     undocumented HTTP status codes. A 404 is reported as `unexpectedResponse` rather than
  ///     ``KaitenError/notFound(resource:id:)`` because spaces are addressed here by string UID,
  ///     which that case cannot represent.
  public func listSpaceTemplateChecklists(spaceUid: String) async throws(KaitenError)
    -> [Components.Schemas.SpaceTemplateChecklist]
  {
    guard
      let response = try await callList({
        try await client.list_space_template_checklists(path: .init(space_uid: spaceUid))
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Creates a template checklist in a space.
  ///
  /// - Parameters:
  ///   - spaceUid: The space UID.
  ///   - name: The template checklist name. Kaiten accepts 1 to 512 characters.
  ///   - sortOrder: The template checklist position. Must be greater than 0.
  /// - Returns: The created template checklist.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for not found (404) or other
  ///     undocumented HTTP status codes. A 404 is reported as `unexpectedResponse` rather than
  ///     ``KaitenError/notFound(resource:id:)`` because spaces are addressed here by string UID,
  ///     which that case cannot represent.
  public func createSpaceTemplateChecklist(
    spaceUid: String,
    name: String? = nil,
    sortOrder: Double? = nil
  ) async throws(KaitenError) -> Components.Schemas.SpaceTemplateChecklist {
    let response = try await call {
      try await client.create_space_template_checklist(
        path: .init(space_uid: spaceUid),
        body: .json(.init(name: name, sort_order: sortOrder))
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Updates a template checklist.
  ///
  /// - Parameters:
  ///   - spaceUid: The space UID.
  ///   - templateChecklistUid: The template checklist UID.
  ///   - name: The updated template checklist name. Kaiten accepts 1 to 512 characters.
  ///   - sortOrder: The updated template checklist position. Must be greater than 0.
  ///   - newSpaceUid: The `space_uid` request attribute. The documentation does not describe
  ///     its effect.
  /// - Returns: The updated template checklist.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for not found (404) or other
  ///     undocumented HTTP status codes. A 404 is reported as `unexpectedResponse` rather than
  ///     ``KaitenError/notFound(resource:id:)`` because both the space and the template checklist
  ///     are addressed by string UID, which that case cannot represent.
  public func updateSpaceTemplateChecklist(
    spaceUid: String,
    templateChecklistUid: String,
    name: String? = nil,
    sortOrder: Double? = nil,
    newSpaceUid: String? = nil
  ) async throws(KaitenError) -> Components.Schemas.SpaceTemplateChecklist {
    let response = try await call {
      try await client.update_space_template_checklist(
        path: .init(space_uid: spaceUid, template_checklist_uid: templateChecklistUid),
        body: .json(.init(name: name, sort_order: sortOrder, space_uid: newSpaceUid))
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Removes a template checklist from a space.
  ///
  /// - Parameters:
  ///   - spaceUid: The space UID.
  ///   - templateChecklistUid: The template checklist UID.
  /// - Returns: The removal confirmation carrying the deleted template checklist UID.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for not found (404) or other
  ///     undocumented HTTP status codes. A 404 is reported as `unexpectedResponse` rather than
  ///     ``KaitenError/notFound(resource:id:)`` because both the space and the template checklist
  ///     are addressed by string UID, which that case cannot represent.
  public func removeSpaceTemplateChecklist(
    spaceUid: String,
    templateChecklistUid: String
  ) async throws(KaitenError) -> Components.Schemas.RemoveSpaceTemplateChecklistResponse {
    let response = try await call {
      try await client.remove_space_template_checklist(
        path: .init(space_uid: spaceUid, template_checklist_uid: templateChecklistUid)
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }
}
