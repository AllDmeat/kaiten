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
    abstract: "Get the metadata and signed URL of a private card file",
    discussion: """
      Requires "Restricted file access" enabled in company settings. The API answers 404 \
      for a file uploaded without restricted access.
      """
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card UID")
  var cardUid: String

  @Option(name: .long, help: "File ID")
  var fileId: String

  @Flag(name: .long, help: "Make the signed URL serve the file as an attachment")
  var download = false

  @Option(name: .long, help: "Deprecated: the API ignores it, so it is not sent")
  var responseType: String?

  func run() async throws {
    let client = try await global.makeClient()
    let file = try await client.getPrivateCardFile(
      cardUid: cardUid, fileId: fileId, download: download ? true : nil)
    try printJSON(file, expand: global.expandedFields)
  }
}

// MARK: - Update Private Card File

struct UpdatePrivateCardFile: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-private-card-file",
    abstract: "Update a private card file",
    discussion: """
      Requires "Restricted file access" enabled in company settings. Setting --card-cover \
      to true additionally requires card update permission.
      """
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card UID")
  var cardUid: String

  @Option(name: .long, help: "File ID")
  var fileId: String

  @Option(name: .long, help: "New file name")
  var name: String?

  @Option(name: .long, help: "Use the image as the card cover")
  var cardCover: Bool?

  func run() async throws {
    let client = try await global.makeClient()
    let file = try await client.updatePrivateFile(
      cardUid: cardUid, fileId: fileId, name: name, cardCover: cardCover)
    try printJSON(file, expand: global.expandedFields)
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
