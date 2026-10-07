import Foundation

/// Filters for querying cards from the Kaiten API.
///
/// Use `CardFilter` to narrow down results when calling ``KaitenClient/listCards(boardId:columnId:laneId:offset:limit:filter:)``
/// or ``KaitenClient/searchCards(boardId:columnId:laneId:startPosition:includeSearchPreview:limit:filter:)``.
/// All properties are optional — only set the ones you need. Non-`nil` values are sent as
/// query parameters to the `GET /cards` endpoint; `nil` values are omitted.
///
/// ### Example: Find overdue cards assigned to specific members
/// ```swift
/// let cards = try await client.listCards(
///   filter: CardFilter(
///     memberIds: "10,25",
///     overdue: true
///   )
/// )
/// ```
///
/// ### Example: Search cards by text within a space
/// ```swift
/// let results = try await client.listCards(
///   filter: CardFilter(
///     query: "login bug",
///     searchFields: "title,description",
///     spaceId: 42
///   )
/// )
/// ```
///
/// ### Example: Filter by workflow state and date range
/// ```swift
/// let done = try await client.listCards(
///   filter: CardFilter(
///     createdAfter: oneWeekAgo,
///     states: [.done],
///     orderBy: "updated_at",
///     orderDirection: "desc"
///   )
/// )
/// ```
///
/// - SeeAlso: [Kaiten API – Cards](https://developers.kaiten.ru/cards/retrieve-card-list)
public struct CardFilter: Sendable {
  // MARK: - Date filters

  /// Filter cards created before this date (inclusive, ISO 8601).
  public let createdBefore: Date?
  /// Filter cards created after this date (inclusive, ISO 8601).
  public let createdAfter: Date?
  /// Filter cards updated before this date.
  public let updatedBefore: Date?
  /// Filter cards updated after this date.
  public let updatedAfter: Date?
  /// Filter cards that first entered an "in progress" column after this date.
  public let firstMovedInProgressAfter: Date?
  /// Filter cards that first entered an "in progress" column before this date.
  public let firstMovedInProgressBefore: Date?
  /// Filter cards whose most recent move to a "done" column happened after this date.
  public let lastMovedToDoneAtAfter: Date?
  /// Filter cards whose most recent move to a "done" column happened before this date.
  public let lastMovedToDoneAtBefore: Date?
  /// Filter cards whose due date is after this date.
  public let dueDateAfter: Date?
  /// Filter cards whose due date is before this date.
  public let dueDateBefore: Date?

  // MARK: - Text search

  /// Free-text search query matched against card content.
  public let query: String?
  /// Comma-separated list of fields to search in (e.g. `"title,description"`).
  ///
  /// When omitted, the API searches all default text fields.
  public let searchFields: String?

  // MARK: - Tags

  /// Filter by exact tag name.
  public let tag: String?
  /// Comma-separated tag IDs (e.g. `"1,2,3"`).
  public let tagIds: String?

  // MARK: - People & entity filters

  /// Filter by a single card type ID.
  public let typeId: Int?
  /// Comma-separated card type IDs (e.g. `"1,4"`).
  public let typeIds: String?
  /// Comma-separated IDs of card **members** (participants added to the card).
  public let memberIds: String?
  /// Filter by a single **owner** ID — the user who created the card.
  public let ownerId: Int?
  /// Comma-separated **owner** IDs (card creators).
  public let ownerIds: String?
  /// Filter by a single **responsible** user ID — the person accountable for the card.
  public let responsibleId: Int?
  /// Comma-separated **responsible** user IDs.
  public let responsibleIds: String?
  /// Comma-separated column IDs to restrict results to specific board columns.
  public let columnIds: String?
  /// Filter cards belonging to a specific space.
  public let spaceId: Int?
  /// Filter by an external integration ID (e.g. a Jira or GitLab reference).
  public let externalId: String?
  /// Comma-separated organization IDs.
  public let organizationsIds: String?

  // MARK: - Exclude filters

  /// Comma-separated board IDs whose cards should be excluded from results.
  public let excludeBoardIds: String?
  /// Comma-separated lane IDs whose cards should be excluded.
  public let excludeLaneIds: String?
  /// Comma-separated column IDs whose cards should be excluded.
  public let excludeColumnIds: String?
  /// Comma-separated owner IDs whose cards should be excluded.
  public let excludeOwnerIds: String?
  /// Comma-separated card IDs to exclude from results.
  public let excludeCardIds: String?

  // MARK: - State filters

  /// Card condition on the board.
  ///
  /// Use `.onBoard` to find active cards or `.archived` for archived ones.
  /// - SeeAlso: ``CardCondition``
  public let condition: CardCondition?
  /// Card workflow states to include (e.g. `[.queued, .inProgress, .done]`).
  ///
  /// When multiple states are provided, cards matching **any** of them are returned.
  /// - SeeAlso: ``CardState``
  public let states: [CardState]?
  /// Filter by archived status (`true` = only archived, `false` = only non-archived).
  public let archived: Bool?
  /// When `true`, return only cards marked as ASAP (high urgency).
  public let asap: Bool?
  /// When `true`, return only cards that are past their due date.
  public let overdue: Bool?
  /// When `true`, return only cards that were completed before their due date.
  public let doneOnTime: Bool?
  /// When `true`, return only cards that have a due date set.
  public let withDueDate: Bool?
  /// When `true`, return only cards created via service desk requests.
  public let isRequest: Bool?

  // MARK: - Sorting

  /// Field name to order results by (e.g. `"created_at"`, `"updated_at"`, `"due_date"`).
  public let orderBy: String?
  /// Sort direction: `"asc"` for ascending or `"desc"` for descending.
  public let orderDirection: String?
  /// Space ID that provides the ordering context (required for some space-specific sort fields).
  public let orderSpaceId: Int?

  // MARK: - Extra

  /// Comma-separated list of additional fields to include in the response (e.g. `"description,checklist"`).
  public let additionalCardFields: String?
  /// Comma-separated project UUIDs.
  public let projectIds: String?
  /// (Beta) And/or condition tree encoded in base64, passed to the API unchanged.
  ///
  /// - SeeAlso: [Kaiten API – Cards](https://developers.kaiten.ru/cards/retrieve-card-list)
  public let filter: String?
  /// Representation of user-type custom property values (`broken_api`).
  ///
  /// The list returns those values as arrays of user objects regardless of this flag.
  public let brokenApi: Bool?

  /// Creates a new card filter with all fields defaulting to `nil`.
  public init(
    createdBefore: Date? = nil,
    createdAfter: Date? = nil,
    updatedBefore: Date? = nil,
    updatedAfter: Date? = nil,
    firstMovedInProgressAfter: Date? = nil,
    firstMovedInProgressBefore: Date? = nil,
    lastMovedToDoneAtAfter: Date? = nil,
    lastMovedToDoneAtBefore: Date? = nil,
    dueDateAfter: Date? = nil,
    dueDateBefore: Date? = nil,
    query: String? = nil,
    searchFields: String? = nil,
    tag: String? = nil,
    tagIds: String? = nil,
    typeId: Int? = nil,
    typeIds: String? = nil,
    memberIds: String? = nil,
    ownerId: Int? = nil,
    ownerIds: String? = nil,
    responsibleId: Int? = nil,
    responsibleIds: String? = nil,
    columnIds: String? = nil,
    spaceId: Int? = nil,
    externalId: String? = nil,
    organizationsIds: String? = nil,
    excludeBoardIds: String? = nil,
    excludeLaneIds: String? = nil,
    excludeColumnIds: String? = nil,
    excludeOwnerIds: String? = nil,
    excludeCardIds: String? = nil,
    condition: CardCondition? = nil,
    states: [CardState]? = nil,
    archived: Bool? = nil,
    asap: Bool? = nil,
    overdue: Bool? = nil,
    doneOnTime: Bool? = nil,
    withDueDate: Bool? = nil,
    isRequest: Bool? = nil,
    orderBy: String? = nil,
    orderDirection: String? = nil,
    orderSpaceId: Int? = nil,
    additionalCardFields: String? = nil,
    projectIds: String? = nil,
    filter: String? = nil,
    brokenApi: Bool? = nil
  ) {
    self.createdBefore = createdBefore
    self.createdAfter = createdAfter
    self.updatedBefore = updatedBefore
    self.updatedAfter = updatedAfter
    self.firstMovedInProgressAfter = firstMovedInProgressAfter
    self.firstMovedInProgressBefore = firstMovedInProgressBefore
    self.lastMovedToDoneAtAfter = lastMovedToDoneAtAfter
    self.lastMovedToDoneAtBefore = lastMovedToDoneAtBefore
    self.dueDateAfter = dueDateAfter
    self.dueDateBefore = dueDateBefore
    self.query = query
    self.searchFields = searchFields
    self.tag = tag
    self.tagIds = tagIds
    self.typeId = typeId
    self.typeIds = typeIds
    self.memberIds = memberIds
    self.ownerId = ownerId
    self.ownerIds = ownerIds
    self.responsibleId = responsibleId
    self.responsibleIds = responsibleIds
    self.columnIds = columnIds
    self.spaceId = spaceId
    self.externalId = externalId
    self.organizationsIds = organizationsIds
    self.excludeBoardIds = excludeBoardIds
    self.excludeLaneIds = excludeLaneIds
    self.excludeColumnIds = excludeColumnIds
    self.excludeOwnerIds = excludeOwnerIds
    self.excludeCardIds = excludeCardIds
    self.condition = condition
    self.states = states
    self.archived = archived
    self.asap = asap
    self.overdue = overdue
    self.doneOnTime = doneOnTime
    self.withDueDate = withDueDate
    self.isRequest = isRequest
    self.orderBy = orderBy
    self.orderDirection = orderDirection
    self.orderSpaceId = orderSpaceId
    self.additionalCardFields = additionalCardFields
    self.projectIds = projectIds
    self.filter = filter
    self.brokenApi = brokenApi
  }
}
