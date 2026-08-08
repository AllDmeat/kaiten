import ArgumentParser
import KaitenSDK

// MARK: - Groups

func parseGroupCondition(_ rawValue: Int?) throws -> GroupCondition? {
  guard let rawValue else { return nil }
  let condition = GroupCondition(rawValue: rawValue)
  guard GroupCondition.allCases.contains(condition) else {
    throw ValidationError(
      "Invalid group condition: \(rawValue). Allowed values: 1 (active), 2 (inactive)")
  }
  return condition
}

// MARK: - List Groups

struct ListGroups: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-groups",
    abstract: "List user groups in the company",
    discussion: """
      The result is paginated only when --limit or --offset is present and \
      --with-tree-entities is not.
      """
  )

  @OptionGroup var global: GlobalOptions

  @Flag(name: .long, help: "Add tree entities for each group")
  var withTreeEntities: Bool = false

  @Flag(name: .long, help: "Add users count for each group")
  var withUsersCount: Bool = false

  @Flag(name: .long, help: "Add sync attribute for each group")
  var withSyncGroupAttribute: Bool = false

  @Option(name: .long, help: "Group condition: 1 = active, 2 = inactive")
  var condition: Int?

  @Option(name: .long, help: "Search query")
  var query: String?

  @Option(name: .long, help: "Maximum amount of records (default 100)")
  var limit: Int?

  @Option(name: .long, help: "Number of records to skip")
  var offset: Int?

  func run() async throws {
    let client = try await global.makeClient()
    let groups = try await client.listGroups(
      withTreeEntities: withTreeEntities ? true : nil,
      withUsersCount: withUsersCount ? true : nil,
      withSyncGroupAttribute: withSyncGroupAttribute ? true : nil,
      condition: try parseGroupCondition(condition),
      query: query,
      limit: limit,
      offset: offset
    )
    try printJSON(groups, expand: global.expandedFields)
  }
}

// MARK: - Create Group

struct CreateGroup: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "create-group",
    abstract: "Create a user group in the company"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Group name (1 to 512 characters)")
  var name: String

  @Option(name: .long, help: "Group permissions bit mask; sum the documented values to combine")
  var permissions: Int?

  @Flag(name: .long, help: "Allow adding all users of the group to cards in group spaces")
  var addToCardsAndSpacesEnabled: Bool = false

  func run() async throws {
    let client = try await global.makeClient()
    let group = try await client.createGroup(
      name: name,
      permissions: permissions,
      addToCardsAndSpacesEnabled: addToCardsAndSpacesEnabled ? true : nil
    )
    try printJSON(group, expand: global.expandedFields)
  }
}

// MARK: - Get Group

struct GetGroup: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "get-group",
    abstract: "Get a user group"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Group UID")
  var uid: String

  func run() async throws {
    let client = try await global.makeClient()
    let group = try await client.getGroup(uid: uid)
    try printJSON(group, expand: global.expandedFields)
  }
}

// MARK: - Update Group

struct UpdateGroup: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-group",
    abstract: "Update a user group"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Group UID")
  var uid: String

  @Option(name: .long, help: "Group name (1 to 512 characters)")
  var name: String?

  @Option(name: .long, help: "Group permissions bit mask; sum the documented values to combine")
  var permissions: Int?

  @Option(name: .long, help: "Allow adding all users of the group to cards in group spaces")
  var addToCardsAndSpacesEnabled: Bool?

  func run() async throws {
    let client = try await global.makeClient()
    let group = try await client.updateGroup(
      uid: uid,
      name: name,
      permissions: permissions,
      addToCardsAndSpacesEnabled: addToCardsAndSpacesEnabled
    )
    try printJSON(group, expand: global.expandedFields)
  }
}

// MARK: - Remove Group

struct RemoveGroup: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "remove-group",
    abstract: "Remove a user group",
    discussion: "Prints the removed group."
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Group UID")
  var uid: String

  func run() async throws {
    let client = try await global.makeClient()
    let group = try await client.removeGroup(uid: uid)
    try printJSON(group, expand: global.expandedFields)
  }
}
