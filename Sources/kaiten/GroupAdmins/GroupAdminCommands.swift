import ArgumentParser
import KaitenSDK

// MARK: - List Group Admins

struct ListGroupAdmins: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-group-admins",
    abstract: "List admins of a group"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Group UID")
  var groupUid: String

  func run() async throws {
    let client = try await global.makeClient()
    let admins = try await client.listGroupAdmins(groupUid: groupUid)
    try printJSON(admins, expand: global.expandedFields)
  }
}

// MARK: - Add Group Admin

struct AddGroupAdmin: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "add-group-admin",
    abstract: "Add a user as an admin of a group"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Group UID")
  var groupUid: String

  @Option(name: .long, help: "User ID")
  var userId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let admin = try await client.addGroupAdmin(groupUid: groupUid, userId: userId)
    try printJSON(admin, expand: global.expandedFields)
  }
}

// MARK: - Remove Group Admin

struct RemoveGroupAdmin: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "remove-group-admin",
    abstract: "Remove an admin from a group"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Group UID")
  var groupUid: String

  @Option(name: .long, help: "User ID")
  var userId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let admin = try await client.removeGroupAdmin(groupUid: groupUid, userId: userId)
    try printJSON(admin, expand: global.expandedFields)
  }
}
