import Foundation
import OpenAPIRuntime

// MARK: - Private Custom Property Files

// Kaiten marks these endpoints as under active development and requires the
// "Restricted file access" company setting to be enabled for them to work.
// The resources are addressed by string UIDs, so a 404 surfaces as
// `unexpectedResponse(statusCode: 404)` per FR-021 — the response does not say
// whether the card, the property or the file is missing.

extension KaitenClient {
  /// Attaches a file to a card's custom property.
  ///
  /// The file is uploaded as `multipart/form-data`. The endpoint requires the
  /// "Restricted file access" company setting to be enabled.
  ///
  /// - Parameters:
  ///   - cardUid: The card UID.
  ///   - propertyUid: The custom property UID.
  ///   - fileData: The file content.
  ///   - filename: The file name sent in the multipart `Content-Disposition` header.
  /// - Returns: The attached custom property file.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for validation errors (400),
  ///     forbidden (403), not found (404) or other undocumented HTTP status codes.
  public func attachFileToCustomProperty(
    cardUid: String,
    propertyUid: String,
    fileData: Data,
    filename: String
  ) async throws(KaitenError) -> Components.Schemas.CustomPropertyFile {
    let response = try await call {
      try await client.attach_file_to_custom_property(
        path: .init(card_uid: cardUid, property_uid: propertyUid),
        body: .multipartForm([
          .file(.init(payload: .init(body: HTTPBody(fileData)), filename: filename))
        ])
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Retrieves the metadata and signed URL of a custom property file.
  ///
  /// The endpoint requires the "Restricted file access" company setting to be enabled. The
  /// API answers 404 for a file uploaded without restricted access.
  ///
  /// - Parameters:
  ///   - cardUid: The card UID.
  ///   - propertyUid: The custom property UID.
  ///   - fileId: The file ID.
  ///   - download: If `true`, the signed URL serves the file as an attachment.
  /// - Returns: The file metadata with its signed URL.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403), not found
  ///     (404) or other undocumented HTTP status codes.
  public func getCustomPropertyFile(
    cardUid: String,
    propertyUid: String,
    fileId: String,
    download: Bool? = nil
  ) async throws(KaitenError) -> Components.Schemas.CustomPropertyFileUrl {
    let response = try await call {
      try await client.get_custom_property_file(
        path: .init(card_uid: cardUid, property_uid: propertyUid, id: fileId),
        query: .init(download: download)
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Retrieves the signed URL of a custom property file.
  ///
  /// Deprecated: the API ignores `response_type` and always answers with the file metadata,
  /// of which this method keeps only the URL.
  ///
  /// - Parameters:
  ///   - cardUid: The card UID.
  ///   - propertyUid: The custom property UID.
  ///   - fileId: The file ID.
  ///   - responseType: Sent as `response_type`; ignored by the API.
  /// - Returns: The signed file URL.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403), not found
  ///     (404) or other undocumented HTTP status codes.
  @available(
    *, deprecated,
    message:
      "The API ignores response_type. Use getCustomPropertyFile(cardUid:propertyUid:fileId:download:)."
  )
  public func getCustomPropertyFileUrl(
    cardUid: String,
    propertyUid: String,
    fileId: String,
    responseType: CustomPropertyFileResponseType = .json
  ) async throws(KaitenError) -> String {
    let response = try await call {
      try await client.get_custom_property_file(
        path: .init(card_uid: cardUid, property_uid: propertyUid, id: fileId),
        query: .init(response_type: responseType.rawValue)
      )
    }
    let result: Components.Schemas.CustomPropertyFileUrl = try decodeResponse(response.toCase()) {
      try $0.json
    }
    return result.url
  }

  /// Updates a custom property file.
  ///
  /// The endpoint requires the "Restricted file access" company setting to be enabled. The
  /// API answers 403 for a locked card.
  ///
  /// - Parameters:
  ///   - cardUid: The card UID.
  ///   - propertyUid: The custom property UID.
  ///   - fileId: The file ID.
  ///   - name: The new file name.
  ///   - cardCover: Whether the image is used as the card cover.
  /// - Returns: The updated custom property file.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for validation errors (400),
  ///     forbidden (403), not found (404) or other undocumented HTTP status codes.
  public func updateCustomPropertyFile(
    cardUid: String,
    propertyUid: String,
    fileId: String,
    name: String? = nil,
    cardCover: Bool? = nil
  ) async throws(KaitenError) -> Components.Schemas.CustomPropertyFile {
    let response = try await call {
      try await client.update_custom_property_file(
        path: .init(card_uid: cardUid, property_uid: propertyUid, id: fileId),
        body: .json(.init(name: name, card_cover: cardCover))
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Deletes a custom property file.
  ///
  /// The endpoint requires the "Restricted file access" company setting to be enabled.
  ///
  /// - Parameters:
  ///   - cardUid: The card UID.
  ///   - propertyUid: The custom property UID.
  ///   - fileId: The file ID.
  /// - Returns: The deleted file ID.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403), not found
  ///     (404) or other undocumented HTTP status codes.
  public func deleteCustomPropertyFile(
    cardUid: String,
    propertyUid: String,
    fileId: String
  ) async throws(KaitenError) -> String {
    let response = try await call {
      try await client.delete_custom_property_file(
        path: .init(card_uid: cardUid, property_uid: propertyUid, id: fileId)
      )
    }
    let result: Components.Schemas.DeletedCustomPropertyFileResponse = try decodeResponse(
      response.toCase()
    ) { try $0.json }
    return result.id
  }
}
