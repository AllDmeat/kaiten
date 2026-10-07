import ArgumentParser
import KaitenSDK

// MARK: - Spaces

struct ListSpaces: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-spaces",
    abstract: "List spaces"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Maximum number of spaces to return (1-100, default 100)")
  var limit: Int?

  @Option(name: .long, help: "Number of spaces to skip")
  var offset: Int?

  func run() async throws {
    let client = try await global.makeClient()
    let spaces = try await client.listSpaces(limit: limit, offset: offset)
    try printJSON(spaces, expand: global.expandedFields)
  }
}
