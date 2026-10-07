import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("ListUsers")
struct ListUsersTests {

  @Test("200 returns array of users")
  func success() async throws {
    let json = """
      [{"id": 1, "uid": "abc-123", "full_name": "Test User", "email": "test@example.com", "username": "testuser", "activated": true, "role": 2, "company_id": 1, "user_id": 1, "external": false, "virtual": false}]
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let users = try await client.listUsers()
    #expect(users.count == 1)
    #expect(users[0].full_name == "Test User")
  }

  @Test("list sends the entity and access filters")
  func sendsFilters() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: "[]")
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    _ = try await client.listUsers(
      includeInactive: true,
      accessTypePermissions: "member",
      excludeMembersByEntityUid: "space-uid-1",
      excludeDirectlyAddedMembersByEntityUid: "space-uid-2"
    )

    let recorded = try #require(transport.recordedRequests.first)
    let path = try #require(recorded.request.path)
    #expect(path.hasPrefix("/users?"))
    for expected in [
      "include_inactive=true", "access_type_permissions=member",
      "exclude_members_by_entity_uid=space-uid-1",
      "exclude_directly_added_members_by_entity_uid=space-uid-2",
    ] {
      #expect(path.contains(expected), "missing \(expected) in \(path)")
    }
  }

  @Test("allUsers forwards the filters to every page")
  func allUsersForwardsFilters() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: "[]")
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    for try await _ in client.allUsers(
      accessTypePermissions: "guest",
      excludeMembersByEntityUid: "space-uid-1",
      excludeDirectlyAddedMembersByEntityUid: "space-uid-2"
    ) {}

    let path = try #require(transport.recordedRequests.first?.request.path)
    for expected in [
      "access_type_permissions=guest", "exclude_members_by_entity_uid=space-uid-1",
      "exclude_directly_added_members_by_entity_uid=space-uid-2",
    ] {
      #expect(path.contains(expected), "missing \(expected) in \(path)")
    }
  }

  @Test("200 decodes settings, permissions and live-only fields")
  func decodesFullUser() async throws {
    let json = """
      [{
        "id": 7, "uid": "user-uid-7", "full_name": "Test User",
        "default_space_id": null, "permissions": 1024, "own_permissions": 1024,
        "email_frequency": 2, "apps_permissions": 5,
        "email_settings": null,
        "slack_id": "U0TEST", "slack_settings": {"channel": "c"}, "slack_private_channel_id": "D0TEST",
        "notification_settings": {"card_add": ["inner", "email"]},
        "notification_enabled_channels": ["inner", "email"],
        "telegram_sd_bot_enabled": false, "invite_last_sent_at": null,
        "last_request_date": "2026-01-01T00:00:00.000Z", "last_request_method": "GET",
        "locked": false, "temporarily_inactive": false, "depersonalized_at": null,
        "beta_features": [{"name": "feature", "enabled": true}],
        "chat_settings": null, "personal_settings": {"key": "value"},
        "work_calendar_id": null,
        "work_time_settings": {"work_days": [1, 2, 3, 4, 5], "hours_count": 8},
        "named_permissions": {"tags": true}, "own_named_permissions": {"tags": false},
        "max_messenger_sd_bot_enabled": false
      }]
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let user = try #require(try await client.listUsers().first)
    #expect(user.default_space_id == nil)
    #expect(user.permissions == 1024)
    #expect(user.own_permissions == 1024)
    #expect(user.email_frequency == 2)
    #expect(user.apps_permissions == 5)
    #expect(user.email_settings == nil)
    #expect(user.slack_id == "U0TEST")
    #expect(user.slack_private_channel_id == "D0TEST")
    #expect(user.slack_settings?.additionalProperties.value["channel"] as? String == "c")
    #expect(user.notification_settings?.additionalProperties.value["card_add"] != nil)
    #expect(user.notification_enabled_channels == ["inner", "email"])
    #expect(user.telegram_sd_bot_enabled == false)
    #expect(user.invite_last_sent_at == nil)
    #expect(user.last_request_method == "GET")
    #expect(user.locked == false)
    #expect(user.temporarily_inactive == false)
    #expect(user.beta_features?.count == 1)
    #expect(user.personal_settings?.additionalProperties.value["key"] as? String == "value")
    #expect(user.work_time_settings?.work_days == [1, 2, 3, 4, 5])
    #expect(user.work_time_settings?.hours_count == 8)
    #expect(user.named_permissions?.additionalProperties.value["tags"] as? Bool == true)
    #expect(user.own_named_permissions?.additionalProperties.value["tags"] as? Bool == false)
    #expect(user.max_messenger_sd_bot_enabled == false)
  }

  @Test("401 throws unauthorized")
  func unauthorized() async throws {
    let transport = MockClientTransport.returning(statusCode: 401)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.listUsers()
    }
  }
}
