import Foundation
import OpenAPIRuntime

// MARK: - Typed Discriminators

// Audit log category and action travel as plain strings (see the comment above
// the audit log enums in `Enums.swift`). These accessors give the generated
// payload a typed surface without losing undocumented values.

extension Components.Schemas.AuditLogEvent {
  /// The event category, or `nil` if the API omitted the field.
  public var auditLogCategory: AuditLogCategory? {
    category.map(AuditLogCategory.init(rawValue:))
  }

  /// The event action, or `nil` if the API omitted the field.
  public var auditLogAction: AuditLogAction? {
    action.map(AuditLogAction.init(rawValue:))
  }
}

// MARK: - Audit Logs

extension KaitenClient {
  /// Returns a page of audit log events for the current company.
  ///
  /// Requires an API token of a user who has access to the administrative section
  /// "Audit log" for the current company. Events are ordered by creation time from
  /// newest to oldest.
  ///
  /// - Parameters:
  ///   - from: Return events created at or after this date-time (optional).
  ///   - to: Return events created at or before this date-time (optional).
  ///   - authorId: Filter events by author user identifier (optional).
  ///   - authorUid: Filter events by author user UID (optional).
  ///   - categories: Filter events by categories (optional).
  ///   - actions: Filter events by actions (optional).
  ///   - id: Filter by audit log event identifier (optional).
  ///   - offset: Number of events to skip (default `0`).
  ///   - limit: Maximum number of events to return (default `100`, max `500`).
  /// - Returns: A ``Page`` of audit log events. Returns an empty page when no events match.
  /// - Throws:
  ///   - ``KaitenError/invalidPaginationRange(offset:limit:)`` if pagination parameters are out of range.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for bad request (400), forbidden
  ///     (403, the user has no access to the audit log administrative section) or other
  ///     undocumented HTTP status codes.
  public func listAuditLogs(
    from: Date? = nil,
    to: Date? = nil,
    authorId: Int? = nil,
    authorUid: String? = nil,
    categories: [AuditLogCategory]? = nil,
    actions: [AuditLogAction]? = nil,
    id: String? = nil,
    offset: Int = 0,
    limit: Int = 100
  ) async throws(KaitenError) -> Page<Components.Schemas.AuditLogEvent> {
    guard offset >= 0, (1...500).contains(limit) else {
      throw .invalidPaginationRange(offset: offset, limit: limit)
    }
    let query = Operations.retrieve_audit_log_events.Input.Query(
      from: from,
      to: to,
      author_id: authorId,
      author_uid: authorUid,
      categories: categories.map { $0.map(\.rawValue).joined(separator: ",") },
      actions: actions.map { $0.map(\.rawValue).joined(separator: ",") },
      id: id,
      limit: limit,
      offset: offset
    )
    guard
      let response = try await callList({
        try await client.retrieve_audit_log_events(query: query)
      })
    else {
      return Page(items: [], offset: offset, limit: limit)
    }
    let items: [Components.Schemas.AuditLogEvent] = try decodeResponse(response.toCase()) {
      try $0.json
    }
    return Page(items: items, offset: offset, limit: limit)
  }
}
