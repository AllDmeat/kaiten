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

/// Maps an option that can clear a nullable integer field:
/// absent → leave unchanged, `""` → send JSON null, a number → send it.
func parseNullableInt(_ raw: String?, option: String) throws -> Int?? {
  try raw.map { raw in
    if raw.isEmpty { return nil }
    guard let value = Int(raw) else {
      throw ValidationError("Invalid \(option) value: '\(raw)'")
    }
    return value
  }
}

/// Settings shared by columns and subcolumns on create and update.
struct ColumnSettingsOptions: ParsableArguments {
  @Option(name: .long, help: "Days without movement after which a card is marked stale")
  var lastMovedWarningAfterDays: Int?

  @Option(name: .long, help: "Hours without movement after which a card is marked stale")
  var lastMovedWarningAfterHours: Int?

  @Option(name: .long, help: "Minutes without movement after which a card is marked stale")
  var lastMovedWarningAfterMinutes: Int?

  @Option(
    name: .long,
    help: "Days after which cards are archived automatically. Honoured only by done columns.")
  var archiveAfterDays: Int?

  @Option(
    name: .long,
    help: "Bit mask of column rules: 1=checklists must be checked, 2=display FIFO order")
  var rules: Int?

  @Option(name: .long, help: "External ID, not shown in the web interface")
  var externalId: String?
}

/// Options accepted only by column and subcolumn updates.
struct ColumnUpdateOptions: ParsableArguments {
  @Option(
    name: .long,
    help: "Hide cards not moved for the last N days. Pass empty string \"\" to turn hiding off.")
  var cardHideAfterDays: String?

  @Option(
    name: .long,
    help:
      "Column ID to move this column before. Pass empty string \"\" to move it to the beginning."
  )
  var prevColumnId: String?

  @Option(
    name: .long,
    help: "Column ID to move this column after. Pass empty string \"\" to move it to the end.")
  var nextColumnId: String?

  @Option(name: .long, help: "Pause the SLA timer in this column (true or false)")
  var pauseSla: Bool?
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

  @Option(name: .long, help: "Hide cards not moved for the last N days")
  var cardHideAfterDays: Int?

  @OptionGroup var settings: ColumnSettingsOptions

  func run() async throws {
    let client = try await global.makeClient()
    let column = try await client.createColumn(
      boardId: boardId,
      title: title,
      sortOrder: sortOrder,
      type: try parseColumnType(columnType),
      wipLimit: wipLimit,
      wipLimitType: try parseWipLimitType(wipLimitType),
      colCount: colCount,
      lastMovedWarningAfterDays: settings.lastMovedWarningAfterDays,
      lastMovedWarningAfterHours: settings.lastMovedWarningAfterHours,
      lastMovedWarningAfterMinutes: settings.lastMovedWarningAfterMinutes,
      archiveAfterDays: settings.archiveAfterDays,
      cardHideAfterDays: cardHideAfterDays,
      rules: settings.rules,
      externalId: settings.externalId
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

  @Option(name: .long, help: "WIP limit value. Pass empty string \"\" to clear the limit.")
  var wipLimit: String?

  @Option(name: .long, help: "WIP limit type: 1=card count, 2=card size")
  var wipLimitType: Int?

  @Option(name: .long, help: "Number of columns to display side by side")
  var colCount: Int?

  @OptionGroup var settings: ColumnSettingsOptions

  @OptionGroup var update: ColumnUpdateOptions

  func run() async throws {
    let client = try await global.makeClient()
    let column = try await client.updateColumn(
      boardId: boardId,
      id: id,
      title: title,
      sortOrder: sortOrder,
      type: try parseColumnType(columnType),
      wipLimit: try parseNullableInt(wipLimit, option: "--wip-limit"),
      wipLimitType: try parseWipLimitType(wipLimitType),
      colCount: colCount,
      lastMovedWarningAfterDays: settings.lastMovedWarningAfterDays,
      lastMovedWarningAfterHours: settings.lastMovedWarningAfterHours,
      lastMovedWarningAfterMinutes: settings.lastMovedWarningAfterMinutes,
      archiveAfterDays: settings.archiveAfterDays,
      cardHideAfterDays: try parseNullableInt(
        update.cardHideAfterDays, option: "--card-hide-after-days"),
      rules: settings.rules,
      externalId: settings.externalId,
      prevColumnId: try parseNullableInt(update.prevColumnId, option: "--prev-column-id"),
      nextColumnId: try parseNullableInt(update.nextColumnId, option: "--next-column-id"),
      pauseSla: update.pauseSla
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

  @Option(name: .long, help: "Number of columns to display side by side")
  var colCount: Int?

  @Option(name: .long, help: "Hide cards not moved for the last N days")
  var cardHideAfterDays: Int?

  @OptionGroup var settings: ColumnSettingsOptions

  func run() async throws {
    let client = try await global.makeClient()
    let subcolumn = try await client.createSubcolumn(
      columnId: columnId,
      title: title,
      sortOrder: sortOrder,
      type: try parseColumnType(columnType),
      colCount: colCount,
      lastMovedWarningAfterDays: settings.lastMovedWarningAfterDays,
      lastMovedWarningAfterHours: settings.lastMovedWarningAfterHours,
      lastMovedWarningAfterMinutes: settings.lastMovedWarningAfterMinutes,
      archiveAfterDays: settings.archiveAfterDays,
      cardHideAfterDays: cardHideAfterDays,
      rules: settings.rules,
      externalId: settings.externalId
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

  @Option(name: .long, help: "Number of columns to display side by side")
  var colCount: Int?

  @OptionGroup var settings: ColumnSettingsOptions

  @OptionGroup var update: ColumnUpdateOptions

  func run() async throws {
    let client = try await global.makeClient()
    let subcolumn = try await client.updateSubcolumn(
      columnId: columnId,
      id: id,
      title: title,
      sortOrder: sortOrder,
      type: try parseColumnType(columnType),
      colCount: colCount,
      lastMovedWarningAfterDays: settings.lastMovedWarningAfterDays,
      lastMovedWarningAfterHours: settings.lastMovedWarningAfterHours,
      lastMovedWarningAfterMinutes: settings.lastMovedWarningAfterMinutes,
      archiveAfterDays: settings.archiveAfterDays,
      cardHideAfterDays: try parseNullableInt(
        update.cardHideAfterDays, option: "--card-hide-after-days"),
      rules: settings.rules,
      externalId: settings.externalId,
      prevColumnId: try parseNullableInt(update.prevColumnId, option: "--prev-column-id"),
      nextColumnId: try parseNullableInt(update.nextColumnId, option: "--next-column-id"),
      pauseSla: update.pauseSla
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
