import ArgumentParser
import KaitenSDK

struct CreateBoard: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "create-board",
    abstract: "Create a new board in a space"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Space ID")
  var spaceId: Int

  @Option(name: .long, help: "Board title")
  var title: String

  @Option(name: .long, help: "Board description")
  var boardDescription: String?

  @Option(name: .long, help: "Sort order")
  var sortOrder: Double?

  @Option(name: .long, help: "External ID")
  var externalId: String?

  func run() async throws {
    let client = try await global.makeClient()
    let board = try await client.createBoard(
      spaceId: spaceId,
      title: title,
      description: boardDescription,
      sortOrder: sortOrder,
      externalId: externalId
    )
    try printJSON(board)
  }
}

struct UpdateBoard: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-board",
    abstract: "Update a board"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Space ID")
  var spaceId: Int

  @Option(name: .long, help: "Board ID")
  var id: Int

  @Option(name: .long, help: "Board title")
  var title: String?

  @Option(name: .long, help: "Board description")
  var boardDescription: String?

  @Option(name: .long, help: "Sort order")
  var sortOrder: Double?

  @Option(name: .long, help: "External ID")
  var externalId: String?

  func run() async throws {
    let client = try await global.makeClient()
    let board = try await client.updateBoard(
      spaceId: spaceId,
      id: id,
      title: title,
      description: boardDescription,
      sortOrder: sortOrder,
      externalId: externalId
    )
    try printJSON(board)
  }
}
