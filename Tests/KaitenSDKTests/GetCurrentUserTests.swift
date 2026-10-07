import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("GetCurrentUser")
struct GetCurrentUserTests {

  @Test("200 returns current user")
  func success() async throws {
    let json = """
      {"id": 42, "uid": "def-456", "full_name": "Current User", "email": "me@example.com", "username": "me", "activated": true, "role": 1, "company_id": 1, "user_id": 42, "external": false, "virtual": false}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let user = try await client.getCurrentUser()
    #expect(user.id == 42)
    #expect(user.full_name == "Current User")
  }

  @Test("200 decodes current-user-only fields")
  func decodesCurrentUserFields() async throws {
    let json = """
      {
        "id": 42, "telegram_id": null, "telegram_settings": {"enabled": true},
        "has_password": true, "directory_synced_profile_fields": [],
        "max_messenger_id": null, "max_messenger_settings": {"enabled": false},
        "email_settings": {"deadlines": true, "subject_by": 1}
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let user = try await client.getCurrentUser()
    #expect(user.telegram_id == nil)
    #expect(user.telegram_settings?.additionalProperties.value["enabled"] as? Bool == true)
    #expect(user.has_password == true)
    #expect(user.directory_synced_profile_fields?.isEmpty == true)
    #expect(user.max_messenger_id == nil)
    #expect(user.max_messenger_settings?.additionalProperties.value["enabled"] as? Bool == false)
    #expect(user.email_settings?.deadlines == true)
    #expect(user.email_settings?.subject_by == 1)
  }

  @Test("401 throws unauthorized")
  func unauthorized() async throws {
    let transport = MockClientTransport.returning(statusCode: 401)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.getCurrentUser()
    }
  }
}
