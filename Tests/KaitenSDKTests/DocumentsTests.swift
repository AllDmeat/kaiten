import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("Documents")
struct DocumentsTests {

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

  /// A sanitized live version=1 list row: `id` is the uid string (not the documented
  /// integer), and `access_record`, `public_id`, `updater_id` are present although
  /// the documentation does not list them.
  private static let listItemJSON = """
    {
      "uid": "doc-uid-1",
      "path": "10.a1b2c3",
      "title": "Team handbook",
      "access": "for_everyone",
      "public": false,
      "public_id": "pub-uid-1",
      "parent_entity_uid": "group-uid-1",
      "entity_type": "document",
      "sort_order": 1.25,
      "author_id": 11,
      "updater_id": 12,
      "created": "2021-07-16T12:34:36.595Z",
      "updated": "2022-02-17T13:36:13.894Z",
      "publish_date": null,
      "archived": false,
      "for_everyone_access_role_id": "role-uid-1",
      "company_id": 10,
      "icon_type": "material_icon",
      "icon_value": "Star",
      "icon_color": 16,
      "settings": {},
      "access_record": {
        "role_permissions": {"document": {"read": true, "update": false}},
        "access_mod": "all",
        "entity_uid": "doc-uid-1",
        "user_id": 13,
        "own_role_ids": null,
        "own_groups_role_ids": null,
        "own_access_mod": null,
        "role_ids": null,
        "groups_role_ids": null,
        "role": 1,
        "own_role": null
      },
      "key": null,
      "id": "doc-uid-1",
      "group_id": "group-uid-1"
    }
    """

  // MARK: - List (version 1)

  @Test("200 returns a page of DocumentListItem")
  func listSuccess() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: "[\(Self.listItemJSON)]"))

    let page = try await client.listDocuments(query: "handbook")
    #expect(page.items.count == 1)
    let document = try #require(page.items.first)
    #expect(document.uid == "doc-uid-1")
    #expect(document.id?.value1 == "doc-uid-1")
    #expect(document.documentAccess == .forEveryone)
    #expect(document.documentIconType == .materialIcon)
    #expect(document.sort_order == 1.25)
    #expect(document.publish_date == nil)
    #expect(document.access_record?.role == 1)
    #expect(document.access_record?.user_id == 13)
    #expect(document.public_id == "pub-uid-1")
    #expect(document.updater_id == 12)
  }

  @Test("list sends query parameters")
  func listSendsQuery() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: "[]")
    let client = try makeClient(transport)

    _ = try await client.listDocuments(query: "handbook", offset: 5, limit: 10)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .get)
    let path = try #require(recorded.request.path)
    #expect(path.hasPrefix("/documents"))
    #expect(path.contains("query=handbook"))
    #expect(path.contains("offset=5"))
    #expect(path.contains("limit=10"))
    #expect(!path.contains("version="))
  }

  @Test("200 with empty body returns an empty page")
  func listEmptyBody() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: ""))
    let page = try await client.listDocuments()
    #expect(page.items.isEmpty)
  }

  @Test("invalid pagination fails fast")
  func listInvalidPagination() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: "[]"))
    await #expect(throws: KaitenError.self) {
      _ = try await client.listDocuments(offset: -1)
    }
    await #expect(throws: KaitenError.self) {
      _ = try await client.listDocuments(limit: 0)
    }
  }

  @Test("401 throws unauthorized")
  func listUnauthorized() async throws {
    let client = try makeClient(.returning(statusCode: 401))
    await #expect(throws: KaitenError.self) {
      _ = try await client.listDocuments()
    }
  }

  // MARK: - Search (version 2)

  @Test("200 returns result and position, and sends version=2")
  func searchSuccess() async throws {
    // Sanitized live version=2 response: rows add ftsVersion, mQueries and preview,
    // and carry archived/company_id, which the version=1 rows also have.
    let json = """
      {
        "result": [
          {
            "uid": "doc-uid-2",
            "path": "10.d4e5f6",
            "title": "Search me",
            "access": "by_invite",
            "public": false,
            "public_id": "pub-uid-2",
            "parent_entity_uid": "group-uid-2",
            "entity_type": "document",
            "sort_order": 1.39,
            "author_id": 21,
            "updater_id": 22,
            "created": "2026-07-30T19:39:22.962Z",
            "updated": "2026-07-30T19:39:57.378Z",
            "publish_date": null,
            "archived": false,
            "for_everyone_access_role_id": "role-uid-1",
            "company_id": 10,
            "icon_type": null,
            "icon_value": null,
            "icon_color": null,
            "settings": {},
            "access_record": {"role": 2, "role_permissions": {}},
            "key": null,
            "id": "doc-uid-2",
            "group_id": "group-uid-2",
            "ftsVersion": "844826698",
            "mQueries": ["document_data_0", "document_title_0"],
            "preview": {"preview_text": "matched snippet"}
          }
        ],
        "position": "ODQ0ODI2Njk4"
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let response = try await client.searchDocuments(
      query: "snippet", fields: "data", includeSearchPreview: true)

    #expect(response.position == "ODQ0ODI2Njk4")
    #expect(response.result?.count == 1)
    let row = try #require(response.result?.first)
    #expect(row.uid == "doc-uid-2")
    #expect(row.documentAccess == .byInvite)
    #expect(row.ftsVersion == "844826698")
    #expect(row.mQueries == ["document_data_0", "document_title_0"])
    #expect(row.preview != nil)

    let recorded = try #require(transport.recordedRequests.first)
    let path = try #require(recorded.request.path)
    #expect(path.contains("version=2"))
    #expect(path.contains("fields=data"))
    #expect(path.contains("include_search_preview=true"))
  }

  @Test("200 with empty body returns an empty search response")
  func searchEmptyBody() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: ""))
    let response = try await client.searchDocuments(query: "nothing")
    #expect(response.result?.isEmpty == true)
    #expect(response.position == nil)
  }

  // MARK: - Get

  /// Sanitized live retrieve response: `data` is a JSON-encoded string (the docs declare
  /// an object), `author`/`updater`/`documentGroup` are embedded although undocumented,
  /// and `archived`/`company_id`/`version`/`schema_version` are absent.
  @Test("200 returns the document with string data and embedded users")
  func getSuccess() async throws {
    let json = """
      {
        "uid": "doc-uid-3",
        "path": "10.g7h8i9",
        "title": "How it works",
        "access": "by_invite",
        "public": false,
        "public_id": "pub-uid-3",
        "parent_entity_uid": "group-uid-3",
        "entity_type": "document",
        "sort_order": 1.14,
        "author_id": 31,
        "updater_id": 32,
        "created": "2024-08-29T15:14:28.295Z",
        "updated": "2026-06-30T09:51:49.871Z",
        "publish_date": null,
        "published_version": null,
        "for_everyone_access_role_id": "role-uid-1",
        "hidden_on_public_site": false,
        "icon_type": null,
        "icon_value": null,
        "icon_color": null,
        "settings": {},
        "slug": null,
        "notification_period_start": null,
        "notification_period_end": null,
        "redirect_url": null,
        "key": null,
        "id": "doc-uid-3",
        "group_id": "group-uid-3",
        "data": "{\\"type\\":\\"doc\\",\\"content\\":[{\\"type\\":\\"paragraph\\"}]}",
        "author": {"id": 31, "full_name": "Test Author", "username": "author", "email": "author@example.com"},
        "updater": {"id": 32, "full_name": "Test Updater", "username": "updater", "email": "updater@example.com"},
        "documentGroup": {"uid": "group-uid-3", "title": "Group"},
        "access_record": {"role": 2, "role_permissions": {}, "access_mod": "all", "entity_uid": "doc-uid-3", "user_id": 13}
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let document = try await client.getDocument(uid: "doc-uid-3")

    #expect(document.uid == "doc-uid-3")
    #expect(document.id?.value1 == "doc-uid-3")
    #expect(document.documentAccess == .byInvite)
    #expect(document.data?.value1?.contains("paragraph") == true)
    #expect(document.author?.full_name == "Test Author")
    #expect(document.updater?.id == 32)
    #expect(document.documentGroup != nil)
    #expect(document.slug == nil)
    #expect(document.access_record?.access_mod == "all")

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .get)
    #expect(recorded.request.path == "/documents/doc-uid-3")
  }

  /// Documents are addressed by string UID, which ``KaitenError/notFound(resource:id:)``
  /// cannot represent, so a 404 surfaces as `unexpectedResponse`.
  @Test("404 throws unexpectedResponse")
  func getNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await expectUnexpectedResponse(statusCode: 404) {
      _ = try await client.getDocument(uid: "missing")
    }
  }

  // MARK: - Create

  /// Fixture from the create-new-document docs example: there `id` is an integer and
  /// `data` is an object, so both anyOf branches must decode.
  @Test("create sends the body and parses the docs-shaped response")
  func createSendsBody() async throws {
    let json = """
      {
        "uid": "doc-uid-4",
        "id": 1,
        "title": "Getting started",
        "created": "2024-03-15T10:00:00.000Z",
        "updated": "2024-03-15T10:00:00.000Z",
        "archived": false,
        "company_id": 1,
        "author_id": 1,
        "parent_entity_uid": null,
        "entity_type": "document",
        "sort_order": 1,
        "access": "by_invite",
        "for_everyone_access_role_id": "role-uid-1",
        "data": {"type": "doc", "content": [{"type": "paragraph"}]},
        "version": 1,
        "published_version": null,
        "publish_date": null,
        "public": false,
        "hidden_on_public_site": false,
        "settings": {},
        "key": null,
        "redirect_url": null,
        "icon_type": null,
        "icon_value": null,
        "icon_color": null,
        "path": "1",
        "schema_version": 3,
        "notification_period_start": null,
        "notification_period_end": null,
        "group_id": null,
        "access_record": {"role": 3, "role_permissions": {"document": {"read": true}}}
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let document = try await client.createDocument(
      sortOrder: 1, title: "Getting started", parentEntityUid: "group-uid-4")

    #expect(document.uid == "doc-uid-4")
    #expect(document.id?.value2 == 1)
    #expect(document.data?.value2 != nil)
    #expect(document.version == 1)
    #expect(document.access_record?.role == 3)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .post)
    #expect(recorded.request.path == "/documents")

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["sort_order"] as? Double == 1)
    #expect(sent["title"] as? String == "Getting started")
    #expect(sent["parent_entity_uid"] as? String == "group-uid-4")
  }

  @Test("409 key conflict throws unexpectedResponse")
  func createConflict() async throws {
    let client = try makeClient(.returning(statusCode: 409))
    await expectUnexpectedResponse(statusCode: 409) {
      _ = try await client.createDocument(sortOrder: 1, key: "TAKEN")
    }
  }

  // MARK: - Update

  @Test("update targets the document UID and sends the fields")
  func updateSuccess() async throws {
    let json = """
      {"uid": "doc-uid-5", "id": 1, "title": "Renamed", "access": "for_everyone", "sort_order": 2}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let document = try await client.updateDocument(
      uid: "doc-uid-5",
      title: "Renamed",
      access: .forEveryone,
      isPublic: true,
      publishedVersion: .init(value1: nil, value2: "current"),
      iconType: .emoji,
      iconValue: "🎉"
    )

    #expect(document.title == "Renamed")
    #expect(document.documentAccess == .forEveryone)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .patch)
    #expect(recorded.request.path == "/documents/doc-uid-5")

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["title"] as? String == "Renamed")
    #expect(sent["access"] as? String == "for_everyone")
    #expect(sent["public"] as? Bool == true)
    #expect(sent["published_version"] as? String == "current")
    #expect(sent["icon_type"] as? String == "emoji")
    #expect(sent["icon_value"] as? String == "🎉")
  }

  @Test("update 404 throws unexpectedResponse")
  func updateNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await expectUnexpectedResponse(statusCode: 404) {
      _ = try await client.updateDocument(uid: "missing", title: "New title")
    }
  }

  // MARK: - Delete

  /// Fixture from the remove-document docs: the response table lists only uid, id,
  /// title and archived, and `id` is an integer there.
  @Test("delete returns the removed document")
  func deleteSuccess() async throws {
    let json = """
      {"uid": "doc-uid-6", "id": 1, "title": "Old notes", "archived": true}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let document = try await client.deleteDocument(uid: "doc-uid-6")

    #expect(document.uid == "doc-uid-6")
    #expect(document.id?.value2 == 1)
    #expect(document.archived == true)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .delete)
    #expect(recorded.request.path == "/documents/doc-uid-6")
  }

  @Test("delete 400 (child tree entities) throws unexpectedResponse")
  func deleteWithChildren() async throws {
    let client = try makeClient(.returning(statusCode: 400))
    await expectUnexpectedResponse(statusCode: 400) {
      _ = try await client.deleteDocument(uid: "doc-with-children")
    }
  }
}
