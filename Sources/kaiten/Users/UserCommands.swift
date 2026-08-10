import ArgumentParser
import KaitenSDK

struct ListUsers: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list-users",
    abstract: "List users in the company"
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "Type of users to return")
  var type: String?

  @Option(name: .long, help: "Search query")
  var query: String?

  @Option(name: .long, help: "Comma-separated user IDs")
  var ids: String?

  @Option(name: .long, help: "Limit the number of users returned (max 100)")
  var limit: Int?

  @Option(name: .long, help: "Offset for pagination")
  var offset: Int?

  @Flag(name: .long, help: "Include inactive users")
  var includeInactive: Bool = false

  func run() async throws {
    let client = try await global.makeClient()
    let users = try await client.listUsers(
      type: type,
      query: query,
      ids: ids,
      limit: limit,
      offset: offset,
      includeInactive: includeInactive ? true : nil
    )
    try printJSON(users, expand: global.expandedFields)
  }
}

struct UpdateUser: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "update-user",
    abstract: "Update a user by ID",
    discussion: "The API requires at least one field to update and answers HTTP 400 otherwise."
  )

  @OptionGroup var global: GlobalOptions

  @Option(name: .long, help: "User ID")
  var id: Int

  @Option(name: .long, help: "Username for mentions and login")
  var username: String?

  @Option(name: .long, help: "Full name (1-128 characters)")
  var fullName: String?

  @Option(name: .long, help: "Initials (exactly 2 characters)")
  var initials: String?

  @Option(name: .long, help: "Avatar type: 1 = gravatar, 2 = initials, 3 = uploaded")
  var avatarType: Int?

  @Option(name: .long, help: "New password (at least 6 characters)")
  var password: String?

  @Option(name: .long, help: "Old password (at least 6 characters)")
  var oldPassword: String?

  @Option(name: .long, help: "Interface language")
  var lng: String?

  @Option(name: .long, help: "Default space ID")
  var defaultSpaceId: Int?

  @Option(name: .long, help: "Interface color theme: light, dark, auto")
  var theme: String?

  @Option(name: .long, help: "Email notification frequency: 1 = never, 2 = instantly")
  var emailFrequency: Int?

  @Option(name: .long, help: "Time zone")
  var timezone: String?

  @Option(name: .long, help: "Email subject format: 1 = id and title, 2 = action")
  var subjectBy: Int?

  @Option(name: .long, help: "Email settings as a JSON object")
  var emailSettings: String?

  @Option(name: .long, help: "Telegram settings as a JSON object")
  var telegramSettings: String?

  @Option(name: .long, help: "Slack settings as a JSON object")
  var slackSettings: String?

  @Option(
    name: .long,
    help: "Comma-separated notification channels: inner, mobile_app, email, slack, telegram")
  var notificationEnabledChannels: String?

  @Option(name: .long, help: "Notification settings as a JSON object")
  var notificationSettings: String?

  @Option(name: .long, help: "User interface version: 1 = old UI, 2 = new UI")
  var uiVersion: Int?

  func run() async throws {
    let parsedEmailSettings = try parseAutomationJSON(
      emailSettings,
      as: Components.Schemas.UpdateUserRequest.email_settingsPayload.self,
      fieldName: "email-settings")
    let parsedTelegramSettings = try parseAutomationJSON(
      telegramSettings,
      as: Components.Schemas.UpdateUserRequest.telegram_settingsPayload.self,
      fieldName: "telegram-settings")
    let parsedSlackSettings = try parseAutomationJSON(
      slackSettings,
      as: Components.Schemas.UpdateUserRequest.slack_settingsPayload.self,
      fieldName: "slack-settings")
    let parsedNotificationSettings = try parseAutomationJSON(
      notificationSettings,
      as: Components.Schemas.UpdateUserRequest.notification_settingsPayload.self,
      fieldName: "notification-settings")
    let channels = notificationEnabledChannels.map { raw in
      raw.split(separator: ",").map { UserNotificationChannel(rawValue: String($0)) }
    }

    let client = try await global.makeClient()
    let user = try await client.updateUser(
      id: id,
      username: username,
      fullName: fullName,
      initials: initials,
      avatarType: avatarType.map(UserAvatarType.init(rawValue:)),
      password: password,
      oldPassword: oldPassword,
      lng: lng,
      defaultSpaceId: defaultSpaceId,
      theme: theme.map(UserTheme.init(rawValue:)),
      emailFrequency: emailFrequency.map(UserEmailFrequency.init(rawValue:)),
      timezone: timezone,
      subjectBy: subjectBy.map(UserEmailSubject.init(rawValue:)),
      emailSettings: parsedEmailSettings,
      telegramSettings: parsedTelegramSettings,
      slackSettings: parsedSlackSettings,
      notificationEnabledChannels: channels,
      notificationSettings: parsedNotificationSettings,
      uiVersion: uiVersion.map(UserUiVersion.init(rawValue:))
    )
    try printJSON(user, expand: global.expandedFields)
  }
}

struct GetCurrentUser: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "get-current-user",
    abstract: "Get the currently authenticated user"
  )

  @OptionGroup var global: GlobalOptions

  func run() async throws {
    let client = try await global.makeClient()
    let user = try await client.getCurrentUser()
    try printJSON(user, expand: global.expandedFields)
  }
}
