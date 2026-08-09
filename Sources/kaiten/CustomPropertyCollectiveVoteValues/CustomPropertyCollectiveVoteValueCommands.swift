import ArgumentParser
import KaitenSDK

// MARK: - List Collective Vote Values

struct ListCollectiveVoteValues: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-collective-vote-values",
    abstract: "List collective vote values on a card for a custom property"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  @Option(name: .long, help: "Custom property ID")
  var propertyId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let values = try await client.listCollectiveVoteValues(cardId: cardId, propertyId: propertyId)
    try printJSON(values, expand: global.expandedFields)
  }
}

// MARK: - Create Collective Vote Value

struct CreateCollectiveVoteValue: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "create-collective-vote-value",
    abstract: "Create a collective vote value on a card"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  @Option(name: .long, help: "Custom property ID")
  var propertyId: Int

  @Option(name: .long, help: "Vote value for a scale or rating property")
  var numberVote: Int?

  @Option(name: .long, help: "Vote emoji for an emoji-set property (1...12 characters)")
  var emojiVote: String?

  func run() async throws {
    let client = try await global.makeClient()
    let value = try await client.createCollectiveVoteValue(
      cardId: cardId, propertyId: propertyId, numberVote: numberVote, emojiVote: emojiVote)
    try printJSON(value, expand: global.expandedFields)
  }
}

// MARK: - Update Collective Vote Value

struct UpdateCollectiveVoteValue: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-collective-vote-value",
    abstract: "Update a collective vote value on a card"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  @Option(name: .long, help: "Custom property ID")
  var propertyId: Int

  @Option(name: .long, help: "Vote value ID")
  var voteValueId: Int

  @Option(
    name: .long,
    help: "Vote value for a scale or rating property. Pass empty string \"\" to clear the vote."
  )
  var numberVote: String?

  func run() async throws {
    let client = try await global.makeClient()
    // Map String? → Double??:
    //   nil (not passed)  → nil          (omit field, server leaves value unchanged)
    //   ""  (empty)       → .some(nil)   (send JSON null, server clears the vote)
    //   "3"               → .some(3.0)   (send number, server sets the vote)
    let parsedNumberVote: Double?? = try numberVote.map { raw in
      if raw.isEmpty { return nil }
      guard let value = Double(raw) else {
        throw ValidationError("Invalid number-vote value: '\(raw)'")
      }
      return value
    }
    let value = try await client.updateCollectiveVoteValue(
      cardId: cardId, propertyId: propertyId, voteValueId: voteValueId,
      numberVote: parsedNumberVote)
    try printJSON(value, expand: global.expandedFields)
  }
}

// MARK: - Remove Collective Vote Value

struct RemoveCollectiveVoteValue: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "remove-collective-vote-value",
    abstract: "Remove a collective vote value from a card"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  @Option(name: .long, help: "Custom property ID")
  var propertyId: Int

  @Option(name: .long, help: "Vote value ID")
  var voteValueId: Int

  @Option(name: .long, help: "Emoji to remove, for an emoji-set property (1...12 characters)")
  var emojiVote: String?

  func run() async throws {
    let client = try await global.makeClient()
    let value = try await client.deleteCollectiveVoteValue(
      cardId: cardId, propertyId: propertyId, voteValueId: voteValueId, emojiVote: emojiVote)
    try printJSON(value, expand: global.expandedFields)
  }
}
