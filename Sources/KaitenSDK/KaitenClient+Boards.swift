import Foundation
import OpenAPIRuntime

// MARK: - Boards

extension KaitenClient {
  /// Fetches a board by its identifier.
  ///
  /// Returns the full board object including columns, lanes, and cards.
  ///
  /// - Parameter id: The board identifier.
  /// - Returns: The full board object.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the board does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func getBoard(id: Int) async throws(KaitenError) -> Components.Schemas.Board {
    let response = try await call { try await client.get_board(path: .init(id: id)) }
    return try decodeResponse(response.toCase(), notFoundResource: ("board", id)) { try $0.json }
  }

  /// Lists all boards within a space.
  ///
  /// - Parameter spaceId: The space identifier.
  /// - Returns: An array of boards. Returns an empty array if the space has no boards.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the space does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func listBoards(spaceId: Int) async throws(KaitenError) -> [Components.Schemas
    .BoardInSpace]
  {
    guard
      let response = try await callList({
        try await client.get_list_of_boards(path: .init(space_id: spaceId))
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("space", spaceId)) {
      try $0.json
    }
  }

  /// Creates a new board in a space.
  ///
  /// - Parameters:
  ///   - spaceId: The space identifier.
  ///   - title: The board title.
  ///   - description: An optional board description.
  ///   - sortOrder: An optional sort order.
  ///   - externalId: An optional external identifier.
  ///   - top: An optional Y coordinate of the board on the space.
  ///   - left: An optional X coordinate of the board on the space.
  ///   - columns: Optional columns to create the board with. A default column is created when
  ///     omitted; the API rejects an empty array.
  ///   - lanes: Optional lanes to create the board with. A default lane is created when omitted;
  ///     the API rejects an empty array.
  /// - Returns: The created board.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the space does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for bad request (400), forbidden (403), or other undocumented HTTP status codes.
  public func createBoard(
    spaceId: Int,
    title: String,
    description: String? = nil,
    sortOrder: Double? = nil,
    externalId: String? = nil,
    top: Int? = nil,
    left: Int? = nil,
    columns: [Components.Schemas.CreateColumnRequest]? = nil,
    lanes: [Components.Schemas.CreateLaneRequest]? = nil
  ) async throws(KaitenError) -> Components.Schemas.Board {
    let response = try await call {
      try await client.create_board(
        path: .init(space_id: spaceId),
        body: .json(
          .init(
            title: title,
            description: description,
            sort_order: sortOrder,
            external_id: externalId,
            top: top,
            left: left,
            columns: columns,
            lanes: lanes
          )))
    }
    return try decodeResponse(
      response.toCase(), notFoundResource: ("space", spaceId)
    ) { try $0.json }
  }

  /// Updates a board.
  ///
  /// - Parameters:
  ///   - spaceId: The space identifier.
  ///   - id: The board identifier.
  ///   - title: The updated title.
  ///   - description: The updated description.
  ///   - sortOrder: The updated sort order.
  ///   - externalId: The updated external identifier.
  ///   - top: The updated Y coordinate of the board on the space.
  ///   - left: The updated X coordinate of the board on the space.
  ///   - type: The placement type: `1` places the board on the space by coordinates,
  ///     `5` attaches it to the space as a sidebar.
  ///   - cellWipLimits: The WIP limit rules for cells, as a JSON object.
  ///   - moveParentsToDone: Whether parent cards move to done when their children on this board are done.
  ///   - hideDonePolicies: Whether done checklist policies are hidden.
  ///   - hideDonePoliciesInDoneColumn: Whether done checklist policies are hidden only in the done column.
  ///   - moveFromSpaceId: The space to move the board from.
  ///   - cardProperties: The card properties suggested for filling, as JSON objects.
  /// - Returns: The updated board.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the board does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for bad request (400), forbidden (403), or other undocumented HTTP status codes.
  public func updateBoard(
    spaceId: Int,
    id: Int,
    title: String? = nil,
    description: String? = nil,
    sortOrder: Double? = nil,
    externalId: String? = nil,
    top: Int? = nil,
    left: Int? = nil,
    type: Int? = nil,
    cellWipLimits: OpenAPIObjectContainer? = nil,
    moveParentsToDone: Bool? = nil,
    hideDonePolicies: Bool? = nil,
    hideDonePoliciesInDoneColumn: Bool? = nil,
    moveFromSpaceId: Int? = nil,
    cardProperties: [OpenAPIObjectContainer]? = nil
  ) async throws(KaitenError) -> Components.Schemas.Board {
    let response = try await call {
      try await client.update_board(
        path: .init(space_id: spaceId, id: id),
        body: .json(
          .init(
            title: title,
            description: description,
            sort_order: sortOrder,
            external_id: externalId,
            top: top,
            left: left,
            _type: type,
            cell_wip_limits: cellWipLimits,
            move_parents_to_done: moveParentsToDone,
            hide_done_policies: hideDonePolicies,
            hide_done_policies_in_done_column: hideDonePoliciesInDoneColumn,
            move_from_space_id: moveFromSpaceId,
            card_properties: cardProperties
          )))
    }
    return try decodeResponse(
      response.toCase(), notFoundResource: ("board", id)
    ) { try $0.json }
  }
}
