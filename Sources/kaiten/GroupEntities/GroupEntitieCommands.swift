import ArgumentParser
import KaitenSDK

// MARK: - List Group Entities

struct ListGroupEntities: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-group-entities",
    abstract: "List entities of a company group"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Group UID")
  var groupUid: String

  func run() async throws {
    let client = try await global.makeClient()
    let entities = try await client.listGroupEntities(groupUid: groupUid)
    try printJSON(entities)
  }
}

// MARK: - Add Group Entity

struct AddGroupEntity: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "add-group-entity",
    abstract: "Add an entity to a company group"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Group UID")
  var groupUid: String

  @Option(name: .long, help: "Entity UID")
  var entityUid: String

  @Option(name: .long, help: "Comma-separated role UIDs for the entity in the group")
  var roleIds: String

  func run() async throws {
    guard let parsedRoleIds = try parseStringCSV(roleIds, fieldName: "--role-ids") else {
      throw ValidationError("Invalid --role-ids value: at least one role UID is required")
    }
    let client = try await global.makeClient()
    let entity = try await client.addGroupEntity(
      groupUid: groupUid, entityUid: entityUid, roleIds: parsedRoleIds)
    try printJSON(entity)
  }
}

// MARK: - Update Group Entity

struct UpdateGroupEntity: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-group-entity",
    abstract: "Update the roles of an entity in a company group"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Group UID")
  var groupUid: String

  @Option(name: .long, help: "Entity UID")
  var uid: String

  @Option(name: .long, help: "Comma-separated role UIDs for the entity in the group")
  var roleIds: String?

  func run() async throws {
    let parsedRoleIds = try parseStringCSV(roleIds, fieldName: "--role-ids")
    let client = try await global.makeClient()
    let entity = try await client.updateGroupEntity(
      groupUid: groupUid, uid: uid, roleIds: parsedRoleIds)
    try printJSON(entity)
  }
}

// MARK: - Remove Group Entity

struct RemoveGroupEntity: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "remove-group-entity",
    abstract: "Remove an entity from a company group"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Group UID")
  var groupUid: String

  @Option(name: .long, help: "Entity UID")
  var uid: String

  func run() async throws {
    let client = try await global.makeClient()
    let entity = try await client.removeGroupEntity(groupUid: groupUid, uid: uid)
    try printJSON(entity)
  }
}
