import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("Automations")
struct AutomationsTests {

  private func makeClient(_ transport: MockClientTransport) throws -> KaitenClient {
    try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)
  }

  /// `KaitenError` is not `Equatable`, so the status code is matched by pattern.
  private func expectUnexpectedResponse(
    statusCode: Int,
    sourceLocation: SourceLocation = #_sourceLocation,
    _ operation: () async throws -> Void
  ) async {
    do {
      try await operation()
      Issue.record(
        "expected KaitenError.unexpectedResponse(statusCode: \(statusCode)), no error thrown",
        sourceLocation: sourceLocation)
    } catch let error as KaitenError {
      guard case .unexpectedResponse(let code, _) = error, code == statusCode else {
        Issue.record(
          "expected KaitenError.unexpectedResponse(statusCode: \(statusCode)), got \(error)",
          sourceLocation: sourceLocation)
        return
      }
    } catch {
      Issue.record("expected KaitenError, got \(error)", sourceLocation: sourceLocation)
    }
  }

  // MARK: - List

  @Test("200 returns array of Automation")
  func listSuccess() async throws {
    let json = """
      [{
        "id": "5355bdb2-3b52-4d2e-9162-beee750c1f47",
        "name": "Assign on create",
        "sort_order": 1.5,
        "space_uid": "space-uid",
        "updater_id": 42,
        "status": "active",
        "type": "on_action",
        "trigger": {"type": "card_created", "hasToFireOnCardCreation": true, "data": {}},
        "actions": [{"type": "add_assignee", "created": "2023-09-19T07:34:34.112Z", "data": {}}],
        "conditions": null
      }]
      """
    let client = try makeClient(.returning(statusCode: 200, body: json))

    let automations = try await client.listAutomations(spaceId: 38155)
    #expect(automations.count == 1)
    #expect(automations[0].id == "5355bdb2-3b52-4d2e-9162-beee750c1f47")
    #expect(automations[0].automationStatus == .active)
    #expect(automations[0].automationType == .onAction)
    #expect(automations[0].trigger?.triggerType == .cardCreated)
    #expect(automations[0].actions?.first?.actionType == .addAssignee)
  }

  @Test("200 with empty body returns empty array")
  func listEmptyBody() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: ""))
    let automations = try await client.listAutomations(spaceId: 38155)
    #expect(automations.isEmpty)
  }

  /// Button (`on_demand`) automations come back with `trigger` and `conditions` set to JSON null,
  /// which the Kaiten documentation declares as non-nullable objects.
  @Test("null trigger and conditions decode to nil")
  func listNullTrigger() async throws {
    let json = """
      [{
        "id": "uid-1",
        "name": "Button automation",
        "type": "on_demand",
        "status": "broken",
        "trigger": null,
        "conditions": null,
        "actions": [{"type": "complete_checklists", "data": {}}],
        "tags": [{"id": 44771, "name": "iOS", "color": 3}],
        "brokenLogs": [{"id": "log-1", "status": "broken"}]
      }]
      """
    let client = try makeClient(.returning(statusCode: 200, body: json))

    let automations = try await client.listAutomations(spaceId: 38155)
    #expect(automations[0].trigger == nil)
    #expect(automations[0].conditions == nil)
    #expect(automations[0].automationType == .onDemand)
    #expect(automations[0].tags?.first?.name == "iOS")
    #expect(automations[0].brokenLogs?.count == 1)
  }

  /// Kaiten returns action types its documentation does not list (`change_type` is a live
  /// example). A closed enum would fail the whole response, so undocumented values must survive
  /// as `.unknown`.
  @Test("undocumented discriminators decode as unknown")
  func listUndocumentedDiscriminators() async throws {
    let json = """
      [{
        "id": "uid-1",
        "type": "on_action",
        "status": "some_new_status",
        "trigger": {"type": "some_new_trigger"},
        "actions": [{"type": "change_type"}],
        "conditions": {"clause": "xor", "conditions": []}
      }]
      """
    let client = try makeClient(.returning(statusCode: 200, body: json))

    let automations = try await client.listAutomations(spaceId: 38155)
    #expect(automations[0].actions?.first?.actionType == .unknown("change_type"))
    #expect(automations[0].trigger?.triggerType == .unknown("some_new_trigger"))
    #expect(automations[0].automationStatus == .unknown("some_new_status"))
    #expect(automations[0].conditions?.conditionClause == .unknown("xor"))
    #expect(automations[0].automationType == .onAction)
  }

  @Test("404 throws notFound")
  func listNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await #expect(throws: KaitenError.self) {
      _ = try await client.listAutomations(spaceId: 999)
    }
  }

  @Test("401 throws unauthorized")
  func listUnauthorized() async throws {
    let client = try makeClient(.returning(statusCode: 401))
    await #expect(throws: KaitenError.self) {
      _ = try await client.listAutomations(spaceId: 1)
    }
  }

  // MARK: - Create

  @Test("create sends type and actions in the body")
  func createSendsBody() async throws {
    let json = """
      {"id": "new-uid", "type": "on_demand", "status": "active", "actions": []}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let automation = try await client.createAutomation(
      spaceId: 38155,
      type: .onDemand,
      actions: [.init(actionType: .completeChecklists)],
      name: "Button automation"
    )

    #expect(automation.id == "new-uid")

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .post)
    #expect(recorded.request.path == "/spaces/38155/automations")

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["type"] as? String == "on_demand")
    #expect(sent["name"] as? String == "Button automation")
    let sentActions = try #require(sent["actions"] as? [[String: Any]])
    #expect(sentActions.first?["type"] as? String == "complete_checklists")
  }

  @Test("402 unsupported tariff throws unexpectedResponse")
  func createPaymentRequired() async throws {
    let client = try makeClient(.returning(statusCode: 402))
    await expectUnexpectedResponse(statusCode: 402) {
      _ = try await client.createAutomation(
        spaceId: 1, type: .onAction, actions: [.init(actionType: .addTag)])
    }
  }

  // MARK: - Update

  @Test("update targets the automation UID")
  func updateSuccess() async throws {
    let json = """
      {"id": "uid-1", "name": "Renamed", "type": "on_action", "status": "disabled"}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let automation = try await client.updateAutomation(
      spaceId: 38155, automationUid: "uid-1", name: "Renamed")

    #expect(automation.name == "Renamed")
    #expect(automation.automationStatus == .disabled)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .patch)
    #expect(recorded.request.path == "/spaces/38155/automations/uid-1")
  }

  /// Automations are addressed by string UID, which ``KaitenError/notFound(resource:id:)``
  /// cannot represent, so a 404 surfaces as `unexpectedResponse`.
  @Test("404 throws unexpectedResponse")
  func updateNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await expectUnexpectedResponse(statusCode: 404) {
      _ = try await client.updateAutomation(spaceId: 1, automationUid: "missing")
    }
  }

  // MARK: - Delete

  @Test("delete succeeds on 200 with no body")
  func deleteSuccess() async throws {
    let transport = MockClientTransport.returning(statusCode: 200)
    let client = try makeClient(transport)

    try await client.deleteAutomation(spaceId: 38155, automationUid: "uid-1")

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .delete)
    #expect(recorded.request.path == "/spaces/38155/automations/uid-1")
  }

  @Test("delete 403 throws unexpectedResponse")
  func deleteForbidden() async throws {
    let client = try makeClient(.returning(statusCode: 403))
    await expectUnexpectedResponse(statusCode: 403) {
      try await client.deleteAutomation(spaceId: 1, automationUid: "uid-1")
    }
  }
}
