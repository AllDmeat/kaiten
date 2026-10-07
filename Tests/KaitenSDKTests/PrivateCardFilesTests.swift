import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

/// Fixtures are built from the documented response attributes. The GET shape was also
/// confirmed against the live API; attach, update and delete were not called live.
@Suite("PrivateCardFiles")
struct PrivateCardFilesTests {

  private static let cardUid = "cccc3333-dd44-ee55-ff66-aaaa7777bbbb"
  private static let fileId = "aaaa1111-bb22-cc33-dd44-eeee5555ffff"

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

  // MARK: - Attach

  /// Fixture built from the documented response attributes of
  /// `POST /cards/{card_uid}/files`.
  static let attachResponse = """
    {
      "id": "aaaa1111-bb22-cc33-dd44-eeee5555ffff",
      "name": "photo.png",
      "size": "4096",
      "mime_type": "image/png",
      "author_uid": "bbbb2222-cc33-dd44-ee55-ffff6666aaaa",
      "card_uid": "cccc3333-dd44-ee55-ff66-aaaa7777bbbb",
      "company_uid": "dddd4444-ee55-ff66-aa77-bbbb8888cccc",
      "entity_type": "card",
      "created": "2024-05-20T14:03:35.022Z",
      "updated": "2024-05-20T14:03:35.022Z",
      "card_cover": false
    }
    """

  @Test("attach: 200 returns the attached private file")
  func attachSuccess() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: Self.attachResponse)
    let client = try makeClient(transport)

    let file = try await client.attachPrivateFile(
      cardUid: Self.cardUid, fileData: Data("png-bytes".utf8), filename: "photo.png")

    #expect(file.id == Self.fileId)
    #expect(file.name == "photo.png")
    #expect(file.size == "4096")
    #expect(file.mime_type == "image/png")
    #expect(file.author_uid == "bbbb2222-cc33-dd44-ee55-ffff6666aaaa")
    #expect(file.card_uid == Self.cardUid)
    #expect(file.company_uid == "dddd4444-ee55-ff66-aa77-bbbb8888cccc")
    #expect(file.entity_type == "card")
    #expect(file.created == "2024-05-20T14:03:35.022Z")
    #expect(file.updated == "2024-05-20T14:03:35.022Z")
    #expect(file.card_cover == false)
  }

  @Test("attach: request is sent as POST multipart/form-data")
  func attachRequestShape() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: Self.attachResponse)
    let client = try makeClient(transport)

    _ = try await client.attachPrivateFile(
      cardUid: Self.cardUid, fileData: Data("png-bytes".utf8), filename: "photo.png")

    let request = try #require(transport.recordedRequests.first)
    #expect(request.request.method == .post)
    #expect(request.request.path?.contains("/cards/\(Self.cardUid)/files") == true)
    #expect(request.request.headerFields[.contentType]?.hasPrefix("multipart/form-data") == true)
  }

  @Test("attach: 401 throws unauthorized")
  func attachUnauthorized() async throws {
    let transport = MockClientTransport.returning(statusCode: 401)
    let client = try makeClient(transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.attachPrivateFile(
        cardUid: Self.cardUid, fileData: Data("x".utf8), filename: "x.txt")
    }
  }

  @Test("attach: 404 throws unexpectedResponse")
  func attachNotFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try makeClient(transport)

    await expectUnexpectedResponse(statusCode: 404) {
      _ = try await client.attachPrivateFile(
        cardUid: Self.cardUid, fileData: Data("x".utf8), filename: "x.txt")
    }
  }

  // MARK: - Get

  /// Fixture built from the documented response attributes of
  /// `GET /cards/{card_uid}/files/{id}`, matching the live shape.
  static let getResponse = """
    {
      "id": "aaaa1111-bb22-cc33-dd44-eeee5555ffff",
      "name": "photo.png",
      "size": null,
      "mime_type": "image/png",
      "entity_type": "card",
      "created": "2024-05-20T14:03:35.022Z",
      "updated": "2024-05-20T14:03:35.022Z",
      "card_uid": "cccc3333-dd44-ee55-ff66-aaaa7777bbbb",
      "author_uid": "bbbb2222-cc33-dd44-ee55-ffff6666aaaa",
      "card_cover": true,
      "url": "https://files.example.com/signed/aaaa1111?token=abc"
    }
    """

  @Test("get: 200 returns the file metadata with the signed URL")
  func getSuccess() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: Self.getResponse)
    let client = try makeClient(transport)

    let file = try await client.getPrivateCardFile(cardUid: Self.cardUid, fileId: Self.fileId)

    #expect(file.id == Self.fileId)
    #expect(file.name == "photo.png")
    #expect(file.size == nil)
    #expect(file.mime_type == "image/png")
    #expect(file.entity_type == "card")
    #expect(file.card_uid == Self.cardUid)
    #expect(file.author_uid == "bbbb2222-cc33-dd44-ee55-ffff6666aaaa")
    #expect(file.card_cover == true)
    #expect(file.url == "https://files.example.com/signed/aaaa1111?token=abc")

    let request = try #require(transport.recordedRequests.first)
    #expect(request.request.method == .get)
    let path = try #require(request.request.path)
    #expect(path.contains("/cards/\(Self.cardUid)/files/\(Self.fileId)"))
    #expect(!path.contains("response_type"))
    #expect(!path.contains("download"))
  }

  @Test("get: download is forwarded as a query parameter")
  func getDownloadForwarded() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: Self.getResponse)
    let client = try makeClient(transport)

    _ = try await client.getPrivateCardFile(
      cardUid: Self.cardUid, fileId: Self.fileId, download: true)

    let request = try #require(transport.recordedRequests.first)
    #expect(request.request.path?.contains("download=true") == true)
  }

  @Test("get (deprecated): returns the URL and still sends response_type")
  @available(*, deprecated)
  func getDeprecated() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: Self.getResponse)
    let client = try makeClient(transport)

    let url = try await client.getPrivateFile(
      cardUid: Self.cardUid, fileId: Self.fileId, responseType: .attachment)

    #expect(url == "https://files.example.com/signed/aaaa1111?token=abc")
    let request = try #require(transport.recordedRequests.first)
    #expect(request.request.path?.contains("response_type=attachment") == true)
  }

  @Test("get: 302 redirect throws unexpectedResponse")
  func getRedirect() async throws {
    let transport = MockClientTransport.returning(statusCode: 302)
    let client = try makeClient(transport)

    await expectUnexpectedResponse(statusCode: 302) {
      _ = try await client.getPrivateCardFile(cardUid: Self.cardUid, fileId: Self.fileId)
    }
  }

  @Test("get: 422 malicious file throws unexpectedResponse")
  func getMaliciousFile() async throws {
    let transport = MockClientTransport.returning(statusCode: 422)
    let client = try makeClient(transport)

    await expectUnexpectedResponse(statusCode: 422) {
      _ = try await client.getPrivateCardFile(cardUid: Self.cardUid, fileId: Self.fileId)
    }
  }

  @Test("get: 401 throws unauthorized")
  func getUnauthorized() async throws {
    let transport = MockClientTransport.returning(statusCode: 401)
    let client = try makeClient(transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.getPrivateCardFile(cardUid: Self.cardUid, fileId: Self.fileId)
    }
  }

  @Test("get: 404 throws unexpectedResponse")
  func getNotFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try makeClient(transport)

    await expectUnexpectedResponse(statusCode: 404) {
      _ = try await client.getPrivateCardFile(cardUid: Self.cardUid, fileId: Self.fileId)
    }
  }

  // MARK: - Update

  @Test("update: sends PATCH with name and card_cover, returns the file")
  func updateSuccess() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: Self.attachResponse)
    let client = try makeClient(transport)

    let file = try await client.updatePrivateFile(
      cardUid: Self.cardUid, fileId: Self.fileId, name: "renamed.png", cardCover: true)

    #expect(file.id == Self.fileId)
    #expect(file.company_uid == "dddd4444-ee55-ff66-aa77-bbbb8888cccc")

    let request = try #require(transport.recordedRequests.first)
    #expect(request.request.method == .patch)
    #expect(request.request.path?.hasSuffix("/cards/\(Self.cardUid)/files/\(Self.fileId)") == true)
    let bytes = try await Data(collecting: #require(request.body), upTo: 1024 * 1024)
    let sent = try #require(try JSONSerialization.jsonObject(with: bytes) as? [String: Any])
    #expect(sent["name"] as? String == "renamed.png")
    #expect(sent["card_cover"] as? Bool == true)
  }

  @Test("update: 400 throws unexpectedResponse")
  func updateValidationError() async throws {
    let client = try makeClient(.returning(statusCode: 400))
    await expectUnexpectedResponse(statusCode: 400) {
      _ = try await client.updatePrivateFile(cardUid: Self.cardUid, fileId: Self.fileId, name: "")
    }
  }

  // MARK: - Delete

  /// Fixture built from the documented response attributes of
  /// `DELETE /cards/{card_uid}/files/{id}`.
  @Test("delete: 200 returns the deleted file ID")
  func deleteSuccess() async throws {
    let json = """
      {"id": "aaaa1111-bb22-cc33-dd44-eeee5555ffff"}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let deletedId = try await client.deletePrivateFile(cardUid: Self.cardUid, fileId: Self.fileId)

    #expect(deletedId == Self.fileId)

    let request = try #require(transport.recordedRequests.first)
    #expect(request.request.method == .delete)
    #expect(request.request.path?.contains("/cards/\(Self.cardUid)/files/\(Self.fileId)") == true)
  }

  @Test("delete: 401 throws unauthorized")
  func deleteUnauthorized() async throws {
    let transport = MockClientTransport.returning(statusCode: 401)
    let client = try makeClient(transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.deletePrivateFile(cardUid: Self.cardUid, fileId: Self.fileId)
    }
  }

  @Test("delete: 404 throws unexpectedResponse")
  func deleteNotFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try makeClient(transport)

    await expectUnexpectedResponse(statusCode: 404) {
      _ = try await client.deletePrivateFile(cardUid: Self.cardUid, fileId: Self.fileId)
    }
  }
}
