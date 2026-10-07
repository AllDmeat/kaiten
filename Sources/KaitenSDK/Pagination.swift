// MARK: - Auto-Pagination

extension KaitenClient {
  /// Auto-paginates through all pages, yielding items one by one.
  ///
  /// The `fetch` closure receives `(offset, limit)` and returns a ``Page``.
  /// Pagination stops when the page signals no more results.
  ///
  /// - Parameters:
  ///   - pageSize: Number of items per page (default `100`).
  ///   - fetch: Closure that fetches a single page given offset and limit.
  /// - Returns: An `AsyncThrowingStream` that yields each item across all pages.
  func allPages<T: Sendable>(
    pageSize: Int = 100,
    fetch: @Sendable @escaping (Int, Int) async throws -> Page<T>
  ) -> AsyncThrowingStream<T, Error> {
    AsyncThrowingStream { continuation in
      guard pageSize > 0 else {
        continuation.finish(throwing: KaitenError.invalidPagination(pageSize: pageSize))
        return
      }

      let task = Task {
        var offset = 0
        while !Task.isCancelled {
          let page: Page<T>
          do {
            page = try await fetch(offset, pageSize)
          } catch {
            continuation.finish(throwing: error)
            return
          }
          for item in page.items {
            continuation.yield(item)
          }
          if !page.hasMore { break }
          offset += pageSize
        }
        continuation.finish()
      }
      continuation.onTermination = { _ in task.cancel() }
    }
  }

  /// Auto-paginates endpoints that return a plain array (no ``Page`` wrapper).
  ///
  /// Pagination stops when the returned array has fewer items than `pageSize`.
  ///
  /// - Parameters:
  ///   - pageSize: Number of items per page (default `100`).
  ///   - fetch: Closure that fetches an array given offset and limit.
  /// - Returns: An `AsyncThrowingStream` that yields each item across all pages.
  func allPages<T: Sendable>(
    pageSize: Int = 100,
    fetch: @Sendable @escaping (Int, Int) async throws -> [T]
  ) -> AsyncThrowingStream<T, Error> {
    allPages(pageSize: pageSize) { offset, limit in
      let items = try await fetch(offset, limit)
      return Page(items: items, offset: offset, limit: limit)
    }
  }

  // MARK: - Convenience methods

  /// Returns all cards across all pages.
  ///
  /// - Parameters:
  ///   - boardId: Filter by board identifier (optional).
  ///   - columnId: Filter by column identifier (optional).
  ///   - laneId: Filter by lane identifier (optional).
  ///   - filter: Optional ``CardFilter`` with additional query parameters.
  ///   - pageSize: Number of cards per page (default `100`).
  /// - Returns: An `AsyncThrowingStream` of all matching cards.
  public func allCards(
    boardId: Int? = nil,
    columnId: Int? = nil,
    laneId: Int? = nil,
    filter: CardFilter? = nil,
    pageSize: Int = 100
  ) -> AsyncThrowingStream<Components.Schemas.Card, Error> {
    allPages(pageSize: pageSize) { [self] offset, limit in
      try await self.listCards(
        boardId: boardId, columnId: columnId, laneId: laneId,
        offset: offset, limit: limit, filter: filter
      )
    }
  }

  /// Returns all custom properties across all pages.
  ///
  /// - Parameters:
  ///   - query: Text search query to filter properties by name.
  ///   - includeValues: Include property values in the response.
  ///   - includeAuthor: Include author details in the response.
  ///   - compact: Return compact representation.
  ///   - orderBy: Field to order by.
  ///   - orderDirection: Order direction: asc or desc.
  ///   - pageSize: Number of properties per page (default `100`).
  /// - Returns: An `AsyncThrowingStream` of all custom properties.
  public func allCustomProperties(
    query: String? = nil,
    includeValues: Bool? = nil,
    includeAuthor: Bool? = nil,
    compact: Bool? = nil,
    orderBy: String? = nil,
    orderDirection: String? = nil,
    pageSize: Int = 100
  ) -> AsyncThrowingStream<Components.Schemas.CustomProperty, Error> {
    allPages(pageSize: pageSize) { [self] offset, limit in
      try await self.listCustomProperties(
        offset: offset, limit: limit, query: query,
        includeValues: includeValues, includeAuthor: includeAuthor,
        compact: compact, orderBy: orderBy, orderDirection: orderDirection
      )
    }
  }

  /// Returns all select values for a custom property across all pages.
  ///
  /// Automatically enables `v2SelectSearch` to support offset-based pagination.
  ///
  /// - Parameters:
  ///   - propertyId: The custom property identifier.
  ///   - query: Filter by select value name.
  ///   - orderBy: Field to sort by.
  ///   - pageSize: Number of values per page (default `100`).
  /// - Returns: An `AsyncThrowingStream` of all select values.
  public func allCustomPropertySelectValues(
    propertyId: Int,
    query: String? = nil,
    orderBy: String? = nil,
    pageSize: Int = 100
  ) -> AsyncThrowingStream<Components.Schemas.CustomPropertySelectValue, Error> {
    allPages(pageSize: pageSize) { [self] offset, limit in
      try await self.listCustomPropertySelectValues(
        propertyId: propertyId, v2SelectSearch: true,
        query: query, orderBy: orderBy, offset: offset, limit: limit
      )
    }
  }

  /// Returns all users across all pages.
  ///
  /// - Parameters:
  ///   - type: Type of users to return.
  ///   - query: Search query.
  ///   - includeInactive: Include inactive users.
  ///   - accessTypePermissions: `member` excludes guests before pagination; `guest` applies
  ///     to the `all` and `domain` types.
  ///   - excludeMembersByEntityUid: Excludes direct, group and inherited members of the entity
  ///     with this UID.
  ///   - excludeDirectlyAddedMembersByEntityUid: Excludes users invited directly to the entity
  ///     with this UID.
  ///   - pageSize: Number of users per page (default `100`).
  /// - Returns: An `AsyncThrowingStream` of all users.
  public func allUsers(
    type: String? = nil,
    query: String? = nil,
    includeInactive: Bool? = nil,
    accessTypePermissions: String? = nil,
    excludeMembersByEntityUid: String? = nil,
    excludeDirectlyAddedMembersByEntityUid: String? = nil,
    pageSize: Int = 100
  ) -> AsyncThrowingStream<Components.Schemas.User, Error> {
    allPages(pageSize: pageSize) { [self] offset, limit in
      try await self.listUsers(
        type: type, query: query, limit: limit,
        offset: offset, includeInactive: includeInactive,
        accessTypePermissions: accessTypePermissions,
        excludeMembersByEntityUid: excludeMembersByEntityUid,
        excludeDirectlyAddedMembersByEntityUid: excludeDirectlyAddedMembersByEntityUid
      )
    }
  }

  /// Returns all card types across all pages.
  ///
  /// - Parameter pageSize: Number of card types per page (default `100`).
  /// - Returns: An `AsyncThrowingStream` of all card types.
  public func allCardTypes(
    pageSize: Int = 100
  ) -> AsyncThrowingStream<Components.Schemas.CardType, Error> {
    allPages(pageSize: pageSize) { [self] offset, limit in
      try await self.listCardTypes(limit: limit, offset: offset)
    }
  }

  /// Returns all sprints across all pages.
  ///
  /// - Parameters:
  ///   - active: Filter by active status.
  ///   - pageSize: Number of sprints per page (default `100`).
  /// - Returns: An `AsyncThrowingStream` of all sprints.
  public func allSprints(
    active: Bool? = nil,
    pageSize: Int = 100
  ) -> AsyncThrowingStream<Components.Schemas.Sprint, Error> {
    allPages(pageSize: pageSize) { [self] offset, limit in
      try await self.listSprints(active: active, limit: limit, offset: offset)
    }
  }
}
