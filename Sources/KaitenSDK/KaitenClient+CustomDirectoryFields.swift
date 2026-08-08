import Foundation
import OpenAPIRuntime

// MARK: - Custom Directory Fields

extension KaitenClient {
  /// Lists the fields of a custom directory.
  ///
  /// The Kaiten documentation marks the custom directories API as beta; parameters and
  /// response shapes may change.
  ///
  /// - Parameters:
  ///   - directoryId: The custom directory identifier.
  ///   - includeAuthor: Include the author user object in each field.
  ///   - conditions: Filter fields by condition.
  /// - Returns: An array of directory fields. Returns an empty array if the directory has no fields.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for not found (404) or other
  ///     undocumented HTTP status codes. A 404 is reported as `unexpectedResponse` rather than
  ///     ``KaitenError/notFound(resource:id:)`` because directories are addressed by string UUID.
  public func listCustomDirectoryFields(
    directoryId: String,
    includeAuthor: Bool? = nil,
    conditions: [CustomDirectoryCondition]? = nil
  ) async throws(KaitenError) -> [Components.Schemas.CustomDirectoryField] {
    guard
      let response = try await callList({
        try await client.list_custom_directory_fields(
          path: .init(directory_id: directoryId),
          query: .init(
            include_author: includeAuthor,
            conditions: conditions.map { $0.map(\.rawValue) }
          )
        )
      })
    else {
      return []
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Creates a field in a custom directory.
  ///
  /// The Kaiten documentation marks the custom directories API as beta; parameters and
  /// response shapes may change. Advanced field bindings (`custom_property_uid`,
  /// `linked_directory_id`) are typically configured via directory create/update endpoints.
  ///
  /// - Parameters:
  ///   - directoryId: The custom directory identifier.
  ///   - name: The field name. Kaiten accepts 1 to 256 characters.
  ///   - type: The field type.
  ///   - sortOrder: The field position. Kaiten accepts values from 0.
  ///   - required: Whether the field is required. Kaiten defaults to `false`.
  ///   - isDisplay: Whether the field is the display field. Kaiten defaults to `false`.
  /// - Returns: The created field.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for validation errors (400),
  ///     not found (404) or other undocumented HTTP status codes. A 404 is reported as
  ///     `unexpectedResponse` rather than ``KaitenError/notFound(resource:id:)`` because
  ///     directories are addressed by string UUID.
  public func createCustomDirectoryField(
    directoryId: String,
    name: String,
    type: CustomDirectoryFieldType,
    sortOrder: Int? = nil,
    required: Bool? = nil,
    isDisplay: Bool? = nil
  ) async throws(KaitenError) -> Components.Schemas.CustomDirectoryField {
    let response = try await call {
      try await client.create_custom_directory_field(
        path: .init(directory_id: directoryId),
        body: .json(
          .init(
            name: name,
            _type: type.rawValue,
            required: required,
            sort_order: sortOrder,
            is_display: isDisplay
          ))
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Fetches a single field of a custom directory.
  ///
  /// The response embeds the author user object, and — where applicable — the linked
  /// directory and custom property objects. The Kaiten documentation marks the custom
  /// directories API as beta; parameters and response shapes may change.
  ///
  /// - Parameters:
  ///   - directoryId: The custom directory identifier.
  ///   - fieldId: The field identifier.
  /// - Returns: The directory field.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for not found (404) or other
  ///     undocumented HTTP status codes. A 404 is reported as `unexpectedResponse` rather than
  ///     ``KaitenError/notFound(resource:id:)`` because directories and fields are addressed by
  ///     string UUID and the response does not say whether the directory or the field is missing.
  public func getCustomDirectoryField(
    directoryId: String,
    fieldId: String
  ) async throws(KaitenError) -> Components.Schemas.CustomDirectoryField {
    let response = try await call {
      try await client.get_custom_directory_field(
        path: .init(directory_id: directoryId, field_id: fieldId)
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Updates a field of a custom directory.
  ///
  /// The Kaiten documentation marks the custom directories API as beta; parameters and
  /// response shapes may change.
  ///
  /// - Parameters:
  ///   - directoryId: The custom directory identifier.
  ///   - fieldId: The field identifier.
  ///   - name: The updated field name. Kaiten accepts 1 to 256 characters.
  ///   - condition: The updated field condition.
  ///   - sortOrder: The updated field position. Kaiten accepts values from 0.
  ///   - required: Whether the field is required.
  ///   - isDisplay: Whether the field is the display field.
  /// - Returns: The updated field.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for not found (404) or other
  ///     undocumented HTTP status codes. A 404 is reported as `unexpectedResponse` rather than
  ///     ``KaitenError/notFound(resource:id:)`` because directories and fields are addressed by
  ///     string UUID and the response does not say whether the directory or the field is missing.
  public func updateCustomDirectoryField(
    directoryId: String,
    fieldId: String,
    name: String? = nil,
    condition: CustomDirectoryCondition? = nil,
    sortOrder: Int? = nil,
    required: Bool? = nil,
    isDisplay: Bool? = nil
  ) async throws(KaitenError) -> Components.Schemas.CustomDirectoryField {
    let response = try await call {
      try await client.update_custom_directory_field(
        path: .init(directory_id: directoryId, field_id: fieldId),
        body: .json(
          .init(
            name: name,
            condition: condition?.rawValue,
            required: required,
            is_display: isDisplay,
            sort_order: sortOrder
          ))
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Deletes a field of a custom directory.
  ///
  /// The endpoint soft-deletes the field (its condition becomes `removed`) and returns
  /// the removed field. The Kaiten documentation marks the custom directories API as
  /// beta; parameters and response shapes may change.
  ///
  /// - Parameters:
  ///   - directoryId: The custom directory identifier.
  ///   - fieldId: The field identifier.
  /// - Returns: The removed field.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for not found (404) or other
  ///     undocumented HTTP status codes. A 404 is reported as `unexpectedResponse` rather than
  ///     ``KaitenError/notFound(resource:id:)`` because directories and fields are addressed by
  ///     string UUID and the response does not say whether the directory or the field is missing.
  public func deleteCustomDirectoryField(
    directoryId: String,
    fieldId: String
  ) async throws(KaitenError) -> Components.Schemas.CustomDirectoryField {
    let response = try await call {
      try await client.delete_custom_directory_field(
        path: .init(directory_id: directoryId, field_id: fieldId)
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }
}
