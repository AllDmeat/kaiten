import ArgumentParser
import Foundation
import KaitenSDK

// MARK: - List Collective Score Values

struct ListCollectiveScoreValues: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-collective-score-values",
    abstract: "List collective score values of a custom property on a card"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  @Option(name: .long, help: "Custom property ID")
  var propertyId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let values = try await client.listCollectiveScoreValues(cardId: cardId, propertyId: propertyId)
    try printJSON(values, expand: global.expandedFields)
  }
}

// MARK: - Create Collective Score Value

struct CreateCollectiveScoreValue: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "create-collective-score-value",
    abstract: "Create a collective score value for a custom property on a card"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  @Option(name: .long, help: "Custom property ID")
  var propertyId: Int

  @Option(name: .long, help: "Score value (1 to 512 characters)")
  var value: String

  func run() async throws {
    let client = try await global.makeClient()
    let scoreValue = try await client.createCollectiveScoreValue(
      cardId: cardId, propertyId: propertyId, value: value)
    try printJSON(scoreValue, expand: global.expandedFields)
  }
}

// MARK: - Update Collective Score Value

struct UpdateCollectiveScoreValue: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-collective-score-value",
    abstract: "Update a collective score value of a custom property on a card"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  @Option(name: .long, help: "Custom property ID")
  var propertyId: Int

  @Option(name: .long, help: "Score value ID")
  var scoreValueId: Int

  @Option(
    name: .long,
    help: "Score value (1 to 512 characters). Pass empty string \"\" to clear the value."
  )
  var value: String?

  func run() async throws {
    let client = try await global.makeClient()
    let scoreValue = try await client.updateCollectiveScoreValue(
      cardId: cardId,
      propertyId: propertyId,
      scoreValueId: scoreValueId,
      // Map String? → String??:
      //   nil (not passed)  → nil           (omit field, server leaves value unchanged)
      //   ""  (empty)       → .some(nil)    (send JSON null, server clears the value)
      //   "value"           → .some("value") (send string, server sets the value)
      value: value.map { $0.isEmpty ? nil : $0 }
    )
    try printJSON(scoreValue, expand: global.expandedFields)
  }
}
