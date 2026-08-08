import ArgumentParser
import Foundation
import KaitenSDK

// MARK: - Private Custom Property Files

func parseCustomPropertyFileResponseType(_ rawValue: String) throws
  -> CustomPropertyFileResponseType
{
  let type = CustomPropertyFileResponseType(rawValue: rawValue)
  guard CustomPropertyFileResponseType.allCases.contains(type) else {
    let allowed = CustomPropertyFileResponseType.allCases.map(\.rawValue).joined(separator: ", ")
    throw ValidationError("Invalid response type: '\(rawValue)'. Allowed values: \(allowed)")
  }
  return type
}

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
    abstract: "Get the signed URL of a custom property file",
    discussion: """
      Requires the "Restricted file access" company setting to be enabled. With \
      response type json (the default) the API returns the signed URL. With inline \
      or attachment the API redirects to the file itself, so the response cannot be \
      printed as JSON.
      """
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card UID")
  var cardUid: String

  @Option(name: .long, help: "Custom property UID")
  var propertyUid: String

  @Option(name: .long, help: "File ID")
  var fileId: String

  @Option(name: .long, help: "Response type: json, inline, attachment")
  var responseType: String = "json"

  func run() async throws {
    let type = try parseCustomPropertyFileResponseType(responseType)
    let client = try await global.makeClient()
    let url = try await client.getCustomPropertyFileUrl(
      cardUid: cardUid, propertyUid: propertyUid, fileId: fileId, responseType: type)
    try printJSON(["url": url], expand: global.expandedFields)
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
