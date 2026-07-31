import ArgumentParser
import KaitenSDK

// MARK: - Spaces

struct ListSpaces: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-spaces",
    abstract: "List all spaces"
  )

  @OptionGroup var global: GlobalOptions

  func run() async throws {
    let client = try await global.makeClient()
    let spaces = try await client.listSpaces()
    try printJSON(spaces, expand: global.expandedFields)
  }
}
