import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("GetCardLocationHistory")
struct GetCardLocationHistoryTests {

  private let minimalJSON = """
    [{
      "id": "1",
      "card_id": 42,
      "board_id": 10,
      "column_id": 100,
      "subcolumn_id": null,
      "lane_id": 200,
      "sprint_id": null,
      "author_id": 5,
      "condition": 1,
      "changed": "2025-01-15T10:00:00Z"
    }]
    """

  private let withAuthorJSON = """
    [{
      "id": "1001",
      "card_id": 42,
      "board_id": 10,
      "column_id": 100,
      "subcolumn_id": null,
      "lane_id": 200,
      "sprint_id": null,
      "author_id": 5,
      "condition": 1,
      "changed": "2025-01-15T10:00:00Z",
      "author": {
        "id": 5,
        "uid": "abc-123",
        "full_name": "Test User",
        "email": "test@example.com",
        "username": "testuser",
        "avatar_initials_url": "data:image/png;base64,abc",
        "avatar_uploaded_url": null,
        "initials": "TU",
        "avatar_type": 2,
        "lng": "ru",
        "timezone": "UTC",
        "theme": "light",
        "created": "2024-01-01T00:00:00Z",
        "updated": "2024-06-01T00:00:00Z",
        "activated": true,
        "ui_version": 2,
        "virtual": false,
        "email_blocked": null,
        "email_blocked_reason": null,
        "delete_requested_at": null
      }
    }]
    """

  @Test("200 returns array of history entries")
  func success() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: minimalJSON)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let history = try await client.getCardLocationHistory(cardId: 42)
    #expect(history.count == 1)
    #expect(history[0].id == "1")
    #expect(history[0].card_id == 42)
    #expect(history[0].board_id == 10)
    #expect(history[0].column_id == 100)
    #expect(history[0].subcolumn_id == nil)
    #expect(history[0].lane_id == 200)
    #expect(history[0].sprint_id == nil)
    #expect(history[0].author_id == 5)
    #expect(history[0].condition == 1)
  }

  @Test("200 decodes author object when present")
  func decodesAuthor() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: withAuthorJSON)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let history = try await client.getCardLocationHistory(cardId: 42)
    #expect(history.count == 1)
    #expect(history[0].id == "1001")
    let author = try #require(history[0].author)
    #expect(author.id == 5)
    #expect(author.full_name == "Test User")
    #expect(author.email == "test@example.com")
    #expect(author.username == "testuser")
    #expect(author.initials == "TU")
    #expect(author.avatar_type == 2)
    #expect(author.avatar_uploaded_url == nil)
  }

  @Test("200 returns empty array when body is empty")
  func emptyResponse() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: "[]")
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let history = try await client.getCardLocationHistory(cardId: 42)
    #expect(history.isEmpty)
  }

  @Test("404 throws notFound")
  func notFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.getCardLocationHistory(cardId: 999)
    }
  }

  @Test("401 throws unauthorized")
  func unauthorized() async throws {
    let transport = MockClientTransport.returning(statusCode: 401)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.getCardLocationHistory(cardId: 42)
    }
  }
}
