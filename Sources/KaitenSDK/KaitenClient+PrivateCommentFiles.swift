import Foundation
import OpenAPIRuntime

// MARK: - Private Comment Files

// All three endpoints require "Restricted file access" enabled in company settings and are
// documented as under active development. They address the card, the comment and the file by
// string UID, so a 404 surfaces as `unexpectedResponse` rather than `notFound(resource:id:)`,
// which carries an `Int` id.

extension KaitenClient {
  /// Attaches a file to a card comment.
  ///
  /// The file is uploaded as `multipart/form-data`. Requires "Restricted file access"
  /// enabled in company settings.
  ///
  /// - Parameters:
  ///   - cardUid: The card UID.
  ///   - commentUid: The comment UID, or `new` for a file uploaded to a comment that has not
  ///     been created yet.
  ///   - fileData: The file content.
  ///   - filename: The file name sent in the multipart `Content-Disposition` header.
  /// - Returns: The attached comment file.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for validation errors (400),
  ///     forbidden (403), not found (404) or other undocumented HTTP status codes. A 404 is
  ///     reported as `unexpectedResponse` rather than ``KaitenError/notFound(resource:id:)``
  ///     because the card and the comment are addressed by string UID.
  public func attachFileToComment(
    cardUid: String,
    commentUid: String,
    fileData: Data,
    filename: String
  ) async throws(KaitenError) -> Components.Schemas.CommentFile {
    let response = try await call {
      try await client.attach_file_to_comment(
        path: .init(card_uid: cardUid, comment_uid: commentUid),
        body: .multipartForm([
          .file(.init(payload: .init(body: HTTPBody(fileData)), filename: filename))
        ])
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Retrieves the metadata and signed URL of a file attached to a card comment.
  ///
  /// Requires "Restricted file access" enabled in company settings. The API answers 404 for
  /// a file uploaded without restricted access.
  ///
  /// - Parameters:
  ///   - cardUid: The card UID.
  ///   - commentUid: The comment UID, or `new` for a file uploaded to a comment that has not
  ///     been created yet.
  ///   - fileId: The file ID.
  ///   - download: If `true`, the signed URL serves the file as an attachment.
  /// - Returns: The file metadata with its signed URL.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403), not found
  ///     (404), a malicious file (422) or other undocumented HTTP status codes. A 404 is
  ///     reported as `unexpectedResponse` rather than ``KaitenError/notFound(resource:id:)``
  ///     because the file is addressed by string UID.
  public func getCommentFile(
    cardUid: String,
    commentUid: String,
    fileId: String,
    download: Bool? = nil
  ) async throws(KaitenError) -> Components.Schemas.CommentFileSignedUrl {
    let response = try await call {
      try await client.get_comment_file(
        path: .init(card_uid: cardUid, comment_uid: commentUid, id: fileId),
        query: .init(download: download)
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Gets a signed URL for a file attached to a card comment.
  ///
  /// Deprecated: the API ignores `response_type`.
  ///
  /// - Parameters:
  ///   - cardUid: The card UID.
  ///   - commentUid: The comment UID.
  ///   - fileId: The file ID.
  ///   - responseType: Sent as `response_type`; ignored by the API.
  /// - Returns: The file metadata with its signed URL.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403), not found
  ///     (404), a malicious file (422) or other undocumented HTTP status codes.
  @available(
    *, deprecated,
    message:
      "The API ignores response_type. Use getCommentFile(cardUid:commentUid:fileId:download:)."
  )
  public func getCommentFile(
    cardUid: String,
    commentUid: String,
    fileId: String,
    responseType: CommentFileResponseType
  ) async throws(KaitenError) -> Components.Schemas.CommentFileSignedUrl {
    let response = try await call {
      try await client.get_comment_file(
        path: .init(card_uid: cardUid, comment_uid: commentUid, id: fileId),
        query: .init(response_type: responseType.rawValue)
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Updates a file attached to a card comment.
  ///
  /// Requires "Restricted file access" enabled in company settings. Setting `cardCover` to
  /// `true` additionally requires card update permission.
  ///
  /// - Parameters:
  ///   - cardUid: The card UID.
  ///   - commentUid: The comment UID, or `new` for a file uploaded to a comment that has not
  ///     been created yet.
  ///   - fileId: The file ID.
  ///   - name: The new file name.
  ///   - cardCover: Whether the image is used as the card cover.
  /// - Returns: The updated comment file.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for validation errors (400),
  ///     forbidden (403), not found (404) or other undocumented HTTP status codes.
  public func updateCommentFile(
    cardUid: String,
    commentUid: String,
    fileId: String,
    name: String? = nil,
    cardCover: Bool? = nil
  ) async throws(KaitenError) -> Components.Schemas.CommentFile {
    let response = try await call {
      try await client.update_comment_file(
        path: .init(card_uid: cardUid, comment_uid: commentUid, id: fileId),
        body: .json(.init(name: name, card_cover: cardCover))
      )
    }
    return try decodeResponse(response.toCase()) { try $0.json }
  }

  /// Deletes a file attached to a card comment.
  ///
  /// Requires "Restricted file access" enabled in company settings.
  ///
  /// - Parameters:
  ///   - cardUid: The card UID.
  ///   - commentUid: The comment UID.
  ///   - fileId: The file ID.
  /// - Returns: The deleted file id.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403), not found
  ///     (404) or other undocumented HTTP status codes. A 404 is reported as
  ///     `unexpectedResponse` rather than ``KaitenError/notFound(resource:id:)`` because the
  ///     file is addressed by string UID.
  public func deleteCommentFile(
    cardUid: String,
    commentUid: String,
    fileId: String
  ) async throws(KaitenError) -> String {
    let response = try await call {
      try await client.delete_comment_file(
        path: .init(card_uid: cardUid, comment_uid: commentUid, id: fileId)
      )
    }
    let result: Components.Schemas.DeletedCommentFileResponse = try decodeResponse(
      response.toCase()
    ) { try $0.json }
    return result.id
  }
}
