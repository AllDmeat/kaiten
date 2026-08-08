import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("Checklist Cards")
struct ChecklistCardsTests {

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

  /// Sanitized copy of a live response: field set, types and nullability are preserved.
  private static let cardJSON = """
    [
      {
        "archived": true,
        "asap": false,
        "blocked": false,
        "blocking_card": false,
        "board_id": 5,
        "calculated_planned_end": null,
        "calculated_planned_start": null,
        "card_cp_value_fts_version": "3",
        "card_tag_fts_version": "2",
        "children_count": 0,
        "children_done": 0,
        "children_ids": null,
        "children_number_properties_sum": null,
        "column_changed_at": "2024-10-25T10:37:26.375Z",
        "column_id": 3,
        "comment_last_added_at": "2024-10-25T08:36:57.209Z",
        "comments_total": 1,
        "completed_at": null,
        "completed_on_time": null,
        "condition": 2,
        "counters_recalculated_at": "2026-02-25T08:57:50.771Z",
        "created": "2024-10-14T10:48:16.594Z",
        "description": "Steps to reproduce",
        "description_filled": true,
        "due_date": null,
        "due_date_time_present": false,
        "estimate_workload": 0,
        "expires_later": false,
        "external_id": null,
        "external_user_emails": null,
        "fifo_order": null,
        "first_moved_to_in_progress_at": "2024-10-19T10:58:38.655Z",
        "fts_version": "1",
        "goals_done": 1,
        "goals_total": 1,
        "has_access_to_space": true,
        "has_blocked_children": false,
        "id": 101,
        "import_id": null,
        "key": null,
        "lane_changed_at": "2024-10-14T10:48:16.594Z",
        "lane_id": 4,
        "last_moved_at": "2024-10-25T10:37:26.375Z",
        "last_moved_to_done_at": "2024-10-25T10:37:26.375Z",
        "locked": null,
        "milestone_id": null,
        "owner_id": 7,
        "parent_checklist_ids": null,
        "parent_link_ids": null,
        "parents_count": 0,
        "parents_ids": null,
        "path_data": {
          "board": {"id": 5, "title": "Sprint"},
          "column": {"id": 3, "sort_order": 3, "title": "Done"},
          "lane": {"id": 4, "sort_order": 40.65, "title": "Default"},
          "space": {"id": 9, "title": "Demo space"}
        },
        "planned_end": null,
        "planned_start": null,
        "properties": {},
        "public": false,
        "sd_external_recipients": null,
        "sd_new_comment": false,
        "service_id": null,
        "share_id": null,
        "share_settings": null,
        "size": null,
        "size_text": null,
        "size_unit": null,
        "sort_order": 16.0009,
        "source": "app",
        "space_id": 9,
        "sprint_id": null,
        "state": 3,
        "tag_ids": null,
        "time_blocked_sum": 0,
        "time_spent_sum": 0,
        "title": "Fix login",
        "type_id": 2,
        "uid": "00000000-0000-0000-0000-000000000001",
        "updated": "2024-10-28T14:36:34.877Z",
        "updater_id": 8,
        "version": 6
      }
    ]
    """

  @Test("200 returns array of ChecklistCard")
  func listSuccess() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: Self.cardJSON)
    let client = try makeClient(transport)

    let cards = try await client.listCardsWithChecklist(checklistId: 123, onlySharedCards: false)

    #expect(cards.count == 1)
    let card = try #require(cards.first)
    #expect(card.id == 101)
    #expect(card.title == "Fix login")
    #expect(card.archived == true)
    #expect(card.state == 3)
    #expect(card.condition == 2)
    #expect(card.fifo_order == nil)
    #expect(card.sprint_id == nil)
    #expect(card.service_id == nil)
    #expect(card.has_access_to_space == true)
    #expect(card.space_id == 9)
    #expect(card.path_data?.board != nil)
    #expect(card.path_data?.subcolumn == nil)
    #expect(card.uid == "00000000-0000-0000-0000-000000000001")
    #expect(card.sort_order == 16.0009)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .get)
    #expect(recorded.request.path == "/checklists/123?only_shared_cards=false")
  }

  @Test("200 with empty body returns empty array")
  func listEmptyBody() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: ""))
    let cards = try await client.listCardsWithChecklist(checklistId: 123, onlySharedCards: true)
    #expect(cards.isEmpty)
  }

  @Test("404 throws notFound")
  func listNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    do {
      _ = try await client.listCardsWithChecklist(checklistId: 999, onlySharedCards: false)
      Issue.record("expected KaitenError.notFound, no error thrown")
    } catch let error as KaitenError {
      guard case .notFound(let resource, let id) = error else {
        Issue.record("expected KaitenError.notFound, got \(error)")
        return
      }
      #expect(resource == "checklist")
      #expect(id == 999)
    } catch {
      Issue.record("expected KaitenError, got \(error)")
    }
  }

  @Test("401 throws unauthorized")
  func listUnauthorized() async throws {
    let client = try makeClient(.returning(statusCode: 401))
    await #expect(throws: KaitenError.self) {
      _ = try await client.listCardsWithChecklist(checklistId: 1, onlySharedCards: false)
    }
  }

  @Test("400 throws unexpectedResponse")
  func listBadRequest() async throws {
    let client = try makeClient(.returning(statusCode: 400))
    await expectUnexpectedResponse(statusCode: 400) {
      _ = try await client.listCardsWithChecklist(checklistId: 1, onlySharedCards: false)
    }
  }

  @Test("403 throws unexpectedResponse")
  func listForbidden() async throws {
    let client = try makeClient(.returning(statusCode: 403))
    await expectUnexpectedResponse(statusCode: 403) {
      _ = try await client.listCardsWithChecklist(checklistId: 1, onlySharedCards: false)
    }
  }
}
