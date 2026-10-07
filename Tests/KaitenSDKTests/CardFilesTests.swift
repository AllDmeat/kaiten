import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

/// A card's `files` array mixes two structurally different objects: legacy attachments
/// (`type` 1-10, integer `id`) and private files (`type` 11, UUID string `id`). Modelling
/// only the legacy shape made `getCard` throw on every card carrying a private file, which
/// is now the majority of recent uploads.
///
/// All payloads below follow the shape of `GET /cards/{id}` responses; every id is invented.
@Suite("Card Files")
struct CardFilesTests {

  // MARK: - Payloads

  /// A `type: 1` attachment. Note `mime_type`, `comment_id`,
  /// `custom_property_id` and `thumbnail_url` arriving as explicit JSON `null`.
  static let legacyAttachment = """
    {
      "id": 101,
      "url": "https://files.kaiten.ru/aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa.MP4",
      "name": "video.mp4",
      "type": 1,
      "size": 7804333,
      "mime_type": null,
      "deleted": false,
      "card_id": 201,
      "external": false,
      "author_id": 301,
      "comment_id": null,
      "sort_order": 1.0522156881732652,
      "card_cover": false,
      "created": "2026-06-15T10:02:53.223Z",
      "updated": "2026-06-15T10:02:53.223Z",
      "uid": "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb",
      "custom_property_id": null,
      "thumbnail_url": null
    }
    """

  /// A `type: 8` comment attachment — same shape, `comment_id` populated.
  static let legacyCommentAttachment = """
    {
      "id": 102,
      "url": "https://files.kaiten.ru/cccccccc-cccc-4ccc-8ccc-cccccccccccc.png",
      "name": "screenshot.png",
      "type": 8,
      "size": 90092,
      "mime_type": null,
      "deleted": false,
      "card_id": 202,
      "external": false,
      "author_id": 301,
      "comment_id": 402,
      "sort_order": 2.5,
      "card_cover": false,
      "created": "2026-01-26T09:14:02.001Z",
      "updated": "2026-01-26T09:14:02.001Z",
      "uid": "1a2b3c4d-5e6f-4071-8293-a4b5c6d7e8f9",
      "custom_property_id": null,
      "thumbnail_url": null
    }
    """

  /// A `type: 11` private file — the payload that broke `getCard`.
  static let privateFile = """
    {
      "id": "11111111-1111-4111-8111-111111111111",
      "name": "image.png",
      "size": "135369",
      "mime_type": "image/png",
      "author_uid": "22222222-2222-4222-8222-222222222222",
      "card_uid": "33333333-3333-4333-8333-333333333333",
      "company_uid": "44444444-4444-4444-8444-444444444444",
      "entity_type": "card",
      "created": "2026-08-07T11:55:35.863Z",
      "updated": "2026-08-07T11:55:35.863Z",
      "resizes": [
        {
          "size": 41704,
          "resize": "224x",
          "created": "2026-08-07T11:55:36.507Z",
          "storage_key": "companies/44444444/cards/33333333/resizes/224x/55555555.png"
        }
      ],
      "card_cover": false,
      "deleted": false,
      "type": 11,
      "url": "/api/v1/cards/33333333-3333-4333-8333-333333333333/files/11111111-1111-4111-8111-111111111111",
      "card_id": 203
    }
    """

  private static func decodeEntry(_ json: String) throws -> Components.Schemas.CardFileEntry {
    try JSONDecoder().decode(
      Components.Schemas.CardFileEntry.self, from: Data(json.utf8))
  }

  // MARK: - Legacy attachments

  @Test("legacy attachment decodes into the File branch, not PrivateFile")
  func legacyDecodesAsFile() throws {
    let entry = try Self.decodeEntry(Self.legacyAttachment)

    let file = try #require(entry.value1)
    #expect(entry.value2 == nil)

    #expect(file.id == 101)
    #expect(file.name == "video.mp4")
    #expect(file._type == 1)
    #expect(file.size == 7_804_333)
    #expect(file.card_id == 201)
    #expect(file.author_id == 301)
    #expect(file.external == false)
    #expect(file.card_cover == false)
    #expect(file.deleted == false)
    #expect(file.sort_order == 1.0522156881732652)
    #expect(file.uid == "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb")
    #expect(file.url == "https://files.kaiten.ru/aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa.MP4")
    #expect(file.created == "2026-06-15T10:02:53.223Z")
    #expect(file.updated == "2026-06-15T10:02:53.223Z")
  }

  @Test("explicit JSON null on a legacy attachment decodes to nil, not a failure")
  func legacyNullsDecodeToNil() throws {
    let file = try #require(try Self.decodeEntry(Self.legacyAttachment).value1)

    #expect(file.comment_id == nil)
    #expect(file.mime_type == nil)
    #expect(file.custom_property_id == nil)
    #expect(file.thumbnail_url == nil)
  }

  @Test("legacy comment attachment keeps comment_id")
  func legacyCommentAttachment() throws {
    let entry = try Self.decodeEntry(Self.legacyCommentAttachment)

    let file = try #require(entry.value1)
    #expect(entry.value2 == nil)
    #expect(file._type == 8)
    #expect(file.comment_id == 402)
    #expect(file.size == 90092)
  }

  @Test("nullable size on a legacy attachment decodes to nil")
  func legacyNullSize() throws {
    let json = """
      {"id": 103, "type": 1, "size": null, "card_id": 204, "name": "note.txt"}
      """
    let file = try #require(try Self.decodeEntry(json).value1)

    #expect(file.id == 103)
    #expect(file.size == nil)
  }

  // MARK: - Private files

  @Test("private comment file decodes kind and comment_uid")
  func privateCommentFileDecodesKind() throws {
    let json = """
      {
        "id": "aaaa1111-bb22-cc33-dd44-eeee5555ffff",
        "name": "notes.txt",
        "entity_type": "comment",
        "kind": "attachment",
        "comment_uid": "comment-uid-1",
        "type": 11
      }
      """
    let file = try #require(try Self.decodeEntry(json).value2)
    #expect(file.kind == "attachment")
    #expect(file.comment_uid == "comment-uid-1")
  }

  @Test("private file decodes into the PrivateFile branch, not File")
  func privateDecodesAsPrivateFile() throws {
    let entry = try Self.decodeEntry(Self.privateFile)

    let file = try #require(entry.value2)
    #expect(entry.value1 == nil)

    #expect(file.id == "11111111-1111-4111-8111-111111111111")
    #expect(file.name == "image.png")
    #expect(file._type == 11)
    #expect(file.size == "135369")
    #expect(file.mime_type == "image/png")
    #expect(file.author_uid == "22222222-2222-4222-8222-222222222222")
    #expect(file.card_uid == "33333333-3333-4333-8333-333333333333")
    #expect(file.company_uid == "44444444-4444-4444-8444-444444444444")
    #expect(file.entity_type == "card")
    #expect(file.card_id == 203)
    #expect(file.card_cover == false)
    #expect(file.deleted == false)
    #expect(file.created == "2026-08-07T11:55:35.863Z")
    #expect(
      file.url
        == "/api/v1/cards/33333333-3333-4333-8333-333333333333/files/11111111-1111-4111-8111-111111111111"
    )
  }

  @Test("private file thumbnails decode")
  func privateFileResizes() throws {
    let file = try #require(try Self.decodeEntry(Self.privateFile).value2)

    let resizes = try #require(file.resizes)
    #expect(resizes.count == 1)
    #expect(resizes[0].size == 41704)
    #expect(resizes[0].resize == "224x")
    #expect(resizes[0].created == "2026-08-07T11:55:36.507Z")
    #expect(resizes[0].storage_key == "companies/44444444/cards/33333333/resizes/224x/55555555.png")
  }

  @Test("private file attached to a comment carries comment_uid and entity_type")
  func privateCommentFile() throws {
    let json = """
      {
        "id": "66666666-6666-4666-8666-666666666666",
        "name": "photo.heic",
        "size": "1818065",
        "mime_type": "image/heic",
        "author_uid": "77777777-7777-4777-8777-777777777777",
        "card_uid": "88888888-8888-4888-8888-888888888888",
        "comment_id": 401,
        "comment_uid": "99999999-9999-4999-8999-999999999999",
        "entity_type": "comment",
        "resizes": [],
        "type": 11,
        "card_id": 205
      }
      """
    let file = try #require(try Self.decodeEntry(json).value2)

    #expect(file.entity_type == "comment")
    #expect(file.comment_id == 401)
    #expect(file.comment_uid == "99999999-9999-4999-8999-999999999999")
    #expect(file.resizes?.isEmpty == true)
  }

  // MARK: - Both shapes together

  @Test("one card carrying both shapes decodes each into its own branch")
  func mixedArray() async throws {
    let json = """
      {"id": 203, "title": "Mixed", "files": [\(Self.legacyAttachment), \(Self.privateFile)]}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "t", transport: transport)

    let card = try await client.getCard(id: 203)
    let files = try #require(card.files)
    #expect(files.count == 2)

    #expect(files[0].value1?.id == 101)
    #expect(files[0].value2 == nil)
    #expect(files[1].value2?.id == "11111111-1111-4111-8111-111111111111")
    #expect(files[1].value1 == nil)
  }

  /// The original bug: `getCard` threw `DecodingError.typeMismatch` at `files[0].id`
  /// because the spec declared `id` as an integer for every file.
  @Test("getCard on a card with a private file no longer throws")
  func getCardWithPrivateFileSucceeds() async throws {
    let json = """
      {"id": 203, "title": "Private only", "files": [\(Self.privateFile)]}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "t", transport: transport)

    let card = try await client.getCard(id: 203)
    #expect(card.files?.count == 1)
    #expect(card.files?.first?.value2?.name == "image.png")
  }

  // MARK: - Forward compatibility

  /// Kaiten has shipped undocumented file types before (`10`, then `11`). A shape matching
  /// neither branch must degrade to the free-form fallback rather than fail the whole card.
  @Test("an unrecognised file shape falls back instead of failing the response")
  func unknownShapeFallsBack() async throws {
    let unknown = """
      {"id": {"nested": "identifier"}, "type": 12, "storage": "somewhere-new"}
      """
    let json = """
      {"id": 1, "title": "Future", "files": [\(unknown)]}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "t", transport: transport)

    let card = try await client.getCard(id: 1)
    let entry = try #require(card.files?.first)

    #expect(entry.value1 == nil)
    #expect(entry.value2 == nil)
    #expect(entry.value3?.value["storage"] as? String == "somewhere-new")
  }

  // MARK: - Round trip

  @Test("both shapes survive a decode/encode round trip")
  func roundTrip() throws {
    for payload in [Self.legacyAttachment, Self.privateFile] {
      let decoded = try Self.decodeEntry(payload)
      let reencoded = try JSONEncoder().encode(decoded)
      let redecoded = try JSONDecoder().decode(
        Components.Schemas.CardFileEntry.self, from: reencoded)

      #expect(redecoded.value1 == decoded.value1)
      #expect(redecoded.value2 == decoded.value2)
    }
  }
}
