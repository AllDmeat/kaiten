import Foundation
import OpenAPIRuntime

// MARK: - Checklist Items

extension KaitenClient {
  /// Adds an item to a checklist addressed by its own identifier, without card context.
  ///
  /// - Parameters:
  ///   - checklistId: The checklist identifier.
  ///   - text: Item content (1–4096 characters).
  ///   - sortOrder: Position (must be > 0).
  ///   - checked: Checked state.
  ///   - dueDate: Due date in YYYY-MM-DD format.
  ///   - responsibleId: Responsible user ID.
  /// - Returns: The created checklist item.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the checklist does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for validation errors (400), forbidden (403), or other undocumented HTTP status codes.
  public func createChecklistItem(
    checklistId: Int,
    text: String,
    sortOrder: Double? = nil,
    checked: Bool? = nil,
    dueDate: String? = nil,
    responsibleId: Int? = nil
  ) async throws(KaitenError) -> Components.Schemas.ChecklistItem {
    let response = try await call {
      try await client.add_item_to_checklist(
        path: .init(checklist_id: checklistId),
        body: .json(
          .init(
            text: text,
            sort_order: sortOrder,
            checked: checked,
            due_date: dueDate,
            responsible_id: responsibleId
          ))
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("checklist", checklistId)) {
      try $0.json
    }
  }

  /// Updates a checklist item addressed by its checklist's identifier, without card context.
  ///
  /// All body parameters are optional — only provided values are changed.
  ///
  /// - Parameters:
  ///   - checklistId: The checklist identifier.
  ///   - itemId: The checklist item identifier.
  ///   - text: Item content (max 4096 characters, pass `nil` to clear).
  ///   - sortOrder: Position (must be > 0).
  ///   - moveToChecklistId: Move item to another checklist.
  ///   - checked: Checked state.
  ///   - dueDate: Due date in YYYY-MM-DD format (pass `nil` to clear).
  ///   - responsibleId: Responsible user ID (pass `nil` to clear).
  /// - Returns: The updated checklist item.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the checklist or item does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for validation errors (400), forbidden (403), or other undocumented HTTP status codes.
  public func updateChecklistItem(
    checklistId: Int,
    itemId: Int,
    text: String? = nil,
    sortOrder: Double? = nil,
    moveToChecklistId: Int? = nil,
    checked: Bool? = nil,
    dueDate: String? = nil,
    responsibleId: Int? = nil
  ) async throws(KaitenError) -> Components.Schemas.ChecklistItem {
    let body = Components.Schemas.UpdateChecklistItemRequest(
      text: text,
      sort_order: sortOrder,
      checklist_id: moveToChecklistId,
      checked: checked,
      due_date: dueDate,
      responsible_id: responsibleId
    )
    let response = try await call {
      try await client.update_item_in_checklist(
        path: .init(checklist_id: checklistId, id: itemId),
        body: .json(body)
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("checklistItem", itemId)) {
      try $0.json
    }
  }

  /// Removes a checklist item addressed by its checklist's identifier, without card context.
  ///
  /// - Parameters:
  ///   - checklistId: The checklist identifier.
  ///   - itemId: The checklist item identifier.
  /// - Returns: The deleted item ID.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the checklist or item does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func removeChecklistItem(
    checklistId: Int,
    itemId: Int
  ) async throws(KaitenError) -> Int {
    let response = try await call {
      try await client.remove_item_from_checklist(
        path: .init(checklist_id: checklistId, id: itemId)
      )
    }
    let body = try decodeResponse(response.toCase(), notFoundResource: ("checklistItem", itemId)) {
      try $0.json
    }
    return body.id
  }
}
