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
