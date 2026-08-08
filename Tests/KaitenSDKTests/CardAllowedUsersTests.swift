import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("CardAllowedUsers")
struct CardAllowedUsersTests {

  private func makeClient(_ transport: MockClientTransport) throws -> KaitenClient {
    try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)
  }

  /// Fixture sanitized from a live response: `uid`, `virtual`, `email_blocked`,
  /// `email_blocked_reason`, `delete_requested_at` and `timeOffRequests` are absent from the
  /// documentation but present in actual responses.
  @Test("200 returns array of AllowedUser")
  func listSuccess() async throws {
    let json = """
      [{
        "id": 1,
        "uid": "00000000-0000-0000-0000-000000000001",
        "full_name": "Alice Example",
        "email": "alice@example.com",
        "username": "alice_example",
        "avatar_initials_url": "data:image/png;base64,AAAA",
        "avatar_uploaded_url": null,
        "initials": "AE",
        "avatar_type": 2,
        "lng": "ru",
        "timezone": "UTC",
        "theme": "auto",
        "created": "2023-01-10T09:52:15.177Z",
        "updated": "2024-09-26T15:51:38.622Z",
        "activated": true,
        "ui_version": 2,
        "virtual": false,
        "email_blocked": null,
        "email_blocked_reason": null,
        "delete_requested_at": null
      },
      {
        "id": 2,
        "uid": "00000000-0000-0000-0000-000000000002",
        "full_name": "Bob Example",
        "email": "bob@example.com",
        "username": "bob_example",
        "avatar_initials_url": "data:image/png;base64,BBBB",
        "avatar_uploaded_url": "https://files.example.com/avatar.jpg",
        "initials": "BE",
        "avatar_type": 3,
        "lng": "en",
        "timezone": "UTC",
        "theme": "auto",
        "created": "2023-01-10T09:52:15.177Z",
        "updated": "2024-09-26T15:51:38.622Z",
        "activated": true,
        "ui_version": 2,
        "virtual": false,
        "email_blocked": null,
        "email_blocked_reason": null,
        "delete_requested_at": null,
        "timeOffRequests": [{
          "id": "00000000-0000-0000-0000-000000000003",
          "user_uid": "00000000-0000-0000-0000-000000000002",
          "start_date": "2026-11-04",
          "end_date": "2026-11-04",
          "reason": "Holiday",
          "status": "approved",
          "comment": null
        }]
      }]
      """
    let client = try makeClient(.returning(statusCode: 200, body: json))

    let users = try await client.listCardAllowedUsers(cardId: 42)
    #expect(users.count == 2)
    #expect(users[0].id == 1)
    #expect(users[0].full_name == "Alice Example")
    #expect(users[0].avatar_uploaded_url == nil)
    #expect(users[0].activated == true)
    #expect(users[0].virtual == false)
    #expect(users[1].avatar_uploaded_url == "https://files.example.com/avatar.jpg")
    #expect(users[1].timeOffRequests?.count == 1)
  }

  @Test("200 with empty body returns empty array")
  func listEmptyBody() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: ""))
    let users = try await client.listCardAllowedUsers(cardId: 42)
    #expect(users.isEmpty)
  }

  @Test("query parameters are forwarded")
  func listForwardsQueryParameters() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: "[]")
    let client = try makeClient(transport)

    _ = try await client.listCardAllowedUsers(
      cardId: 42,
      type: "virtual-users",
      search: "alice",
      orderBy: "email",
      role: 1,
      limit: 10,
      offset: 5
    )

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .get)
    let path = try #require(recorded.request.path)
    #expect(path.hasPrefix("/cards/42/allowed-users?"))
    #expect(path.contains("type=virtual-users"))
    #expect(path.contains("search=alice"))
    #expect(path.contains("orderBy=email"))
    #expect(path.contains("role=1"))
    #expect(path.contains("limit=10"))
    #expect(path.contains("offset=5"))
  }

  @Test("404 throws notFound")
  func listNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    do {
      _ = try await client.listCardAllowedUsers(cardId: 999)
      Issue.record("expected KaitenError.notFound, no error thrown")
    } catch let error as KaitenError {
      guard case .notFound(let resource, let id) = error else {
        Issue.record("expected KaitenError.notFound, got \(error)")
        return
      }
      #expect(resource == "card")
      #expect(id == 999)
    } catch {
      Issue.record("expected KaitenError, got \(error)")
    }
  }

  @Test("401 throws unauthorized")
  func listUnauthorized() async throws {
    let client = try makeClient(.returning(statusCode: 401))
    await #expect(throws: KaitenError.self) {
      _ = try await client.listCardAllowedUsers(cardId: 1)
    }
  }
}
