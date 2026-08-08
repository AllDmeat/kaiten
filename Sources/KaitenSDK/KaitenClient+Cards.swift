import Foundation
import OpenAPIRuntime

// MARK: - Typed Sorting Parameters

// Batch-update sorting discriminators travel as plain strings (see the comment
// above the automation enums in `Enums.swift`). These accessors and the
// initializer give the generated payload a typed surface without losing
// undocumented values.

extension Components.Schemas.BatchUpdateCardsOrderBy {
  /// The field cards are sorted by, or `nil` if the field is not set.
  public var orderField: BatchUpdateOrderField? {
    field_type.map(BatchUpdateOrderField.init(rawValue:))
  }

  /// The sorting direction, or `nil` if the field is not set.
  public var sortDirection: SortDirection? {
    direction.map(SortDirection.init(rawValue:))
  }

  /// Creates sorting parameters from typed values.
  ///
  /// - Parameters:
  ///   - field: The field type to sort by.
  ///   - id: The custom property identifier to sort by, required when `field`
  ///     is ``BatchUpdateOrderField/customProperty``.
  ///   - direction: The sorting direction.
  public init(field: BatchUpdateOrderField, id: Int? = nil, direction: SortDirection) {
    self.init(field_type: field.rawValue, id: id, direction: direction.rawValue)
  }
}

// MARK: - Cards

extension KaitenClient {
  /// Returns a page of cards, optionally filtered.
  ///
  /// - Parameters:
  ///   - boardId: Filter by board identifier (optional).
  ///   - columnId: Filter by column identifier (optional).
  ///   - laneId: Filter by lane identifier (optional).
  ///   - offset: Number of cards to skip (default `0`).
  ///   - limit: Maximum number of cards to return (default `100`).
  ///   - filter: Optional ``CardFilter`` with additional query parameters.
  /// - Returns: A ``Page`` of cards. Returns an empty page when no cards match.
  /// - Throws:
  ///   - ``KaitenError/invalidPaginationRange(offset:limit:)`` if pagination parameters are out of range.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for undocumented HTTP status codes.
  public func listCards(
    boardId: Int? = nil, columnId: Int? = nil, laneId: Int? = nil, offset: Int = 0,
    limit: Int = 100, filter: KaitenSDK.CardFilter? = nil
  ) async throws(KaitenError) -> Page<Components.Schemas.Card> {
    try validatePagination(offset: offset, limit: limit)
    let f = filter
    let queryParams = Operations.get_cards.Input.Query(
      board_id: boardId,
      column_id: columnId,
      lane_id: laneId,
      offset: offset,
      limit: limit,
      created_before: f?.createdBefore,
      created_after: f?.createdAfter,
      updated_before: f?.updatedBefore,
      updated_after: f?.updatedAfter,
      first_moved_in_progress_after: f?.firstMovedInProgressAfter,
      first_moved_in_progress_before: f?.firstMovedInProgressBefore,
      last_moved_to_done_at_after: f?.lastMovedToDoneAtAfter,
      last_moved_to_done_at_before: f?.lastMovedToDoneAtBefore,
      due_date_after: f?.dueDateAfter,
      due_date_before: f?.dueDateBefore,
      query: f?.query,
      search_fields: f?.searchFields,
      tag: f?.tag,
      tag_ids: f?.tagIds,
      type_id: f?.typeId,
      type_ids: f?.typeIds,
      member_ids: f?.memberIds,
      owner_id: f?.ownerId,
      owner_ids: f?.ownerIds,
      responsible_id: f?.responsibleId,
      responsible_ids: f?.responsibleIds,
      column_ids: f?.columnIds,
      space_id: f?.spaceId,
      external_id: f?.externalId,
      organizations_ids: f?.organizationsIds,
      exclude_board_ids: f?.excludeBoardIds,
      exclude_lane_ids: f?.excludeLaneIds,
      exclude_column_ids: f?.excludeColumnIds,
      exclude_owner_ids: f?.excludeOwnerIds,
      exclude_card_ids: f?.excludeCardIds,
      condition: f?.condition?.rawValue,
      states: f?.states.map { $0.map { String($0.rawValue) }.joined(separator: ",") },
      archived: f?.archived,
      asap: f?.asap,
      overdue: f?.overdue,
      done_on_time: f?.doneOnTime,
      with_due_date: f?.withDueDate,
      is_request: f?.isRequest,
      order_by: f?.orderBy,
      order_direction: f?.orderDirection,
      order_space_id: f?.orderSpaceId,
      additional_card_fields: f?.additionalCardFields
    )
    guard let response = try await callList({ try await client.get_cards(query: queryParams) })
    else {
      return Page(items: [], offset: offset, limit: limit)
    }
    let items: [Components.Schemas.Card] = try decodeResponse(response.toCase()) { try $0.json }
    return Page(items: items, offset: offset, limit: limit)
  }

  /// Fetches a single card by its identifier.
  ///
  /// - Parameter id: The card identifier.
  /// - Returns: The full card object with all fields including custom properties.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for undocumented HTTP status codes.
  public func getCard(id: Int) async throws(KaitenError) -> Components.Schemas.Card {
    let response = try await call { try await client.get_card(path: .init(card_id: id)) }
    return try decodeResponse(response.toCase(), notFoundResource: ("card", id)) { try $0.json }
  }

  /// Creates a new card on a board.
  ///
  /// - Parameter options: Creation options. See ``CardCreateOptions``.
  /// - Returns: The created card.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for bad request (400), forbidden (403), or other undocumented HTTP status codes.
  public func createCard(
    _ options: CardCreateOptions
  ) async throws(KaitenError) -> Components.Schemas.Card {
    let body = Components.Schemas.CreateCardRequest(
      title: options.title,
      board_id: options.boardId,
      column_id: options.columnId,
      lane_id: options.laneId,
      description: options.description,
      asap: options.asap,
      due_date: options.dueDate,
      due_date_time_present: options.dueDateTimePresent,
      sort_order: options.sortOrder,
      expires_later: options.expiresLater,
      size_text: options.sizeText,
      owner_id: options.ownerId,
      responsible_id: options.responsibleId,
      owner_email: options.ownerEmail,
      position: options.position?.rawValue,
      type_id: options.typeId,
      external_id: options.externalId,
      text_format_type_id: options.textFormatTypeId?.rawValue,
      properties: options.properties
    )
    let response = try await call {
      try await client.create_card(body: .json(body))
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Updates a card by its identifier.
  ///
  /// All fields in ``CardUpdateOptions`` are optional — only set values are changed.
  ///
  /// - Parameters:
  ///   - id: The card identifier.
  ///   - options: Update options. See ``CardUpdateOptions``.
  /// - Returns: The updated card.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for bad request (400), forbidden (403), or other undocumented HTTP status codes.
  public func updateCard(
    id: Int,
    _ options: CardUpdateOptions
  ) async throws(KaitenError) -> Components.Schemas.Card {
    let body = Components.Schemas.UpdateCardRequest(
      title: options.title,
      description: options.description,
      asap: options.asap,
      due_date: options.dueDate,
      due_date_time_present: options.dueDateTimePresent,
      sort_order: options.sortOrder,
      expires_later: options.expiresLater,
      size_text: options.sizeText,
      board_id: options.boardId,
      column_id: options.columnId,
      lane_id: options.laneId,
      owner_id: options.ownerId,
      type_id: options.typeId,
      service_id: options.serviceId,
      blocked: options.blocked,
      condition: options.condition?.rawValue,
      external_id: options.externalId,
      text_format_type_id: options.textFormatTypeId?.rawValue,
      sd_new_comment: options.sdNewComment,
      owner_email: options.ownerEmail,
      prev_card_id: options.prevCardId,
      estimate_workload: options.estimateWorkload,
      // Map String?? → ExplicitNullString?:
      //   nil          → nil          (field omitted from JSON, server leaves value unchanged)
      //   .some(nil)   → .some(.null) (field sent as JSON null, server clears the value)
      //   .some("x")   → .some(.value("x")) (field sent as string, server sets the value)
      planned_start: options.plannedStart.map { $0.map(ExplicitNullString.value) ?? .null },
      planned_end: options.plannedEnd.map { $0.map(ExplicitNullString.value) ?? .null },
      properties: options.properties
    )
    let response = try await call {
      try await client.update_card(
        path: .init(card_id: id),
        body: .json(body)
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("card", id)) { try $0.json }
  }

  /// Updates multiple cards selected by criteria.
  ///
  /// The update runs in the background — the method returns the identifier of the
  /// background job, not the updated cards. The Kaiten documentation requires at
  /// least one criteria parameter together with `attributes`, or `columnId` +
  /// `laneId` together with `orderBy`.
  ///
  /// - Parameters:
  ///   - boardId: Criteria board identifier.
  ///   - columnId: Criteria column identifier.
  ///   - laneId: Criteria lane identifier.
  ///   - ownerId: Criteria owner identifier.
  ///   - typeId: Criteria card type identifier.
  ///   - condition: Criteria card condition (live or archived).
  ///   - attributes: Attributes to change on every card matching the criteria.
  ///   - orderBy: Sorting parameters for repositioning cards inside a cell.
  /// - Returns: The accepted background job with its UUID.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for bad request (400), unsupported
  ///     tariff (402), forbidden (403), not found (404) or other undocumented HTTP status codes.
  ///     A 404 is reported as `unexpectedResponse` rather than
  ///     ``KaitenError/notFound(resource:id:)`` because cards are selected by criteria and the
  ///     response does not say which referenced entity is missing.
  public func batchUpdateCards(
    boardId: Int? = nil,
    columnId: Int? = nil,
    laneId: Int? = nil,
    ownerId: Int? = nil,
    typeId: Int? = nil,
    condition: CardCondition? = nil,
    attributes: Components.Schemas.BatchUpdateCardsAttributes? = nil,
    orderBy: Components.Schemas.BatchUpdateCardsOrderBy? = nil
  ) async throws(KaitenError) -> Components.Schemas.BatchUpdateCardsResponse {
    let body = Components.Schemas.BatchUpdateCardsRequest(
      board_id: boardId,
      column_id: columnId,
      lane_id: laneId,
      owner_id: ownerId,
      type_id: typeId,
      condition: condition?.rawValue,
      attributes: attributes,
      order_by: orderBy
    )
    let response = try await call {
      try await client.batch_update_cards(body: .json(body))
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Deletes a card.
  ///
  /// - Parameter id: The card identifier.
  /// - Returns: The deleted card.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func deleteCard(id: Int) async throws(KaitenError) -> Components.Schemas.Card {
    let response = try await call {
      try await client.delete_card(path: .init(card_id: id))
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("card", id)) { try $0.json }
  }

  /// Gets card location history.
  ///
  /// - Parameter cardId: The card identifier.
  /// - Returns: An array of location history entries. Returns an empty array if no history exists.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func getCardLocationHistory(
    cardId: Int
  ) async throws(KaitenError) -> [Components.Schemas.CardLocationHistory] {
    guard
      let response = try await callList({
        try await client.get_card_location_history(path: .init(card_id: cardId))
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("card", cardId)) { try $0.json }
  }

  /// Gets card baselines.
  ///
  /// - Parameter cardId: The card identifier.
  /// - Returns: An array of card baselines. Returns an empty array if no baselines exist.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func getCardBaselines(
    cardId: Int
  ) async throws(KaitenError)
    -> [Components.Schemas.CardBaseline]
  {
    guard
      let response = try await callList({
        try await client.get_card_baselines(
          path: .init(card_id: cardId)
        )
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Lists card types.
  ///
  /// - Parameters:
  ///   - limit: Maximum number of card types to return.
  ///   - offset: Pagination offset.
  /// - Returns: An array of card types.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func listCardTypes(
    limit: Int? = nil, offset: Int? = nil
  ) async throws(KaitenError) -> [Components.Schemas.CardType] {
    guard
      let response = try await callList({
        try await client.list_card_types(query: .init(limit: limit, offset: offset))
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Lists children of a card.
  ///
  /// - Parameter cardId: The card identifier.
  /// - Returns: An array of card children.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func listCardChildren(cardId: Int) async throws(KaitenError) -> [Components.Schemas
    .CardChild]
  {
    guard
      let response = try await callList({
        try await client.list_card_children(path: .init(card_id: cardId))
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("card", cardId)) {
      try $0.json
    }
  }

  /// Adds a child card to a parent card.
  ///
  /// - Parameters:
  ///   - cardId: The parent card identifier.
  ///   - childCardId: The child card identifier.
  /// - Returns: The created card child.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func addCardChild(cardId: Int, childCardId: Int) async throws(KaitenError)
    -> Components.Schemas.CardChild
  {
    let response = try await call {
      try await client.add_card_child(
        path: .init(card_id: cardId),
        body: .json(.init(card_id: childCardId))
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("card", cardId)) {
      try $0.json
    }
  }

  /// Removes a child card from a parent card.
  ///
  /// - Parameters:
  ///   - cardId: The parent card identifier.
  ///   - childCardId: The child card identifier.
  /// - Returns: The deleted child ID.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card or child does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func removeCardChild(cardId: Int, childCardId: Int) async throws(KaitenError) -> Int {
    let response = try await call {
      try await client.remove_card_child(
        path: .init(card_id: cardId, id: childCardId)
      )
    }
    let body = try decodeResponse(response.toCase(), notFoundResource: ("child", childCardId)) {
      try $0.json
    }
    return body.id
  }
}
