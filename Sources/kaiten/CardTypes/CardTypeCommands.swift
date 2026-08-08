import ArgumentParser
import Foundation
import KaitenSDK
import OpenAPIRuntime

// MARK: - Card Types

/// Decodes a JSON command-line argument into a generated OpenAPI type.
///
/// Malformed JSON fails locally with a validation error — the value is never
/// silently dropped or forwarded to the SDK.
func parseCardTypeJSON<T: Decodable>(
  _ rawValue: String?, as type: T.Type, fieldName: String
) throws -> T? {
  guard let rawValue else { return nil }
  let data = Data(rawValue.utf8)
  do {
    return try JSONDecoder().decode(T.self, from: data)
  } catch {
    throw ValidationError("Invalid \(fieldName) JSON: \(error.localizedDescription)")
  }
}

struct ListCardTypes: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-card-types",
    abstract: "List card types"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Limit the number of card types returned (max 100)")
  var limit: Int?

  @Option(name: .long, help: "Offset for pagination")
  var offset: Int?

  func run() async throws {
    let client = try await global.makeClient()
    let types = try await client.listCardTypes(limit: limit, offset: offset)
    try printJSON(types, expand: global.expandedFields)
  }
}

struct GetCardType: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "get-card-type",
    abstract: "Get a card type by ID"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card type ID")
  var id: Int

  func run() async throws {
    let client = try await global.makeClient()
    let type = try await client.getCardType(id: id)
    try printJSON(type, expand: global.expandedFields)
  }
}

struct CreateCardType: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "create-card-type",
    abstract: "Create a new card type"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Character that represents the type (1 character, up to 11 for emoji)")
  var letter: String

  @Option(name: .long, help: "Type name (1 to 64 characters)")
  var name: String

  @Option(name: .long, help: "Color number (2 to 25)")
  var color: Int

  @Option(
    name: .long,
    help: "Deprecated old-format properties as a JSON object, e.g. '{\"due_date\": true}'")
  var properties: String?

  @Option(
    name: .long,
    help:
      "Suggested card properties as a JSON array, e.g. '[{\"regular_property\":\"size\",\"required\":true}]'"
  )
  var cardProperties: String?

  @Option(name: .long, help: "Offer to display additional fields based on statistics")
  var suggestFields: Bool?

  func run() async throws {
    let parsedProperties = try parseCardTypeJSON(
      properties, as: OpenAPIObjectContainer.self,
      fieldName: "properties")
    let parsedCardProperties = try parseCardTypeJSON(
      cardProperties, as: [Components.Schemas.CardTypePropertyInput].self,
      fieldName: "card-properties")

    let client = try await global.makeClient()
    let type = try await client.createCardType(
      letter: letter,
      name: name,
      color: color,
      properties: parsedProperties,
      cardProperties: parsedCardProperties,
      suggestFields: suggestFields
    )
    try printJSON(type, expand: global.expandedFields)
  }
}

struct UpdateCardType: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-card-type",
    abstract: "Update a card type by ID"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card type ID")
  var id: Int

  @Option(name: .long, help: "Character that represents the type (1 character, up to 11 for emoji)")
  var letter: String?

  @Option(name: .long, help: "Type name (1 to 64 characters)")
  var name: String?

  @Option(name: .long, help: "Color number (2 to 25)")
  var color: Int?

  @Option(
    name: .long,
    help: "Deprecated old-format properties as a JSON object, e.g. '{\"due_date\": true}'")
  var properties: String?

  @Option(
    name: .long,
    help:
      "Suggested card properties as a JSON array, e.g. '[{\"regular_property\":\"size\",\"required\":true}]'"
  )
  var cardProperties: String?

  @Option(name: .long, help: "Offer to display additional fields based on statistics")
  var suggestFields: Bool?

  func run() async throws {
    let parsedProperties = try parseCardTypeJSON(
      properties, as: OpenAPIObjectContainer.self,
      fieldName: "properties")
    let parsedCardProperties = try parseCardTypeJSON(
      cardProperties, as: [Components.Schemas.CardTypePropertyInput].self,
      fieldName: "card-properties")

    let client = try await global.makeClient()
    let type = try await client.updateCardType(
      id: id,
      letter: letter,
      name: name,
      color: color,
      properties: parsedProperties,
      cardProperties: parsedCardProperties,
      suggestFields: suggestFields
    )
    try printJSON(type, expand: global.expandedFields)
  }
}

struct DeleteCardType: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "delete-card-type",
    abstract: "Remove a card type, replacing it in existing cards"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card type ID")
  var id: Int

  @Option(name: .long, help: "ID of the card type that replaces the removed type in existing cards")
  var replaceTypeId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let type = try await client.deleteCardType(id: id, replaceTypeId: replaceTypeId)
    try printJSON(type, expand: global.expandedFields)
  }
}
