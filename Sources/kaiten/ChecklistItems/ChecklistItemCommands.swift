import ArgumentParser
import KaitenSDK

// MARK: - Checklist Items (checklist-scoped endpoints)

struct AddItemToChecklist: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "add-item-to-checklist",
    abstract: "Add an item to a checklist addressed by checklist ID"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Checklist ID")
  var checklistId: Int

  @Option(name: .long, help: "Item text (1-4096 characters)")
  var text: String

  @Option(name: .long, help: "Sort order (must be > 0)")
  var sortOrder: Double?

  @Option(name: .long, help: "Checked state")
  var checked: Bool?

  @Option(name: .long, help: "Due date (YYYY-MM-DD)")
  var dueDate: String?

  @Option(name: .long, help: "Responsible user ID")
  var responsibleId: Int?

  func run() async throws {
    let client = try await global.makeClient()
    let item = try await client.createChecklistItem(
      checklistId: checklistId,
      text: text,
      sortOrder: sortOrder,
      checked: checked,
      dueDate: dueDate,
      responsibleId: responsibleId
    )
    try printJSON(item, expand: global.expandedFields)
  }
}

struct UpdateItemInChecklist: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-item-in-checklist",
    abstract: "Update a checklist item addressed by checklist ID"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Checklist ID")
  var checklistId: Int

  @Option(name: .long, help: "Checklist item ID")
  var itemId: Int

  @Option(name: .long, help: "Item text (max 4096 characters)")
  var text: String?

  @Option(name: .long, help: "Sort order (must be > 0)")
  var sortOrder: Double?

  @Option(name: .long, help: "Move to another checklist ID")
  var moveToChecklistId: Int?

  @Option(name: .long, help: "Checked state")
  var checked: Bool?

  @Option(name: .long, help: "Due date (YYYY-MM-DD)")
  var dueDate: String?

  @Option(name: .long, help: "Responsible user ID")
  var responsibleId: Int?

  func run() async throws {
    let client = try await global.makeClient()
    let item = try await client.updateChecklistItem(
      checklistId: checklistId,
      itemId: itemId,
      text: text,
      sortOrder: sortOrder,
      moveToChecklistId: moveToChecklistId,
      checked: checked,
      dueDate: dueDate,
      responsibleId: responsibleId
    )
    try printJSON(item, expand: global.expandedFields)
  }
}

struct RemoveItemFromChecklist: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "remove-item-from-checklist",
    abstract: "Remove a checklist item addressed by checklist ID"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Checklist ID")
  var checklistId: Int

  @Option(name: .long, help: "Checklist item ID")
  var itemId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let deletedId = try await client.removeChecklistItem(
      checklistId: checklistId,
      itemId: itemId
    )
    try printJSON(["id": deletedId], expand: global.expandedFields)
  }
}
