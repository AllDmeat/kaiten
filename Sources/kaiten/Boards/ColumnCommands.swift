import ArgumentParser
import KaitenSDK

func parseColumnType(_ rawValue: Int?) throws -> ColumnType? {
  guard let rawValue else { return nil }
  let type = ColumnType(rawValue: rawValue)
  guard ColumnType.allCases.contains(type) else {
    throw ValidationError(
      "Invalid column type: \(rawValue). Allowed values: 1 (queue), 2 (in progress), 3 (done)"
    )
  }
  return type
}

func parseWipLimitType(_ rawValue: Int?) throws -> WipLimitType? {
  guard let rawValue else { return nil }
  let type = WipLimitType(rawValue: rawValue)
  guard WipLimitType.allCases.contains(type) else {
    throw ValidationError(
      "Invalid WIP limit type: \(rawValue). Allowed values: 1 (card count), 2 (card size)"
    )
  }
  return type
}

struct CreateColumn: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "create-column",
    abstract: "Create a new column on a board"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Board ID")
  var boardId: Int

  @Option(name: .long, help: "Column title")
  var title: String

  @Option(name: .long, help: "Sort order")
  var sortOrder: Double?

  @Option(name: .long, help: "Column type: 1=queue, 2=in progress, 3=done")
  var columnType: Int?

  @Option(name: .long, help: "WIP limit value")
  var wipLimit: Int?

  @Option(name: .long, help: "WIP limit type: 1=card count, 2=card size")
  var wipLimitType: Int?

  @Option(name: .long, help: "Number of columns to display side by side")
  var colCount: Int?

  func run() async throws {
    let client = try await global.makeClient()
    let column = try await client.createColumn(
      boardId: boardId,
      title: title,
      sortOrder: sortOrder,
      type: try parseColumnType(columnType),
      wipLimit: wipLimit,
      wipLimitType: try parseWipLimitType(wipLimitType),
      colCount: colCount
    )
    try printJSON(column, expand: global.expandedFields)
  }
}

struct UpdateColumn: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-column",
    abstract: "Update a column"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Board ID")
  var boardId: Int

  @Option(name: .long, help: "Column ID")
  var id: Int

  @Option(name: .long, help: "Column title")
  var title: String?

  @Option(name: .long, help: "Sort order")
  var sortOrder: Double?

  @Option(name: .long, help: "Column type: 1=queue, 2=in progress, 3=done")
  var columnType: Int?

  @Option(name: .long, help: "WIP limit value")
  var wipLimit: Int?

  @Option(name: .long, help: "WIP limit type: 1=card count, 2=card size")
  var wipLimitType: Int?

  @Option(name: .long, help: "Number of columns to display side by side")
  var colCount: Int?

  func run() async throws {
    let client = try await global.makeClient()
    let column = try await client.updateColumn(
      boardId: boardId,
      id: id,
      title: title,
      sortOrder: sortOrder,
      type: try parseColumnType(columnType),
      wipLimit: wipLimit,
      wipLimitType: try parseWipLimitType(wipLimitType),
      colCount: colCount
    )
    try printJSON(column, expand: global.expandedFields)
  }
}

struct DeleteColumn: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "delete-column",
    abstract: "Delete a column"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Board ID")
  var boardId: Int

  @Option(name: .long, help: "Column ID")
  var id: Int

  func run() async throws {
    let client = try await global.makeClient()
    let deletedId = try await client.deleteColumn(
      boardId: boardId,
      id: id
    )
    try printJSON(["id": deletedId], expand: global.expandedFields)
  }
}

// MARK: - Subcolumns

struct ListSubcolumns: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-subcolumns",
    abstract: "List subcolumns of a column"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Column ID")
  var columnId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let subcolumns = try await client.listSubcolumns(
      columnId: columnId
    )
    try printJSON(subcolumns, expand: global.expandedFields)
  }
}

struct CreateSubcolumn: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "create-subcolumn",
    abstract: "Create a new subcolumn"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Column ID")
  var columnId: Int

  @Option(name: .long, help: "Subcolumn title")
  var title: String

  @Option(name: .long, help: "Sort order")
  var sortOrder: Double?

  @Option(name: .long, help: "Subcolumn type: 1=queue, 2=in progress, 3=done")
  var columnType: Int?

  func run() async throws {
    let client = try await global.makeClient()
    let subcolumn = try await client.createSubcolumn(
      columnId: columnId,
      title: title,
      sortOrder: sortOrder,
      type: try parseColumnType(columnType)
    )
    try printJSON(subcolumn, expand: global.expandedFields)
  }
}

struct UpdateSubcolumn: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-subcolumn",
    abstract: "Update a subcolumn"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Column ID")
  var columnId: Int

  @Option(name: .long, help: "Subcolumn ID")
  var id: Int

  @Option(name: .long, help: "Subcolumn title")
  var title: String?

  @Option(name: .long, help: "Sort order")
  var sortOrder: Double?

  @Option(name: .long, help: "Subcolumn type: 1=queue, 2=in progress, 3=done")
  var columnType: Int?

  func run() async throws {
    let client = try await global.makeClient()
    let subcolumn = try await client.updateSubcolumn(
      columnId: columnId,
      id: id,
      title: title,
      sortOrder: sortOrder,
      type: try parseColumnType(columnType)
    )
    try printJSON(subcolumn, expand: global.expandedFields)
  }
}

struct DeleteSubcolumn: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "delete-subcolumn",
    abstract: "Delete a subcolumn"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Column ID")
  var columnId: Int

  @Option(name: .long, help: "Subcolumn ID")
  var id: Int

  func run() async throws {
    let client = try await global.makeClient()
    let deletedId = try await client.deleteSubcolumn(
      columnId: columnId,
      id: id
    )
    try printJSON(["id": deletedId], expand: global.expandedFields)
  }
}
