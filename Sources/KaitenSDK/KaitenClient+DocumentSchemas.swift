import Foundation
import OpenAPIRuntime

// MARK: - Typed Variants

// GET /document-schemas/{id} returns one of two structurally different objects,
// selected by the request's `format` query parameter. The generated `anyOf`
// surface exposes them as `value1`/`value2`; these accessors give the variants
// readable names.

extension Components.Schemas.DocumentSchema {
  /// The JSON Schema draft-06 variant, or `nil` when the response carries the
  /// ProseMirror variant.
  public var draft06: Components.Schemas.DocumentSchemaDraft06? {
    value1
  }

  /// The sanitized ProseMirror variant, or `nil` when the response carries the
  /// JSON Schema draft-06 variant.
  public var proseMirror: Components.Schemas.DocumentSchemaProseMirror? {
    value2
  }
}

// MARK: - Document Schemas

extension KaitenClient {
  /// Gets the schema used to validate and describe document data in ProseMirror JSON format.
  ///
  /// - Parameters:
  ///   - id: The document schema version. Pass `latest` for the latest available schema, or a
  ///     concrete version in `v{number}` format, for example `v25`. When `latest` is passed, the
  ///     response `version` field contains the resolved `v{number}` version.
  ///   - format: The response format. The API defaults to ``DocumentSchemaFormat/draft06``, which
  ///     returns a JSON Schema draft-06 document; ``DocumentSchemaFormat/proseMirror`` returns
  ///     sanitized ProseMirror node and mark specs.
  /// - Returns: The document data schema. Exactly one of
  ///   ``Components/Schemas/DocumentSchema/draft06`` and
  ///   ``Components/Schemas/DocumentSchema/proseMirror`` is populated, matching the requested
  ///   format.
  /// - Throws:
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for unsupported format (400),
  ///     schema version not found (404) or other undocumented HTTP status codes. A 404 is
  ///     reported as `unexpectedResponse` rather than ``KaitenError/notFound(resource:id:)``
  ///     because document schemas are addressed by string version, which that case cannot
  ///     represent.
  public func getDocumentSchema(
    id: String,
    format: DocumentSchemaFormat? = nil
  ) async throws(KaitenError) -> Components.Schemas.DocumentSchema {
    let response = try await call {
      try await client.get_document_schema(
        path: .init(id: id),
        query: .init(format: format?.rawValue)
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }
}
