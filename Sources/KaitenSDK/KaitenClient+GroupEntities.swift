import Foundation
import OpenAPIRuntime

// MARK: - Typed Discriminators

extension Components.Schemas.GroupEntityListItem {
  /// The entity type, or `nil` if the API omitted the field.
  public var groupEntityType: GroupEntityType? {
    entity_type.map(GroupEntityType.init(rawValue:))
  }
}

// MARK: - Group Entities

extension KaitenClient {
  /// Lists the entities (spaces, documents, folders and story maps) attached to a company group.
  ///
  /// - Parameter groupUid: The group UID.
  /// - Returns: An array of group entities. Returns an empty array if the group has none.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403), not found (404)
  ///     or other undocumented HTTP status codes. A 404 is reported as `unexpectedResponse` rather
  ///     than ``KaitenError/notFound(resource:id:)`` because groups are addressed by string UID,
  ///     which that case cannot represent.
  public func listGroupEntities(groupUid: String) async throws(KaitenError) -> [Components.Schemas
    .GroupEntityListItem]
  {
    guard
      let response = try await callList({
        try await client.list_group_entities(path: .init(group_uid: groupUid))
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Adds an entity to a company group.
  ///
  /// - Parameters:
  ///   - groupUid: The group UID.
  ///   - entityUid: The UID of the entity to add.
  ///   - roleIds: The role UIDs for the entity in the group. Kaiten requires at least one.
  /// - Returns: The group entity with its resolved roles and permissions.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for validation error (400),
  ///     unsupported tariff (402), forbidden (403), not found (404) or other undocumented HTTP
  ///     status codes.
  public func addGroupEntity(
    groupUid: String,
    entityUid: String,
    roleIds: [String]
  ) async throws(KaitenError) -> Components.Schemas.GroupEntity {
    let response = try await call {
      try await client.add_group_entity(
        path: .init(group_uid: groupUid),
        body: .json(.init(entity_uid: entityUid, role_ids: roleIds))
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Updates the roles of an entity in a company group.
  ///
  /// - Parameters:
  ///   - groupUid: The group UID.
  ///   - uid: The entity UID.
  ///   - roleIds: The role UIDs for the entity in the group. Kaiten requires at least one.
  /// - Returns: The group entity with its resolved roles and permissions.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for validation error (400),
  ///     unsupported tariff (402), forbidden (403), not found (404) or other undocumented HTTP
  ///     status codes.
  public func updateGroupEntity(
    groupUid: String,
    uid: String,
    roleIds: [String]? = nil
  ) async throws(KaitenError) -> Components.Schemas.GroupEntity {
    let response = try await call {
      try await client.update_group_entity(
        path: .init(group_uid: groupUid, uid: uid),
        body: .json(.init(role_ids: roleIds))
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Removes an entity from a company group.
  ///
  /// - Parameters:
  ///   - groupUid: The group UID.
  ///   - uid: The entity UID.
  /// - Returns: The removed group entity. Its `own_role_ids` and `role_permissions` come back
  ///   as JSON `null`, which decodes to `nil`.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403), not found (404)
  ///     or other undocumented HTTP status codes.
  public func removeGroupEntity(
    groupUid: String,
    uid: String
  ) async throws(KaitenError) -> Components.Schemas.GroupEntity {
    let response = try await call {
      try await client.remove_group_entity(path: .init(group_uid: groupUid, uid: uid))
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }
}
