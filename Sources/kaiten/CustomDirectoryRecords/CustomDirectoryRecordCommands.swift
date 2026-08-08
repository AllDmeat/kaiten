import ArgumentParser
import Foundation
import KaitenSDK

// MARK: - Custom Directory Records

func parseCustomDirectoryProfile(_ rawValue: String?, fieldName: String) throws
  -> CustomDirectoryProfile?
{
  guard let rawValue else { return nil }
  let profile = CustomDirectoryProfile(rawValue: rawValue)
  guard CustomDirectoryProfile.allCases.contains(profile) else {
    let allowed = CustomDirectoryProfile.allCases.map(\.rawValue).joined(separator: ", ")
    throw ValidationError("Invalid \(fieldName): '\(rawValue)'. Allowed values: \(allowed)")
  }
  return profile
}

func parseCustomDirectoryRecordCondition(_ rawValue: String) throws
  -> CustomDirectoryRecordCondition
{
  let condition = CustomDirectoryRecordCondition(rawValue: rawValue)
  guard CustomDirectoryRecordCondition.allCases.contains(condition) else {
    let allowed = CustomDirectoryRecordCondition.allCases.map(\.rawValue).joined(separator: ", ")
    throw ValidationError("Invalid condition: '\(rawValue)'. Allowed values: \(allowed)")
  }
  return condition
}

func parseCustomDirectoryRecordConditions(_ rawValue: String?) throws
  -> [CustomDirectoryRecordCondition]?
{
  guard let tokens = try parseStringCSV(rawValue, fieldName: "--conditions") else { return nil }
  return try tokens.map(parseCustomDirectoryRecordCondition)
}

func parseCustomDirectoryFilterOperator(_ rawValue: String?) throws
  -> CustomDirectoryFilterOperator?
{
  guard let rawValue else { return nil }
  let filterOperator = CustomDirectoryFilterOperator(rawValue: rawValue)
  guard CustomDirectoryFilterOperator.allCases.contains(filterOperator) else {
    let allowed = CustomDirectoryFilterOperator.allCases.map(\.rawValue).joined(separator: ", ")
    throw ValidationError("Invalid filter operator: '\(rawValue)'. Allowed values: \(allowed)")
  }
  return filterOperator
}

// MARK: - List Custom Directory Records

struct ListCustomDirectoryRecords: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-custom-directory-records",
    abstract: "List records in a custom directory (paginated)",
    discussion: "The custom directories API is in beta and may change."
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Directory ID")
  var directoryId: String

  @Option(name: .long, help: "Quick search by record display value")
  var query: String?

  @Option(name: .long, help: "Included relations: none, summary, details, full")
  var profile: String?

  @Option(name: .long, help: "Legacy: include the values array")
  var includeValues: Bool?

  @Option(name: .long, help: "Include the author user object")
  var includeAuthor: Bool?

  @Option(name: .long, help: "Comma-separated conditions: active, inactive, removed")
  var conditions: String?

  @Option(name: .long, help: "Advanced field-based filters as a JSON object")
  var filters: String?

  @Option(name: .long, help: "Boolean operator for filters: and, or (default: and)")
  var filterOperator: String?

  @Option(name: .long, help: "Offset for pagination (default: 0)")
  var offset: Int = 0

  @Option(name: .long, help: "Limit for pagination (default: 100, max: 100)")
  var limit: Int = 100

  func run() async throws {
    let parsedProfile = try parseCustomDirectoryProfile(profile, fieldName: "profile")
    let parsedConditions = try parseCustomDirectoryRecordConditions(conditions)
    let parsedFilterOperator = try parseCustomDirectoryFilterOperator(filterOperator)
    let client = try await global.makeClient()
    let page = try await client.listCustomDirectoryRecords(
      directoryId: directoryId,
      query: query,
      profile: parsedProfile,
      includeValues: includeValues,
      includeAuthor: includeAuthor,
      conditions: parsedConditions,
      filters: filters,
      filterOperator: parsedFilterOperator,
      offset: offset,
      limit: limit
    )
    try printJSON(page, expand: global.expandedFields)
  }
}

// MARK: - Create Custom Directory Record

struct CreateCustomDirectoryRecord: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "create-custom-directory-record",
    abstract: "Create a record in a custom directory",
    discussion: "The custom directories API is in beta and may change."
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Directory ID")
  var directoryId: String

  @Option(
    name: .long,
    help:
      "Values as a JSON object keyed by directory field ID; each value is an object or an array of objects"
  )
  var values: String

  @Option(name: .long, help: "Response size: none, summary, details, full")
  var responseProfile: String?

  func run() async throws {
    guard
      let parsedValues = try parseAutomationJSON(
        values, as: Components.Schemas.CreateCustomDirectoryRecordRequest.valuesPayload.self,
        fieldName: "values")
    else {
      throw ValidationError("Invalid values: value is required")
    }
    let parsedResponseProfile = try parseCustomDirectoryProfile(
      responseProfile, fieldName: "response profile")
    let client = try await global.makeClient()
    let record = try await client.createCustomDirectoryRecord(
      directoryId: directoryId,
      values: parsedValues,
      responseProfile: parsedResponseProfile
    )
    try printJSON(record, expand: global.expandedFields)
  }
}

// MARK: - Get Custom Directory Record

struct GetCustomDirectoryRecord: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "get-custom-directory-record",
    abstract: "Get a custom directory record",
    discussion: "The custom directories API is in beta and may change."
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Directory ID")
  var directoryId: String

  @Option(name: .long, help: "Record ID")
  var recordId: String

  @Option(name: .long, help: "Included relations: none, summary, details, full")
  var profile: String?

  func run() async throws {
    let parsedProfile = try parseCustomDirectoryProfile(profile, fieldName: "profile")
    let client = try await global.makeClient()
    let record = try await client.getCustomDirectoryRecord(
      directoryId: directoryId,
      recordId: recordId,
      profile: parsedProfile
    )
    try printJSON(record, expand: global.expandedFields)
  }
}

// MARK: - Update Custom Directory Record

struct UpdateCustomDirectoryRecord: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-custom-directory-record",
    abstract: "Update a custom directory record's values and/or condition",
    discussion: "The custom directories API is in beta and may change."
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Directory ID")
  var directoryId: String

  @Option(name: .long, help: "Record ID")
  var recordId: String

  @Option(name: .long, help: "Record condition: active, inactive, removed")
  var condition: String?

  @Option(
    name: .long,
    help:
      "Values as a JSON object keyed by directory field ID; each value is an object or an array of objects"
  )
  var values: String?

  @Option(name: .long, help: "Response size: none, summary, details, full")
  var responseProfile: String?

  func run() async throws {
    let parsedCondition = try condition.map(parseCustomDirectoryRecordCondition)
    let parsedValues = try parseAutomationJSON(
      values, as: Components.Schemas.UpdateCustomDirectoryRecordRequest.valuesPayload.self,
      fieldName: "values")
    let parsedResponseProfile = try parseCustomDirectoryProfile(
      responseProfile, fieldName: "response profile")
    let client = try await global.makeClient()
    let record = try await client.updateCustomDirectoryRecord(
      directoryId: directoryId,
      recordId: recordId,
      condition: parsedCondition,
      values: parsedValues,
      responseProfile: parsedResponseProfile
    )
    try printJSON(record, expand: global.expandedFields)
  }
}

// MARK: - Delete Custom Directory Record

struct DeleteCustomDirectoryRecord: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "delete-custom-directory-record",
    abstract: "Soft-delete a custom directory record (condition becomes removed)",
    discussion: "The custom directories API is in beta and may change."
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Directory ID")
  var directoryId: String

  @Option(name: .long, help: "Record ID")
  var recordId: String

  func run() async throws {
    let client = try await global.makeClient()
    let record = try await client.deleteCustomDirectoryRecord(
      directoryId: directoryId,
      recordId: recordId
    )
    try printJSON(record, expand: global.expandedFields)
  }
}

// MARK: - List Custom Directory Record Cards

struct ListCustomDirectoryRecordCards: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-custom-directory-record-cards",
    abstract: "List cards linked to a custom directory record (paginated)",
    discussion: """
      Returns cards linked to the record, including cards linked through ancestor records. \
      The custom directories API is in beta and may change.
      """
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Directory ID")
  var directoryId: String

  @Option(name: .long, help: "Record ID")
  var recordId: String

  @Option(name: .long, help: "Base64-encoded JSON card filter, merged with the base filter")
  var filter: String?

  @Option(name: .long, help: "Offset for pagination (default: 0)")
  var offset: Int = 0

  @Option(name: .long, help: "Limit for pagination (default: 100, max: 100)")
  var limit: Int = 100

  func run() async throws {
    let client = try await global.makeClient()
    let page = try await client.listCustomDirectoryRecordCards(
      directoryId: directoryId,
      recordId: recordId,
      filter: filter,
      offset: offset,
      limit: limit
    )
    try printJSON(page, expand: global.expandedFields)
  }
}
