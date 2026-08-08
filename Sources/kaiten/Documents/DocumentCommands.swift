import ArgumentParser
import Foundation
import KaitenSDK

// MARK: - Documents

func parseDocumentAccess(_ rawValue: String?) throws -> DocumentAccess? {
  guard let rawValue else { return nil }
  let access = DocumentAccess(rawValue: rawValue)
  guard DocumentAccess.allCases.contains(access) else {
    let allowed = DocumentAccess.allCases.map(\.rawValue).joined(separator: ", ")
    throw ValidationError("Invalid document access: '\(rawValue)'. Allowed values: \(allowed)")
  }
  return access
}

func parseDocumentIconType(_ rawValue: String?) throws -> DocumentIconType? {
  guard let rawValue else { return nil }
  let iconType = DocumentIconType(rawValue: rawValue)
  guard DocumentIconType.allCases.contains(iconType) else {
    let allowed = DocumentIconType.allCases.map(\.rawValue).joined(separator: ", ")
    throw ValidationError("Invalid icon type: '\(rawValue)'. Allowed values: \(allowed)")
  }
  return iconType
}

/// Decodes a JSON command-line argument into a generated OpenAPI type.
///
/// Malformed JSON fails locally with a validation error — the value is never
/// silently dropped or forwarded to the SDK.
func parseDocumentJSON<T: Decodable>(
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

/// Parses `--published-version`: a version number, or the literal `current`.
func parsePublishedVersion(
  _ rawValue: String?
) throws -> Components.Schemas.UpdateDocumentRequest.published_versionPayload? {
  guard let rawValue else { return nil }
  if rawValue == "current" {
    return .init(value1: nil, value2: rawValue)
  }
  guard let number = Double(rawValue) else {
    throw ValidationError(
      "Invalid published version: '\(rawValue)'. Pass a version number or 'current'")
  }
  return .init(value1: number, value2: nil)
}

// MARK: - List Documents

struct ListDocuments: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-documents",
    abstract: "List documents (paginated)"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Search query string")
  var query: String?

  @Option(name: .long, help: "Offset for pagination (default: 0)")
  var offset: Int = 0

  @Option(name: .long, help: "Limit for pagination (default: 100)")
  var limit: Int = 100

  func run() async throws {
    let client = try await global.makeClient()
    let page = try await client.listDocuments(query: query, offset: offset, limit: limit)
    try printJSON(page, expand: global.expandedFields)
  }
}

// MARK: - Search Documents

struct SearchDocuments: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "search-documents",
    abstract: "Search documents via OpenSearch (version=2)",
    discussion: """
      Prints an object with `result` and an opaque `position` cursor; pass that value back via \
      --start-position to fetch the next page.
      """
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Search query string")
  var query: String?

  @Option(name: .long, help: "Filter condition")
  var condition: Int?

  @Option(name: .long, help: "Comma-separated fields to search in, e.g. 'data'")
  var fields: String?

  @Option(name: .long, help: "Search cursor from the previous response")
  var startPosition: String?

  @Option(name: .long, help: "Include the preview object in each result (needs --fields data)")
  var includeSearchPreview: Bool?

  @Option(name: .long, help: "Offset for pagination (default: 0)")
  var offset: Int = 0

  @Option(name: .long, help: "Limit for pagination (default: 100)")
  var limit: Int = 100

  func run() async throws {
    let client = try await global.makeClient()
    let response = try await client.searchDocuments(
      query: query,
      condition: condition,
      fields: fields,
      startPosition: startPosition,
      includeSearchPreview: includeSearchPreview,
      offset: offset,
      limit: limit
    )
    try printJSON(response, expand: global.expandedFields)
  }
}

// MARK: - Get Document

struct GetDocument: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "get-document",
    abstract: "Get a document, including its content",
    discussion: """
      The `data` field carries the ProseMirror content as a JSON-encoded string, not an object, \
      despite what the Kaiten documentation declares.
      """
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Document UID")
  var documentUid: String

  func run() async throws {
    let client = try await global.makeClient()
    let document = try await client.getDocument(uid: documentUid)
    try printJSON(document, expand: global.expandedFields)
  }
}

// MARK: - Create Document

struct CreateDocument: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "create-document",
    abstract: "Create a document"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Sort order, greater than 0")
  var sortOrder: Double

  @Option(name: .long, help: "Document title")
  var title: String?

  @Option(name: .long, help: "Parent tree entity UID")
  var parentEntityUid: String?

  @Option(name: .long, help: "Role id for everyone access")
  var forEveryoneAccessRoleId: String?

  @Option(name: .long, help: "Document UID to copy")
  var cloneUid: String?

  @Option(name: .long, help: "Document version to copy")
  var cloneVersion: Double?

  @Option(name: .long, help: "Unique document key within the company")
  var key: String?

  func run() async throws {
    let client = try await global.makeClient()
    let document = try await client.createDocument(
      sortOrder: sortOrder,
      title: title,
      parentEntityUid: parentEntityUid,
      forEveryoneAccessRoleId: forEveryoneAccessRoleId,
      cloneUid: cloneUid,
      cloneVersion: cloneVersion,
      key: key
    )
    try printJSON(document, expand: global.expandedFields)
  }
}

// MARK: - Update Document

struct UpdateDocument: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-document",
    abstract: "Update a document"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Document UID")
  var documentUid: String

  @Option(name: .long, help: "Document title")
  var title: String?

  @Option(name: .long, help: "Sort order, greater than 0")
  var sortOrder: Double?

  @Option(name: .long, help: "Publication date (ISO 8601)")
  var publishDate: String?

  @Option(name: .long, help: "Document content as a ProseMirror JSON object")
  var data: String?

  @Option(name: .long, help: "Access type: for_everyone, by_invite")
  var access: String?

  @Option(name: .long, help: "Parent tree entity UID")
  var parentEntityUid: String?

  @Option(name: .long, help: "Role id for everyone access")
  var forEveryoneAccessRoleId: String?

  @Option(name: .long, help: "Whether the document is publicly available (legacy field)")
  var `public`: Bool?

  @Option(name: .long, help: "Redirect URL")
  var redirectUrl: String?

  @Option(name: .long, help: "Whether the document is hidden on the public site")
  var hiddenOnPublicSite: Bool?

  @Option(name: .long, help: "Appearance settings as a JSON object; the server merges shallowly")
  var settings: String?

  @Option(name: .long, help: "Document version to restore")
  var backupVersion: Double?

  @Option(name: .long, help: "Version to publish on the public site, or 'current'")
  var publishedVersion: String?

  @Option(name: .long, help: "Unique document key within the company")
  var key: String?

  @Option(name: .long, help: "Icon type: emoji, material_icon")
  var iconType: String?

  @Option(name: .long, help: "Icon value: emoji character or material icon name")
  var iconValue: String?

  @Option(name: .long, help: "Icon color index (1-17)")
  var iconColor: Int?

  @Option(name: .long, help: "Notification period start date")
  var notificationPeriodStart: String?

  @Option(name: .long, help: "Notification period end date")
  var notificationPeriodEnd: String?

  @Option(name: .long, help: "URL slug: lowercase latin letters, digits and hyphens")
  var slug: String?

  func run() async throws {
    let parsedData = try parseDocumentJSON(
      data, as: Components.Schemas.UpdateDocumentRequest.dataPayload.self, fieldName: "data")
    let parsedSettings = try parseDocumentJSON(
      settings, as: Components.Schemas.DocumentSettings.self, fieldName: "settings")
    let parsedAccess = try parseDocumentAccess(access)
    let parsedIconType = try parseDocumentIconType(iconType)
    let parsedPublishedVersion = try parsePublishedVersion(publishedVersion)

    let client = try await global.makeClient()
    let document = try await client.updateDocument(
      uid: documentUid,
      title: title,
      sortOrder: sortOrder,
      publishDate: publishDate,
      data: parsedData,
      access: parsedAccess,
      parentEntityUid: parentEntityUid,
      forEveryoneAccessRoleId: forEveryoneAccessRoleId,
      isPublic: `public`,
      redirectUrl: redirectUrl,
      hiddenOnPublicSite: hiddenOnPublicSite,
      settings: parsedSettings,
      backupVersion: backupVersion,
      publishedVersion: parsedPublishedVersion,
      key: key,
      iconType: parsedIconType,
      iconValue: iconValue,
      iconColor: iconColor,
      notificationPeriodStart: notificationPeriodStart,
      notificationPeriodEnd: notificationPeriodEnd,
      slug: slug
    )
    try printJSON(document, expand: global.expandedFields)
  }
}

// MARK: - Delete Document

struct DeleteDocument: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "delete-document",
    abstract: "Remove a document",
    discussion: """
      A document that still has child tree entities cannot be removed — the API answers \
      HTTP 400 until they are removed or moved.
      """
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Document UID")
  var documentUid: String

  func run() async throws {
    let client = try await global.makeClient()
    let document = try await client.deleteDocument(uid: documentUid)
    try printJSON(document, expand: global.expandedFields)
  }
}
