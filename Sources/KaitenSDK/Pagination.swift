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
  ///   - includeAuthor: Include author details in the response.
  ///   - compact: Return compact representation.
  ///   - orderBy: Field to order by.
  ///   - orderDirection: Order direction: asc or desc.
  ///   - pageSize: Number of properties per page (default `100`).
  /// - Returns: An `AsyncThrowingStream` of all custom properties.
  public func allCustomProperties(
    query: String? = nil,
    includeAuthor: Bool? = nil,
    compact: Bool? = nil,
    orderBy: String? = nil,
    orderDirection: String? = nil,
    pageSize: Int = 100
  ) -> AsyncThrowingStream<Components.Schemas.CustomProperty, Error> {
    allPages(pageSize: pageSize) { [self] offset, limit in
      try await self.listCustomProperties(
        offset: offset, limit: limit, query: query, includeAuthor: includeAuthor,
        compact: compact, orderBy: orderBy, orderDirection: orderDirection
      )
    }
  }

  /// Returns all custom properties across all pages, sending `include_values`.
  ///
  /// - Parameters:
  ///   - query: Text search query to filter properties by name.
  ///   - includeValues: Include property values in the response. The public API answers
  ///     `true` with HTTP 400 since October 1, 2026.
  ///   - includeAuthor: Include author details in the response.
  ///   - compact: Return compact representation.
  ///   - orderBy: Field to order by.
  ///   - orderDirection: Order direction: asc or desc.
  ///   - pageSize: Number of properties per page (default `100`).
  /// - Returns: An `AsyncThrowingStream` of all custom properties.
  @available(
    *, deprecated,
    message:
      "The public API rejects include_values=true with HTTP 400; read values from the paginated value endpoints"
  )
  public func allCustomProperties(
    query: String? = nil,
    includeValues: Bool?,
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

  /// Returns all spaces across all pages.
  ///
  /// - Parameter pageSize: Number of spaces per page (1–100, default `100`).
  /// - Returns: An `AsyncThrowingStream` of all spaces.
  public func allSpaces(
    pageSize: Int = 100
  ) -> AsyncThrowingStream<Components.Schemas.Space, Error> {
    allPages(pageSize: pageSize) { [self] offset, limit in
      try await self.listSpaces(limit: limit, offset: offset)
    }
  }

  /// Returns all comments on a card across all pages.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - pageSize: Number of comments per page (1–100, default `100`).
  /// - Returns: An `AsyncThrowingStream` of all comments.
  public func allCardComments(
    cardId: Int,
    pageSize: Int = 100
  ) -> AsyncThrowingStream<Components.Schemas.Comment, Error> {
    allPages(pageSize: pageSize) { [self] offset, limit in
      try await self.getCardComments(cardId: cardId, limit: limit, offset: offset)
    }
  }

  /// Returns all children of a card across all pages.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - pageSize: Number of children per page (1–100, default `100`).
  /// - Returns: An `AsyncThrowingStream` of all card children.
  public func allCardChildren(
    cardId: Int,
    pageSize: Int = 100
  ) -> AsyncThrowingStream<Components.Schemas.CardChild, Error> {
    allPages(pageSize: pageSize) { [self] offset, limit in
      try await self.listCardChildren(cardId: cardId, limit: limit, offset: offset)
    }
  }

  /// Returns all time logs on a card across all pages.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - forDate: Filter by the `for_date` attribute (`YYYY-MM-DD`).
  ///   - personal: When `true`, returns only the current user's time logs.
  ///   - pageSize: Number of time logs per page (1–100, default `100`).
  /// - Returns: An `AsyncThrowingStream` of all time logs.
  public func allCardTimeLogs(
    cardId: Int,
    forDate: String? = nil,
    personal: Bool? = nil,
    pageSize: Int = 100
  ) -> AsyncThrowingStream<Components.Schemas.CardTimeLog, Error> {
    allPages(pageSize: pageSize) { [self] offset, limit in
      try await self.getCardTimeLogs(
        cardId: cardId, forDate: forDate, personal: personal, limit: limit, offset: offset)
    }
  }

  /// Returns all users of a company group across all pages.
  ///
  /// - Parameters:
  ///   - groupUid: The group UID.
  ///   - pageSize: Number of users per page (1–100, default `100`).
  /// - Returns: An `AsyncThrowingStream` of all group users.
  public func allGroupUsers(
    groupUid: String,
    pageSize: Int = 100
  ) -> AsyncThrowingStream<Components.Schemas.GroupUser, Error> {
    allPages(pageSize: pageSize) { [self] offset, limit in
      try await self.listGroupUsers(groupUid: groupUid, limit: limit, offset: offset)
    }
  }

  /// Returns all users with access to a card across all pages.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - type: The type of users to return.
  ///   - role: Filter by role.
  ///   - pageSize: Number of users per page (1–100, default `100`).
  /// - Returns: An `AsyncThrowingStream` of all allowed users.
  public func allCardAllowedUsers(
    cardId: Int,
    type: String? = nil,
    role: Int? = nil,
    pageSize: Int = 100
  ) -> AsyncThrowingStream<Components.Schemas.AllowedUser, Error> {
    allPages(pageSize: pageSize) { [self] offset, limit in
      try await self.listCardAllowedUsers(
        cardId: cardId, type: type, role: role, limit: limit, offset: offset)
    }
  }

  /// Returns all users of a space across all pages.
  ///
  /// The endpoint pages by a `last_user_id` cursor rather than an offset. Each request passes the
  /// greatest user id seen on the previous page, since the default list is not ordered by id.
  ///
  /// - Parameters:
  ///   - spaceId: The space identifier.
  ///   - includeInheritedAccess: Include users whose access is inherited from a parent entity.
  ///   - inactive: Return only members who are inactive in the company.
  ///   - pageSize: Number of users per page (1–500, default `100`).
  /// - Returns: An `AsyncThrowingStream` of all space users.
  public func allSpaceUsers(
    spaceId: Int,
    includeInheritedAccess: Bool? = nil,
    inactive: Bool? = nil,
    pageSize: Int = 100
  ) -> AsyncThrowingStream<Components.Schemas.SpaceUser, Error> {
    AsyncThrowingStream { continuation in
      let task = Task {
        var lastUserId: Int?
        do {
          while !Task.isCancelled {
            let users = try await listSpaceUsers(
              spaceId: spaceId, includeInheritedAccess: includeInheritedAccess,
              inactive: inactive, limit: pageSize, lastUserId: lastUserId)
            for user in users { continuation.yield(user) }
            // A short page is the last one; a cursor that stops growing would repeat the page.
            guard users.count == pageSize, let maxId = users.compactMap(\.id).max(),
              maxId > lastUserId ?? .min
            else { break }
            lastUserId = maxId
          }
          continuation.finish()
        } catch {
          continuation.finish(throwing: error)
        }
      }
      continuation.onTermination = { _ in task.cancel() }
    }
  }
}
