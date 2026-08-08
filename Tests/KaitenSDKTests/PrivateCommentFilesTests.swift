import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("PrivateCommentFiles")
struct PrivateCommentFilesTests {

  private func makeClient(_ transport: MockClientTransport) throws -> KaitenClient {
    try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)
  }

  /// `KaitenError` is not `Equatable`, so the status code is matched by pattern.
  private func expectUnexpectedResponse(
    statusCode: Int,
    sourceLocation: SourceLocation = #_sourceLocation,
    _ operation: () async throws -> Void
  ) async {
    do {
      try await operation()
      Issue.record(
        "expected KaitenError.unexpectedResponse(statusCode: \(statusCode)), no error thrown",
        sourceLocation: sourceLocation)
    } catch let error as KaitenError {
      guard case .unexpectedResponse(let code, _) = error, code == statusCode else {
        Issue.record(
          "expected KaitenError.unexpectedResponse(statusCode: \(statusCode)), got \(error)",
          sourceLocation: sourceLocation)
        return
      }
    } catch {
      Issue.record("expected KaitenError, got \(error)", sourceLocation: sourceLocation)
    }
  }

  /// Fixture built from the documented response attributes of
  /// `POST /cards/{card_uid}/comments/{comment_uid}/files`. The endpoint could not be
  /// verified live: it requires "Restricted file access" enabled in company settings,
  /// and the verification instance has it disabled (the route answers 404).
  static let commentFileResponse = """
    {
      "id": "aaaa1111-bb22-cc33-dd44-eeee5555ffff",
      "name": "screenshot.png",
      "size": "6848",
      "mime_type": "image/png",
      "author_uid": "bbbb2222-cc33-dd44-ee55-ffff6666aaaa",
      "card_uid": "cccc3333-dd44-ee55-ff66-aaaa7777bbbb",
      "comment_uid": "dddd4444-ee55-ff66-aa77-bbbb8888cccc",
      "entity_type": "comment",
      "created": "2024-03-22T14:03:35.022Z",
      "updated": "2024-03-22T14:03:35.022Z",
      "card_cover": false
    }
    """

  // MARK: - Attach

  @Test("200 returns the attached comment file")
  func attachSuccess() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: Self.commentFileResponse))

    let file = try await client.attachFileToComment(
      cardUid: "cccc3333-dd44-ee55-ff66-aaaa7777bbbb",
      commentUid: "dddd4444-ee55-ff66-aa77-bbbb8888cccc",
      fileData: Data("png-bytes".utf8),
      filename: "screenshot.png"
    )

    #expect(file.id == "aaaa1111-bb22-cc33-dd44-eeee5555ffff")
    #expect(file.name == "screenshot.png")
    #expect(file.size == "6848")
    #expect(file.mime_type == "image/png")
    #expect(file.author_uid == "bbbb2222-cc33-dd44-ee55-ffff6666aaaa")
    #expect(file.card_uid == "cccc3333-dd44-ee55-ff66-aaaa7777bbbb")
    #expect(file.comment_uid == "dddd4444-ee55-ff66-aa77-bbbb8888cccc")
    #expect(file.entity_type == "comment")
    #expect(file.card_cover == false)
  }

  @Test("attach is sent as multipart POST to the comment files path")
  func attachRequest() async throws {
    let transport = MockClientTransport.returning(
      statusCode: 200, body: Self.commentFileResponse)
    let client = try makeClient(transport)

    _ = try await client.attachFileToComment(
      cardUid: "card-uid-1",
      commentUid: "comment-uid-1",
      fileData: Data("png-bytes".utf8),
      filename: "screenshot.png"
    )

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .post)
    #expect(recorded.request.path == "/cards/card-uid-1/comments/comment-uid-1/files")
    #expect(
      recorded.request.headerFields[.contentType]?.hasPrefix("multipart/form-data") == true)
  }

  /// The docs declare `comment_uid` as `null | string`.
  @Test("null comment_uid decodes to nil")
  func attachNullCommentUid() async throws {
    let json = """
      {
        "id": "aaaa1111-bb22-cc33-dd44-eeee5555ffff",
        "name": "screenshot.png",
        "comment_uid": null
      }
      """
    let client = try makeClient(.returning(statusCode: 200, body: json))

    let file = try await client.attachFileToComment(
      cardUid: "card-uid-1",
      commentUid: "comment-uid-1",
      fileData: Data("x".utf8),
      filename: "x.png"
    )

    #expect(file.comment_uid == nil)
  }

  /// The card and the comment are addressed by string UID, which
  /// `KaitenError.notFound(resource:id:)` cannot represent, so a 404 surfaces
  /// as `unexpectedResponse`.
  @Test("attach 404 throws unexpectedResponse")
  func attachNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await expectUnexpectedResponse(statusCode: 404) {
      _ = try await client.attachFileToComment(
        cardUid: "missing", commentUid: "missing",
        fileData: Data("x".utf8), filename: "x.txt")
    }
  }

  @Test("attach 401 throws unauthorized")
  func attachUnauthorized() async throws {
    let client = try makeClient(.returning(statusCode: 401))
    await #expect(throws: KaitenError.self) {
      _ = try await client.attachFileToComment(
        cardUid: "card-uid-1", commentUid: "comment-uid-1",
        fileData: Data("x".utf8), filename: "x.txt")
    }
  }

  // MARK: - Get

  @Test("200 returns the signed URL")
  func getSuccess() async throws {
    let json = """
      {"url": "https://files.test.kaiten.ru/signed/aaaa1111?sig=abc"}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let signed = try await client.getCommentFile(
      cardUid: "card-uid-1", commentUid: "comment-uid-1",
      fileId: "aaaa1111-bb22-cc33-dd44-eeee5555ffff")

    #expect(signed.url == "https://files.test.kaiten.ru/signed/aaaa1111?sig=abc")

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .get)
    let path = try #require(recorded.request.path)
    #expect(
      path.hasPrefix(
        "/cards/card-uid-1/comments/comment-uid-1/files/aaaa1111-bb22-cc33-dd44-eeee5555ffff"))
    #expect(path.contains("response_type=json"))
  }

  /// `inline` and `attachment` dispositions answer with a redirect to the file
  /// content instead of a JSON body, which the SDK reports as `unexpectedResponse`.
  @Test("302 redirect throws unexpectedResponse")
  func getRedirect() async throws {
    let client = try makeClient(.returning(statusCode: 302))
    await expectUnexpectedResponse(statusCode: 302) {
      _ = try await client.getCommentFile(
        cardUid: "card-uid-1", commentUid: "comment-uid-1", fileId: "file-id-1",
        responseType: .inline)
    }
  }

  @Test("get 404 throws unexpectedResponse")
  func getNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await expectUnexpectedResponse(statusCode: 404) {
      _ = try await client.getCommentFile(
        cardUid: "card-uid-1", commentUid: "comment-uid-1", fileId: "missing")
    }
  }

  @Test("get 422 malicious file throws unexpectedResponse")
  func getMalicious() async throws {
    let client = try makeClient(.returning(statusCode: 422))
    await expectUnexpectedResponse(statusCode: 422) {
      _ = try await client.getCommentFile(
        cardUid: "card-uid-1", commentUid: "comment-uid-1", fileId: "file-id-1")
    }
  }

  // MARK: - Delete

  @Test("200 returns the deleted file id")
  func deleteSuccess() async throws {
    let json = """
      {"id": "aaaa1111-bb22-cc33-dd44-eeee5555ffff"}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let deletedId = try await client.deleteCommentFile(
      cardUid: "card-uid-1", commentUid: "comment-uid-1",
      fileId: "aaaa1111-bb22-cc33-dd44-eeee5555ffff")

    #expect(deletedId == "aaaa1111-bb22-cc33-dd44-eeee5555ffff")

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .delete)
    #expect(
      recorded.request.path
        == "/cards/card-uid-1/comments/comment-uid-1/files/aaaa1111-bb22-cc33-dd44-eeee5555ffff")
  }

  @Test("delete 403 throws unexpectedResponse")
  func deleteForbidden() async throws {
    let client = try makeClient(.returning(statusCode: 403))
    await expectUnexpectedResponse(statusCode: 403) {
      _ = try await client.deleteCommentFile(
        cardUid: "card-uid-1", commentUid: "comment-uid-1", fileId: "file-id-1")
    }
  }

  // MARK: - Enum

  @Test("CommentFileResponseType round-trips and preserves unknown values")
  func responseTypeEnum() {
    for c in CommentFileResponseType.allCases {
      #expect(CommentFileResponseType(rawValue: c.rawValue) == c)
    }
    #expect(CommentFileResponseType(rawValue: "json") == .json)
    #expect(CommentFileResponseType(rawValue: "inline") == .inline)
    #expect(CommentFileResponseType(rawValue: "attachment") == .attachment)
    #expect(CommentFileResponseType(rawValue: "preview") == .unknown("preview"))
  }
}
