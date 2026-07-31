import ArgumentParser
import KaitenSDK

struct GetSprintSummary: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "get-sprint-summary",
    abstract: "Get sprint summary by ID"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Sprint ID")
  var id: Int

  @Flag(name: .long, help: "Exclude deleted cards")
  var excludeDeletedCards: Bool = false

  func run() async throws {
    let client = try await global.makeClient()
    let summary = try await client.getSprintSummary(
      id: id, excludeDeletedCards: excludeDeletedCards ? true : nil)
    try printJSON(summary, expand: global.expandedFields)
  }
}
