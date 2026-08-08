import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

/// Private custom property files are addressed by string UIDs, so a 404 must
/// surface as `unexpectedResponse(statusCode: 404)` per FR-021.
///
/// The endpoints require the "Restricted file access" company setting and are
/// marked as under active development; the fixtures below follow the documented
/// field list — no live 200 response was reachable read-only.
@Suite("Private Custom Property Files")
struct PrivateCustomPropertyFilesTests {

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

  @Test("200 returns CustomPropertyFile")
  func attachSuccess() async throws {
    let json = """
      {
        "id": "file-uid-1",
        "name": "diagram.png",
        "size": "2048",
        "mime_type": "image/png",
        "author_uid": "user-uid-1",
        "card_uid": "card-uid-1",
        "custom_property_uid": "prop-uid-1",
        "entity_type": "card",
        "created": "2026-01-01T00:00:00.000Z",
        "updated": "2026-01-01T00:00:00.000Z",
        "card_cover": false
      }
      """
    let client = try makeClient(.returning(statusCode: 200, body: json))

    let file = try await client.attachFileToCustomProperty(
      cardUid: "card-uid-1", propertyUid: "prop-uid-1",
      fileData: Data("test".utf8), filename: "diagram.png")
    #expect(file.id == "file-uid-1")
    #expect(file.name == "diagram.png")
    #expect(file.size == "2048")
    #expect(file.mime_type == "image/png")
    #expect(file.author_uid == "user-uid-1")
    #expect(file.card_uid == "card-uid-1")
    #expect(file.custom_property_uid == "prop-uid-1")
    #expect(file.entity_type == "card")
    #expect(file.card_cover == false)
  }

  @Test("attach: 400 throws unexpectedResponse")
  func attachBadRequest() async throws {
    let client = try makeClient(.returning(statusCode: 400, body: #"{"message":"bad file"}"#))
    await expectUnexpectedResponse(statusCode: 400) {
      _ = try await client.attachFileToCustomProperty(
        cardUid: "card-uid-1", propertyUid: "prop-uid-1",
        fileData: Data("test".utf8), filename: "diagram.png")
    }
  }

  @Test("attach: 401 throws unauthorized")
  func attachUnauthorized() async throws {
    let client = try makeClient(.returning(statusCode: 401))
    do {
      _ = try await client.attachFileToCustomProperty(
        cardUid: "card-uid-1", propertyUid: "prop-uid-1",
        fileData: Data("test".utf8), filename: "diagram.png")
      Issue.record("expected KaitenError.unauthorized, no error thrown")
    } catch {
      guard case .unauthorized = error else {
        Issue.record("expected KaitenError.unauthorized, got \(error)")
        return
      }
    }
  }

  // MARK: - Get URL

  @Test("200 returns signed URL")
  func getUrlSuccess() async throws {
    let json = #"{"url": "https://storage.example.com/signed/file-uid-1?sig=abc"}"#
    let client = try makeClient(.returning(statusCode: 200, body: json))

    let url = try await client.getCustomPropertyFileUrl(
      cardUid: "card-uid-1", propertyUid: "prop-uid-1", fileId: "file-uid-1")
    #expect(url == "https://storage.example.com/signed/file-uid-1?sig=abc")
  }

  @Test("get sends response_type query parameter")
  func getUrlSendsResponseType() async throws {
    let transport = MockClientTransport { request, _, _, _ in
      #expect(request.path?.contains("response_type=json") == true)
      var response = HTTPResponse(status: .init(code: 200))
      response.headerFields[.contentType] = "application/json"
      return (response, .init(#"{"url": "https://storage.example.com/f"}"#))
    }
    let client = try makeClient(transport)

    _ = try await client.getCustomPropertyFileUrl(
      cardUid: "card-uid-1", propertyUid: "prop-uid-1", fileId: "file-uid-1")
  }

  /// UID-addressed resource: a 404 must not fake a `notFound(resource:id:)` (FR-021).
  @Test("get: 404 throws unexpectedResponse")
  func getUrlNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await expectUnexpectedResponse(statusCode: 404) {
      _ = try await client.getCustomPropertyFileUrl(
        cardUid: "card-uid-1", propertyUid: "prop-uid-1", fileId: "missing")
    }
  }

  // MARK: - Delete

  @Test("200 returns deleted file id")
  func deleteSuccess() async throws {
    let json = #"{"id": "file-uid-1"}"#
    let client = try makeClient(.returning(statusCode: 200, body: json))

    let deletedId = try await client.deleteCustomPropertyFile(
      cardUid: "card-uid-1", propertyUid: "prop-uid-1", fileId: "file-uid-1")
    #expect(deletedId == "file-uid-1")
  }

  @Test("delete: 403 throws unexpectedResponse")
  func deleteForbidden() async throws {
    let client = try makeClient(.returning(statusCode: 403))
    await expectUnexpectedResponse(statusCode: 403) {
      _ = try await client.deleteCustomPropertyFile(
        cardUid: "card-uid-1", propertyUid: "prop-uid-1", fileId: "file-uid-1")
    }
  }

  @Test("delete: 404 throws unexpectedResponse")
  func deleteNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await expectUnexpectedResponse(statusCode: 404) {
      _ = try await client.deleteCustomPropertyFile(
        cardUid: "card-uid-1", propertyUid: "prop-uid-1", fileId: "missing")
    }
  }

  // MARK: - Response Type Enum

  @Test("CustomPropertyFileResponseType preserves unknown values")
  func responseTypeUnknown() {
    #expect(CustomPropertyFileResponseType(rawValue: "json") == .json)
    #expect(CustomPropertyFileResponseType(rawValue: "inline") == .inline)
    #expect(CustomPropertyFileResponseType(rawValue: "attachment") == .attachment)
    #expect(CustomPropertyFileResponseType(rawValue: "signed") == .unknown("signed"))
    #expect(CustomPropertyFileResponseType.unknown("signed").rawValue == "signed")
  }
}
