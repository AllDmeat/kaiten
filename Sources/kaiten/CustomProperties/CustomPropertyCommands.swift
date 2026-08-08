import ArgumentParser
import Foundation
import KaitenSDK

// MARK: - Parsing Helpers

/// Decodes a JSON command-line argument into a generated OpenAPI type.
///
/// Malformed JSON fails locally with a validation error — the value is never
/// silently dropped or forwarded to the SDK.
func parseCustomPropertyJSON<T: Decodable>(
  _ rawValue: String?, as type: T.Type, fieldName: String
) throws -> T? {
  guard let rawValue else { return nil }
  guard let data = rawValue.data(using: .utf8) else {
    throw ValidationError("Invalid \(fieldName): value is not valid UTF-8")
  }
  do {
    return try JSONDecoder().decode(T.self, from: data)
  } catch {
    throw ValidationError("Invalid \(fieldName) JSON: \(error.localizedDescription)")
  }
}

func parseCustomPropertyType(_ rawValue: String?) throws -> CustomPropertyType? {
  guard let rawValue else { return nil }
  let type = CustomPropertyType(rawValue: rawValue)
  guard CustomPropertyType.allCases.contains(type) else {
    let allowed = CustomPropertyType.allCases.map(\.rawValue).joined(separator: ", ")
    throw ValidationError("Invalid custom property type: '\(rawValue)'. Allowed values: \(allowed)")
  }
  return type
}

func parseCustomPropertyCondition(_ rawValue: String?) throws -> CustomPropertyCondition? {
  guard let rawValue else { return nil }
  let condition = CustomPropertyCondition(rawValue: rawValue)
  guard CustomPropertyCondition.allCases.contains(condition) else {
    let allowed = CustomPropertyCondition.allCases.map(\.rawValue).joined(separator: ", ")
    throw ValidationError(
      "Invalid custom property condition: '\(rawValue)'. Allowed values: \(allowed)")
  }
  return condition
}

func parseCustomPropertyVoteVariant(_ rawValue: String?) throws -> CustomPropertyVoteVariant? {
  guard let rawValue else { return nil }
  let variant = CustomPropertyVoteVariant(rawValue: rawValue)
  guard CustomPropertyVoteVariant.allCases.contains(variant) else {
    let allowed = CustomPropertyVoteVariant.allCases.map(\.rawValue).joined(separator: ", ")
    throw ValidationError("Invalid vote variant: '\(rawValue)'. Allowed values: \(allowed)")
  }
  return variant
}

func parseCustomPropertyValuesType(_ rawValue: String?) throws -> CustomPropertyValuesType? {
  guard let rawValue else { return nil }
  let valuesType = CustomPropertyValuesType(rawValue: rawValue)
  guard CustomPropertyValuesType.allCases.contains(valuesType) else {
    let allowed = CustomPropertyValuesType.allCases.map(\.rawValue).joined(separator: ", ")
    throw ValidationError("Invalid values type: '\(rawValue)'. Allowed values: \(allowed)")
  }
  return valuesType
}

// MARK: - Custom Properties

struct ListCustomProperties: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-custom-properties",
    abstract: "List custom property definitions (paginated)"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Offset for pagination (default: 0)")
  var offset: Int = 0

  @Option(name: .long, help: "Limit for pagination (default/max: 100)")
  var limit: Int = 100

  @Option(name: .long, help: "Text search query")
  var query: String?

  @Option(name: .long, help: "Include property values in response")
  var includeValues: Bool?

  @Option(name: .long, help: "Include author details in response")
  var includeAuthor: Bool?

  @Option(name: .long, help: "Return compact representation")
  var compact: Bool?

  @Option(name: .long, help: "Load properties by IDs")
  var loadByIds: Bool?

  @Option(name: .long, help: "Comma-separated property IDs to load")
  var ids: String?

  @Option(name: .long, help: "Field to order by")
  var orderBy: String?

  @Option(name: .long, help: "Order direction: asc or desc")
  var orderDirection: String?

  func run() async throws {
    let client = try await global.makeClient()
    let parsedIds = try parseIntegerCSV(ids, fieldName: "ids")
    let page = try await client.listCustomProperties(
      offset: offset,
      limit: limit,
      query: query,
      includeValues: includeValues,
      includeAuthor: includeAuthor,
      compact: compact,
      loadByIds: loadByIds,
      ids: parsedIds,
      orderBy: orderBy,
      orderDirection: orderDirection
    )
    try printJSON(page, expand: global.expandedFields)
  }
}

struct GetCustomProperty: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "get-custom-property",
    abstract: "Get a custom property by ID"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Custom property ID")
  var id: Int

  func run() async throws {
    let client = try await global.makeClient()
    let prop = try await client.getCustomProperty(id: id)
    try printJSON(prop, expand: global.expandedFields)
  }
}

struct CreateCustomProperty: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "create-custom-property",
    abstract: "Create a custom property definition"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Custom property name, 1 to 128 characters")
  var name: String

  @Option(
    name: .long,
    help:
      "Property value type: string, number, date, email, phone, checkbox, select, formula, url, collective_score, vote, collective_vote, catalog, user, attachment (default: string)"
  )
  var type: String?

  @Option(name: .long, help: "Show the property on the card facade")
  var showOnFacade: Bool?

  @Option(name: .long, help: "Render a multiline text field")
  var multiline: Bool?

  @Option(
    name: .long,
    help: "Vote variant for vote and collective_vote properties: rating, scale, emoji_set")
  var voteVariant: String?

  @Option(name: .long, help: "Type of values for collective_score properties: number, text")
  var valuesType: String?

  @Option(name: .long, help: "Select a color when creating new select values (select properties)")
  var colorful: Bool?

  @Option(name: .long, help: "Use the select property as a multi select (select properties)")
  var multiSelect: Bool?

  @Option(
    name: .long,
    help: "Allow users with the writer role to create new select values (select properties)")
  var valuesCreatableByUsers: Bool?

  @Option(
    name: .long,
    help: "Additional property data as a JSON object, e.g. '{\"formula\":\"prop(\\\"a\\\") * 2\"}'")
  var data: String?

  @Option(name: .long, help: "Color of a catalog property")
  var color: Int?

  @Option(
    name: .long, help: "Field settings for catalog properties as a JSON object keyed by field UID")
  var fieldsSettings: String?

  func run() async throws {
    let parsedType = try parseCustomPropertyType(type)
    let parsedVoteVariant = try parseCustomPropertyVoteVariant(voteVariant)
    let parsedValuesType = try parseCustomPropertyValuesType(valuesType)
    let parsedData = try parseCustomPropertyJSON(
      data, as: Components.Schemas.CreateCustomPropertyRequest.dataPayload.self, fieldName: "data")
    let parsedFieldsSettings = try parseCustomPropertyJSON(
      fieldsSettings,
      as: Components.Schemas.CreateCustomPropertyRequest.fields_settingsPayload.self,
      fieldName: "fields-settings")

    let client = try await global.makeClient()
    let created = try await client.createCustomProperty(
      name: name,
      type: parsedType,
      showOnFacade: showOnFacade,
      multiline: multiline,
      voteVariant: parsedVoteVariant,
      valuesType: parsedValuesType,
      colorful: colorful,
      multiSelect: multiSelect,
      valuesCreatableByUsers: valuesCreatableByUsers,
      data: parsedData,
      color: color,
      fieldsSettings: parsedFieldsSettings
    )
    try printJSON(created, expand: global.expandedFields)
  }
}

struct UpdateCustomProperty: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-custom-property",
    abstract: "Update a custom property definition"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Custom property ID")
  var id: Int

  @Option(name: .long, help: "Custom property name, 1 to 128 characters")
  var name: String?

  @Option(name: .long, help: "Show the property on the card facade")
  var showOnFacade: Bool?

  @Option(name: .long, help: "Render a multiline text field")
  var multiline: Bool?

  @Option(name: .long, help: "Property condition: active, inactive")
  var condition: String?

  @Option(name: .long, help: "Select a color when creating new select values (select properties)")
  var colorful: Bool?

  @Option(name: .long, help: "Use the select property as a multi select (select properties)")
  var multiSelect: Bool?

  @Option(
    name: .long,
    help: "Allow users with the writer role to create new select values (select properties)")
  var valuesCreatableByUsers: Bool?

  @Option(name: .long, help: "Additional property data as a JSON object")
  var data: String?

  @Option(name: .long, help: "Color of a catalog property")
  var color: Int?

  @Option(
    name: .long, help: "Field settings for catalog properties as a JSON object keyed by field UID")
  var fieldsSettings: String?

  @Option(name: .long, help: "Use the property value as a progress indicator")
  var isUsedAsProgress: Bool?

  func run() async throws {
    let parsedCondition = try parseCustomPropertyCondition(condition)
    let parsedData = try parseCustomPropertyJSON(
      data, as: Components.Schemas.UpdateCustomPropertyRequest.dataPayload.self, fieldName: "data")
    let parsedFieldsSettings = try parseCustomPropertyJSON(
      fieldsSettings,
      as: Components.Schemas.UpdateCustomPropertyRequest.fields_settingsPayload.self,
      fieldName: "fields-settings")

    let client = try await global.makeClient()
    let updated = try await client.updateCustomProperty(
      id: id,
      name: name,
      showOnFacade: showOnFacade,
      multiline: multiline,
      condition: parsedCondition,
      colorful: colorful,
      multiSelect: multiSelect,
      valuesCreatableByUsers: valuesCreatableByUsers,
      data: parsedData,
      color: color,
      fieldsSettings: parsedFieldsSettings,
      isUsedAsProgress: isUsedAsProgress
    )
    try printJSON(updated, expand: global.expandedFields)
  }
}

struct RemoveCustomProperty: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "remove-custom-property",
    abstract: "Remove a custom property definition"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Custom property ID")
  var id: Int

  func run() async throws {
    let client = try await global.makeClient()
    let removed = try await client.removeCustomProperty(id: id)
    try printJSON(removed, expand: global.expandedFields)
  }
}
