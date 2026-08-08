import ArgumentParser
import Foundation
import KaitenSDK

// MARK: - List User Roles

struct ListUserRoles: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-user-roles",
    abstract: "List user roles in the company"
  )

  @OptionGroup var global: GlobalOptions

  func run() async throws {
    let client = try await global.makeClient()
    let roles = try await client.listUserRoles()
    try printJSON(roles, expand: global.expandedFields)
  }
}

// MARK: - Create User Role

struct CreateUserRole: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "create-user-role",
    abstract: "Create a user role"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Role name (1-64 characters)")
  var name: String

  func run() async throws {
    let client = try await global.makeClient()
    let role = try await client.createUserRole(name: name)
    try printJSON(role, expand: global.expandedFields)
  }
}

// MARK: - Get User Role

struct GetUserRole: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "get-user-role",
    abstract: "Get a user role"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Role ID")
  var id: Int

  func run() async throws {
    let client = try await global.makeClient()
    let role = try await client.getUserRole(id: id)
    try printJSON(role, expand: global.expandedFields)
  }
}

// MARK: - Update User Role

struct UpdateUserRole: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-user-role",
    abstract: "Update a user role"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Role ID")
  var id: Int

  @Option(name: .long, help: "Role name (1-64 characters)")
  var name: String

  func run() async throws {
    let client = try await global.makeClient()
    let role = try await client.updateUserRole(id: id, name: name)
    try printJSON(role, expand: global.expandedFields)
  }
}

// MARK: - Delete User Role

struct DeleteUserRole: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "delete-user-role",
    abstract: "Delete a user role, moving its users to a replacement role"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Role ID")
  var id: Int

  @Option(name: .long, help: "ID of the role that replaces the deleted one")
  var replaceRoleId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let role = try await client.deleteUserRole(id: id, replaceRoleId: replaceRoleId)
    try printJSON(role, expand: global.expandedFields)
  }
}
