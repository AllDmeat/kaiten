import ArgumentParser
import Foundation
import KaitenSDK

// MARK: - Add Service Desk External Recipient

struct AddServiceDeskExternalRecipient: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "add-sd-external-recipient",
    abstract: "Add an external recipient to a card's service desk request"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  @Option(name: .long, help: "Recipient email")
  var email: String

  func run() async throws {
    let client = try await global.makeClient()
    let recipient = try await client.addServiceDeskExternalRecipient(cardId: cardId, email: email)
    try printJSON(recipient, expand: global.expandedFields)
  }
}

// MARK: - Remove Service Desk External Recipient

struct RemoveServiceDeskExternalRecipient: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "remove-sd-external-recipient",
    abstract: "Remove an external recipient from a card's service desk request"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  @Option(name: .long, help: "Recipient email")
  var email: String

  func run() async throws {
    let client = try await global.makeClient()
    let recipient = try await client.removeServiceDeskExternalRecipient(
      cardId: cardId, email: email)
    try printJSON(recipient, expand: global.expandedFields)
  }
}
