import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

/// A card's `files` array mixes two structurally different objects: legacy attachments
/// (`type` 1-10, integer `id`) and private files (`type` 11, UUID string `id`). Modelling
/// only the legacy shape made `getCard` throw on every card carrying a private file, which
/// is now the majority of recent uploads.
///
/// All payloads below are verbatim responses from `GET /cards/{id}`.
@Suite("Card Files")
struct CardFilesTests {

  // MARK: - Payloads

  /// Card 66100735, a `type: 1` attachment. Note `mime_type`, `comment_id`,
  /// `custom_property_id` and `thumbnail_url` arriving as explicit JSON `null`.
  static let legacyAttachment = """
    {
      "id": 59934975,
      "url": "https://files.kaiten.ru/ef8b499b-f83a-4c26-8816-ab0586407017.MP4",
      "name": "IMG_3131 (1).MP4",
      "type": 1,
      "size": 7804333,
      "mime_type": null,
      "deleted": false,
      "card_id": 66100735,
      "external": false,
      "author_id": 560196,
      "comment_id": null,
      "sort_order": 1.0522156881732652,
      "card_cover": false,
      "created": "2026-06-15T10:02:53.223Z",
      "updated": "2026-06-15T10:02:53.223Z",
      "uid": "05c48b07-8548-44cd-b8ab-c82941342858",
      "custom_property_id": null,
      "thumbnail_url": null
    }
    """

  /// Card 55002297, a `type: 8` comment attachment — same shape, `comment_id` populated.
  static let legacyCommentAttachment = """
    {
      "id": 53886952,
      "url": "https://files.kaiten.ru/9d1f6b04-2c8a-4a11-9f3e-1b7c2d5e8a90.png",
      "name": "screenshot.png",
      "type": 8,
      "size": 90092,
      "mime_type": null,
      "deleted": false,
      "card_id": 55002297,
      "external": false,
      "author_id": 560196,
      "comment_id": 71234567,
      "sort_order": 2.5,
      "card_cover": false,
      "created": "2026-01-26T09:14:02.001Z",
      "updated": "2026-01-26T09:14:02.001Z",
      "uid": "1a2b3c4d-5e6f-4071-8293-a4b5c6d7e8f9",
      "custom_property_id": null,
      "thumbnail_url": null
    }
    """

  /// Card 68484284, a `type: 11` private file — the payload that broke `getCard`.
  static let privateFile = """
    {
      "id": "1818c668-3274-46c2-8f14-8702ce35f36e",
      "name": "image.png",
      "size": "135369",
      "mime_type": "image/png",
      "author_uid": "27ee7c96-bc0c-47ba-b990-c6f6bcf86ecb",
      "card_uid": "d3249745-0ba5-4d8a-8185-613718ab49a0",
      "company_uid": "c455e813-394b-4b73-a238-0fdfe312d8c0",
      "entity_type": "card",
      "created": "2026-08-07T11:55:35.863Z",
      "updated": "2026-08-07T11:55:35.863Z",
      "resizes": [
        {
          "size": 41704,
          "resize": "224x",
          "created": "2026-08-07T11:55:36.507Z",
          "storage_key": "companies/c455e813/cards/d3249745/resizes/224x/e091e68c.png"
        }
      ],
      "card_cover": false,
      "deleted": false,
      "type": 11,
      "url": "/api/v1/cards/d3249745-0ba5-4d8a-8185-613718ab49a0/files/1818c668-3274-46c2-8f14-8702ce35f36e",
      "card_id": 68484284
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

    #expect(file.id == 59_934_975)
    #expect(file.name == "IMG_3131 (1).MP4")
    #expect(file._type == 1)
    #expect(file.size == 7_804_333)
    #expect(file.card_id == 66_100_735)
    #expect(file.author_id == 560_196)
    #expect(file.external == false)
    #expect(file.card_cover == false)
    #expect(file.deleted == false)
    #expect(file.sort_order == 1.0522156881732652)
    #expect(file.uid == "05c48b07-8548-44cd-b8ab-c82941342858")
    #expect(file.url == "https://files.kaiten.ru/ef8b499b-f83a-4c26-8816-ab0586407017.MP4")
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
    #expect(file.comment_id == 71_234_567)
    #expect(file.size == 90092)
  }

  @Test("nullable size on a legacy attachment decodes to nil")
  func legacyNullSize() throws {
    let json = """
      {"id": 61308055, "type": 1, "size": null, "card_id": 67495212, "name": "note.txt"}
      """
    let file = try #require(try Self.decodeEntry(json).value1)

    #expect(file.id == 61_308_055)
    #expect(file.size == nil)
  }

  // MARK: - Private files

  @Test("private file decodes into the PrivateFile branch, not File")
  func privateDecodesAsPrivateFile() throws {
    let entry = try Self.decodeEntry(Self.privateFile)

    let file = try #require(entry.value2)
    #expect(entry.value1 == nil)

    #expect(file.id == "1818c668-3274-46c2-8f14-8702ce35f36e")
    #expect(file.name == "image.png")
    #expect(file._type == 11)
    #expect(file.size == "135369")
    #expect(file.mime_type == "image/png")
    #expect(file.author_uid == "27ee7c96-bc0c-47ba-b990-c6f6bcf86ecb")
    #expect(file.card_uid == "d3249745-0ba5-4d8a-8185-613718ab49a0")
    #expect(file.company_uid == "c455e813-394b-4b73-a238-0fdfe312d8c0")
    #expect(file.entity_type == "card")
    #expect(file.card_id == 68_484_284)
    #expect(file.card_cover == false)
    #expect(file.deleted == false)
    #expect(file.created == "2026-08-07T11:55:35.863Z")
    #expect(
      file.url
        == "/api/v1/cards/d3249745-0ba5-4d8a-8185-613718ab49a0/files/1818c668-3274-46c2-8f14-8702ce35f36e"
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
    #expect(resizes[0].storage_key == "companies/c455e813/cards/d3249745/resizes/224x/e091e68c.png")
  }

  @Test("private file attached to a comment carries comment_uid and entity_type")
  func privateCommentFile() throws {
    let json = """
      {
        "id": "d19ceb87-ac73-4e8b-9834-3f461ee08319",
        "name": "IMG_4064.HEIC",
        "size": "1818065",
        "mime_type": "image/heic",
        "author_uid": "7853defd-c8bf-43f6-bea5-b457fd935f0b",
        "card_uid": "0f156403-c6ed-43d5-a764-79b59fd6b578",
        "comment_id": 75078936,
        "comment_uid": "a2a9de0b-c6b3-401d-a0e1-95becdb91eee",
        "entity_type": "comment",
        "resizes": [],
        "type": 11,
        "card_id": 68495047
      }
      """
    let file = try #require(try Self.decodeEntry(json).value2)

    #expect(file.entity_type == "comment")
    #expect(file.comment_id == 75_078_936)
    #expect(file.comment_uid == "a2a9de0b-c6b3-401d-a0e1-95becdb91eee")
    #expect(file.resizes?.isEmpty == true)
  }

  // MARK: - Both shapes together

  @Test("one card carrying both shapes decodes each into its own branch")
  func mixedArray() async throws {
    let json = """
      {"id": 68484284, "title": "Mixed", "files": [\(Self.legacyAttachment), \(Self.privateFile)]}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "t", transport: transport)

    let card = try await client.getCard(id: 68_484_284)
    let files = try #require(card.files)
    #expect(files.count == 2)

    #expect(files[0].value1?.id == 59_934_975)
    #expect(files[0].value2 == nil)
    #expect(files[1].value2?.id == "1818c668-3274-46c2-8f14-8702ce35f36e")
    #expect(files[1].value1 == nil)
  }

  /// The original bug: `getCard` threw `DecodingError.typeMismatch` at `files[0].id`
  /// because the spec declared `id` as an integer for every file.
  @Test("getCard on a card with a private file no longer throws")
  func getCardWithPrivateFileSucceeds() async throws {
    let json = """
      {"id": 68484284, "title": "[Android] change_variant", "files": [\(Self.privateFile)]}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "t", transport: transport)

    let card = try await client.getCard(id: 68_484_284)
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
