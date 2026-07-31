import ArgumentParser
import KaitenSDK

struct ListSprints: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-sprints",
    abstract: "List sprints"
  )

  @OptionGroup var global: GlobalOptions

  @Flag(name: .long, help: "Filter by active sprints")
  var active: Bool = false

  @Option(name: .long, help: "Limit the number of sprints returned (max 100)")
  var limit: Int?

  @Option(name: .long, help: "Offset for pagination")
  var offset: Int?

  func run() async throws {
    let client = try await global.makeClient()
    let sprints = try await client.listSprints(
      active: active ? true : nil, limit: limit, offset: offset)
    try printJSON(sprints, expand: global.expandedFields)
  }
}
