import ArgumentParser
import KaitenSDK

struct ListCardAllowedUsers: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-card-allowed-users",
    abstract: "List users with access to a card, ordered by user id",
    discussion: """
      The API accepts --search and --order-by but has been observed to ignore them: the list \
      is not filtered and stays ordered by id.
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

  @Option(name: .long, help: "Maximum number of users to return (1-100, default 100)")
  var limit: Int?

  @Option(name: .long, help: "Number of users to skip")
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
