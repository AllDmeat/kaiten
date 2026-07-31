import ArgumentParser
import Foundation
import KaitenSDK

// MARK: - List External Links

struct ListExternalLinks: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-external-links",
    abstract: "List external links on a card"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let links = try await client.listExternalLinks(cardId: cardId)
    try printJSON(links, expand: global.expandedFields)
  }
}

// MARK: - Create External Link

struct CreateExternalLink: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "create-external-link",
    abstract: "Add an external link to a card"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  @Option(name: .long, help: "URL")
  var url: String

  @Option(name: .long, help: "Description")
  var description: String?

  func run() async throws {
    let client = try await global.makeClient()
    let link = try await client.createExternalLink(
      cardId: cardId, url: url, description: description)
    try printJSON(link, expand: global.expandedFields)
  }
}

// MARK: - Update External Link

struct UpdateExternalLink: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-external-link",
    abstract: "Update an external link on a card"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  @Option(name: .long, help: "External link ID")
  var linkId: Int

  @Option(name: .long, help: "URL")
  var url: String?

  @Option(name: .long, help: "Description")
  var description: String?

  func run() async throws {
    let client = try await global.makeClient()
    let link = try await client.updateExternalLink(
      cardId: cardId, linkId: linkId, url: url, description: description)
    try printJSON(link, expand: global.expandedFields)
  }
}

// MARK: - Remove External Link

struct RemoveExternalLink: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "remove-external-link",
    abstract: "Remove an external link from a card"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  @Option(name: .long, help: "External link ID")
  var linkId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let deletedId = try await client.removeExternalLink(cardId: cardId, linkId: linkId)
    try printJSON(["id": deletedId], expand: global.expandedFields)
  }
}
