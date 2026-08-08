import ArgumentParser
import KaitenSDK

// MARK: - List Tree Entity Roles

struct ListTreeEntityRoles: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-tree-entity-roles",
    abstract: "List tree entity roles of the company",
    discussion: """
      Kaiten documents this endpoint as under active development, so its response format is \
      subject to change.
      """
  )

  @OptionGroup var global: GlobalOptions

  func run() async throws {
    let client = try await global.makeClient()
    let roles = try await client.listTreeEntityRoles()
    try printJSON(roles, expand: global.expandedFields)
  }
}
