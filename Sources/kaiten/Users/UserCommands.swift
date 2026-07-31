import ArgumentParser
import KaitenSDK

struct ListUsers: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-users",
    abstract: "List users in the company"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Type of users to return")
  var type: String?

  @Option(name: .long, help: "Search query")
  var query: String?

  @Option(name: .long, help: "Comma-separated user IDs")
  var ids: String?

  @Option(name: .long, help: "Limit the number of users returned (max 100)")
  var limit: Int?

  @Option(name: .long, help: "Offset for pagination")
  var offset: Int?

  @Flag(name: .long, help: "Include inactive users")
  var includeInactive: Bool = false

  func run() async throws {
    let client = try await global.makeClient()
    let users = try await client.listUsers(
      type: type,
      query: query,
      ids: ids,
      limit: limit,
      offset: offset,
      includeInactive: includeInactive ? true : nil
    )
    try printJSON(users, expand: global.expandedFields)
  }
}

struct GetCurrentUser: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "get-current-user",
    abstract: "Get the currently authenticated user"
  )

  @OptionGroup var global: GlobalOptions

  func run() async throws {
    let client = try await global.makeClient()
    let user = try await client.getCurrentUser()
    try printJSON(user, expand: global.expandedFields)
  }
}
