import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("CustomPropertyTreeEntities")
struct CustomPropertyTreeEntitiesTests {

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

  /// Fixture mirrors a sanitized live response: every field the documentation
  /// lists came back non-null, and `sort_order` is a fractional number.
  @Test("200 returns array of CustomPropertyTreeEntity")
  func listSuccess() async throws {
    let json = """
      [{
        "uid": "11111111-2222-3333-4444-555555555555",
        "access": "by_invite",
        "for_everyone_access_role_id": "66666666-7777-8888-9999-aaaaaaaaaaaa",
        "entity_type": "space",
        "path": "10.abc123.def456",
        "sort_order": 1.4588347597716682,
        "parent_entity_uid": "bbbbbbbb-cccc-dddd-eeee-ffffffffffff",
        "company_id": 10,
        "protected": false,
        "archived": false,
        "title": "Product space"
      }]
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let entities = try await client.listCustomPropertyTreeEntities(propertyId: 42)
    #expect(entities.count == 1)
    #expect(entities[0].uid == "11111111-2222-3333-4444-555555555555")
    #expect(entities[0].access == "by_invite")
    #expect(entities[0].for_everyone_access_role_id == "66666666-7777-8888-9999-aaaaaaaaaaaa")
    #expect(entities[0].entity_type == "space")
    #expect(entities[0].path == "10.abc123.def456")
    #expect(entities[0].sort_order == 1.4588347597716682)
    #expect(entities[0].parent_entity_uid == "bbbbbbbb-cccc-dddd-eeee-ffffffffffff")
    #expect(entities[0].company_id == 10)
    #expect(entities[0].protected == false)
    #expect(entities[0].archived == false)
    #expect(entities[0].title == "Product space")

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .get)
    #expect(recorded.request.path == "/company/custom-properties/42/tree-entities")
  }

  /// The live API returns an empty array for a property with no usage paths.
  @Test("200 with empty array returns empty array")
  func listEmpty() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: "[]"))
    let entities = try await client.listCustomPropertyTreeEntities(propertyId: 42)
    #expect(entities.isEmpty)
  }

  @Test("401 throws unauthorized")
  func listUnauthorized() async throws {
    let client = try makeClient(.returning(statusCode: 401))
    await #expect(throws: KaitenError.self) {
      _ = try await client.listCustomPropertyTreeEntities(propertyId: 42)
    }
  }

  @Test("402 unsupported tariff throws unexpectedResponse")
  func listPaymentRequired() async throws {
    let client = try makeClient(.returning(statusCode: 402))
    await expectUnexpectedResponse(statusCode: 402) {
      _ = try await client.listCustomPropertyTreeEntities(propertyId: 42)
    }
  }

  @Test("403 throws unexpectedResponse")
  func listForbidden() async throws {
    let client = try makeClient(.returning(statusCode: 403))
    await expectUnexpectedResponse(statusCode: 403) {
      _ = try await client.listCustomPropertyTreeEntities(propertyId: 42)
    }
  }

  // MARK: - Add

  /// Fixture follows the documented example response: an object with the custom property id.
  @Test("add sends tree_entity_uid and returns the custom property id")
  func addSuccess() async throws {
    let json = """
      {"id": 42}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let result = try await client.addCustomPropertyTreeEntity(
      propertyId: 42, treeEntityUid: "11111111-2222-3333-4444-555555555555")
    #expect(result.id == 42)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .post)
    #expect(recorded.request.path == "/company/custom-properties/42/tree-entities")

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["tree_entity_uid"] as? String == "11111111-2222-3333-4444-555555555555")
  }

  @Test("add 400 throws unexpectedResponse")
  func addBadRequest() async throws {
    let client = try makeClient(.returning(statusCode: 400))
    await expectUnexpectedResponse(statusCode: 400) {
      _ = try await client.addCustomPropertyTreeEntity(propertyId: 42, treeEntityUid: "missing-uid")
    }
  }

  @Test("add 402 unsupported tariff throws unexpectedResponse")
  func addPaymentRequired() async throws {
    let client = try makeClient(.returning(statusCode: 402))
    await expectUnexpectedResponse(statusCode: 402) {
      _ = try await client.addCustomPropertyTreeEntity(propertyId: 42, treeEntityUid: "some-uid")
    }
  }

  // MARK: - Delete

  /// Fixture follows the documented response schema: an object with the custom property id.
  @Test("delete targets the tree entity UID and returns the custom property id")
  func deleteSuccess() async throws {
    let json = """
      {"id": 42}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let result = try await client.deleteCustomPropertyTreeEntity(
      propertyId: 42, uid: "11111111-2222-3333-4444-555555555555")
    #expect(result.id == 42)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .delete)
    #expect(
      recorded.request.path
        == "/company/custom-properties/42/tree-entities/11111111-2222-3333-4444-555555555555")
  }

  @Test("delete 403 throws unexpectedResponse")
  func deleteForbidden() async throws {
    let client = try makeClient(.returning(statusCode: 403))
    await expectUnexpectedResponse(statusCode: 403) {
      _ = try await client.deleteCustomPropertyTreeEntity(propertyId: 42, uid: "some-uid")
    }
  }

  @Test("delete 401 throws unauthorized")
  func deleteUnauthorized() async throws {
    let client = try makeClient(.returning(statusCode: 401))
    await #expect(throws: KaitenError.self) {
      _ = try await client.deleteCustomPropertyTreeEntity(propertyId: 42, uid: "some-uid")
    }
  }
}
