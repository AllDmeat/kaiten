import Foundation
import OpenAPIRuntime

// MARK: - Typed Discriminators

// Custom property discriminators travel as plain strings (see the comment above
// the custom property enums in `Enums.swift`). These accessors give the
// generated payload a typed surface without losing undocumented values.

extension Components.Schemas.CustomProperty {
  /// The property value type, or `nil` if the API omitted the field.
  public var propertyType: CustomPropertyType? {
    _type.map(CustomPropertyType.init(rawValue:))
  }

  /// The property condition, or `nil` if the API omitted the field.
  public var propertyCondition: CustomPropertyCondition? {
    condition.map(CustomPropertyCondition.init(rawValue:))
  }

  /// The vote variant, or `nil` if the API omitted the field or returned `null`.
  public var propertyVoteVariant: CustomPropertyVoteVariant? {
    vote_variant.map(CustomPropertyVoteVariant.init(rawValue:))
  }

  /// The type of values, or `nil` if the API omitted the field or returned `null`.
  public var propertyValuesType: CustomPropertyValuesType? {
    values_type.map(CustomPropertyValuesType.init(rawValue:))
  }
}

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

  /// Creates a custom property definition.
  ///
  /// - Parameters:
  ///   - name: The custom property name (1...128 characters).
  ///   - type: The property value type. When `nil`, Kaiten defaults to ``CustomPropertyType/string``.
  ///   - showOnFacade: Whether to show the property on the card facade.
  ///   - multiline: Whether to render a multiline text field.
  ///   - voteVariant: The vote variant. Only meaningful for vote and collective vote properties.
  ///   - valuesType: The type of values. Only meaningful for collective value properties.
  ///   - colorful: Whether a colour is selected when creating new select values. Only meaningful for select properties.
  ///   - multiSelect: Whether the select property is used as a multi select. Only meaningful for select properties.
  ///   - valuesCreatableByUsers: Whether users with the writer role can create new select values. Only meaningful for select properties.
  ///   - data: Additional property data. Its shape depends on the property type and is
  ///     described only through examples in the Kaiten documentation.
  ///   - color: Colour of a catalog property, or `nil` for no colour.
  ///   - fieldsSettings: Field settings for catalog properties, keyed by field UID.
  /// - Returns: The created custom property definition.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for bad request (400), unsupported
  ///     tariff (402), forbidden (403) or other undocumented HTTP status codes.
  public func createCustomProperty(
    name: String,
    type: CustomPropertyType? = nil,
    showOnFacade: Bool? = nil,
    multiline: Bool? = nil,
    voteVariant: CustomPropertyVoteVariant? = nil,
    valuesType: CustomPropertyValuesType? = nil,
    colorful: Bool? = nil,
    multiSelect: Bool? = nil,
    valuesCreatableByUsers: Bool? = nil,
    data: Components.Schemas.CreateCustomPropertyRequest.dataPayload? = nil,
    color: Int? = nil,
    fieldsSettings: Components.Schemas.CreateCustomPropertyRequest.fields_settingsPayload? = nil
  ) async throws(KaitenError) -> Components.Schemas.CustomProperty {
    let response = try await call {
      try await client.create_property(
        body: .json(
          .init(
            name: name,
            _type: type?.rawValue,
            show_on_facade: showOnFacade,
            multiline: multiline,
            vote_variant: voteVariant?.rawValue,
            values_type: valuesType?.rawValue,
            colorful: colorful,
            multi_select: multiSelect,
            values_creatable_by_users: valuesCreatableByUsers,
            data: data,
            color: color,
            fields_settings: fieldsSettings
          ))
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Updates a custom property definition.
  ///
  /// - Parameters:
  ///   - id: The custom property identifier.
  ///   - name: The updated property name (1...128 characters).
  ///   - showOnFacade: Whether to show the property on the card facade.
  ///   - multiline: Whether to render a multiline text field.
  ///   - condition: The property condition.
  ///   - colorful: Whether a colour is selected when creating new select values. Only meaningful for select properties.
  ///   - multiSelect: Whether the select property is used as a multi select. Only meaningful for select properties.
  ///   - valuesCreatableByUsers: Whether users with the writer role can create new select values. Only meaningful for select properties.
  ///   - data: Additional property data. Its shape depends on the property type and is
  ///     described only through examples in the Kaiten documentation.
  ///   - color: Colour of a catalog property, or `nil` for no colour.
  ///   - fieldsSettings: Field settings for catalog properties, keyed by field UID.
  ///   - isUsedAsProgress: Whether to use the property value as a progress indicator.
  /// - Returns: The updated custom property definition.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the property does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for bad request (400), unsupported
  ///     tariff (402), forbidden (403) or other undocumented HTTP status codes.
  public func updateCustomProperty(
    id: Int,
    name: String? = nil,
    showOnFacade: Bool? = nil,
    multiline: Bool? = nil,
    condition: CustomPropertyCondition? = nil,
    colorful: Bool? = nil,
    multiSelect: Bool? = nil,
    valuesCreatableByUsers: Bool? = nil,
    data: Components.Schemas.UpdateCustomPropertyRequest.dataPayload? = nil,
    color: Int? = nil,
    fieldsSettings: Components.Schemas.UpdateCustomPropertyRequest.fields_settingsPayload? = nil,
    isUsedAsProgress: Bool? = nil
  ) async throws(KaitenError) -> Components.Schemas.CustomProperty {
    let response = try await call {
      try await client.update_property(
        path: .init(id: id),
        body: .json(
          .init(
            name: name,
            show_on_facade: showOnFacade,
            multiline: multiline,
            condition: condition?.rawValue,
            colorful: colorful,
            multi_select: multiSelect,
            values_creatable_by_users: valuesCreatableByUsers,
            data: data,
            color: color,
            fields_settings: fieldsSettings,
            is_used_as_progress: isUsedAsProgress
          ))
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("customProperty", id)) {
      try $0.json
    }
  }

  /// Removes a custom property definition.
  ///
  /// The endpoint returns HTTP 200 with the removed property definition.
  ///
  /// - Parameter id: The custom property identifier.
  /// - Returns: The removed custom property definition.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the property does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for bad request (400), forbidden
  ///     (403) or other undocumented HTTP status codes.
  @discardableResult
  public func removeCustomProperty(id: Int) async throws(KaitenError)
    -> Components.Schemas.CustomProperty
  {
    let response = try await call { try await client.remove_property(path: .init(id: id)) }
    return try decodeResponse(response.toCase(), notFoundResource: ("customProperty", id)) {
      try $0.json
    }
  }
}
