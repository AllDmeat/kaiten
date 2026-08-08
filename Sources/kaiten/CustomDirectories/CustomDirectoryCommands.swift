import ArgumentParser
import Foundation
import KaitenSDK

// MARK: - Custom Directories

func parseCustomDirectoryConditions(_ rawValue: String?) throws -> [CustomDirectoryCondition]? {
  guard let tokens = try parseStringCSV(rawValue, fieldName: "--conditions") else { return nil }
  return try tokens.map { token in
    let condition = CustomDirectoryCondition(rawValue: token)
    guard CustomDirectoryCondition.allCases.contains(condition) else {
      let allowed = CustomDirectoryCondition.allCases.map(\.rawValue).joined(separator: ", ")
      throw ValidationError(
        "Invalid custom directory condition: '\(token)'. Allowed values: \(allowed)")
    }
    return condition
  }
}

func parseCustomDirectoryCondition(_ rawValue: String?) throws -> CustomDirectoryCondition? {
  guard let rawValue else { return nil }
  let condition = CustomDirectoryCondition(rawValue: rawValue)
  guard CustomDirectoryCondition.allCases.contains(condition) else {
    let allowed = CustomDirectoryCondition.allCases.map(\.rawValue).joined(separator: ", ")
    throw ValidationError(
      "Invalid custom directory condition: '\(rawValue)'. Allowed values: \(allowed)")
  }
  return condition
}

/// Decodes a JSON command-line argument into a generated OpenAPI type.
///
/// Malformed JSON fails locally with a validation error — the value is never
/// silently dropped or forwarded to the SDK.
func parseCustomDirectoryJSON<T: Decodable>(
  _ rawValue: String?, as type: T.Type, fieldName: String
) throws -> T? {
  guard let rawValue else { return nil }
  do {
    return try JSONDecoder().decode(T.self, from: Data(rawValue.utf8))
  } catch {
    throw ValidationError("Invalid \(fieldName) JSON: \(error.localizedDescription)")
  }
}

// MARK: - List Custom Directories

struct ListCustomDirectories: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-custom-directories",
    abstract: "List custom directories in the company (paginated)",
    discussion: """
      Directories in conditions other than active are returned only when \
      --conditions names them.
      """
  )

  @OptionGroup var global: GlobalOptions

  @Flag(name: .long, help: "Include directory fields in each directory")
  var includeFields = false

  @Flag(name: .long, help: "Include the author user object in each directory")
  var includeAuthor = false

  @Flag(name: .long, help: "Include records_count in each directory")
  var includeRecordsCount = false

  @Option(name: .long, help: "Search by directory name (case-insensitive)")
  var query: String?

  @Option(name: .long, help: "Comma-separated conditions: active, inactive, removed")
  var conditions: String?

  @Option(name: .long, help: "Offset for pagination (default: 0)")
  var offset: Int = 0

  @Option(name: .long, help: "Limit for pagination (default: 200, max: 200)")
  var limit: Int = 200

  func run() async throws {
    let parsedConditions = try parseCustomDirectoryConditions(conditions)
    let client = try await global.makeClient()
    let page = try await client.listCustomDirectories(
      includeFields: includeFields ? true : nil,
      includeAuthor: includeAuthor ? true : nil,
      includeRecordsCount: includeRecordsCount ? true : nil,
      query: query,
      conditions: parsedConditions,
      offset: offset,
      limit: limit
    )
    try printJSON(page, expand: global.expandedFields)
  }
}

// MARK: - Create Custom Directory

struct CreateCustomDirectory: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "create-custom-directory",
    abstract: "Create a custom directory"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Directory name")
  var name: String

  @Option(name: .long, help: "Directory description")
  var description: String?

  @Option(name: .long, help: "Allow multiple values per field in records")
  var multiSelect: Bool?

  @Option(
    name: .long, help: "Allow editing records from cards without custom properties permission")
  var allowEditing: Bool?

  @Option(name: .long, help: "Index of the field to use as a display field")
  var displayFieldIndex: Int?

  @Option(
    name: .long,
    help: "Fields as a JSON array, e.g. '[{\"name\":\"Name\",\"type\":\"string\"}]'")
  var fields: String?

  func run() async throws {
    let parsedFields = try parseCustomDirectoryJSON(
      fields, as: [Components.Schemas.CreateCustomDirectoryFieldRequest].self, fieldName: "fields")
    let client = try await global.makeClient()
    let directory = try await client.createCustomDirectory(
      name: name,
      description: description,
      multiSelect: multiSelect,
      allowEditing: allowEditing,
      displayFieldIndex: displayFieldIndex,
      fields: parsedFields
    )
    try printJSON(directory, expand: global.expandedFields)
  }
}

// MARK: - Get Custom Directory

struct GetCustomDirectory: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "get-custom-directory",
    abstract: "Get a custom directory"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Directory ID")
  var directoryId: String

  func run() async throws {
    let client = try await global.makeClient()
    let directory = try await client.getCustomDirectory(directoryId: directoryId)
    try printJSON(directory, expand: global.expandedFields)
  }
}

// MARK: - Update Custom Directory

struct UpdateCustomDirectory: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-custom-directory",
    abstract: "Update a custom directory",
    discussion: """
      When --fields is provided it must carry the full fields list: fields \
      omitted from the array are soft-deleted (condition=removed).
      """
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Directory ID")
  var directoryId: String

  @Option(name: .long, help: "Directory name")
  var name: String?

  @Option(name: .long, help: "Directory description")
  var description: String?

  @Flag(name: .long, help: "Clear the directory description")
  var clearDescription = false

  @Option(name: .long, help: "Directory condition: active, inactive, removed")
  var condition: String?

  @Option(name: .long, help: "Allow multiple values per field in records")
  var multiSelect: Bool?

  @Option(
    name: .long, help: "Allow editing records from cards without custom properties permission")
  var allowEditing: Bool?

  @Option(name: .long, help: "Full fields list as a JSON array")
  var fields: String?

  func validate() throws {
    if description != nil && clearDescription {
      throw ValidationError("--description and --clear-description are mutually exclusive")
    }
  }

  func run() async throws {
    let parsedCondition = try parseCustomDirectoryCondition(condition)
    let parsedFields = try parseCustomDirectoryJSON(
      fields, as: [Components.Schemas.UpdateCustomDirectoryFieldRequest].self, fieldName: "fields")
    let descriptionUpdate: String?? =
      if clearDescription {
        .some(nil)
      } else if let description {
        .some(description)
      } else {
        .none
      }
    let client = try await global.makeClient()
    let directory = try await client.updateCustomDirectory(
      directoryId: directoryId,
      name: name,
      description: descriptionUpdate,
      condition: parsedCondition,
      multiSelect: multiSelect,
      allowEditing: allowEditing,
      fields: parsedFields
    )
    try printJSON(directory, expand: global.expandedFields)
  }
}

// MARK: - Delete Custom Directory

struct DeleteCustomDirectory: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "delete-custom-directory",
    abstract: "Delete a custom directory",
    discussion: """
      Soft-deletes the directory (condition=removed). Deletion is not allowed \
      while active custom properties are linked to the directory.
      """
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Directory ID")
  var directoryId: String

  func run() async throws {
    let client = try await global.makeClient()
    let result = try await client.deleteCustomDirectory(directoryId: directoryId)
    try printJSON(result, expand: global.expandedFields)
  }
}
