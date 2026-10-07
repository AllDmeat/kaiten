import ArgumentParser
import KaitenSDK

// MARK: - Space Boards

struct GetSpaceBoard: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "get-space-board",
    abstract: "Get a board within a space, including its position on the space",
    discussion: """
      Kaiten deprecated card retrieval from this endpoint: `cards` holds at most 100 cards \
      since 2026-10-01 and is no longer returned from 2026-11-01.
      """
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Space ID")
  var spaceId: Int

  @Option(name: .long, help: "Board ID")
  var id: Int

  func run() async throws {
    let client = try await global.makeClient()
    let board = try await client.getSpaceBoard(spaceId: spaceId, id: id)
    try printJSON(board, expand: global.expandedFields)
  }
}
