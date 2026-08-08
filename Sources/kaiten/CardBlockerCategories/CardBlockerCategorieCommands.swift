import ArgumentParser
import Foundation
import KaitenSDK

// MARK: - List Blocker Categories

struct ListBlockerCategories: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-blocker-categories",
    abstract: "List blocker categories in the company"
  )

  @OptionGroup var global: GlobalOptions

  func run() async throws {
    let client = try await global.makeClient()
    let categories = try await client.listBlockerCategories()
    try printJSON(categories)
  }
}

// MARK: - Add Blocker Category

struct AddBlockerCategory: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "add-blocker-category",
    abstract: "Add a category to a card blocker"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Blocker ID")
  var blockerId: Int

  @Option(name: .long, help: "Blocker category name")
  var name: String

  func run() async throws {
    let client = try await global.makeClient()
    let category = try await client.addBlockerCategory(blockerId: blockerId, name: name)
    try printJSON(category)
  }
}

// MARK: - Remove Blocker Category

struct RemoveBlockerCategory: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "remove-blocker-category",
    abstract: "Remove a category from a card blocker"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Blocker ID")
  var blockerId: Int

  @Option(name: .long, help: "Blocker category UID")
  var categoryUid: String

  func run() async throws {
    let client = try await global.makeClient()
    let removed = try await client.removeBlockerCategory(
      blockerId: blockerId, categoryUid: categoryUid)
    try printJSON(removed)
  }
}
