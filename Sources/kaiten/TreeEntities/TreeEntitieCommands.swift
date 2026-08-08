import ArgumentParser
import KaitenSDK

// MARK: - List Tree Entities

struct ListTreeEntities: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-tree-entities",
    abstract: "List company tree entities (paginated)",
    discussion: """
      Returns nodes of the company entity tree: spaces, documents, document groups and \
      story maps. Kaiten documents the endpoint as under active development, so parameters, \
      attributes and response formats are subject to change. Each entity type carries its \
      own extra fields beyond the common ones.
      """
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Return entities nested in the entity with this UID")
  var parentEntityUid: String?

  @Option(name: .long, help: "Maximum depth level (max: 2)")
  var levelsCount: Int?

  @Option(name: .long, help: "Offset for pagination (default: 0)")
  var offset: Int = 0

  @Option(name: .long, help: "Limit for pagination (default: 500, max: 500)")
  var limit: Int = 500

  func run() async throws {
    let client = try await global.makeClient()
    let page = try await client.listTreeEntities(
      parentEntityUid: parentEntityUid,
      levelsCount: levelsCount,
      offset: offset,
      limit: limit
    )
    try printJSON(page, expand: global.expandedFields)
  }
}
