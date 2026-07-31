import ArgumentParser
import Foundation
import KaitenSDK

// MARK: - List Card Blockers

struct ListCardBlockers: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-card-blockers",
    abstract: "List blockers on a card"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let blockers = try await client.listCardBlockers(cardId: cardId)
    try printJSON(blockers, expand: global.expandedFields)
  }
}

// MARK: - Create Card Blocker

struct CreateCardBlocker: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "create-card-blocker",
    abstract: "Create a blocker on a card"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  @Option(name: .long, help: "Block reason")
  var reason: String?

  @Option(name: .long, help: "Blocker card ID")
  var blockerCardId: Int?

  func run() async throws {
    let client = try await global.makeClient()
    let blocker = try await client.createCardBlocker(
      cardId: cardId, reason: reason, blockerCardId: blockerCardId)
    try printJSON(blocker, expand: global.expandedFields)
  }
}

// MARK: - Update Card Blocker

struct UpdateCardBlocker: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-card-blocker",
    abstract: "Update a card blocker"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  @Option(name: .long, help: "Blocker ID")
  var blockerId: Int

  @Option(name: .long, help: "Block reason")
  var reason: String?

  @Option(name: .long, help: "Blocker card ID")
  var blockerCardId: Int?

  func run() async throws {
    let client = try await global.makeClient()
    let blocker = try await client.updateCardBlocker(
      cardId: cardId, blockerId: blockerId, reason: reason, blockerCardId: blockerCardId)
    try printJSON(blocker, expand: global.expandedFields)
  }
}

// MARK: - Delete Card Blocker

struct DeleteCardBlocker: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "delete-card-blocker",
    abstract: "Delete a card blocker"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  @Option(name: .long, help: "Blocker ID")
  var blockerId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let blocker = try await client.deleteCardBlocker(cardId: cardId, blockerId: blockerId)
    try printJSON(blocker, expand: global.expandedFields)
  }
}
