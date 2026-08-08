import ArgumentParser
import Foundation
import KaitenSDK

// MARK: - Attach Card File

struct AttachCardFile: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "attach-card-file",
    abstract: "Attach a file to a card"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

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
    let attached = try await client.attachFile(
      cardId: cardId, fileData: fileData, filename: fileURL.lastPathComponent)
    try printJSON(attached, expand: global.expandedFields)
  }
}

// MARK: - Update Card File

struct UpdateCardFile: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-card-file",
    abstract: "Update a file attached to a card",
    discussion: "The endpoint returns HTTP 200 with no response body."
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  @Option(name: .long, help: "File ID")
  var fileId: Int

  @Option(name: .long, help: "Use the image as the card cover")
  var cardCover: Bool?

  func run() async throws {
    let client = try await global.makeClient()
    try await client.updateFile(cardId: cardId, fileId: fileId, cardCover: cardCover)
  }
}

// MARK: - Detach Card File

struct DetachCardFile: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "detach-card-file",
    abstract: "Detach a file from a card"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  @Option(name: .long, help: "File ID")
  var fileId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let deletedId = try await client.detachFile(cardId: cardId, fileId: fileId)
    try printJSON(["id": deletedId], expand: global.expandedFields)
  }
}
