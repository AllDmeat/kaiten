import ArgumentParser
import Configuration
import Foundation
import KaitenSDK
import SystemPackage

@main
struct Kaiten: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "kaiten",
    abstract: "CLI for Kaiten API",
    discussion: "Every subcommand prints compact JSON to stdout.",
    subcommands: [
      ListSpaces.self,
      ListBoards.self,
      GetBoard.self,
      GetBoardColumns.self,
      GetBoardLanes.self,
      ListCards.self,
      CreateCard.self,
      GetCard.self,
      UpdateCard.self,
      BatchUpdateCards.self,
      GetCardComments.self,
      AddComment.self,
      UpdateComment.self,
      GetCardMembers.self,
      AddCardMember.self,
      UpdateCardMemberRole.self,
      RemoveCardMember.self,
      CreateChecklist.self,
      RemoveChecklist.self,
      CreateChecklistItem.self,
      RemoveChecklistItem.self,
      UpdateChecklistItem.self,
      AddItemToChecklist.self,
      UpdateItemInChecklist.self,
      RemoveItemFromChecklist.self,
      UpdateChecklist.self,
      ListCustomProperties.self,
      GetCustomProperty.self,
      CreateCustomProperty.self,
      UpdateCustomProperty.self,
      RemoveCustomProperty.self,
      ListCustomPropertySelectValues.self,
      GetCustomPropertySelectValue.self,
      CreateCustomPropertySelectValue.self,
      UpdateCustomPropertySelectValue.self,
      RemoveCustomPropertySelectValue.self,
      ListCustomPropertyCatalogValues.self,
      GetCustomPropertyCatalogValue.self,
      CreateCustomPropertyCatalogValue.self,
      UpdateCustomPropertyCatalogValue.self,
      RemoveCustomPropertyCatalogValue.self,
      GetChecklist.self,
      DeleteCard.self,
      DeleteComment.self,
      ListCardTags.self,
      AddCardTag.self,
      RemoveCardTag.self,
      ListUsers.self,
      GetCurrentUser.self,
      ListCardChildren.self,
      AddCardChild.self,
      RemoveCardChild.self,
      ListCardBlockers.self,
      CreateCardBlocker.self,
      UpdateCardBlocker.self,
      DeleteCardBlocker.self,
      ListCardTypes.self,
      CreateCardType.self,
      GetCardType.self,
      UpdateCardType.self,
      DeleteCardType.self,
      ListSprints.self,
      GetCardHistory.self,
      ListExternalLinks.self,
      CreateExternalLink.self,
      UpdateExternalLink.self,
      RemoveExternalLink.self,
      GetSprintSummary.self,
      CreateSpace.self,
      GetSpace.self,
      UpdateSpace.self,
      CreateBoard.self,
      UpdateBoard.self,
      CreateColumn.self,
      UpdateColumn.self,
      DeleteColumn.self,
      ListSubcolumns.self,
      CreateSubcolumn.self,
      UpdateSubcolumn.self,
      DeleteSubcolumn.self,
      CreateLane.self,
      UpdateLane.self,
      GetCardBaselines.self,
      ListCardAllowedUsers.self,
      AttachCardFile.self,
      UpdateCardFile.self,
      DetachCardFile.self,
      ListAutomations.self,
      CreateAutomation.self,
      UpdateAutomation.self,
      DeleteAutomation.self,
      AddServiceDeskExternalRecipient.self,
      RemoveServiceDeskExternalRecipient.self,
      ListBlockerCategories.self,
      AddBlockerCategory.self,
      RemoveBlockerCategory.self,
      GetCardSlaMeasurements.self,
      ListCardTypeTreeEntities.self,
      AddCardTypeTreeEntity.self,
      DeleteCardTypeTreeEntity.self,
      GetCardTimeLogs.self,
      AddTimeLog.self,
      UpdateTimeLog.self,
      RemoveTimeLog.self,
      ListAuditLogs.self,
      ListCardBlockerUsers.self,
      AddCardBlockerUser.self,
      RemoveCardBlockerUser.self,
      GetCurrentUserBlockers.self,
      ListChecklistCards.self,
      ListCustomDirectories.self,
      CreateCustomDirectory.self,
      GetCustomDirectory.self,
      UpdateCustomDirectory.self,
      DeleteCustomDirectory.self,
      ListCompanyUsers.self,
      UpdateCompanyUser.self,
      RemoveVirtualUser.self,
      ListCustomDirectoryFields.self,
      CreateCustomDirectoryField.self,
      GetCustomDirectoryField.self,
      UpdateCustomDirectoryField.self,
      DeleteCustomDirectoryField.self,
      ListCustomDirectoryRecords.self,
      CreateCustomDirectoryRecord.self,
      GetCustomDirectoryRecord.self,
      UpdateCustomDirectoryRecord.self,
      DeleteCustomDirectoryRecord.self,
      ListCustomDirectoryRecordCards.self,
      ListCustomPropertyTreeEntities.self,
      AddCustomPropertyTreeEntity.self,
      DeleteCustomPropertyTreeEntity.self,
      ListGroupAdmins.self,
      AddGroupAdmin.self,
      RemoveGroupAdmin.self,
    ]
  )
}

// MARK: - Global Options

struct GlobalOptions: ParsableArguments {
  @Option(name: .long, help: "Path to Kaiten config.json")
  var config: String?

  @Option(
    name: .long,
    help: ArgumentHelp(
      "Comma-separated nested fields to include in the output, or 'all'.",
      discussion: """
        Responses omit nested entities by default. A single one is dropped, its `*_id` staying \
        behind: a card keeps owner_id and loses the embedded owner object. A collection collapses \
        to an array of its members' ids under its own key, so `members` holds user ids, and an \
        empty `members` means nobody rather than something withheld.

        Naming a field brings the entities back, one level deep — an expanded value is itself \
        stripped of its nested fields.

        A nested value carrying no id is data, not a reference, and nothing else in the response \
        stands in for it, so it is always present and cannot be expanded: a card's custom field \
        values are never omitted.

        Pass an unknown name to list what a command offers.
        """,
      valueName: "fields"
    )
  )
  var expand: String?

  /// `--expand` names, parsed with the same strict CSV rules as the other list-valued options: a
  /// malformed token fails locally rather than being silently dropped.
  var expandedFields: Set<String> {
    get throws {
      Set(try parseStringCSV(expand, fieldName: "--expand") ?? [])
    }
  }

  var selectedConfigPath: String {
    config ?? Self.defaultConfigPath
  }

  func makeClient() async throws -> KaitenClient {
    let configPath = selectedConfigPath
    let config = try await Self.loadConfigReader(configPath: configPath)
    let connection = try Self.resolveConnection(
      environment: ProcessInfo.processInfo.environment,
      configURL: config?.string(forKey: "url"),
      configToken: config?.string(forKey: "token"),
      configPath: configPath
    )
    return try KaitenClient(baseURL: connection.url, token: connection.token)
  }

  /// Resolves each connection parameter independently: environment variable first,
  /// selected config file second. An empty environment value counts as unset —
  /// CI substitutes an empty string for a missing secret, and an empty token must
  /// fail here rather than reach the API.
  static func resolveConnection(
    environment: [String: String],
    configURL: String?,
    configToken: String?,
    configPath: String
  ) throws -> (url: String, token: String) {
    guard let url = nonEmpty(environment["KAITEN_URL"]) ?? configURL else {
      throw ValidationError(
        "Missing Kaiten API URL. Set KAITEN_URL, set \"url\" in \(configPath), "
          + "or pass --config <path>"
      )
    }
    guard let token = nonEmpty(environment["KAITEN_TOKEN"]) ?? configToken else {
      throw ValidationError(
        "Missing Kaiten API token. Set KAITEN_TOKEN, set \"token\" in \(configPath), "
          + "or pass --config <path>"
      )
    }
    return (url, token)
  }

  private static func nonEmpty(_ value: String?) -> String? {
    guard let value, !value.isEmpty else { return nil }
    return value
  }

  static var defaultConfigPath: String {
    let home = FileManager.default.homeDirectoryForCurrentUser
    return home.appendingPathComponent(".config/kaiten/config.json").path
  }

  private static func loadConfigReader(configPath: String) async throws -> ConfigReader? {
    guard FileManager.default.fileExists(atPath: configPath) else { return nil }

    do {
      let provider = try await FileProvider<JSONSnapshot>(filePath: FilePath(configPath))
      return ConfigReader(providers: [provider])
    } catch {
      throw ValidationError(
        "Failed to read configuration at \(configPath): \(error.localizedDescription)"
      )
    }
  }
}

// MARK: - Helpers

/// Decodes a custom-properties JSON object into the generated request payload.
///
/// Custom property values are a free-form object rather than a flat scalar, so they cannot be
/// expressed as ordinary options. Keys are `id_<property-id>`; values are an array of value IDs for
/// select properties, a number for numeric ones, or `null` to clear the property.
///
/// Parsing happens locally so a malformed object fails before any request is sent.
func parseCardProperties<Payload: Decodable>(
  _ rawValue: String?,
  fieldName: String
) throws -> Payload? {
  guard let rawValue else { return nil }
  let data = Data(rawValue.utf8)
  guard let object = try? JSONSerialization.jsonObject(with: data), object is [String: Any] else {
    throw ValidationError(
      "Invalid \(fieldName) value: expected a JSON object such as '{\"id_42\": [7]}'"
    )
  }
  do {
    return try JSONDecoder().decode(Payload.self, from: data)
  } catch {
    throw ValidationError(
      "Invalid \(fieldName) value: \(error.localizedDescription)"
    )
  }
}

func parseIntegerCSV(_ rawValue: String?, fieldName: String) throws -> [Int]? {
  guard let rawValue else { return nil }
  var result: [Int] = []
  for token in rawValue.split(separator: ",", omittingEmptySubsequences: false) {
    let trimmed = token.trimmingCharacters(in: .whitespaces)
    guard let value = Int(trimmed) else {
      throw ValidationError("Invalid \(fieldName) value: '\(trimmed)'")
    }
    result.append(value)
  }
  return result
}

func parseStringCSV(_ rawValue: String?, fieldName: String) throws -> [String]? {
  guard let rawValue else { return nil }
  var result: [String] = []
  for token in rawValue.split(separator: ",", omittingEmptySubsequences: false) {
    let trimmed = token.trimmingCharacters(in: .whitespaces)
    guard !trimmed.isEmpty else {
      throw ValidationError("Invalid \(fieldName) value: empty token")
    }
    result.append(trimmed)
  }
  return result
}
