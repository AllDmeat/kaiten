import ArgumentParser
import Foundation
import KaitenSDK

// MARK: - Document Groups

func parseDocumentGroupAccess(_ rawValue: String) throws -> DocumentGroupAccess {
  let access = DocumentGroupAccess(rawValue: rawValue)
  guard DocumentGroupAccess.allCases.contains(access) else {
    let allowed = DocumentGroupAccess.allCases.map(\.rawValue).joined(separator: ", ")
    throw ValidationError("Invalid access type: '\(rawValue)'. Allowed values: \(allowed)")
  }
  return access
}

// MARK: - List Document Groups

struct ListDocumentGroups: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-document-groups",
    abstract: "List document groups"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Search query string")
  var query: String?

  @Option(name: .long, help: "Minimum user role: 1 - reader, 2 - writer, 3 - admin")
  var role: Int?

  @Option(name: .long, help: "Number of records to skip")
  var offset: Int?

  @Option(name: .long, help: "Maximum number of records to return")
  var limit: Int?

  func run() async throws {
    let client = try await global.makeClient()
    let groups = try await client.listDocumentGroups(
      query: query, role: role, offset: offset, limit: limit)
    try printJSON(groups, expand: global.expandedFields)
  }
}

// MARK: - Search Document Groups

struct SearchDocumentGroups: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "search-document-groups",
    abstract: "Search document groups via OpenSearch",
    discussion: """
      Returns matching groups under `result` and an opaque cursor under `position`; \
      pass that cursor as --start-position to fetch the next page.
      """
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Search query string")
  var query: String?

  @Option(name: .long, help: "Filter condition")
  var condition: Int?

  @Option(name: .long, help: "Search cursor - the position value from the previous response")
  var startPosition: String?

  @Option(name: .long, help: "Minimum user role: 1 - reader, 2 - writer, 3 - admin")
  var role: Int?

  @Option(name: .long, help: "Number of records to skip")
  var offset: Int?

  @Option(name: .long, help: "Maximum number of records to return")
  var limit: Int?

  func run() async throws {
    let client = try await global.makeClient()
    let result = try await client.searchDocumentGroups(
      query: query,
      condition: condition,
      startPosition: startPosition,
      role: role,
      offset: offset,
      limit: limit
    )
    try printJSON(result, expand: global.expandedFields)
  }
}

// MARK: - Get Document Group

struct GetDocumentGroup: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "get-document-group",
    abstract: "Get a document group"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Document group UID")
  var documentGroupUid: String

  @Option(
    name: .long,
    help: "Comma-separated relations to include: documents, groups, parent, author"
  )
  var relations: String?

  func run() async throws {
    let parsedRelations = try parseStringCSV(relations, fieldName: "--relations")
    let client = try await global.makeClient()
    let group = try await client.getDocumentGroup(
      uid: documentGroupUid, relations: parsedRelations)
    try printJSON(group, expand: global.expandedFields)
  }
}

// MARK: - Create Document Group

struct CreateDocumentGroup: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "create-document-group",
    abstract: "Create a document group"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Document group title")
  var title: String

  @Option(name: .long, help: "Parent tree entity UID")
  var parentEntityUid: String?

  @Option(name: .long, help: "Role id for everyone access")
  var forEveryoneAccessRoleId: String?

  @Option(name: .long, help: "Sort order (greater than 0)")
  var sortOrder: Double?

  @Option(name: .long, help: "Unique document group key within the company")
  var key: String?

  func run() async throws {
    let client = try await global.makeClient()
    let group = try await client.createDocumentGroup(
      title: title,
      parentEntityUid: parentEntityUid,
      forEveryoneAccessRoleId: forEveryoneAccessRoleId,
      sortOrder: sortOrder,
      key: key
    )
    try printJSON(group, expand: global.expandedFields)
  }
}

// MARK: - Update Document Group

struct UpdateDocumentGroup: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-document-group",
    abstract: "Update a document group"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Document group UID")
  var documentGroupUid: String

  @Option(name: .long, help: "Document group title")
  var title: String?

  @Option(name: .long, help: "Parent tree entity UID; moves the group in the tree")
  var parentEntityUid: String?

  @Option(name: .long, help: "Sort order (greater than 0)")
  var sortOrder: Double?

  @Option(name: .long, help: "Access type: for_everyone, by_invite")
  var access: String?

  @Option(name: .long, help: "Role id for everyone access")
  var forEveryoneAccessRoleId: String?

  @Option(name: .long, help: "Custom hostname for the public site")
  var hostname: String?

  @Option(name: .long, help: "Redirect URL")
  var redirectUrl: String?

  @Option(name: .long, help: "Unique document group key; cannot be changed once set")
  var key: String?

  @Option(name: .long, help: "Icon type")
  var iconType: String?

  @Option(name: .long, help: "Icon value (icon name for the material_icon type)")
  var iconValue: String?

  @Option(name: .long, help: "Icon color")
  var iconColor: Int?

  @Option(name: .long, help: "Hide the group on the public site (true/false)")
  var hiddenOnPublicSite: Bool?

  @Option(
    name: .long,
    help:
      "Mark the group as a news feed (true/false); requires a hostname on this folder or a parent"
  )
  var newsFeed: Bool?

  @Option(name: .long, help: "UID of the document used as the folder home page")
  var indexDocumentUid: String?

  func run() async throws {
    let parsedAccess = try access.map(parseDocumentGroupAccess)
    let client = try await global.makeClient()
    let group = try await client.updateDocumentGroup(
      uid: documentGroupUid,
      title: title,
      parentEntityUid: parentEntityUid,
      sortOrder: sortOrder,
      access: parsedAccess,
      forEveryoneAccessRoleId: forEveryoneAccessRoleId,
      hostname: hostname,
      redirectUrl: redirectUrl,
      key: key,
      iconType: iconType,
      iconValue: iconValue,
      iconColor: iconColor,
      hiddenOnPublicSite: hiddenOnPublicSite,
      newsFeed: newsFeed,
      indexDocumentUid: indexDocumentUid
    )
    try printJSON(group, expand: global.expandedFields)
  }
}

// MARK: - Delete Document Group

struct DeleteDocumentGroup: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "delete-document-group",
    abstract: "Remove a document group",
    discussion: """
      The API answers HTTP 400 while the group still has child tree entities - \
      remove or move them first.
      """
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Document group UID")
  var documentGroupUid: String

  func run() async throws {
    let client = try await global.makeClient()
    let removed = try await client.deleteDocumentGroup(uid: documentGroupUid)
    try printJSON(removed, expand: global.expandedFields)
  }
}
