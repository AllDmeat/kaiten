import ArgumentParser
import Foundation
import KaitenSDK

// MARK: - List Service Desk Services

struct ListServiceDeskServices: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-service-desk-services",
    abstract: "List service desk services in the company",
    discussion: "The API answers HTTP 403 for tokens without access to the service desk."
  )

  @OptionGroup var global: GlobalOptions

  func run() async throws {
    let client = try await global.makeClient()
    let services = try await client.listServiceDeskServices()
    try printJSON(services, expand: global.expandedFields)
  }
}
