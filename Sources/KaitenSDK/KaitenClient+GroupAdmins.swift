import Foundation
import OpenAPIRuntime

// MARK: - Group Admins

extension KaitenClient {
  /// Lists the admins of a group.
  ///
  /// - Parameter groupUid: The group UID.
  /// - Returns: An array of group admins. Returns an empty array if the group has no admins.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403), not found (404)
  ///     or other undocumented HTTP status codes. A 404 is reported as `unexpectedResponse` rather
  ///     than ``KaitenError/notFound(resource:id:)`` because groups are addressed by string UID,
  ///     which that case cannot represent.
  public func listGroupAdmins(groupUid: String) async throws(KaitenError) -> [Components.Schemas
    .GroupAdmin]
  {
    guard
      let response = try await callList({
        try await client.list_group_admins(path: .init(group_uid: groupUid))
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Adds a user as an admin of a group.
  ///
  /// - Parameters:
  ///   - groupUid: The group UID.
  ///   - userId: The identifier of the user to make a group admin.
  /// - Returns: The added group admin.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for validation errors (400),
  ///     unsupported tariff (402), forbidden (403), not found (404) or other undocumented HTTP
  ///     status codes. A 404 is reported as `unexpectedResponse` rather than
  ///     ``KaitenError/notFound(resource:id:)`` because groups are addressed by string UID,
  ///     which that case cannot represent.
  public func addGroupAdmin(groupUid: String, userId: Int) async throws(KaitenError)
    -> Components
    .Schemas.GroupAdmin
  {
    let response = try await call {
      try await client.add_group_admin(
        path: .init(group_uid: groupUid),
        body: .json(.init(user_id: userId))
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Removes an admin from a group.
  ///
  /// - Parameters:
  ///   - groupUid: The group UID.
  ///   - userId: The identifier of the admin to remove.
  /// - Returns: The removed group admin.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for unsupported tariff (402),
  ///     forbidden (403), not found (404) or other undocumented HTTP status codes. A 404 is
  ///     reported as `unexpectedResponse` rather than ``KaitenError/notFound(resource:id:)``
  ///     because the group is addressed by string UID and the response does not say whether the
  ///     group or the user is missing.
  public func removeGroupAdmin(groupUid: String, userId: Int) async throws(KaitenError)
    -> Components.Schemas.GroupAdmin
  {
    let response = try await call {
      try await client.remove_group_admin(
        path: .init(group_uid: groupUid, user_id: userId)
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }
}
