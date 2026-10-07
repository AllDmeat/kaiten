import ArgumentParser
import Foundation
import OpenAPIRuntime
import Testing

@testable import KaitenSDK
@testable import kaiten

@Suite("Space and board attributes")
struct SpaceBoardAttributesTests {
  private func makeClient(_ transport: MockClientTransport) throws -> KaitenClient {
    try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "t", transport: transport)
  }

  private func sentJSON(_ transport: MockClientTransport) async throws -> [String: Any] {
    let req = try #require(transport.recordedRequests.first)
    let data = try await Data(collecting: #require(req.body), upTo: 1024 * 1024)
    return try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
  }

  @Test("Space decodes hidden card types, null settings and live-only fields")
  func spaceDecodesNewFields() async throws {
    let json = """
      [{"id": 1, "title": "S", "hidden_card_type_uids": ["ct-a", "ct-b"],
        "allowed_card_type_ids": null, "settings": null, "work_calendar_id": null,
        "author_uid": null, "icon_color": 5, "icon_type": "emoji", "icon_value": "x",
        "import_uid": null, "key": null, "protected": false,
        "notifications_enabled": true, "role": 2,
        "role_permissions": {"space": {"read": true}}}]
      """
    let client = try makeClient(.returning(statusCode: 200, body: json))

    let space = try #require(try await client.listSpaces().first)
    #expect(space.hidden_card_type_uids == ["ct-a", "ct-b"])
    #expect(space.settings == nil)
    #expect(space.icon_color == 5)
    #expect(space.icon_type == "emoji")
    #expect(space.protected == false)
    #expect(space.notifications_enabled == true)
    #expect(space.role == 2)
    #expect(space.role_permissions != nil)
  }

  @Test("Space.allowed_card_type_ids is marked deprecated in the spec")
  func allowedCardTypeIdsDeprecated() throws {
    let spec = try String(
      contentsOf: URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("openapi/kaiten.yaml"),
      encoding: .utf8)
    let space = try #require(spec.range(of: "\n    Space:\n"))
    let field = try #require(
      spec.range(of: "allowed_card_type_ids:", range: space.upperBound..<spec.endIndex))
    let next = try #require(
      spec.range(of: "hidden_card_type_uids:", range: field.upperBound..<spec.endIndex))
    #expect(spec[field.upperBound..<next.lowerBound].contains("deprecated: true"))
  }

  @Test("Board decodes null description, placement and embedded column policies")
  func boardDecodesNewFields() async throws {
    let json = """
      {"id": 10, "title": "B", "description": null, "top": 3, "left": 4, "sort_order": 1.5,
       "uid": "b-uid", "import_uid": null, "locked": null, "settings": null,
       "cards_deprecation_message": "use cards",
       "columns": [{"id": 20, "title": "C", "policies": [{"id": 1, "name": "P"}]}]}
      """
    let client = try makeClient(.returning(statusCode: 200, body: json))

    let board = try await client.getBoard(id: 10)
    #expect(board.description == nil)
    #expect(board.top == 3)
    #expect(board.left == 4)
    #expect(board.sort_order == 1.5)
    #expect(board.uid == "b-uid")
    #expect(board.cards_deprecation_message == "use cards")
    #expect(board.columns?.first?.policies?.count == 1)
  }

  @Test("Space boards list decodes null description and live-only fields")
  func boardInSpaceDecodesNewFields() async throws {
    let json = """
      [{"id": 10, "title": "B", "description": null, "space_id": 1, "board_id": 10,
        "uid": "b-uid", "import_uid": null, "locked": null, "primary_path": true,
        "settings": {"a": 1}, "type": 1}]
      """
    let client = try makeClient(.returning(statusCode: 200, body: json))

    let board = try #require(try await client.listBoards(spaceId: 1).first)
    #expect(board.description == nil)
    #expect(board.space_id == 1)
    #expect(board.board_id == 10)
    #expect(board.primary_path == true)
    #expect(board.settings != nil)
  }

  @Test("SpaceBoard decodes cards_deprecation_message and null sidebar placement")
  func spaceBoardDeprecationMessage() async throws {
    let json =
      #"{"id": 10, "cards_deprecation_message": "use cards", "type": 5, "top": null, "left": null, "sort_order": null}"#
    let client = try makeClient(.returning(statusCode: 200, body: json))

    let board = try await client.getSpaceBoard(spaceId: 1, id: 10)
    #expect(board.cards_deprecation_message == "use cards")
    #expect(board.top == nil)
    #expect(board.sort_order == nil)
  }

  @Test("createSpace sends work_calendar_id")
  func createSpaceSendsWorkCalendar() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: #"{"id": 1}"#)
    _ = try await makeClient(transport).createSpace(title: "S", workCalendarId: "cal-1")

    let json = try await sentJSON(transport)
    #expect(json["work_calendar_id"] as? String == "cal-1")
  }

  @Test("updateSpace sends hidden_card_type_uids and settings")
  func updateSpaceSendsNewFields() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: #"{"id": 1}"#)
    let settings = try JSONDecoder().decode(
      OpenAPIObjectContainer.self, from: Data(#"{"timeline": {"planningUnits": 2}}"#.utf8))
    _ = try await makeClient(transport).updateSpace(
      id: 1, hiddenCardTypeUids: ["ct-a"], settings: settings)

    let json = try await sentJSON(transport)
    #expect(json["hidden_card_type_uids"] as? [String] == ["ct-a"])
    let sentSettings = try #require(json["settings"] as? [String: Any])
    #expect((sentSettings["timeline"] as? [String: Any])?["planningUnits"] as? Int == 2)
  }

  @Test("createBoard sends placement, columns and lanes")
  func createBoardSendsNewFields() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: #"{"id": 10}"#)
    _ = try await makeClient(transport).createBoard(
      spaceId: 1, title: "B", top: 3, left: 4,
      columns: [.init(title: "Queue", _type: 1)],
      lanes: [.init(title: "Lane")])

    let json = try await sentJSON(transport)
    #expect(json["top"] as? Int == 3)
    #expect(json["left"] as? Int == 4)
    let columns = try #require(json["columns"] as? [[String: Any]])
    #expect(columns.first?["title"] as? String == "Queue")
    #expect(columns.first?["type"] as? Int == 1)
    #expect(columns.first?["wip_limit_type"] == nil)
    let lanes = try #require(json["lanes"] as? [[String: Any]])
    #expect(lanes.first?["title"] as? String == "Lane")
  }

  @Test("updateBoard sends placement and board settings")
  func updateBoardSendsNewFields() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: #"{"id": 10}"#)
    let limits = try JSONDecoder().decode(
      OpenAPIValueContainer.self, from: Data(#"[{"limit": 1}]"#.utf8))
    let property = try JSONDecoder().decode(
      OpenAPIObjectContainer.self, from: Data(#"{"key": "id_1", "required": true}"#.utf8))
    _ = try await makeClient(transport).updateBoard(
      spaceId: 1, id: 10, top: 3, left: 4, type: 5, cellWipLimits: limits,
      moveParentsToDone: true, hideDonePolicies: false, hideDonePoliciesInDoneColumn: true,
      moveFromSpaceId: 2, cardProperties: [property])

    let json = try await sentJSON(transport)
    #expect(json["top"] as? Int == 3)
    #expect(json["left"] as? Int == 4)
    #expect(json["type"] as? Int == 5)
    #expect((json["cell_wip_limits"] as? [[String: Any]])?.first?["limit"] as? Int == 1)
    #expect(json["move_parents_to_done"] as? Bool == true)
    #expect(json["hide_done_policies"] as? Bool == false)
    #expect(json["hide_done_policies_in_done_column"] as? Bool == true)
    #expect(json["move_from_space_id"] as? Int == 2)
    #expect((json["card_properties"] as? [[String: Any]])?.first?["key"] as? String == "id_1")
  }

  @Test("create-board rejects empty --columns and --lanes before any request")
  func createBoardRejectsEmptyArrays() async throws {
    for flag in ["--columns", "--lanes"] {
      let command = try CreateBoard.parse(["--space-id", "1", "--title", "B", flag, "[ ]"])
      await #expect(throws: ValidationError.self) { try await command.run() }
    }
  }

  @Test("update-board rejects malformed --cell-wip-limits before any request")
  func updateBoardRejectsMalformedJSON() async throws {
    let command = try UpdateBoard.parse(["--space-id", "1", "--id", "2", "--cell-wip-limits", "{"])
    await #expect(throws: ValidationError.self) { try await command.run() }
  }
}
