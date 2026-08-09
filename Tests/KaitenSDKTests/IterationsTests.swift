import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("Iterations")
struct IterationsTests {

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

  /// Sanitized live response of `GET /spaces/{space_uid}/iterations?with_data=cards`:
  /// a closed iteration with full statistics and a card record, and an active
  /// iteration whose statistics carry only `committed`.
  private static let listFixture = """
    [{
      "created": "2026-07-28T06:28:02.762Z",
      "updated": "2026-07-28T06:28:28.587Z",
      "id": "iter-uid-1",
      "space_uid": "space-uid-1",
      "title": "Sprint 2",
      "goal": null,
      "status": "closed",
      "creator_uid": "user-uid-1",
      "updater_uid": "user-uid-1",
      "start_date": "2026-07-28T06:28:03.984Z",
      "finish_date": "2026-07-30T21:00:00.000Z",
      "actual_finish_date": "2026-07-28T06:28:28.587Z",
      "sort_order": 4.692551831115192,
      "data": {
        "velocity": {"size": 0},
        "committed": {"size": 0},
        "doneCount": 0,
        "totalCount": 1
      },
      "cards": [{
        "created": "2026-07-28T06:28:19.343Z",
        "updated": "2026-07-28T06:28:19.343Z",
        "iteration_id": "iter-uid-1",
        "card_uid": "card-uid-1",
        "added_by_uid": "user-uid-1",
        "removed_at": null,
        "removed_by_uid": null,
        "sort_order": 1.8589389494913282
      }]
    }, {
      "created": "2026-07-14T12:50:51.313Z",
      "updated": "2026-07-14T12:51:37.811Z",
      "id": "iter-uid-2",
      "space_uid": "space-uid-1",
      "title": "Sprint 1",
      "goal": "Try out iterations",
      "status": "active",
      "creator_uid": "user-uid-1",
      "updater_uid": "user-uid-1",
      "start_date": "2026-07-14T12:51:31.616Z",
      "finish_date": "2026-08-03T08:00:00.000Z",
      "actual_finish_date": null,
      "sort_order": 1.934035284816916,
      "data": {"committed": {"size": 0}}
    }]
    """

  // MARK: - List Iterations

  @Test("200 returns array of Iteration")
  func listSuccess() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: Self.listFixture))

    let iterations = try await client.listIterations(spaceUid: "space-uid-1")
    #expect(iterations.count == 2)
    let closed = iterations[0]
    #expect(closed.id == "iter-uid-1")
    #expect(closed.iterationStatus == .closed)
    #expect(closed.goal == nil)
    #expect(closed.actual_finish_date == "2026-07-28T06:28:28.587Z")
    #expect(closed.data?.doneCount == 0)
    #expect(closed.data?.totalCount == 1)
    #expect(closed.cards?.count == 1)
    #expect(closed.cards?.first?.card_uid == "card-uid-1")
    #expect(closed.cards?.first?.removed_at == nil)
    let active = iterations[1]
    #expect(active.iterationStatus == .active)
    #expect(active.goal == "Try out iterations")
    #expect(active.actual_finish_date == nil)
    #expect(active.data?.doneCount == nil)
    #expect(active.cards == nil)
  }

  @Test("200 with empty body returns empty array")
  func listEmptyBody() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: ""))
    let iterations = try await client.listIterations(spaceUid: "space-uid-1")
    #expect(iterations.isEmpty)
  }

  @Test("query parameters are sent")
  func listSendsQueryParameters() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: "[]")
    let client = try makeClient(transport)

    _ = try await client.listIterations(
      spaceUid: "space-uid-1",
      status: [.planned, .active],
      withData: "cards",
      limit: 50,
      offset: 10,
      order: "desc"
    )

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .get)
    let path = try #require(recorded.request.path)
    #expect(path.hasPrefix("/spaces/space-uid-1/iterations?"))
    // The generated client percent-encodes the comma separator.
    #expect(path.contains("status=planned%2Cactive"))
    #expect(path.contains("with_data=cards"))
    #expect(path.contains("limit=50"))
    #expect(path.contains("offset=10"))
    #expect(path.contains("order=desc"))
  }

  /// Forward compatibility per FR-020a: an undocumented status value must
  /// survive as `.unknown` instead of failing the whole response.
  @Test("undocumented status decodes as unknown")
  func listUndocumentedStatus() async throws {
    let json = """
      [{"id": "iter-uid-1", "status": "some_new_status"}]
      """
    let client = try makeClient(.returning(statusCode: 200, body: json))

    let iterations = try await client.listIterations(spaceUid: "space-uid-1")
    #expect(iterations[0].iterationStatus == .unknown("some_new_status"))
  }

  /// Spaces are addressed by string UID here, which `notFound(resource:id:)`
  /// cannot represent, so a 404 surfaces as `unexpectedResponse`.
  @Test("404 throws unexpectedResponse")
  func listNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await expectUnexpectedResponse(statusCode: 404) {
      _ = try await client.listIterations(spaceUid: "missing-uid")
    }
  }

  @Test("401 throws unauthorized")
  func listUnauthorized() async throws {
    let client = try makeClient(.returning(statusCode: 401))
    await #expect(throws: KaitenError.self) {
      _ = try await client.listIterations(spaceUid: "space-uid-1")
    }
  }

  // MARK: - Create Iteration

  @Test("create sends title and dates in the body")
  func createSendsBody() async throws {
    // Docs-based fixture: a newly created iteration is planned and has null statistics.
    let json = """
      {
        "id": "iter-uid-3",
        "space_uid": "space-uid-1",
        "title": "Sprint 3",
        "goal": "Ship the feature",
        "status": "planned",
        "creator_uid": "user-uid-1",
        "updater_uid": "user-uid-1",
        "start_date": "2026-08-10T00:00:00.000Z",
        "finish_date": "2026-08-24T00:00:00.000Z",
        "actual_finish_date": null,
        "sort_order": 5.5,
        "data": null,
        "created": "2026-08-01T00:00:00.000Z",
        "updated": "2026-08-01T00:00:00.000Z"
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let iteration = try await client.createIteration(
      spaceUid: "space-uid-1",
      title: "Sprint 3",
      goal: "Ship the feature",
      startDate: "2026-08-10T00:00:00.000Z",
      finishDate: "2026-08-24T00:00:00.000Z"
    )

    #expect(iteration.id == "iter-uid-3")
    #expect(iteration.iterationStatus == .planned)
    #expect(iteration.data == nil)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .post)
    #expect(recorded.request.path == "/spaces/space-uid-1/iterations")

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["title"] as? String == "Sprint 3")
    #expect(sent["goal"] as? String == "Ship the feature")
    #expect(sent["start_date"] as? String == "2026-08-10T00:00:00.000Z")
    #expect(sent["finish_date"] as? String == "2026-08-24T00:00:00.000Z")
  }

  @Test("create 400 throws unexpectedResponse")
  func createBadRequest() async throws {
    let client = try makeClient(.returning(statusCode: 400))
    await expectUnexpectedResponse(statusCode: 400) {
      _ = try await client.createIteration(spaceUid: "space-uid-1", title: "Sprint 3")
    }
  }

  @Test("create 402 unsupported tariff throws unexpectedResponse")
  func createPaymentRequired() async throws {
    let client = try makeClient(.returning(statusCode: 402))
    await expectUnexpectedResponse(statusCode: 402) {
      _ = try await client.createIteration(spaceUid: "space-uid-1", title: "Sprint 3")
    }
  }

  // MARK: - Get Iteration

  @Test("200 returns Iteration")
  func getSuccess() async throws {
    // Sanitized live response of `GET /spaces/{space_uid}/iterations/{id}`.
    let json = """
      {
        "id": "iter-uid-1",
        "space_uid": "space-uid-1",
        "title": "Sprint 2",
        "goal": null,
        "status": "closed",
        "creator_uid": "user-uid-1",
        "updater_uid": "user-uid-1",
        "start_date": "2026-07-28T06:28:03.984Z",
        "finish_date": "2026-07-30T21:00:00.000Z",
        "actual_finish_date": "2026-07-28T06:28:28.587Z",
        "sort_order": 4.692551831115192,
        "data": {
          "velocity": {"size": 0},
          "committed": {"size": 0},
          "doneCount": 0,
          "totalCount": 1
        },
        "created": "2026-07-28T06:28:02.762Z",
        "updated": "2026-07-28T06:28:28.587Z"
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let iteration = try await client.getIteration(spaceUid: "space-uid-1", id: "iter-uid-1")
    #expect(iteration.id == "iter-uid-1")
    #expect(iteration.iterationStatus == .closed)
    #expect(iteration.data?.totalCount == 1)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .get)
    #expect(recorded.request.path == "/spaces/space-uid-1/iterations/iter-uid-1")
  }

  @Test("get 404 throws unexpectedResponse")
  func getNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await expectUnexpectedResponse(statusCode: 404) {
      _ = try await client.getIteration(spaceUid: "space-uid-1", id: "missing-uid")
    }
  }

  // MARK: - Update Iteration

  @Test("update targets the iteration and decodes moved_cards")
  func updateSuccess() async throws {
    // Docs-based fixture: closing with new_iteration_id moves unfinished cards.
    let json = """
      {
        "id": "iter-uid-1",
        "space_uid": "space-uid-1",
        "title": "Sprint 2",
        "goal": null,
        "status": "closed",
        "creator_uid": "user-uid-1",
        "updater_uid": "user-uid-1",
        "start_date": "2026-07-28T06:28:03.984Z",
        "finish_date": "2026-07-30T21:00:00.000Z",
        "actual_finish_date": "2026-08-01T00:00:00.000Z",
        "sort_order": 4.5,
        "data": {"committed": {"size": 0}},
        "moved_cards": [{
          "iteration_id": "iter-uid-2",
          "card_uid": "card-uid-1",
          "added_by_uid": "user-uid-1",
          "sort_order": 1.5,
          "created": "2026-08-01T00:00:00.000Z",
          "updated": "2026-08-01T00:00:00.000Z"
        }],
        "created": "2026-07-28T06:28:02.762Z",
        "updated": "2026-08-01T00:00:00.000Z"
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let iteration = try await client.updateIteration(
      spaceUid: "space-uid-1",
      id: "iter-uid-1",
      status: .closed,
      newIterationId: "iter-uid-2"
    )

    #expect(iteration.iterationStatus == .closed)
    #expect(iteration.moved_cards?.count == 1)
    #expect(iteration.moved_cards?.first?.iteration_id == "iter-uid-2")

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .patch)
    #expect(recorded.request.path == "/spaces/space-uid-1/iterations/iter-uid-1")

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["status"] as? String == "closed")
    #expect(sent["new_iteration_id"] as? String == "iter-uid-2")
  }

  @Test("update 400 throws unexpectedResponse")
  func updateBadRequest() async throws {
    let client = try makeClient(.returning(statusCode: 400))
    await expectUnexpectedResponse(statusCode: 400) {
      _ = try await client.updateIteration(
        spaceUid: "space-uid-1", id: "iter-uid-1", status: .planned)
    }
  }

  // MARK: - Delete Iteration

  @Test("delete returns the removed iteration")
  func deleteSuccess() async throws {
    // Docs-based fixture: the deleted iteration is returned with the removed status.
    let json = """
      {
        "id": "iter-uid-1",
        "space_uid": "space-uid-1",
        "title": "Sprint 2",
        "goal": null,
        "status": "removed",
        "creator_uid": "user-uid-1",
        "updater_uid": "user-uid-1",
        "start_date": null,
        "finish_date": null,
        "actual_finish_date": null,
        "sort_order": 4.5,
        "data": null,
        "moved_cards": null,
        "created": "2026-07-28T06:28:02.762Z",
        "updated": "2026-08-01T00:00:00.000Z"
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let iteration = try await client.deleteIteration(spaceUid: "space-uid-1", id: "iter-uid-1")

    #expect(iteration.iterationStatus == .removed)
    #expect(iteration.moved_cards == nil)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .delete)
    #expect(recorded.request.path == "/spaces/space-uid-1/iterations/iter-uid-1")
  }

  @Test("delete sends new_iteration_id in the body")
  func deleteSendsBody() async throws {
    let json = """
      {"id": "iter-uid-1", "status": "removed"}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    _ = try await client.deleteIteration(
      spaceUid: "space-uid-1", id: "iter-uid-1", newIterationId: "iter-uid-2")

    let recorded = try #require(transport.recordedRequests.first)
    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["new_iteration_id"] as? String == "iter-uid-2")
  }

  @Test("delete 400 throws unexpectedResponse")
  func deleteBadRequest() async throws {
    let client = try makeClient(.returning(statusCode: 400))
    await expectUnexpectedResponse(statusCode: 400) {
      _ = try await client.deleteIteration(
        spaceUid: "space-uid-1", id: "iter-uid-1", newIterationId: "iter-uid-1")
    }
  }

  // MARK: - List Iteration Cards

  @Test("200 returns array of IterationCard")
  func listCardsSuccess() async throws {
    // Sanitized live response of `GET /spaces/{space_uid}/iterations/{iteration_id}/cards`.
    let json = """
      [{
        "iteration_id": "iter-uid-1",
        "card_uid": "card-uid-1",
        "added_by_uid": "user-uid-1",
        "removed_at": null,
        "removed_by_uid": null,
        "sort_order": 1.8589389494913282,
        "created": "2026-07-28T06:28:19.343Z",
        "updated": "2026-07-28T06:28:19.343Z"
      }]
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let records = try await client.listIterationCards(
      spaceUid: "space-uid-1", iterationId: "iter-uid-1")
    #expect(records.count == 1)
    #expect(records[0].iteration_id == "iter-uid-1")
    #expect(records[0].card_uid == "card-uid-1")
    #expect(records[0].removed_at == nil)
    #expect(records[0].removed_by_uid == nil)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .get)
    #expect(recorded.request.path == "/spaces/space-uid-1/iterations/iter-uid-1/cards")
  }

  @Test("status filter is sent as a query parameter")
  func listCardsSendsStatus() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: "[]")
    let client = try makeClient(transport)

    _ = try await client.listIterationCards(
      spaceUid: "space-uid-1", iterationId: "iter-uid-1", status: "removed")

    let recorded = try #require(transport.recordedRequests.first)
    let path = try #require(recorded.request.path)
    #expect(path == "/spaces/space-uid-1/iterations/iter-uid-1/cards?status=removed")
  }

  @Test("list cards 400 throws unexpectedResponse")
  func listCardsBadRequest() async throws {
    let client = try makeClient(.returning(statusCode: 400))
    await expectUnexpectedResponse(statusCode: 400) {
      _ = try await client.listIterationCards(
        spaceUid: "space-uid-1", iterationId: "iter-uid-1", status: "bogus")
    }
  }

  // MARK: - Add Card to Iteration

  @Test("add sends card_uid and decodes the record")
  func addCardSuccess() async throws {
    // Docs-based fixture: a fresh record has null removal fields.
    let json = """
      {
        "iteration_id": "iter-uid-1",
        "card_uid": "card-uid-1",
        "added_by_uid": "user-uid-1",
        "removed_at": null,
        "removed_by_uid": null,
        "sort_order": 1.5,
        "created": "2026-08-01T00:00:00.000Z",
        "updated": "2026-08-01T00:00:00.000Z"
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let record = try await client.addCardToIteration(
      spaceUid: "space-uid-1", iterationId: "iter-uid-1", cardUid: "card-uid-1")

    #expect(record.card_uid == "card-uid-1")
    #expect(record.removed_at == nil)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .post)
    #expect(recorded.request.path == "/spaces/space-uid-1/iterations/iter-uid-1/cards")

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["card_uid"] as? String == "card-uid-1")
  }

  @Test("add 400 throws unexpectedResponse")
  func addCardBadRequest() async throws {
    let client = try makeClient(.returning(statusCode: 400))
    await expectUnexpectedResponse(statusCode: 400) {
      _ = try await client.addCardToIteration(
        spaceUid: "space-uid-1", iterationId: "iter-uid-1", cardUid: "card-uid-1")
    }
  }

  // MARK: - Remove Card from Iteration

  @Test("remove targets the card and decodes the record")
  func removeCardSuccess() async throws {
    // Docs-based fixture: removal fills removed_at and removed_by_uid.
    let json = """
      {
        "iteration_id": "iter-uid-1",
        "card_uid": "card-uid-1",
        "added_by_uid": "user-uid-1",
        "removed_at": "2026-08-02T00:00:00.000Z",
        "removed_by_uid": "user-uid-2",
        "sort_order": 1.5,
        "created": "2026-08-01T00:00:00.000Z",
        "updated": "2026-08-02T00:00:00.000Z"
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let record = try await client.removeCardFromIteration(
      spaceUid: "space-uid-1", iterationId: "iter-uid-1", cardUid: "card-uid-1")

    #expect(record.removed_at == "2026-08-02T00:00:00.000Z")
    #expect(record.removed_by_uid == "user-uid-2")

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .delete)
    #expect(recorded.request.path == "/spaces/space-uid-1/iterations/iter-uid-1/cards/card-uid-1")
  }

  @Test("remove 404 throws unexpectedResponse")
  func removeCardNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await expectUnexpectedResponse(statusCode: 404) {
      _ = try await client.removeCardFromIteration(
        spaceUid: "space-uid-1", iterationId: "iter-uid-1", cardUid: "missing-uid")
    }
  }

  // MARK: - Card Iterations History

  @Test("history 200 returns array of IterationCard")
  func historySuccess() async throws {
    // Sanitized live response of `GET /cards/{card_uid}/iterations-history`.
    let json = """
      [{
        "created": "2026-07-28T06:28:19.343Z",
        "updated": "2026-07-28T06:28:19.343Z",
        "iteration_id": "iter-uid-1",
        "card_uid": "card-uid-1",
        "added_by_uid": "user-uid-1",
        "removed_at": null,
        "removed_by_uid": null,
        "sort_order": 1.8589389494913282
      }]
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let records = try await client.getCardIterationsHistory(cardUid: "card-uid-1")
    #expect(records.count == 1)
    #expect(records[0].iteration_id == "iter-uid-1")
    #expect(records[0].card_uid == "card-uid-1")

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .get)
    #expect(recorded.request.path == "/cards/card-uid-1/iterations-history")
  }

  @Test("history 200 with empty body returns empty array")
  func historyEmptyBody() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: ""))
    let records = try await client.getCardIterationsHistory(cardUid: "card-uid-1")
    #expect(records.isEmpty)
  }

  @Test("history 404 throws unexpectedResponse")
  func historyNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await expectUnexpectedResponse(statusCode: 404) {
      _ = try await client.getCardIterationsHistory(cardUid: "missing-uid")
    }
  }
}
