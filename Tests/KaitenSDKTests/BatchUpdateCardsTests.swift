import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("BatchUpdateCards")
struct BatchUpdateCardsTests {

  private func makeClient(_ transport: MockClientTransport) throws -> KaitenClient {
    try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)
  }

  /// Reads the recorded request body as a JSON dictionary.
  private func requestBodyJSON(from transport: MockClientTransport) async throws -> [String: Any] {
    let req = try #require(transport.recordedRequests.first)
    let bodyData = try await Data(collecting: #require(req.body), upTo: 1024 * 1024)
    return try #require(
      try JSONSerialization.jsonObject(with: bodyData) as? [String: Any]
    )
  }

  // Fixture based on the documented 202 response: a single string `id`
  // carrying the UUID of the background job.
  private let jobJSON = """
    {"id": "3fa85f64-5717-4562-b3fc-2c963f66afa6"}
    """

  @Test("202 returns background job ID")
  func success() async throws {
    let transport = MockClientTransport.returning(statusCode: 202, body: jobJSON)
    let client = try makeClient(transport)

    let job = try await client.batchUpdateCards(
      boardId: 1,
      attributes: .init(asap: true)
    )
    #expect(job.id == "3fa85f64-5717-4562-b3fc-2c963f66afa6")

    let req = try #require(transport.recordedRequests.first)
    #expect(req.request.method == .patch)
    #expect(req.request.path == "/cards")
  }

  @Test("request body carries criteria, attributes and order_by")
  func requestBody() async throws {
    let transport = MockClientTransport.returning(statusCode: 202, body: jobJSON)
    let client = try makeClient(transport)

    _ = try await client.batchUpdateCards(
      columnId: 2,
      laneId: 3,
      condition: .archived,
      attributes: .init(owner_id: 42, title: "Renamed", asap: true),
      orderBy: .init(field: .dueDate, direction: .ascending)
    )

    let body = try await requestBodyJSON(from: transport)
    #expect(body["column_id"] as? Int == 2)
    #expect(body["lane_id"] as? Int == 3)
    #expect(body["condition"] as? Int == 2)
    #expect(body["board_id"] == nil, "unset criteria should be absent")
    let attributes = try #require(body["attributes"] as? [String: Any])
    #expect(attributes["owner_id"] as? Int == 42)
    #expect(attributes["title"] as? String == "Renamed")
    #expect(attributes["asap"] as? Bool == true)
    let orderBy = try #require(body["order_by"] as? [String: Any])
    #expect(orderBy["field_type"] as? String == "due_date")
    #expect(orderBy["direction"] as? String == "asc")
  }

  @Test("typed sorting accessors preserve undocumented values")
  func sortingAccessors() {
    let orderBy = Components.Schemas.BatchUpdateCardsOrderBy(
      field_type: "some_new_field", id: 7, direction: "sideways")
    #expect(orderBy.orderField == .unknown("some_new_field"))
    #expect(orderBy.sortDirection == .unknown("sideways"))

    let typed = Components.Schemas.BatchUpdateCardsOrderBy(
      field: .customProperty, id: 7, direction: .descending)
    #expect(typed.field_type == "cp")
    #expect(typed.id == 7)
    #expect(typed.direction == "desc")
  }

  @Test("400 throws unexpectedResponse")
  func badRequest() async throws {
    let client = try makeClient(.returning(statusCode: 400))
    await #expect(throws: KaitenError.self) {
      _ = try await client.batchUpdateCards(boardId: 1, attributes: .init(asap: true))
    }
  }

  @Test("401 throws unauthorized")
  func unauthorized() async throws {
    let client = try makeClient(.returning(statusCode: 401))
    do {
      _ = try await client.batchUpdateCards(boardId: 1, attributes: .init(asap: true))
      Issue.record("expected KaitenError.unauthorized, no error thrown")
    } catch {
      guard case .unauthorized = error else {
        Issue.record("expected KaitenError.unauthorized, got \(error)")
        return
      }
    }
  }

  @Test("402 throws unexpectedResponse")
  func paymentRequired() async throws {
    let client = try makeClient(.returning(statusCode: 402))
    do {
      _ = try await client.batchUpdateCards(boardId: 1, attributes: .init(asap: true))
      Issue.record("expected KaitenError.unexpectedResponse(402), no error thrown")
    } catch {
      guard case .unexpectedResponse(let code, _) = error, code == 402 else {
        Issue.record("expected KaitenError.unexpectedResponse(402), got \(error)")
        return
      }
    }
  }

  @Test("404 throws unexpectedResponse, not notFound")
  func notFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    do {
      _ = try await client.batchUpdateCards(boardId: 999, attributes: .init(asap: true))
      Issue.record("expected KaitenError.unexpectedResponse(404), no error thrown")
    } catch {
      guard case .unexpectedResponse(let code, _) = error, code == 404 else {
        Issue.record("expected KaitenError.unexpectedResponse(404), got \(error)")
        return
      }
    }
  }
}
