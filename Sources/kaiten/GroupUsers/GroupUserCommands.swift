import ArgumentParser
import KaitenSDK

// MARK: - List Group Users

struct ListGroupUsers: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-group-users",
    abstract: "List users in a company group"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Group UID")
  var groupUid: String

  func run() async throws {
    let client = try await global.makeClient()
    let users = try await client.listGroupUsers(groupUid: groupUid)
    try printJSON(users, expand: global.expandedFields)
  }
}

// MARK: - Add Group User

struct AddGroupUser: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "add-group-user",
    abstract: "Add a user to a company group"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Group UID")
  var groupUid: String

  @Option(name: .long, help: "User ID")
  var userId: Int

  @Option(name: .long, help: "Request id if the addition is an answer to an access request")
  var requestId: String?

  @Option(
    name: .long,
    help: "Operator's comment if the addition is an answer to an access request (1-1024 characters)"
  )
  var operatorComment: String?

  func run() async throws {
    let client = try await global.makeClient()
    let user = try await client.addUserToGroup(
      groupUid: groupUid,
      userId: userId,
      requestId: requestId,
      operatorComment: operatorComment
    )
    try printJSON(user, expand: global.expandedFields)
  }
}

// MARK: - Remove Group User

struct RemoveGroupUser: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "remove-group-user",
    abstract: "Remove a user from a company group"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Group UID")
  var groupUid: String

  @Option(name: .long, help: "User ID")
  var userId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let user = try await client.removeUserFromGroup(groupUid: groupUid, userId: userId)
    try printJSON(user, expand: global.expandedFields)
  }
}
