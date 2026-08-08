import Foundation
import OpenAPIRuntime

// MARK: - Checklists

extension KaitenClient {
  /// Lists the cards that use a checklist.
  ///
  /// - Parameters:
  ///   - checklistId: The checklist identifier.
  ///   - onlySharedCards: Required by the API; requests without it are rejected with 400. No
  ///     filtering effect has been observed — a card that is neither public nor shared is
  ///     returned with either value.
  /// - Returns: An array of cards that use the checklist. Returns an empty array if the API
  ///   responds with an empty body.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the checklist does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for validation error (400),
  ///     forbidden (403) or other undocumented HTTP status codes.
  public func listCardsWithChecklist(
    checklistId: Int,
    onlySharedCards: Bool
  ) async throws(KaitenError) -> [Components.Schemas.ChecklistCard] {
    guard
      let response = try await callList({
        try await client.retrieve_cards_with_checklist(
          path: .init(id: checklistId),
          query: .init(only_shared_cards: onlySharedCards)
        )
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("checklist", checklistId)) {
      try $0.json
    }
  }

  /// Creates a checklist on a card.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - name: Checklist name (required).
  ///   - sortOrder: Position (optional).
  /// - Returns: The created checklist.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func createChecklist(cardId: Int, name: String, sortOrder: Double? = nil)
    async throws(KaitenError) -> Components.Schemas.Checklist
  {
    let response = try await call {
      try await client.create_checklist(
        path: .init(card_id: cardId),
        body: .json(.init(name: name, sort_order: sortOrder))
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("card", cardId)) {
      try $0.json
    }
  }

  /// Fetches a single checklist by its identifier.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - checklistId: The checklist identifier.
  /// - Returns: The checklist object.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card or checklist does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func getChecklist(cardId: Int, checklistId: Int) async throws(KaitenError)
    -> Components.Schemas.Checklist
  {
    let response = try await call {
      try await client.get_checklist(path: .init(card_id: cardId, id: checklistId))
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("checklist", checklistId)) {
      try $0.json
    }
  }

  /// Removes a checklist from a card.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - checklistId: The checklist identifier.
  /// - Returns: The deleted checklist ID.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card or checklist does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func removeChecklist(cardId: Int, checklistId: Int) async throws(KaitenError) -> Int {
    let response = try await call {
      try await client.remove_checklist(path: .init(card_id: cardId, id: checklistId))
    }
    let result: Components.Schemas.DeletedChecklistResponse = try decodeResponse(
      response.toCase(), notFoundResource: ("checklist", checklistId)
    ) { try $0.json }
    return result.id
  }

  /// Updates a checklist.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - checklistId: The checklist identifier.
  ///   - name: New checklist name (1–1024 characters).
  ///   - sortOrder: New position.
  ///   - moveToCardId: Move checklist to another card.
  /// - Returns: The updated checklist object.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card or checklist does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func updateChecklist(
    cardId: Int,
    checklistId: Int,
    name: String? = nil,
    sortOrder: Double? = nil,
    moveToCardId: Int? = nil
  ) async throws(KaitenError) -> Components.Schemas.Checklist {
    let response = try await call {
      try await client.update_checklist(
        path: .init(card_id: cardId, id: checklistId),
        body: .json(
          .init(
            name: name,
            sort_order: sortOrder,
            card_id: moveToCardId
          ))
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("checklist", checklistId)) {
      try $0.json
    }
  }

  /// Creates a new checklist item.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - checklistId: The checklist identifier.
  ///   - text: Item content (1–4096 characters).
  ///   - sortOrder: Position (must be > 0).
  ///   - checked: Checked state.
  ///   - dueDate: Due date in YYYY-MM-DD format.
  ///   - responsibleId: Responsible user ID.
  /// - Returns: The created checklist item.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card or checklist does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func createChecklistItem(
    cardId: Int,
    checklistId: Int,
    text: String,
    sortOrder: Double? = nil,
    checked: Bool? = nil,
    dueDate: String? = nil,
    responsibleId: Int? = nil
  ) async throws(KaitenError) -> Components.Schemas.ChecklistItem {
    let response = try await call {
      try await client.create_checklist_item(
        path: .init(card_id: cardId, checklist_id: checklistId),
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

  /// Updates a checklist item on a card.
  ///
  /// All body parameters are optional — only provided values are changed.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
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
  ///   - ``KaitenError/notFound(resource:id:)`` if the card, checklist, or item does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func updateChecklistItem(
    cardId: Int,
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
      try await client.update_checklist_item(
        path: .init(card_id: cardId, checklist_id: checklistId, id: itemId),
        body: .json(body)
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("checklistItem", itemId)) {
      try $0.json
    }
  }

  /// Removes a checklist item.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - checklistId: The checklist identifier.
  ///   - itemId: The checklist item identifier.
  /// - Returns: The deleted item ID.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card, checklist, or item does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func removeChecklistItem(
    cardId: Int,
    checklistId: Int,
    itemId: Int
  ) async throws(KaitenError) -> Int {
    let response = try await call {
      try await client.remove_checklist_item(
        path: .init(card_id: cardId, checklist_id: checklistId, id: itemId)
      )
    }
    let body = try decodeResponse(response.toCase(), notFoundResource: ("checklistItem", itemId)) {
      try $0.json
    }
    return body.id
  }
}
