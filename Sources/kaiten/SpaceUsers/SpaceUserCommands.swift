import ArgumentParser
import Foundation
import KaitenSDK

/// Shared help for the `--role-id` option of the invite and update commands.
private let spaceUserRoleIdHelp = ArgumentHelp(
  "Role id. Preset roles: reader 06ccb31f-426b-4fa3-b7e5-861daee95696, "
    + "writer a431ed00-1b32-4cc7-92b6-85e4bc7de40e, admin 07ea3efc-a004-4d31-8683-4bb2084e209b")

// MARK: - List Space Users

struct ListSpaceUsers: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-space-users",
    abstract: "List users of a space"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Space ID")
  var spaceId: Int

  @Option(name: .long, help: "Include users with inherited access")
  var includeInheritedAccess: Bool?

  @Option(name: .long, help: "Return only members inactive in the company")
  var inactive: Bool?

  func run() async throws {
    let client = try await global.makeClient()
    let users = try await client.listSpaceUsers(
      spaceId: spaceId,
      includeInheritedAccess: includeInheritedAccess,
      inactive: inactive
    )
    try printJSON(users, expand: global.expandedFields)
  }
}

// MARK: - Invite Space User

struct InviteSpaceUser: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "invite-space-user",
    abstract: "Invite a user to a space"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Space ID")
  var spaceId: Int

  @Option(name: .long, help: "User email address")
  var email: String

  @Option(name: .long, help: spaceUserRoleIdHelp)
  var roleId: String?

  @Option(name: .long, help: "Invite the user as a guest")
  var guest: Bool?

  @Option(name: .long, help: "Operator's comment")
  var operatorComment: String?

  @Option(name: .long, help: "Whether to send an invitation email")
  var sendEmail: Bool?

  func run() async throws {
    let client = try await global.makeClient()
    let result = try await client.inviteUserToSpace(
      spaceId: spaceId,
      email: email,
      roleId: roleId,
      guest: guest,
      operatorComment: operatorComment,
      sendEmail: sendEmail
    )
    try printJSON(result, expand: global.expandedFields)
  }
}

// MARK: - Get Space User

struct GetSpaceUser: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "get-space-user",
    abstract: "Get a user of a space"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Space ID")
  var spaceId: Int

  @Option(name: .long, help: "User ID")
  var userId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let user = try await client.getSpaceUser(spaceId: spaceId, userId: userId)
    try printJSON(user, expand: global.expandedFields)
  }
}

// MARK: - Update Space User

struct UpdateSpaceUser: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-space-user",
    abstract: "Change a space user's role and notification settings"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Space ID")
  var spaceId: Int

  @Option(name: .long, help: "User ID")
  var userId: Int

  @Option(name: .long, help: spaceUserRoleIdHelp)
  var roleId: String?

  @Option(name: .long, help: "Enable or disable notifications for space events")
  var notificationsEnabled: Bool?

  @Option(name: .long, help: "Space group id")
  var spaceGroupId: Double?

  @Option(name: .long, help: "Space user settings as a JSON object")
  var settings: String?

  func run() async throws {
    let parsedSettings = try parseAutomationJSON(
      settings, as: Components.Schemas.UpdateSpaceUserRequest.settingsPayload.self,
      fieldName: "settings")

    let client = try await global.makeClient()
    let result = try await client.updateSpaceUser(
      spaceId: spaceId,
      userId: userId,
      roleId: roleId,
      notificationsEnabled: notificationsEnabled,
      spaceGroupId: spaceGroupId,
      settings: parsedSettings
    )
    try printJSON(result, expand: global.expandedFields)
  }
}

// MARK: - Remove Space User

struct RemoveSpaceUser: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "remove-space-user",
    abstract: "Remove a user from a space"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Space ID")
  var spaceId: Int

  @Option(name: .long, help: "User ID")
  var userId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let result = try await client.removeSpaceUser(spaceId: spaceId, userId: userId)
    try printJSON(result, expand: global.expandedFields)
  }
}
