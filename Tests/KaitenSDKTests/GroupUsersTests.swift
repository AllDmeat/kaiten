import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("Group Users")
struct GroupUsersTests {

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

  /// Fixture built from the documented response attributes of the group-users endpoints.
  /// The live GET could not be exercised: listing company groups requires an administrative
  /// permission the verification token does not have, so no real group UID was obtainable.
  private static let groupUserJSON = """
    {
      "id": 123,
      "full_name": "Jane Doe",
      "email": "jane.doe@example.com",
      "username": "jane.doe",
      "avatar_initials_url": "https://example.kaiten.ru/avatars/initials/jd.png",
      "avatar_uploaded_url": null,
      "initials": "JD",
      "avatar_type": 2,
      "lng": "en",
      "timezone": "Europe/Amsterdam",
      "theme": "auto",
      "updated": "2026-01-02T03:04:05.678Z",
      "created": "2025-01-02T03:04:05.678Z",
      "activated": true,
      "ui_version": 2,
      "virtual": false,
      "email_blocked": null,
      "email_blocked_reason": null,
      "delete_requested_at": null,
      "delete_confirmation_sent_at": null,
      "sd_telegram_id": 456,
      "news_subscription": true
    }
    """

  // MARK: - List

  @Test("200 returns array of GroupUser")
  func listSuccess() async throws {
    let transport = MockClientTransport.returning(
      statusCode: 200, body: "[\(Self.groupUserJSON)]")
    let client = try makeClient(transport)

    let users = try await client.listGroupUsers(groupUid: "group-uid-1")
    #expect(users.count == 1)
    #expect(users[0].id == 123)
    #expect(users[0].full_name == "Jane Doe")
    #expect(users[0].email == "jane.doe@example.com")
    #expect(users[0].avatar_uploaded_url == nil)
    #expect(users[0].avatar_type == 2)
    #expect(users[0].activated == true)
    #expect(users[0].virtual == false)
    #expect(users[0].sd_telegram_id == 456)
    #expect(users[0].news_subscription == true)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .get)
    #expect(recorded.request.path == "/groups/group-uid-1/users")
  }

  @Test("200 with empty body returns empty array")
  func listEmptyBody() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: ""))
    let users = try await client.listGroupUsers(groupUid: "group-uid-1")
    #expect(users.isEmpty)
  }

  /// Groups are addressed by string UID, which ``KaitenError/notFound(resource:id:)``
  /// cannot represent, so a 404 surfaces as `unexpectedResponse`.
  @Test("list 404 throws unexpectedResponse")
  func listNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await expectUnexpectedResponse(statusCode: 404) {
      _ = try await client.listGroupUsers(groupUid: "missing")
    }
  }

  @Test("list 401 throws unauthorized")
  func listUnauthorized() async throws {
    let client = try makeClient(.returning(statusCode: 401))
    await #expect(throws: KaitenError.self) {
      _ = try await client.listGroupUsers(groupUid: "group-uid-1")
    }
  }

  @Test("list 403 throws unexpectedResponse")
  func listForbidden() async throws {
    let client = try makeClient(.returning(statusCode: 403))
    await expectUnexpectedResponse(statusCode: 403) {
      _ = try await client.listGroupUsers(groupUid: "group-uid-1")
    }
  }

  // MARK: - Add

  @Test("add sends user_id in the body and parses the added user")
  func addSendsBody() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: Self.groupUserJSON)
    let client = try makeClient(transport)

    let user = try await client.addUserToGroup(
      groupUid: "group-uid-1",
      userId: 123,
      requestId: "request-uid-1",
      operatorComment: "Access approved"
    )

    #expect(user.id == 123)
    #expect(user.username == "jane.doe")

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .post)
    #expect(recorded.request.path == "/groups/group-uid-1/users")

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["user_id"] as? Int == 123)
    #expect(sent["request_id"] as? String == "request-uid-1")
    #expect(sent["operator_comment"] as? String == "Access approved")
  }

  @Test("add 400 validation error throws unexpectedResponse")
  func addBadRequest() async throws {
    let client = try makeClient(.returning(statusCode: 400))
    await expectUnexpectedResponse(statusCode: 400) {
      _ = try await client.addUserToGroup(groupUid: "group-uid-1", userId: 123)
    }
  }

  @Test("add 402 unsupported tariff throws unexpectedResponse")
  func addPaymentRequired() async throws {
    let client = try makeClient(.returning(statusCode: 402))
    await expectUnexpectedResponse(statusCode: 402) {
      _ = try await client.addUserToGroup(groupUid: "group-uid-1", userId: 123)
    }
  }

  @Test("add 404 throws unexpectedResponse")
  func addNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await expectUnexpectedResponse(statusCode: 404) {
      _ = try await client.addUserToGroup(groupUid: "missing", userId: 123)
    }
  }

  // MARK: - Remove

  @Test("remove targets the user ID and parses the removed user")
  func removeSuccess() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: Self.groupUserJSON)
    let client = try makeClient(transport)

    let user = try await client.removeUserFromGroup(groupUid: "group-uid-1", userId: 123)

    #expect(user.id == 123)
    #expect(user.email == "jane.doe@example.com")

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .delete)
    #expect(recorded.request.path == "/groups/group-uid-1/users/123")
  }

  @Test("remove 402 unsupported tariff throws unexpectedResponse")
  func removePaymentRequired() async throws {
    let client = try makeClient(.returning(statusCode: 402))
    await expectUnexpectedResponse(statusCode: 402) {
      _ = try await client.removeUserFromGroup(groupUid: "group-uid-1", userId: 123)
    }
  }

  @Test("remove 403 throws unexpectedResponse")
  func removeForbidden() async throws {
    let client = try makeClient(.returning(statusCode: 403))
    await expectUnexpectedResponse(statusCode: 403) {
      _ = try await client.removeUserFromGroup(groupUid: "group-uid-1", userId: 123)
    }
  }

  @Test("remove 404 throws unexpectedResponse")
  func removeNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await expectUnexpectedResponse(statusCode: 404) {
      _ = try await client.removeUserFromGroup(groupUid: "group-uid-1", userId: 456)
    }
  }
}
