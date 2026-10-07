import Foundation
import HTTPTypes
import OpenAPIRuntime
import Synchronization
import Testing

@testable import KaitenSDK
@testable import kaiten

@Suite("Cards search v2, broken_api and card fields")
struct CardsSearchTests {

  private func makeClient(_ transport: MockClientTransport) throws -> KaitenClient {
    try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)
  }

  private func response(_ body: String) -> (HTTPResponse, HTTPBody?) {
    var headerFields = HTTPFields()
    headerFields[.contentType] = "application/json"
    return (HTTPResponse(status: .ok, headerFields: headerFields), HTTPBody(body))
  }

  private func requestBodyJSON(from transport: MockClientTransport) async throws -> [String: Any] {
    let req = try #require(transport.recordedRequests.first)
    let bodyData = try await Data(collecting: #require(req.body), upTo: 1024 * 1024)
    return try #require(try JSONSerialization.jsonObject(with: bodyData) as? [String: Any])
  }

  /// A sanitized card row carrying the fields this change adds: the documented
  /// `ignore_planned_dates_recalculation` and `path_data`, the single-card block fields,
  /// live-only fields, and an embedded child with relation fields, a `null`
  /// `counters_recalculated_at` and a card type whose `company_id` is `null`.
  private static let cardJSON = """
    {
      "id": 1,
      "title": "Card A",
      "ignore_planned_dates_recalculation": true,
      "path_data": {"space": {"id": 2, "title": "Space"}, "board": {"id": 3}},
      "counters_recalculated_at": "2026-01-01T00:00:00.000Z",
      "properties": {
        "id_10": [11, 12],
        "id_20": ["user-uid-1"],
        "id_30": [{"id": 13, "full_name": "Jane Roe"}]
      },
      "type": {"id": 4, "name": "Task", "company_id": null},
      "blocked": true,
      "blockers": [
        {
          "id": 5, "uid": "blocker-uid-1", "reason": "Waiting", "card_id": 1, "blocker_id": 6,
          "blocker_card_id": null, "blocker_card_title": null, "released": false,
          "released_by_id": null, "due_date": null, "due_date_time_present": false,
          "created": "2026-01-01T00:00:00.000Z", "updated": "2026-01-01T00:00:00.000Z",
          "fts_version": "1"
        }
      ],
      "blocked_at": "2026-01-02T00:00:00.000Z",
      "blocker_id": 6,
      "blocker": {"id": 6, "full_name": "John Doe"},
      "block_reason": "Waiting",
      "cardRole": 2,
      "email": "card-1@example.com",
      "key": null,
      "locked": null,
      "tag_ids": [7],
      "in_workflow": false,
      "card_permissions": {"read": true, "update": false},
      "fts_version": "1",
      "card_cp_value_fts_version": "2",
      "card_tag_fts_version": "3",
      "children": [
        {
          "id": 8,
          "title": "Child",
          "card_id": 1,
          "depends_on_card_id": 8,
          "has_access_to_space": true,
          "space_id": null,
          "path_data": {"board": {"id": 3}},
          "counters_recalculated_at": null,
          "type": {"id": 4, "company_id": null}
        }
      ]
    }
    """

  // MARK: - GET /cards (version 1)

  @Test("listCards sends project_ids, filter and broken_api, and no version")
  func listCardsSendsNewFilters() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: "[]")
    let client = try makeClient(transport)

    _ = try await client.listCards(
      filter: CardFilter(
        projectIds: "proj-1,proj-2", filter: "eyJrZXkiOiJhbmQifQ==", brokenApi: false)
    )

    let path = try #require(transport.recordedRequests.first?.request.path)
    #expect(path.contains("project_ids=proj-1%2Cproj-2"))
    #expect(path.contains("filter=eyJrZXkiOiJhbmQifQ%3D%3D"))
    #expect(path.contains("broken_api=false"))
    #expect(!path.contains("version="))
  }

  @Test("listCards decodes the new card fields and every user-property representation")
  func listCardsDecodesNewFields() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: "[\(Self.cardJSON)]")
    let client = try makeClient(transport)

    let card = try #require(try await client.listCards().items.first)

    #expect(card.ignore_planned_dates_recalculation == true)
    #expect(card.path_data?.additionalProperties.value["space"] != nil)
    #expect(card._type?.company_id == nil)
    #expect(card.blockers?.first?.reason == "Waiting")
    #expect(card.blocked_at == "2026-01-02T00:00:00.000Z")
    #expect(card.blocker_id == 6)
    #expect(card.blocker?.full_name == "John Doe")
    #expect(card.block_reason == "Waiting")
    #expect(card.cardRole == 2)
    #expect(card.email == "card-1@example.com")
    #expect(card.tag_ids == [7])
    #expect(card.in_workflow == false)
    #expect(card.card_permissions?.additionalProperties.value["read"] != nil)
    #expect(card.card_cp_value_fts_version == "2")
    #expect(card.card_tag_fts_version == "3")

    let properties = try #require(card.properties?.additionalProperties.value)
    #expect(properties["id_10"] as? [Any] != nil, "integer user ids")
    #expect(properties["id_20"] as? [Any] != nil, "user UID strings")
    #expect(properties["id_30"] as? [Any] != nil, "user objects")

    let child = try #require(card.children?.first)
    #expect(child.card_id == 1)
    #expect(child.depends_on_card_id == 8)
    #expect(child.has_access_to_space == true)
    #expect(child.space_id == nil)
    #expect(child.path_data != nil)
    #expect(child.counters_recalculated_at == nil)
    #expect(child._type?.company_id == nil)
  }

  @Test("listCards rejects a version=2 shaped response")
  func listCardsRejectsSearchShape() async throws {
    let transport = MockClientTransport.returning(
      statusCode: 200, body: #"{"result": [], "position": "cursor-1"}"#)
    let client = try makeClient(transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.listCards()
    }
  }

  // MARK: - GET /cards (version 2)

  @Test("searchCards sends version=2 and the cursor, and never an offset")
  func searchCardsSendsQuery() async throws {
    let transport = MockClientTransport.returning(
      statusCode: 200, body: #"{"result": [], "position": "cursor-2"}"#)
    let client = try makeClient(transport)

    _ = try await client.searchCards(
      boardId: 3, startPosition: "cursor-1", includeSearchPreview: true, limit: 20,
      filter: CardFilter(query: "login", searchFields: "description"))

    let path = try #require(transport.recordedRequests.first?.request.path)
    #expect(path.hasPrefix("/cards?"))
    #expect(path.contains("version=2"))
    #expect(path.contains("start_position=cursor-1"))
    #expect(path.contains("include_search_preview=true"))
    #expect(path.contains("limit=20"))
    #expect(path.contains("board_id=3"))
    #expect(path.contains("query=login"))
    #expect(path.contains("search_fields=description"))
    #expect(!path.contains("offset="))
  }

  @Test("searchCards decodes result, position, preview and mQueries")
  func searchCardsDecodes() async throws {
    let body = """
      {
        "result": [
          {
            "id": 1,
            "title": "Card A",
            "preview": {"preview_text": "a snippet", "preview_source": "description"},
            "mQueries": [["login"]],
            "path_data": {"board": {"id": 3}}
          }
        ],
        "position": "cursor-2"
      }
      """
    let client = try makeClient(MockClientTransport.returning(statusCode: 200, body: body))

    let response = try await client.searchCards(filter: CardFilter(query: "login"))

    #expect(response.position == "cursor-2")
    let card = try #require(response.result?.first)
    #expect(card.id == 1)
    #expect(card.preview?.additionalProperties.value["preview_text"] != nil)
    #expect(card.mQueries?.count == 1)
  }

  @Test("searchCards rejects a version=1 shaped response")
  func searchCardsRejectsArray() async throws {
    let client = try makeClient(MockClientTransport.returning(statusCode: 200, body: "[]"))

    await #expect(throws: KaitenError.self) {
      _ = try await client.searchCards()
    }
  }

  @Test("searchCards validates limit before any request")
  func searchCardsValidatesLimit() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: "[]")
    let client = try makeClient(transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.searchCards(limit: 101)
    }
    #expect(transport.recordedRequests.isEmpty)
  }

  @Test("searchAllCards follows the cursor and stops on an empty page that still has a position")
  func searchAllCardsStopsOnEmptyPage() async throws {
    let transport = MockClientTransport { request, _, _, _ in
      let path = request.path ?? ""
      if path.contains("start_position=cursor-2") {
        return self.response(#"{"result": [], "position": "cursor-3"}"#)
      }
      if path.contains("start_position=cursor-1") {
        return self.response(#"{"result": [{"id": 3}], "position": "cursor-2"}"#)
      }
      return self.response(#"{"result": [{"id": 1}, {"id": 2}], "position": "cursor-1"}"#)
    }
    let client = try makeClient(transport)

    var ids: [Int] = []
    for try await card in client.searchAllCards(pageSize: 2) {
      ids.append(try #require(card.id))
    }

    #expect(ids == [1, 2, 3])
    #expect(transport.recordedRequests.count == 3)
    #expect(transport.recordedRequests.allSatisfy { !($0.request.path ?? "").contains("offset=") })
  }

  @Test("searchAllCards yields each card once when pages overlap")
  func searchAllCardsDeduplicatesOverlap() async throws {
    let transport = MockClientTransport { request, _, _, _ in
      let path = request.path ?? ""
      if path.contains("start_position=cursor-2") {
        return self.response(#"{"result": [], "position": "cursor-3"}"#)
      }
      if path.contains("start_position=cursor-1") {
        return self.response(#"{"result": [{"id": 2}, {"id": 3}], "position": "cursor-2"}"#)
      }
      return self.response(#"{"result": [{"id": 1}, {"id": 2}], "position": "cursor-1"}"#)
    }
    let client = try makeClient(transport)

    var ids: [Int] = []
    for try await card in client.searchAllCards(pageSize: 2) {
      ids.append(try #require(card.id))
    }

    #expect(ids == [1, 2, 3])
  }

  @Test("searchAllCards stops when the API repeats a position, even with new cards")
  func searchAllCardsStopsOnRepeatedPosition() async throws {
    let transport = MockClientTransport { request, _, _, _ in
      if (request.path ?? "").contains("start_position=cursor-1") {
        return self.response(#"{"result": [{"id": 3}], "position": "cursor-1"}"#)
      }
      return self.response(#"{"result": [{"id": 1}, {"id": 2}], "position": "cursor-1"}"#)
    }
    let client = try makeClient(transport)

    var ids: [Int] = []
    for try await card in client.searchAllCards(pageSize: 2) {
      ids.append(try #require(card.id))
    }

    #expect(ids == [1, 2, 3])
    #expect(transport.recordedRequests.count == 2)
  }

  @Test("searchAllCards keeps going past a fully duplicate page")
  func searchAllCardsContinuesPastDuplicatePage() async throws {
    let transport = MockClientTransport { request, _, _, _ in
      let path = request.path ?? ""
      if path.contains("start_position=cursor-3") {
        return self.response(#"{"result": [], "position": "cursor-4"}"#)
      }
      if path.contains("start_position=cursor-2") {
        return self.response(#"{"result": [{"id": 3}], "position": "cursor-3"}"#)
      }
      if path.contains("start_position=cursor-1") {
        return self.response(#"{"result": [{"id": 1}, {"id": 2}], "position": "cursor-2"}"#)
      }
      return self.response(#"{"result": [{"id": 1}, {"id": 2}], "position": "cursor-1"}"#)
    }
    let client = try makeClient(transport)

    var ids: [Int] = []
    for try await card in client.searchAllCards(pageSize: 2) {
      ids.append(try #require(card.id))
    }

    #expect(ids == [1, 2, 3])
    #expect(transport.recordedRequests.count == 4)
  }

  @Test("searchAllCards stops after three consecutive pages without a new card")
  func searchAllCardsStopsAfterThreeDuplicatePages() async throws {
    let counter = Mutex(0)
    let transport = MockClientTransport { _, _, _, _ in
      let page = counter.withLock { value -> Int in
        value += 1
        return value
      }
      return self.response(#"{"result": [{"id": 1}], "position": "cursor-\#(page)"}"#)
    }
    let client = try makeClient(transport)

    var ids: [Int] = []
    for try await card in client.searchAllCards(pageSize: 1) {
      ids.append(try #require(card.id))
    }

    #expect(ids == [1])
    #expect(transport.recordedRequests.count == 4)
  }

  @Test("searchAllCards stops when a page carries no position")
  func searchAllCardsStopsWithoutPosition() async throws {
    let transport = MockClientTransport { _, _, _, _ in
      self.response(#"{"result": [{"id": 1}]}"#)
    }
    let client = try makeClient(transport)

    var count = 0
    for try await _ in client.searchAllCards() {
      count += 1
    }

    #expect(count == 1)
    #expect(transport.recordedRequests.count == 1)
  }

  // MARK: - broken_api on single-card endpoints

  @Test("getCard sends broken_api when set and omits it otherwise")
  func getCardBrokenApi() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: Self.cardJSON)
    let client = try makeClient(transport)

    _ = try await client.getCard(id: 1, brokenApi: true)
    _ = try await client.getCard(id: 1)

    let paths = transport.recordedRequests.map { $0.request.path ?? "" }
    #expect(paths == ["/cards/1?broken_api=true", "/cards/1"])
  }

  @Test("listCardChildren sends broken_api")
  func listCardChildrenBrokenApi() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: "[]")
    let client = try makeClient(transport)

    _ = try await client.listCardChildren(cardId: 1, brokenApi: false)

    #expect(transport.recordedRequests.first?.request.path == "/cards/1/children?broken_api=false")
  }

  @Test("allCardChildren sends broken_api with every page")
  func allCardChildrenBrokenApi() async throws {
    let transport = MockClientTransport { request, _, _, _ in
      let path = request.path ?? ""
      return self.response(path.contains("offset=0") ? #"[{"id": 1}, {"id": 2}]"# : "[]")
    }
    let client = try makeClient(transport)

    var count = 0
    for try await _ in client.allCardChildren(cardId: 1, brokenApi: true, pageSize: 2) {
      count += 1
    }

    #expect(count == 2)
    #expect(transport.recordedRequests.count == 2)
    #expect(
      transport.recordedRequests.allSatisfy {
        ($0.request.path ?? "").contains("broken_api=true")
      })
  }

  // MARK: - Request attributes

  @Test("createCard sends service_id")
  func createCardSendsServiceId() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: Self.cardJSON)
    let client = try makeClient(transport)

    var options = CardCreateOptions(title: "Card A", boardId: 3)
    options.serviceId = 9
    _ = try await client.createCard(options)

    let body = try await requestBodyJSON(from: transport)
    #expect(body["service_id"] as? Int == 9)
  }

  @Test("updateCard sends ignore_planned_dates_recalculation")
  func updateCardSendsIgnorePlannedDates() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: Self.cardJSON)
    let client = try makeClient(transport)

    var options = CardUpdateOptions()
    options.ignorePlannedDatesRecalculation = true
    _ = try await client.updateCard(id: 1, options)

    let body = try await requestBodyJSON(from: transport)
    #expect(body["ignore_planned_dates_recalculation"] as? Bool == true)
  }

  // MARK: - CLI

  @Test("search-cards takes the shared filters and has no offset")
  func searchCardsCommandParses() throws {
    let command = try SearchCards.parse([
      "--start-position", "cursor-1", "--project-ids", "proj-1", "--broken-api", "true",
    ])
    #expect(command.startPosition == "cursor-1")
    let filter = try command.filters.makeFilter()
    #expect(filter.projectIds == "proj-1")
    #expect(filter.brokenApi == true)

    #expect(throws: (any Error).self) {
      _ = try SearchCards.parse(["--offset", "5"])
    }
  }
}
