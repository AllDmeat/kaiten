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
  ///   - commentUid: The comment UID.
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

  /// Gets a signed URL for a file attached to a card comment.
  ///
  /// Requires "Restricted file access" enabled in company settings.
  ///
  /// - Parameters:
  ///   - cardUid: The card UID.
  ///   - commentUid: The comment UID.
  ///   - fileId: The file ID.
  ///   - responseType: The requested content disposition. Defaults to ``CommentFileResponseType/json``,
  ///     the only disposition the SDK can represent: `inline` and `attachment` answer with a
  ///     redirect to the file content instead of a JSON body, which ends in an error.
  /// - Returns: The signed file URL response.
  /// - Throws:
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for a redirect (302), forbidden
  ///     (403), not found (404), a malicious file (422) or other undocumented HTTP status
  ///     codes. A 404 is reported as `unexpectedResponse` rather than
  ///     ``KaitenError/notFound(resource:id:)`` because the file is addressed by string UID.
  public func getCommentFile(
    cardUid: String,
    commentUid: String,
    fileId: String,
    responseType: CommentFileResponseType = .json
  ) async throws(KaitenError) -> Components.Schemas.CommentFileSignedUrl {
    let response = try await call {
      try await client.get_comment_file(
        path: .init(card_uid: cardUid, comment_uid: commentUid, id: fileId),
        query: .init(response_type: responseType.rawValue)
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
