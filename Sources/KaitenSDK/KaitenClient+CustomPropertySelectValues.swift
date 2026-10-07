import Foundation
import OpenAPIRuntime

// MARK: - Typed Discriminators

// The select value `condition` travels as a plain string (see the comment above
// `CustomPropertySelectValueCondition` in `Enums.swift`). This accessor gives
// the generated payload a typed surface without losing undocumented values.

extension Components.Schemas.CustomPropertySelectValue {
  /// The select value condition, or `nil` if the API omitted the field.
  public var selectValueCondition: CustomPropertySelectValueCondition? {
    condition.map(CustomPropertySelectValueCondition.init(rawValue:))
  }
}

// MARK: - Custom Property Select Values

extension KaitenClient {
  /// Lists select values for a select-type custom property.
  ///
  /// - Parameters:
  ///   - propertyId: The custom property identifier.
  ///   - query: Filter by select value.
  ///   - orderBy: Field to sort by.
  ///   - ids: Array of value IDs to filter by.
  ///   - conditions: Array of conditions to filter by.
  ///   - offset: Number of records to skip.
  ///   - limit: Maximum number of values to return (default `100`).
  /// - Returns: A ``Page`` of select values.
  /// - Throws:
  ///   - ``KaitenError/invalidPaginationRange(offset:limit:)`` if pagination parameters are out of range.
  ///   - ``KaitenError/notFound(resource:id:)`` if the property does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func listCustomPropertySelectValues(
    propertyId: Int,
    query: String? = nil,
    orderBy: String? = nil,
    ids: [Int]? = nil,
    conditions: [String]? = nil,
    offset: Int = 0,
    limit: Int = 100
  ) async throws(KaitenError) -> Page<Components.Schemas.CustomPropertySelectValue> {
    try await selectValues(
      propertyId: propertyId, v2SelectSearch: nil, query: query, orderBy: orderBy,
      ids: ids, conditions: conditions, offset: offset, limit: limit)
  }

  /// Lists select values for a select-type custom property, sending `v2_select_search`.
  ///
  /// Kaiten documents `v2_select_search` as a deprecated parameter with no effect.
  @available(
    *, deprecated,
    message:
      "v2_select_search has no effect. Use listCustomPropertySelectValues(propertyId:query:orderBy:ids:conditions:offset:limit:)."
  )
  public func listCustomPropertySelectValues(
    propertyId: Int,
    v2SelectSearch: Bool?,
    query: String? = nil,
    orderBy: String? = nil,
    ids: [Int]? = nil,
    conditions: [String]? = nil,
    offset: Int = 0,
    limit: Int = 100
  ) async throws(KaitenError) -> Page<Components.Schemas.CustomPropertySelectValue> {
    try await selectValues(
      propertyId: propertyId, v2SelectSearch: v2SelectSearch, query: query, orderBy: orderBy,
      ids: ids, conditions: conditions, offset: offset, limit: limit)
  }

  private func selectValues(
    propertyId: Int,
    v2SelectSearch: Bool?,
    query: String?,
    orderBy: String?,
    ids: [Int]?,
    conditions: [String]?,
    offset: Int,
    limit: Int
  ) async throws(KaitenError) -> Page<Components.Schemas.CustomPropertySelectValue> {
    try validatePagination(offset: offset, limit: limit)
    guard
      let response = try await callList({
        try await client.get_list_of_select_values(
          path: .init(property_id: propertyId),
          query: .init(
            v2_select_search: v2SelectSearch, query: query, order_by: orderBy,
            ids: ids, conditions: conditions, offset: offset, limit: limit))
      })
    else {
      return Page(items: [], offset: offset, limit: limit)
    }
    let items: [Components.Schemas.CustomPropertySelectValue] = try decodeResponse(
      response.toCase()
    ) { try $0.json }
    return Page(items: items, offset: offset, limit: limit)
  }

  /// Creates a select value for a select-type custom property.
  ///
  /// - Parameters:
  ///   - propertyId: The custom property identifier.
  ///   - value: The value text (1...128 characters).
  ///   - color: Colour number, or `nil` for no colour.
  /// - Returns: The created select value.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the property does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for bad request (400), forbidden (403), or other undocumented HTTP status codes.
  public func createCustomPropertySelectValue(
    propertyId: Int,
    value: String,
    color: Int? = nil
  ) async throws(KaitenError) -> Components.Schemas.CustomPropertySelectValue {
    let response = try await call {
      try await client.create_select_value(
        path: .init(property_id: propertyId),
        body: .json(.init(value: value, color: color))
      )
    }
    return try decodeResponse(
      response.toCase(), notFoundResource: ("customProperty", propertyId)
    ) {
      try $0.json
    }
  }

  /// Fetches a single select value by its identifier.
  ///
  /// - Parameters:
  ///   - propertyId: The custom property identifier.
  ///   - id: The select value identifier.
  /// - Returns: The select value.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the value does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func getCustomPropertySelectValue(
    propertyId: Int,
    id: Int
  ) async throws(KaitenError) -> Components.Schemas.CustomPropertySelectValue {
    let response = try await call {
      try await client.get_select_value(path: .init(property_id: propertyId, id: id))
    }
    return try decodeResponse(
      response.toCase(), notFoundResource: ("customPropertySelectValue", id)
    ) {
      try $0.json
    }
  }

  /// Updates a select value of a select-type custom property.
  ///
  /// - Parameters:
  ///   - propertyId: The custom property identifier.
  ///   - id: The select value identifier.
  ///   - value: The updated value text (1...128 characters).
  ///   - color: Colour number, or `nil` to leave the colour unchanged.
  ///   - condition: The select value condition.
  ///   - sortOrder: Position (0 or greater).
  ///   - deleted: The select value delete condition.
  /// - Returns: The updated select value.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the value does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for bad request (400), forbidden (403), or other undocumented HTTP status codes.
  public func updateCustomPropertySelectValue(
    propertyId: Int,
    id: Int,
    value: String? = nil,
    color: Int? = nil,
    condition: CustomPropertySelectValueCondition? = nil,
    sortOrder: Double? = nil,
    deleted: Bool? = nil
  ) async throws(KaitenError) -> Components.Schemas.CustomPropertySelectValue {
    let response = try await call {
      try await client.update_select_value(
        path: .init(property_id: propertyId, id: id),
        body: .json(
          .init(
            value: value,
            color: color,
            condition: condition?.rawValue,
            sort_order: sortOrder,
            deleted: deleted
          ))
      )
    }
    return try decodeResponse(
      response.toCase(), notFoundResource: ("customPropertySelectValue", id)
    ) {
      try $0.json
    }
  }

  /// Removes a select value from a select-type custom property.
  ///
  /// The endpoint returns the removed select value.
  ///
  /// - Parameters:
  ///   - propertyId: The custom property identifier.
  ///   - id: The select value identifier.
  /// - Returns: The removed select value.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the value does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func removeCustomPropertySelectValue(
    propertyId: Int,
    id: Int
  ) async throws(KaitenError) -> Components.Schemas.CustomPropertySelectValue {
    let response = try await call {
      try await client.remove_select_value(path: .init(property_id: propertyId, id: id))
    }
    return try decodeResponse(
      response.toCase(), notFoundResource: ("customPropertySelectValue", id)
    ) {
      try $0.json
    }
  }
}
