import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("AttachFile")
struct AttachFileTests {

  /// Fixture from the documented example response of `PUT /cards/{card_id}/files`.
  static let legacyResponse = """
    {
      "author_id": 1,
      "card_cover": false,
      "card_id": 1,
      "comment_id": null,
      "created": "2022-03-22T14:03:35.022Z",
      "deleted": false,
      "external": false,
      "id": 2177127,
      "mh_markup_id": null,
      "mh_secret": null,
      "name": "unnamed.png",
      "size": 6848,
      "sort_order": 3.0562675120446787,
      "type": 1,
      "updated": "2022-03-22T14:03:35.022Z",
      "url": "https://files.hostName/3a18e07.png"
    }
    """

  @Test("200 returns the attached file entry")
  func success() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: Self.legacyResponse)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let entry = try await client.attachFile(
      cardId: 1, fileData: Data("png-bytes".utf8), filename: "unnamed.png")

    let file = try #require(entry.value1)
    #expect(entry.value2 == nil)
    #expect(file.id == 2_177_127)
    #expect(file.name == "unnamed.png")
    #expect(file._type == 1)
    #expect(file.size == 6848)
    #expect(file.card_id == 1)
    #expect(file.author_id == 1)
    #expect(file.comment_id == nil)
    #expect(file.card_cover == false)
    #expect(file.deleted == false)
    #expect(file.external == false)
    #expect(file.url == "https://files.hostName/3a18e07.png")
  }

  @Test("request is sent as multipart/form-data")
  func multipartRequest() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: Self.legacyResponse)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    _ = try await client.attachFile(
      cardId: 1, fileData: Data("png-bytes".utf8), filename: "unnamed.png")

    let request = try #require(transport.recordedRequests.first)
    #expect(request.request.method == .put)
    #expect(request.request.headerFields[.contentType]?.hasPrefix("multipart/form-data") == true)
  }

  /// The docs' `type` enum includes 11 (private file), and type-11 files carry a UUID
  /// string `id` — the same second shape a card's `files` array holds. A private-file
  /// response must decode into the PrivateFile branch instead of failing.
  @Test("private-file shaped response decodes into the PrivateFile branch")
  func privateFileResponse() async throws {
    let json = """
      {
        "id": "aaaa1111-bb22-cc33-dd44-eeee5555ffff",
        "name": "photo.png",
        "size": "4096",
        "mime_type": "image/png",
        "author_uid": "bbbb2222-cc33-dd44-ee55-ffff6666aaaa",
        "card_uid": "cccc3333-dd44-ee55-ff66-aaaa7777bbbb",
        "entity_type": "card",
        "resizes": [],
        "card_cover": false,
        "deleted": false,
        "type": 11,
        "url": "/api/v1/cards/cccc3333/files/aaaa1111",
        "card_id": 7
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let entry = try await client.attachFile(
      cardId: 7, fileData: Data("png-bytes".utf8), filename: "photo.png")

    let file = try #require(entry.value2)
    #expect(entry.value1 == nil)
    #expect(file.id == "aaaa1111-bb22-cc33-dd44-eeee5555ffff")
    #expect(file._type == 11)
    #expect(file.size == "4096")
  }

  @Test("404 throws notFound")
  func notFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.attachFile(
        cardId: 999, fileData: Data("x".utf8), filename: "x.txt")
    }
  }

  @Test("401 throws unauthorized")
  func unauthorized() async throws {
    let transport = MockClientTransport.returning(statusCode: 401)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.attachFile(
        cardId: 1, fileData: Data("x".utf8), filename: "x.txt")
    }
  }
}
