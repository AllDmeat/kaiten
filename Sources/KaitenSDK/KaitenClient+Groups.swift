import Foundation
import OpenAPIRuntime

// MARK: - Groups

extension KaitenClient {
  /// Lists user groups in the company.
  ///
  /// The result is paginated only when `limit` or `offset` is present and
  /// `withTreeEntities` is `false`.
  ///
  /// - Parameters:
  ///   - withTreeEntities: Add tree entities for each group.
  ///   - withUsersCount: Add users count for each group.
  ///   - withSyncGroupAttribute: Add sync attribute for each group.
  ///   - condition: Optional group condition filter.
  ///   - query: Search query.
  ///   - limit: Maximum amount of records (default `100` on the server).
  ///   - offset: Number of records to skip.
  /// - Returns: An array of groups. Returns an empty array if the company has no groups.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403, the token lacks
  ///     access to the administrative section "Members"), not found (404) or other undocumented
  ///     HTTP status codes.
  public func listGroups(
    withTreeEntities: Bool? = nil,
    withUsersCount: Bool? = nil,
    withSyncGroupAttribute: Bool? = nil,
    condition: GroupCondition? = nil,
    query: String? = nil,
    limit: Int? = nil,
    offset: Int? = nil
  ) async throws(KaitenError) -> [Components.Schemas.Group] {
    guard
      let response = try await callList({
        try await client.list_groups(
          query: .init(
            with_tree_entities: withTreeEntities,
            with_users_count: withUsersCount,
            with_sync_group_attribute: withSyncGroupAttribute,
            condition: condition?.rawValue,
            query: query,
            limit: limit,
            offset: offset
          )
        )
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Creates a user group in the company.
  ///
  /// - Parameters:
  ///   - name: The group name (1 to 512 characters).
  ///   - permissions: The group permissions bit mask. To set several permissions, sum their
  ///     documented values.
  ///   - addToCardsAndSpacesEnabled: Ability to add all users of the group to cards placed in
  ///     group spaces.
  /// - Returns: The created group.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for bad request (400), unsupported
  ///     tariff (402), forbidden (403), not found (404) or other undocumented HTTP status codes.
  public func createGroup(
    name: String,
    permissions: Int? = nil,
    addToCardsAndSpacesEnabled: Bool? = nil
  ) async throws(KaitenError) -> Components.Schemas.Group {
    let response = try await call {
      try await client.create_group(
        body: .json(
          .init(
            name: name,
            permissions: permissions,
            add_to_cards_and_spaces_enabled: addToCardsAndSpacesEnabled
          ))
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Retrieves a user group.
  ///
  /// - Parameter uid: The group UID.
  /// - Returns: The group.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403), not found (404)
  ///     or other undocumented HTTP status codes. A 404 is reported as `unexpectedResponse` rather
  ///     than ``KaitenError/notFound(resource:id:)`` because groups are addressed by string UID.
  public func getGroup(uid: String) async throws(KaitenError) -> Components.Schemas.Group {
    let response = try await call {
      try await client.get_group(path: .init(uid: uid))
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Updates a user group.
  ///
  /// - Parameters:
  ///   - uid: The group UID.
  ///   - name: The updated group name (1 to 512 characters).
  ///   - permissions: The updated group permissions bit mask. To set several permissions, sum
  ///     their documented values.
  ///   - addToCardsAndSpacesEnabled: Ability to add all users of the group to cards placed in
  ///     group spaces.
  /// - Returns: The updated group.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for bad request (400), unsupported
  ///     tariff (402), forbidden (403), not found (404) or other undocumented HTTP status codes.
  ///     A 404 is reported as `unexpectedResponse` rather than
  ///     ``KaitenError/notFound(resource:id:)`` because groups are addressed by string UID.
  public func updateGroup(
    uid: String,
    name: String? = nil,
    permissions: Int? = nil,
    addToCardsAndSpacesEnabled: Bool? = nil
  ) async throws(KaitenError) -> Components.Schemas.Group {
    let response = try await call {
      try await client.update_group(
        path: .init(uid: uid),
        body: .json(
          .init(
            name: name,
            permissions: permissions,
            add_to_cards_and_spaces_enabled: addToCardsAndSpacesEnabled
          ))
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Removes a user group.
  ///
  /// - Parameter uid: The group UID.
  /// - Returns: The removed group.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403), not found (404)
  ///     or other undocumented HTTP status codes. A 404 is reported as `unexpectedResponse` rather
  ///     than ``KaitenError/notFound(resource:id:)`` because groups are addressed by string UID.
  public func removeGroup(uid: String) async throws(KaitenError) -> Components.Schemas.Group {
    let response = try await call {
      try await client.remove_group(path: .init(uid: uid))
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }
}
