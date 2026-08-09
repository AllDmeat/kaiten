import ArgumentParser
import KaitenSDK

// MARK: - Space Template Checklist Items

struct CreateSpaceTemplateChecklistItem: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "create-space-template-checklist-item",
    abstract: "Create an item in a space template checklist"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Space UID")
  var spaceUid: String

  @Option(name: .long, help: "Template checklist UID")
  var templateChecklistUid: String

  @Option(name: .long, help: "Item text (1-4096 characters)")
  var text: String

  @Option(name: .long, help: "Sort order (must be > 0)")
  var sortOrder: Double?

  func run() async throws {
    let client = try await global.makeClient()
    let item = try await client.createSpaceTemplateChecklistItem(
      spaceUid: spaceUid,
      templateChecklistUid: templateChecklistUid,
      text: text,
      sortOrder: sortOrder
    )
    try printJSON(item, expand: global.expandedFields)
  }
}

struct UpdateSpaceTemplateChecklistItem: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-space-template-checklist-item",
    abstract: "Update an item in a space template checklist"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Space UID")
  var spaceUid: String

  @Option(name: .long, help: "Template checklist UID")
  var templateChecklistUid: String

  @Option(name: .long, help: "Template checklist item UID")
  var itemUid: String

  @Option(name: .long, help: "Item text (1-4096 characters)")
  var text: String?

  @Option(name: .long, help: "Sort order (must be > 0)")
  var sortOrder: Double?

  func run() async throws {
    let client = try await global.makeClient()
    let item = try await client.updateSpaceTemplateChecklistItem(
      spaceUid: spaceUid,
      templateChecklistUid: templateChecklistUid,
      itemUid: itemUid,
      text: text,
      sortOrder: sortOrder
    )
    try printJSON(item, expand: global.expandedFields)
  }
}

struct RemoveSpaceTemplateChecklistItem: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "remove-space-template-checklist-item",
    abstract: "Remove an item from a space template checklist"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Space UID")
  var spaceUid: String

  @Option(name: .long, help: "Template checklist UID")
  var templateChecklistUid: String

  @Option(name: .long, help: "Template checklist item UID")
  var itemUid: String

  func run() async throws {
    let client = try await global.makeClient()
    let deletedUid = try await client.removeSpaceTemplateChecklistItem(
      spaceUid: spaceUid,
      templateChecklistUid: templateChecklistUid,
      itemUid: itemUid
    )
    try printJSON(["uid": deletedUid], expand: global.expandedFields)
  }
}
