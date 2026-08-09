import Foundation
import OpenAPIRuntime

// MARK: - Space Users

extension KaitenClient {
  /// Lists the users of a space.
  ///
  /// - Parameters:
  ///   - spaceId: The space identifier.
  ///   - includeInheritedAccess: Include users whose access is inherited from a parent entity.
  ///   - inactive: Return only members who are inactive in the company.
  /// - Returns: An array of space users. Returns an empty array if the space has no users.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the space does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func listSpaceUsers(
    spaceId: Int,
    includeInheritedAccess: Bool? = nil,
    inactive: Bool? = nil
  ) async throws(KaitenError) -> [Components.Schemas.SpaceUser] {
    guard
      let response = try await callList({
        try await client.list_space_users(
          path: .init(space_id: spaceId),
          query: .init(
            include_inherited_access: includeInheritedAccess,
            inactive: inactive
          )
        )
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("space", spaceId)) {
      try $0.json
    }
  }

  /// Invites a user to a space.
  ///
  /// - Parameters:
  ///   - spaceId: The space identifier.
  ///   - email: The email address of the user to invite.
  ///   - roleId: The role id. Preset roles: reader `06ccb31f-426b-4fa3-b7e5-861daee95696`,
  ///     writer `a431ed00-1b32-4cc7-92b6-85e4bc7de40e`, admin `07ea3efc-a004-4d31-8683-4bb2084e209b`.
  ///   - guest: Invite the user as a guest.
  ///   - operatorComment: The operator's comment.
  ///   - sendEmail: Whether to send an invitation email.
  /// - Returns: The invited user, the created access record and a success message.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the space does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for validation errors (400),
  ///     forbidden (403) or other undocumented HTTP status codes.
  public func inviteUserToSpace(
    spaceId: Int,
    email: String,
    roleId: String? = nil,
    guest: Bool? = nil,
    operatorComment: String? = nil,
    sendEmail: Bool? = nil
  ) async throws(KaitenError) -> Components.Schemas.InviteSpaceUserResponse {
    let response = try await call {
      try await client.invite_user_to_space(
        path: .init(space_id: spaceId),
        body: .json(
          .init(
            email: email,
            role_id: roleId,
            guest: guest,
            operator_comment: operatorComment,
            send_email: sendEmail
          ))
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("space", spaceId)) {
      try $0.json
    }
  }

  /// Retrieves a user of a space.
  ///
  /// - Parameters:
  ///   - spaceId: The space identifier.
  ///   - userId: The user identifier.
  /// - Returns: The space user with the access record fields.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the space or the user does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func getSpaceUser(spaceId: Int, userId: Int) async throws(KaitenError)
    -> Components.Schemas.SpaceUserDetails
  {
    let response = try await call {
      try await client.get_space_user(path: .init(space_id: spaceId, id: userId))
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("user", userId)) {
      try $0.json
    }
  }

  /// Changes a space user's role and notification settings.
  ///
  /// - Parameters:
  ///   - spaceId: The space identifier.
  ///   - userId: The user identifier.
  ///   - roleId: The role id. Preset roles: reader `06ccb31f-426b-4fa3-b7e5-861daee95696`,
  ///     writer `a431ed00-1b32-4cc7-92b6-85e4bc7de40e`, admin `07ea3efc-a004-4d31-8683-4bb2084e209b`.
  ///   - notificationsEnabled: Enable or disable notifications for space events.
  ///   - spaceGroupId: The space group id.
  ///   - settings: Space user settings. The shape is not described in the Kaiten documentation.
  /// - Returns: The updated access record.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the space or the user does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for validation errors (400),
  ///     forbidden (403) or other undocumented HTTP status codes.
  public func updateSpaceUser(
    spaceId: Int,
    userId: Int,
    roleId: String? = nil,
    notificationsEnabled: Bool? = nil,
    spaceGroupId: Double? = nil,
    settings: Components.Schemas.UpdateSpaceUserRequest.settingsPayload? = nil
  ) async throws(KaitenError) -> Components.Schemas.UpdateSpaceUserResponse {
    let response = try await call {
      try await client.update_space_user(
        path: .init(space_id: spaceId, id: userId),
        body: .json(
          .init(
            role_id: roleId,
            notifications_enabled: notificationsEnabled,
            space_group_id: spaceGroupId,
            settings: settings
          ))
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("user", userId)) {
      try $0.json
    }
  }

  /// Removes a user from a space.
  ///
  /// - Parameters:
  ///   - spaceId: The space identifier.
  ///   - userId: The user identifier.
  /// - Returns: The removal confirmation carrying the removed access record.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the space or the user does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403), conflict (409)
  ///     or other undocumented HTTP status codes.
  public func removeSpaceUser(spaceId: Int, userId: Int) async throws(KaitenError)
    -> Components.Schemas.RemoveSpaceUserResponse
  {
    let response = try await call {
      try await client.remove_space_user(path: .init(space_id: spaceId, id: userId))
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("user", userId)) {
      try $0.json
    }
  }
}
