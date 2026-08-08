import ArgumentParser
import KaitenSDK

// MARK: - Custom Directory Fields

func parseCustomDirectoryFieldType(_ rawValue: String) throws -> CustomDirectoryFieldType {
  let type = CustomDirectoryFieldType(rawValue: rawValue)
  guard CustomDirectoryFieldType.allCases.contains(type) else {
    let allowed = CustomDirectoryFieldType.allCases.map(\.rawValue).joined(separator: ", ")
    throw ValidationError("Invalid field type: '\(rawValue)'. Allowed values: \(allowed)")
  }
  return type
}

// MARK: - List Custom Directory Fields

struct ListCustomDirectoryFields: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-custom-directory-fields",
    abstract: "List fields of a custom directory",
    discussion: "The custom directories API is documented as beta and may change."
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Custom directory ID")
  var directoryId: String

  @Option(name: .long, help: "Include the author user object in each field")
  var includeAuthor: Bool?

  @Option(name: .long, help: "Comma-separated conditions to filter by: active, inactive, removed")
  var conditions: String?

  func run() async throws {
    let parsedConditions = try parseCustomDirectoryConditions(conditions)

    let client = try await global.makeClient()
    let fields = try await client.listCustomDirectoryFields(
      directoryId: directoryId,
      includeAuthor: includeAuthor,
      conditions: parsedConditions
    )
    try printJSON(fields, expand: global.expandedFields)
  }
}

// MARK: - Create Custom Directory Field

struct CreateCustomDirectoryField: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "create-custom-directory-field",
    abstract: "Create a field in a custom directory",
    discussion: "The custom directories API is documented as beta and may change."
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Custom directory ID")
  var directoryId: String

  @Option(name: .long, help: "Field name (1-256 characters)")
  var name: String

  @Option(
    name: .long,
    help:
      "Field type: string, number, date, email, url, phone, checkbox, select, user, catalog, directory_link, file"
  )
  var type: String

  @Option(name: .long, help: "Field position (from 0)")
  var sortOrder: Int?

  @Option(name: .long, help: "Required field flag (API default: false)")
  var required: Bool?

  @Option(name: .long, help: "Display field flag (API default: false)")
  var isDisplay: Bool?

  func run() async throws {
    let fieldType = try parseCustomDirectoryFieldType(type)

    let client = try await global.makeClient()
    let field = try await client.createCustomDirectoryField(
      directoryId: directoryId,
      name: name,
      type: fieldType,
      sortOrder: sortOrder,
      required: required,
      isDisplay: isDisplay
    )
    try printJSON(field, expand: global.expandedFields)
  }
}

// MARK: - Get Custom Directory Field

struct GetCustomDirectoryField: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "get-custom-directory-field",
    abstract: "Get a field of a custom directory",
    discussion: "The custom directories API is documented as beta and may change."
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Custom directory ID")
  var directoryId: String

  @Option(name: .long, help: "Field ID")
  var fieldId: String

  func run() async throws {
    let client = try await global.makeClient()
    let field = try await client.getCustomDirectoryField(
      directoryId: directoryId, fieldId: fieldId)
    try printJSON(field, expand: global.expandedFields)
  }
}

// MARK: - Update Custom Directory Field

struct UpdateCustomDirectoryField: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-custom-directory-field",
    abstract: "Update a field of a custom directory",
    discussion: "The custom directories API is documented as beta and may change."
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Custom directory ID")
  var directoryId: String

  @Option(name: .long, help: "Field ID")
  var fieldId: String

  @Option(name: .long, help: "Field name (1-256 characters)")
  var name: String?

  @Option(name: .long, help: "Field condition: active, inactive, removed")
  var condition: String?

  @Option(name: .long, help: "Field position (from 0)")
  var sortOrder: Int?

  @Option(name: .long, help: "Required field flag")
  var required: Bool?

  @Option(name: .long, help: "Display field flag")
  var isDisplay: Bool?

  func run() async throws {
    let parsedCondition = try parseCustomDirectoryCondition(condition)

    let client = try await global.makeClient()
    let field = try await client.updateCustomDirectoryField(
      directoryId: directoryId,
      fieldId: fieldId,
      name: name,
      condition: parsedCondition,
      sortOrder: sortOrder,
      required: required,
      isDisplay: isDisplay
    )
    try printJSON(field, expand: global.expandedFields)
  }
}

// MARK: - Delete Custom Directory Field

struct DeleteCustomDirectoryField: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "delete-custom-directory-field",
    abstract: "Delete a field of a custom directory",
    discussion:
      "Soft-deletes the field (its condition becomes removed) and prints the removed field. The custom directories API is documented as beta and may change."
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Custom directory ID")
  var directoryId: String

  @Option(name: .long, help: "Field ID")
  var fieldId: String

  func run() async throws {
    let client = try await global.makeClient()
    let field = try await client.deleteCustomDirectoryField(
      directoryId: directoryId, fieldId: fieldId)
    try printJSON(field, expand: global.expandedFields)
  }
}
