import ArgumentParser
import KaitenSDK

// MARK: - Checklist Cards

struct ListChecklistCards: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-checklist-cards",
    abstract: "List cards that use a checklist"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Checklist ID")
  var checklistId: Int

  @Option(
    name: .long,
    help: ArgumentHelp(
      "Required by the API; requests without it are rejected with 400.",
      discussion:
        "No filtering effect has been observed — a card that is neither public nor shared is returned with either value."
    )
  )
  var onlySharedCards: Bool

  func run() async throws {
    let client = try await global.makeClient()
    let cards = try await client.listCardsWithChecklist(
      checklistId: checklistId, onlySharedCards: onlySharedCards)
    try printJSON(cards, expand: global.expandedFields)
  }
}
