import ArgumentParser
import Foundation
import KaitenSDK

// MARK: - Automations

func parseAutomationType(_ rawValue: String) throws -> AutomationType {
  let type = AutomationType(rawValue: rawValue)
  guard AutomationType.allCases.contains(type) else {
    let allowed = AutomationType.allCases.map(\.rawValue).joined(separator: ", ")
    throw ValidationError("Invalid automation type: '\(rawValue)'. Allowed values: \(allowed)")
  }
  return type
}

/// Decodes a JSON command-line argument into a generated OpenAPI type.
///
/// Malformed JSON fails locally with a validation error — the value is never
/// silently dropped or forwarded to the SDK.
func parseAutomationJSON<T: Decodable>(
  _ rawValue: String?, as type: T.Type, fieldName: String
) throws -> T? {
  guard let rawValue else { return nil }
  guard let data = rawValue.data(using: .utf8) else {
    throw ValidationError("Invalid \(fieldName): value is not valid UTF-8")
  }
  do {
    return try JSONDecoder().decode(T.self, from: data)
  } catch {
    throw ValidationError("Invalid \(fieldName) JSON: \(error.localizedDescription)")
  }
}

// MARK: - List Automations

struct ListAutomations: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-automations",
    abstract: "List automations in a space"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Space ID")
  var spaceId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let automations = try await client.listAutomations(spaceId: spaceId)
    try printJSON(automations)
  }
}

// MARK: - Create Automation

struct CreateAutomation: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "create-automation",
    abstract: "Create an automation in a space"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Space ID")
  var spaceId: Int

  @Option(name: .long, help: "Automation type: on_action, on_date, on_demand")
  var type: String

  @Option(name: .long, help: "Actions as a JSON array, e.g. '[{\"type\":\"add_assignee\"}]'")
  var actions: String

  @Option(name: .long, help: "Automation name")
  var name: String?

  @Option(name: .long, help: "Trigger as a JSON object, e.g. '{\"type\":\"card_created\"}'")
  var trigger: String?

  @Option(name: .long, help: "Conditions as a JSON object")
  var conditions: String?

  func run() async throws {
    let automationType = try parseAutomationType(type)
    guard
      let parsedActions = try parseAutomationJSON(
        actions, as: [Components.Schemas.AutomationAction].self, fieldName: "actions")
    else {
      throw ValidationError("Invalid actions: value is required")
    }
    let parsedTrigger = try parseAutomationJSON(
      trigger, as: Components.Schemas.AutomationTrigger.self, fieldName: "trigger")
    let parsedConditions = try parseAutomationJSON(
      conditions, as: Components.Schemas.AutomationConditionGroup.self, fieldName: "conditions")

    let client = try await global.makeClient()
    let automation = try await client.createAutomation(
      spaceId: spaceId,
      type: automationType,
      actions: parsedActions,
      name: name,
      trigger: parsedTrigger,
      conditions: parsedConditions
    )
    try printJSON(automation)
  }
}

// MARK: - Update Automation

struct UpdateAutomation: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-automation",
    abstract: "Update an automation"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Space ID")
  var spaceId: Int

  @Option(name: .long, help: "Automation UID")
  var automationUid: String

  @Option(name: .long, help: "Automation name")
  var name: String?

  @Option(name: .long, help: "Trigger as a JSON object")
  var trigger: String?

  @Option(name: .long, help: "Conditions as a JSON object")
  var conditions: String?

  @Option(name: .long, help: "Actions as a JSON array")
  var actions: String?

  func run() async throws {
    let parsedTrigger = try parseAutomationJSON(
      trigger, as: Components.Schemas.AutomationTrigger.self, fieldName: "trigger")
    let parsedConditions = try parseAutomationJSON(
      conditions, as: Components.Schemas.AutomationConditionGroup.self, fieldName: "conditions")
    let parsedActions = try parseAutomationJSON(
      actions, as: [Components.Schemas.AutomationAction].self, fieldName: "actions")

    let client = try await global.makeClient()
    let automation = try await client.updateAutomation(
      spaceId: spaceId,
      automationUid: automationUid,
      name: name,
      trigger: parsedTrigger,
      conditions: parsedConditions,
      actions: parsedActions
    )
    try printJSON(automation)
  }
}

// MARK: - Delete Automation

struct DeleteAutomation: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "delete-automation",
    abstract: "Delete an automation"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Space ID")
  var spaceId: Int

  @Option(name: .long, help: "Automation UID")
  var automationUid: String

  func run() async throws {
    let client = try await global.makeClient()
    try await client.deleteAutomation(spaceId: spaceId, automationUid: automationUid)
  }
}
