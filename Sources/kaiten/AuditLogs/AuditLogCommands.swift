import ArgumentParser
import Foundation
import KaitenSDK

// MARK: - Audit Logs

func parseAuditLogCategories(_ rawValue: String?) throws -> [AuditLogCategory]? {
  guard let tokens = try parseStringCSV(rawValue, fieldName: "--categories") else { return nil }
  return try tokens.map { token in
    let category = AuditLogCategory(rawValue: token)
    guard AuditLogCategory.allCases.contains(category) else {
      let allowed = AuditLogCategory.allCases.map(\.rawValue).joined(separator: ", ")
      throw ValidationError("Invalid audit log category: '\(token)'. Allowed values: \(allowed)")
    }
    return category
  }
}

func parseAuditLogActions(_ rawValue: String?) throws -> [AuditLogAction]? {
  guard let tokens = try parseStringCSV(rawValue, fieldName: "--actions") else { return nil }
  return try tokens.map { token in
    let action = AuditLogAction(rawValue: token)
    guard AuditLogAction.allCases.contains(action) else {
      let allowed = AuditLogAction.allCases.map(\.rawValue).joined(separator: ", ")
      throw ValidationError("Invalid audit log action: '\(token)'. Allowed values: \(allowed)")
    }
    return action
  }
}

// MARK: - List Audit Logs

struct ListAuditLogs: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-audit-logs",
    abstract: "List audit log events for the current company (paginated)",
    discussion: """
      Requires an API token of a user with access to the administrative section "Audit log". \
      Events are ordered by creation time from newest to oldest.
      """
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Return events created at or after this date-time (ISO 8601)")
  var from: String?

  @Option(name: .long, help: "Return events created at or before this date-time (ISO 8601)")
  var to: String?

  @Option(name: .long, help: "Filter events by author user ID")
  var authorId: Int?

  @Option(name: .long, help: "Filter events by author user UID")
  var authorUid: String?

  @Option(
    name: .long,
    help:
      "Comma-separated categories: app, auth, user_profile, user_management, group_management, service_desk, publication, import, company_profile"
  )
  var categories: String?

  @Option(name: .long, help: "Comma-separated actions, e.g. sign_in_fail,change_permissions")
  var actions: String?

  @Option(name: .long, help: "Filter by audit log event ID")
  var id: String?

  @Option(name: .long, help: "Offset for pagination (default: 0)")
  var offset: Int = 0

  @Option(name: .long, help: "Limit for pagination (default: 100, max: 500)")
  var limit: Int = 100

  func run() async throws {
    let parsedCategories = try parseAuditLogCategories(categories)
    let parsedActions = try parseAuditLogActions(actions)
    let client = try await global.makeClient()
    let page = try await client.listAuditLogs(
      from: try DateParsing.parse(from),
      to: try DateParsing.parse(to),
      authorId: authorId,
      authorUid: authorUid,
      categories: parsedCategories,
      actions: parsedActions,
      id: id,
      offset: offset,
      limit: limit
    )
    try printJSON(page, expand: global.expandedFields)
  }
}
