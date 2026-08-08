import ArgumentParser
import Foundation
import KaitenSDK

// MARK: - Get Document Schema

struct GetDocumentSchema: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "get-document-schema",
    abstract: "Get the document data schema",
    discussion: """
      Returns the schema used to validate and describe document data in ProseMirror JSON \
      format. The response shape follows --format: a JSON Schema draft-06 document by default, \
      or sanitized ProseMirror node and mark specs with runtime-only fields omitted.
      """
  )

  @OptionGroup var global: GlobalOptions

  @Option(
    name: .long,
    help: "Document schema version: 'latest', or a concrete version such as 'v25'")
  var id: String

  @Option(name: .long, help: "Response format: draft-06 (default), prosemirror")
  var format: String?

  func run() async throws {
    let parsedFormat = try format.map { rawValue in
      let format = DocumentSchemaFormat(rawValue: rawValue)
      guard DocumentSchemaFormat.allCases.contains(format) else {
        let allowed = DocumentSchemaFormat.allCases.map(\.rawValue).joined(separator: ", ")
        throw ValidationError("Invalid format: '\(rawValue)'. Allowed values: \(allowed)")
      }
      return format
    }
    let client = try await global.makeClient()
    let schema = try await client.getDocumentSchema(id: id, format: parsedFormat)
    try printJSON(schema, expand: global.expandedFields)
  }
}
