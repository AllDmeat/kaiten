import ArgumentParser
import Foundation
import KaitenSDK

// MARK: - Get Card Time Logs

struct GetCardTimeLogs: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "get-card-time-logs",
    abstract: "List time logs on a card"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  @Option(name: .long, help: "Filter by log date (YYYY-MM-DD)")
  var forDate: String?

  @Flag(name: .long, help: "Only the current user's time logs")
  var personal: Bool = false

  func run() async throws {
    let client = try await global.makeClient()
    let timeLogs = try await client.getCardTimeLogs(
      cardId: cardId, forDate: forDate, personal: personal ? true : nil)
    try printJSON(timeLogs, expand: global.expandedFields)
  }
}

// MARK: - Add Time Log

struct AddTimeLog: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "add-time-log",
    abstract: "Add a time log to a card"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  @Option(name: .long, help: "Role ID; the predefined role -1 is Employee")
  var roleId: Int

  @Option(name: .long, help: "Minutes to log (at least 1)")
  var timeSpent: Int

  @Option(name: .long, help: "Log date (YYYY-MM-DD)")
  var forDate: String

  @Option(name: .long, help: "Comment (up to 4096 characters)")
  var comment: String?

  func run() async throws {
    let client = try await global.makeClient()
    let timeLog = try await client.createCardTimeLog(
      cardId: cardId, roleId: roleId, timeSpent: timeSpent, forDate: forDate, comment: comment)
    try printJSON(timeLog, expand: global.expandedFields)
  }
}

// MARK: - Update Time Log

struct UpdateTimeLog: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-time-log",
    abstract: "Update a time log on a card"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  @Option(name: .long, help: "Time log ID")
  var timeLogId: Int

  @Option(name: .long, help: "Role ID; the predefined role -1 is Employee")
  var roleId: Int?

  @Option(name: .long, help: "Minutes to log (at least 1)")
  var timeSpent: Int?

  @Option(name: .long, help: "Log date (YYYY-MM-DD)")
  var forDate: String?

  @Option(name: .long, help: "Comment (up to 4096 characters)")
  var comment: String?

  func run() async throws {
    let client = try await global.makeClient()
    let timeLog = try await client.updateCardTimeLog(
      cardId: cardId,
      timeLogId: timeLogId,
      roleId: roleId,
      timeSpent: timeSpent,
      forDate: forDate,
      comment: comment
    )
    try printJSON(timeLog, expand: global.expandedFields)
  }
}

// MARK: - Remove Time Log

struct RemoveTimeLog: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "remove-time-log",
    abstract: "Remove a time log from a card"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  @Option(name: .long, help: "Time log ID")
  var timeLogId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let deletedId = try await client.deleteCardTimeLog(cardId: cardId, timeLogId: timeLogId)
    try printJSON(["id": deletedId], expand: global.expandedFields)
  }
}
