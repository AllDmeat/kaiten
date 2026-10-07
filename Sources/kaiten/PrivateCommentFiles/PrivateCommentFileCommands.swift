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

  @Option(name: .long, help: "Comment UID, or new for a comment that has not been created yet")
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
    abstract: "Get the metadata and signed URL of a file attached to a card comment",
    discussion: """
      The endpoint requires "Restricted file access" enabled in company settings. The API \
      answers 404 for a file uploaded without restricted access.
      """
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card UID")
  var cardUid: String

  @Option(name: .long, help: "Comment UID, or new for a comment that has not been created yet")
  var commentUid: String

  @Option(name: .long, help: "File ID")
  var fileId: String

  @Flag(name: .long, help: "Make the signed URL serve the file as an attachment")
  var download = false

  func run() async throws {
    let client = try await global.makeClient()
    let file = try await client.getCommentFile(
      cardUid: cardUid, commentUid: commentUid, fileId: fileId, download: download ? true : nil)
    try printJSON(file, expand: global.expandedFields)
  }
}

// MARK: - Update Comment File

struct UpdateCommentFile: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-comment-file",
    abstract: "Update a file attached to a card comment",
    discussion: """
      Requires "Restricted file access" enabled in company settings. Setting --card-cover \
      to true additionally requires card update permission.
      """
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card UID")
  var cardUid: String

  @Option(name: .long, help: "Comment UID, or new for a comment that has not been created yet")
  var commentUid: String

  @Option(name: .long, help: "File ID")
  var fileId: String

  @Option(name: .long, help: "New file name")
  var name: String?

  @Option(name: .long, help: "Use the image as the card cover")
  var cardCover: Bool?

  func run() async throws {
    let client = try await global.makeClient()
    let file = try await client.updateCommentFile(
      cardUid: cardUid, commentUid: commentUid, fileId: fileId, name: name,
      cardCover: cardCover)
    try printJSON(file, expand: global.expandedFields)
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

  @Option(name: .long, help: "Comment UID, or new for a comment that has not been created yet")
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
