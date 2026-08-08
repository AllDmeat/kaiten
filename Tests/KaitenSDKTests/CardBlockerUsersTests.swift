import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("Card Blocker Users")
struct CardBlockerUsersTests {

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

  // MARK: - List

  /// Fixture built from the documented response attributes — live verification only produced
  /// empty arrays (no blocker in the instance had assigned users).
  @Test("200 returns array of CardBlockerUser")
  func listSuccess() async throws {
    let json = """
      [{
        "id": 42,
        "uid": "user-uid-1",
        "full_name": "Jane Doe",
        "email": "jane@example.com",
        "username": "jane",
        "avatar_initials_url": "https://example.com/avatar-initials.png",
        "avatar_uploaded_url": null,
        "initials": "JD",
        "avatar_type": 2,
        "lng": "en",
        "timezone": "Europe/London",
        "theme": "auto",
        "updated": "2026-02-01T12:30:00.000Z",
        "created": "2026-01-01T10:00:00.000Z",
        "activated": true,
        "ui_version": 2,
        "virtual": false,
        "email_blocked": null,
        "email_blocked_reason": null,
        "delete_requested_at": null,
        "show_tour": false,
        "chat_enabled": true,
        "sd_telegram_id": null,
        "news_subscription": true,
        "delete_confirmation_sent_at": null,
        "eula_accepted_at": null,
        "terms_of_service_accepted_at": null,
        "privacy_policy_accepted_at": null,
        "block_uid": "block-uid-1",
        "user_uid": "user-uid-1"
      }]
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let users = try await client.listCardBlockerUsers(blockerId: 501)
    #expect(users.count == 1)
    #expect(users[0].id == 42)
    #expect(users[0].uid == "user-uid-1")
    #expect(users[0].full_name == "Jane Doe")
    #expect(users[0].email == "jane@example.com")
    #expect(users[0].avatar_uploaded_url == nil)
    #expect(users[0].avatar_type == 2)
    #expect(users[0].activated == true)
    #expect(users[0].virtual == false)
    #expect(users[0].show_tour == false)
    #expect(users[0].block_uid == "block-uid-1")
    #expect(users[0].user_uid == "user-uid-1")

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .get)
    #expect(recorded.request.path == "/blockers/501/users")
  }

  /// A live instance answers `[]` for a blocker with no assigned users.
  @Test("200 with empty array returns empty result")
  func listEmptyArray() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: "[]"))
    let users = try await client.listCardBlockerUsers(blockerId: 501)
    #expect(users.isEmpty)
  }

  @Test("200 with empty body returns empty array")
  func listEmptyBody() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: ""))
    let users = try await client.listCardBlockerUsers(blockerId: 501)
    #expect(users.isEmpty)
  }

  @Test("401 throws unauthorized")
  func listUnauthorized() async throws {
    let client = try makeClient(.returning(statusCode: 401))
    await #expect(throws: KaitenError.self) {
      _ = try await client.listCardBlockerUsers(blockerId: 501)
    }
  }

  @Test("403 throws unexpectedResponse")
  func listForbidden() async throws {
    let client = try makeClient(.returning(statusCode: 403))
    await expectUnexpectedResponse(statusCode: 403) {
      _ = try await client.listCardBlockerUsers(blockerId: 501)
    }
  }

  // MARK: - Add

  /// Fixture built from the documented response attributes — mutating endpoints are not
  /// exercised against the live API.
  @Test("add sends user_id in the body and returns the added user")
  func addSendsBody() async throws {
    let json = """
      {
        "id": 42,
        "uid": "user-uid-1",
        "full_name": "Jane Doe",
        "email": "jane@example.com",
        "username": "jane",
        "avatar_initials_url": "https://example.com/avatar-initials.png",
        "avatar_uploaded_url": null,
        "initials": "JD",
        "avatar_type": 2,
        "lng": "en",
        "timezone": "Europe/London",
        "theme": "light",
        "updated": "2026-02-01T12:30:00.000Z",
        "created": "2026-01-01T10:00:00.000Z",
        "activated": true,
        "ui_version": 2,
        "virtual": false,
        "email_blocked": null,
        "email_blocked_reason": null,
        "delete_requested_at": null
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let user = try await client.addCardBlockerUser(blockerId: 501, userId: 42)

    #expect(user.id == 42)
    #expect(user.uid == "user-uid-1")
    #expect(user.full_name == "Jane Doe")
    #expect(user.email_blocked == nil)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .post)
    #expect(recorded.request.path == "/blockers/501/users")

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["user_id"] as? Int == 42)
  }

  @Test("add 401 throws unauthorized")
  func addUnauthorized() async throws {
    let client = try makeClient(.returning(statusCode: 401))
    await #expect(throws: KaitenError.self) {
      _ = try await client.addCardBlockerUser(blockerId: 501, userId: 42)
    }
  }

  // MARK: - Remove

  /// Fixture built from the documented response attributes (`id`) — mutating endpoints are not
  /// exercised against the live API.
  @Test("remove targets the user id and returns the removed id")
  func removeSuccess() async throws {
    let json = """
      {"id": 42}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let removed = try await client.removeCardBlockerUser(blockerId: 501, userId: 42)

    #expect(removed.id == 42)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .delete)
    #expect(recorded.request.path == "/blockers/501/users/42")
  }

  @Test("remove 403 throws unexpectedResponse")
  func removeForbidden() async throws {
    let client = try makeClient(.returning(statusCode: 403))
    await expectUnexpectedResponse(statusCode: 403) {
      _ = try await client.removeCardBlockerUser(blockerId: 501, userId: 42)
    }
  }

  // MARK: - Current User Blockers

  /// Fixture built from the documented response attributes — live verification only produced
  /// the empty-array shape (the current user had no blockers).
  @Test("200 returns blocked cards and summary")
  func currentUserBlockersSuccess() async throws {
    let json = """
      {
        "blocked_cards": [{
          "card_id": 11,
          "card_title": "Blocked card",
          "blocked_by": {
            "card_id": 12,
            "card_title": "Blocking card",
            "blocker_id": 42,
            "blocker_name": "Jane Doe",
            "blocker_emale": "jane@example.com"
          },
          "block_reason": null,
          "categories": [{
            "uid": "cat-uid-1",
            "name": "Waiting for info",
            "color": 16
          }],
          "block_created": 1767225600,
          "updated": "2026-02-01T12:30:00.000Z",
          "released": false
        }],
        "summary": {
          "total_blocked": 1,
          "blocked_by_user": "Jane Doe",
          "cards_without_reason": 1
        }
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let blockers = try await client.getCurrentUserBlockers()

    let card = try #require(blockers.blocked_cards?.first)
    #expect(card.card_id == 11)
    #expect(card.card_title == "Blocked card")
    #expect(card.block_reason == nil)
    #expect(card.blocked_by?.blocker_id == 42)
    #expect(card.blocked_by?.blocker_name == "Jane Doe")
    #expect(card.blocked_by?.blocker_emale == "jane@example.com")
    #expect(card.categories?.first?.uid == "cat-uid-1")
    #expect(card.categories?.first?.color == 16)
    #expect(card.block_created == 1_767_225_600)
    #expect(card.released == false)
    #expect(blockers.summary?.total_blocked == 1)
    #expect(blockers.summary?.cards_without_reason == 1)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .get)
    #expect(recorded.request.path == "/users/current/blockers")
  }

  /// The documentation declares an object, but a live instance answers `[]` when the current
  /// user has no blockers. The SDK maps that shape to an empty result.
  @Test("200 with empty array maps to empty result")
  func currentUserBlockersEmptyArray() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: "[]"))
    let blockers = try await client.getCurrentUserBlockers()
    #expect(blockers.blocked_cards?.isEmpty == true)
    #expect(blockers.summary == nil)
  }

  @Test("401 throws unauthorized")
  func currentUserBlockersUnauthorized() async throws {
    let client = try makeClient(.returning(statusCode: 401))
    await #expect(throws: KaitenError.self) {
      _ = try await client.getCurrentUserBlockers()
    }
  }
}
