import ArgumentParser
import Foundation
import KaitenSDK

// MARK: - Private Custom Property Files

// MARK: - Attach Custom Property File

struct AttachCustomPropertyFile: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "attach-custom-property-file",
    abstract: "Attach a file to a card custom property",
    discussion: "Requires the \"Restricted file access\" company setting to be enabled."
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card UID")
  var cardUid: String

  @Option(name: .long, help: "Custom property UID")
  var propertyUid: String

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
    let attached = try await client.attachFileToCustomProperty(
      cardUid: cardUid, propertyUid: propertyUid, fileData: fileData,
      filename: fileURL.lastPathComponent)
    try printJSON(attached, expand: global.expandedFields)
  }
}

// MARK: - Get Custom Property File

struct GetCustomPropertyFile: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "get-custom-property-file",
    abstract: "Get the metadata and signed URL of a custom property file",
    discussion: """
      Requires the "Restricted file access" company setting to be enabled. The API answers \
      404 for a file uploaded without restricted access.
      """
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card UID")
  var cardUid: String

  @Option(name: .long, help: "Custom property UID")
  var propertyUid: String

  @Option(name: .long, help: "File ID")
  var fileId: String

  @Flag(name: .long, help: "Make the signed URL serve the file as an attachment")
  var download = false

  @Option(name: .long, help: "Deprecated: the API ignores it, so it is not sent")
  var responseType: String?

  func run() async throws {
    let client = try await global.makeClient()
    let file = try await client.getCustomPropertyFile(
      cardUid: cardUid, propertyUid: propertyUid, fileId: fileId,
      download: download ? true : nil)
    try printJSON(file, expand: global.expandedFields)
  }
}

// MARK: - Update Custom Property File

struct UpdateCustomPropertyFile: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-custom-property-file",
    abstract: "Update a custom property file",
    discussion: """
      Requires "Restricted file access" enabled in company settings. Setting --card-cover \
      to true additionally requires card update permission.
      """
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card UID")
  var cardUid: String

  @Option(name: .long, help: "Custom property UID")
  var propertyUid: String

  @Option(name: .long, help: "File ID")
  var fileId: String

  @Option(name: .long, help: "New file name")
  var name: String?

  @Option(name: .long, help: "Use the image as the card cover")
  var cardCover: Bool?

  func run() async throws {
    let client = try await global.makeClient()
    let file = try await client.updateCustomPropertyFile(
      cardUid: cardUid, propertyUid: propertyUid, fileId: fileId, name: name,
      cardCover: cardCover)
    try printJSON(file, expand: global.expandedFields)
  }
}

// MARK: - Delete Custom Property File

struct DeleteCustomPropertyFile: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "delete-custom-property-file",
    abstract: "Delete a custom property file",
    discussion: "Requires the \"Restricted file access\" company setting to be enabled."
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card UID")
  var cardUid: String

  @Option(name: .long, help: "Custom property UID")
  var propertyUid: String

  @Option(name: .long, help: "File ID")
  var fileId: String

  func run() async throws {
    let client = try await global.makeClient()
    let deletedId = try await client.deleteCustomPropertyFile(
      cardUid: cardUid, propertyUid: propertyUid, fileId: fileId)
    try printJSON(["id": deletedId], expand: global.expandedFields)
  }
}
