import ArgumentParser
import KaitenSDK

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

// MARK: - Custom Property Select Values

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
