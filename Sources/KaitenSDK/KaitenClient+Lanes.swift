import Foundation
import OpenAPIRuntime

// MARK: - Lanes

extension KaitenClient {
  /// Fetches all lanes (horizontal swimlanes) for a board.
  ///
  /// - Parameters:
  ///   - boardId: The board identifier.
  ///   - condition: Optional lane condition filter.
  /// - Returns: An array of lanes. Returns an empty array if the board has no lanes.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the board does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func getBoardLanes(boardId: Int, condition: LaneCondition? = nil) async throws(KaitenError)
    -> [Components.Schemas.Lane]
  {
    guard
      let response = try await callList({
        try await client.get_list_of_lanes(
          path: .init(board_id: boardId), query: .init(condition: condition?.rawValue))
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("board", boardId)) {
      try $0.json
    }
  }

  /// Creates a new lane on a board.
  ///
  /// - Parameters:
  ///   - boardId: The board identifier.
  ///   - title: The lane title.
  ///   - sortOrder: An optional sort order.
  ///   - wipLimit: An optional WIP limit.
  ///   - wipLimitType: An optional WIP limit type.
  ///   - rowCount: An optional row count.
  ///   - lastMovedWarningAfterDays: Days without movement after which a card is marked stale.
  ///   - lastMovedWarningAfterHours: Hours without movement after which a card is marked stale.
  ///   - lastMovedWarningAfterMinutes: Minutes without movement after which a card is marked stale.
  /// - Returns: The created lane.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the board does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for bad request (400), forbidden (403), or other undocumented HTTP status codes.
  public func createLane(
    boardId: Int,
    title: String,
    sortOrder: Double? = nil,
    wipLimit: Int? = nil,
    wipLimitType: WipLimitType? = nil,
    rowCount: Int? = nil,
    lastMovedWarningAfterDays: Int? = nil,
    lastMovedWarningAfterHours: Int? = nil,
    lastMovedWarningAfterMinutes: Int? = nil
  ) async throws(KaitenError) -> Components.Schemas.Lane {
    let response = try await call {
      try await client.create_lane(
        path: .init(board_id: boardId),
        body: .json(
          .init(
            title: title,
            sort_order: sortOrder,
            wip_limit: wipLimit,
            wip_limit_type: wipLimitType?.rawValue,
            row_count: rowCount,
            last_moved_warning_after_days: lastMovedWarningAfterDays,
            last_moved_warning_after_hours: lastMovedWarningAfterHours,
            last_moved_warning_after_minutes: lastMovedWarningAfterMinutes
          )))
    }
    return try decodeResponse(
      response.toCase(), notFoundResource: ("board", boardId)
    ) { try $0.json }
  }

  /// Updates a lane.
  ///
  /// - Parameters:
  ///   - boardId: The board identifier.
  ///   - id: The lane identifier.
  ///   - title: The updated title.
  ///   - sortOrder: The updated sort order.
  ///   - wipLimit: The updated WIP limit. `nil` leaves it unchanged.
  ///   - clearWipLimit: Pass `true` to remove the WIP limit (sends `"wip_limit": null`).
  ///   - wipLimitType: The updated WIP limit type.
  ///   - rowCount: The updated row count.
  ///   - condition: The updated lane condition.
  ///   - lastMovedWarningAfterDays: Days without movement after which a card is marked stale.
  ///   - lastMovedWarningAfterHours: Hours without movement after which a card is marked stale.
  ///   - lastMovedWarningAfterMinutes: Minutes without movement after which a card is marked stale.
  /// - Returns: The updated lane.
  /// - Throws:
  ///   - ``KaitenError/conflictingArguments(_:_:)`` if both `wipLimit` and `clearWipLimit` are given.
  ///   - ``KaitenError/notFound(resource:id:)`` if the lane does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for bad request (400), forbidden (403), or other undocumented HTTP status codes.
  public func updateLane(
    boardId: Int,
    id: Int,
    title: String? = nil,
    sortOrder: Double? = nil,
    wipLimit: Int? = nil,
    clearWipLimit: Bool = false,
    wipLimitType: WipLimitType? = nil,
    rowCount: Int? = nil,
    condition: LaneCondition? = nil,
    lastMovedWarningAfterDays: Int? = nil,
    lastMovedWarningAfterHours: Int? = nil,
    lastMovedWarningAfterMinutes: Int? = nil
  ) async throws(KaitenError) -> Components.Schemas.Lane {
    if clearWipLimit, wipLimit != nil {
      throw .conflictingArguments("wipLimit", "clearWipLimit")
    }
    let response = try await call {
      try await ExplicitNullFieldsMiddleware.$fields.withValue(
        clearWipLimit ? ["wip_limit"] : []
      ) {
        try await client.update_lane(
          path: .init(board_id: boardId, id: id),
          body: .json(
            .init(
              title: title,
              sort_order: sortOrder,
              wip_limit: wipLimit,
              wip_limit_type: wipLimitType?.rawValue,
              row_count: rowCount,
              last_moved_warning_after_days: lastMovedWarningAfterDays,
              last_moved_warning_after_hours: lastMovedWarningAfterHours,
              last_moved_warning_after_minutes: lastMovedWarningAfterMinutes,
              condition: condition?.rawValue
            )))
      }
    }
    return try decodeResponse(
      response.toCase(), notFoundResource: ("lane", id)
    ) { try $0.json }
  }
}
