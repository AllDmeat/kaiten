import OpenAPIRuntime

/// Options for creating a new card.
///
/// Only ``title`` and ``boardId`` are required; all other properties default to `nil`
/// and are omitted from the request when not set.
///
/// ```swift
/// var opts = CardCreateOptions(title: "Bug fix", boardId: 1)
/// opts.columnId = 42
/// opts.description = "Fix the login crash"
/// let card = try await client.createCard(opts)
/// ```
public struct CardCreateOptions: Sendable {
  /// Card title (required).
  public var title: String
  /// Board ID (required).
  public var boardId: Int
  /// Target column ID.
  public var columnId: Int?
  /// Target lane ID.
  public var laneId: Int?
  /// Card description.
  public var description: String?
  /// ASAP marker.
  public var asap: Bool?
  /// Deadline in ISO 8601 format.
  public var dueDate: String?
  /// Whether deadline includes hours and minutes.
  public var dueDateTimePresent: Bool?
  /// Position in the cell (numeric sort order).
  public var sortOrder: Double?
  /// Fixed deadline flag.
  public var expiresLater: Bool?
  /// Size text (e.g. "1", "S", "XL").
  public var sizeText: String?
  /// Owner user ID.
  public var ownerId: Int?
  /// Responsible user ID.
  public var responsibleId: Int?
  /// Owner email address.
  public var ownerEmail: String?
  /// Card position in cell (first or last). Overrides ``sortOrder``.
  public var position: CardPosition?
  /// Card type ID.
  public var typeId: Int?
  /// Service desk service ID. Must reference an active service.
  public var serviceId: Int?
  /// External identifier.
  public var externalId: String?
  /// Text format for card description.
  public var textFormatTypeId: TextFormatType?
  /// Custom properties object.
  public var properties: Components.Schemas.CreateCardRequest.propertiesPayload?

  /// Creates card creation options.
  ///
  /// - Parameters:
  ///   - title: Card title.
  ///   - boardId: Board ID.
  public init(title: String, boardId: Int) {
    self.title = title
    self.boardId = boardId
  }
}

/// Options for updating an existing card.
///
/// All properties default to `nil` — only set values are sent to the server.
///
/// ```swift
/// var opts = CardUpdateOptions()
/// opts.title = "New Title"
/// opts.columnId = 42
/// let card = try await client.updateCard(id: 123, opts)
/// ```
public struct CardUpdateOptions: Sendable {
  /// New card title.
  public var title: String?
  /// New description.
  public var description: String?
  /// ASAP marker.
  public var asap: Bool?
  /// Deadline in ISO 8601 format.
  public var dueDate: String?
  /// Whether deadline includes hours and minutes.
  public var dueDateTimePresent: Bool?
  /// Position in the cell.
  public var sortOrder: Double?
  /// Fixed deadline flag.
  public var expiresLater: Bool?
  /// Size text (e.g. "1", "S", "XL").
  public var sizeText: String?
  /// Target board ID.
  public var boardId: Int?
  /// Target column ID.
  public var columnId: Int?
  /// Target lane ID.
  public var laneId: Int?
  /// Owner user ID.
  public var ownerId: Int?
  /// Card type ID.
  public var typeId: Int?
  /// Service ID.
  public var serviceId: Int?
  /// Send `false` to release all blocks.
  public var blocked: Bool?
  /// Card condition (on board or archived).
  public var condition: CardCondition?
  /// External identifier.
  public var externalId: String?
  /// Text format for card description.
  public var textFormatTypeId: TextFormatType?
  /// Service Desk new comment flag.
  public var sdNewComment: Bool?
  /// Owner email address.
  public var ownerEmail: String?
  /// Previous card ID for repositioning.
  public var prevCardId: Int?
  /// Estimated workload.
  public var estimateWorkload: Double?
  /// Planned start date. Supports three states via `String??`:
  ///
  /// - `nil` (default): field omitted — server leaves value unchanged.
  /// - `.some(nil)`: field sent as JSON `null` — server clears the value.
  /// - `.some("2026-03-10")`: field sent as ISO 8601 string — server sets the value.
  public var plannedStart: String??
  /// Planned end date. Same three-state semantics as ``plannedStart``.
  public var plannedEnd: String??
  /// Skip the card in planned dates recalculation by planned relations. Requires the Gantt and
  /// Resource planning feature.
  public var ignorePlannedDatesRecalculation: Bool?
  /// Custom properties object.
  public var properties: Components.Schemas.UpdateCardRequest.propertiesPayload?

  /// Creates empty card update options.
  public init() {}
}
