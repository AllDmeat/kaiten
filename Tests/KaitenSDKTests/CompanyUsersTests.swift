import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("CompanyUsers")
struct CompanyUsersTests {

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

  /// A full company user as the get-list-of-users documentation describes it. The live
  /// endpoint could not be verified (the verification token lacks access to the "Members"
  /// administrative section), so the fixture follows the documented schema with invented values.
  private static let companyUserJSON = """
    {
      "id": 101,
      "uid": "fake-user-uid-1",
      "full_name": "Jane Doe",
      "email": "jane.doe@example.com",
      "avatar_initials_url": "https://example.kaiten.ru/avatars/jd.png",
      "avatar_uploaded_url": null,
      "initials": "JD",
      "avatar_type": 2,
      "lng": "en",
      "timezone": "UTC",
      "theme": "auto",
      "updated": "2024-01-02T03:04:05.678Z",
      "created": "2023-01-02T03:04:05.678Z",
      "activated": true,
      "ui_version": 2,
      "virtual": false,
      "email_blocked": null,
      "email_blocked_reason": null,
      "delete_requested_at": null,
      "permissions": 1024,
      "own_permissions": 1024,
      "user_id": 101,
      "company_id": 7,
      "default_space_id": null,
      "role": 2,
      "email_frequency": 2,
      "email_settings": {"deadlines": true, "subject_by": 1},
      "slack_id": null,
      "slack_settings": null,
      "notification_settings": {"card_add": ["inner", "email"], "card_move": []},
      "notification_enabled_channels": ["inner", "email"],
      "slack_private_channel_id": null,
      "telegram_sd_bot_enabled": false,
      "apps_permissions": 5,
      "invite_last_sent_at": "2023-01-02T03:04:05.678Z",
      "external": false,
      "last_request_date": "2024-05-06T07:08:09.101Z",
      "last_request_method": "GET",
      "work_time_settings": {"work_days": [1, 2, 3, 4, 5], "hours_count": 8},
      "personal_settings": {"current_card_view_id": "fake-view-uid-1"},
      "locked": false,
      "take_licence": true,
      "spaces": [{
        "id": 11,
        "uid": "fake-space-uid-1",
        "title": "Demo space",
        "external_id": null,
        "company_id": 7,
        "path": "11",
        "sort_order": 1.5,
        "parent_entity_uid": null,
        "archived": false,
        "access": "private",
        "for_everyone_access_role_id": "3",
        "entity_uid": "fake-entity-uid-1",
        "user_id": 101,
        "access_mod": "direct",
        "role": "3"
      }],
      "groups": {
        "updated": "2024-01-02T03:04:05.678Z",
        "created": "2023-01-02T03:04:05.678Z",
        "id": 5,
        "uid": "fake-group-uid-1",
        "name": "Engineers",
        "permissions": 0,
        "company_id": 7,
        "add_to_cards_and_spaces_enabled": true,
        "user_id": 101,
        "group_id": 5,
        "spaces": [{"id": 11}]
      }
    }
    """

  // MARK: - List

  @Test("200 returns array of CompanyUser")
  func listSuccess() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: "[\(Self.companyUserJSON)]"))

    let users = try await client.listCompanyUsers()
    #expect(users.count == 1)
    let user = try #require(users.first)
    #expect(user.id == 101)
    #expect(user.full_name == "Jane Doe")
    #expect(user.avatar_uploaded_url == nil)
    #expect(user.email_blocked == nil)
    #expect(user.default_space_id == nil)
    #expect(user.role == 2)
    #expect(user.apps_permissions == 5)
    #expect(user.email_settings?.deadlines == true)
    #expect(user.email_settings?.subject_by == 1)
    #expect(user.notification_settings?.card_add == ["inner", "email"])
    #expect(user.notification_enabled_channels == ["inner", "email"])
    #expect(user.work_time_settings?.work_days == [1, 2, 3, 4, 5])
    #expect(user.work_time_settings?.hours_count == 8)
    #expect(user.personal_settings?.current_card_view_id == "fake-view-uid-1")
    #expect(user.take_licence == true)
    #expect(user.spaces?.first?.title == "Demo space")
    #expect(user.spaces?.first?.sort_order == 1.5)
    #expect(user.spaces?.first?.role == "3")
    #expect(user.groups?.name == "Engineers")
    #expect(user.groups?.spaces?.count == 1)
  }

  /// The user serializer returns explicit JSON `null` for settings objects the documentation
  /// declares as non-nullable; plain optional `$ref` properties must decode that to `nil`.
  @Test("null settings objects decode to nil")
  func listNullSettings() async throws {
    let json = """
      [{"id": 102, "email_settings": null, "personal_settings": null, "slack_settings": null}]
      """
    let client = try makeClient(.returning(statusCode: 200, body: json))

    let users = try await client.listCompanyUsers()
    #expect(users.count == 1)
    #expect(users[0].id == 102)
    #expect(users[0].email_settings == nil)
    #expect(users[0].personal_settings == nil)
    #expect(users[0].slack_settings == nil)
  }

  @Test("200 with empty body returns empty array")
  func listEmptyBody() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: ""))
    let users = try await client.listCompanyUsers()
    #expect(users.isEmpty)
  }

  @Test("list sends all query parameters")
  func listSendsQueryParameters() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: "[]")
    let client = try makeClient(transport)

    _ = try await client.listCompanyUsers(
      invitesOnly: true,
      withTransferAccessStatus: true,
      forMembersSection: true,
      ownerOnly: true,
      onlyPaid: true,
      onlyRecordsCount: true,
      onlyVirtual: true,
      offset: 20,
      limit: 10,
      query: "jane",
      accessTypePermissions: "full",
      sdAccessType: "none",
      takeLicence: "true",
      temporarilyInactiveStatus: "active",
      groupIds: [5, 6],
      permissions: [1, 4]
    )

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .get)
    let path = try #require(recorded.request.path)
    #expect(path.hasPrefix("/company/users?"))
    for expected in [
      "invitesOnly=true", "withTransferAccessStatus=true", "for_members_section=true",
      "owner_only=true", "only_paid=true", "only_records_count=true", "only_virtual=true",
      "offset=20", "limit=10", "query=jane", "access_type_permissions=full",
      "sd_access_type=none", "take_licence=true", "temporarily_inactive_status=active",
      "group_ids=5", "group_ids=6", "permissions=1", "permissions=4",
    ] {
      #expect(path.contains(expected), "missing \(expected) in \(path)")
    }
  }

  @Test("401 throws unauthorized")
  func listUnauthorized() async throws {
    let client = try makeClient(.returning(statusCode: 401))
    await #expect(throws: KaitenError.self) {
      _ = try await client.listCompanyUsers()
    }
  }

  @Test("403 throws unexpectedResponse")
  func listForbidden() async throws {
    let client = try makeClient(.returning(statusCode: 403))
    await expectUnexpectedResponse(statusCode: 403) {
      _ = try await client.listCompanyUsers()
    }
  }

  // MARK: - Update

  @Test("update sends PATCH with body and parses the response")
  func updateSuccess() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: Self.companyUserJSON)
    let client = try makeClient(transport)

    let user = try await client.updateCompanyUser(
      id: 101, appsPermissions: 0, temporarilyInactive: true)

    #expect(user.id == 101)
    #expect(user.email == "jane.doe@example.com")

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .patch)
    #expect(recorded.request.path == "/company/users/101")

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["apps_permissions"] as? Int == 0)
    #expect(sent["temporarily_inactive"] as? Bool == true)
  }

  @Test("update 400 throws unexpectedResponse")
  func updateBadRequest() async throws {
    let client = try makeClient(.returning(statusCode: 400, body: #"{"message": "bad"}"#))
    await expectUnexpectedResponse(statusCode: 400) {
      _ = try await client.updateCompanyUser(id: 1, appsPermissions: 99)
    }
  }

  @Test("update 404 throws notFound")
  func updateNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    do {
      _ = try await client.updateCompanyUser(id: 999, temporarilyInactive: false)
      Issue.record("expected KaitenError.notFound, no error thrown")
    } catch let error as KaitenError {
      guard case .notFound(let resource, let id) = error else {
        Issue.record("expected KaitenError.notFound, got \(error)")
        return
      }
      #expect(resource == "user")
      #expect(id == 999)
    } catch {
      Issue.record("expected KaitenError, got \(error)")
    }
  }

  // MARK: - Remove

  @Test("remove sends DELETE and returns the deleted user id")
  func removeSuccess() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: #"{"id": 101}"#)
    let client = try makeClient(transport)

    let deletedId = try await client.removeVirtualUser(id: 101)
    #expect(deletedId == 101)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .delete)
    #expect(recorded.request.path == "/company/users/101")
  }

  @Test("remove 404 throws notFound")
  func removeNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await #expect(throws: KaitenError.self) {
      _ = try await client.removeVirtualUser(id: 999)
    }
  }

  @Test("remove 403 throws unexpectedResponse")
  func removeForbidden() async throws {
    let client = try makeClient(.returning(statusCode: 403))
    await expectUnexpectedResponse(statusCode: 403) {
      _ = try await client.removeVirtualUser(id: 1)
    }
  }
}
