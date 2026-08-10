import Foundation
import OpenAPIRuntime

// MARK: - Users

extension KaitenClient {
  /// Lists users in the company.
  ///
  /// - Parameters:
  ///   - type: Type of users to return.
  ///   - query: Search query.
  ///   - ids: Comma-separated user IDs.
  ///   - limit: Maximum number of users (max 100).
  ///   - offset: Pagination offset.
  ///   - includeInactive: Include inactive users.
  /// - Returns: An array of users.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for undocumented HTTP status codes.
  public func listUsers(
    type: String? = nil,
    query: String? = nil,
    ids: String? = nil,
    limit: Int? = nil,
    offset: Int? = nil,
    includeInactive: Bool? = nil
  ) async throws(KaitenError) -> [Components.Schemas.User] {
    guard
      let response = try await callList({
        try await client.retrieve_list_of_users(
          query: .init(
            _type: type,
            query: query,
            ids: ids,
            limit: limit,
            offset: offset,
            include_inactive: includeInactive
          )
        )
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Retrieves the currently authenticated user.
  ///
  /// - Returns: The current user.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for undocumented HTTP status codes.
  public func getCurrentUser() async throws(KaitenError) -> Components.Schemas.User {
    let response = try await call { try await client.retrieve_current_user() }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Updates a user.
  ///
  /// All fields are optional — only set values are changed. The API requires
  /// at least one field in the request and answers HTTP 400 otherwise.
  ///
  /// - Parameters:
  ///   - id: The user identifier.
  ///   - username: Username for mentions and login.
  ///   - fullName: Full name (1–128 characters).
  ///   - initials: Initials (exactly 2 characters).
  ///   - avatarType: Avatar type.
  ///   - password: New password (at least 6 characters).
  ///   - oldPassword: Old password (at least 6 characters).
  ///   - lng: Interface language.
  ///   - defaultSpaceId: Default space identifier.
  ///   - theme: Interface color theme.
  ///   - emailFrequency: Email notification frequency.
  ///   - timezone: Time zone.
  ///   - subjectBy: Email notification subject format.
  ///   - emailSettings: Email settings. The documentation does not describe the fields.
  ///   - telegramSettings: Telegram settings. The documentation does not describe the fields.
  ///   - slackSettings: Slack settings. The documentation does not describe the fields.
  ///   - notificationEnabledChannels: Channels enabled for notifications.
  ///   - notificationSettings: Channel lists where notifications for specified events
  ///     should be sent. The documentation does not describe the fields.
  ///   - uiVersion: User interface version.
  /// - Returns: The updated user.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the user does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for validation errors (400),
  ///     forbidden (403) or other undocumented HTTP status codes.
  public func updateUser(
    id: Int,
    username: String? = nil,
    fullName: String? = nil,
    initials: String? = nil,
    avatarType: UserAvatarType? = nil,
    password: String? = nil,
    oldPassword: String? = nil,
    lng: String? = nil,
    defaultSpaceId: Int? = nil,
    theme: UserTheme? = nil,
    emailFrequency: UserEmailFrequency? = nil,
    timezone: String? = nil,
    subjectBy: UserEmailSubject? = nil,
    emailSettings: Components.Schemas.UpdateUserRequest.email_settingsPayload? = nil,
    telegramSettings: Components.Schemas.UpdateUserRequest.telegram_settingsPayload? = nil,
    slackSettings: Components.Schemas.UpdateUserRequest.slack_settingsPayload? = nil,
    notificationEnabledChannels: [UserNotificationChannel]? = nil,
    notificationSettings: Components.Schemas.UpdateUserRequest.notification_settingsPayload? = nil,
    uiVersion: UserUiVersion? = nil
  ) async throws(KaitenError) -> Components.Schemas.UpdateUserResponse {
    let body = Components.Schemas.UpdateUserRequest(
      username: username,
      full_name: fullName,
      initials: initials,
      avatar_type: avatarType?.rawValue,
      password: password,
      old_password: oldPassword,
      lng: lng,
      default_space_id: defaultSpaceId,
      theme: theme?.rawValue,
      email_frequency: emailFrequency?.rawValue,
      timezone: timezone,
      subject_by: subjectBy?.rawValue,
      email_settings: emailSettings,
      telegram_settings: telegramSettings,
      slack_settings: slackSettings,
      notification_enabled_channels: notificationEnabledChannels?.map(\.rawValue),
      notification_settings: notificationSettings,
      ui_version: uiVersion?.rawValue
    )
    let response = try await call {
      try await client.update_user(path: .init(id: id), body: .json(body))
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("user", id)) { try $0.json }
  }
}
