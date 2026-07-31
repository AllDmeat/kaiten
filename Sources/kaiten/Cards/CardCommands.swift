import ArgumentParser
import Foundation
import KaitenSDK

// MARK: - Cards

func parseCardStates(_ rawValue: String?) throws -> [CardState]? {
  guard let rawValue else { return nil }
  var states: [CardState] = []

  for token in rawValue.split(separator: ",", omittingEmptySubsequences: false) {
    let trimmed = token.trimmingCharacters(in: .whitespaces)
    guard !trimmed.isEmpty, let intValue = Int(trimmed) else {
      throw ValidationError(
        "Invalid card state: '\(trimmed)'. Allowed values: 1 (queued), 2 (in progress), 3 (done)"
      )
    }
    let state = CardState(rawValue: intValue)
    guard CardState.allCases.contains(state) else {
      throw ValidationError(
        "Invalid card state: '\(trimmed)'. Allowed values: 1 (queued), 2 (in progress), 3 (done)"
      )
    }
    states.append(state)
  }

  return states
}

func parseCardCondition(_ rawValue: Int?) throws -> CardCondition? {
  guard let rawValue else { return nil }
  let condition = CardCondition(rawValue: rawValue)
  guard CardCondition.allCases.contains(condition) else {
    throw ValidationError(
      "Invalid card condition: \(rawValue). Allowed values: 1 (on board), 2 (archived)"
    )
  }
  return condition
}

struct ListCards: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-cards",
    abstract: "List cards on a board (paginated)"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Board ID")
  var boardId: Int?

  @Option(name: .long, help: "Column ID")
  var columnId: Int?

  @Option(name: .long, help: "Lane ID")
  var laneId: Int?

  @Option(name: .long, help: "Offset for pagination (default: 0)")
  var offset: Int = 0

  @Option(name: .long, help: "Limit for pagination (default/max: 100)")
  var limit: Int = 100

  // Date filters
  @Option(name: .long, help: "Filter cards created before this date (ISO 8601)")
  var createdBefore: String?

  @Option(name: .long, help: "Filter cards created after this date (ISO 8601)")
  var createdAfter: String?

  @Option(name: .long, help: "Filter cards updated before this date (ISO 8601)")
  var updatedBefore: String?

  @Option(name: .long, help: "Filter cards updated after this date (ISO 8601)")
  var updatedAfter: String?

  @Option(name: .long, help: "Filter cards first moved to in-progress after this date")
  var firstMovedInProgressAfter: String?

  @Option(name: .long, help: "Filter cards first moved to in-progress before this date")
  var firstMovedInProgressBefore: String?

  @Option(name: .long, help: "Filter cards last moved to done after this date")
  var lastMovedToDoneAtAfter: String?

  @Option(name: .long, help: "Filter cards last moved to done before this date")
  var lastMovedToDoneAtBefore: String?

  @Option(name: .long, help: "Filter cards with due date after this date")
  var dueDateAfter: String?

  @Option(name: .long, help: "Filter cards with due date before this date")
  var dueDateBefore: String?

  // Text search
  @Option(name: .long, help: "Text search query")
  var query: String?

  @Option(name: .long, help: "Comma-separated fields to search in")
  var searchFields: String?

  // Tags
  @Option(name: .long, help: "Filter by tag name")
  var tag: String?

  @Option(name: .long, help: "Comma-separated tag IDs")
  var tagIds: String?

  // ID filters
  @Option(name: .long, help: "Filter by card type ID")
  var typeId: Int?

  @Option(name: .long, help: "Comma-separated card type IDs")
  var typeIds: String?

  @Option(name: .long, help: "Comma-separated member user IDs")
  var memberIds: String?

  @Option(name: .long, help: "Filter by owner user ID")
  var ownerId: Int?

  @Option(name: .long, help: "Comma-separated owner user IDs")
  var ownerIds: String?

  @Option(name: .long, help: "Filter by responsible user ID")
  var responsibleId: Int?

  @Option(name: .long, help: "Comma-separated responsible user IDs")
  var responsibleIds: String?

  @Option(name: .long, help: "Comma-separated column IDs")
  var columnIds: String?

  @Option(name: .long, help: "Filter by space ID")
  var spaceId: Int?

  @Option(name: .long, help: "Filter by external ID")
  var externalId: String?

  @Option(name: .long, help: "Comma-separated organization IDs")
  var organizationsIds: String?

  // Exclude filters
  @Option(name: .long, help: "Comma-separated board IDs to exclude")
  var excludeBoardIds: String?

  @Option(name: .long, help: "Comma-separated lane IDs to exclude")
  var excludeLaneIds: String?

  @Option(name: .long, help: "Comma-separated column IDs to exclude")
  var excludeColumnIds: String?

  @Option(name: .long, help: "Comma-separated owner IDs to exclude")
  var excludeOwnerIds: String?

  @Option(name: .long, help: "Comma-separated card IDs to exclude")
  var excludeCardIds: String?

  // State filters
  @Option(name: .long, help: "Card condition: 1 = on board, 2 = archived")
  var condition: Int?

  @Option(name: .long, help: "Comma-separated states: 1 = queued, 2 = in progress, 3 = done")
  var states: String?

  @Option(name: .long, help: "Filter by archived status")
  var archived: Bool?

  @Option(name: .long, help: "Filter ASAP cards")
  var asap: Bool?

  @Option(name: .long, help: "Filter overdue cards")
  var overdue: Bool?

  @Option(name: .long, help: "Filter cards done on time")
  var doneOnTime: Bool?

  @Option(name: .long, help: "Filter cards that have a due date")
  var withDueDate: Bool?

  @Option(name: .long, help: "Filter service desk request cards")
  var isRequest: Bool?

  // Sorting
  @Option(name: .long, help: "Field to order by")
  var orderBy: String?

  @Option(name: .long, help: "Order direction: asc or desc")
  var orderDirection: String?

  @Option(name: .long, help: "Space ID for ordering context")
  var orderSpaceId: Int?

  // Extra
  @Option(name: .long, help: "Comma-separated additional fields to include")
  var additionalCardFields: String?

  func run() async throws {
    let client = try await global.makeClient()
    let filter = KaitenClient.CardFilter(
      createdBefore: try DateParsing.parse(createdBefore),
      createdAfter: try DateParsing.parse(createdAfter),
      updatedBefore: try DateParsing.parse(updatedBefore),
      updatedAfter: try DateParsing.parse(updatedAfter),
      firstMovedInProgressAfter: try DateParsing.parse(firstMovedInProgressAfter),
      firstMovedInProgressBefore: try DateParsing.parse(firstMovedInProgressBefore),
      lastMovedToDoneAtAfter: try DateParsing.parse(lastMovedToDoneAtAfter),
      lastMovedToDoneAtBefore: try DateParsing.parse(lastMovedToDoneAtBefore),
      dueDateAfter: try DateParsing.parse(dueDateAfter),
      dueDateBefore: try DateParsing.parse(dueDateBefore),
      query: query,
      searchFields: searchFields,
      tag: tag,
      tagIds: tagIds,
      typeId: typeId,
      typeIds: typeIds,
      memberIds: memberIds,
      ownerId: ownerId,
      ownerIds: ownerIds,
      responsibleId: responsibleId,
      responsibleIds: responsibleIds,
      columnIds: columnIds,
      spaceId: spaceId,
      externalId: externalId,
      organizationsIds: organizationsIds,
      excludeBoardIds: excludeBoardIds,
      excludeLaneIds: excludeLaneIds,
      excludeColumnIds: excludeColumnIds,
      excludeOwnerIds: excludeOwnerIds,
      excludeCardIds: excludeCardIds,
      condition: try parseCardCondition(condition),
      states: try parseCardStates(states),
      archived: archived,
      asap: asap,
      overdue: overdue,
      doneOnTime: doneOnTime,
      withDueDate: withDueDate,
      isRequest: isRequest,
      orderBy: orderBy,
      orderDirection: orderDirection,
      orderSpaceId: orderSpaceId,
      additionalCardFields: additionalCardFields
    )
    let page = try await client.listCards(
      boardId: boardId, columnId: columnId, laneId: laneId, offset: offset, limit: limit,
      filter: filter)
    try printJSON(page)
  }
}

struct CreateCard: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "create-card",
    abstract: "Create a new card on a board"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Board ID (required)")
  var boardId: Int

  @Option(name: .long, help: "Card title (required)")
  var title: String

  @Option(name: .long, help: "Column ID")
  var columnId: Int?

  @Option(name: .long, help: "Lane ID")
  var laneId: Int?

  @Option(name: .long, help: "Card description")
  var description: String?

  @Option(name: .long, help: "ASAP marker")
  var asap: Bool?

  @Option(name: .long, help: "Deadline (ISO 8601)")
  var dueDate: String?

  @Option(name: .long, help: "Deadline includes hours and minutes")
  var dueDateTimePresent: Bool?

  @Option(name: .long, help: "Position in the cell")
  var sortOrder: Double?

  @Option(name: .long, help: "Fixed deadline flag")
  var expiresLater: Bool?

  @Option(name: .long, help: "Size text (e.g. '1', 'S', 'XL')")
  var sizeText: String?

  @Option(name: .long, help: "Owner user ID")
  var ownerId: Int?

  @Option(name: .long, help: "Responsible user ID")
  var responsibleId: Int?

  @Option(name: .long, help: "Owner email address")
  var ownerEmail: String?

  @Option(name: .long, help: "1 - first in cell, 2 - last in cell")
  var position: Int?

  @Option(name: .long, help: "Card type ID")
  var typeId: Int?

  @Option(name: .long, help: "External ID")
  var externalId: String?

  @Option(name: .long, help: "Text format: 1 - markdown, 2 - html, 3 - jira wiki")
  var textFormatTypeId: Int?

  @Option(
    name: .long,
    help:
      "Custom properties as a JSON object. Keys are \"id_<property-id>\"; values are an array of value IDs for select properties, a number for numeric ones, or null to clear. Example: '{\"id_299126\": [106915]}'"
  )
  var properties: String?

  func run() async throws {
    let client = try await global.makeClient()
    var opts = CardCreateOptions(title: title, boardId: boardId)
    opts.columnId = columnId
    opts.laneId = laneId
    opts.description = description
    opts.asap = asap
    opts.dueDate = dueDate
    opts.dueDateTimePresent = dueDateTimePresent
    opts.sortOrder = sortOrder
    opts.expiresLater = expiresLater
    opts.sizeText = sizeText
    opts.ownerId = ownerId
    opts.responsibleId = responsibleId
    opts.ownerEmail = ownerEmail
    opts.position = position.map(CardPosition.init(rawValue:))
    opts.typeId = typeId
    opts.externalId = externalId
    opts.textFormatTypeId = textFormatTypeId.map(TextFormatType.init(rawValue:))
    opts.properties = try parseCardProperties(properties, fieldName: "properties")
    let card = try await client.createCard(opts)
    try printJSON(card)
  }
}

struct GetCard: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "get-card",
    abstract: "Get a card by ID"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var id: Int

  func run() async throws {
    let client = try await global.makeClient()
    let card = try await client.getCard(id: id)
    try printJSON(card)
  }
}

struct UpdateCard: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-card",
    abstract: "Update a card by ID"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var id: Int

  @Option(name: .long, help: "New title")
  var title: String?

  @Option(name: .long, help: "New description")
  var description: String?

  @Option(name: .long, help: "ASAP marker")
  var asap: Bool?

  @Option(name: .long, help: "Deadline (ISO 8601)")
  var dueDate: String?

  @Option(name: .long, help: "Deadline includes hours and minutes")
  var dueDateTimePresent: Bool?

  @Option(name: .long, help: "Position in the cell")
  var sortOrder: Double?

  @Option(name: .long, help: "Fixed deadline flag")
  var expiresLater: Bool?

  @Option(name: .long, help: "Size text (e.g. '1', 'S', 'XL')")
  var sizeText: String?

  @Option(name: .long, help: "Board ID")
  var boardId: Int?

  @Option(name: .long, help: "Column ID")
  var columnId: Int?

  @Option(name: .long, help: "Lane ID")
  var laneId: Int?

  @Option(name: .long, help: "Owner user ID")
  var ownerId: Int?

  @Option(name: .long, help: "Card type ID")
  var typeId: Int?

  @Option(name: .long, help: "Service ID")
  var serviceId: Int?

  @Option(name: .long, help: "Release all blocks (pass false)")
  var blocked: Bool?

  @Option(name: .long, help: "Condition: 1 = live, 2 = archived")
  var condition: Int?

  @Option(name: .long, help: "External ID")
  var externalId: String?

  @Option(name: .long, help: "Text format: 1 = markdown, 2 = html, 3 = jira wiki")
  var textFormatTypeId: Int?

  @Option(name: .long, help: "Owner email address")
  var ownerEmail: String?

  @Option(name: .long, help: "Previous card ID for repositioning")
  var prevCardId: Int?

  @Option(name: .long, help: "Estimate workload")
  var estimateWorkload: Double?

  @Option(
    name: .long,
    help: "Planned start date (ISO 8601). Pass empty string \"\" to clear the value."
  )
  var plannedStart: String?

  @Option(
    name: .long,
    help: "Planned end date (ISO 8601). Pass empty string \"\" to clear the value."
  )
  var plannedEnd: String?

  @Option(
    name: .long,
    help:
      "Custom properties as a JSON object. Keys are \"id_<property-id>\"; values are an array of value IDs for select properties, a number for numeric ones, or null to clear. Example: '{\"id_299126\": [106915]}'"
  )
  var properties: String?

  func run() async throws {
    let client = try await global.makeClient()
    var opts = CardUpdateOptions()
    opts.title = title
    opts.description = description
    opts.asap = asap
    opts.dueDate = dueDate
    opts.dueDateTimePresent = dueDateTimePresent
    opts.sortOrder = sortOrder
    opts.expiresLater = expiresLater
    opts.sizeText = sizeText
    opts.boardId = boardId
    opts.columnId = columnId
    opts.laneId = laneId
    opts.ownerId = ownerId
    opts.typeId = typeId
    opts.serviceId = serviceId
    opts.blocked = blocked
    opts.condition = condition.map(CardCondition.init(rawValue:))
    opts.externalId = externalId
    opts.textFormatTypeId = textFormatTypeId.map(TextFormatType.init(rawValue:))
    opts.ownerEmail = ownerEmail
    opts.prevCardId = prevCardId
    opts.estimateWorkload = estimateWorkload
    // Map String? → String??:
    //   nil (not passed)  → nil         (omit field, server leaves value unchanged)
    //   ""  (empty)       → .some(nil)  (send JSON null, server clears the value)
    //   "date"            → .some("date") (send string, server sets the value)
    opts.plannedStart = plannedStart.map { $0.isEmpty ? nil : $0 }
    opts.plannedEnd = plannedEnd.map { $0.isEmpty ? nil : $0 }
    opts.properties = try parseCardProperties(properties, fieldName: "properties")
    let card = try await client.updateCard(id: id, opts)
    try printJSON(card)
  }
}

struct GetCardComments: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "get-card-comments",
    abstract: "Get comments on a card"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let comments = try await client.getCardComments(cardId: cardId)
    try printJSON(comments)
  }
}

struct GetCardMembers: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "get-card-members",
    abstract: "Get members of a card"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let members = try await client.getCardMembers(cardId: cardId)
    try printJSON(members)
  }
}

struct UpdateComment: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-comment",
    abstract: "Update a comment on a card"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  @Option(name: .long, help: "Comment ID")
  var commentId: Int

  @Option(name: .long, help: "New comment text (markdown)")
  var text: String

  func run() async throws {
    let client = try await global.makeClient()
    let comment = try await client.updateComment(
      cardId: cardId, commentId: commentId, text: text)
    try printJSON(comment)
  }
}

struct AddComment: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "add-comment",
    abstract: "Create a comment on a card"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  @Option(name: .long, help: "Comment text (markdown)")
  var text: String

  func run() async throws {
    let client = try await global.makeClient()
    let comment = try await client.createComment(cardId: cardId, text: text)
    try printJSON(comment)
  }
}

struct DeleteCard: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "delete-card",
    abstract: "Delete a card"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let card = try await client.deleteCard(id: cardId)
    try printJSON(card)
  }
}

struct DeleteComment: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "delete-comment",
    abstract: "Delete a comment from a card"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Card ID")
  var cardId: Int

  @Option(name: .long, help: "Comment ID")
  var commentId: Int

  func run() async throws {
    let client = try await global.makeClient()
    let deletedId = try await client.deleteComment(cardId: cardId, commentId: commentId)
    try printJSON(["id": deletedId])
  }
}
