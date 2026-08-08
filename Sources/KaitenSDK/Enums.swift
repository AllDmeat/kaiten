// MARK: - Type-Safe Enums for Kaiten API
//
// These enums replace magic integer literals in the public API.
// Values are sourced from the Kaiten API documentation:
// https://developers.kaiten.ru
//
// Each enum includes an `unknown(Int)` case for forward compatibility.
// If the API introduces new values, they are preserved as `.unknown(rawValue)`
// instead of being silently dropped.

/// Card condition on a board.
///
/// Used in ``KaitenClient/CardFilter`` and ``CardUpdateOptions``.
/// - SeeAlso: [Kaiten API – Cards](https://developers.kaiten.ru/cards/retrieve-card-list)
public enum CardCondition: Sendable, Equatable, CaseIterable, Codable {
  /// Card is on the board (active).
  case onBoard
  /// Card is archived.
  case archived
  /// Unknown value returned by the API (forward compatibility).
  case unknown(Int)

  public static var allCases: [CardCondition] { [.onBoard, .archived] }

  public init(rawValue: Int) {
    switch rawValue {
    case 1: self = .onBoard
    case 2: self = .archived
    default: self = .unknown(rawValue)
    }
  }

  public var rawValue: Int {
    switch self {
    case .onBoard: 1
    case .archived: 2
    case .unknown(let v): v
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(Int.self)
    self.init(rawValue: value)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

/// Lane condition (includes deleted state).
///
/// Used in ``KaitenClient/getBoardLanes(boardId:condition:)``
/// and ``KaitenClient/updateLane(boardId:id:...)``.
/// - SeeAlso: [Kaiten API – Lanes](https://developers.kaiten.ru/lanes/get-list-of-lanes)
public enum LaneCondition: Sendable, Equatable, CaseIterable, Codable {
  /// Lane is live (active).
  case live
  /// Lane is archived.
  case archived
  /// Lane is deleted.
  case deleted
  /// Unknown value returned by the API (forward compatibility).
  case unknown(Int)

  public static var allCases: [LaneCondition] { [.live, .archived, .deleted] }

  public init(rawValue: Int) {
    switch rawValue {
    case 1: self = .live
    case 2: self = .archived
    case 3: self = .deleted
    default: self = .unknown(rawValue)
    }
  }

  public var rawValue: Int {
    switch self {
    case .live: 1
    case .archived: 2
    case .deleted: 3
    case .unknown(let v): v
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(Int.self)
    self.init(rawValue: value)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

/// Card workflow state.
///
/// Used in ``KaitenClient/CardFilter`` (`states` parameter).
/// - SeeAlso: [Kaiten API – Cards](https://developers.kaiten.ru/cards/retrieve-card-list)
public enum CardState: Sendable, Equatable, CaseIterable, Codable {
  /// Card is queued (not yet started).
  case queued
  /// Card is in progress.
  case inProgress
  /// Card is done.
  case done
  /// Unknown value returned by the API (forward compatibility).
  case unknown(Int)

  public static var allCases: [CardState] { [.queued, .inProgress, .done] }

  public init(rawValue: Int) {
    switch rawValue {
    case 1: self = .queued
    case 2: self = .inProgress
    case 3: self = .done
    default: self = .unknown(rawValue)
    }
  }

  public var rawValue: Int {
    switch self {
    case .queued: 1
    case .inProgress: 2
    case .done: 3
    case .unknown(let v): v
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(Int.self)
    self.init(rawValue: value)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

/// Card member role type.
///
/// Used in ``KaitenClient/updateCardMemberRole(cardId:userId:type:)``.
/// - SeeAlso: [Kaiten API – Card Members](https://developers.kaiten.ru/cards/update-card)
public enum CardMemberRoleType: Sendable, Equatable, CaseIterable, Codable {
  /// Regular member.
  case member
  /// Responsible person for the card.
  case responsible
  /// Unknown value returned by the API (forward compatibility).
  case unknown(Int)

  public static var allCases: [CardMemberRoleType] { [.member, .responsible] }

  public init(rawValue: Int) {
    switch rawValue {
    case 1: self = .member
    case 2: self = .responsible
    default: self = .unknown(rawValue)
    }
  }

  public var rawValue: Int {
    switch self {
    case .member: 1
    case .responsible: 2
    case .unknown(let v): v
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(Int.self)
    self.init(rawValue: value)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

/// Text format for card description.
///
/// Used in ``CardCreateOptions`` and ``CardUpdateOptions``.
/// - SeeAlso: [Kaiten API – Create Card](https://developers.kaiten.ru/cards/create-card)
public enum TextFormatType: Sendable, Equatable, CaseIterable, Codable {
  /// Markdown format (default).
  case markdown
  /// HTML format.
  case html
  /// Jira Wiki format.
  case jiraWiki
  /// Unknown value returned by the API (forward compatibility).
  case unknown(Int)

  public static var allCases: [TextFormatType] { [.markdown, .html, .jiraWiki] }

  public init(rawValue: Int) {
    switch rawValue {
    case 1: self = .markdown
    case 2: self = .html
    case 3: self = .jiraWiki
    default: self = .unknown(rawValue)
    }
  }

  public var rawValue: Int {
    switch self {
    case .markdown: 1
    case .html: 2
    case .jiraWiki: 3
    case .unknown(let v): v
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(Int.self)
    self.init(rawValue: value)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

/// Card position within a cell.
///
/// Overrides `sort_order` if present.
/// - SeeAlso: [Kaiten API – Create Card](https://developers.kaiten.ru/cards/create-card)
public enum CardPosition: Sendable, Equatable, CaseIterable, Codable {
  /// First in cell.
  case first
  /// Last in cell.
  case last
  /// Unknown value returned by the API (forward compatibility).
  case unknown(Int)

  public static var allCases: [CardPosition] { [.first, .last] }

  public init(rawValue: Int) {
    switch rawValue {
    case 1: self = .first
    case 2: self = .last
    default: self = .unknown(rawValue)
    }
  }

  public var rawValue: Int {
    switch self {
    case .first: 1
    case .last: 2
    case .unknown(let v): v
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(Int.self)
    self.init(rawValue: value)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

/// Column type (workflow stage).
///
/// Used in ``KaitenClient/createColumn(...)`` and ``KaitenClient/updateColumn(...)``.
/// - SeeAlso: [Kaiten API – Columns](https://developers.kaiten.ru/columns/create-column)
public enum ColumnType: Sendable, Equatable, CaseIterable, Codable {
  /// Queue column.
  case queue
  /// In-progress column.
  case inProgress
  /// Done column.
  case done
  /// Unknown value returned by the API (forward compatibility).
  case unknown(Int)

  public static var allCases: [ColumnType] { [.queue, .inProgress, .done] }

  public init(rawValue: Int) {
    switch rawValue {
    case 1: self = .queue
    case 2: self = .inProgress
    case 3: self = .done
    default: self = .unknown(rawValue)
    }
  }

  public var rawValue: Int {
    switch self {
    case .queue: 1
    case .inProgress: 2
    case .done: 3
    case .unknown(let v): v
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(Int.self)
    self.init(rawValue: value)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

/// WIP limit counting type.
///
/// Used in column and lane creation/update.
/// - SeeAlso: [Kaiten API – Columns](https://developers.kaiten.ru/columns/create-column)
public enum WipLimitType: Sendable, Equatable, CaseIterable, Codable {
  /// Limit by card count.
  case cardCount
  /// Limit by card size.
  case cardSize
  /// Unknown value returned by the API (forward compatibility).
  case unknown(Int)

  public static var allCases: [WipLimitType] { [.cardCount, .cardSize] }

  public init(rawValue: Int) {
    switch rawValue {
    case 1: self = .cardCount
    case 2: self = .cardSize
    default: self = .unknown(rawValue)
    }
  }

  public var rawValue: Int {
    switch self {
    case .cardCount: 1
    case .cardSize: 2
    case .unknown(let v): v
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(Int.self)
    self.init(rawValue: value)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

/// Card location history event condition.
///
/// Describes the board state at the time the movement event was recorded.
/// - SeeAlso: [Kaiten API – Card Location History](https://developers.kaiten.ru/cards/retrieve-card-location-history)
public enum CardHistoryCondition: Sendable, Equatable, CaseIterable, Codable {
  /// Card was on the board (active) at the time of the event.
  case active
  /// Card was archived at the time of the event.
  case archived
  /// Card was deleted at the time of the event.
  case deleted
  /// Unknown value returned by the API (forward compatibility).
  case unknown(Int)

  public static var allCases: [CardHistoryCondition] { [.active, .archived, .deleted] }

  public init(rawValue: Int) {
    switch rawValue {
    case 1: self = .active
    case 2: self = .archived
    case 3: self = .deleted
    default: self = .unknown(rawValue)
    }
  }

  public var rawValue: Int {
    switch self {
    case .active: 1
    case .archived: 2
    case .deleted: 3
    case .unknown(let v): v
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(Int.self)
    self.init(rawValue: value)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

// MARK: - Automations
//
// Automation discriminators are declared as plain strings in the OpenAPI spec
// because Kaiten returns values that its documentation does not list (for
// example the action type `change_type`). A generated closed enum would fail to
// decode those responses outright, so the typed surface lives here instead —
// with an `unknown(String)` case that preserves anything new the API adds.

/// Automation type.
///
/// Used in ``KaitenClient/createAutomation(spaceId:type:actions:name:trigger:conditions:)``.
/// - SeeAlso: [Kaiten API – Automations](https://developers.kaiten.ru/automations/create-automation)
public enum AutomationType: Sendable, Equatable, CaseIterable, Codable {
  /// Triggered by an event.
  case onAction
  /// Triggered by a due date.
  case onDate
  /// Triggered manually via the automation button on a card.
  case onDemand
  /// Unknown value returned by the API (forward compatibility).
  case unknown(String)

  public static var allCases: [AutomationType] {
    [.onAction, .onDate, .onDemand]
  }

  public init(rawValue: String) {
    switch rawValue {
    case "on_action": self = .onAction
    case "on_date": self = .onDate
    case "on_demand": self = .onDemand
    default: self = .unknown(rawValue)
    }
  }

  public var rawValue: String {
    switch self {
    case .onAction: "on_action"
    case .onDate: "on_date"
    case .onDemand: "on_demand"
    case .unknown(let v): v
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(String.self)
    self.init(rawValue: value)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

/// Automation status.
/// - SeeAlso: [Kaiten API – Automations](https://developers.kaiten.ru/automations/get-list-of-automations)
public enum AutomationStatus: Sendable, Equatable, CaseIterable, Codable {
  /// Automation is enabled.
  case active
  /// Automation is switched off.
  case disabled
  /// Automation is deleted.
  case removed
  /// Automation references a missing entity and cannot run.
  case broken
  /// Unknown value returned by the API (forward compatibility).
  case unknown(String)

  public static var allCases: [AutomationStatus] {
    [.active, .disabled, .removed, .broken]
  }

  public init(rawValue: String) {
    switch rawValue {
    case "active": self = .active
    case "disabled": self = .disabled
    case "removed": self = .removed
    case "broken": self = .broken
    default: self = .unknown(rawValue)
    }
  }

  public var rawValue: String {
    switch self {
    case .active: "active"
    case .disabled: "disabled"
    case .removed: "removed"
    case .broken: "broken"
    case .unknown(let v): v
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(String.self)
    self.init(rawValue: value)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

/// Automation trigger type.
/// - SeeAlso: [Kaiten API – Automations](https://developers.kaiten.ru/automations/get-list-of-automations)
public enum AutomationTriggerType: Sendable, Equatable, CaseIterable, Codable {
  /// Card moved.
  case cardMovedInPath
  /// Card created.
  case cardCreated
  /// Comment is posted to a card.
  case commentPosted
  /// Card member added.
  case cardUserAdded
  /// Card responsible member added.
  case responsibleAdded
  /// Card type is changed.
  case cardTypeChanged
  /// Card state is changed.
  case cardStateChanged
  /// Property is changed.
  case customPropertyChanged
  /// Due date is changed.
  case dueDateChanged
  /// Checklist item is checked.
  case checklistItemChecked
  /// All checklists in a card are completed.
  case checklistsCompleted
  /// Child cards state is changed.
  case childCardsStateChanged
  /// Tag added.
  case tagAdded
  /// Tag removed.
  case tagRemoved
  /// Card is blocked.
  case blocked
  /// Card is unblocked.
  case unblocked
  /// Blocker is added to a card.
  case blockerAdded
  /// Card has a due date.
  case dueDateOnDate
  /// Checklist item has a due date.
  case checklistItemDueDateOnDate
  /// A field with the Date type has a date.
  case customPropertyDateOnDate
  /// All automation conditions are met.
  case allConditionsMet
  /// Unknown value returned by the API (forward compatibility).
  case unknown(String)

  public static var allCases: [AutomationTriggerType] {
    [
      .cardMovedInPath,
      .cardCreated,
      .commentPosted,
      .cardUserAdded,
      .responsibleAdded,
      .cardTypeChanged,
      .cardStateChanged,
      .customPropertyChanged,
      .dueDateChanged,
      .checklistItemChecked,
      .checklistsCompleted,
      .childCardsStateChanged,
      .tagAdded,
      .tagRemoved,
      .blocked,
      .unblocked,
      .blockerAdded,
      .dueDateOnDate,
      .checklistItemDueDateOnDate,
      .customPropertyDateOnDate,
      .allConditionsMet,
    ]
  }

  public init(rawValue: String) {
    switch rawValue {
    case "card_moved_in_path": self = .cardMovedInPath
    case "card_created": self = .cardCreated
    case "comment_posted": self = .commentPosted
    case "card_user_added": self = .cardUserAdded
    case "responsible_added": self = .responsibleAdded
    case "card_type_changed": self = .cardTypeChanged
    case "card_state_changed": self = .cardStateChanged
    case "custom_property_changed": self = .customPropertyChanged
    case "due_date_changed": self = .dueDateChanged
    case "checklist_item_checked": self = .checklistItemChecked
    case "checklists_completed": self = .checklistsCompleted
    case "child_cards_state_changed": self = .childCardsStateChanged
    case "tag_added": self = .tagAdded
    case "tag_removed": self = .tagRemoved
    case "blocked": self = .blocked
    case "unblocked": self = .unblocked
    case "blocker_added": self = .blockerAdded
    case "due_date_on_date": self = .dueDateOnDate
    case "checklist_item_due_date_on_date": self = .checklistItemDueDateOnDate
    case "custom_property_date_on_date": self = .customPropertyDateOnDate
    case "all_conditions_met": self = .allConditionsMet
    default: self = .unknown(rawValue)
    }
  }

  public var rawValue: String {
    switch self {
    case .cardMovedInPath: "card_moved_in_path"
    case .cardCreated: "card_created"
    case .commentPosted: "comment_posted"
    case .cardUserAdded: "card_user_added"
    case .responsibleAdded: "responsible_added"
    case .cardTypeChanged: "card_type_changed"
    case .cardStateChanged: "card_state_changed"
    case .customPropertyChanged: "custom_property_changed"
    case .dueDateChanged: "due_date_changed"
    case .checklistItemChecked: "checklist_item_checked"
    case .checklistsCompleted: "checklists_completed"
    case .childCardsStateChanged: "child_cards_state_changed"
    case .tagAdded: "tag_added"
    case .tagRemoved: "tag_removed"
    case .blocked: "blocked"
    case .unblocked: "unblocked"
    case .blockerAdded: "blocker_added"
    case .dueDateOnDate: "due_date_on_date"
    case .checklistItemDueDateOnDate: "checklist_item_due_date_on_date"
    case .customPropertyDateOnDate: "custom_property_date_on_date"
    case .allConditionsMet: "all_conditions_met"
    case .unknown(let v): v
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(String.self)
    self.init(rawValue: value)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

/// Automation action type.
/// - SeeAlso: [Kaiten API – Automations](https://developers.kaiten.ru/automations/get-list-of-automations)
public enum AutomationActionType: Sendable, Equatable, CaseIterable, Codable {
  /// Make responsible.
  case addAssignee
  /// Remove responsible.
  case removeAssignee
  /// Add card members.
  case addCardUsers
  /// Remove card members.
  case removeCardUsers
  /// Add user groups to a card.
  case addUserGroups
  /// Add tags.
  case addTag
  /// Remove tags.
  case removeTags
  /// Add property.
  case addProperty
  /// Add property to child cards.
  case propertyAddToChildCard
  /// Add size.
  case addSize
  /// Add timeline.
  case addTimeline
  /// Change ASAP.
  case changeAsap
  /// Set due date.
  case addDueDate
  /// Remove due date.
  case removeDueDate
  /// Move card to.
  case moveToPath
  /// Move a card within the board.
  case moveOnBoard
  /// Archive card.
  case archive
  /// Create child card.
  case addChildCard
  /// Create parent card.
  case addParentCard
  /// Add parent card.
  case connectParentCard
  /// Complete all checklists in card.
  case completeChecklists
  /// Sort cards.
  case sortCards
  /// Add comment.
  case addComment
  /// Add SLA.
  case cardAddSla
  /// Remove SLA.
  case cardRemoveSla
  /// Unknown value returned by the API (forward compatibility).
  case unknown(String)

  public static var allCases: [AutomationActionType] {
    [
      .addAssignee,
      .removeAssignee,
      .addCardUsers,
      .removeCardUsers,
      .addUserGroups,
      .addTag,
      .removeTags,
      .addProperty,
      .propertyAddToChildCard,
      .addSize,
      .addTimeline,
      .changeAsap,
      .addDueDate,
      .removeDueDate,
      .moveToPath,
      .moveOnBoard,
      .archive,
      .addChildCard,
      .addParentCard,
      .connectParentCard,
      .completeChecklists,
      .sortCards,
      .addComment,
      .cardAddSla,
      .cardRemoveSla,
    ]
  }

  public init(rawValue: String) {
    switch rawValue {
    case "add_assignee": self = .addAssignee
    case "remove_assignee": self = .removeAssignee
    case "add_card_users": self = .addCardUsers
    case "remove_card_users": self = .removeCardUsers
    case "add_user_groups": self = .addUserGroups
    case "add_tag": self = .addTag
    case "remove_tags": self = .removeTags
    case "add_property": self = .addProperty
    case "property_add_to_child_card": self = .propertyAddToChildCard
    case "add_size": self = .addSize
    case "add_timeline": self = .addTimeline
    case "change_asap": self = .changeAsap
    case "add_due_date": self = .addDueDate
    case "remove_due_date": self = .removeDueDate
    case "move_to_path": self = .moveToPath
    case "move_on_board": self = .moveOnBoard
    case "archive": self = .archive
    case "add_child_card": self = .addChildCard
    case "add_parent_card": self = .addParentCard
    case "connect_parent_card": self = .connectParentCard
    case "complete_checklists": self = .completeChecklists
    case "sort_cards": self = .sortCards
    case "add_comment": self = .addComment
    case "card_add_sla": self = .cardAddSla
    case "card_remove_sla": self = .cardRemoveSla
    default: self = .unknown(rawValue)
    }
  }

  public var rawValue: String {
    switch self {
    case .addAssignee: "add_assignee"
    case .removeAssignee: "remove_assignee"
    case .addCardUsers: "add_card_users"
    case .removeCardUsers: "remove_card_users"
    case .addUserGroups: "add_user_groups"
    case .addTag: "add_tag"
    case .removeTags: "remove_tags"
    case .addProperty: "add_property"
    case .propertyAddToChildCard: "property_add_to_child_card"
    case .addSize: "add_size"
    case .addTimeline: "add_timeline"
    case .changeAsap: "change_asap"
    case .addDueDate: "add_due_date"
    case .removeDueDate: "remove_due_date"
    case .moveToPath: "move_to_path"
    case .moveOnBoard: "move_on_board"
    case .archive: "archive"
    case .addChildCard: "add_child_card"
    case .addParentCard: "add_parent_card"
    case .connectParentCard: "connect_parent_card"
    case .completeChecklists: "complete_checklists"
    case .sortCards: "sort_cards"
    case .addComment: "add_comment"
    case .cardAddSla: "card_add_sla"
    case .cardRemoveSla: "card_remove_sla"
    case .unknown(let v): v
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(String.self)
    self.init(rawValue: value)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

/// Boolean clause joining automation conditions within a group.
/// - SeeAlso: [Kaiten API – Automations](https://developers.kaiten.ru/automations/get-list-of-automations)
public enum AutomationConditionClause: Sendable, Equatable, CaseIterable, Codable {
  /// All nested conditions must match.
  case and
  /// Any nested condition must match.
  case or
  /// Unknown value returned by the API (forward compatibility).
  case unknown(String)

  public static var allCases: [AutomationConditionClause] {
    [.and, .or]
  }

  public init(rawValue: String) {
    switch rawValue {
    case "and": self = .and
    case "or": self = .or
    default: self = .unknown(rawValue)
    }
  }

  public var rawValue: String {
    switch self {
    case .and: "and"
    case .or: "or"
    case .unknown(let v): v
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(String.self)
    self.init(rawValue: value)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

// MARK: - Audit Logs

/// Audit log event category.
///
/// Used in ``KaitenClient/listAuditLogs(from:to:authorId:authorUid:categories:actions:id:offset:limit:)``.
/// - SeeAlso: [Kaiten API – Audit logs](https://developers.kaiten.ru/audit-logs/retrieve-audit-log-events)
public enum AuditLogCategory: Sendable, Equatable, CaseIterable, Codable {
  /// Application lifecycle events.
  case app
  /// Authentication events.
  case auth
  /// User profile events.
  case userProfile
  /// User management events.
  case userManagement
  /// Group management events.
  case groupManagement
  /// Service desk events.
  case serviceDesk
  /// Publication events.
  case publication
  /// Import events.
  case `import`
  /// Company profile events.
  case companyProfile
  /// Unknown value returned by the API (forward compatibility).
  case unknown(String)

  public static var allCases: [AuditLogCategory] {
    [
      .app, .auth, .userProfile, .userManagement, .groupManagement, .serviceDesk, .publication,
      .import, .companyProfile,
    ]
  }

  public init(rawValue: String) {
    switch rawValue {
    case "app": self = .app
    case "auth": self = .auth
    case "user_profile": self = .userProfile
    case "user_management": self = .userManagement
    case "group_management": self = .groupManagement
    case "service_desk": self = .serviceDesk
    case "publication": self = .publication
    case "import": self = .import
    case "company_profile": self = .companyProfile
    default: self = .unknown(rawValue)
    }
  }

  public var rawValue: String {
    switch self {
    case .app: "app"
    case .auth: "auth"
    case .userProfile: "user_profile"
    case .userManagement: "user_management"
    case .groupManagement: "group_management"
    case .serviceDesk: "service_desk"
    case .publication: "publication"
    case .import: "import"
    case .companyProfile: "company_profile"
    case .unknown(let v): v
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(String.self)
    self.init(rawValue: value)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

/// Audit log event action.
///
/// Used in ``KaitenClient/listAuditLogs(from:to:authorId:authorUid:categories:actions:id:offset:limit:)``.
/// - SeeAlso: [Kaiten API – Audit logs](https://developers.kaiten.ru/audit-logs/retrieve-audit-log-events)
public enum AuditLogAction: Sendable, Equatable, CaseIterable, Codable {
  /// Application started.
  case start
  /// Application stopped.
  case stop
  /// Successful sign-in.
  case signIn
  /// Failed sign-in attempt.
  case signInFail
  /// Sign-out.
  case signOut
  /// Authentication PIN requested.
  case requestAuthPin
  /// Password changed.
  case changePassword
  /// Email change requested.
  case requestChangeEmail
  /// Email changed.
  case changeEmail
  /// User invited.
  case invite
  /// User invitation failed.
  case inviteFail
  /// User deactivated.
  case deactivate
  /// User activated.
  case activate
  /// Permissions changed.
  case changePermissions
  /// Application permissions changed.
  case changeAppsPermissions
  /// Access granted.
  case grantAccess
  /// Access revoked.
  case revokeAccess
  /// Ownership transferred.
  case transferOwnership
  /// User data depersonalized.
  case depersonalization
  /// Entity created.
  case create
  /// Entity deleted.
  case delete
  /// Group activated.
  case groupActivate
  /// Group deactivated.
  case groupDeactivate
  /// User added.
  case addUser
  /// Admin added.
  case addAdmin
  /// User added by an admin.
  case adminAddUser
  /// User deleted.
  case deleteUser
  /// User deleted by an admin.
  case adminDeleteUser
  /// Admin deleted.
  case deleteAdmin
  /// Service desk password set.
  case setSdPassword
  /// Temporary service desk password changed.
  case changeTemporarySdPassword
  /// Document published.
  case publishDocument
  /// Document group published.
  case publishDocumentGroup
  /// Card published.
  case publishCard
  /// Document unpublished.
  case unpublishDocument
  /// Document group unpublished.
  case unpublishDocumentGroup
  /// Card unpublished.
  case unpublishCard
  /// Entity shared.
  case shareEntity
  /// Entity unshared.
  case unshareEntity
  /// Public link created.
  case publicLink
  /// Trial extended.
  case extendTrial
  /// Unknown value returned by the API (forward compatibility).
  case unknown(String)

  public static var allCases: [AuditLogAction] {
    [
      .start, .stop, .signIn, .signInFail, .signOut, .requestAuthPin, .changePassword,
      .requestChangeEmail, .changeEmail, .invite, .inviteFail, .deactivate, .activate,
      .changePermissions, .changeAppsPermissions, .grantAccess, .revokeAccess, .transferOwnership,
      .depersonalization, .create, .delete, .groupActivate, .groupDeactivate, .addUser, .addAdmin,
      .adminAddUser, .deleteUser, .adminDeleteUser, .deleteAdmin, .setSdPassword,
      .changeTemporarySdPassword, .publishDocument, .publishDocumentGroup, .publishCard,
      .unpublishDocument, .unpublishDocumentGroup, .unpublishCard, .shareEntity, .unshareEntity,
      .publicLink, .extendTrial,
    ]
  }

  public init(rawValue: String) {
    switch rawValue {
    case "start": self = .start
    case "stop": self = .stop
    case "sign_in": self = .signIn
    case "sign_in_fail": self = .signInFail
    case "sign_out": self = .signOut
    case "request_auth_pin": self = .requestAuthPin
    case "change_password": self = .changePassword
    case "request_change_email": self = .requestChangeEmail
    case "change_email": self = .changeEmail
    case "invite": self = .invite
    case "invite_fail": self = .inviteFail
    case "deactivate": self = .deactivate
    case "activate": self = .activate
    case "change_permissions": self = .changePermissions
    case "change_apps_permissions": self = .changeAppsPermissions
    case "grant_access": self = .grantAccess
    case "revoke_access": self = .revokeAccess
    case "transfer_ownership": self = .transferOwnership
    case "depersonalization": self = .depersonalization
    case "create": self = .create
    case "delete": self = .delete
    case "group_activate": self = .groupActivate
    case "group_deactivate": self = .groupDeactivate
    case "add_user": self = .addUser
    case "add_admin": self = .addAdmin
    case "admin_add_user": self = .adminAddUser
    case "delete_user": self = .deleteUser
    case "admin_delete_user": self = .adminDeleteUser
    case "delete_admin": self = .deleteAdmin
    case "set_sd_password": self = .setSdPassword
    case "change_temporary_sd_password": self = .changeTemporarySdPassword
    case "publish_document": self = .publishDocument
    case "publish_document_group": self = .publishDocumentGroup
    case "publish_card": self = .publishCard
    case "unpublish_document": self = .unpublishDocument
    case "unpublish_document_group": self = .unpublishDocumentGroup
    case "unpublish_card": self = .unpublishCard
    case "share_entity": self = .shareEntity
    case "unshare_entity": self = .unshareEntity
    case "public_link": self = .publicLink
    case "extend_trial": self = .extendTrial
    default: self = .unknown(rawValue)
    }
  }

  public var rawValue: String {
    switch self {
    case .start: "start"
    case .stop: "stop"
    case .signIn: "sign_in"
    case .signInFail: "sign_in_fail"
    case .signOut: "sign_out"
    case .requestAuthPin: "request_auth_pin"
    case .changePassword: "change_password"
    case .requestChangeEmail: "request_change_email"
    case .changeEmail: "change_email"
    case .invite: "invite"
    case .inviteFail: "invite_fail"
    case .deactivate: "deactivate"
    case .activate: "activate"
    case .changePermissions: "change_permissions"
    case .changeAppsPermissions: "change_apps_permissions"
    case .grantAccess: "grant_access"
    case .revokeAccess: "revoke_access"
    case .transferOwnership: "transfer_ownership"
    case .depersonalization: "depersonalization"
    case .create: "create"
    case .delete: "delete"
    case .groupActivate: "group_activate"
    case .groupDeactivate: "group_deactivate"
    case .addUser: "add_user"
    case .addAdmin: "add_admin"
    case .adminAddUser: "admin_add_user"
    case .deleteUser: "delete_user"
    case .adminDeleteUser: "admin_delete_user"
    case .deleteAdmin: "delete_admin"
    case .setSdPassword: "set_sd_password"
    case .changeTemporarySdPassword: "change_temporary_sd_password"
    case .publishDocument: "publish_document"
    case .publishDocumentGroup: "publish_document_group"
    case .publishCard: "publish_card"
    case .unpublishDocument: "unpublish_document"
    case .unpublishDocumentGroup: "unpublish_document_group"
    case .unpublishCard: "unpublish_card"
    case .shareEntity: "share_entity"
    case .unshareEntity: "unshare_entity"
    case .publicLink: "public_link"
    case .extendTrial: "extend_trial"
    case .unknown(let v): v
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(String.self)
    self.init(rawValue: value)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

// MARK: - Batch Update Cards

/// Field type cards are sorted by when a batch update repositions them.
///
/// Used in ``KaitenClient/batchUpdateCards(boardId:columnId:laneId:ownerId:typeId:condition:attributes:orderBy:)``.
/// - SeeAlso: [Kaiten API – Batch update for cards](https://developers.kaiten.ru/cards/batch-update-for-cards)
public enum BatchUpdateOrderField: Sendable, Equatable, CaseIterable, Codable {
  /// Sort by a custom property (identified by the `id` sorting parameter).
  case customProperty
  /// Sort by card size.
  case size
  /// Sort by creation date.
  case created
  /// Sort by due date.
  case dueDate
  /// Sort by title.
  case title
  /// Unknown value (forward compatibility).
  case unknown(String)

  public static var allCases: [BatchUpdateOrderField] {
    [.customProperty, .size, .created, .dueDate, .title]
  }

  public init(rawValue: String) {
    switch rawValue {
    case "cp": self = .customProperty
    case "size": self = .size
    case "created": self = .created
    case "due_date": self = .dueDate
    case "title": self = .title
    default: self = .unknown(rawValue)
    }
  }

  public var rawValue: String {
    switch self {
    case .customProperty: "cp"
    case .size: "size"
    case .created: "created"
    case .dueDate: "due_date"
    case .title: "title"
    case .unknown(let v): v
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(String.self)
    self.init(rawValue: value)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

// MARK: - Card Types

/// Regular (preset) card property suggested by a card type.
///
/// Travels as a plain string in ``Components/Schemas/CardTypeProperty`` and
/// ``Components/Schemas/CardTypePropertyInput`` so undocumented values survive decoding.
/// - SeeAlso: [Kaiten API – Card types](https://developers.kaiten.ru/card-types/get-card-type)
public enum CardTypeRegularProperty: Sendable, Equatable, CaseIterable, Codable {
  /// Card size.
  case size
  /// Card due date.
  case dueDate
  /// Card tags.
  case tags
  /// Card timeline.
  case timeline
  /// Card description.
  case description
  /// Unknown value returned by the API (forward compatibility).
  case unknown(String)

  public static var allCases: [CardTypeRegularProperty] {
    [.size, .dueDate, .tags, .timeline, .description]
  }

  public init(rawValue: String) {
    switch rawValue {
    case "size": self = .size
    case "due_date": self = .dueDate
    case "tags": self = .tags
    case "timeline": self = .timeline
    case "description": self = .description
    default: self = .unknown(rawValue)
    }
  }

  public var rawValue: String {
    switch self {
    case .size: "size"
    case .dueDate: "due_date"
    case .tags: "tags"
    case .timeline: "timeline"
    case .description: "description"
    case .unknown(let v): v
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(String.self)
    self.init(rawValue: value)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

/// Sorting direction of a batch card update.
/// - SeeAlso: [Kaiten API – Batch update for cards](https://developers.kaiten.ru/cards/batch-update-for-cards)
public enum SortDirection: Sendable, Equatable, CaseIterable, Codable {
  /// Ascending order.
  case ascending
  /// Descending order.
  case descending
  /// Unknown value (forward compatibility).
  case unknown(String)

  public static var allCases: [SortDirection] {
    [.ascending, .descending]
  }

  public init(rawValue: String) {
    switch rawValue {
    case "asc": self = .ascending
    case "desc": self = .descending
    default: self = .unknown(rawValue)
    }
  }

  public var rawValue: String {
    switch self {
    case .ascending: "asc"
    case .descending: "desc"
    case .unknown(let v): v
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(String.self)
    self.init(rawValue: value)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

// MARK: - Custom Properties
//
// Custom property discriminators are declared as plain strings in the OpenAPI
// spec so that values the documentation does not list survive decoding. The
// typed surface lives here instead — with an `unknown(String)` case that
// preserves anything new the API adds.

/// Custom property value type.
///
/// Used in ``KaitenClient/createCustomProperty(name:type:showOnFacade:multiline:voteVariant:valuesType:colorful:multiSelect:valuesCreatableByUsers:data:color:fieldsSettings:)``.
/// - SeeAlso: [Kaiten API – Custom properties](https://developers.kaiten.ru/custom-properties/create-new-property)
public enum CustomPropertyType: Sendable, Equatable, CaseIterable, Codable {
  /// Free-form text value.
  case string
  /// Numeric value.
  case number
  /// Date value.
  case date
  /// Email address value.
  case email
  /// Phone number value.
  case phone
  /// Boolean checkbox value.
  case checkbox
  /// Value picked from predefined select values.
  case select
  /// Value calculated by a formula.
  case formula
  /// URL value.
  case url
  /// Collective score value.
  case collectiveScore
  /// Vote value.
  case vote
  /// Collective vote value.
  case collectiveVote
  /// Catalog (directory) value.
  case catalog
  /// User reference value.
  case user
  /// File attachment value.
  case attachment
  /// Unknown value returned by the API (forward compatibility).
  case unknown(String)

  public static var allCases: [CustomPropertyType] {
    [
      .string, .number, .date, .email, .phone, .checkbox, .select, .formula, .url,
      .collectiveScore, .vote, .collectiveVote, .catalog, .user, .attachment,
    ]
  }

  public init(rawValue: String) {
    switch rawValue {
    case "string": self = .string
    case "number": self = .number
    case "date": self = .date
    case "email": self = .email
    case "phone": self = .phone
    case "checkbox": self = .checkbox
    case "select": self = .select
    case "formula": self = .formula
    case "url": self = .url
    case "collective_score": self = .collectiveScore
    case "vote": self = .vote
    case "collective_vote": self = .collectiveVote
    case "catalog": self = .catalog
    case "user": self = .user
    case "attachment": self = .attachment
    default: self = .unknown(rawValue)
    }
  }

  public var rawValue: String {
    switch self {
    case .string: "string"
    case .number: "number"
    case .date: "date"
    case .email: "email"
    case .phone: "phone"
    case .checkbox: "checkbox"
    case .select: "select"
    case .formula: "formula"
    case .url: "url"
    case .collectiveScore: "collective_score"
    case .vote: "vote"
    case .collectiveVote: "collective_vote"
    case .catalog: "catalog"
    case .user: "user"
    case .attachment: "attachment"
    case .unknown(let v): v
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(String.self)
    self.init(rawValue: value)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

/// Custom property condition.
///
/// Used in ``KaitenClient/updateCustomProperty(id:name:showOnFacade:multiline:condition:colorful:multiSelect:valuesCreatableByUsers:data:color:fieldsSettings:isUsedAsProgress:)``.
/// - SeeAlso: [Kaiten API – Custom properties](https://developers.kaiten.ru/custom-properties/update-property)
public enum CustomPropertyCondition: Sendable, Equatable, CaseIterable, Codable {
  /// Property is active.
  case active
  /// Property is inactive.
  case inactive
  /// Unknown value returned by the API (forward compatibility).
  case unknown(String)

  public static var allCases: [CustomPropertyCondition] {
    [.active, .inactive]
  }

  public init(rawValue: String) {
    switch rawValue {
    case "active": self = .active
    case "inactive": self = .inactive
    default: self = .unknown(rawValue)
    }
  }

  public var rawValue: String {
    switch self {
    case .active: "active"
    case .inactive: "inactive"
    case .unknown(let v): v
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(String.self)
    self.init(rawValue: value)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

/// Vote variant of vote and collective vote custom properties.
///
/// Used in ``KaitenClient/createCustomProperty(name:type:showOnFacade:multiline:voteVariant:valuesType:colorful:multiSelect:valuesCreatableByUsers:data:color:fieldsSettings:)``.
/// - SeeAlso: [Kaiten API – Custom properties](https://developers.kaiten.ru/custom-properties/create-new-property)
public enum CustomPropertyVoteVariant: Sendable, Equatable, CaseIterable, Codable {
  /// Rating vote.
  case rating
  /// Scale vote.
  case scale
  /// Emoji set vote.
  case emojiSet
  /// Unknown value returned by the API (forward compatibility).
  case unknown(String)

  public static var allCases: [CustomPropertyVoteVariant] {
    [.rating, .scale, .emojiSet]
  }

  public init(rawValue: String) {
    switch rawValue {
    case "rating": self = .rating
    case "scale": self = .scale
    case "emoji_set": self = .emojiSet
    default: self = .unknown(rawValue)
    }
  }

  public var rawValue: String {
    switch self {
    case .rating: "rating"
    case .scale: "scale"
    case .emojiSet: "emoji_set"
    case .unknown(let v): v
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(String.self)
    self.init(rawValue: value)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

/// Type of values of collective value custom properties.
///
/// Used in ``KaitenClient/createCustomProperty(name:type:showOnFacade:multiline:voteVariant:valuesType:colorful:multiSelect:valuesCreatableByUsers:data:color:fieldsSettings:)``.
/// - SeeAlso: [Kaiten API – Custom properties](https://developers.kaiten.ru/custom-properties/create-new-property)
public enum CustomPropertyValuesType: Sendable, Equatable, CaseIterable, Codable {
  /// Numeric values.
  case number
  /// Text values.
  case text
  /// Unknown value returned by the API (forward compatibility).
  case unknown(String)

  public static var allCases: [CustomPropertyValuesType] {
    [.number, .text]
  }

  public init(rawValue: String) {
    switch rawValue {
    case "number": self = .number
    case "text": self = .text
    default: self = .unknown(rawValue)
    }
  }

  public var rawValue: String {
    switch self {
    case .number: "number"
    case .text: "text"
    case .unknown(let v): v
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(String.self)
    self.init(rawValue: value)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

// MARK: - Custom Directories
//
// Custom directory discriminators are declared as plain strings in the OpenAPI
// spec: the custom-directories API is documented as beta and subject to change,
// and a generated closed enum would fail the entire response on the first value
// the documentation does not list. The typed surface lives here instead — with
// an `unknown(String)` case that preserves anything new the API adds.

/// Custom directory (and directory field) condition.
/// - SeeAlso: [Kaiten API – Custom directories](https://developers.kaiten.ru/custom-directories/get-list-of-custom-directories)
public enum CustomDirectoryCondition: Sendable, Equatable, CaseIterable, Codable {
  /// Directory or field is active.
  case active
  /// Directory or field is inactive.
  case inactive
  /// Directory or field is soft-deleted.
  case removed
  /// Unknown value returned by the API (forward compatibility).
  case unknown(String)

  public static var allCases: [CustomDirectoryCondition] {
    [.active, .inactive, .removed]
  }

  public init(rawValue: String) {
    switch rawValue {
    case "active": self = .active
    case "inactive": self = .inactive
    case "removed": self = .removed
    default: self = .unknown(rawValue)
    }
  }

  public var rawValue: String {
    switch self {
    case .active: "active"
    case .inactive: "inactive"
    case .removed: "removed"
    case .unknown(let v): v
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(String.self)
    self.init(rawValue: value)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

/// Custom directory field type.
/// - SeeAlso: [Kaiten API – Custom directories](https://developers.kaiten.ru/custom-directories/create-custom-directory)
public enum CustomDirectoryFieldType: Sendable, Equatable, CaseIterable, Codable {
  /// Text field.
  case string
  /// Numeric field.
  case number
  /// Date field.
  case date
  /// Email field.
  case email
  /// URL field.
  case url
  /// Phone number field.
  case phone
  /// Checkbox field.
  case checkbox
  /// Select field backed by a custom property.
  case select
  /// User field backed by a custom property.
  case user
  /// Catalog field backed by a custom property.
  case catalog
  /// Link to a record of another custom directory.
  case directoryLink
  /// File field.
  case file
  /// Unknown value returned by the API (forward compatibility).
  case unknown(String)

  public static var allCases: [CustomDirectoryFieldType] {
    [
      .string, .number, .date, .email, .url, .phone, .checkbox, .select, .user, .catalog,
      .directoryLink, .file,
    ]
  }

  public init(rawValue: String) {
    switch rawValue {
    case "string": self = .string
    case "number": self = .number
    case "date": self = .date
    case "email": self = .email
    case "url": self = .url
    case "phone": self = .phone
    case "checkbox": self = .checkbox
    case "select": self = .select
    case "user": self = .user
    case "catalog": self = .catalog
    case "directory_link": self = .directoryLink
    case "file": self = .file
    default: self = .unknown(rawValue)
    }
  }

  public var rawValue: String {
    switch self {
    case .string: "string"
    case .number: "number"
    case .date: "date"
    case .email: "email"
    case .url: "url"
    case .phone: "phone"
    case .checkbox: "checkbox"
    case .select: "select"
    case .user: "user"
    case .catalog: "catalog"
    case .directoryLink: "directory_link"
    case .file: "file"
    case .unknown(let v): v
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(String.self)
    self.init(rawValue: value)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}
