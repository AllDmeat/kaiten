import ArgumentParser
import KaitenSDK

// MARK: - List Card Type Tree Entities

struct ListCardTypeTreeEntities: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-card-type-tree-entities",
    abstract: "List tree entities of a card type"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card type ID")
  var typeId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let entities = try await client.listCardTypeTreeEntities(typeId: typeId)
    try printJSON(entities)
  }
}

// MARK: - Add Card Type Tree Entity

struct AddCardTypeTreeEntity: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "add-card-type-tree-entity",
    abstract: "Add a tree entity to a card type"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card type ID")
  var typeId: Int

  @Option(name: .long, help: "Tree entity UID")
  var treeEntityUid: String

  func run() async throws {
    let client = try await global.makeClient()
    let result = try await client.addCardTypeTreeEntity(
      typeId: typeId, treeEntityUid: treeEntityUid)
    try printJSON(result)
  }
}

// MARK: - Delete Card Type Tree Entity

struct DeleteCardTypeTreeEntity: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "delete-card-type-tree-entity",
    abstract: "Delete a tree entity from a card type"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card type ID")
  var typeId: Int

  @Option(name: .long, help: "Tree entity UID")
  var uid: String

  func run() async throws {
    let client = try await global.makeClient()
    let result = try await client.deleteCardTypeTreeEntity(typeId: typeId, uid: uid)
    try printJSON(result)
  }
}
