import ArgumentParser
import KaitenSDK

func parseLaneCondition(_ rawValue: Int?) throws -> LaneCondition? {
  guard let rawValue else { return nil }
  let condition = LaneCondition(rawValue: rawValue)
  guard LaneCondition.allCases.contains(condition) else {
    throw ValidationError(
      "Invalid lane condition: \(rawValue). Allowed values: 1 (live), 2 (archived)")
  }
  return condition
}

struct CreateLane: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "create-lane",
    abstract: "Create a new lane on a board"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Board ID")
  var boardId: Int

  @Option(name: .long, help: "Lane title")
  var title: String

  @Option(name: .long, help: "Sort order")
  var sortOrder: Double?

  @Option(name: .long, help: "WIP limit value")
  var wipLimit: Int?

  @Option(name: .long, help: "WIP limit type: 1=card count, 2=card size")
  var wipLimitType: Int?

  @Option(name: .long, help: "Row count (height)")
  var rowCount: Int?

  func run() async throws {
    let client = try await global.makeClient()
    let lane = try await client.createLane(
      boardId: boardId,
      title: title,
      sortOrder: sortOrder,
      wipLimit: wipLimit,
      wipLimitType: try parseWipLimitType(wipLimitType),
      rowCount: rowCount
    )
    try printJSON(lane)
  }
}

struct UpdateLane: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-lane",
    abstract: "Update a lane"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Board ID")
  var boardId: Int

  @Option(name: .long, help: "Lane ID")
  var id: Int

  @Option(name: .long, help: "Lane title")
  var title: String?

  @Option(name: .long, help: "Sort order")
  var sortOrder: Double?

  @Option(name: .long, help: "WIP limit value")
  var wipLimit: Int?

  @Option(name: .long, help: "WIP limit type: 1=card count, 2=card size")
  var wipLimitType: Int?

  @Option(name: .long, help: "Row count (height)")
  var rowCount: Int?

  @Option(name: .long, help: "Condition: 1=live, 2=archived")
  var condition: Int?

  func run() async throws {
    let client = try await global.makeClient()
    let lane = try await client.updateLane(
      boardId: boardId,
      id: id,
      title: title,
      sortOrder: sortOrder,
      wipLimit: wipLimit,
      wipLimitType: try parseWipLimitType(wipLimitType),
      rowCount: rowCount,
      condition: try parseLaneCondition(condition)
    )
    try printJSON(lane)
  }
}
