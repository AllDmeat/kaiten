import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("CreateChecklist")
struct CreateChecklistTests {

  @Test("200 returns created Checklist")
  func success() async throws {
    let json = """
      {"id": 100, "name": "Test checklist", "uid": "eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee", "card_id": 42, "checklist_id": 100, "sort_order": 1.5, "policy_id": null, "fts_version": "-574871004", "deleted": false, "created": "2026-02-18T03:13:03Z", "updated": "2026-02-18T03:13:03Z"}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let checklist = try await client.createChecklist(cardId: 42, name: "Test checklist")
    #expect(checklist.id == 100)
    #expect(checklist.name == "Test checklist")
  }

  @Test("404 throws notFound")
  func notFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.createChecklist(cardId: 999, name: "x")
    }
  }

  @Test("401 throws unauthorized")
  func unauthorized() async throws {
    let transport = MockClientTransport.returning(statusCode: 401)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.createChecklist(cardId: 42, name: "x")
    }
  }
}
