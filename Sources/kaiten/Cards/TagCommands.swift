import ArgumentParser
import Foundation
import KaitenSDK

// MARK: - List Card Tags

struct ListCardTags: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-card-tags",
    abstract: "List tags on a card"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let tags = try await client.listCardTags(cardId: cardId)
    try printJSON(tags, expand: global.expandedFields)
  }
}

// MARK: - Add Card Tag

struct AddCardTag: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "add-card-tag",
    abstract: "Add a tag to a card"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  @Option(name: .long, help: "Tag name")
  var name: String

  func run() async throws {
    let client = try await global.makeClient()
    let tag = try await client.addCardTag(cardId: cardId, name: name)
    try printJSON(tag, expand: global.expandedFields)
  }
}

// MARK: - Remove Card Tag

struct RemoveCardTag: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "remove-card-tag",
    abstract: "Remove a tag from a card"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  @Option(name: .long, help: "Tag ID")
  var tagId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let deletedId = try await client.removeCardTag(cardId: cardId, tagId: tagId)
    try printJSON(["id": deletedId], expand: global.expandedFields)
  }
}
