import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("Space Boards")
struct SpaceBoardsTests {

  private func makeClient(_ transport: MockClientTransport) throws -> KaitenClient {
    try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)
  }

  // MARK: - getSpaceBoard

  /// Fixture is a sanitized live response: the endpoint returns a single object with the
  /// board's space placement (`top`, `left`, `sort_order`, `space_id`) next to the full
  /// board contents, although the documentation declares an array of objects.
  @Test("200 returns SpaceBoard with space placement")
  func getSpaceBoardSuccess() async throws {
    let json = """
      {
        "created": "2024-10-03T13:33:57.237Z",
        "updated": "2026-07-27T08:35:48.355Z",
        "id": 10,
        "title": "Sprint",
        "cell_wip_limits": null,
        "external_id": null,
        "default_card_type_id": 4,
        "description": "Board guide",
        "email_key": "abc123",
        "move_parents_to_done": false,
        "default_tags": null,
        "first_image_is_cover": false,
        "reset_lane_spent_time": false,
        "backward_moves_enabled": false,
        "hide_done_policies": false,
        "hide_done_policies_in_done_column": false,
        "automove_cards": false,
        "auto_assign_enabled": false,
        "card_properties": [
          {"key": "size", "laneIds": [], "required": true, "columnIds": [], "cardTypeIds": []}
        ],
        "uid": "board-uid-1",
        "import_uid": null,
        "locked": null,
        "settings": {
          "cardsSumUnit": null,
          "cardsSumPropertyUid": null,
          "showCardsSumInLanes": true,
          "showCardsSumInColumns": true
        },
        "columns": [
          {
            "id": 31, "uid": "col-uid-1", "title": "QA", "sort_order": 2.5, "col_count": 1,
            "type": 2, "board_id": 10, "column_id": null, "external_id": null, "rules": 0,
            "pause_sla": false,
            "subcolumns": [
              {"id": 32, "uid": "col-uid-2", "title": "Testing", "sort_order": 3.04,
               "col_count": 1, "type": 2, "board_id": 10, "column_id": 31,
               "external_id": null, "rules": 0, "pause_sla": false}
            ]
          }
        ],
        "lanes": [
          {"id": 21, "uid": "lane-uid-1", "title": "Goal 1", "sort_order": 2.66,
           "board_id": 10, "condition": 2, "external_id": null, "default_card_type_id": null}
        ],
        "cards": [
          {
            "id": 41, "uid": "card-uid-1", "created": "2026-07-22T11:19:55.166Z",
            "updated": "2026-07-30T21:45:05.890Z", "archived": false, "title": "Fix statuses",
            "asap": false, "due_date": null, "sort_order": 0.4, "fifo_order": null,
            "state": 3, "condition": 1, "expires_later": false, "parents_count": 2,
            "children_count": 0, "children_done": 0, "has_blocked_children": false,
            "goals_total": 0, "goals_done": 0, "time_spent_sum": 0, "time_blocked_sum": 0,
            "children_number_properties_sum": null, "parents_ids": [42, 43],
            "children_ids": null, "blocking_card": false, "blocked": false, "size": 1,
            "size_unit": null, "size_text": "1", "due_date_time_present": false,
            "board_id": 10, "column_id": 31, "lane_id": 21, "owner_id": 7, "type_id": 4,
            "version": 10, "updater_id": 7, "completed_on_time": null, "completed_at": null,
            "sprint_id": 5, "external_id": null, "comments_total": 1,
            "properties": {"id_1": [2]}
          }
        ],
        "space_id": 1,
        "board_id": 10,
        "top": 0,
        "left": 312,
        "sort_order": 1308.77,
        "primary_path": true
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let board = try await client.getSpaceBoard(spaceId: 1, id: 10)
    #expect(board.id == 10)
    #expect(board.title == "Sprint")
    #expect(board.uid == "board-uid-1")
    #expect(board.space_id == 1)
    #expect(board.board_id == 10)
    #expect(board.top == 0)
    #expect(board.left == 312)
    #expect(board.sort_order == 1308.77)
    #expect(board.primary_path == true)
    #expect(board.columns?.count == 1)
    #expect(board.lanes?.count == 1)
    #expect(board.cards?.count == 1)
    #expect(board.cards?.first?.id == 41)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .get)
    #expect(recorded.request.path == "/spaces/1/boards/10")
  }

  /// The documentation declares `description` as a non-nullable string; live boards
  /// without a description return JSON null there, along with null `settings`.
  @Test("null description and settings decode to nil")
  func getSpaceBoardNullableFields() async throws {
    let json = """
      {
        "id": 11,
        "title": "Backlog",
        "description": null,
        "settings": null,
        "card_properties": null,
        "import_uid": null,
        "locked": null,
        "space_id": 1,
        "board_id": 11,
        "top": 0,
        "left": 0,
        "sort_order": 1.0,
        "primary_path": false
      }
      """
    let client = try makeClient(.returning(statusCode: 200, body: json))

    let board = try await client.getSpaceBoard(spaceId: 1, id: 11)
    #expect(board.id == 11)
    #expect(board.description == nil)
    #expect(board.settings == nil)
    #expect(board.primary_path == false)
  }

  @Test("404 throws notFound")
  func getSpaceBoardNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    do {
      _ = try await client.getSpaceBoard(spaceId: 1, id: 999)
      Issue.record("expected KaitenError.notFound, no error thrown")
    } catch let error as KaitenError {
      guard case .notFound = error else {
        Issue.record("expected KaitenError.notFound, got \(error)")
        return
      }
    } catch {
      Issue.record("expected KaitenError, got \(error)")
    }
  }

  @Test("401 throws unauthorized")
  func getSpaceBoardUnauthorized() async throws {
    let client = try makeClient(.returning(statusCode: 401))
    await #expect(throws: KaitenError.self) {
      _ = try await client.getSpaceBoard(spaceId: 1, id: 10)
    }
  }
}
