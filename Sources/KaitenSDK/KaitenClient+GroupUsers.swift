import Foundation
import OpenAPIRuntime

// MARK: - Group Users

extension KaitenClient {
  /// Lists users that belong to a company group.
  ///
  /// - Parameter groupUid: The group UID.
  /// - Returns: An array of group users. Returns an empty array if the group has no users.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403), not found (404)
  ///     or other undocumented HTTP status codes. A 404 is reported as `unexpectedResponse` rather
  ///     than ``KaitenError/notFound(resource:id:)`` because groups are addressed by string UID.
  public func listGroupUsers(groupUid: String) async throws(KaitenError) -> [Components.Schemas
    .GroupUser]
  {
    guard
      let response = try await callList({
        try await client.list_group_users(path: .init(group_uid: groupUid))
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Adds a user to a company group.
  ///
  /// - Parameters:
  ///   - groupUid: The group UID.
  ///   - userId: The identifier of the user to add.
  ///   - requestId: Request id if the addition to the group is an answer to an access request.
  ///   - operatorComment: Operator's comment if the addition to the group is an answer to an
  ///     access request. Kaiten accepts 1 to 1024 characters.
  /// - Returns: The added user.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for validation error (400),
  ///     unsupported tariff (402), forbidden (403), not found (404) or other undocumented HTTP
  ///     status codes. A 404 is reported as `unexpectedResponse` rather than
  ///     ``KaitenError/notFound(resource:id:)`` because groups are addressed by string UID.
  public func addUserToGroup(
    groupUid: String,
    userId: Int,
    requestId: String? = nil,
    operatorComment: String? = nil
  ) async throws(KaitenError) -> Components.Schemas.GroupUser {
    let response = try await call {
      try await client.add_user_to_group(
        path: .init(group_uid: groupUid),
        body: .json(
          .init(
            user_id: userId,
            request_id: requestId,
            operator_comment: operatorComment
          ))
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Removes a user from a company group.
  ///
  /// - Parameters:
  ///   - groupUid: The group UID.
  ///   - userId: The identifier of the user to remove.
  /// - Returns: The removed user.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for unsupported tariff (402),
  ///     forbidden (403), not found (404) or other undocumented HTTP status codes. A 404 is
  ///     reported as `unexpectedResponse` rather than ``KaitenError/notFound(resource:id:)``
  ///     because groups are addressed by string UID and the response does not say whether the
  ///     group or the user is missing.
  public func removeUserFromGroup(
    groupUid: String,
    userId: Int
  ) async throws(KaitenError) -> Components.Schemas.GroupUser {
    let response = try await call {
      try await client.remove_user_from_group(
        path: .init(group_uid: groupUid, user_id: userId)
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }
}
