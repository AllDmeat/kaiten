import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("Group Admins")
struct GroupAdminsTests {

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

  /// Fixture follows the documented example response of the list endpoint, which carries
  /// `sd_telegram_id`, `news_subscription` and `delete_confirmation_sent_at` on top of the
  /// fields the add/remove responses document.
  @Test("200 returns array of GroupAdmin")
  func listSuccess() async throws {
    let json = """
      [{
        "created": "2024-08-06T06:30:38.514Z",
        "updated": "2024-08-06T06:30:38.514Z",
        "id": 272,
        "uid": "1cd74db5-7c62-4a9a-9c19-053f583c4008",
        "full_name": "Clara Walker",
        "username": "Abbie60262",
        "email": "clara@example.com",
        "activated": true,
        "avatar_initials_url": "data:image/png;base64,abc",
        "avatar_uploaded_url": null,
        "initials": "CW",
        "avatar_type": 2,
        "lng": "en",
        "sd_telegram_id": null,
        "timezone": "UTC",
        "news_subscription": false,
        "theme": "auto",
        "ui_version": 2,
        "virtual": false,
        "email_blocked": null,
        "email_blocked_reason": null,
        "delete_requested_at": null,
        "delete_confirmation_sent_at": null
      }]
      """
    let client = try makeClient(.returning(statusCode: 200, body: json))

    let admins = try await client.listGroupAdmins(groupUid: "group-uid-1")
    #expect(admins.count == 1)
    #expect(admins[0].id == 272)
    #expect(admins[0].uid == "1cd74db5-7c62-4a9a-9c19-053f583c4008")
    #expect(admins[0].full_name == "Clara Walker")
    #expect(admins[0].avatar_uploaded_url == nil)
    #expect(admins[0].avatar_type == 2)
    #expect(admins[0].sd_telegram_id == nil)
    #expect(admins[0].news_subscription == false)
    #expect(admins[0].delete_confirmation_sent_at == nil)
  }

  @Test("list targets the group UID")
  func listRequestPath() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: "[]")
    let client = try makeClient(transport)

    _ = try await client.listGroupAdmins(groupUid: "group-uid-1")

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .get)
    #expect(recorded.request.path == "/groups/group-uid-1/admins")
  }

  @Test("200 with empty body returns empty array")
  func listEmptyBody() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: ""))
    let admins = try await client.listGroupAdmins(groupUid: "group-uid-1")
    #expect(admins.isEmpty)
  }

  @Test("401 throws unauthorized")
  func listUnauthorized() async throws {
    let client = try makeClient(.returning(statusCode: 401))
    await #expect(throws: KaitenError.self) {
      _ = try await client.listGroupAdmins(groupUid: "group-uid-1")
    }
  }

  /// Groups are addressed by string UID, which ``KaitenError/notFound(resource:id:)``
  /// cannot represent, so a 404 surfaces as `unexpectedResponse`.
  @Test("list 404 throws unexpectedResponse")
  func listNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await expectUnexpectedResponse(statusCode: 404) {
      _ = try await client.listGroupAdmins(groupUid: "missing")
    }
  }

  // MARK: - Add

  /// Fixture follows the documented example response of the add endpoint.
  @Test("add sends user_id in the body")
  func addSendsBody() async throws {
    let json = """
      {
        "id": 1,
        "uid": "20072568-2bb5-4c48-94ba-ee7986e4ac83",
        "full_name": "Johnny Doe",
        "email": "admin@example.com",
        "username": "admin",
        "avatar_initials_url": "data:image/png;base64,abc",
        "avatar_uploaded_url": null,
        "initials": "JD",
        "avatar_type": 2,
        "lng": "en",
        "timezone": "UTC",
        "theme": "auto",
        "created": "2024-08-06T06:30:37.802Z",
        "updated": "2024-09-06T13:48:40.670Z",
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

    let admin = try await client.addGroupAdmin(groupUid: "group-uid-1", userId: 1)

    #expect(admin.id == 1)
    #expect(admin.username == "admin")

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .post)
    #expect(recorded.request.path == "/groups/group-uid-1/admins")

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["user_id"] as? Int == 1)
  }

  @Test("add 400 validation error throws unexpectedResponse")
  func addBadRequest() async throws {
    let client = try makeClient(.returning(statusCode: 400))
    await expectUnexpectedResponse(statusCode: 400) {
      _ = try await client.addGroupAdmin(groupUid: "group-uid-1", userId: 1)
    }
  }

  @Test("add 402 unsupported tariff throws unexpectedResponse")
  func addPaymentRequired() async throws {
    let client = try makeClient(.returning(statusCode: 402))
    await expectUnexpectedResponse(statusCode: 402) {
      _ = try await client.addGroupAdmin(groupUid: "group-uid-1", userId: 1)
    }
  }

  // MARK: - Remove

  /// Fixture follows the documented example response of the remove endpoint.
  @Test("remove targets the group UID and user ID and returns the removed admin")
  func removeSuccess() async throws {
    let json = """
      {
        "id": 1,
        "uid": "20072568-2bb5-4c48-94ba-ee7986e4ac83",
        "full_name": "Johnny Doe",
        "email": "admin@example.com",
        "username": "admin",
        "avatar_initials_url": "data:image/png;base64,abc",
        "avatar_uploaded_url": null,
        "initials": "JD",
        "avatar_type": 2,
        "lng": "en",
        "timezone": "UTC",
        "theme": "auto",
        "created": "2024-08-06T06:30:37.802Z",
        "updated": "2024-09-06T13:48:40.670Z",
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

    let admin = try await client.removeGroupAdmin(groupUid: "group-uid-1", userId: 1)

    #expect(admin.id == 1)
    #expect(admin.full_name == "Johnny Doe")

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .delete)
    #expect(recorded.request.path == "/groups/group-uid-1/admins/1")
  }

  /// The group is addressed by string UID and the response does not say whether the group or
  /// the user is missing, so a 404 surfaces as `unexpectedResponse`.
  @Test("remove 404 throws unexpectedResponse")
  func removeNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await expectUnexpectedResponse(statusCode: 404) {
      _ = try await client.removeGroupAdmin(groupUid: "missing", userId: 1)
    }
  }
}
