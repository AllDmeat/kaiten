import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("Groups")
struct GroupsTests {

  private func makeClient(_ transport: MockClientTransport) throws -> KaitenClient {
    try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)
  }

  /// A group object matching the documentation example. Live verification is unavailable —
  /// the endpoints answer 403 to tokens without access to the administrative section "Members".
  private static let groupJSON = """
    {
      "name": "QA engineers",
      "permissions": 3,
      "add_to_cards_and_spaces_enabled": false,
      "updated": "2024-08-29T13:16:19.886Z",
      "created": "2024-08-29T13:16:19.886Z",
      "id": 11,
      "uid": "00000000-0000-4000-8000-000000000001"
    }
    """

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

  @Test("200 returns array of Group")
  func listSuccess() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: "[\(Self.groupJSON)]"))

    let groups = try await client.listGroups()
    #expect(groups.count == 1)
    #expect(groups[0].id == 11)
    #expect(groups[0].uid == "00000000-0000-4000-8000-000000000001")
    #expect(groups[0].name == "QA engineers")
    #expect(groups[0].permissions == 3)
    #expect(groups[0].add_to_cards_and_spaces_enabled == false)
    #expect(groups[0].created == "2024-08-29T13:16:19.886Z")
    #expect(groups[0].updated == "2024-08-29T13:16:19.886Z")
  }

  @Test("200 with empty body returns empty array")
  func listEmptyBody() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: ""))
    let groups = try await client.listGroups()
    #expect(groups.isEmpty)
  }

  @Test("query parameters are sent")
  func listSendsQueryParameters() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: "[]")
    let client = try makeClient(transport)

    _ = try await client.listGroups(
      withTreeEntities: true,
      withUsersCount: true,
      withSyncGroupAttribute: true,
      condition: .inactive,
      query: "designers",
      limit: 50,
      offset: 100
    )

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .get)
    let path = try #require(recorded.request.path)
    #expect(path.hasPrefix("/company/groups?"))
    #expect(path.contains("with_tree_entities=true"))
    #expect(path.contains("with_users_count=true"))
    #expect(path.contains("with_sync_group_attribute=true"))
    #expect(path.contains("condition=2"))
    #expect(path.contains("query=designers"))
    #expect(path.contains("limit=50"))
    #expect(path.contains("offset=100"))
  }

  @Test("401 throws unauthorized")
  func listUnauthorized() async throws {
    let client = try makeClient(.returning(statusCode: 401))
    await #expect(throws: KaitenError.self) {
      _ = try await client.listGroups()
    }
  }

  /// The endpoint answers 403 with an empty body when the token's user has no access to the
  /// administrative section "Members" (verified live).
  @Test("403 throws unexpectedResponse")
  func listForbidden() async throws {
    let client = try makeClient(.returning(statusCode: 403))
    await expectUnexpectedResponse(statusCode: 403) {
      _ = try await client.listGroups()
    }
  }

  // MARK: - Create

  @Test("create sends the body and parses the group")
  func createSendsBody() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: Self.groupJSON)
    let client = try makeClient(transport)

    let group = try await client.createGroup(
      name: "QA engineers",
      permissions: 3,
      addToCardsAndSpacesEnabled: false
    )

    #expect(group.id == 11)
    #expect(group.name == "QA engineers")

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .post)
    #expect(recorded.request.path == "/company/groups")

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["name"] as? String == "QA engineers")
    #expect(sent["permissions"] as? Int == 3)
    #expect(sent["add_to_cards_and_spaces_enabled"] as? Bool == false)
  }

  @Test("402 unsupported tariff throws unexpectedResponse")
  func createPaymentRequired() async throws {
    let client = try makeClient(.returning(statusCode: 402))
    await expectUnexpectedResponse(statusCode: 402) {
      _ = try await client.createGroup(name: "QA engineers")
    }
  }

  // MARK: - Get

  @Test("200 returns the group")
  func getSuccess() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: Self.groupJSON)
    let client = try makeClient(transport)

    let group = try await client.getGroup(uid: "00000000-0000-4000-8000-000000000001")

    #expect(group.id == 11)
    #expect(group.name == "QA engineers")

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .get)
    #expect(recorded.request.path == "/company/groups/00000000-0000-4000-8000-000000000001")
  }

  /// Groups are addressed by string UID, which ``KaitenError/notFound(resource:id:)``
  /// cannot represent, so a 404 surfaces as `unexpectedResponse`.
  @Test("404 throws unexpectedResponse")
  func getNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await expectUnexpectedResponse(statusCode: 404) {
      _ = try await client.getGroup(uid: "missing")
    }
  }

  // MARK: - Update

  @Test("update targets the group UID")
  func updateSuccess() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: Self.groupJSON)
    let client = try makeClient(transport)

    let group = try await client.updateGroup(
      uid: "00000000-0000-4000-8000-000000000001", name: "QA engineers", permissions: 3)

    #expect(group.name == "QA engineers")
    #expect(group.permissions == 3)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .patch)
    #expect(recorded.request.path == "/company/groups/00000000-0000-4000-8000-000000000001")

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["name"] as? String == "QA engineers")
    #expect(sent["permissions"] as? Int == 3)
  }

  @Test("update 400 throws unexpectedResponse")
  func updateBadRequest() async throws {
    let client = try makeClient(.returning(statusCode: 400))
    await expectUnexpectedResponse(statusCode: 400) {
      _ = try await client.updateGroup(uid: "uid-1", name: "")
    }
  }

  // MARK: - Remove

  @Test("remove returns the removed group")
  func removeSuccess() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: Self.groupJSON)
    let client = try makeClient(transport)

    let group = try await client.removeGroup(uid: "00000000-0000-4000-8000-000000000001")

    #expect(group.id == 11)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .delete)
    #expect(recorded.request.path == "/company/groups/00000000-0000-4000-8000-000000000001")
  }

  @Test("remove 403 throws unexpectedResponse")
  func removeForbidden() async throws {
    let client = try makeClient(.returning(statusCode: 403))
    await expectUnexpectedResponse(statusCode: 403) {
      _ = try await client.removeGroup(uid: "uid-1")
    }
  }
}
