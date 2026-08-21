import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("GetCard")
struct GetCardTests {

  @Test("200 returns Card")
  func success() async throws {
    let json = """
      {"id": 42, "title": "Test card"}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let card = try await client.getCard(id: 42)
    #expect(card.id == 42)
    #expect(card.title == "Test card")
  }

  @Test("200 parses the iteration the card belongs to")
  func iteration() async throws {
    let json = """
      {"id": 42, "title": "Test card", "sprint_id": 7, "iteration": [{
        "id": "00000000-0000-4000-8000-000000000001",
        "iteration_id": "00000000-0000-4000-8000-000000000001",
        "card_uid": "00000000-0000-4000-8000-000000000002",
        "space_uid": "00000000-0000-4000-8000-000000000003",
        "title": "Iteration 1",
        "status": "active",
        "creator_uid": "00000000-0000-4000-8000-000000000004",
        "updater_uid": "00000000-0000-4000-8000-000000000005"
      }]}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let card = try await client.getCard(id: 42)
    let iteration = try #require(card.iteration?.first)
    #expect(iteration.id == "00000000-0000-4000-8000-000000000001")
    #expect(iteration.iteration_id == "00000000-0000-4000-8000-000000000001")
    #expect(iteration.card_uid == "00000000-0000-4000-8000-000000000002")
    #expect(iteration.space_uid == "00000000-0000-4000-8000-000000000003")
    #expect(iteration.title == "Iteration 1")
    #expect(iteration.status == "active")
    #expect(iteration.iterationStatus == .active)
    #expect(iteration.creator_uid == "00000000-0000-4000-8000-000000000004")
    #expect(iteration.updater_uid == "00000000-0000-4000-8000-000000000005")
  }

  @Test("200 leaves iteration nil when the card belongs to none")
  func iterationAbsent() async throws {
    let json = """
      {"id": 42, "title": "Test card", "sprint_id": 7}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let card = try await client.getCard(id: 42)
    #expect(card.iteration == nil)
    #expect(card.sprint_id == 7)
  }

  @Test("200 preserves an undocumented iteration status")
  func iterationUnknownStatus() async throws {
    let json = """
      {"id": 42, "iteration": [{"title": "Iteration 1", "status": "some_new_status"}]}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let card = try await client.getCard(id: 42)
    let iteration = try #require(card.iteration?.first)
    #expect(iteration.iterationStatus == .unknown("some_new_status"))
  }

  @Test("404 throws notFound")
  func notFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.getCard(id: 999)
    }
  }

  @Test("401 throws unauthorized")
  func unauthorized() async throws {
    let transport = MockClientTransport.returning(statusCode: 401)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.getCard(id: 1)
    }
  }
}
