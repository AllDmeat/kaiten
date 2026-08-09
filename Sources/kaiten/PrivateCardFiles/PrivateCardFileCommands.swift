import ArgumentParser
import Foundation
import KaitenSDK

// MARK: - Attach Private Card File

struct AttachPrivateCardFile: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "attach-private-card-file",
    abstract: "Attach a file to a card addressed by UID (private files)",
    discussion: "Requires \"Restricted file access\" enabled in company settings."
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card UID")
  var cardUid: String

  @Option(name: .long, help: "Path to the file to upload")
  var file: String

  func run() async throws {
    let fileURL = URL(fileURLWithPath: file)
    let fileData: Data
    do {
      fileData = try Data(contentsOf: fileURL)
    } catch {
      throw ValidationError("Cannot read file at \(file): \(error.localizedDescription)")
    }

    let client = try await global.makeClient()
    let attached = try await client.attachPrivateFile(
      cardUid: cardUid, fileData: fileData, filename: fileURL.lastPathComponent)
    try printJSON(attached, expand: global.expandedFields)
  }
}

// MARK: - Get Private Card File

struct GetPrivateCardFile: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "get-private-card-file",
    abstract: "Get the signed URL of a private card file",
    discussion: """
      Requires "Restricted file access" enabled in company settings. The API returns the \
      signed URL as JSON; requesting an inline or attachment disposition makes the API \
      answer with a 302 redirect instead, which this command reports as an error.
      """
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card UID")
  var cardUid: String

  @Option(name: .long, help: "File ID")
  var fileId: String

  @Option(name: .long, help: "One of: json, inline, attachment (default: json)")
  var responseType: String?

  func run() async throws {
    let client = try await global.makeClient()
    let url = try await client.getPrivateFile(
      cardUid: cardUid, fileId: fileId,
      responseType: responseType.map(PrivateCardFileResponseType.init(rawValue:)) ?? .json)
    try printJSON(["url": url], expand: global.expandedFields)
  }
}

// MARK: - Delete Private Card File

struct DeletePrivateCardFile: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "delete-private-card-file",
    abstract: "Delete a private card file",
    discussion: "Requires \"Restricted file access\" enabled in company settings."
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card UID")
  var cardUid: String

  @Option(name: .long, help: "File ID")
  var fileId: String

  func run() async throws {
    let client = try await global.makeClient()
    let deletedId = try await client.deletePrivateFile(cardUid: cardUid, fileId: fileId)
    try printJSON(["id": deletedId], expand: global.expandedFields)
  }
}
