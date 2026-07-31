import ArgumentParser
import KaitenSDK

func parseCardMemberRoleType(_ rawValue: Int) throws -> CardMemberRoleType {
  let roleType = CardMemberRoleType(rawValue: rawValue)
  guard CardMemberRoleType.allCases.contains(roleType) else {
    throw ValidationError("Invalid role type: \(rawValue). Allowed values: 2 (responsible)")
  }
  return roleType
}

struct AddCardMember: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "add-card-member",
    abstract: "Add a member to a card"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  @Option(name: .long, help: "User ID")
  var userId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let member = try await client.addCardMember(cardId: cardId, userId: userId)
    try printJSON(member, expand: global.expandedFields)
  }
}

struct UpdateCardMemberRole: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-card-member-role",
    abstract: "Update a card member's role"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  @Option(name: .long, help: "User ID")
  var userId: Int

  @Option(name: .long, help: "Role type (2 = responsible)")
  var type: Int

  func run() async throws {
    let client = try await global.makeClient()
    let roleType = try parseCardMemberRoleType(type)
    let role = try await client.updateCardMemberRole(cardId: cardId, userId: userId, type: roleType)
    try printJSON(role, expand: global.expandedFields)
  }
}

struct RemoveCardMember: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "remove-card-member",
    abstract: "Remove a member from a card"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  @Option(name: .long, help: "User ID")
  var userId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let deletedId = try await client.removeCardMember(cardId: cardId, userId: userId)
    try printJSON(["id": deletedId], expand: global.expandedFields)
  }
}
