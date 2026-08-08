import Foundation
import OpenAPIRuntime

// MARK: - Company Users

extension KaitenClient {
  /// Lists company users filtered by query parameters.
  ///
  /// Requires an API token of a user with access to the administrative section "Members".
  ///
  /// - Parameters:
  ///   - invitesOnly: Return only invites.
  ///   - withTransferAccessStatus: Add data about the user rights transfer process.
  ///   - forMembersSection: Return users for the "Members" administrative section,
  ///     paginated with `limit` and `offset`.
  ///   - ownerOnly: Return the company owner.
  ///   - onlyPaid: Return only users with paid access.
  ///   - onlyRecordsCount: Return only the number of users. Works only together with
  ///     `forMembersSection` or `onlyVirtual`. The count-only response shape is not described
  ///     in the Kaiten documentation and is not modelled, so the call throws
  ///     ``KaitenError/decodingError(underlying:)``.
  ///   - onlyVirtual: Return only virtual users, paginated with `limit` and `offset`.
  ///   - offset: Number of records to skip.
  ///   - limit: Maximum amount of users in the response (default 100, max 100).
  ///   - query: Filter by email and full name. Works only with `forMembersSection`.
  ///   - accessTypePermissions: Filter by access to Kaiten. Works only with `forMembersSection`.
  ///   - sdAccessType: Filter by access to Service Desk. Works only with `forMembersSection`.
  ///   - takeLicence: Filter by users consuming the license. Works only with `forMembersSection`.
  ///   - temporarilyInactiveStatus: Filter by temporarily inactive users. Works only with
  ///     `forMembersSection`.
  ///   - groupIds: Filter by group IDs. Works only with `forMembersSection`.
  ///   - permissions: Filter by access granted to users. Works only with `forMembersSection`.
  /// - Returns: An array of company users. Returns an empty array when the response body is empty.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403, the token
  ///     lacks access to the "Members" administrative section), not found (404) or other
  ///     undocumented HTTP status codes.
  public func listCompanyUsers(
    invitesOnly: Bool? = nil,
    withTransferAccessStatus: Bool? = nil,
    forMembersSection: Bool? = nil,
    ownerOnly: Bool? = nil,
    onlyPaid: Bool? = nil,
    onlyRecordsCount: Bool? = nil,
    onlyVirtual: Bool? = nil,
    offset: Int? = nil,
    limit: Int? = nil,
    query: String? = nil,
    accessTypePermissions: String? = nil,
    sdAccessType: String? = nil,
    takeLicence: String? = nil,
    temporarilyInactiveStatus: String? = nil,
    groupIds: [Int]? = nil,
    permissions: [Int]? = nil
  ) async throws(KaitenError) -> [Components.Schemas.CompanyUser] {
    guard
      let response = try await callList({
        try await client.get_company_users(
          query: .init(
            invitesOnly: invitesOnly,
            withTransferAccessStatus: withTransferAccessStatus,
            for_members_section: forMembersSection,
            owner_only: ownerOnly,
            only_paid: onlyPaid,
            only_records_count: onlyRecordsCount,
            only_virtual: onlyVirtual,
            offset: offset,
            limit: limit,
            query: query,
            access_type_permissions: accessTypePermissions,
            sd_access_type: sdAccessType,
            take_licence: takeLicence,
            temporarily_inactive_status: temporarilyInactiveStatus,
            group_ids: groupIds,
            permissions: permissions
          )
        )
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Updates a company user.
  ///
  /// Requires an API token of a user with access to the administrative section "Members".
  ///
  /// - Parameters:
  ///   - id: The user identifier.
  ///   - appsPermissions: User access. Documented values: 0 — no access; 1 — full access to
  ///     Kaiten, access to service desk denied; 2 — guest access to Kaiten, access to service
  ///     desk denied; 4 — access only to service desk; 5 — full access to Kaiten and service
  ///     desk; 6 — guest access to Kaiten, access to service desk.
  ///   - temporarilyInactive: Temporarily inactive: the user stays in the company but cannot
  ///     sign in and does not need a license.
  /// - Returns: The updated company user.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the user does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for validation errors (400),
  ///     forbidden (403) or other undocumented HTTP status codes.
  public func updateCompanyUser(
    id: Int,
    appsPermissions: Int? = nil,
    temporarilyInactive: Bool? = nil
  ) async throws(KaitenError) -> Components.Schemas.CompanyUser {
    let response = try await call {
      try await client.update_company_user(
        path: .init(id: id),
        body: .json(
          .init(
            apps_permissions: appsPermissions,
            temporarily_inactive: temporarilyInactive
          ))
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("user", id)) {
      try $0.json
    }
  }

  /// Removes a virtual user.
  ///
  /// Requires an API token of a user with access to the administrative section
  /// "Resource planning".
  ///
  /// - Parameter id: The user identifier.
  /// - Returns: The removed user's identifier.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the user does not exist.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other
  ///     undocumented HTTP status codes, including unauthorized (401), which the documentation
  ///     does not list for this endpoint.
  public func removeVirtualUser(id: Int) async throws(KaitenError) -> Int {
    let response = try await call {
      try await client.remove_virtual_user(path: .init(id: id))
    }
    let result: Components.Schemas.DeletedCompanyUserResponse = try decodeResponse(
      response.toCase(), notFoundResource: ("user", id)
    ) { try $0.json }
    return result.id
  }
}
