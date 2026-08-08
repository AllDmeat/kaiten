import Foundation
import OpenAPIRuntime

// MARK: - Card Files

extension KaitenClient {
  /// Attaches a file to a card.
  ///
  /// The file is uploaded as `multipart/form-data`. The response is one of two shapes:
  /// a legacy attachment (integer `id`) or a private file (UUID string `id`) — the same
  /// pair a card's `files` array carries.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - fileData: The file content.
  ///   - filename: The file name sent in the multipart `Content-Disposition` header.
  /// - Returns: The attached file entry.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for upload errors (400),
  ///     forbidden (403), service unavailable (503) or other undocumented HTTP status codes.
  public func attachFile(
    cardId: Int,
    fileData: Data,
    filename: String
  ) async throws(KaitenError) -> Components.Schemas.CardFileEntry {
    let response = try await call {
      try await client.attach_file_to_card(
        path: .init(card_id: cardId),
        body: .multipartForm([
          .file(.init(payload: .init(body: HTTPBody(fileData)), filename: filename))
        ])
      )
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("card", cardId)) {
      try $0.json
    }
  }

  /// Updates a file attached to a card.
  ///
  /// The endpoint returns HTTP 200 with no documented response schema.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - fileId: The file identifier.
  ///   - cardCover: Whether the image is used as the card cover.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the file does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other
  ///     undocumented HTTP status codes.
  public func updateFile(
    cardId: Int,
    fileId: Int,
    cardCover: Bool? = nil
  ) async throws(KaitenError) {
    let response = try await call {
      try await client.update_card_file(
        path: .init(card_id: cardId, id: fileId),
        body: .json(.init(card_cover: cardCover))
      )
    }
    try decodeResponse(response.toCase(), notFoundResource: ("file", fileId)) { _ in () }
  }

  /// Detaches a file from a card.
  ///
  /// - Parameters:
  ///   - cardId: The card identifier.
  ///   - fileId: The file identifier.
  /// - Returns: The deleted file ID.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the file does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for forbidden (403) or other
  ///     undocumented HTTP status codes.
  public func detachFile(cardId: Int, fileId: Int) async throws(KaitenError) -> Int {
    let response = try await call {
      try await client.detach_file_from_card(path: .init(card_id: cardId, id: fileId))
    }
    let result: Components.Schemas.DeletedCardFileResponse = try decodeResponse(
      response.toCase(), notFoundResource: ("file", fileId)
    ) { try $0.json }
    return result.id
  }
}
