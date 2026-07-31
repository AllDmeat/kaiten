import ArgumentParser
import KaitenSDK

struct CreateChecklist: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "create-checklist",
    abstract: "Create a checklist on a card"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  @Option(name: .long, help: "Checklist name")
  var name: String

  @Option(name: .long, help: "Position (sort order)")
  var sortOrder: Double?

  func run() async throws {
    let client = try await global.makeClient()
    let checklist = try await client.createChecklist(
      cardId: cardId, name: name, sortOrder: sortOrder)
    try printJSON(checklist, expand: global.expandedFields)
  }
}

// MARK: - Checklists

struct GetChecklist: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "get-checklist",
    abstract: "Retrieve a card checklist"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  @Option(name: .long, help: "Checklist ID")
  var checklistId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let checklist = try await client.getChecklist(cardId: cardId, checklistId: checklistId)
    try printJSON(checklist, expand: global.expandedFields)
  }
}

struct RemoveChecklist: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "remove-checklist",
    abstract: "Remove a checklist from a card"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  @Option(name: .long, help: "Checklist ID")
  var checklistId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let deletedId = try await client.removeChecklist(cardId: cardId, checklistId: checklistId)
    try printJSON(["id": deletedId], expand: global.expandedFields)
  }
}

struct UpdateChecklist: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-checklist",
    abstract: "Update a card checklist"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  @Option(name: .long, help: "Checklist ID")
  var checklistId: Int

  @Option(name: .long, help: "New checklist name")
  var name: String?

  @Option(name: .long, help: "New sort order")
  var sortOrder: Double?

  @Option(name: .long, help: "Move checklist to another card (card ID)")
  var moveToCardId: Int?

  func run() async throws {
    let client = try await global.makeClient()
    let checklist = try await client.updateChecklist(
      cardId: cardId,
      checklistId: checklistId,
      name: name,
      sortOrder: sortOrder,
      moveToCardId: moveToCardId
    )
    try printJSON(checklist, expand: global.expandedFields)
  }
}

// MARK: - Checklist Items

struct UpdateChecklistItem: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-checklist-item",
    abstract: "Update a checklist item on a card"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

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
      cardId: cardId,
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

struct CreateChecklistItem: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "create-checklist-item",
    abstract: "Add an item to a checklist"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  @Option(name: .long, help: "Checklist ID")
  var checklistId: Int

  @Option(name: .long, help: "Item text")
  var text: String

  @Option(name: .long, help: "Sort order")
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
      cardId: cardId,
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

struct RemoveChecklistItem: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "remove-checklist-item",
    abstract: "Remove an item from a checklist"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  @Option(name: .long, help: "Checklist ID")
  var checklistId: Int

  @Option(name: .long, help: "Checklist item ID")
  var itemId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let deletedId = try await client.removeChecklistItem(
      cardId: cardId,
      checklistId: checklistId,
      itemId: itemId
    )
    try printJSON(["id": deletedId], expand: global.expandedFields)
  }
}
