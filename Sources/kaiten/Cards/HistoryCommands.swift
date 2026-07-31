import ArgumentParser
import KaitenSDK

struct GetCardHistory: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "get-card-history",
    abstract: "Get card location history"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let history = try await client.getCardLocationHistory(cardId: cardId)
    try printJSON(history, expand: global.expandedFields)
  }
}
