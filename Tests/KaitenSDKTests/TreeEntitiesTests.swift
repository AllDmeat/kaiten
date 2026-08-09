import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("TreeEntities")
struct TreeEntitiesTests {

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

  // MARK: - List

  /// Fixture is a sanitized live response. Each entity type carries its own extra fields
  /// beyond the documented common ones: spaces have `external_id` and `work_calendar_id`,
  /// document groups have `hostname`, `index_document_uid` and `news_feed`, documents have
  /// `created`, `updated`, `public_id`, `publish_date` and `settings` — and lack `id`.
  @Test("200 returns page of TreeEntity")
  func listSuccess() async throws {
    let json = """
      [{
        "shared": false,
        "id": 11,
        "uid": "sp-uid-1",
        "title": "Space One",
        "external_id": null,
        "company_id": 100,
        "sort_order": 271.4964174176432,
        "path": "100",
        "parent_entity_uid": null,
        "entity_type": "space",
        "access": "by_invite",
        "archived": false,
        "for_everyone_access_role_id": "role-uid-1",
        "work_calendar_id": null,
        "icon_type": null,
        "icon_value": null,
        "icon_color": null,
        "author_uid": null,
        "has_children": false,
        "key": null
      },
      {
        "shared": false,
        "id": 12,
        "uid": "dg-uid-1",
        "title": "Docs Group",
        "access": "for_everyone",
        "sort_order": 12,
        "author_id": 21,
        "company_id": 100,
        "path": "100",
        "parent_entity_uid": null,
        "entity_type": "document_group",
        "archived": false,
        "for_everyone_access_role_id": "role-uid-2",
        "icon_type": "emoji",
        "icon_value": "1f4d6",
        "icon_color": null,
        "hostname": null,
        "index_document_uid": null,
        "news_feed": false,
        "public": false,
        "updater_id": 21,
        "has_children": true,
        "key": null
      },
      {
        "shared": false,
        "uid": "doc-uid-1",
        "title": "A Document",
        "access": "for_everyone",
        "sort_order": 1.5,
        "author_id": 21,
        "company_id": 100,
        "path": "100.aaaa",
        "parent_entity_uid": "dg-uid-1",
        "entity_type": "document",
        "archived": false,
        "for_everyone_access_role_id": "role-uid-2",
        "icon_type": null,
        "icon_value": null,
        "icon_color": null,
        "public": false,
        "public_id": "pub-id-1",
        "publish_date": null,
        "settings": {"cover": null},
        "created": "2026-04-01T12:00:00.000Z",
        "updated": "2026-04-02T12:00:00.000Z",
        "updater_id": 21,
        "has_children": false,
        "key": null
      }]
      """
    let client = try makeClient(.returning(statusCode: 200, body: json))

    let page = try await client.listTreeEntities()
    #expect(page.items.count == 3)

    let space = try #require(page.items.first)
    #expect(space.uid == "sp-uid-1")
    #expect(space.treeEntityType == .space)
    #expect(space.id == 11)
    #expect(space.parent_entity_uid == nil)
    #expect(space.external_id == nil)
    #expect(space.work_calendar_id == nil)
    #expect(space.archived == false)
    #expect(space.access == "by_invite")
    #expect(space.for_everyone_access_role_id == "role-uid-1")
    #expect(space.sort_order == 271.4964174176432)
    #expect(space.has_children == false)

    let group = page.items[1]
    #expect(group.treeEntityType == .documentGroup)
    #expect(group.icon_type == "emoji")
    #expect(group.icon_value == "1f4d6")
    #expect(group.news_feed == false)
    #expect(group.has_children == true)

    let document = page.items[2]
    #expect(document.treeEntityType == .document)
    #expect(document.id == nil)
    #expect(document.parent_entity_uid == "dg-uid-1")
    #expect(document.public_id == "pub-id-1")
    #expect(document.publish_date == nil)
    #expect(document.settings != nil)
    #expect(document.created == "2026-04-01T12:00:00.000Z")
  }

  @Test("200 with empty body returns empty page")
  func listEmptyBody() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: ""))
    let page = try await client.listTreeEntities()
    #expect(page.items.isEmpty)
    #expect(!page.hasMore)
  }

  /// The documentation lists no `entity_type` values and marks the endpoint as under active
  /// development. A closed enum would fail the whole response, so new values must survive
  /// as `.unknown`.
  @Test("undocumented entity type decodes as unknown")
  func listUndocumentedEntityType() async throws {
    let json = """
      [{
        "uid": "uid-1",
        "title": "Story Map",
        "entity_type": "story_map",
        "sort_order": 1,
        "archived": false,
        "access": "for_everyone",
        "for_everyone_access_role_id": "role-uid-1",
        "path": "100",
        "parent_entity_uid": null
      },
      {
        "uid": "uid-2",
        "title": "New Thing",
        "entity_type": "some_new_entity",
        "sort_order": 2,
        "archived": false,
        "access": "by_invite",
        "for_everyone_access_role_id": "role-uid-1",
        "path": "100",
        "parent_entity_uid": null
      }]
      """
    let client = try makeClient(.returning(statusCode: 200, body: json))

    let page = try await client.listTreeEntities()
    #expect(page.items[0].treeEntityType == .storyMap)
    #expect(page.items[1].treeEntityType == .unknown("some_new_entity"))
  }

  @Test("query parameters are sent")
  func listSendsQueryParameters() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: "[]")
    let client = try makeClient(transport)

    _ = try await client.listTreeEntities(
      parentEntityUid: "parent-uid-1",
      levelsCount: 2,
      offset: 50,
      limit: 200
    )

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .get)
    let path = try #require(recorded.request.path)
    #expect(path.hasPrefix("/tree-entities?"))
    #expect(path.contains("parent_entity_uid=parent-uid-1"))
    #expect(path.contains("levels_count=2"))
    #expect(path.contains("offset=50"))
    #expect(path.contains("limit=200"))
  }

  @Test("limit above 500 throws invalidPaginationRange")
  func listInvalidPagination() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: "[]"))
    await #expect(throws: KaitenError.self) {
      _ = try await client.listTreeEntities(limit: 501)
    }
  }

  @Test("401 throws unauthorized")
  func listUnauthorized() async throws {
    let client = try makeClient(.returning(statusCode: 401))
    await #expect(throws: KaitenError.self) {
      _ = try await client.listTreeEntities()
    }
  }

  @Test("403 throws unexpectedResponse")
  func listForbidden() async throws {
    let client = try makeClient(.returning(statusCode: 403))
    await expectUnexpectedResponse(statusCode: 403) {
      _ = try await client.listTreeEntities()
    }
  }
}
