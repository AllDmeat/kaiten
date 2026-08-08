import ArgumentParser
import Foundation
import KaitenSDK

// MARK: - Custom Property Catalog Values

func parseCatalogValueCondition(_ rawValue: String) throws -> CatalogValueCondition {
  let condition = CatalogValueCondition(rawValue: rawValue)
  guard CatalogValueCondition.allCases.contains(condition) else {
    let allowed = CatalogValueCondition.allCases.map(\.rawValue).joined(separator: ", ")
    throw ValidationError("Invalid condition: '\(rawValue)'. Allowed values: \(allowed)")
  }
  return condition
}

/// Decodes the catalog value JSON object command-line argument.
///
/// Malformed JSON fails locally with a validation error — the value is never
/// silently dropped or forwarded to the SDK.
func parseCatalogValueObject<Payload: Decodable>(
  _ rawValue: String?, fieldName: String
) throws -> Payload? {
  guard let rawValue else { return nil }
  let data = Data(rawValue.utf8)
  guard let object = try? JSONSerialization.jsonObject(with: data), object is [String: Any] else {
    throw ValidationError(
      "Invalid \(fieldName) value: expected a JSON object of catalog field uid to field value pairs"
    )
  }
  do {
    return try JSONDecoder().decode(Payload.self, from: data)
  } catch {
    throw ValidationError("Invalid \(fieldName) value: \(error.localizedDescription)")
  }
}

// MARK: - List Catalog Values

struct ListCustomPropertyCatalogValues: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-custom-property-catalog-values",
    abstract: "List catalog values for a custom property (paginated)"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Custom property ID")
  var propertyId: Int

  @Option(name: .long, help: "Text search filter by catalog values")
  var query: String?

  @Option(name: .long, help: "Filter by condition: active or inactive")
  var conditions: String?

  @Option(name: .long, help: "Offset for pagination (default: 0)")
  var offset: Int = 0

  @Option(name: .long, help: "Limit for pagination (default: 100)")
  var limit: Int = 100

  func run() async throws {
    let parsedConditions = try conditions.map(parseCatalogValueCondition)
    let client = try await global.makeClient()
    let page = try await client.listCustomPropertyCatalogValues(
      propertyId: propertyId,
      query: query,
      conditions: parsedConditions,
      offset: offset,
      limit: limit
    )
    try printJSON(page, expand: global.expandedFields)
  }
}

// MARK: - Get Catalog Value

struct GetCustomPropertyCatalogValue: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "get-custom-property-catalog-value",
    abstract: "Get a specific catalog value for a custom property"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Custom property ID")
  var propertyId: Int

  @Option(name: .long, help: "Catalog value ID")
  var id: Int

  func run() async throws {
    let client = try await global.makeClient()
    let value = try await client.getCustomPropertyCatalogValue(propertyId: propertyId, id: id)
    try printJSON(value, expand: global.expandedFields)
  }
}

// MARK: - Create Catalog Value

struct CreateCustomPropertyCatalogValue: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "create-custom-property-catalog-value",
    abstract: "Create a catalog value for a custom property"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Custom property ID")
  var propertyId: Int

  @Option(
    name: .long,
    help:
      "Catalog value as a JSON object of catalog field uid to field value pairs, e.g. '{\"<field-uid>\":\"text\"}'"
  )
  var value: String

  func run() async throws {
    guard
      let parsedValue: Components.Schemas.CreateCatalogValueRequest.valuePayload =
        try parseCatalogValueObject(value, fieldName: "value")
    else {
      throw ValidationError("Invalid value: value is required")
    }
    let client = try await global.makeClient()
    let created = try await client.createCustomPropertyCatalogValue(
      propertyId: propertyId, value: parsedValue)
    try printJSON(created, expand: global.expandedFields)
  }
}

// MARK: - Update Catalog Value

struct UpdateCustomPropertyCatalogValue: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-custom-property-catalog-value",
    abstract: "Update a catalog value of a custom property"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Custom property ID")
  var propertyId: Int

  @Option(name: .long, help: "Catalog value ID")
  var id: Int

  @Option(name: .long, help: "Catalog value condition: active or inactive")
  var condition: String?

  @Option(
    name: .long,
    help: "Catalog value as a JSON object of catalog field uid to field value pairs"
  )
  var value: String?

  @Option(name: .long, help: "Catalog value delete condition")
  var deleted: Bool?

  func run() async throws {
    let parsedCondition = try condition.map(parseCatalogValueCondition)
    let parsedValue: Components.Schemas.UpdateCatalogValueRequest.valuePayload? =
      try parseCatalogValueObject(value, fieldName: "value")
    let client = try await global.makeClient()
    let updated = try await client.updateCustomPropertyCatalogValue(
      propertyId: propertyId,
      id: id,
      condition: parsedCondition,
      value: parsedValue,
      deleted: deleted
    )
    try printJSON(updated, expand: global.expandedFields)
  }
}

// MARK: - Remove Catalog Value

struct RemoveCustomPropertyCatalogValue: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "remove-custom-property-catalog-value",
    abstract: "Remove a catalog value from a custom property"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Custom property ID")
  var propertyId: Int

  @Option(name: .long, help: "Catalog value ID")
  var id: Int

  func run() async throws {
    let client = try await global.makeClient()
    let removed = try await client.removeCustomPropertyCatalogValue(propertyId: propertyId, id: id)
    try printJSON(removed, expand: global.expandedFields)
  }
}
