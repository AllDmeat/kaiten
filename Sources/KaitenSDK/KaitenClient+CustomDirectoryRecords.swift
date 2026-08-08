import Foundation
import OpenAPIRuntime

// MARK: - Typed Discriminators

// The record condition travels as a plain string (see the comment above the
// custom directory enums in `Enums.swift`). This accessor gives the generated
// payload a typed surface without losing undocumented values.

extension Components.Schemas.CustomDirectoryRecord {
  /// The record condition, or `nil` if the API omitted the field.
  public var recordCondition: CustomDirectoryRecordCondition? {
    condition.map(CustomDirectoryRecordCondition.init(rawValue:))
  }
}

// MARK: - Custom Directory Records

extension KaitenClient {
  /// Returns a page of records in a custom directory.
  ///
  /// The custom directories API is documented as beta and may change.
  ///
  /// - Parameters:
  ///   - directoryId: The directory identifier.
  ///   - query: Quick search by record display value (optional).
  ///   - profile: Controls which relations the response includes (optional).
  ///   - includeValues: Legacy switch that includes the `values` array (optional).
  ///   - includeAuthor: Includes the author user object (optional).
  ///   - conditions: Filter by record conditions (optional).
  ///   - filters: Advanced field-based filters as a JSON-encoded object (optional).
  ///   - filterOperator: Boolean operator joining `filters`; the API defaults to `and` (optional).
  ///   - offset: Number of records to skip (default `0`).
  ///   - limit: Maximum number of records to return (default `100`, max `100`).
  /// - Returns: A ``Page`` of records. Returns an empty page when the directory has no
  ///   matching records.
  /// - Throws:
  ///   - ``KaitenError/invalidPaginationRange(offset:limit:)`` if pagination parameters are out of range.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for not found (404) or other
  ///     undocumented HTTP status codes. A 404 is reported as `unexpectedResponse` rather than
  ///     ``KaitenError/notFound(resource:id:)`` because directories are addressed by string ID.
  public func listCustomDirectoryRecords(
    directoryId: String,
    query: String? = nil,
    profile: CustomDirectoryProfile? = nil,
    includeValues: Bool? = nil,
    includeAuthor: Bool? = nil,
    conditions: [CustomDirectoryRecordCondition]? = nil,
    filters: String? = nil,
    filterOperator: CustomDirectoryFilterOperator? = nil,
    offset: Int = 0,
    limit: Int = 100
  ) async throws(KaitenError) -> Page<Components.Schemas.CustomDirectoryRecord> {
    try validatePagination(offset: offset, limit: limit)
    let queryInput = Operations.list_custom_directory_records.Input.Query(
      limit: limit,
      offset: offset,
      query: query,
      profile: profile?.rawValue,
      include_values: includeValues,
      include_author: includeAuthor,
      conditions: conditions.map { $0.map(\.rawValue) },
      filters: filters,
      filter_operator: filterOperator?.rawValue
    )
    guard
      let response = try await callList({
        try await client.list_custom_directory_records(
          path: .init(directory_id: directoryId), query: queryInput)
      })
    else {
      return Page(items: [], offset: offset, limit: limit)
    }
    let items: [Components.Schemas.CustomDirectoryRecord] = try decodeResponse(response.toCase()) {
      try $0.json
    }
    return Page(items: items, offset: offset, limit: limit)
  }

  /// Creates a record in a custom directory.
  ///
  /// The custom directories API is documented as beta and may change.
  ///
  /// - Parameters:
  ///   - directoryId: The directory identifier.
  ///   - values: Values map where keys are custom directory field identifiers. Each value is
  ///     either an object (single-value field) or an array of objects (multi-select field).
  ///     The Kaiten documentation does not describe the value shapes beyond that.
  ///   - responseProfile: Controls the response size. ``CustomDirectoryProfile/noRelations``
  ///     returns `{ id }` only (optional).
  /// - Returns: The created record. Which fields are present depends on `responseProfile`.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for validation errors (400), not
  ///     found (404) or other undocumented HTTP status codes. A 404 is reported as
  ///     `unexpectedResponse` rather than ``KaitenError/notFound(resource:id:)`` because
  ///     directories are addressed by string ID.
  public func createCustomDirectoryRecord(
    directoryId: String,
    values: Components.Schemas.CreateCustomDirectoryRecordRequest.valuesPayload,
    responseProfile: CustomDirectoryProfile? = nil
  ) async throws(KaitenError) -> Components.Schemas.CustomDirectoryRecord {
    let response = try await call {
      try await client.create_custom_directory_record(
        path: .init(directory_id: directoryId),
        query: .init(response_profile: responseProfile?.rawValue),
        body: .json(.init(values: values))
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Returns a single custom directory record.
  ///
  /// The custom directories API is documented as beta and may change.
  ///
  /// - Parameters:
  ///   - directoryId: The directory identifier.
  ///   - recordId: The record identifier.
  ///   - profile: Controls which relations the response includes (optional).
  /// - Returns: The record. Which fields are present depends on `profile`.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for not found (404) or other
  ///     undocumented HTTP status codes. A 404 is reported as `unexpectedResponse` rather than
  ///     ``KaitenError/notFound(resource:id:)`` because records are addressed by string ID and
  ///     the response does not say whether the directory or the record is missing.
  public func getCustomDirectoryRecord(
    directoryId: String,
    recordId: String,
    profile: CustomDirectoryProfile? = nil
  ) async throws(KaitenError) -> Components.Schemas.CustomDirectoryRecord {
    let response = try await call {
      try await client.get_custom_directory_record(
        path: .init(directory_id: directoryId, record_id: recordId),
        query: .init(profile: profile?.rawValue)
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Updates a custom directory record's values and/or condition.
  ///
  /// The custom directories API is documented as beta and may change.
  ///
  /// - Parameters:
  ///   - directoryId: The directory identifier.
  ///   - recordId: The record identifier.
  ///   - condition: The new record condition (optional).
  ///   - values: Values map where keys are custom directory field identifiers. Each value is
  ///     either an object (single-value field) or an array of objects (multi-select field).
  ///     The Kaiten documentation does not describe the value shapes beyond that (optional).
  ///   - responseProfile: Controls the response size. ``CustomDirectoryProfile/noRelations``
  ///     returns `{ id }` only (optional).
  /// - Returns: The updated record. Which fields are present depends on `responseProfile`.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for validation errors (400), not
  ///     found (404) or other undocumented HTTP status codes. A 404 is reported as
  ///     `unexpectedResponse` rather than ``KaitenError/notFound(resource:id:)`` because records
  ///     are addressed by string ID and the response does not say whether the directory or the
  ///     record is missing.
  public func updateCustomDirectoryRecord(
    directoryId: String,
    recordId: String,
    condition: CustomDirectoryRecordCondition? = nil,
    values: Components.Schemas.UpdateCustomDirectoryRecordRequest.valuesPayload? = nil,
    responseProfile: CustomDirectoryProfile? = nil
  ) async throws(KaitenError) -> Components.Schemas.CustomDirectoryRecord {
    let response = try await call {
      try await client.update_custom_directory_record(
        path: .init(directory_id: directoryId, record_id: recordId),
        query: .init(response_profile: responseProfile?.rawValue),
        body: .json(.init(condition: condition?.rawValue, values: values))
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Soft-deletes a custom directory record, setting its condition to `removed`.
  ///
  /// The custom directories API is documented as beta and may change.
  ///
  /// - Parameters:
  ///   - directoryId: The directory identifier.
  ///   - recordId: The record identifier.
  /// - Returns: The deleted record. The documentation lists only `id` and `condition` in
  ///   the response.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for not found (404) or other
  ///     undocumented HTTP status codes. A 404 is reported as `unexpectedResponse` rather than
  ///     ``KaitenError/notFound(resource:id:)`` because records are addressed by string ID and
  ///     the response does not say whether the directory or the record is missing.
  public func deleteCustomDirectoryRecord(
    directoryId: String,
    recordId: String
  ) async throws(KaitenError) -> Components.Schemas.CustomDirectoryRecord {
    let response = try await call {
      try await client.delete_custom_directory_record(
        path: .init(directory_id: directoryId, record_id: recordId)
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Returns a page of cards linked to a custom directory record, including cards linked
  /// through ancestor records.
  ///
  /// The custom directories API is documented as beta and may change.
  ///
  /// - Parameters:
  ///   - directoryId: The directory identifier.
  ///   - recordId: The record identifier.
  ///   - filter: Base64-encoded JSON card filter, merged with the base filter (optional).
  ///   - offset: Number of cards to skip (default `0`).
  ///   - limit: Maximum number of cards to return (default `100`, max `100`).
  /// - Returns: A ``Page`` of linked cards. Returns an empty page when the record has no
  ///   linked cards.
  /// - Throws:
  ///   - ``KaitenError/invalidPaginationRange(offset:limit:)`` if pagination parameters are out of range.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for validation errors (400), not
  ///     found (404) or other undocumented HTTP status codes. A 404 is reported as
  ///     `unexpectedResponse` rather than ``KaitenError/notFound(resource:id:)`` because records
  ///     are addressed by string ID and the response does not say whether the directory or the
  ///     record is missing.
  public func listCustomDirectoryRecordCards(
    directoryId: String,
    recordId: String,
    filter: String? = nil,
    offset: Int = 0,
    limit: Int = 100
  ) async throws(KaitenError) -> Page<Components.Schemas.CustomDirectoryLinkedCard> {
    try validatePagination(offset: offset, limit: limit)
    guard
      let response = try await callList({
        try await client.list_custom_directory_record_cards(
          path: .init(directory_id: directoryId, record_id: recordId),
          query: .init(limit: limit, offset: offset, filter: filter)
        )
      })
    else {
      return Page(items: [], offset: offset, limit: limit)
    }
    let items: [Components.Schemas.CustomDirectoryLinkedCard] = try decodeResponse(
      response.toCase()
    ) {
      try $0.json
    }
    return Page(items: items, offset: offset, limit: limit)
  }
}
