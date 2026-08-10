import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("UpdateUser")
struct UpdateUserTests {

  /// Based on the documentation's 200 example response (sanitized).
  /// `sd_telegram_id`, `email_settings` and `telegram_id` are null there even
  /// though the attribute table declares them non-nullable, and `show_tour` is
  /// present without being documented at all.
  private let userJSON = """
    {
      "created": "2022-10-14T12:52:19.462Z",
      "updated": "2022-10-19T12:12:03.016Z",
      "id": 42,
      "full_name": "Test User",
      "username": "testuser",
      "email": "user@example.com",
      "activated": true,
      "show_tour": true,
      "avatar_initials_url": "data:image/png;base64,AAAA",
      "avatar_uploaded_url": "https://files.example.com/avatar-1.png",
      "initials": "TU",
      "avatar_type": 3,
      "lng": "en",
      "sd_telegram_id": null,
      "timezone": "UTC",
      "news_subscription": false,
      "theme": "auto",
      "ui_version": 2,
      "default_space_id": 1,
      "email_frequency": 2,
      "email_settings": null,
      "work_time_settings": {"work_days": [0, 1, 2, 3, 4], "hours_count": 8},
      "telegram_id": null,
      "telegram_settings": {},
      "has_password": true
    }
    """

  private func makeClient(_ transport: MockClientTransport) throws -> KaitenClient {
    try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)
  }

  @Test("200 returns updated user")
  func success() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: userJSON)
    let client = try makeClient(transport)

    let user = try await client.updateUser(id: 42, fullName: "Test User")
    #expect(user.id == 42)
    #expect(user.full_name == "Test User")
    #expect(user.username == "testuser")
    #expect(user.avatar_type == 3)
    #expect(user.sd_telegram_id == nil)
    #expect(user.email_settings == nil)
    #expect(user.telegram_id == nil)
    #expect(user.theme == "auto")
    #expect(user.default_space_id == 1)
    #expect(user.email_frequency == 2)
    #expect(user.work_time_settings?.hours_count == 8)
    #expect(user.work_time_settings?.work_days == [0, 1, 2, 3, 4])
    #expect(user.has_password == true)
  }

  @Test("request body encodes enum raw values and omits unset fields")
  func requestBodyEncoding() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: userJSON)
    let client = try makeClient(transport)

    _ = try await client.updateUser(
      id: 42,
      avatarType: .initials,
      theme: .dark,
      emailFrequency: .never,
      subjectBy: .action,
      notificationEnabledChannels: [.inner, .mobileApp],
      uiVersion: .newUi
    )

    let req = try #require(transport.recordedRequests.first)
    let bodyData = try await Data(collecting: #require(req.body), upTo: 1024 * 1024)
    let json = try #require(
      try JSONSerialization.jsonObject(with: bodyData) as? [String: Any])
    #expect(json["avatar_type"] as? Int == 2)
    #expect(json["theme"] as? String == "dark")
    #expect(json["email_frequency"] as? Int == 1)
    #expect(json["subject_by"] as? Int == 2)
    #expect(json["notification_enabled_channels"] as? [String] == ["inner", "mobile_app"])
    #expect(json["ui_version"] as? Int == 2)
    #expect(json["username"] == nil)
    #expect(json["password"] == nil)
  }

  @Test("user enums round-trip and map unknown values")
  func enumRoundTrip() {
    for c in UserAvatarType.allCases { #expect(UserAvatarType(rawValue: c.rawValue) == c) }
    for c in UserTheme.allCases { #expect(UserTheme(rawValue: c.rawValue) == c) }
    for c in UserEmailFrequency.allCases { #expect(UserEmailFrequency(rawValue: c.rawValue) == c) }
    for c in UserEmailSubject.allCases { #expect(UserEmailSubject(rawValue: c.rawValue) == c) }
    for c in UserUiVersion.allCases { #expect(UserUiVersion(rawValue: c.rawValue) == c) }
    for c in UserNotificationChannel.allCases {
      #expect(UserNotificationChannel(rawValue: c.rawValue) == c)
    }
    #expect(UserAvatarType(rawValue: 999) == .unknown(999))
    #expect(UserTheme(rawValue: "sepia") == .unknown("sepia"))
    #expect(UserNotificationChannel(rawValue: "pager") == .unknown("pager"))
  }

  @Test("404 throws notFound")
  func notFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try makeClient(transport)

    let operation: () async throws -> Void = {
      _ = try await client.updateUser(id: 999, fullName: "x")
    }
    do {
      try await operation()
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

  @Test("401 throws unauthorized")
  func unauthorized() async throws {
    let transport = MockClientTransport.returning(statusCode: 401)
    let client = try makeClient(transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.updateUser(id: 1, fullName: "x")
    }
  }

  @Test("400 throws unexpectedResponse")
  func badRequest() async throws {
    let transport = MockClientTransport.returning(
      statusCode: 400, body: #"{"message": "User should have required property '.username'"}"#)
    let client = try makeClient(transport)

    let operation: () async throws -> Void = {
      _ = try await client.updateUser(id: 1)
    }
    do {
      try await operation()
      Issue.record("expected KaitenError.unexpectedResponse, no error thrown")
    } catch let error as KaitenError {
      guard case .unexpectedResponse(let statusCode, _) = error, statusCode == 400 else {
        Issue.record("expected KaitenError.unexpectedResponse(400), got \(error)")
        return
      }
    } catch {
      Issue.record("expected KaitenError, got \(error)")
    }
  }
}
