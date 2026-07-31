import ArgumentParser
import Foundation
import KaitenSDK

// MARK: - List Card Children

struct ListCardChildren: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-card-children",
    abstract: "List children of a card"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let children = try await client.listCardChildren(cardId: cardId)
    try printJSON(children, expand: global.expandedFields)
  }
}

// MARK: - Add Card Child

struct AddCardChild: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "add-card-child",
    abstract: "Add a child card to a parent card"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Parent Card ID")
  var cardId: Int

  @Option(name: .long, help: "Child Card ID")
  var childCardId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let child = try await client.addCardChild(cardId: cardId, childCardId: childCardId)
    try printJSON(child, expand: global.expandedFields)
  }
}

// MARK: - Remove Card Child

struct RemoveCardChild: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "remove-card-child",
    abstract: "Remove a child card from a parent card"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Parent Card ID")
  var cardId: Int

  @Option(name: .long, help: "Child Card ID")
  var childCardId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let deletedId = try await client.removeCardChild(cardId: cardId, childCardId: childCardId)
    try printJSON(["id": deletedId], expand: global.expandedFields)
  }
}
