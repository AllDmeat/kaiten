import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("GetChecklist")
struct GetChecklistTests {

  @Test("200 returns Checklist")
  func success() async throws {
    let json = """
      {"id": 100, "name": "My checklist"}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let checklist = try await client.getChecklist(cardId: 1, checklistId: 100)
    #expect(checklist.id == 100)
    #expect(checklist.name == "My checklist")
  }

  @Test("404 throws notFound")
  func notFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.getChecklist(cardId: 1, checklistId: 999)
    }
  }

  @Test("401 throws unauthorized")
  func unauthorized() async throws {
    let transport = MockClientTransport.returning(statusCode: 401)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.getChecklist(cardId: 1, checklistId: 1)
    }
  }

  @Test("200 decodes checklist item responsible as User object")
  func checklistItemResponsible() async throws {
    let json = """
      {
        "id": 100,
        "name": "My checklist",
        "items": [
          {
            "id": 1,
            "text": "Do the thing",
            "sort_order": 1.0,
            "checked": false,
            "checklist_id": 100,
            "user_id": 5,
            "deleted": false,
            "due_date_time_present": false,
            "uid": "abc-123",
            "fts_version": "1",
            "responsible_id": 42,
            "responsible": {
              "id": 42,
              "uid": "user-uid-42",
              "full_name": "Jane Doe",
              "email": "jane.doe@example.com",
              "username": "jane_doe",
              "created": "2019-01-09T14:20:00.759Z",
              "updated": "2024-10-25T16:54:29.326Z",
              "activated": true,
              "virtual": false,
              "ui_version": 2,
              "avatar_type": 3,
              "lng": "en",
              "timezone": "UTC",
              "theme": "auto",
              "initials": "JD",
              "avatar_initials_url": "",
              "avatar_uploaded_url": null,
              "email_blocked": null,
              "email_blocked_reason": null,
              "delete_requested_at": null
            }
          }
        ]
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let checklist = try await client.getChecklist(cardId: 1, checklistId: 100)
    let item = try #require(checklist.items?[safe: 0])
    // Verify responsible_id is decoded correctly
    #expect(item.responsible_id == 42)
  }
}
