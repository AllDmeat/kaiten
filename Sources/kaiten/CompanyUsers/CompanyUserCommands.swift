import ArgumentParser
import KaitenSDK

// MARK: - List Company Users

struct ListCompanyUsers: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-company-users",
    abstract: "List company users",
    discussion: """
      Requires an API token of a user with access to the administrative section "Members"; \
      without it the API returns 403.
      """
  )

  @OptionGroup var global: GlobalOptions

  @Flag(name: .long, help: "Return only invites")
  var invitesOnly: Bool = false

  @Flag(name: .long, help: "Add data about the user rights transfer process")
  var withTransferAccessStatus: Bool = false

  @Flag(
    name: .long,
    help: "Return users for the \"Members\" administrative section, paginated with --limit/--offset"
  )
  var forMembersSection: Bool = false

  @Flag(name: .long, help: "Return the company owner")
  var ownerOnly: Bool = false

  @Flag(name: .long, help: "Return only users with paid access")
  var onlyPaid: Bool = false

  @Flag(
    name: .long,
    help:
      "Return only the number of users (works only with --for-members-section or --only-virtual)"
  )
  var onlyRecordsCount: Bool = false

  @Flag(name: .long, help: "Return only virtual users, paginated with --limit/--offset")
  var onlyVirtual: Bool = false

  @Option(name: .long, help: "Number of records to skip")
  var offset: Int?

  @Option(name: .long, help: "Maximum amount of users in response (default 100, max 100)")
  var limit: Int?

  @Option(
    name: .long, help: "Filter by email and full name (works only with --for-members-section)")
  var query: String?

  @Option(name: .long, help: "Filter by access to Kaiten (works only with --for-members-section)")
  var accessTypePermissions: String?

  @Option(
    name: .long, help: "Filter by access to Service Desk (works only with --for-members-section)")
  var sdAccessType: String?

  @Option(
    name: .long,
    help: "Filter by users consuming the license (works only with --for-members-section)")
  var takeLicence: String?

  @Option(
    name: .long,
    help: "Filter by temporarily inactive users (works only with --for-members-section)")
  var temporarilyInactiveStatus: String?

  @Option(
    name: .long,
    help: "Comma-separated group IDs to filter by (works only with --for-members-section)")
  var groupIds: String?

  @Option(
    name: .long,
    help: "Comma-separated permissions to filter by (works only with --for-members-section)")
  var permissions: String?

  func run() async throws {
    let client = try await global.makeClient()
    let users = try await client.listCompanyUsers(
      invitesOnly: invitesOnly ? true : nil,
      withTransferAccessStatus: withTransferAccessStatus ? true : nil,
      forMembersSection: forMembersSection ? true : nil,
      ownerOnly: ownerOnly ? true : nil,
      onlyPaid: onlyPaid ? true : nil,
      onlyRecordsCount: onlyRecordsCount ? true : nil,
      onlyVirtual: onlyVirtual ? true : nil,
      offset: offset,
      limit: limit,
      query: query,
      accessTypePermissions: accessTypePermissions,
      sdAccessType: sdAccessType,
      takeLicence: takeLicence,
      temporarilyInactiveStatus: temporarilyInactiveStatus,
      groupIds: try parseIntegerCSV(groupIds, fieldName: "--group-ids"),
      permissions: try parseIntegerCSV(permissions, fieldName: "--permissions")
    )
    try printJSON(users, expand: global.expandedFields)
  }
}

// MARK: - Update Company User

struct UpdateCompanyUser: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-company-user",
    abstract: "Update a company user",
    discussion: """
      Requires an API token of a user with access to the administrative section "Members"; \
      without it the API returns 403.
      """
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "User ID")
  var id: Int

  @Option(
    name: .long,
    help: """
      User access: 0 - no access, 1 - full access to Kaiten without service desk, \
      2 - guest access to Kaiten without service desk, 4 - access only to service desk, \
      5 - full access to Kaiten and service desk, 6 - guest access to Kaiten and service desk
      """
  )
  var appsPermissions: Int?

  @Option(
    name: .long,
    help:
      "Temporarily inactive: user stays in the company but cannot sign in and does not need a license"
  )
  var temporarilyInactive: Bool?

  func run() async throws {
    let client = try await global.makeClient()
    let user = try await client.updateCompanyUser(
      id: id,
      appsPermissions: appsPermissions,
      temporarilyInactive: temporarilyInactive
    )
    try printJSON(user, expand: global.expandedFields)
  }
}

// MARK: - Remove Virtual User

struct RemoveVirtualUser: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "remove-virtual-user",
    abstract: "Remove a virtual user",
    discussion: """
      Requires an API token of a user with access to the administrative section \
      "Resource planning"; without it the API returns 403.
      """
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "User ID")
  var id: Int

  func run() async throws {
    let client = try await global.makeClient()
    let deletedId = try await client.removeVirtualUser(id: id)
    try printJSON(["id": deletedId])
  }
}
