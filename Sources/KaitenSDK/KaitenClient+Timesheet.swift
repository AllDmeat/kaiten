import Foundation
import OpenAPIRuntime

// MARK: - Timesheet

extension KaitenClient {
  /// Returns a page of time logs for the whole company, filtered by query parameters.
  ///
  /// Requires an API token of a user who has access to the company timesheet. The SDK models the
  /// documented (ungrouped) response shape; the `groupBy`, `withDailyDistribution` and
  /// `onlyGeneralSum` parameters are forwarded as documented, but the documentation does not
  /// describe how they change the response.
  ///
  /// - Parameters:
  ///   - from: Start date of the reporting period, format `YYYY-MM-DD`.
  ///   - to: End date of the reporting period, format `YYYY-MM-DD`.
  ///   - tagIds: Filter by tag identifiers (optional).
  ///   - userIds: Filter by user identifiers (optional).
  ///   - groupIds: Filter by user group identifiers (optional).
  ///   - spaceIds: Filter by space identifiers (optional).
  ///   - boardIds: Filter by board identifiers (optional).
  ///   - columnIds: Filter by column identifiers (optional).
  ///   - cardIds: Filter by card identifiers (optional).
  ///   - visibleColumnIds: Visible column identifiers (optional).
  ///   - condition: Condition filter (optional). The documentation describes this parameter only
  ///     with the `offset` description, so its accepted values are not documented.
  ///   - groupBy: Grouping option: `0` — no groups, `1` — by user, `2` — by card (optional).
  ///   - timePrecision: Time precision for the specified `timeUnit` (optional).
  ///   - timeUnit: Time unit (optional).
  ///   - withDailyDistribution: Returns data daily when grouped by user or card (optional).
  ///   - onlyGeneralSum: Returns the general sum of time spent (optional).
  ///   - offset: Number of records to skip (default `0`).
  ///   - limit: Maximum number of records to return (default `100`, max `200`).
  /// - Returns: A ``Page`` of time logs. Returns an empty page when no records match.
  /// - Throws:
  ///   - ``KaitenError/invalidPaginationRange(offset:limit:)`` if pagination parameters are out of range.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for bad request (400), forbidden
  ///     (403, the token's user has no access to the timesheet; the API answers with an empty
  ///     body) or other undocumented HTTP status codes.
  public func listTimeLogs(
    from: String,
    to: String,
    tagIds: [Int]? = nil,
    userIds: [Int]? = nil,
    groupIds: [Int]? = nil,
    spaceIds: [Int]? = nil,
    boardIds: [Int]? = nil,
    columnIds: [Int]? = nil,
    cardIds: [Int]? = nil,
    visibleColumnIds: [Int]? = nil,
    condition: Int? = nil,
    groupBy: Int? = nil,
    timePrecision: Int? = nil,
    timeUnit: Int? = nil,
    withDailyDistribution: Int? = nil,
    onlyGeneralSum: Int? = nil,
    offset: Int = 0,
    limit: Int = 100
  ) async throws(KaitenError) -> Page<Components.Schemas.TimeLog> {
    guard offset >= 0, (1...200).contains(limit) else {
      throw .invalidPaginationRange(offset: offset, limit: limit)
    }
    let query = Operations.list_time_logs.Input.Query(
      from: from,
      to: to,
      tag_ids: tagIds.map(joinIds),
      user_ids: userIds.map(joinIds),
      group_ids: groupIds.map(joinIds),
      space_ids: spaceIds.map(joinIds),
      board_ids: boardIds.map(joinIds),
      column_ids: columnIds.map(joinIds),
      card_ids: cardIds.map(joinIds),
      visible_column_ids: visibleColumnIds.map(joinIds),
      limit: limit,
      offset: offset,
      condition: condition,
      group_by: groupBy,
      time_precision: timePrecision,
      time_unit: timeUnit,
      with_daily_distribution: withDailyDistribution,
      only_general_sum: onlyGeneralSum
    )
    guard
      let response = try await callList({
        try await client.list_time_logs(query: query)
      })
    else {
      return Page(items: [], offset: offset, limit: limit)
    }
    let items: [Components.Schemas.TimeLog] = try decodeResponse(response.toCase()) {
      try $0.json
    }
    return Page(items: items, offset: offset, limit: limit)
  }

  /// Joins identifier lists into the comma-separated string form the endpoint documents.
  private func joinIds(_ ids: [Int]) -> String {
    ids.map(String.init).joined(separator: ",")
  }
}
