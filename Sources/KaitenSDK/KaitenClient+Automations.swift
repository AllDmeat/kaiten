import Foundation
import OpenAPIRuntime

// MARK: - Typed Discriminators

// Automation discriminators travel as plain strings (see the comment above the
// automation enums in `Enums.swift`). These accessors and initializers give the
// generated payloads a typed surface without losing undocumented values.

extension Components.Schemas.Automation {
  /// The automation type, or `nil` if the API omitted the field.
  public var automationType: AutomationType? {
    _type.map(AutomationType.init(rawValue:))
  }

  /// The automation status, or `nil` if the API omitted the field.
  public var automationStatus: AutomationStatus? {
    status.map(AutomationStatus.init(rawValue:))
  }
}

extension Components.Schemas.AutomationTrigger {
  /// The trigger type, or `nil` if the API omitted the field.
  public var triggerType: AutomationTriggerType? {
    _type.map(AutomationTriggerType.init(rawValue:))
  }

  /// Creates a trigger from a typed trigger type.
  ///
  /// - Parameters:
  ///   - triggerType: The trigger type.
  ///   - hasToFireOnCardCreation: Whether the trigger fires on card creation.
  ///   - data: Trigger payload. Its shape depends on the trigger type and is not
  ///     described in the Kaiten documentation.
  public init(
    triggerType: AutomationTriggerType,
    hasToFireOnCardCreation: Bool? = nil,
    data: Components.Schemas.AutomationTrigger.dataPayload? = nil
  ) {
    self.init(
      _type: triggerType.rawValue, hasToFireOnCardCreation: hasToFireOnCardCreation, data: data)
  }
}

extension Components.Schemas.AutomationAction {
  /// The action type, or `nil` if the API omitted the field.
  public var actionType: AutomationActionType? {
    _type.map(AutomationActionType.init(rawValue:))
  }

  /// Creates an action from a typed action type.
  ///
  /// - Parameters:
  ///   - actionType: The action type.
  ///   - created: Action creation timestamp.
  ///   - data: Action payload. Its shape depends on the action type and is not
  ///     described in the Kaiten documentation.
  public init(
    actionType: AutomationActionType,
    created: String? = nil,
    data: Components.Schemas.AutomationAction.dataPayload? = nil
  ) {
    self.init(_type: actionType.rawValue, created: created, data: data)
  }
}

extension Components.Schemas.AutomationConditionGroup {
  /// The clause joining the nested conditions, or `nil` if the API omitted the field.
  public var conditionClause: AutomationConditionClause? {
    clause.map(AutomationConditionClause.init(rawValue:))
  }
}

// MARK: - Automations

extension KaitenClient {
  /// Lists all automations in a space.
  ///
  /// - Parameter spaceId: The space identifier.
  /// - Returns: An array of automations. Returns an empty array if the space has no automations.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the space does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func listAutomations(spaceId: Int) async throws(KaitenError) -> [Components.Schemas
    .Automation]
  {
    guard
      let response = try await callList({
        try await client.list_automations(path: .init(space_id: spaceId))
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("space", spaceId)) {
      try $0.json
    }
  }

  /// Creates an automation in a space.
  ///
  /// - Parameters:
  ///   - spaceId: The space identifier.
  ///   - type: The automation type. `on_action` and `on_date` automations require a `trigger`;
  ///     `on_demand` (button) automations require a `name`.
  ///   - actions: The actions the automation performs. Kaiten accepts 1 to 10 actions.
  ///   - name: The automation name.
  ///   - trigger: The automation trigger.
  ///   - conditions: The automation conditions.
  /// - Returns: The created automation.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the space does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for bad request (400), unsupported
  ///     tariff (402), forbidden (403) or other undocumented HTTP status codes.
  public func createAutomation(
    spaceId: Int,
    type: AutomationType,
    actions: [Components.Schemas.AutomationAction],
    name: String? = nil,
    trigger: Components.Schemas.AutomationTrigger? = nil,
    conditions: Components.Schemas.AutomationConditionGroup? = nil
  ) async throws(KaitenError) -> Components.Schemas.Automation {
    let response = try await call {
      try await client.create_automation(
        path: .init(space_id: spaceId),
        body: .json(
          .init(
            name: name,
            _type: type.rawValue,
            trigger: trigger,
            conditions: conditions,
            actions: actions
          ))
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("space", spaceId)) {
      try $0.json
    }
  }

  /// Updates an automation.
  ///
  /// - Parameters:
  ///   - spaceId: The space identifier.
  ///   - automationUid: The automation UID.
  ///   - name: The updated automation name.
  ///   - trigger: The updated automation trigger.
  ///   - conditions: The updated automation conditions.
  ///   - actions: The updated automation actions. Kaiten accepts 1 to 10 actions.
  /// - Returns: The updated automation.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for bad request (400), unsupported
  ///     tariff (402), forbidden (403), not found (404) or other undocumented HTTP status codes.
  ///     A 404 is reported as `unexpectedResponse` rather than
  ///     ``KaitenError/notFound(resource:id:)`` because automations are addressed by string UID and
  ///     the response does not say whether the space or the automation is missing.
  public func updateAutomation(
    spaceId: Int,
    automationUid: String,
    name: String? = nil,
    trigger: Components.Schemas.AutomationTrigger? = nil,
    conditions: Components.Schemas.AutomationConditionGroup? = nil,
    actions: [Components.Schemas.AutomationAction]? = nil
  ) async throws(KaitenError) -> Components.Schemas.Automation {
    let response = try await call {
      try await client.update_automation(
        path: .init(space_id: spaceId, automation_uid: automationUid),
        body: .json(
          .init(
            name: name,
            trigger: trigger,
            conditions: conditions,
            actions: actions
          ))
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Deletes an automation.
  ///
  /// The endpoint returns HTTP 200 with no response body.
  ///
  /// - Parameters:
  ///   - spaceId: The space identifier.
  ///   - automationUid: The automation UID.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403), not found (404)
  ///     or other undocumented HTTP status codes. A 404 is reported as `unexpectedResponse` rather
  ///     than ``KaitenError/notFound(resource:id:)`` because automations are addressed by string
  ///     UID and the response does not say whether the space or the automation is missing.
  public func deleteAutomation(spaceId: Int, automationUid: String) async throws(KaitenError) {
    let response = try await call {
      try await client.delete_automation(
        path: .init(space_id: spaceId, automation_uid: automationUid)
      )
    }
    try decodeResponse(response.toCase()) { _ in () }
  }
}
