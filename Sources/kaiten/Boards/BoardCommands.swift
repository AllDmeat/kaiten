import ArgumentParser
import KaitenSDK

// MARK: - Boards

struct ListBoards: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-boards",
    abstract: "List boards in a space"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Space ID")
  var spaceId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let boards = try await client.listBoards(spaceId: spaceId)
    try printJSON(boards, expand: global.expandedFields)
  }
}

struct GetBoard: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "get-board",
    abstract: "Get a board by ID",
    discussion: """
      Kaiten deprecated card retrieval from this endpoint: `cards` holds at most 100 cards \
      since 2026-10-01 and is no longer returned from 2026-11-01. The API pages a board's \
      cards through `GET /cards` with `board_id`, `limit` and `offset`.
      """
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Board ID")
  var id: Int

  func run() async throws {
    let client = try await global.makeClient()
    let board = try await client.getBoard(id: id)
    try printJSON(board, expand: global.expandedFields)
  }
}

struct GetBoardColumns: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "get-board-columns",
    abstract: "Get columns of a board"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Board ID")
  var boardId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let columns = try await client.getBoardColumns(boardId: boardId)
    try printJSON(columns, expand: global.expandedFields)
  }
}

struct GetBoardLanes: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "get-board-lanes",
    abstract: "Get lanes of a board"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Board ID")
  var boardId: Int

  @Option(name: .long, help: "Lane condition: 1 = live, 2 = archived, 3 = deleted")
  var condition: Int?

  func run() async throws {
    let client = try await global.makeClient()
    let lanes = try await client.getBoardLanes(
      boardId: boardId,
      condition: try parseLaneCondition(condition)
    )
    try printJSON(lanes, expand: global.expandedFields)
  }
}
