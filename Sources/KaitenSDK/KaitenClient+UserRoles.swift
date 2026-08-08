import Foundation
import OpenAPIRuntime

// MARK: - User Roles

extension KaitenClient {
  /// Lists all user roles in the company.
  ///
  /// - Returns: An array of user roles. Returns an empty array if the company has no roles.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other
  ///     undocumented HTTP status codes.
  public func listUserRoles() async throws(KaitenError) -> [Components.Schemas.UserRole] {
    guard
      let response = try await callList({
        try await client.list_user_roles()
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Creates a user role.
  ///
  /// - Parameter name: The role name. Kaiten accepts 1 to 64 characters.
  /// - Returns: The created user role.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for validation error (400),
  ///     forbidden (403) or other undocumented HTTP status codes.
  public func createUserRole(name: String) async throws(KaitenError) -> Components.Schemas.UserRole
  {
    let response = try await call {
      try await client.create_user_role(body: .json(.init(name: name)))
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Gets a single user role.
  ///
  /// - Parameter id: The role identifier.
  /// - Returns: The user role.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the role does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other
  ///     undocumented HTTP status codes.
  public func getUserRole(id: Int) async throws(KaitenError) -> Components.Schemas.UserRole {
    let response = try await call {
      try await client.get_user_role(path: .init(role_id: id))
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("userRole", id)) {
      try $0.json
    }
  }

  /// Updates a user role.
  ///
  /// - Parameters:
  ///   - id: The role identifier.
  ///   - name: The updated role name. Kaiten accepts 1 to 64 characters.
  /// - Returns: The updated user role.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the role does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for validation error (400),
  ///     forbidden (403) or other undocumented HTTP status codes.
  public func updateUserRole(id: Int, name: String) async throws(KaitenError)
    -> Components.Schemas
    .UserRole
  {
    let response = try await call {
      try await client.update_user_role(path: .init(role_id: id), body: .json(.init(name: name)))
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("userRole", id)) {
      try $0.json
    }
  }

  /// Deletes a user role.
  ///
  /// Users holding the deleted role are moved to the replacement role.
  ///
  /// - Parameters:
  ///   - id: The role identifier.
  ///   - replaceRoleId: The identifier of the role that replaces the deleted one.
  /// - Returns: The deleted user role.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the role does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other
  ///     undocumented HTTP status codes.
  @discardableResult
  public func deleteUserRole(id: Int, replaceRoleId: Int) async throws(KaitenError)
    -> Components.Schemas.UserRole
  {
    let response = try await call {
      try await client.delete_user_role(
        path: .init(role_id: id), body: .json(.init(replace_role_id: replaceRoleId)))
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("userRole", id)) {
      try $0.json
    }
  }
}
