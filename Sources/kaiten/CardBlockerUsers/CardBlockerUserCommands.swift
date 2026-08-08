import ArgumentParser
import Foundation
import KaitenSDK

// MARK: - List Card Blocker Users

struct ListCardBlockerUsers: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-card-blocker-users",
    abstract: "List users assigned to a card blocker"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Blocker ID")
  var blockerId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let users = try await client.listCardBlockerUsers(blockerId: blockerId)
    try printJSON(users, expand: global.expandedFields)
  }
}

// MARK: - Add Card Blocker User

struct AddCardBlockerUser: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "add-card-blocker-user",
    abstract: "Add a user to a card blocker"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Blocker ID")
  var blockerId: Int

  @Option(name: .long, help: "User ID")
  var userId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let user = try await client.addCardBlockerUser(blockerId: blockerId, userId: userId)
    try printJSON(user, expand: global.expandedFields)
  }
}

// MARK: - Remove Card Blocker User

struct RemoveCardBlockerUser: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "remove-card-blocker-user",
    abstract: "Remove a user from a card blocker"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Blocker ID")
  var blockerId: Int

  @Option(name: .long, help: "User ID")
  var userId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let removed = try await client.removeCardBlockerUser(blockerId: blockerId, userId: userId)
    try printJSON(removed, expand: global.expandedFields)
  }
}

// MARK: - Get Current User Blockers

struct GetCurrentUserBlockers: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "get-current-user-blockers",
    abstract: "Get cards blocked on the current user",
    discussion: """
      Prints an object with `blocked_cards` and `summary`. When the current user has no \
      blockers the API answers with an empty array instead of the documented object; the \
      CLI maps that to the object shape: `blocked_cards` is empty and `summary` is absent.
      """
  )

  @OptionGroup var global: GlobalOptions

  func run() async throws {
    let client = try await global.makeClient()
    let blockers = try await client.getCurrentUserBlockers()
    try printJSON(blockers, expand: global.expandedFields)
  }
}
