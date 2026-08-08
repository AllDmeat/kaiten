import Foundation
import OpenAPIRuntime

// MARK: - Typed Discriminators

extension Components.Schemas.CustomPropertyCatalogValue {
  /// The catalog value condition, or `nil` if the API omitted the field.
  public var catalogValueCondition: CatalogValueCondition? {
    condition.map(CatalogValueCondition.init(rawValue:))
  }
}

// MARK: - Custom Property Catalog Values

extension KaitenClient {
  /// Lists catalog values for a catalog-type custom property.
  ///
  /// - Parameters:
  ///   - propertyId: The custom property identifier.
  ///   - query: Text search filter by catalog values.
  ///   - conditions: Filter by catalog value condition (`.active` or `.inactive`).
  ///   - offset: Number of values to skip (default `0`).
  ///   - limit: Maximum number of values to return (default `100`).
  /// - Returns: A ``Page`` of catalog values.
  /// - Throws:
  ///   - ``KaitenError/invalidPaginationRange(offset:limit:)`` if pagination parameters are out of range.
  ///   - ``KaitenError/notFound(resource:id:)`` if the property does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func listCustomPropertyCatalogValues(
    propertyId: Int,
    query: String? = nil,
    conditions: CatalogValueCondition? = nil,
    offset: Int = 0,
    limit: Int = 100
  ) async throws(KaitenError) -> Page<Components.Schemas.CustomPropertyCatalogValue> {
    try validatePagination(offset: offset, limit: limit)
    guard
      let response = try await callList({
        try await client.get_list_of_catalog_values(
          path: .init(property_id: propertyId),
          query: .init(
            query: query, conditions: conditions?.rawValue, limit: limit, offset: offset))
      })
    else {
      return Page(items: [], offset: offset, limit: limit)
    }
    let items: [Components.Schemas.CustomPropertyCatalogValue] = try decodeResponse(
      response.toCase(), notFoundResource: ("customProperty", propertyId)
    ) { try $0.json }
    return Page(items: items, offset: offset, limit: limit)
  }

  /// Creates a catalog value for a catalog-type custom property.
  ///
  /// - Parameters:
  ///   - propertyId: The custom property identifier.
  ///   - value: Pairs of catalog field UID to field value.
  /// - Returns: The created catalog value.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the property does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for bad request (400), forbidden (403), or other undocumented HTTP status codes.
  public func createCustomPropertyCatalogValue(
    propertyId: Int,
    value: Components.Schemas.CreateCatalogValueRequest.valuePayload
  ) async throws(KaitenError) -> Components.Schemas.CustomPropertyCatalogValue {
    let response = try await call {
      try await client.create_catalog_value(
        path: .init(property_id: propertyId),
        body: .json(.init(value: value))
      )
    }
    return try decodeResponse(
      response.toCase(), notFoundResource: ("customProperty", propertyId)
    ) {
      try $0.json
    }
  }

  /// Fetches a single catalog value by its identifier.
  ///
  /// - Parameters:
  ///   - propertyId: The custom property identifier.
  ///   - id: The catalog value identifier.
  /// - Returns: The catalog value.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the value does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func getCustomPropertyCatalogValue(
    propertyId: Int,
    id: Int
  ) async throws(KaitenError) -> Components.Schemas.CustomPropertyCatalogValue {
    let response = try await call {
      try await client.get_catalog_value(path: .init(property_id: propertyId, id: id))
    }
    return try decodeResponse(
      response.toCase(), notFoundResource: ("customPropertyCatalogValue", id)
    ) {
      try $0.json
    }
  }

  /// Updates a catalog value.
  ///
  /// - Parameters:
  ///   - propertyId: The custom property identifier.
  ///   - id: The catalog value identifier.
  ///   - condition: The updated catalog value condition (`.active` or `.inactive`).
  ///   - value: Pairs of catalog field UID to field value.
  ///   - deleted: The updated delete condition.
  /// - Returns: The updated catalog value.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the value does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for bad request (400), forbidden (403), or other undocumented HTTP status codes.
  public func updateCustomPropertyCatalogValue(
    propertyId: Int,
    id: Int,
    condition: CatalogValueCondition? = nil,
    value: Components.Schemas.UpdateCatalogValueRequest.valuePayload? = nil,
    deleted: Bool? = nil
  ) async throws(KaitenError) -> Components.Schemas.CustomPropertyCatalogValue {
    let response = try await call {
      try await client.update_catalog_value(
        path: .init(property_id: propertyId, id: id),
        body: .json(.init(condition: condition?.rawValue, value: value, deleted: deleted))
      )
    }
    return try decodeResponse(
      response.toCase(), notFoundResource: ("customPropertyCatalogValue", id)
    ) {
      try $0.json
    }
  }

  /// Removes a catalog value.
  ///
  /// - Parameters:
  ///   - propertyId: The custom property identifier.
  ///   - id: The catalog value identifier.
  /// - Returns: The removed catalog value.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the value does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func removeCustomPropertyCatalogValue(
    propertyId: Int,
    id: Int
  ) async throws(KaitenError) -> Components.Schemas.CustomPropertyCatalogValue {
    let response = try await call {
      try await client.remove_catalog_value(path: .init(property_id: propertyId, id: id))
    }
    return try decodeResponse(
      response.toCase(), notFoundResource: ("customPropertyCatalogValue", id)
    ) {
      try $0.json
    }
  }
}
