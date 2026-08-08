import ArgumentParser
import Foundation
import KaitenSDK

// MARK: - Attach Comment File

struct AttachCommentFile: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "attach-comment-file",
    abstract: "Attach a file to a card comment",
    discussion: "The endpoint requires \"Restricted file access\" enabled in company settings."
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card UID")
  var cardUid: String

  @Option(name: .long, help: "Comment UID")
  var commentUid: String

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
    let attached = try await client.attachFileToComment(
      cardUid: cardUid, commentUid: commentUid, fileData: fileData,
      filename: fileURL.lastPathComponent)
    try printJSON(attached, expand: global.expandedFields)
  }
}

// MARK: - Get Comment File

struct GetCommentFile: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "get-comment-file",
    abstract: "Get a signed URL for a file attached to a card comment",
    discussion: """
      The endpoint requires "Restricted file access" enabled in company settings. The signed \
      URL is requested in JSON form; the endpoint's other dispositions answer with a redirect \
      to the file content, which the CLI cannot print.
      """
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card UID")
  var cardUid: String

  @Option(name: .long, help: "Comment UID")
  var commentUid: String

  @Option(name: .long, help: "File ID")
  var fileId: String

  func run() async throws {
    let client = try await global.makeClient()
    let signedUrl = try await client.getCommentFile(
      cardUid: cardUid, commentUid: commentUid, fileId: fileId)
    try printJSON(signedUrl, expand: global.expandedFields)
  }
}

// MARK: - Delete Comment File

struct DeleteCommentFile: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "delete-comment-file",
    abstract: "Delete a file attached to a card comment",
    discussion: "The endpoint requires \"Restricted file access\" enabled in company settings."
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card UID")
  var cardUid: String

  @Option(name: .long, help: "Comment UID")
  var commentUid: String

  @Option(name: .long, help: "File ID")
  var fileId: String

  func run() async throws {
    let client = try await global.makeClient()
    let deletedId = try await client.deleteCommentFile(
      cardUid: cardUid, commentUid: commentUid, fileId: fileId)
    try printJSON(["id": deletedId], expand: global.expandedFields)
  }
}
