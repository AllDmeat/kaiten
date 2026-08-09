import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("Space Users")
struct SpaceUsersTests {

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

  /// Sanitized real response. The second user has access inherited from a parent entity, so
  /// `own_access_mod`, `own_role_ids` and `own_role` are JSON null — the documentation declares
  /// them non-nullable.
  private static let listFixture = """
    [
      {
        "id": 11,
        "uid": "00000000-0000-0000-0000-000000000a01",
        "full_name": "Alice Example",
        "email": "alice@example.com",
        "username": "alice",
        "avatar_initials_url": "data:image/png;base64,AAAA",
        "avatar_uploaded_url": "https://files.kaiten.example/avatar.jpg",
        "initials": "AE",
        "avatar_type": 3,
        "lng": "en",
        "timezone": "UTC",
        "theme": "auto",
        "created": "2019-01-09T14:20:00.759Z",
        "updated": "2024-10-25T16:54:29.326Z",
        "activated": true,
        "ui_version": 2,
        "virtual": false,
        "email_blocked": null,
        "email_blocked_reason": null,
        "delete_requested_at": null,
        "apps_permissions": 5,
        "temporarily_inactive": false,
        "role_permissions": {"space": {"read": true}},
        "role": 3,
        "space_role_id": 3,
        "role_ids": ["00000000-0000-0000-0000-000000000r01"],
        "groups_role_ids": null,
        "access_mod": "all",
        "own_role": 3,
        "own_role_ids": ["00000000-0000-0000-0000-000000000r01"],
        "own_groups_role_ids": null,
        "own_access_mod": "all",
        "groups": [{"id": 5, "name": "Example group", "company_id": 1, "permissions": 0, "add_to_cards_and_spaces_enabled": false, "user_id": 11}],
        "current": true
      },
      {
        "id": 12,
        "uid": "00000000-0000-0000-0000-000000000a02",
        "full_name": "Bob Example",
        "email": "bob@example.com",
        "username": "bob",
        "avatar_initials_url": "data:image/png;base64,BBBB",
        "avatar_uploaded_url": null,
        "initials": "BE",
        "avatar_type": 2,
        "lng": "ru",
        "timezone": "Europe/Moscow",
        "theme": "light",
        "created": "2020-02-02T10:00:00.000Z",
        "updated": "2024-01-01T00:00:00.000Z",
        "activated": true,
        "ui_version": 2,
        "virtual": false,
        "email_blocked": null,
        "email_blocked_reason": null,
        "delete_requested_at": null,
        "apps_permissions": 1,
        "temporarily_inactive": false,
        "role_permissions": {},
        "role": 2,
        "space_role_id": 2,
        "role_ids": ["00000000-0000-0000-0000-000000000r02"],
        "groups_role_ids": null,
        "access_mod": "all",
        "own_role": null,
        "own_role_ids": null,
        "own_groups_role_ids": null,
        "own_access_mod": null,
        "current": false
      }
    ]
    """

  @Test("200 returns array of SpaceUser")
  func listSuccess() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: Self.listFixture)
    let client = try makeClient(transport)

    let users = try await client.listSpaceUsers(spaceId: 55)
    #expect(users.count == 2)
    #expect(users[0].id == 11)
    #expect(users[0].email == "alice@example.com")
    #expect(users[0].apps_permissions == 5)
    #expect(users[0].own_access_mod == "all")
    #expect(users[0].own_role_ids?.count == 1)
    #expect(users[0].current == true)
    #expect(users[0].groups?.count == 1)
    #expect(users[1].avatar_uploaded_url == nil)
    #expect(users[1].own_access_mod == nil)
    #expect(users[1].own_role_ids == nil)
    #expect(users[1].own_role == nil)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .get)
    #expect(recorded.request.path == "/spaces/55/users")
  }

  @Test("query parameters are sent")
  func listQueryParameters() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: "[]")
    let client = try makeClient(transport)

    _ = try await client.listSpaceUsers(spaceId: 55, includeInheritedAccess: true, inactive: false)

    let recorded = try #require(transport.recordedRequests.first)
    let path = try #require(recorded.request.path)
    #expect(path.contains("include_inherited_access=true"))
    #expect(path.contains("inactive=false"))
  }

  @Test("200 with empty body returns empty array")
  func listEmptyBody() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: ""))
    let users = try await client.listSpaceUsers(spaceId: 55)
    #expect(users.isEmpty)
  }

  @Test("404 throws notFound")
  func listNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await #expect(throws: KaitenError.self) {
      _ = try await client.listSpaceUsers(spaceId: 999)
    }
  }

  @Test("401 throws unauthorized")
  func listUnauthorized() async throws {
    let client = try makeClient(.returning(statusCode: 401))
    await #expect(throws: KaitenError.self) {
      _ = try await client.listSpaceUsers(spaceId: 55)
    }
  }

  // MARK: - Invite

  @Test("invite sends the body and parses the response")
  func inviteSuccess() async throws {
    // Fixture from the documentation's response schema.
    let json = """
      {
        "user": {
          "id": 13,
          "full_name": "Carol Example",
          "email": "carol@example.com",
          "username": "carol",
          "avatar_initials_url": "data:image/png;base64,CCCC",
          "avatar_uploaded_url": null,
          "initials": "CE",
          "avatar_type": 2,
          "lng": "en",
          "timezone": "UTC",
          "theme": "auto",
          "updated": "2024-01-01T00:00:00.000Z",
          "created": "2024-01-01T00:00:00.000Z",
          "activated": false,
          "ui_version": 2,
          "virtual": false
        },
        "access_record": {
          "access_mod": "all",
          "entity_uid": "00000000-0000-0000-0000-000000000e01",
          "user_id": 13,
          "own_role_ids": ["06ccb31f-426b-4fa3-b7e5-861daee95696"],
          "own_access_mod": "all"
        },
        "message": "User invited"
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let result = try await client.inviteUserToSpace(
      spaceId: 55,
      email: "carol@example.com",
      roleId: "06ccb31f-426b-4fa3-b7e5-861daee95696",
      guest: true,
      sendEmail: false
    )

    #expect(result.user?.id == 13)
    #expect(result.access_record?.user_id == 13)
    #expect(result.access_record?.own_role_ids?.count == 1)
    #expect(result.message == "User invited")

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .post)
    #expect(recorded.request.path == "/spaces/55/users")

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["email"] as? String == "carol@example.com")
    #expect(sent["role_id"] as? String == "06ccb31f-426b-4fa3-b7e5-861daee95696")
    #expect(sent["guest"] as? Bool == true)
    #expect(sent["send_email"] as? Bool == false)
  }

  @Test("invite 400 throws unexpectedResponse")
  func inviteBadRequest() async throws {
    let client = try makeClient(.returning(statusCode: 400, body: #"{"message": "bad email"}"#))
    await expectUnexpectedResponse(statusCode: 400) {
      _ = try await client.inviteUserToSpace(spaceId: 55, email: "not-an-email")
    }
  }

  // MARK: - Get

  @Test("200 returns SpaceUserDetails")
  func getSuccess() async throws {
    // Sanitized real response.
    let json = """
      {
        "id": 11,
        "uid": "00000000-0000-0000-0000-000000000a01",
        "full_name": "Alice Example",
        "email": "alice@example.com",
        "username": "alice",
        "avatar_initials_url": "data:image/png;base64,AAAA",
        "avatar_uploaded_url": "https://files.kaiten.example/avatar.jpg",
        "initials": "AE",
        "avatar_type": 3,
        "lng": "en",
        "timezone": "UTC",
        "theme": "auto",
        "created": "2019-01-09T14:20:00.759Z",
        "updated": "2024-10-25T16:54:29.326Z",
        "activated": true,
        "ui_version": 2,
        "virtual": false,
        "email_blocked": null,
        "email_blocked_reason": null,
        "delete_requested_at": null,
        "entity_uid": "00000000-0000-0000-0000-000000000e01",
        "user_id": 11,
        "access_mod": "all",
        "role": 3,
        "space_role_id": 3
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let user = try await client.getSpaceUser(spaceId: 55, userId: 11)
    #expect(user.id == 11)
    #expect(user.user_id == 11)
    #expect(user.entity_uid == "00000000-0000-0000-0000-000000000e01")
    #expect(user.access_mod == "all")
    #expect(user.role == 3)
    #expect(user.space_role_id == 3)
    #expect(user.email_blocked == nil)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .get)
    #expect(recorded.request.path == "/spaces/55/users/11")
  }

  @Test("get 404 throws notFound")
  func getNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await #expect(throws: KaitenError.self) {
      _ = try await client.getSpaceUser(spaceId: 55, userId: 999)
    }
  }

  // MARK: - Update

  @Test("update sends the body and parses the response")
  func updateSuccess() async throws {
    // Fixture from the documentation's response schema.
    let json = """
      {
        "entity_uid": "00000000-0000-0000-0000-000000000e01",
        "access_mod": "all",
        "own_access_mod": "all",
        "own_role_ids": ["a431ed00-1b32-4cc7-92b6-85e4bc7de40e"],
        "id": 11,
        "user_id": 11
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let result = try await client.updateSpaceUser(
      spaceId: 55,
      userId: 11,
      roleId: "a431ed00-1b32-4cc7-92b6-85e4bc7de40e",
      notificationsEnabled: true
    )

    #expect(result.id == 11)
    #expect(result.own_role_ids == ["a431ed00-1b32-4cc7-92b6-85e4bc7de40e"])

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .patch)
    #expect(recorded.request.path == "/spaces/55/users/11")

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["role_id"] as? String == "a431ed00-1b32-4cc7-92b6-85e4bc7de40e")
    #expect(sent["notifications_enabled"] as? Bool == true)
  }

  @Test("update 400 throws unexpectedResponse")
  func updateBadRequest() async throws {
    let client = try makeClient(.returning(statusCode: 400, body: #"{"message": "bad role"}"#))
    await expectUnexpectedResponse(statusCode: 400) {
      _ = try await client.updateSpaceUser(spaceId: 55, userId: 11, roleId: "bogus")
    }
  }

  // MARK: - Remove

  @Test("remove targets the user and parses the response")
  func removeSuccess() async throws {
    // Fixture from the documentation's response schema; `own_role_ids` is documented as null.
    let json = """
      {
        "user_id": 11,
        "entity_uid": "00000000-0000-0000-0000-000000000e01",
        "access_mod": "all",
        "own_access_mod": "all",
        "own_role_ids": null
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let result = try await client.removeSpaceUser(spaceId: 55, userId: 11)
    #expect(result.user_id == 11)
    #expect(result.own_role_ids == nil)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .delete)
    #expect(recorded.request.path == "/spaces/55/users/11")
  }

  @Test("remove 409 throws unexpectedResponse")
  func removeConflict() async throws {
    let client = try makeClient(.returning(statusCode: 409))
    await expectUnexpectedResponse(statusCode: 409) {
      _ = try await client.removeSpaceUser(spaceId: 55, userId: 11)
    }
  }

  @Test("remove 404 throws notFound")
  func removeNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await #expect(throws: KaitenError.self) {
      _ = try await client.removeSpaceUser(spaceId: 55, userId: 999)
    }
  }
}
