import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

/// Covers the request attributes and response fields added by SDK FR-042.
@Suite("DocumentationGaps")
struct DocumentationGapsTests {

  private func makeClient(_ transport: MockClientTransport) throws -> KaitenClient {
    try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)
  }

  private func sentJSON(_ transport: MockClientTransport) async throws -> [String: Any] {
    let recorded = try #require(transport.recordedRequests.first)
    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    return try #require(try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
  }

  // MARK: - Iterations

  @Test("iterations history sends with_details and decodes the details")
  func iterationsHistoryWithDetails() async throws {
    let json = """
      [{"iteration_id": "iter-1", "card_uid": "card-1", "added_by_uid": "user-1",
        "removed_at": null, "removed_by_uid": null, "sort_order": 1.5, "source": "manual",
        "board_uid": null, "created": "2026-01-01T00:00:00Z", "updated": "2026-01-01T00:00:00Z",
        "iteration": {"id": "iter-1", "title": "Sprint", "space_uid": "space-1",
                      "is_accessible": true},
        "addedBy": {"id": 7, "uid": "user-1", "full_name": "Jane Doe", "email": "jane@example.com",
                    "username": "jane", "avatar_initials_url": "https://example.com/a.png",
                    "avatar_uploaded_url": null, "initials": "JD", "avatar_type": 2, "lng": "en",
                    "timezone": "UTC", "theme": "light", "created": "2026-01-01T00:00:00Z",
                    "updated": "2026-01-01T00:00:00Z", "activated": true, "ui_version": 2,
                    "virtual": false, "email_blocked": null, "email_blocked_reason": null,
                    "delete_requested_at": null}},
       {"iteration_id": "iter-2", "card_uid": "card-1", "added_by_uid": "user-1",
        "removed_at": null, "removed_by_uid": null, "sort_order": 2,
        "created": "2026-01-01T00:00:00Z", "updated": "2026-01-01T00:00:00Z",
        "iteration": {"id": "iter-2", "is_accessible": false}}]
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let records = try await makeClient(transport).getCardIterationsHistory(
      cardUid: "card-1", withDetails: true)

    #expect(records.count == 2)
    #expect(records[0].source == "manual")
    #expect(records[0].board_uid == nil)
    #expect(records[0].iteration?.title == "Sprint")
    #expect(records[0].iteration?.is_accessible == true)
    #expect(records[0].addedBy?.full_name == "Jane Doe")
    #expect(records[0].removedBy == nil)
    #expect(records[1].iteration?.is_accessible == false)
    #expect(records[1].iteration?.title == nil)

    let path = try #require(transport.recordedRequests.first?.request.path)
    #expect(path.contains("with_details=true"))
  }

  @Test("iterations history omits with_details by default")
  func iterationsHistoryWithoutDetails() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: "[]")
    _ = try await makeClient(transport).getCardIterationsHistory(cardUid: "card-1")
    let path = try #require(transport.recordedRequests.first?.request.path)
    #expect(!path.contains("with_details"))
  }

  @Test("iteration card decodes card_id")
  func iterationCardId() async throws {
    let json = """
      [{"iteration_id": "iter-1", "card_uid": "card-1", "card_id": 101, "added_by_uid": "user-1",
        "removed_at": null, "removed_by_uid": null, "sort_order": 1, "source": "manual",
        "board_uid": null, "created": "2026-01-01T00:00:00Z", "updated": "2026-01-01T00:00:00Z"}]
      """
    let cards = try await makeClient(.returning(statusCode: 200, body: json)).listIterationCards(
      spaceUid: "space-1", iterationId: "iter-1")
    #expect(cards.first?.card_id == 101)
  }

  // MARK: - Card children

  @Test("card children decode full and reduced card rows")
  func cardChildren() async throws {
    let json = """
      [{"id": 11, "uid": "child-uid-1", "title": "Full", "archived": false, "asap": false,
        "due_date": null, "state": 2, "condition": 1, "board_id": 3, "column_id": 4,
        "lane_id": 5, "owner_id": 6, "type_id": 7, "card_id": 10, "depends_on_card_id": 11,
        "size": 3, "size_text": "3", "children_count": 0, "goals_total": 0,
        "counters_recalculated_at": null, "ignore_planned_dates_recalculation": false,
        "fifo_order": null, "estimate_workload": 1.5,
        "external_user_emails": null,
        "properties": null, "sprint_id": null, "external_id": null, "completed_at": null,
        "created": "2026-01-01T00:00:00Z", "updated": "2026-01-01T00:00:00Z",
        "last_moved_at": "2026-01-01T00:00:00Z", "tags": [], "members": []},
       {"id": 12, "uid": "child-uid-2", "title": "Reduced", "condition": 1, "owner_id": 6,
        "type_id": 7, "card_id": 10, "depends_on_card_id": 12, "source": null, "key": null,
        "created": "2026-01-01T00:00:00Z", "updated": "2026-01-01T00:00:00Z",
        "members": [], "tags": []}]
      """
    let children = try await makeClient(.returning(statusCode: 200, body: json))
      .listCardChildren(cardId: 10)
    #expect(children.count == 2)
    #expect(children[0].uid == "child-uid-1")
    #expect(children[0].size_text == "3")
    #expect(children[0].counters_recalculated_at == nil)
    #expect(children[0].archived == false)
    #expect(children[0].ignore_planned_dates_recalculation == false)
    #expect(children[0].sprint_id == nil)
    #expect(children[0].estimate_workload == 1.5)
    #expect(children[1].state == nil)
    #expect(children[1].depends_on_card_id == 12)
  }

  // MARK: - Comments

  @Test("comments decode author, null meta and null email_addresses_to")
  func comments() async throws {
    let json = """
      [{"id": 1, "uid": "comment-uid-1", "text": "Hi", "type": 1, "edited": false, "card_id": 10,
        "author_id": 7, "email_addresses_to": null, "internal": false, "deleted": false,
        "sd_external_recipients_cc": null, "sd_description": false,
        "notification_sent": "2026-01-01T00:00:00Z", "meta": null,
        "created": "2026-01-01T00:00:00Z", "updated": "2026-01-01T00:00:00Z",
        "author": {"id": 7, "uid": "user-1", "full_name": "Jane Doe", "email": "jane@example.com",
                   "virtual": false}}]
      """
    let comments = try await makeClient(.returning(statusCode: 200, body: json))
      .getCardComments(cardId: 10)
    #expect(comments.first?.author?.full_name == "Jane Doe")
    #expect(comments.first?.author?.uid == "user-1")
    #expect(comments.first?.email_addresses_to == nil)
    #expect(comments.first?.meta == nil)
  }

  // MARK: - Checklists

  @Test("createChecklist sends copy attributes and decodes deleted")
  func createChecklist() async throws {
    let json = """
      {"id": 5, "name": "Copy", "policy_id": null, "checklist_id": 5, "sort_order": 1,
       "deleted": false, "items": [], "created": "2026-01-01T00:00:00Z",
       "updated": "2026-01-01T00:00:00Z"}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let checklist = try await makeClient(transport).createChecklist(
      cardId: 10, name: "Copy", itemsSourceChecklistId: 3, excludeItemIds: [1, 2],
      sourceShareId: 4)
    #expect(checklist.deleted == false)

    let sent = try await sentJSON(transport)
    #expect(sent["items_source_checklist_id"] as? Int == 3)
    #expect(sent["exclude_item_ids"] as? [Int] == [1, 2])
    #expect(sent["source_share_id"] as? Int == 4)
  }

  // MARK: - Custom properties

  @Test("createCustomProperty sends directory and formula attributes")
  func createCustomProperty() async throws {
    let json = """
      {"id": 1, "uid": "prop-uid-1", "name": "Link", "type": "directory",
       "directory_id": "dir-1", "fts_version": "1", "import_uid": null,
       "is_used_as_progress": false, "calculation_method": null}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let property = try await makeClient(transport).createCustomProperty(
      name: "Link", type: .directory, directoryId: "dir-1", formula: "1 + 1",
      formulaSourceCard: .init(additionalProperties: .init(unvalidatedValue: ["id": 1])))
    #expect(property.directory_id == "dir-1")
    #expect(property.fts_version == "1")

    let sent = try await sentJSON(transport)
    #expect(sent["type"] as? String == "directory")
    #expect(sent["directory_id"] as? String == "dir-1")
    #expect(sent["formula"] as? String == "1 + 1")
    #expect((sent["formula_source_card"] as? [String: Any])?["id"] as? Int == 1)
  }

  @Test("CustomPropertyType round-trips directory")
  func directoryType() {
    #expect(CustomPropertyType(rawValue: "directory") == .directory)
    #expect(CustomPropertyType.directory.rawValue == "directory")
    #expect(CustomPropertyType.allCases.contains(.directory))
  }

  // MARK: - Custom directories

  @Test("updateCustomDirectory sends expected_field_ids")
  func updateCustomDirectory() async throws {
    let transport = MockClientTransport.returning(
      statusCode: 200, body: #"{"id": "dir-1", "name": "Dir"}"#)
    _ = try await makeClient(transport).updateCustomDirectory(
      directoryId: "dir-1", fields: [], expectedFieldIds: ["field-1", "field-2"])
    let sent = try await sentJSON(transport)
    #expect(sent["expected_field_ids"] as? [String] == ["field-1", "field-2"])
  }

  @Test("updateCustomDirectory maps 409 to unexpectedResponse")
  func updateCustomDirectoryConflict() async throws {
    let client = try makeClient(.returning(statusCode: 409, body: #"{"code": 16}"#))
    do {
      _ = try await client.updateCustomDirectory(
        directoryId: "dir-1", fields: [], expectedFieldIds: ["field-1"])
      Issue.record("expected an error")
    } catch {
      guard case .unexpectedResponse(let code, _) = error else {
        Issue.record("expected unexpectedResponse, got \(error)")
        return
      }
      #expect(code == 409)
    }
  }

  // MARK: - Blockers

  @Test("updateCardBlocker sends due date fields")
  func updateCardBlockerDueDate() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: #"{"id": 1}"#)
    _ = try await makeClient(transport).updateCardBlocker(
      cardId: 10, blockerId: 1, dueDate: "2026-01-01T10:00:00Z", dueDateTimePresent: true)
    let sent = try await sentJSON(transport)
    #expect(sent["due_date"] as? String == "2026-01-01T10:00:00Z")
    #expect(sent["due_date_time_present"] as? Bool == true)
  }

  @Test("updateCardBlocker sends null to clear the due date and omits it by default")
  func updateCardBlockerClearDueDate() async throws {
    let clearing = MockClientTransport.returning(statusCode: 200, body: #"{"id": 1}"#)
    _ = try await makeClient(clearing).updateCardBlocker(
      cardId: 10, blockerId: 1, dueDate: .some(nil))
    let cleared = try await sentJSON(clearing)
    #expect(cleared["due_date"] is NSNull)

    let untouched = MockClientTransport.returning(statusCode: 200, body: #"{"id": 1}"#)
    _ = try await makeClient(untouched).updateCardBlocker(cardId: 10, blockerId: 1, reason: "r")
    let sent = try await sentJSON(untouched)
    #expect(sent["due_date"] == nil)
  }
}
