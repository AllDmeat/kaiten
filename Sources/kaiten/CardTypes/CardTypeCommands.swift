import ArgumentParser
import KaitenSDK

struct ListCardTypes: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-card-types",
    abstract: "List card types"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Limit the number of card types returned (max 100)")
  var limit: Int?

  @Option(name: .long, help: "Offset for pagination")
  var offset: Int?

  func run() async throws {
    let client = try await global.makeClient()
    let types = try await client.listCardTypes(limit: limit, offset: offset)
    try printJSON(types, expand: global.expandedFields)
  }
}
