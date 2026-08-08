import Foundation
import OpenAPIRuntime

// MARK: - Space Boards

extension KaitenClient {
  /// Fetches a board within a space.
  ///
  /// Returns the full board object including columns, lanes, and cards, plus the
  /// space binding: the board's position on the space (`top`, `left`, `sort_order`)
  /// and the `space_id` itself.
  ///
  /// - Parameters:
  ///   - spaceId: The space identifier.
  ///   - id: The board identifier.
  /// - Returns: The board with its space-placement attributes.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the board does not exist in the space.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func getSpaceBoard(spaceId: Int, id: Int) async throws(KaitenError)
    -> Components.Schemas
    .SpaceBoard
  {
    let response = try await call {
      try await client.get_space_board(path: .init(space_id: spaceId, id: id))
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("board", id)) { try $0.json }
  }
}
