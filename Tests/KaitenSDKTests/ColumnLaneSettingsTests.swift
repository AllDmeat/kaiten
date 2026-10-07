import ArgumentParser
import Foundation
import Testing

@testable import KaitenSDK
@testable import kaiten

@Suite("Column and lane settings")
struct ColumnLaneSettingsTests {
  private let columnJSON = """
    {"id": 100, "title": "To Do", "board_id": 10}
    """
  private let laneJSON = """
    {"id": 200, "title": "Lane", "board_id": 10}
    """

  private func makeClient(_ transport: MockClientTransport) throws -> KaitenClient {
    try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "t", transport: transport)
  }

  private func sentBody(_ transport: MockClientTransport) async throws -> [String: Any] {
    let req = try #require(transport.recordedRequests.first)
    let data = try await Data(collecting: #require(req.body), upTo: 1024 * 1024)
    return try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
  }

  @Test("createColumn sends stale-card, archive, hide, rules and external id settings")
  func createColumnBody() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: columnJSON)
    _ = try await makeClient(transport).createColumn(
      boardId: 10, title: "Done", type: .done,
      lastMovedWarningAfterDays: 3, lastMovedWarningAfterHours: 4,
      lastMovedWarningAfterMinutes: 5, archiveAfterDays: 30, cardHideAfterDays: 14,
      rules: 3, externalId: "ext-1")

    let json = try await sentBody(transport)
    #expect(json["last_moved_warning_after_days"] as? Int == 3)
    #expect(json["last_moved_warning_after_hours"] as? Int == 4)
    #expect(json["last_moved_warning_after_minutes"] as? Int == 5)
    #expect(json["archive_after_days"] as? Int == 30)
    #expect(json["card_hide_after_days"] as? Int == 14)
    #expect(json["rules"] as? Int == 3)
    #expect(json["external_id"] as? String == "ext-1")
    #expect(json["prev_column_id"] == nil)
  }

  @Test("updateColumn sends reordering and pause_sla, omits unset fields")
  func updateColumnBody() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: columnJSON)
    _ = try await makeClient(transport).updateColumn(
      boardId: 10, id: 100, prevColumnId: 7, nextColumnId: 8, pauseSla: true)

    let json = try await sentBody(transport)
    #expect(json["prev_column_id"] as? Int == 7)
    #expect(json["next_column_id"] as? Int == 8)
    #expect(json["pause_sla"] as? Bool == true)
    #expect(json["title"] == nil)
    #expect(json["card_hide_after_days"] == nil)
  }

  @Test("updateColumn sends explicit null for cleared nullable integers")
  func updateColumnExplicitNull() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: columnJSON)
    _ = try await makeClient(transport).updateColumn(
      boardId: 10, id: 100, cardHideAfterDays: .some(nil),
      prevColumnId: .some(nil), nextColumnId: .some(nil))

    let json = try await sentBody(transport)
    for key in ["card_hide_after_days", "prev_column_id", "next_column_id"] {
      #expect(json[key] is NSNull, "\(key) should be JSON null")
    }
  }

  @Test("updateColumn sends values and omits absent nullable integers")
  func updateColumnNullableValues() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: columnJSON)
    _ = try await makeClient(transport).updateColumn(
      boardId: 10, id: 100, cardHideAfterDays: 14, nextColumnId: 8)

    let json = try await sentBody(transport)
    #expect(json["next_column_id"] as? Int == 8)
    #expect(json["card_hide_after_days"] as? Int == 14)
    #expect(json.keys.contains("prev_column_id") == false)
    #expect(json.keys.contains("wip_limit") == false)
  }

  @Test("updateSubcolumn sends explicit null to turn card hiding off")
  func updateSubcolumnExplicitNull() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: columnJSON)
    _ = try await makeClient(transport).updateSubcolumn(
      columnId: 100, id: 101, cardHideAfterDays: .some(nil))

    let json = try await sentBody(transport)
    #expect(json["card_hide_after_days"] is NSNull)
    #expect(json.keys.contains("prev_column_id") == false)
  }

  @Test("ExplicitNullInteger encodes integers without a fractional part and null as null")
  func explicitNullIntegerEncoding() throws {
    let encoder = JSONEncoder()
    #expect(
      String(decoding: try encoder.encode(ExplicitNullInteger.value(14)), as: UTF8.self) == "14")
    #expect(String(decoding: try encoder.encode(ExplicitNullInteger.null), as: UTF8.self) == "null")
    #expect(try JSONDecoder().decode(ExplicitNullInteger.self, from: Data("null".utf8)) == .null)
    #expect(try JSONDecoder().decode(ExplicitNullInteger.self, from: Data("7".utf8)) == .value(7))
  }

  @Test("createSubcolumn sends column settings and no WIP limit")
  func createSubcolumnBody() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: columnJSON)
    _ = try await makeClient(transport).createSubcolumn(
      columnId: 100, title: "Sub", colCount: 2, lastMovedWarningAfterDays: 1, rules: 2)

    let json = try await sentBody(transport)
    #expect(json["col_count"] as? Int == 2)
    #expect(json["last_moved_warning_after_days"] as? Int == 1)
    #expect(json["rules"] as? Int == 2)
    #expect(json["wip_limit"] == nil)
    #expect(json["wip_limit_type"] == nil)
  }

  @Test("updateSubcolumn sends reordering, pause_sla and settings")
  func updateSubcolumnBody() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: columnJSON)
    _ = try await makeClient(transport).updateSubcolumn(
      columnId: 100, id: 101, archiveAfterDays: 9, nextColumnId: 102, pauseSla: false)

    let json = try await sentBody(transport)
    #expect(json["archive_after_days"] as? Int == 9)
    #expect(json["next_column_id"] as? Int == 102)
    #expect(json["pause_sla"] as? Bool == false)
  }

  @Test("createLane and updateLane send stale-card warning settings")
  func laneBodies() async throws {
    let create = MockClientTransport.returning(statusCode: 200, body: laneJSON)
    _ = try await makeClient(create).createLane(
      boardId: 10, title: "Lane", lastMovedWarningAfterDays: 2, lastMovedWarningAfterHours: 6,
      lastMovedWarningAfterMinutes: 30)
    let created = try await sentBody(create)
    #expect(created["last_moved_warning_after_days"] as? Int == 2)
    #expect(created["last_moved_warning_after_hours"] as? Int == 6)
    #expect(created["last_moved_warning_after_minutes"] as? Int == 30)

    let update = MockClientTransport.returning(statusCode: 200, body: laneJSON)
    _ = try await makeClient(update).updateLane(
      boardId: 10, id: 200, condition: .live, lastMovedWarningAfterMinutes: 15)
    let updated = try await sentBody(update)
    #expect(updated["last_moved_warning_after_minutes"] as? Int == 15)
    #expect(updated["condition"] as? Int == 1)
    #expect(updated["last_moved_warning_after_days"] == nil)
  }

  @Test("Column decodes nested subcolumns and the deprecated months_to_hide_cards")
  func columnDecodesSubcolumns() async throws {
    let json = """
      [{"id": 100, "title": "Doing", "board_id": 10, "pause_sla": true,
        "months_to_hide_cards": null, "card_hide_after_days": null, "rules": 2,
        "subcolumns": [{"id": 101, "title": "Review", "board_id": 10, "column_id": 100,
                        "pause_sla": false, "wip_limit_type": 1}]},
       {"id": 102, "title": "Done", "board_id": 10, "archive_after_days": 30}]
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let columns = try await makeClient(transport).getBoardColumns(boardId: 10)

    #expect(columns[0].pause_sla == true)
    #expect(columns[0].rules == 2)
    let sub = try #require(columns[0].subcolumns?.first)
    #expect(sub.id == 101)
    #expect(sub.column_id == 100)
    #expect(sub.pause_sla == false)
    #expect(columns[1].subcolumns == nil)
    #expect(columns[1].archive_after_days == 30)
  }

  @Test("Column.months_to_hide_cards is marked deprecated in the spec")
  func monthsToHideCardsDeprecated() throws {
    let spec = try String(
      contentsOf: URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("openapi/kaiten.yaml"),
      encoding: .utf8)
    let column = try #require(spec.range(of: "\n    Column:\n"))
    let field = try #require(
      spec.range(of: "months_to_hide_cards:", range: column.upperBound..<spec.endIndex))
    let next = try #require(
      spec.range(of: "card_hide_after_days:", range: field.upperBound..<spec.endIndex))
    #expect(spec[field.upperBound..<next.lowerBound].contains("deprecated: true"))
  }

  @Test("CLI collapses nested subcolumns to ids unless expanded")
  func subcolumnsOutput() throws {
    let column = try JSONDecoder().decode(
      Components.Schemas.Column.self,
      from: Data(#"{"id": 100, "subcolumns": [{"id": 101}, {"id": 102}]}"#.utf8))
    #expect(try renderJSON(column) == #"{"id":100,"subcolumns":[101,102]}"#)
    #expect(
      try renderJSON(column, expand: ["subcolumns"])
        == #"{"id":100,"subcolumns":[{"id":101},{"id":102}]}"#)
  }

  @Test("update-column parses settings and reordering options")
  func updateColumnCLIOptions() throws {
    let command = try UpdateColumn.parse([
      "--board-id", "10", "--id", "100", "--card-hide-after-days", "14", "--rules", "1",
      "--external-id", "ext-1", "--prev-column-id", "7", "--pause-sla", "true",
    ])
    #expect(command.update.cardHideAfterDays == "14")
    #expect(command.settings.rules == 1)
    #expect(command.settings.externalId == "ext-1")
    #expect(command.update.prevColumnId == "7")
    #expect(command.update.pauseSla == true)
  }

  @Test("nullable integer options map absent, empty and numeric input")
  func parseNullableIntOption() throws {
    #expect(try parseNullableInt(nil, option: "--card-hide-after-days") == .none)
    #expect(try parseNullableInt("", option: "--card-hide-after-days") == .some(nil))
    #expect(try parseNullableInt("5", option: "--card-hide-after-days") == .some(5))
    #expect(throws: ValidationError.self) {
      _ = try parseNullableInt("five", option: "--card-hide-after-days")
    }
  }

  @Test("update-lane parses stale-card warning options")
  func updateLaneCLIOptions() throws {
    let command = try UpdateLane.parse([
      "--board-id", "10", "--id", "200", "--last-moved-warning-after-hours", "6",
    ])
    #expect(command.lastMovedWarningAfterHours == 6)
  }

  @Test("updateColumn and updateLane send a WIP limit value")
  func wipLimitValue() async throws {
    let columns = MockClientTransport.returning(statusCode: 200, body: columnJSON)
    _ = try await makeClient(columns).updateColumn(boardId: 10, id: 100, wipLimit: 5)
    #expect(try await sentBody(columns)["wip_limit"] as? Int == 5)

    let lanes = MockClientTransport.returning(statusCode: 200, body: laneJSON)
    _ = try await makeClient(lanes).updateLane(boardId: 10, id: 200, wipLimit: 5)
    #expect(try await sentBody(lanes)["wip_limit"] as? Int == 5)
  }

  @Test("an absent WIP limit, including an Int? variable holding nil, is not sent")
  func wipLimitAbsent() async throws {
    let unchanged: Int? = nil
    let columns = MockClientTransport.returning(statusCode: 200, body: columnJSON)
    _ = try await makeClient(columns).updateColumn(
      boardId: 10, id: 100, title: "T", wipLimit: unchanged)
    let columnJSON = try await sentBody(columns)
    #expect(columnJSON["title"] as? String == "T")
    #expect(columnJSON.keys.contains("wip_limit") == false)

    let lanes = MockClientTransport.returning(statusCode: 200, body: laneJSON)
    _ = try await makeClient(lanes).updateLane(
      boardId: 10, id: 200, title: "T", wipLimit: unchanged)
    #expect(try await sentBody(lanes).keys.contains("wip_limit") == false)
  }

  @Test("clearWipLimit sends wip_limit null and keeps the other fields")
  func wipLimitClear() async throws {
    let columns = MockClientTransport.returning(statusCode: 200, body: columnJSON)
    _ = try await makeClient(columns).updateColumn(
      boardId: 10, id: 100, title: "T", clearWipLimit: true, wipLimitType: .cardCount)
    let columnJSON = try await sentBody(columns)
    #expect(columnJSON["wip_limit"] is NSNull)
    let request = try #require(columns.recordedRequests.first)
    let sent = try await Data(collecting: #require(request.body), upTo: 1024 * 1024)
    #expect(request.request.headerFields[.contentLength] == String(sent.count))
    #expect(columnJSON["title"] as? String == "T")
    #expect(columnJSON["wip_limit_type"] as? Int == 1)

    let lanes = MockClientTransport.returning(statusCode: 200, body: laneJSON)
    _ = try await makeClient(lanes).updateLane(
      boardId: 10, id: 200, clearWipLimit: true)
    #expect(try await sentBody(lanes)["wip_limit"] is NSNull)
  }

  @Test("the explicit null does not leak into later requests")
  func wipLimitClearDoesNotLeak() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: columnJSON)
    let client = try makeClient(transport)
    _ = try await client.updateColumn(boardId: 10, id: 100, clearWipLimit: true)
    _ = try await client.updateColumn(boardId: 10, id: 100, title: "T")
    let req = try #require(transport.recordedRequests.last)
    let data = try await Data(collecting: #require(req.body), upTo: 1024 * 1024)
    let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    #expect(json.keys.contains("wip_limit") == false)
  }

  @Test("wipLimit together with clearWipLimit fails before any request")
  func wipLimitConflict() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: columnJSON)
    let client = try makeClient(transport)
    let columnError = await #expect(throws: KaitenError.self) {
      _ = try await client.updateColumn(boardId: 10, id: 100, wipLimit: 3, clearWipLimit: true)
    }
    let laneError = await #expect(throws: KaitenError.self) {
      _ = try await client.updateLane(boardId: 10, id: 200, wipLimit: 3, clearWipLimit: true)
    }
    for error in [columnError, laneError] {
      guard case .conflictingArguments("wipLimit", "clearWipLimit") = error else {
        Issue.record("unexpected error: \(String(describing: error))")
        continue
      }
    }
    #expect(transport.recordedRequests.isEmpty)
  }

  @Test("update-column and update-lane take an empty --wip-limit and reject other text")
  func wipLimitCLIOption() async throws {
    #expect(
      try UpdateColumn.parse(["--board-id", "10", "--id", "100", "--wip-limit", ""]).wipLimit
        == "")
    #expect(
      try UpdateLane.parse(["--board-id", "10", "--id", "200", "--wip-limit", "4"]).wipLimit
        == "4")
    let invalid = try UpdateLane.parse(["--board-id", "10", "--id", "200", "--wip-limit", "x"])
    await #expect(throws: ValidationError.self) { try await invalid.run() }
    #expect(try UpdateLane.parse(["--board-id", "10", "--id", "200"]).wipLimit == nil)
  }
}
