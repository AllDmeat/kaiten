import Foundation
import OpenAPIRuntime

// MARK: - Typed Discriminators

// Custom directory discriminators travel as plain strings (see the comment
// above the custom directory enums in `Enums.swift`). These accessors and
// initializers give the generated payloads a typed surface without losing
// undocumented values.

extension Components.Schemas.CustomDirectory {
  /// The directory condition, or `nil` if the API omitted the field.
  public var directoryCondition: CustomDirectoryCondition? {
    condition.map(CustomDirectoryCondition.init(rawValue:))
  }
}

extension Components.Schemas.CustomDirectoryField {
  /// The field type, or `nil` if the API omitted the field.
  public var fieldType: CustomDirectoryFieldType? {
    _type.map(CustomDirectoryFieldType.init(rawValue:))
  }

  /// The field condition, or `nil` if the API omitted the field.
  public var fieldCondition: CustomDirectoryCondition? {
    condition.map(CustomDirectoryCondition.init(rawValue:))
  }
}

extension Components.Schemas.DeleteCustomDirectoryResponse {
  /// The directory condition after deletion, or `nil` if the API omitted the field.
  public var directoryCondition: CustomDirectoryCondition? {
    condition.map(CustomDirectoryCondition.init(rawValue:))
  }
}

extension Components.Schemas.CreateCustomDirectoryFieldRequest {
  /// Creates a field definition from a typed field type.
  ///
  /// - Parameters:
  ///   - fieldType: The field type.
  ///   - name: The field name.
  ///   - required: Whether the field is required.
  ///   - sortOrder: The field position.
  ///   - customPropertyUid: The custom property UID. Required for `select`, `user` and
  ///     `catalog` fields.
  ///   - linkedDirectoryId: The linked custom directory ID. Required for `directory_link`
  ///     fields.
  public init(
    fieldType: CustomDirectoryFieldType,
    name: String,
    required: Bool? = nil,
    sortOrder: Int? = nil,
    customPropertyUid: String? = nil,
    linkedDirectoryId: String? = nil
  ) {
    self.init(
      name: name,
      _type: fieldType.rawValue,
      required: required,
      sort_order: sortOrder,
      custom_property_uid: customPropertyUid,
      linked_directory_id: linkedDirectoryId
    )
  }
}

extension Components.Schemas.UpdateCustomDirectoryFieldRequest {
  /// Creates a field update from a typed field type.
  ///
  /// - Parameters:
  ///   - id: The field ID. Pass to update an existing field; omit to create a new one.
  ///   - fieldType: The field type.
  ///   - name: The field name.
  ///   - required: Whether the field is required.
  ///   - isDisplay: Whether the field is the display field. Only one field should have
  ///     `isDisplay` set to `true`.
  ///   - sortOrder: The field position.
  ///   - customPropertyUid: The custom property UID. Required for `select`, `user` and
  ///     `catalog` fields.
  ///   - linkedDirectoryId: The linked custom directory ID. Required for `directory_link`
  ///     fields.
  public init(
    id: String? = nil,
    fieldType: CustomDirectoryFieldType? = nil,
    name: String? = nil,
    required: Bool? = nil,
    isDisplay: Bool? = nil,
    sortOrder: Int? = nil,
    customPropertyUid: String? = nil,
    linkedDirectoryId: String? = nil
  ) {
    self.init(
      id: id,
      name: name,
      _type: fieldType?.rawValue,
      required: required,
      is_display: isDisplay,
      sort_order: sortOrder,
      custom_property_uid: customPropertyUid,
      linked_directory_id: linkedDirectoryId
    )
  }
}

// MARK: - Custom Directories

extension KaitenClient {
  /// Returns a page of custom directories for the current company.
  ///
  /// The custom-directories API is documented as beta: parameters, attributes and response
  /// formats are subject to change. Directories whose condition is not `active` are returned
  /// only when `conditions` names them.
  ///
  /// - Parameters:
  ///   - includeFields: Include directory fields in each directory (optional).
  ///   - includeAuthor: Include the author user object in each directory (optional).
  ///   - includeRecordsCount: Include `records_count` in each directory (optional).
  ///   - query: Search by directory name, case-insensitive (optional).
  ///   - conditions: Filter by condition values (optional).
  ///   - offset: Number of directories to skip (default `0`).
  ///   - limit: Maximum number of directories to return (default `200`, max `200`).
  /// - Returns: A ``Page`` of custom directories. Returns an empty page when no directories match.
  /// - Throws:
  ///   - ``KaitenError/invalidPaginationRange(offset:limit:)`` if pagination parameters are out of range.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other
  ///     undocumented HTTP status codes.
  public func listCustomDirectories(
    includeFields: Bool? = nil,
    includeAuthor: Bool? = nil,
    includeRecordsCount: Bool? = nil,
    query: String? = nil,
    conditions: [CustomDirectoryCondition]? = nil,
    offset: Int = 0,
    limit: Int = 200
  ) async throws(KaitenError) -> Page<Components.Schemas.CustomDirectory> {
    guard offset >= 0, (1...200).contains(limit) else {
      throw .invalidPaginationRange(offset: offset, limit: limit)
    }
    let query = Operations.list_custom_directories.Input.Query(
      include_fields: includeFields,
      include_author: includeAuthor,
      include_records_count: includeRecordsCount,
      limit: limit,
      offset: offset,
      query: query,
      conditions_lbrack__rbrack_: conditions.map { $0.map(\.rawValue) }
    )
    guard
      let response = try await callList({
        try await client.list_custom_directories(query: query)
      })
    else {
      return Page(items: [], offset: offset, limit: limit)
    }
    let items: [Components.Schemas.CustomDirectory] = try decodeResponse(response.toCase()) {
      try $0.json
    }
    return Page(items: items, offset: offset, limit: limit)
  }

  /// Creates a custom directory.
  ///
  /// The custom-directories API is documented as beta: parameters, attributes and response
  /// formats are subject to change.
  ///
  /// - Parameters:
  ///   - name: The directory name.
  ///   - description: The directory description.
  ///   - multiSelect: Whether directory records can store multiple values per field.
  ///   - allowEditing: Whether directory records can be edited from cards without the custom
  ///     properties permission.
  ///   - displayFieldIndex: Index of the field to use as the display field. If omitted, the
  ///     first field is used.
  ///   - fields: The directory fields definition.
  /// - Returns: The created directory.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for validation errors (400),
  ///     forbidden (403) or other undocumented HTTP status codes.
  public func createCustomDirectory(
    name: String,
    description: String? = nil,
    multiSelect: Bool? = nil,
    allowEditing: Bool? = nil,
    displayFieldIndex: Int? = nil,
    fields: [Components.Schemas.CreateCustomDirectoryFieldRequest]? = nil
  ) async throws(KaitenError) -> Components.Schemas.CustomDirectory {
    let response = try await call {
      try await client.create_custom_directory(
        body: .json(
          .init(
            name: name,
            description: description,
            multi_select: multiSelect,
            allow_editing: allowEditing,
            display_field_index: displayFieldIndex,
            fields: fields
          ))
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Returns a custom directory.
  ///
  /// The custom-directories API is documented as beta: parameters, attributes and response
  /// formats are subject to change.
  ///
  /// - Parameter directoryId: The directory ID.
  /// - Returns: The directory.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for not found (404) or other
  ///     undocumented HTTP status codes. A 404 is reported as `unexpectedResponse` rather than
  ///     ``KaitenError/notFound(resource:id:)`` because directories are addressed by string ID.
  ///     Directories in the `removed` condition also answer 404.
  public func getCustomDirectory(
    directoryId: String
  ) async throws(KaitenError) -> Components.Schemas.CustomDirectory {
    let response = try await call {
      try await client.get_custom_directory(path: .init(directory_id: directoryId))
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Updates a custom directory.
  ///
  /// The custom-directories API is documented as beta: parameters, attributes and response
  /// formats are subject to change.
  ///
  /// - Parameters:
  ///   - directoryId: The directory ID.
  ///   - name: The updated directory name.
  ///   - description: The updated directory description. Pass `.some(nil)` to clear it;
  ///     `nil` leaves it unchanged.
  ///   - condition: The updated directory condition.
  ///   - multiSelect: Whether directory records can store multiple values per field.
  ///   - allowEditing: Whether directory records can be edited from cards without the custom
  ///     properties permission.
  ///   - fields: The full fields list. Fields omitted from this array are soft-deleted
  ///     (their condition becomes `removed`).
  /// - Returns: The updated directory.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for validation errors (400),
  ///     not found (404) or other undocumented HTTP status codes. A 404 is reported as
  ///     `unexpectedResponse` rather than ``KaitenError/notFound(resource:id:)`` because
  ///     directories are addressed by string ID.
  public func updateCustomDirectory(
    directoryId: String,
    name: String? = nil,
    description: String?? = .none,
    condition: CustomDirectoryCondition? = nil,
    multiSelect: Bool? = nil,
    allowEditing: Bool? = nil,
    fields: [Components.Schemas.UpdateCustomDirectoryFieldRequest]? = nil
  ) async throws(KaitenError) -> Components.Schemas.CustomDirectory {
    let response = try await call {
      try await client.update_custom_directory(
        path: .init(directory_id: directoryId),
        body: .json(
          .init(
            name: name,
            description: description.map { $0.map(ExplicitNullString.value) ?? .null },
            condition: condition?.rawValue,
            multi_select: multiSelect,
            allow_editing: allowEditing,
            fields: fields
          ))
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Deletes a custom directory.
  ///
  /// The directory is soft-deleted: its condition becomes `removed`. Deletion is not allowed
  /// while active custom properties are linked to the directory.
  ///
  /// - Parameter directoryId: The directory ID.
  /// - Returns: The deletion result carrying the directory ID and its condition.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for validation errors (400,
  ///     including deletion blocked by linked custom properties), not found (404) or other
  ///     undocumented HTTP status codes. A 404 is reported as `unexpectedResponse` rather than
  ///     ``KaitenError/notFound(resource:id:)`` because directories are addressed by string ID.
  public func deleteCustomDirectory(
    directoryId: String
  ) async throws(KaitenError) -> Components.Schemas.DeleteCustomDirectoryResponse {
    let response = try await call {
      try await client.delete_custom_directory(path: .init(directory_id: directoryId))
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }
}
