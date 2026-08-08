import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("GroupEntities")
struct GroupEntitiesTests {

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

  /// Fixture shape mirrors the documentation example — the live API could not be queried because
  /// the verification token lacks group-admin rights (403 from /company/groups).
  @Test("200 returns array of GroupEntityListItem")
  func listSuccess() async throws {
    let json = """
      [
        {
          "uid": "entity-uid-1",
          "path": "1",
          "title": "Test space",
          "entity_type": "space",
          "own_role_ids": ["role-uid-1"]
        },
        {
          "uid": "entity-uid-2",
          "path": "1",
          "title": "",
          "entity_type": "document_group",
          "own_role_ids": ["role-uid-2"]
        },
        {
          "uid": "entity-uid-3",
          "path": "1",
          "title": "Test doc",
          "entity_type": "document",
          "own_role_ids": ["role-uid-1"]
        }
      ]
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let entities = try await client.listGroupEntities(groupUid: "group-uid-1")
    #expect(entities.count == 3)
    #expect(entities[0].uid == "entity-uid-1")
    #expect(entities[0].groupEntityType == .space)
    #expect(entities[0].own_role_ids == ["role-uid-1"])
    #expect(entities[1].groupEntityType == .documentGroup)
    #expect(entities[1].title == "")
    #expect(entities[2].groupEntityType == .document)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .get)
    #expect(recorded.request.path == "/company/groups/group-uid-1/entities")
  }

  @Test("200 with empty body returns empty array")
  func listEmptyBody() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: ""))
    let entities = try await client.listGroupEntities(groupUid: "group-uid-1")
    #expect(entities.isEmpty)
  }

  /// The entity type discriminator is a plain string in the spec: an undocumented value must
  /// survive as `.unknown` instead of failing the whole response.
  @Test("undocumented entity_type decodes as unknown")
  func listUndocumentedEntityType() async throws {
    let json = """
      [{"uid": "entity-uid-1", "path": "1", "title": "New thing", "entity_type": "whiteboard", "own_role_ids": []}]
      """
    let client = try makeClient(.returning(statusCode: 200, body: json))

    let entities = try await client.listGroupEntities(groupUid: "group-uid-1")
    #expect(entities[0].groupEntityType == .unknown("whiteboard"))
  }

  /// Groups are addressed by string UID, which ``KaitenError/notFound(resource:id:)`` cannot
  /// represent, so a 404 surfaces as `unexpectedResponse`.
  @Test("404 throws unexpectedResponse")
  func listNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await expectUnexpectedResponse(statusCode: 404) {
      _ = try await client.listGroupEntities(groupUid: "missing")
    }
  }

  @Test("401 throws unauthorized")
  func listUnauthorized() async throws {
    let client = try makeClient(.returning(statusCode: 401))
    await #expect(throws: KaitenError.self) {
      _ = try await client.listGroupEntities(groupUid: "group-uid-1")
    }
  }

  // MARK: - Add

  @Test("add sends entity_uid and role_ids and parses the group entity")
  func addSendsBody() async throws {
    let json = """
      {
        "group_id": 40,
        "entity_uid": "entity-uid-1",
        "role_permissions": {
          "root": {"move": true, "create": true},
          "space": {"read": true, "create": true, "delete": false},
          "document": {"read": true},
          "story_map": {"read": true},
          "document_group": {"read": true}
        },
        "access_mod": null,
        "own_role_ids": ["role-uid-1"],
        "own_access_mod": null,
        "role_ids": ["role-uid-1"]
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let entity = try await client.addGroupEntity(
      groupUid: "group-uid-1", entityUid: "entity-uid-1", roleIds: ["role-uid-1"])

    #expect(entity.group_id == 40)
    #expect(entity.entity_uid == "entity-uid-1")
    #expect(entity.access_mod == nil)
    #expect(entity.own_access_mod == nil)
    #expect(entity.role_ids == ["role-uid-1"])
    #expect(entity.own_role_ids == ["role-uid-1"])
    #expect(entity.role_permissions != nil)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .post)
    #expect(recorded.request.path == "/company/groups/group-uid-1/entities")

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["entity_uid"] as? String == "entity-uid-1")
    #expect(sent["role_ids"] as? [String] == ["role-uid-1"])
  }

  @Test("add 400 throws unexpectedResponse")
  func addBadRequest() async throws {
    let client = try makeClient(.returning(statusCode: 400))
    await expectUnexpectedResponse(statusCode: 400) {
      _ = try await client.addGroupEntity(
        groupUid: "group-uid-1", entityUid: "entity-uid-1", roleIds: ["role-uid-1"])
    }
  }

  @Test("add 402 unsupported tariff throws unexpectedResponse")
  func addPaymentRequired() async throws {
    let client = try makeClient(.returning(statusCode: 402))
    await expectUnexpectedResponse(statusCode: 402) {
      _ = try await client.addGroupEntity(
        groupUid: "group-uid-1", entityUid: "entity-uid-1", roleIds: ["role-uid-1"])
    }
  }

  // MARK: - Update

  @Test("update targets the entity UID and parses the group entity")
  func updateSuccess() async throws {
    let json = """
      {
        "group_id": 40,
        "entity_uid": "entity-uid-1",
        "role_permissions": {"root": {"move": true, "create": true}},
        "access_mod": null,
        "own_role_ids": ["role-uid-2"],
        "own_access_mod": null,
        "role_ids": ["role-uid-2"]
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let entity = try await client.updateGroupEntity(
      groupUid: "group-uid-1", uid: "entity-uid-1", roleIds: ["role-uid-2"])

    #expect(entity.role_ids == ["role-uid-2"])

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .patch)
    #expect(recorded.request.path == "/company/groups/group-uid-1/entities/entity-uid-1")

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["role_ids"] as? [String] == ["role-uid-2"])
  }

  @Test("update 400 throws unexpectedResponse")
  func updateBadRequest() async throws {
    let client = try makeClient(.returning(statusCode: 400))
    await expectUnexpectedResponse(statusCode: 400) {
      _ = try await client.updateGroupEntity(
        groupUid: "group-uid-1", uid: "entity-uid-1", roleIds: [])
    }
  }

  // MARK: - Remove

  /// The remove response nulls out `own_role_ids` and `role_permissions`, which the documentation
  /// for the other endpoints declares as non-nullable.
  @Test("remove parses nulled own_role_ids and role_permissions")
  func removeSuccess() async throws {
    let json = """
      {
        "group_id": 40,
        "entity_uid": "entity-uid-1",
        "role_permissions": null,
        "access_mod": null,
        "own_role_ids": null,
        "own_access_mod": null,
        "role_ids": []
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let entity = try await client.removeGroupEntity(groupUid: "group-uid-1", uid: "entity-uid-1")

    #expect(entity.group_id == 40)
    #expect(entity.own_role_ids == nil)
    #expect(entity.role_permissions == nil)
    #expect(entity.role_ids == [])

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .delete)
    #expect(recorded.request.path == "/company/groups/group-uid-1/entities/entity-uid-1")
  }

  @Test("remove 403 throws unexpectedResponse")
  func removeForbidden() async throws {
    let client = try makeClient(.returning(statusCode: 403))
    await expectUnexpectedResponse(statusCode: 403) {
      _ = try await client.removeGroupEntity(groupUid: "group-uid-1", uid: "entity-uid-1")
    }
  }
}
