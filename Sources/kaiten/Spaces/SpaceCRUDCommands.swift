import ArgumentParser
import KaitenSDK
import OpenAPIRuntime

struct CreateSpace: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "create-space",
    abstract: "Create a new space"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Space title")
  var title: String

  @Option(name: .long, help: "External ID")
  var externalId: String?

  @Option(name: .long, help: "Sort order")
  var sortOrder: Double?

  @Option(name: .long, help: "Parent entity UID for nesting the space")
  var parentEntityUid: String?

  @Option(name: .long, help: "Work calendar ID")
  var workCalendarId: String?

  func run() async throws {
    let client = try await global.makeClient()
    let space = try await client.createSpace(
      title: title,
      externalId: externalId,
      parentEntityUid: parentEntityUid,
      sortOrder: sortOrder,
      workCalendarId: workCalendarId
    )
    try printJSON(space, expand: global.expandedFields)
  }
}

struct GetSpace: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "get-space",
    abstract: "Get a space by ID"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Space ID")
  var id: Int

  func run() async throws {
    let client = try await global.makeClient()
    let space = try await client.getSpace(id: id)
    try printJSON(space, expand: global.expandedFields)
  }
}

struct UpdateSpace: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-space",
    abstract: "Update a space"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Space ID")
  var id: Int

  @Option(name: .long, help: "Space title")
  var title: String?

  @Option(name: .long, help: "External ID")
  var externalId: String?

  @Option(name: .long, help: "Sort order")
  var sortOrder: Double?

  @Option(name: .long, help: "Access mode")
  var access: String?

  @Option(name: .long, help: "Parent entity UID for nesting the space")
  var parentEntityUid: String?

  @Option(name: .long, help: "Comma-separated UIDs of card types hidden in the space")
  var hiddenCardTypeUids: String?

  @Option(name: .long, help: "Space settings as a JSON object")
  var settings: String?

  func run() async throws {
    let parsedHiddenCardTypeUids = try parseStringCSV(
      hiddenCardTypeUids, fieldName: "hidden-card-type-uids")
    let parsedSettings = try parseCardTypeJSON(
      settings, as: OpenAPIObjectContainer.self, fieldName: "settings")

    let client = try await global.makeClient()
    let space = try await client.updateSpace(
      id: id,
      title: title,
      externalId: externalId,
      sortOrder: sortOrder,
      access: access,
      parentEntityUid: parentEntityUid,
      hiddenCardTypeUids: parsedHiddenCardTypeUids,
      settings: parsedSettings
    )
    try printJSON(space, expand: global.expandedFields)
  }
}
