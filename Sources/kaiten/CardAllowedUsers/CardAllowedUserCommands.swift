import ArgumentParser
import KaitenSDK

struct ListCardAllowedUsers: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-card-allowed-users",
    abstract: "List users with access to a card",
    discussion: """
      The API accepts --search, --order-by, --limit and --offset but has been observed to \
      ignore them: the full list is returned regardless.
      """
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  @Option(
    name: .long,
    help: "Type of users to return: sd-owners (service-desk users), virtual-users, mention")
  var type: String?

  @Option(name: .long, help: "Filter by full name, email or username")
  var search: String?

  @Option(name: .long, help: "The field to sort by")
  var orderBy: String?

  @Option(name: .long, help: "Filter by role")
  var role: Int?

  @Option(name: .long, help: "Maximum amount of users in response")
  var limit: Int?

  @Option(name: .long, help: "Number of records to skip")
  var offset: Int?

  func run() async throws {
    let client = try await global.makeClient()
    let users = try await client.listCardAllowedUsers(
      cardId: cardId,
      type: type,
      search: search,
      orderBy: orderBy,
      role: role,
      limit: limit,
      offset: offset
    )
    try printJSON(users, expand: global.expandedFields)
  }
}
