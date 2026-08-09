import ArgumentParser
import Foundation
import KaitenSDK

// MARK: - Iterations

func parseIterationStatuses(_ rawValue: String?) throws -> [IterationStatus]? {
  guard let tokens = try parseStringCSV(rawValue, fieldName: "--status") else { return nil }
  return try tokens.map { token in
    let status = IterationStatus(rawValue: token)
    guard IterationStatus.allCases.contains(status) else {
      let allowed = IterationStatus.allCases.map(\.rawValue).joined(separator: ", ")
      throw ValidationError("Invalid iteration status: '\(token)'. Allowed values: \(allowed)")
    }
    return status
  }
}

struct GetCardIterationsHistory: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "get-card-iterations-history",
    abstract: "Get the iterations history of a card",
    discussion: "Records are ordered from the most recent to the oldest."
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card UID")
  var cardUid: String

  func run() async throws {
    let client = try await global.makeClient()
    let records = try await client.getCardIterationsHistory(cardUid: cardUid)
    try printJSON(records, expand: global.expandedFields)
  }
}

struct ListIterations: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-iterations",
    abstract: "List iterations of a space",
    discussion: "Iterations with the removed status do not contain cards."
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Space UID")
  var spaceUid: String

  @Option(name: .long, help: "Comma-separated statuses: planned, active, closed, removed")
  var status: String?

  @Option(name: .long, help: "Comma-separated related data to include. Documented value: cards")
  var withData: String?

  @Option(
    name: .long, help: "Maximum number of iterations to return (clamped to 1-100, default: 100)")
  var limit: Int?

  @Option(name: .long, help: "Number of iterations to skip (default: 0)")
  var offset: Int?

  @Option(name: .long, help: "Sort order by creation date: asc or desc (default: asc)")
  var order: String?

  func run() async throws {
    let statuses = try parseIterationStatuses(status)
    let client = try await global.makeClient()
    let iterations = try await client.listIterations(
      spaceUid: spaceUid,
      status: statuses,
      withData: withData,
      limit: limit,
      offset: offset,
      order: order
    )
    try printJSON(iterations, expand: global.expandedFields)
  }
}

struct CreateIteration: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "create-iteration",
    abstract: "Create an iteration in a space",
    discussion: "A created iteration gets the planned status."
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Space UID")
  var spaceUid: String

  @Option(name: .long, help: "Iteration title (1-256 characters)")
  var title: String

  @Option(name: .long, help: "Iteration goal")
  var goal: String?

  @Option(name: .long, help: "Start date (ISO 8601)")
  var startDate: String?

  @Option(name: .long, help: "Finish date (ISO 8601), must be later than the start date")
  var finishDate: String?

  func run() async throws {
    let client = try await global.makeClient()
    let iteration = try await client.createIteration(
      spaceUid: spaceUid,
      title: title,
      goal: goal,
      startDate: startDate,
      finishDate: finishDate
    )
    try printJSON(iteration, expand: global.expandedFields)
  }
}

struct GetIteration: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "get-iteration",
    abstract: "Get an iteration by ID"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Space UID")
  var spaceUid: String

  @Option(name: .long, help: "Iteration ID")
  var id: String

  func run() async throws {
    let client = try await global.makeClient()
    let iteration = try await client.getIteration(spaceUid: spaceUid, id: id)
    try printJSON(iteration, expand: global.expandedFields)
  }
}

struct UpdateIteration: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-iteration",
    abstract: "Update an iteration",
    discussion: """
      Status transitions are limited to planned-to-active and active-to-closed; deleting an \
      iteration is a separate operation. At least one editable option must be provided.
      """
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Space UID")
  var spaceUid: String

  @Option(name: .long, help: "Iteration ID")
  var id: String

  @Option(name: .long, help: "Iteration title (1-256 characters)")
  var title: String?

  @Option(name: .long, help: "Iteration goal")
  var goal: String?

  @Option(name: .long, help: "New status: active (from planned) or closed (from active)")
  var status: String?

  @Option(name: .long, help: "Start date (ISO 8601)")
  var startDate: String?

  @Option(name: .long, help: "Finish date (ISO 8601)")
  var finishDate: String?

  @Option(
    name: .long,
    help: "Actual finish date applied when closing (ISO 8601, defaults to the current time)"
  )
  var actualFinishDate: String?

  @Option(
    name: .long,
    help: "Iteration to move unfinished cards to when closing; must be planned or active"
  )
  var newIterationId: String?

  func run() async throws {
    let parsedStatus = try status.map { raw in
      let value = IterationStatus(rawValue: raw)
      guard IterationStatus.allCases.contains(value) else {
        let allowed = IterationStatus.allCases.map(\.rawValue).joined(separator: ", ")
        throw ValidationError("Invalid iteration status: '\(raw)'. Allowed values: \(allowed)")
      }
      return value
    }
    let client = try await global.makeClient()
    let iteration = try await client.updateIteration(
      spaceUid: spaceUid,
      id: id,
      title: title,
      goal: goal,
      status: parsedStatus,
      startDate: startDate,
      finishDate: finishDate,
      actualFinishDate: actualFinishDate,
      newIterationId: newIterationId
    )
    try printJSON(iteration, expand: global.expandedFields)
  }
}

struct DeleteIteration: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "delete-iteration",
    abstract: "Delete an iteration",
    discussion: """
      Links to cards that were part of the iteration are deleted too and cannot be restored. \
      The iteration gets the removed status and is printed in the response.
      """
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Space UID")
  var spaceUid: String

  @Option(name: .long, help: "Iteration ID")
  var id: String

  @Option(
    name: .long,
    help: "Iteration to move cards to before removal; must be planned or active"
  )
  var newIterationId: String?

  func run() async throws {
    let client = try await global.makeClient()
    let iteration = try await client.deleteIteration(
      spaceUid: spaceUid, id: id, newIterationId: newIterationId)
    try printJSON(iteration, expand: global.expandedFields)
  }
}

struct ListIterationCards: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-iteration-cards",
    abstract: "List card records of an iteration",
    discussion: "Each record links a card to the iteration."
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Space UID")
  var spaceUid: String

  @Option(name: .long, help: "Iteration ID")
  var iterationId: String

  @Option(name: .long, help: "Record status filter: active or removed (default: both)")
  var status: String?

  func run() async throws {
    let client = try await global.makeClient()
    let records = try await client.listIterationCards(
      spaceUid: spaceUid, iterationId: iterationId, status: status)
    try printJSON(records, expand: global.expandedFields)
  }
}

struct AddCardToIteration: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "add-card-to-iteration",
    abstract: "Add a card to an iteration",
    discussion: """
      The card must be active and belong to one of the space's primary boards. Cards can be \
      added to planned and active iterations only; adding a card that belongs to another \
      planned or active iteration moves it to the target iteration.
      """
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Space UID")
  var spaceUid: String

  @Option(name: .long, help: "Iteration ID")
  var iterationId: String

  @Option(name: .long, help: "Card UID")
  var cardUid: String

  func run() async throws {
    let client = try await global.makeClient()
    let record = try await client.addCardToIteration(
      spaceUid: spaceUid, iterationId: iterationId, cardUid: cardUid)
    try printJSON(record, expand: global.expandedFields)
  }
}

struct RemoveCardFromIteration: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "remove-card-from-iteration",
    abstract: "Remove a card from an iteration",
    discussion: """
      Sets removed_at and removed_by_uid on the iteration card record. Cards cannot be removed \
      from closed iterations.
      """
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Space UID")
  var spaceUid: String

  @Option(name: .long, help: "Iteration ID")
  var iterationId: String

  @Option(name: .long, help: "Card UID")
  var cardUid: String

  func run() async throws {
    let client = try await global.makeClient()
    let record = try await client.removeCardFromIteration(
      spaceUid: spaceUid, iterationId: iterationId, cardUid: cardUid)
    try printJSON(record, expand: global.expandedFields)
  }
}
