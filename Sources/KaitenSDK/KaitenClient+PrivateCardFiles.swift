import Foundation
import OpenAPIRuntime

// MARK: - Private Card Files

// The private-card-files routes address the card by UID and the file by UUID string id —
// a route family separate from the integer-id card-files endpoints. They are live only
// when "Restricted file access" is enabled in company settings, and the Kaiten docs mark
// the whole section as under active development.

extension KaitenClient {
  /// Attaches a file to a card addressed by UID (private files).
  ///
  /// The file is uploaded as `multipart/form-data`. Requires "Restricted file access"
  /// enabled in company settings.
  ///
  /// - Parameters:
  ///   - cardUid: The card UID.
  ///   - fileData: The file content.
  ///   - filename: The file name sent in the multipart `Content-Disposition` header.
  /// - Returns: The attached private file.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for validation errors (400),
  ///     forbidden (403), not found (404) or other undocumented HTTP status codes. A 404 is
  ///     reported as `unexpectedResponse` rather than ``KaitenError/notFound(resource:id:)``
  ///     because the card is addressed by string UID.
  public func attachPrivateFile(
    cardUid: String,
    fileData: Data,
    filename: String
  ) async throws(KaitenError) -> Components.Schemas.PrivateCardFile {
    let response = try await call {
      try await client.attach_private_card_file(
        path: .init(card_uid: cardUid),
        body: .multipartForm([
          .file(.init(payload: .init(body: HTTPBody(fileData)), filename: filename))
        ])
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Retrieves the metadata and signed URL of a private card file.
  ///
  /// Requires "Restricted file access" enabled in company settings. The API answers 404 for
  /// a file uploaded without restricted access.
  ///
  /// - Parameters:
  ///   - cardUid: The card UID.
  ///   - fileId: The file ID.
  ///   - download: If `true`, the signed URL serves the file as an attachment.
  /// - Returns: The file metadata with its signed URL.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403), not found
  ///     (404), malicious files (422) or other undocumented HTTP status codes. A 404 is
  ///     reported as `unexpectedResponse` rather than ``KaitenError/notFound(resource:id:)``
  ///     because the file is addressed by string ID.
  public func getPrivateCardFile(
    cardUid: String,
    fileId: String,
    download: Bool? = nil
  ) async throws(KaitenError) -> Components.Schemas.PrivateCardFileUrlResponse {
    let response = try await call {
      try await client.get_private_card_file(
        path: .init(card_uid: cardUid, id: fileId),
        query: .init(download: download)
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Updates a private card file.
  ///
  /// Requires "Restricted file access" enabled in company settings.
  ///
  /// - Parameters:
  ///   - cardUid: The card UID.
  ///   - fileId: The file ID.
  ///   - name: The new file name.
  ///   - cardCover: Whether the image is used as the card cover.
  /// - Returns: The updated file.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for validation errors (400),
  ///     forbidden (403), not found (404) or other undocumented HTTP status codes.
  public func updatePrivateFile(
    cardUid: String,
    fileId: String,
    name: String? = nil,
    cardCover: Bool? = nil
  ) async throws(KaitenError) -> Components.Schemas.PrivateCardFile {
    let response = try await call {
      try await client.update_private_card_file(
        path: .init(card_uid: cardUid, id: fileId),
        body: .json(.init(name: name, card_cover: cardCover))
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Retrieves the signed URL of a private card file.
  ///
  /// Deprecated: the API ignores `response_type` and always answers with the file metadata,
  /// of which this method keeps only the URL.
  ///
  /// - Parameters:
  ///   - cardUid: The card UID.
  ///   - fileId: The file ID.
  ///   - responseType: Sent as `response_type`; ignored by the API.
  /// - Returns: The signed file URL.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403), not found
  ///     (404), malicious files (422) or other undocumented HTTP status codes.
  @available(
    *, deprecated,
    message: "The API ignores response_type. Use getPrivateCardFile(cardUid:fileId:download:)."
  )
  public func getPrivateFile(
    cardUid: String,
    fileId: String,
    responseType: PrivateCardFileResponseType = .json
  ) async throws(KaitenError) -> String {
    let response = try await call {
      try await client.get_private_card_file(
        path: .init(card_uid: cardUid, id: fileId),
        query: .init(response_type: responseType.rawValue)
      )
    }
    let result: Components.Schemas.PrivateCardFileUrlResponse = try decodeResponse(
      response.toCase()
    ) { try $0.json }
    return result.url
  }

  /// Deletes a private card file.
  ///
  /// Requires "Restricted file access" enabled in company settings.
  ///
  /// - Parameters:
  ///   - cardUid: The card UID.
  ///   - fileId: The file ID.
  /// - Returns: The deleted file ID.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403), not found
  ///     (404) or other undocumented HTTP status codes. A 404 is reported as
  ///     `unexpectedResponse` rather than ``KaitenError/notFound(resource:id:)`` because the
  ///     file is addressed by string ID.
  public func deletePrivateFile(cardUid: String, fileId: String) async throws(KaitenError)
    -> String
  {
    let response = try await call {
      try await client.delete_private_card_file(path: .init(card_uid: cardUid, id: fileId))
    }
    let result: Components.Schemas.DeletedPrivateCardFileResponse = try decodeResponse(
      response.toCase()
    ) { try $0.json }
    return result.id
  }
}
