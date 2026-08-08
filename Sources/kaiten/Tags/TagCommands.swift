import ArgumentParser
import KaitenSDK

// MARK: - List Tags

struct ListTags: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-tags",
    abstract: "List tags in the company"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Maximum amount of tags (default 100, max 100)")
  var limit: Int?

  @Option(name: .long, help: "Number of records to skip")
  var offset: Int?

  @Option(name: .long, help: "Filter by space ID")
  var spaceId: Int?

  @Option(name: .long, help: "Comma-separated tag IDs to filter by")
  var ids: String?

  @Option(name: .long, help: "Tag name contains text search filter")
  var query: String?

  func run() async throws {
    let client = try await global.makeClient()
    let tags = try await client.listTags(
      limit: limit,
      offset: offset,
      spaceId: spaceId,
      ids: ids,
      query: query
    )
    try printJSON(tags, expand: global.expandedFields)
  }
}

// MARK: - Add Tag

struct AddTag: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "add-tag",
    abstract: "Add a tag to the company"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Tag name (1 to 128 characters)")
  var name: String

  func run() async throws {
    let client = try await global.makeClient()
    let tag = try await client.addTag(name: name)
    try printJSON(tag, expand: global.expandedFields)
  }
}
