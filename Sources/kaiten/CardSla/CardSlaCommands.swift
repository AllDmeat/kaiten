import ArgumentParser
import KaitenSDK

struct GetCardSlaMeasurements: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "get-card-sla-measurements",
    abstract: "Get card SLA measurements",
    discussion: """
      The API computes SLA measurements only for service desk request cards; any other card, \
      and any archived card, is answered with HTTP 400.
      """
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let measurements = try await client.getCardSlaMeasurements(cardId: cardId)
    try printJSON(measurements, expand: global.expandedFields)
  }
}
