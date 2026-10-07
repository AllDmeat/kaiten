import Foundation
import OpenAPIRuntime

// MARK: - Typed Discriminators

// The regular-property key travels as a plain string (see `CardTypeRegularProperty`
// in `Enums.swift`). These accessors and initializers give the generated payloads
// a typed surface without losing undocumented values.

extension Components.Schemas.CardTypeProperty {
  /// The regular-property key, or `nil` if the property is a custom property.
  public var regularPropertyKey: CardTypeRegularProperty? {
    regular_property.map(CardTypeRegularProperty.init(rawValue:))
  }
}

extension Components.Schemas.CardTypePropertyInput {
  /// Creates an input for a regular (preset) card property.
  ///
  /// - Parameters:
  ///   - regularProperty: The regular-property key.
  ///   - sortOrder: Order of the property in the card.
  ///   - required: Whether the property is required to fill in the card.
  public init(
    regularProperty: CardTypeRegularProperty,
    sortOrder: Double? = nil,
    required: Bool
  ) {
    self.init(
      regular_property: regularProperty.rawValue, sort_order: sortOrder, required: required)
  }

  /// Creates an input for a custom card property.
  ///
  /// - Parameters:
  ///   - propertyUid: The UID of the custom property.
  ///   - sortOrder: Order of the property in the card.
  ///   - required: Whether the property is required to fill in the card.
  public init(
    propertyUid: String,
    sortOrder: Double? = nil,
    required: Bool
  ) {
    self.init(property_uid: propertyUid, sort_order: sortOrder, required: required)
  }
}

// MARK: - Card Types

extension KaitenClient {
  /// Gets a card type by ID.
  ///
  /// - Parameter id: The card type identifier.
  /// - Returns: The card type.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card type does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other undocumented HTTP status codes.
  public func getCardType(id: Int) async throws(KaitenError) -> Components.Schemas.CardType {
    let response = try await call {
      try await client.get_card_type(path: .init(id: id))
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("cardType", id)) {
      try $0.json
    }
  }

  /// Creates a new card type.
  ///
  /// - Parameters:
  ///   - letter: Character that represents the type. Kaiten accepts 1 character (up to 11 for emoji).
  ///   - name: The type name (1 to 64 characters).
  ///   - color: The color number (2 to 25).
  ///   - cardProperties: Card properties that will be suggested for filling in cards of this type.
  ///   - suggestFields: Whether cards of this type will be offered to display additional fields
  ///     based on statistics.
  /// - Returns: The created card type.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for validation error (400),
  ///     forbidden (403) or other undocumented HTTP status codes.
  public func createCardType(
    letter: String,
    name: String,
    color: Int,
    cardProperties: [Components.Schemas.CardTypePropertyInput]? = nil,
    suggestFields: Bool? = nil
  ) async throws(KaitenError) -> Components.Schemas.CardType {
    try await createCardType(
      body: .init(
        letter: letter, name: name, color: color, card_properties: cardProperties,
        suggest_fields: suggestFields))
  }

  /// Creates a new card type with the old-format `properties`.
  ///
  /// Kaiten deprecated `properties` in favour of `card_properties`.
  @available(
    *, deprecated,
    message: "Kaiten deprecated card type properties. Use cardProperties instead."
  )
  public func createCardType(
    letter: String,
    name: String,
    color: Int,
    properties: OpenAPIRuntime.OpenAPIObjectContainer?,
    cardProperties: [Components.Schemas.CardTypePropertyInput]? = nil,
    suggestFields: Bool? = nil
  ) async throws(KaitenError) -> Components.Schemas.CardType {
    var body = Components.Schemas.CreateCardTypeRequest(
      letter: letter, name: name, color: color, card_properties: cardProperties,
      suggest_fields: suggestFields)
    body.properties = properties
    return try await createCardType(body: body)
  }

  private func createCardType(
    body: Components.Schemas.CreateCardTypeRequest
  ) async throws(KaitenError) -> Components.Schemas.CardType {
    let response = try await call {
      try await client.create_card_type(body: .json(body))
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Updates a card type.
  ///
  /// - Parameters:
  ///   - id: The card type identifier.
  ///   - letter: The updated letter. Kaiten accepts 1 character (up to 11 for emoji).
  ///   - name: The updated type name (1 to 64 characters).
  ///   - color: The updated color number (2 to 25).
  ///   - cardProperties: Card properties that will be suggested for filling in cards of this type.
  ///   - suggestFields: Whether cards of this type will be offered to display additional fields
  ///     based on statistics.
  /// - Returns: The updated card type.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card type does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for validation error (400),
  ///     forbidden (403) or other undocumented HTTP status codes.
  public func updateCardType(
    id: Int,
    letter: String? = nil,
    name: String? = nil,
    color: Int? = nil,
    cardProperties: [Components.Schemas.CardTypePropertyInput]? = nil,
    suggestFields: Bool? = nil
  ) async throws(KaitenError) -> Components.Schemas.CardType {
    try await updateCardType(
      id: id,
      body: .init(
        letter: letter, name: name, color: color, card_properties: cardProperties,
        suggest_fields: suggestFields))
  }

  /// Updates a card type with the old-format `properties`.
  ///
  /// Kaiten deprecated `properties` in favour of `card_properties`.
  @available(
    *, deprecated,
    message: "Kaiten deprecated card type properties. Use cardProperties instead."
  )
  public func updateCardType(
    id: Int,
    letter: String? = nil,
    name: String? = nil,
    color: Int? = nil,
    properties: OpenAPIRuntime.OpenAPIObjectContainer?,
    cardProperties: [Components.Schemas.CardTypePropertyInput]? = nil,
    suggestFields: Bool? = nil
  ) async throws(KaitenError) -> Components.Schemas.CardType {
    var body = Components.Schemas.UpdateCardTypeRequest(
      letter: letter, name: name, color: color, card_properties: cardProperties,
      suggest_fields: suggestFields)
    body.properties = properties
    return try await updateCardType(id: id, body: body)
  }

  private func updateCardType(
    id: Int, body: Components.Schemas.UpdateCardTypeRequest
  ) async throws(KaitenError) -> Components.Schemas.CardType {
    let response = try await call {
      try await client.update_card_type(path: .init(id: id), body: .json(body))
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("cardType", id)) {
      try $0.json
    }
  }

  /// Removes a card type.
  ///
  /// Cards of the removed type are reassigned to the replacement type.
  ///
  /// - Parameters:
  ///   - id: The card type identifier.
  ///   - replaceTypeId: The identifier of the card type that replaces the removed type in
  ///     existing cards.
  /// - Returns: The removed card type.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card type does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for validation error (400),
  ///     forbidden (403) or other undocumented HTTP status codes.
  public func deleteCardType(
    id: Int, replaceTypeId: Int
  ) async throws(KaitenError) -> Components.Schemas.CardType {
    let response = try await call {
      try await client.delete_card_type(
        path: .init(id: id),
        body: .json(.init(replace_type_id: Double(replaceTypeId)))
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("cardType", id)) {
      try $0.json
    }
  }
}
