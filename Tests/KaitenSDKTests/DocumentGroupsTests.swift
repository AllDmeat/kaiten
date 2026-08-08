import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("DocumentGroups")
struct DocumentGroupsTests {

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

  /// Sanitized from a live version-1 list response. The list shape omits `created`, `updated`,
  /// `redirect_url` and `hidden_on_public_site` even though the documentation lists them, `id`
  /// is a string equal to `uid`, and `access_record` / `updater_id` are present although
  /// undocumented.
  private static let listItemJSON = """
    {
      "uid": "dg-uid-1",
      "path": "100",
      "access": "for_everyone",
      "title": "Handbook",
      "public": false,
      "parent_entity_uid": null,
      "entity_type": "document_group",
      "sort_order": 1.1483993608289147,
      "author_id": 7,
      "updater_id": 7,
      "news_feed": false,
      "hostname": null,
      "index_document_uid": null,
      "archived": false,
      "for_everyone_access_role_id": "role-uid-1",
      "company_id": 100,
      "icon_type": null,
      "icon_value": null,
      "icon_color": null,
      "key": null,
      "id": "dg-uid-1",
      "parent_group_id": null,
      "access_record": {
        "access_mod": "all",
        "entity_uid": "dg-uid-1",
        "user_id": 7,
        "own_role_ids": null,
        "own_groups_role_ids": null,
        "own_access_mod": null,
        "role_ids": ["role-uid-1"],
        "groups_role_ids": null,
        "role": 1,
        "own_role": null,
        "role_permissions": {"document": {"read": true, "create": false}}
      }
    }
    """

  // MARK: - List

  @Test("200 returns array of DocumentGroup")
  func listSuccess() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: "[\(Self.listItemJSON)]"))

    let groups = try await client.listDocumentGroups()
    #expect(groups.count == 1)
    #expect(groups[0].uid == "dg-uid-1")
    #expect(groups[0].id == "dg-uid-1")
    #expect(groups[0].documentGroupAccess == .forEveryone)
    #expect(groups[0].sort_order == 1.1483993608289147)
    #expect(groups[0].parent_entity_uid == nil)
    #expect(groups[0].updater_id == 7)
    #expect(groups[0].access_record?.role == 1)
    #expect(groups[0].access_record?.role_ids == ["role-uid-1"])
    #expect(groups[0].access_record?.own_role == nil)
  }

  @Test("list sends the documented query parameters")
  func listSendsQuery() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: "[]")
    let client = try makeClient(transport)

    _ = try await client.listDocumentGroups(query: "handbook", role: 2, offset: 10, limit: 50)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .get)
    let path = try #require(recorded.request.path)
    #expect(path.hasPrefix("/document-groups"))
    #expect(path.contains("query=handbook"))
    #expect(path.contains("role=2"))
    #expect(path.contains("offset=10"))
    #expect(path.contains("limit=50"))
    #expect(!path.contains("version="))
  }

  @Test("200 with empty body returns empty array")
  func listEmptyBody() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: ""))
    let groups = try await client.listDocumentGroups()
    #expect(groups.isEmpty)
  }

  /// The access discriminator is a plain string in the spec, so a value the documentation does
  /// not list must survive as `.unknown` instead of failing the response.
  @Test("undocumented access decodes as unknown")
  func listUnknownAccess() async throws {
    let json = """
      [{"uid": "dg-uid-2", "id": "dg-uid-2", "title": "Restricted", "access": "secret"}]
      """
    let client = try makeClient(.returning(statusCode: 200, body: json))

    let groups = try await client.listDocumentGroups()
    #expect(groups[0].documentGroupAccess == .unknown("secret"))
  }

  @Test("401 throws unauthorized")
  func listUnauthorized() async throws {
    let client = try makeClient(.returning(statusCode: 401))
    await #expect(throws: KaitenError.self) {
      _ = try await client.listDocumentGroups()
    }
  }

  // MARK: - Search (version=2)

  /// Sanitized from a live version=2 response: an object with `result` and `position`, whose
  /// items additionally carry the undocumented `mQueries` and `ftsVersion` fields.
  @Test("search returns result and position")
  func searchSuccess() async throws {
    let json = """
      {
        "result": [{
          "id": "dg-uid-3",
          "mQueries": ["document_group_title_0"],
          "ftsVersion": "123456",
          "uid": "dg-uid-3",
          "path": "100.aaaa.bbbb",
          "access": "by_invite",
          "title": "Recipes",
          "public": false,
          "parent_entity_uid": "dg-uid-2",
          "entity_type": "document_group",
          "sort_order": 1.5,
          "author_id": 8,
          "updater_id": 8,
          "news_feed": false,
          "hostname": null,
          "index_document_uid": null,
          "archived": false,
          "for_everyone_access_role_id": "role-uid-1",
          "company_id": 100,
          "icon_type": "emoji",
          "icon_value": "X",
          "icon_color": null,
          "key": null,
          "parent_group_id": "dg-uid-2"
        }],
        "position": "cursor-1"
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let response = try await client.searchDocumentGroups(query: "recipes", limit: 1)
    #expect(response.position == "cursor-1")
    #expect(response.result?.count == 1)
    #expect(response.result?.first?.uid == "dg-uid-3")
    #expect(response.result?.first?.documentGroupAccess == .byInvite)
    #expect(response.result?.first?.ftsVersion == "123456")

    let recorded = try #require(transport.recordedRequests.first)
    let path = try #require(recorded.request.path)
    #expect(path.contains("version=2"))
    #expect(path.contains("query=recipes"))
  }

  // MARK: - Get

  /// Sanitized from a live single-group response, which carries the undocumented `updater_id`,
  /// `protected`, `import_uid`, `description`, `public_id`, `fts_version`, `slug` and `branding`
  /// fields, and requested with `relations=author` so the author object is present.
  @Test("200 returns DocumentGroup")
  func getSuccess() async throws {
    let json = """
      {
        "created": "2024-02-06T05:51:53.337Z",
        "updated": "2024-02-06T05:57:41.826Z",
        "archived": false,
        "uid": "dg-uid-1",
        "access": "for_everyone",
        "entity_type": "document_group",
        "path": "100",
        "sort_order": 1.1483993608289147,
        "parent_entity_uid": null,
        "for_everyone_access_role_id": "role-uid-1",
        "icon_type": null,
        "icon_value": null,
        "icon_color": null,
        "company_id": 100,
        "protected": false,
        "import_uid": null,
        "title": "Handbook",
        "description": null,
        "public": false,
        "author_id": 7,
        "updater_id": 7,
        "id": "dg-uid-1",
        "parent_group_id": null,
        "public_id": "pub-uid-1",
        "hostname": null,
        "news_feed": false,
        "redirect_url": null,
        "hidden_on_public_site": false,
        "fts_version": "123456",
        "index_document_uid": null,
        "slug": null,
        "branding": null,
        "key": null,
        "documents": null,
        "groups": null,
        "parent": null,
        "author": {"id": 7, "username": "jdoe", "full_name": "Jane Doe", "email": "jdoe@example.com"},
        "access_record": {"role": 3, "role_permissions": {"document": {"read": true}}}
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let group = try await client.getDocumentGroup(uid: "dg-uid-1", relations: ["author"])
    #expect(group.uid == "dg-uid-1")
    #expect(group.created == "2024-02-06T05:51:53.337Z")
    #expect(group.hidden_on_public_site == false)
    #expect(group.protected == false)
    #expect(group.public_id == "pub-uid-1")
    #expect(group.description == nil)
    #expect(group.author != nil)
    #expect(group.parent == nil)
    #expect(group.access_record?.role == 3)

    let recorded = try #require(transport.recordedRequests.first)
    let path = try #require(recorded.request.path)
    #expect(path.hasPrefix("/document-groups/dg-uid-1"))
    #expect(path.contains("relations=author"))
  }

  /// Document groups are addressed by string UID, which ``KaitenError/notFound(resource:id:)``
  /// cannot represent, so a 404 surfaces as `unexpectedResponse`.
  @Test("get 404 throws unexpectedResponse")
  func getNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await expectUnexpectedResponse(statusCode: 404) {
      _ = try await client.getDocumentGroup(uid: "missing")
    }
  }

  // MARK: - Create

  @Test("create sends title and key in the body")
  func createSendsBody() async throws {
    let json = """
      {
        "uid": "dg-uid-9",
        "id": "dg-uid-9",
        "title": "New group",
        "created": "2026-01-01T00:00:00.000Z",
        "updated": "2026-01-01T00:00:00.000Z",
        "archived": false,
        "company_id": 100,
        "author_id": 7,
        "parent_entity_uid": null,
        "parent_group_id": null,
        "entity_type": "document_group",
        "sort_order": 2.5,
        "access": "for_everyone",
        "for_everyone_access_role_id": null,
        "hostname": null,
        "redirect_url": null,
        "key": "NEWGROUP",
        "icon_type": null,
        "icon_value": null,
        "icon_color": null,
        "public": false,
        "news_feed": false,
        "hidden_on_public_site": false,
        "path": "100",
        "index_document_uid": null,
        "access_record": {"role": 3, "role_permissions": {}}
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let group = try await client.createDocumentGroup(
      title: "New group", sortOrder: 2.5, key: "NEWGROUP")

    #expect(group.uid == "dg-uid-9")
    #expect(group.key == "NEWGROUP")

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .post)
    #expect(recorded.request.path == "/document-groups")

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["title"] as? String == "New group")
    #expect(sent["sort_order"] as? Double == 2.5)
    #expect(sent["key"] as? String == "NEWGROUP")
  }

  @Test("create 409 key conflict throws unexpectedResponse")
  func createConflict() async throws {
    let client = try makeClient(.returning(statusCode: 409))
    await expectUnexpectedResponse(statusCode: 409) {
      _ = try await client.createDocumentGroup(title: "Duplicate key")
    }
  }

  @Test("create 402 unsupported tariff throws unexpectedResponse")
  func createPaymentRequired() async throws {
    let client = try makeClient(.returning(statusCode: 402))
    await expectUnexpectedResponse(statusCode: 402) {
      _ = try await client.createDocumentGroup(title: "No tariff")
    }
  }

  // MARK: - Update

  @Test("update targets the document group UID")
  func updateSuccess() async throws {
    let json = """
      {"uid": "dg-uid-1", "id": "dg-uid-1", "title": "Renamed", "access": "by_invite"}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let group = try await client.updateDocumentGroup(
      uid: "dg-uid-1", title: "Renamed", access: .byInvite)

    #expect(group.title == "Renamed")
    #expect(group.documentGroupAccess == .byInvite)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .patch)
    #expect(recorded.request.path == "/document-groups/dg-uid-1")

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["title"] as? String == "Renamed")
    #expect(sent["access"] as? String == "by_invite")
  }

  @Test("update 404 throws unexpectedResponse")
  func updateNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await expectUnexpectedResponse(statusCode: 404) {
      _ = try await client.updateDocumentGroup(uid: "missing", title: "Renamed")
    }
  }

  // MARK: - Delete

  @Test("delete returns the removed stub")
  func deleteSuccess() async throws {
    let json = """
      {"uid": "dg-uid-1", "id": "dg-uid-1", "title": "Handbook", "archived": true}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let removed = try await client.deleteDocumentGroup(uid: "dg-uid-1")

    #expect(removed.uid == "dg-uid-1")
    #expect(removed.archived == true)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .delete)
    #expect(recorded.request.path == "/document-groups/dg-uid-1")
  }

  /// The API answers HTTP 400 while the group still has child tree entities.
  @Test("delete 400 throws unexpectedResponse")
  func deleteWithChildren() async throws {
    let client = try makeClient(.returning(statusCode: 400))
    await expectUnexpectedResponse(statusCode: 400) {
      _ = try await client.deleteDocumentGroup(uid: "dg-uid-1")
    }
  }
}
