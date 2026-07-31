import ArgumentParser
import KaitenSDK

struct GetCardBaselines: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "get-card-baselines",
    abstract: "Get card baselines"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let baselines = try await client.getCardBaselines(cardId: cardId)
    try printJSON(baselines, expand: global.expandedFields)
  }
}
