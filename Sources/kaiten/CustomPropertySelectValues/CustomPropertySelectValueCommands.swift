import ArgumentParser
import KaitenSDK

// MARK: - Custom Property Select Values

func parseSelectValueCondition(_ rawValue: String) throws -> CustomPropertySelectValueCondition {
  let condition = CustomPropertySelectValueCondition(rawValue: rawValue)
  guard CustomPropertySelectValueCondition.allCases.contains(condition) else {
    let allowed = CustomPropertySelectValueCondition.allCases.map(\.rawValue)
      .joined(separator: ", ")
    throw ValidationError("Invalid condition: '\(rawValue)'. Allowed values: \(allowed)")
  }
  return condition
}

struct ListCustomPropertySelectValues: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-custom-property-select-values",
    abstract: "List select values for a custom property"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Custom property ID")
  var propertyId: Int

  @Option(name: .long, help: "Enable v2 search filtering")
  var v2SelectSearch: Bool?

  @Option(name: .long, help: "Filter by select value (requires v2-select-search)")
  var query: String?

  @Option(name: .long, help: "Field to sort by (requires v2-select-search)")
  var orderBy: String?

  @Option(name: .long, help: "Comma-separated value IDs to filter by")
  var ids: String?

  @Option(name: .long, help: "Comma-separated conditions to filter by")
  var conditions: String?

  @Option(name: .long, help: "Offset for pagination (requires v2-select-search)")
  var offset: Int?

  @Option(name: .long, help: "Limit for pagination (requires v2-select-search, default: 100)")
  var limit: Int?

  func run() async throws {
    let client = try await global.makeClient()
    let parsedIds = try parseIntegerCSV(ids, fieldName: "ids")
    let parsedConditions = try parseStringCSV(conditions, fieldName: "conditions")
    let values = try await client.listCustomPropertySelectValues(
      propertyId: propertyId,
      v2SelectSearch: v2SelectSearch,
      query: query,
      orderBy: orderBy,
      ids: parsedIds,
      conditions: parsedConditions,
      offset: offset ?? 0,
      limit: limit ?? 100
    )
    try printJSON(values, expand: global.expandedFields)
  }
}

struct GetCustomPropertySelectValue: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "get-custom-property-select-value",
    abstract: "Get a specific select value for a custom property"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Custom property ID")
  var propertyId: Int

  @Option(name: .long, help: "Select value ID")
  var id: Int

  func run() async throws {
    let client = try await global.makeClient()
    let value = try await client.getCustomPropertySelectValue(
      propertyId: propertyId, id: id)
    try printJSON(value, expand: global.expandedFields)
  }
}

struct CreateCustomPropertySelectValue: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "create-custom-property-select-value",
    abstract: "Create a select value for a custom property"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Custom property ID")
  var propertyId: Int

  @Option(name: .long, help: "Value text, 1 to 128 characters")
  var value: String

  @Option(name: .long, help: "Colour number; omit for no colour")
  var color: Int?

  func run() async throws {
    let client = try await global.makeClient()
    let created = try await client.createCustomPropertySelectValue(
      propertyId: propertyId, value: value, color: color)
    try printJSON(created, expand: global.expandedFields)
  }
}

struct UpdateCustomPropertySelectValue: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-custom-property-select-value",
    abstract: "Update a select value of a custom property"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Custom property ID")
  var propertyId: Int

  @Option(name: .long, help: "Select value ID")
  var id: Int

  @Option(name: .long, help: "Value text, 1 to 128 characters")
  var value: String?

  @Option(name: .long, help: "Colour number")
  var color: Int?

  @Option(name: .long, help: "Condition: active or inactive")
  var condition: String?

  @Option(name: .long, help: "Position, 0 or greater")
  var sortOrder: Double?

  @Option(name: .long, help: "Delete condition")
  var deleted: Bool?

  func run() async throws {
    let parsedCondition = try condition.map(parseSelectValueCondition)
    let client = try await global.makeClient()
    let updated = try await client.updateCustomPropertySelectValue(
      propertyId: propertyId,
      id: id,
      value: value,
      color: color,
      condition: parsedCondition,
      sortOrder: sortOrder,
      deleted: deleted
    )
    try printJSON(updated, expand: global.expandedFields)
  }
}

struct RemoveCustomPropertySelectValue: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "remove-custom-property-select-value",
    abstract: "Remove a select value from a custom property"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Custom property ID")
  var propertyId: Int

  @Option(name: .long, help: "Select value ID")
  var id: Int

  func run() async throws {
    let client = try await global.makeClient()
    let removed = try await client.removeCustomPropertySelectValue(
      propertyId: propertyId, id: id)
    try printJSON(removed, expand: global.expandedFields)
  }
}
