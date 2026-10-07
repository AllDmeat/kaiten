import ArgumentParser
import KaitenSDK
import OpenAPIRuntime

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

  @Option(name: .long, help: "Y coordinate of the board on the space")
  var top: Int?

  @Option(name: .long, help: "X coordinate of the board on the space")
  var left: Int?

  @Option(
    name: .long,
    help:
      "Columns as a JSON array of column objects. A default column is created when omitted; the API rejects an empty array"
  )
  var columns: String?

  @Option(
    name: .long,
    help:
      "Lanes as a JSON array of lane objects. A default lane is created when omitted; the API rejects an empty array"
  )
  var lanes: String?

  func run() async throws {
    let parsedColumns = try parseCardTypeJSON(
      columns, as: [Components.Schemas.CreateBoardColumnRequest].self, fieldName: "columns")
    let parsedLanes = try parseCardTypeJSON(
      lanes, as: [Components.Schemas.CreateBoardLaneRequest].self, fieldName: "lanes")
    if parsedColumns?.isEmpty == true {
      throw ValidationError("--columns must not be an empty array")
    }
    if parsedLanes?.isEmpty == true {
      throw ValidationError("--lanes must not be an empty array")
    }

    let client = try await global.makeClient()
    let board = try await client.createBoard(
      spaceId: spaceId,
      title: title,
      description: boardDescription,
      sortOrder: sortOrder,
      externalId: externalId,
      top: top,
      left: left,
      columns: parsedColumns,
      lanes: parsedLanes
    )
    try printJSON(board, expand: global.expandedFields)
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

  @Option(name: .long, help: "Y coordinate of the board on the space")
  var top: Int?

  @Option(name: .long, help: "X coordinate of the board on the space")
  var left: Int?

  @Option(
    name: .long,
    help:
      "Placement: 1 - on the space by coordinates (top, left), 5 - attached to the space as a sidebar"
  )
  var type: Int?

  @Option(name: .long, help: "WIP limit rules for cells as JSON")
  var cellWipLimits: String?

  @Option(name: .long, help: "Move parent cards to done when their children on this board are done")
  var moveParentsToDone: Bool?

  @Option(name: .long, help: "Hide done checklist policies")
  var hideDonePolicies: Bool?

  @Option(name: .long, help: "Hide done checklist policies only in the done column")
  var hideDonePoliciesInDoneColumn: Bool?

  @Option(name: .long, help: "ID of the space to move the board from")
  var moveFromSpaceId: Int?

  @Option(name: .long, help: "Card properties suggested for filling as a JSON array of objects")
  var cardProperties: String?

  func run() async throws {
    let parsedCellWipLimits = try parseCardTypeJSON(
      cellWipLimits, as: OpenAPIValueContainer.self, fieldName: "cell-wip-limits")
    let parsedCardProperties = try parseCardTypeJSON(
      cardProperties, as: [OpenAPIObjectContainer].self, fieldName: "card-properties")

    let client = try await global.makeClient()
    let board = try await client.updateBoard(
      spaceId: spaceId,
      id: id,
      title: title,
      description: boardDescription,
      sortOrder: sortOrder,
      externalId: externalId,
      top: top,
      left: left,
      type: type,
      cellWipLimits: parsedCellWipLimits,
      moveParentsToDone: moveParentsToDone,
      hideDonePolicies: hideDonePolicies,
      hideDonePoliciesInDoneColumn: hideDonePoliciesInDoneColumn,
      moveFromSpaceId: moveFromSpaceId,
      cardProperties: parsedCardProperties
    )
    try printJSON(board, expand: global.expandedFields)
  }
}
