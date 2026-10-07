import Foundation
import OpenAPIRuntime

// MARK: - Sprints

extension KaitenClient {
  /// Lists sprints.
  ///
  /// Kaiten deprecated sprints: starting new sprints is unavailable since 2026-10-01. Existing
  /// sprints can still be finished and read; iterations replace them.
  ///
  /// - Parameters:
  ///   - active: Filter by active status.
  ///   - limit: Maximum number of sprints to return.
  ///   - offset: Pagination offset.
  /// - Returns: An array of sprints.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  @available(
    *, deprecated,
    message:
      "Kaiten deprecated sprints: new sprints cannot be started since 2026-10-01. Use iterations."
  )
  public func listSprints(
    active: Bool? = nil, limit: Int? = nil, offset: Int? = nil
  ) async throws(KaitenError) -> [Components.Schemas.Sprint] {
    guard
      let response = try await callList({
        try await client.list_sprints(query: .init(active: active, limit: limit, offset: offset))
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Gets a sprint summary by ID.
  ///
  /// Kaiten deprecated sprints: starting new sprints is unavailable since 2026-10-01. Existing
  /// sprints can still be finished and read; iterations replace them.
  ///
  /// - Parameters:
  ///   - id: The sprint identifier.
  ///   - excludeDeletedCards: Whether to exclude deleted cards from the summary.
  /// - Returns: The sprint summary.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the sprint does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  @available(
    *, deprecated,
    message:
      "Kaiten deprecated sprints: new sprints cannot be started since 2026-10-01. Use iterations."
  )
  public func getSprintSummary(
    id: Int, excludeDeletedCards: Bool? = nil
  ) async throws(KaitenError) -> Components.Schemas.SprintSummary {
    let response = try await call {
      try await client.get_sprint_summary(
        path: .init(id: id),
        query: .init(exclude_deleted_cards: excludeDeletedCards)
      )
    }
    return try decodeResponse(
      response.toCase(), notFoundResource: ("sprint", id)
    ) { try $0.json }
  }
}
