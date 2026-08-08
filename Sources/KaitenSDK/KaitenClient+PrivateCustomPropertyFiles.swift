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

  /// Retrieves the signed URL of a custom property file.
  ///
  /// The endpoint requires the "Restricted file access" company setting to be
  /// enabled. With ``CustomPropertyFileResponseType/json`` (the default) the API
  /// returns the signed URL as JSON. With ``CustomPropertyFileResponseType/inline``
  /// or ``CustomPropertyFileResponseType/attachment`` the API responds with a 302
  /// redirect to the file itself; the underlying transport follows the redirect,
  /// so the response is the raw file content and cannot be decoded as JSON — those
  /// values are only useful for clients that handle redirects themselves.
  ///
  /// - Parameters:
  ///   - cardUid: The card UID.
  ///   - propertyUid: The custom property UID.
  ///   - fileId: The file ID.
  ///   - responseType: The documented `response_type` query parameter. Defaults to `.json`.
  /// - Returns: The signed file URL.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403), not found
  ///     (404) or other undocumented HTTP status codes.
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
