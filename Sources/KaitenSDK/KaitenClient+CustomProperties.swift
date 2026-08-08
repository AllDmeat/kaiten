import Foundation
import OpenAPIRuntime

// MARK: - Custom Properties

extension KaitenClient {
  /// Lists all custom property definitions for the company.
  ///
  /// Custom properties are company-wide field definitions (e.g. "Team", "Platform")
  /// that can be attached to cards.
  ///
  /// - Parameters:
  ///   - offset: Number of properties to skip (default `0`).
  ///   - limit: Maximum number of properties to return (default `100`).
  ///   - query: Text search query to filter properties by name.
  ///   - includeValues: Include property values in the response.
  ///   - includeAuthor: Include author details in the response.
  ///   - compact: Return compact representation.
  ///   - loadByIds: Load properties by IDs (use with `ids`).
  ///   - ids: Array of property IDs to load (requires `loadByIds: true`).
  ///   - orderBy: Field to order by.
  ///   - orderDirection: Order direction: asc or desc.
  /// - Returns: A ``Page`` of custom property definitions.
  /// - Throws:
  ///   - ``KaitenError/invalidPaginationRange(offset:limit:)`` if pagination parameters are out of range.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func listCustomProperties(
    offset: Int = 0,
    limit: Int = 100,
    query: String? = nil,
    includeValues: Bool? = nil,
    includeAuthor: Bool? = nil,
    compact: Bool? = nil,
    loadByIds: Bool? = nil,
    ids: [Int]? = nil,
    orderBy: String? = nil,
    orderDirection: String? = nil
  ) async throws(KaitenError) -> Page<Components.Schemas.CustomProperty> {
    try validatePagination(offset: offset, limit: limit)
    guard
      let response = try await callList({
        try await client.get_list_of_properties(
          query: .init(
            offset: offset, limit: limit, include_values: includeValues,
            include_author: includeAuthor, compact: compact, load_by_ids: loadByIds, ids: ids,
            order_by: orderBy, order_direction: orderDirection, query: query))
      })
    else {
      return Page(items: [], offset: offset, limit: limit)
    }
    let items: [Components.Schemas.CustomProperty] = try decodeResponse(response.toCase()) {
      try $0.json
    }
    return Page(items: items, offset: offset, limit: limit)
  }

  /// Fetches a single custom property definition by its identifier.
  ///
  /// - Parameter id: The custom property identifier.
  /// - Returns: The custom property definition.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the property does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func getCustomProperty(id: Int) async throws(KaitenError)
    -> Components.Schemas.CustomProperty
  {
    let response = try await call { try await client.get_property(path: .init(id: id)) }
    return try decodeResponse(response.toCase(), notFoundResource: ("customProperty", id)) {
      try $0.json
    }
  }

  /// Lists select values for a select-type custom property.
  ///
  /// - Parameters:
  ///   - propertyId: The custom property identifier.
  ///   - v2SelectSearch: Enable additional filtering capabilities.
  ///   - query: Filter by select value (requires `v2SelectSearch`).
  ///   - orderBy: Field to sort by (requires `v2SelectSearch`).
  ///   - ids: Array of value IDs to filter by (requires `v2SelectSearch`).
  ///   - conditions: Array of conditions to filter by (requires `v2SelectSearch`).
  ///   - offset: Number of records to skip (requires `v2SelectSearch`).
  ///   - limit: Maximum number of values to return (requires `v2SelectSearch`, default `100`).
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
    v2SelectSearch: Bool? = nil,
    query: String? = nil,
    orderBy: String? = nil,
    ids: [Int]? = nil,
    conditions: [String]? = nil,
    offset: Int = 0,
    limit: Int = 100
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
}
