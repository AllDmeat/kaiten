import Foundation
import OpenAPIRuntime

// MARK: - Typed Discriminators

// The iteration status travels as a plain string (see the comment above
// `IterationStatus` in `Enums.swift`). This accessor gives the generated
// payload a typed surface without losing undocumented values.

extension Components.Schemas.Iteration {
  /// The iteration status, or `nil` if the API omitted the field.
  public var iterationStatus: IterationStatus? {
    status.map(IterationStatus.init(rawValue:))
  }
}

// MARK: - Iterations

extension KaitenClient {
  /// Gets the iterations history of a card.
  ///
  /// Returns all iteration card records for the card, ordered from the most recent to the
  /// oldest. The Kaiten iterations API is in beta and may change.
  ///
  /// - Parameter cardUid: The card UID.
  /// - Returns: An array of iteration card records. Returns an empty array if the card has
  ///   never been in an iteration.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for unsupported tariff (402),
  ///     forbidden (403), not found (404) or other undocumented HTTP status codes. A 404 is
  ///     reported as `unexpectedResponse` rather than ``KaitenError/notFound(resource:id:)``
  ///     because cards are addressed here by string UID, which that error cannot represent.
  public func getCardIterationsHistory(cardUid: String) async throws(KaitenError) -> [Components
    .Schemas.IterationCard]
  {
    guard
      let response = try await callList({
        try await client.get_card_iterations_history(path: .init(card_uid: cardUid))
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Lists the iterations of a space.
  ///
  /// The iterations feature must be enabled for the company. The Kaiten iterations API is in
  /// beta and may change.
  ///
  /// - Parameters:
  ///   - spaceUid: The space UID.
  ///   - status: Iteration statuses to filter by. Sent as a comma-separated list.
  ///   - withData: Related data to include, as a comma-separated list. The only documented
  ///     value is `cards`. Iterations with the `removed` status do not contain cards.
  ///   - limit: Maximum number of iterations to return. The API clamps the value to the range
  ///     1-100 and defaults to 100.
  ///   - offset: Number of iterations to skip from the beginning of the result set. The API
  ///     defaults to 0.
  ///   - order: Sort order by creation date, `asc` or `desc`. The API defaults to `asc`.
  /// - Returns: An array of iterations. Returns an empty array if the space has no iterations.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for unsupported tariff (402),
  ///     forbidden (403), not found (404) or other undocumented HTTP status codes. A 404 is
  ///     reported as `unexpectedResponse` rather than ``KaitenError/notFound(resource:id:)``
  ///     because spaces are addressed here by string UID, which that error cannot represent.
  public func listIterations(
    spaceUid: String,
    status: [IterationStatus]? = nil,
    withData: String? = nil,
    limit: Int? = nil,
    offset: Int? = nil,
    order: String? = nil
  ) async throws(KaitenError) -> [Components.Schemas.Iteration] {
    let query = Operations.list_iterations.Input.Query(
      status: status.map { $0.map(\.rawValue).joined(separator: ",") },
      with_data: withData,
      limit: limit,
      offset: offset,
      order: order
    )
    guard
      let response = try await callList({
        try await client.list_iterations(path: .init(space_uid: spaceUid), query: query)
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Creates an iteration in a space.
  ///
  /// A created iteration gets the `planned` status. The iterations feature must be enabled for
  /// the company. The Kaiten iterations API is in beta and may change.
  ///
  /// - Parameters:
  ///   - spaceUid: The space UID.
  ///   - title: The iteration title, 1 to 256 characters.
  ///   - goal: The iteration goal.
  ///   - startDate: The start date, ISO 8601 format.
  ///   - finishDate: The finish date, ISO 8601 format. Must be later than the start date.
  /// - Returns: The created iteration.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for bad request (400, including
  ///     an invalid date range), unsupported tariff (402), forbidden (403), not found (404) or
  ///     other undocumented HTTP status codes. A 404 is reported as `unexpectedResponse` rather
  ///     than ``KaitenError/notFound(resource:id:)`` because spaces are addressed here by
  ///     string UID, which that error cannot represent.
  public func createIteration(
    spaceUid: String,
    title: String,
    goal: String? = nil,
    startDate: String? = nil,
    finishDate: String? = nil
  ) async throws(KaitenError) -> Components.Schemas.Iteration {
    let response = try await call {
      try await client.create_iteration(
        path: .init(space_uid: spaceUid),
        body: .json(
          .init(
            title: title,
            goal: goal,
            start_date: startDate,
            finish_date: finishDate
          ))
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Gets a single iteration of a space by its ID.
  ///
  /// The Kaiten iterations API is in beta and may change.
  ///
  /// - Parameters:
  ///   - spaceUid: The space UID.
  ///   - id: The iteration ID.
  /// - Returns: The iteration.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for unsupported tariff (402),
  ///     forbidden (403), not found (404) or other undocumented HTTP status codes. A 404 is
  ///     reported as `unexpectedResponse` rather than ``KaitenError/notFound(resource:id:)``
  ///     because iterations are addressed by string ID, which that error cannot represent.
  public func getIteration(
    spaceUid: String, id: String
  ) async throws(KaitenError) -> Components.Schemas.Iteration {
    let response = try await call {
      try await client.get_iteration(path: .init(space_uid: spaceUid, id: id))
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Updates an iteration.
  ///
  /// Status transitions are limited to `planned` to `active` and `active` to `closed`; use
  /// ``deleteIteration(spaceUid:id:newIterationId:)`` to remove an iteration. At least one
  /// editable field must be provided. The Kaiten iterations API is in beta and may change.
  ///
  /// - Parameters:
  ///   - spaceUid: The space UID.
  ///   - id: The iteration ID.
  ///   - title: The updated iteration title, 1 to 256 characters.
  ///   - goal: The updated iteration goal.
  ///   - status: The updated iteration status. Documented transition targets are `.active`
  ///     (from `planned`) and `.closed` (from `active`).
  ///   - startDate: The updated start date, ISO 8601 format.
  ///   - finishDate: The updated finish date, ISO 8601 format.
  ///   - actualFinishDate: The actual finish date, applied when closing an iteration. Must be
  ///     later than the start date; defaults to the current time if omitted. ISO 8601 format.
  ///   - newIterationId: ID of the iteration to move unfinished cards to when closing with
  ///     status `closed`. Must belong to the same space and have the `planned` or `active`
  ///     status.
  /// - Returns: The updated iteration. When closing with `newIterationId` and unfinished cards
  ///   were moved, the returned iteration carries the `moved_cards` records.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for bad request (400, a
  ///     validation error or lifecycle rule violation), unsupported tariff (402), forbidden
  ///     (403), not found (404) or other undocumented HTTP status codes. A 404 is reported as
  ///     `unexpectedResponse` rather than ``KaitenError/notFound(resource:id:)`` because
  ///     iterations are addressed by string ID, which that error cannot represent.
  public func updateIteration(
    spaceUid: String,
    id: String,
    title: String? = nil,
    goal: String? = nil,
    status: IterationStatus? = nil,
    startDate: String? = nil,
    finishDate: String? = nil,
    actualFinishDate: String? = nil,
    newIterationId: String? = nil
  ) async throws(KaitenError) -> Components.Schemas.Iteration {
    let response = try await call {
      try await client.update_iteration(
        path: .init(space_uid: spaceUid, id: id),
        body: .json(
          .init(
            title: title,
            goal: goal,
            status: status?.rawValue,
            start_date: startDate,
            finish_date: finishDate,
            actual_finish_date: actualFinishDate,
            new_iteration_id: newIterationId
          ))
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Deletes an iteration.
  ///
  /// Links to cards that were part of the iteration are deleted too and cannot be restored.
  /// The iteration gets the `removed` status and is returned in the response. The Kaiten
  /// iterations API is in beta and may change.
  ///
  /// - Parameters:
  ///   - spaceUid: The space UID.
  ///   - id: The iteration ID.
  ///   - newIterationId: ID of the iteration to move cards to when this iteration is removed.
  ///     Must belong to the same space and have the `planned` or `active` status.
  /// - Returns: The deleted iteration. `moved_cards` carries the records of cards moved to
  ///   `newIterationId`, or is `nil` when no cards were moved.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for bad request (400, an invalid
  ///     `newIterationId`), unsupported tariff (402), forbidden (403), not found (404) or other
  ///     undocumented HTTP status codes. A 404 is reported as `unexpectedResponse` rather than
  ///     ``KaitenError/notFound(resource:id:)`` because iterations are addressed by string ID,
  ///     which that error cannot represent.
  public func deleteIteration(
    spaceUid: String,
    id: String,
    newIterationId: String? = nil
  ) async throws(KaitenError) -> Components.Schemas.Iteration {
    let body: Operations.delete_iteration.Input.Body? = newIterationId.map {
      .json(.init(new_iteration_id: $0))
    }
    let response = try await call {
      try await client.delete_iteration(path: .init(space_uid: spaceUid, id: id), body: body)
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Lists the card records of an iteration.
  ///
  /// Each record links a card to the iteration. The Kaiten iterations API is in beta and may
  /// change.
  ///
  /// - Parameters:
  ///   - spaceUid: The space UID.
  ///   - iterationId: The iteration ID.
  ///   - status: Record status to filter by, `active` or `removed`. When `nil`, both active
  ///     and removed records are returned.
  /// - Returns: An array of iteration card records. Returns an empty array if the iteration
  ///   has no cards.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for bad request (400, an invalid
  ///     status filter value), unsupported tariff (402), forbidden (403), not found (404) or
  ///     other undocumented HTTP status codes. A 404 is reported as `unexpectedResponse`
  ///     rather than ``KaitenError/notFound(resource:id:)`` because iterations are addressed
  ///     by string ID, which that error cannot represent.
  public func listIterationCards(
    spaceUid: String,
    iterationId: String,
    status: String? = nil
  ) async throws(KaitenError) -> [Components.Schemas.IterationCard] {
    guard
      let response = try await callList({
        try await client.list_iteration_cards(
          path: .init(space_uid: spaceUid, iteration_id: iterationId),
          query: .init(status: status)
        )
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Adds a card to an iteration.
  ///
  /// The card must be active and belong to one of the space's primary boards. Cards can be
  /// added to `planned` and `active` iterations only. Adding a card that belongs to another
  /// planned or active iteration moves it to the target iteration. The Kaiten iterations API
  /// is in beta and may change.
  ///
  /// - Parameters:
  ///   - spaceUid: The space UID.
  ///   - iterationId: The iteration ID.
  ///   - cardUid: The UID of the card to add.
  /// - Returns: The created iteration card record.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for bad request (400, a
  ///     validation error or card rule violation), unsupported tariff (402), forbidden (403),
  ///     not found (404) or other undocumented HTTP status codes. A 404 is reported as
  ///     `unexpectedResponse` rather than ``KaitenError/notFound(resource:id:)`` because
  ///     iterations and cards are addressed here by string identifiers, which that error
  ///     cannot represent.
  public func addCardToIteration(
    spaceUid: String,
    iterationId: String,
    cardUid: String
  ) async throws(KaitenError) -> Components.Schemas.IterationCard {
    let response = try await call {
      try await client.add_card_to_iteration(
        path: .init(space_uid: spaceUid, iteration_id: iterationId),
        body: .json(.init(card_uid: cardUid))
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Removes a card from an iteration.
  ///
  /// Removal sets `removed_at` and `removed_by_uid` on the iteration card record. Cards cannot
  /// be removed from `closed` iterations. The Kaiten iterations API is in beta and may change.
  ///
  /// - Parameters:
  ///   - spaceUid: The space UID.
  ///   - iterationId: The iteration ID.
  ///   - cardUid: The UID of the card to remove.
  /// - Returns: The updated iteration card record with `removed_at` and `removed_by_uid` set.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for bad request (400, the card
  ///     cannot be removed from the iteration), unsupported tariff (402), forbidden (403), not
  ///     found (404) or other undocumented HTTP status codes. A 404 is reported as
  ///     `unexpectedResponse` rather than ``KaitenError/notFound(resource:id:)`` because
  ///     iterations and cards are addressed here by string identifiers, which that error
  ///     cannot represent.
  public func removeCardFromIteration(
    spaceUid: String,
    iterationId: String,
    cardUid: String
  ) async throws(KaitenError) -> Components.Schemas.IterationCard {
    let response = try await call {
      try await client.remove_card_from_iteration(
        path: .init(space_uid: spaceUid, iteration_id: iterationId, uid: cardUid)
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }
}
