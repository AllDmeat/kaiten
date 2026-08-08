import ArgumentParser
import Foundation
import KaitenSDK

// MARK: - List Space Template Checklists

struct ListSpaceTemplateChecklists: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-space-template-checklists",
    abstract: "List template checklists in a space"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Space UID")
  var spaceUid: String

  func run() async throws {
    let client = try await global.makeClient()
    let checklists = try await client.listSpaceTemplateChecklists(spaceUid: spaceUid)
    try printJSON(checklists)
  }
}

// MARK: - Create Space Template Checklist

struct CreateSpaceTemplateChecklist: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "create-space-template-checklist",
    abstract: "Create a template checklist in a space"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Space UID")
  var spaceUid: String

  @Option(name: .long, help: "Template checklist name (1 to 512 characters)")
  var name: String?

  @Option(name: .long, help: "Position (greater than 0)")
  var sortOrder: Double?

  func run() async throws {
    let client = try await global.makeClient()
    let checklist = try await client.createSpaceTemplateChecklist(
      spaceUid: spaceUid,
      name: name,
      sortOrder: sortOrder
    )
    try printJSON(checklist)
  }
}

// MARK: - Update Space Template Checklist

struct UpdateSpaceTemplateChecklist: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-space-template-checklist",
    abstract: "Update a space template checklist"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Space UID")
  var spaceUid: String

  @Option(name: .long, help: "Template checklist UID")
  var templateChecklistUid: String

  @Option(name: .long, help: "Template checklist name (1 to 512 characters)")
  var name: String?

  @Option(name: .long, help: "Position (greater than 0)")
  var sortOrder: Double?

  @Option(
    name: .long,
    help: "The space_uid request attribute. The documentation does not describe its effect")
  var newSpaceUid: String?

  func run() async throws {
    let client = try await global.makeClient()
    let checklist = try await client.updateSpaceTemplateChecklist(
      spaceUid: spaceUid,
      templateChecklistUid: templateChecklistUid,
      name: name,
      sortOrder: sortOrder,
      newSpaceUid: newSpaceUid
    )
    try printJSON(checklist)
  }
}

// MARK: - Remove Space Template Checklist

struct RemoveSpaceTemplateChecklist: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "remove-space-template-checklist",
    abstract: "Remove a template checklist from a space"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Space UID")
  var spaceUid: String

  @Option(name: .long, help: "Template checklist UID")
  var templateChecklistUid: String

  func run() async throws {
    let client = try await global.makeClient()
    let response = try await client.removeSpaceTemplateChecklist(
      spaceUid: spaceUid,
      templateChecklistUid: templateChecklistUid
    )
    try printJSON(response)
  }
}
