import ArgumentParser
import KaitenSDK

// MARK: - List Custom Property Tree Entities

struct ListCustomPropertyTreeEntities: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-custom-property-tree-entities",
    abstract: "List tree entities of a custom property"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Custom property ID")
  var propertyId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let entities = try await client.listCustomPropertyTreeEntities(propertyId: propertyId)
    try printJSON(entities)
  }
}

// MARK: - Add Custom Property Tree Entity

struct AddCustomPropertyTreeEntity: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "add-custom-property-tree-entity",
    abstract: "Add a tree entity to a custom property"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Custom property ID")
  var propertyId: Int

  @Option(name: .long, help: "Tree entity UID")
  var treeEntityUid: String

  func run() async throws {
    let client = try await global.makeClient()
    let result = try await client.addCustomPropertyTreeEntity(
      propertyId: propertyId, treeEntityUid: treeEntityUid)
    try printJSON(result)
  }
}

// MARK: - Delete Custom Property Tree Entity

struct DeleteCustomPropertyTreeEntity: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "delete-custom-property-tree-entity",
    abstract: "Delete a tree entity from a custom property"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Custom property ID")
  var propertyId: Int

  @Option(name: .long, help: "Tree entity UID")
  var uid: String

  func run() async throws {
    let client = try await global.makeClient()
    let result = try await client.deleteCustomPropertyTreeEntity(propertyId: propertyId, uid: uid)
    try printJSON(result)
  }
}
