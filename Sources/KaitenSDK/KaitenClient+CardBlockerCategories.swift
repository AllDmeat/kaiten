import Foundation
import OpenAPIRuntime

// MARK: - Card Blocker Categories

extension KaitenClient {
  /// Lists all blocker categories in the company.
  ///
  /// - Returns: An array of blocker categories. Returns an empty array if the company has no
  ///   blocker categories.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func listBlockerCategories() async throws(KaitenError) -> [Components.Schemas
    .BlockerCategory]
  {
    guard
      let response = try await callList({
        try await client.list_blocker_categories()
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Adds a category to a card blocker.
  ///
  /// - Parameters:
  ///   - blockerId: The blocker identifier.
  ///   - name: The blocker category name. Kaiten accepts 1 to 128 characters.
  /// - Returns: The blocker category attached to the blocker.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the blocker does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func addBlockerCategory(blockerId: Int, name: String) async throws(KaitenError)
    -> Components.Schemas.BlockerCategory
  {
    let response = try await call {
      try await client.add_blocker_category(
        path: .init(blocker_id: blockerId),
        body: .json(.init(name: name))
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("blocker", blockerId)) {
      try $0.json
    }
  }

  /// Removes a category from a card blocker.
  ///
  /// - Parameters:
  ///   - blockerId: The blocker identifier.
  ///   - categoryUid: The blocker category UID.
  /// - Returns: The removal confirmation carrying the removed category UID.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the blocker does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func removeBlockerCategory(blockerId: Int, categoryUid: String) async throws(KaitenError)
    -> Components.Schemas.RemovedBlockerCategoryResponse
  {
    let response = try await call {
      try await client.remove_blocker_category(
        path: .init(blocker_id: blockerId, category_uuid: categoryUid)
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("blocker", blockerId)) {
      try $0.json
    }
  }
}
