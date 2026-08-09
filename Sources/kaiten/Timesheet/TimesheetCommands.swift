import ArgumentParser
import Foundation
import KaitenSDK

// MARK: - List Time Logs

struct ListTimeLogs: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-time-logs",
    abstract: "List time logs for the whole company (paginated)",
    discussion: """
      Requires an API token of a user with access to the company timesheet; without it the API \
      answers HTTP 403 with an empty body. The output models the ungrouped response shape; the \
      grouping options are forwarded as documented, but the API documentation does not describe \
      how they change the response.
      """
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Start date of the reporting period (YYYY-MM-DD)")
  var from: String

  @Option(name: .long, help: "End date of the reporting period (YYYY-MM-DD)")
  var to: String

  @Option(name: .long, help: "Comma-separated tag IDs")
  var tagIds: String?

  @Option(name: .long, help: "Comma-separated user IDs")
  var userIds: String?

  @Option(name: .long, help: "Comma-separated user group IDs")
  var groupIds: String?

  @Option(name: .long, help: "Comma-separated space IDs")
  var spaceIds: String?

  @Option(name: .long, help: "Comma-separated board IDs")
  var boardIds: String?

  @Option(name: .long, help: "Comma-separated column IDs")
  var columnIds: String?

  @Option(name: .long, help: "Comma-separated card IDs")
  var cardIds: String?

  @Option(name: .long, help: "Comma-separated visible column IDs")
  var visibleColumnIds: String?

  @Option(
    name: .long,
    help: "Condition filter; the API documentation does not describe its accepted values"
  )
  var condition: Int?

  @Option(name: .long, help: "Grouping option: 0 - no groups, 1 - by user, 2 - by card")
  var groupBy: Int?

  @Option(name: .long, help: "Time precision for the specified time unit")
  var timePrecision: Int?

  @Option(name: .long, help: "Time unit")
  var timeUnit: Int?

  @Option(name: .long, help: "Returns data daily when grouped by user or card")
  var withDailyDistribution: Int?

  @Option(name: .long, help: "Returns the general sum of time spent")
  var onlyGeneralSum: Int?

  @Option(name: .long, help: "Offset for pagination (default: 0)")
  var offset: Int = 0

  @Option(name: .long, help: "Limit for pagination (default: 100, max: 200)")
  var limit: Int = 100

  func run() async throws {
    let client = try await global.makeClient()
    let page = try await client.listTimeLogs(
      from: from,
      to: to,
      tagIds: try parseIntegerCSV(tagIds, fieldName: "--tag-ids"),
      userIds: try parseIntegerCSV(userIds, fieldName: "--user-ids"),
      groupIds: try parseIntegerCSV(groupIds, fieldName: "--group-ids"),
      spaceIds: try parseIntegerCSV(spaceIds, fieldName: "--space-ids"),
      boardIds: try parseIntegerCSV(boardIds, fieldName: "--board-ids"),
      columnIds: try parseIntegerCSV(columnIds, fieldName: "--column-ids"),
      cardIds: try parseIntegerCSV(cardIds, fieldName: "--card-ids"),
      visibleColumnIds: try parseIntegerCSV(visibleColumnIds, fieldName: "--visible-column-ids"),
      condition: condition,
      groupBy: groupBy,
      timePrecision: timePrecision,
      timeUnit: timeUnit,
      withDailyDistribution: withDailyDistribution,
      onlyGeneralSum: onlyGeneralSum,
      offset: offset,
      limit: limit
    )
    try printJSON(page, expand: global.expandedFields)
  }
}
