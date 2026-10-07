import Foundation
import OpenAPIRuntime

// MARK: - Columns

extension KaitenClient {
  /// Fetches all columns for a board.
  ///
  /// - Parameter boardId: The board identifier.
  /// - Returns: An array of columns. Returns an empty array if the board has no columns.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the board does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func getBoardColumns(boardId: Int) async throws(KaitenError) -> [Components.Schemas.Column]
  {
    guard
      let response = try await callList({
        try await client.get_list_of_columns(path: .init(board_id: boardId))
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("board", boardId)) {
      try $0.json
    }
  }

  /// Creates a new column on a board.
  ///
  /// - Parameters:
  ///   - boardId: The board identifier.
  ///   - title: The column title.
  ///   - sortOrder: An optional sort order.
  ///   - type: An optional column type.
  ///   - wipLimit: An optional WIP limit.
  ///   - wipLimitType: An optional WIP limit type.
  ///   - colCount: An optional column count.
  ///   - lastMovedWarningAfterDays: Days without movement after which a card is marked stale.
  ///   - lastMovedWarningAfterHours: Hours without movement after which a card is marked stale.
  ///   - lastMovedWarningAfterMinutes: Minutes without movement after which a card is marked stale.
  ///   - archiveAfterDays: Days after which cards are archived automatically. Honoured only by
  ///     columns of type ``ColumnType/done``.
  ///   - cardHideAfterDays: Hides cards not moved for the last N days.
  ///   - rules: Bit mask of column rules: `1` — checklists must be checked, `2` — display FIFO order.
  ///   - externalId: An external identifier, not shown in the web interface.
  /// - Returns: The created column.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the board does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for bad request (400), forbidden (403), or other undocumented HTTP status codes.
  public func createColumn(
    boardId: Int,
    title: String,
    sortOrder: Double? = nil,
    type: ColumnType? = nil,
    wipLimit: Int? = nil,
    wipLimitType: WipLimitType? = nil,
    colCount: Int? = nil,
    lastMovedWarningAfterDays: Int? = nil,
    lastMovedWarningAfterHours: Int? = nil,
    lastMovedWarningAfterMinutes: Int? = nil,
    archiveAfterDays: Int? = nil,
    cardHideAfterDays: Int? = nil,
    rules: Int? = nil,
    externalId: String? = nil
  ) async throws(KaitenError) -> Components.Schemas.Column {
    let response = try await call {
      try await client.create_column(
        path: .init(board_id: boardId),
        body: .json(
          .init(
            title: title,
            sort_order: sortOrder,
            _type: type?.rawValue,
            wip_limit: wipLimit,
            wip_limit_type: wipLimitType?.rawValue,
            col_count: colCount,
            last_moved_warning_after_days: lastMovedWarningAfterDays,
            last_moved_warning_after_hours: lastMovedWarningAfterHours,
            last_moved_warning_after_minutes: lastMovedWarningAfterMinutes,
            archive_after_days: archiveAfterDays,
            card_hide_after_days: cardHideAfterDays,
            rules: rules,
            external_id: externalId
          )))
    }
    return try decodeResponse(
      response.toCase(), notFoundResource: ("board", boardId)
    ) { try $0.json }
  }

  /// Updates a column.
  ///
  /// - Parameters:
  ///   - boardId: The board identifier.
  ///   - id: The column identifier.
  ///   - title: The updated title.
  ///   - sortOrder: The updated sort order.
  ///   - type: The updated column type.
  ///   - wipLimit: The updated WIP limit.
  ///   - wipLimitType: The updated WIP limit type.
  ///   - colCount: The updated column count.
  ///   - lastMovedWarningAfterDays: Days without movement after which a card is marked stale.
  ///   - lastMovedWarningAfterHours: Hours without movement after which a card is marked stale.
  ///   - lastMovedWarningAfterMinutes: Minutes without movement after which a card is marked stale.
  ///   - archiveAfterDays: Days after which cards are archived automatically. Honoured only by
  ///     columns of type ``ColumnType/done``.
  ///   - cardHideAfterDays: Hides cards not moved for the last N days. Pass `.some(nil)` to turn
  ///     hiding off.
  ///     An `Int?` variable holding `nil` is promoted to `.some(nil)` and sends `null`.
  ///   - rules: Bit mask of column rules: `1` — checklists must be checked, `2` — display FIFO order.
  ///   - externalId: An external identifier, not shown in the web interface.
  ///   - prevColumnId: The column to move this column before. Pass `.some(nil)` to move it to
  ///     the beginning.
  ///     An `Int?` variable holding `nil` is promoted to `.some(nil)` and sends `null`.
  ///   - nextColumnId: The column to move this column after. Pass `.some(nil)` to move it to the
  ///     end.
  ///     An `Int?` variable holding `nil` is promoted to `.some(nil)` and sends `null`.
  ///   - pauseSla: Whether the SLA timer is paused in this column.
  /// - Returns: The updated column.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the column does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for bad request (400), forbidden (403), or other undocumented HTTP status codes.
  public func updateColumn(
    boardId: Int,
    id: Int,
    title: String? = nil,
    sortOrder: Double? = nil,
    type: ColumnType? = nil,
    wipLimit: Int? = nil,
    wipLimitType: WipLimitType? = nil,
    colCount: Int? = nil,
    lastMovedWarningAfterDays: Int? = nil,
    lastMovedWarningAfterHours: Int? = nil,
    lastMovedWarningAfterMinutes: Int? = nil,
    archiveAfterDays: Int? = nil,
    cardHideAfterDays: Int?? = nil,
    rules: Int? = nil,
    externalId: String? = nil,
    prevColumnId: Int?? = nil,
    nextColumnId: Int?? = nil,
    pauseSla: Bool? = nil
  ) async throws(KaitenError) -> Components.Schemas.Column {
    let response = try await call {
      try await client.update_column(
        path: .init(board_id: boardId, id: id),
        body: .json(
          .init(
            title: title,
            sort_order: sortOrder,
            _type: type?.rawValue,
            wip_limit: wipLimit,
            wip_limit_type: wipLimitType?.rawValue,
            col_count: colCount,
            last_moved_warning_after_days: lastMovedWarningAfterDays,
            last_moved_warning_after_hours: lastMovedWarningAfterHours,
            last_moved_warning_after_minutes: lastMovedWarningAfterMinutes,
            archive_after_days: archiveAfterDays,
            card_hide_after_days: .from(cardHideAfterDays),
            rules: rules,
            external_id: externalId,
            prev_column_id: .from(prevColumnId),
            next_column_id: .from(nextColumnId),
            pause_sla: pauseSla
          )))
    }
    return try decodeResponse(
      response.toCase(), notFoundResource: ("column", id)
    ) { try $0.json }
  }

  /// Deletes a column.
  ///
  /// - Parameters:
  ///   - boardId: The board identifier.
  ///   - id: The column identifier.
  /// - Returns: The deleted column ID.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the column does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for bad request (400), forbidden (403), or other undocumented HTTP status codes.
  public func deleteColumn(
    boardId: Int, id: Int
  ) async throws(KaitenError) -> Int {
    let response = try await call {
      try await client.remove_column(
        path: .init(board_id: boardId, id: id)
      )
    }
    let result: Components.Schemas.DeletedIdResponse =
      try decodeResponse(
        response.toCase(), notFoundResource: ("column", id)
      ) { try $0.json }
    return result.id
  }

  /// Lists subcolumns of a column.
  ///
  /// - Parameter columnId: The parent column identifier.
  /// - Returns: An array of subcolumns. Returns an empty array if the column has no subcolumns.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the column does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func listSubcolumns(
    columnId: Int
  ) async throws(KaitenError) -> [Components.Schemas.Column] {
    guard
      let response = try await callList({
        try await client.get_list_of_subcolumns(
          path: .init(column_id: columnId)
        )
      })
    else {
      return []
    }
    return try decodeResponse(
      response.toCase(), notFoundResource: ("column", columnId)
    ) { try $0.json }
  }

  /// Creates a subcolumn.
  ///
  /// - Parameters:
  ///   - columnId: The parent column identifier.
  ///   - title: The subcolumn title.
  ///   - sortOrder: An optional sort order.
  ///   - type: An optional column type.
  ///   - colCount: An optional column count.
  ///   - lastMovedWarningAfterDays: Days without movement after which a card is marked stale.
  ///   - lastMovedWarningAfterHours: Hours without movement after which a card is marked stale.
  ///   - lastMovedWarningAfterMinutes: Minutes without movement after which a card is marked stale.
  ///   - archiveAfterDays: Days after which cards are archived automatically. Honoured only by
  ///     columns of type ``ColumnType/done``.
  ///   - cardHideAfterDays: Hides cards not moved for the last N days.
  ///   - rules: Bit mask of column rules: `1` — checklists must be checked, `2` — display FIFO order.
  ///   - externalId: An external identifier, not shown in the web interface.
  /// - Returns: The created subcolumn.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the column does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for bad request (400), forbidden (403), or other undocumented HTTP status codes.
  public func createSubcolumn(
    columnId: Int,
    title: String,
    sortOrder: Double? = nil,
    type: ColumnType? = nil,
    colCount: Int? = nil,
    lastMovedWarningAfterDays: Int? = nil,
    lastMovedWarningAfterHours: Int? = nil,
    lastMovedWarningAfterMinutes: Int? = nil,
    archiveAfterDays: Int? = nil,
    cardHideAfterDays: Int? = nil,
    rules: Int? = nil,
    externalId: String? = nil
  ) async throws(KaitenError) -> Components.Schemas.Column {
    let response = try await call {
      try await client.create_subcolumn(
        path: .init(column_id: columnId),
        body: .json(
          .init(
            title: title,
            sort_order: sortOrder,
            _type: type?.rawValue,
            col_count: colCount,
            last_moved_warning_after_days: lastMovedWarningAfterDays,
            last_moved_warning_after_hours: lastMovedWarningAfterHours,
            last_moved_warning_after_minutes: lastMovedWarningAfterMinutes,
            archive_after_days: archiveAfterDays,
            card_hide_after_days: cardHideAfterDays,
            rules: rules,
            external_id: externalId
          )))
    }
    return try decodeResponse(
      response.toCase(), notFoundResource: ("column", columnId)
    ) { try $0.json }
  }

  /// Updates a subcolumn.
  ///
  /// - Parameters:
  ///   - columnId: The parent column identifier.
  ///   - id: The subcolumn identifier.
  ///   - title: The updated title.
  ///   - sortOrder: The updated sort order.
  ///   - type: The updated column type.
  ///   - colCount: The updated column count.
  ///   - lastMovedWarningAfterDays: Days without movement after which a card is marked stale.
  ///   - lastMovedWarningAfterHours: Hours without movement after which a card is marked stale.
  ///   - lastMovedWarningAfterMinutes: Minutes without movement after which a card is marked stale.
  ///   - archiveAfterDays: Days after which cards are archived automatically. Honoured only by
  ///     columns of type ``ColumnType/done``.
  ///   - cardHideAfterDays: Hides cards not moved for the last N days. Pass `.some(nil)` to turn
  ///     hiding off.
  ///     An `Int?` variable holding `nil` is promoted to `.some(nil)` and sends `null`.
  ///   - rules: Bit mask of column rules: `1` — checklists must be checked, `2` — display FIFO order.
  ///   - externalId: An external identifier, not shown in the web interface.
  ///   - prevColumnId: The column to move this column before. Pass `.some(nil)` to move it to
  ///     the beginning.
  ///     An `Int?` variable holding `nil` is promoted to `.some(nil)` and sends `null`.
  ///   - nextColumnId: The column to move this column after. Pass `.some(nil)` to move it to the
  ///     end.
  ///     An `Int?` variable holding `nil` is promoted to `.some(nil)` and sends `null`.
  ///   - pauseSla: Whether the SLA timer is paused in this column.
  /// - Returns: The updated subcolumn.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the subcolumn does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for bad request (400), forbidden (403), or other undocumented HTTP status codes.
  public func updateSubcolumn(
    columnId: Int,
    id: Int,
    title: String? = nil,
    sortOrder: Double? = nil,
    type: ColumnType? = nil,
    colCount: Int? = nil,
    lastMovedWarningAfterDays: Int? = nil,
    lastMovedWarningAfterHours: Int? = nil,
    lastMovedWarningAfterMinutes: Int? = nil,
    archiveAfterDays: Int? = nil,
    cardHideAfterDays: Int?? = nil,
    rules: Int? = nil,
    externalId: String? = nil,
    prevColumnId: Int?? = nil,
    nextColumnId: Int?? = nil,
    pauseSla: Bool? = nil
  ) async throws(KaitenError) -> Components.Schemas.Column {
    let response = try await call {
      try await client.update_subcolumn(
        path: .init(column_id: columnId, id: id),
        body: .json(
          .init(
            title: title,
            sort_order: sortOrder,
            _type: type?.rawValue,
            col_count: colCount,
            last_moved_warning_after_days: lastMovedWarningAfterDays,
            last_moved_warning_after_hours: lastMovedWarningAfterHours,
            last_moved_warning_after_minutes: lastMovedWarningAfterMinutes,
            archive_after_days: archiveAfterDays,
            card_hide_after_days: .from(cardHideAfterDays),
            rules: rules,
            external_id: externalId,
            prev_column_id: .from(prevColumnId),
            next_column_id: .from(nextColumnId),
            pause_sla: pauseSla
          )))
    }
    return try decodeResponse(
      response.toCase(), notFoundResource: ("subcolumn", id)
    ) { try $0.json }
  }

  /// Deletes a subcolumn.
  ///
  /// - Parameters:
  ///   - columnId: The parent column identifier.
  ///   - id: The subcolumn identifier.
  /// - Returns: The deleted subcolumn ID.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the subcolumn does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for bad request (400), forbidden (403), or other undocumented HTTP status codes.
  public func deleteSubcolumn(
    columnId: Int, id: Int
  ) async throws(KaitenError) -> Int {
    let response = try await call {
      try await client.remove_subcolumn(
        path: .init(column_id: columnId, id: id)
      )
    }
    let result: Components.Schemas.DeletedIdResponse =
      try decodeResponse(
        response.toCase(), notFoundResource: ("subcolumn", id)
      ) { try $0.json }
    return result.id
  }
}
