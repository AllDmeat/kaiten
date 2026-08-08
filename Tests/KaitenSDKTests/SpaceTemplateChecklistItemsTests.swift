import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("Space Template Checklist Items")
struct SpaceTemplateChecklistItemsTests {

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

  /// Fixture based on the documentation example response. Live template checklist items carry
  /// fractional `sort_order` values, so the fixture uses one to prove `number` decoding.
  private static let itemJSON = """
    {
      "uid": "item-uid-1",
      "text": "Item name",
      "sort_order": 1.5,
      "user_id": 42,
      "created": "2025-04-14T11:36:37.154Z",
      "updated": "2025-04-14T11:36:37.154Z"
    }
    """

  // MARK: - Create

  @Test("create 200 returns the created item and sends the body")
  func createSuccess() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: Self.itemJSON)
    let client = try makeClient(transport)

    let item = try await client.createSpaceTemplateChecklistItem(
      spaceUid: "space-uid-1",
      templateChecklistUid: "checklist-uid-1",
      text: "Item name",
      sortOrder: 1.5
    )

    #expect(item.uid == "item-uid-1")
    #expect(item.text == "Item name")
    #expect(item.sort_order == 1.5)
    #expect(item.user_id == 42)
    #expect(item.created == "2025-04-14T11:36:37.154Z")
    #expect(item.updated == "2025-04-14T11:36:37.154Z")

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .post)
    #expect(
      recorded.request.path == "/spaces/space-uid-1/template-checklists/checklist-uid-1/items")

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["text"] as? String == "Item name")
    #expect(sent["sort_order"] as? Double == 1.5)
  }

  @Test("create 401 throws unauthorized")
  func createUnauthorized() async throws {
    let client = try makeClient(.returning(statusCode: 401))
    do {
      _ = try await client.createSpaceTemplateChecklistItem(
        spaceUid: "space-uid-1", templateChecklistUid: "checklist-uid-1", text: "Item name")
      Issue.record("expected KaitenError.unauthorized, no error thrown")
    } catch let error as KaitenError {
      guard case .unauthorized = error else {
        Issue.record("expected KaitenError.unauthorized, got \(error)")
        return
      }
    } catch {
      Issue.record("expected KaitenError, got \(error)")
    }
  }

  // MARK: - Update

  @Test("update 200 targets the item UID and returns the item")
  func updateSuccess() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: Self.itemJSON)
    let client = try makeClient(transport)

    let item = try await client.updateSpaceTemplateChecklistItem(
      spaceUid: "space-uid-1",
      templateChecklistUid: "checklist-uid-1",
      itemUid: "item-uid-1",
      text: "Item name"
    )

    #expect(item.uid == "item-uid-1")
    #expect(item.sort_order == 1.5)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .patch)
    #expect(
      recorded.request.path
        == "/spaces/space-uid-1/template-checklists/checklist-uid-1/items/item-uid-1")
  }

  /// The space, the template checklist and the item are all addressed by string UIDs, which
  /// ``KaitenError/notFound(resource:id:)`` cannot represent, so a 404 surfaces as
  /// `unexpectedResponse`.
  @Test("update 404 throws unexpectedResponse")
  func updateNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await expectUnexpectedResponse(statusCode: 404) {
      _ = try await client.updateSpaceTemplateChecklistItem(
        spaceUid: "space-uid-1", templateChecklistUid: "checklist-uid-1", itemUid: "missing")
    }
  }

  // MARK: - Remove

  @Test("remove 200 returns the deleted item UID")
  func removeSuccess() async throws {
    let json = """
      {"uid": "item-uid-1"}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let deletedUid = try await client.removeSpaceTemplateChecklistItem(
      spaceUid: "space-uid-1",
      templateChecklistUid: "checklist-uid-1",
      itemUid: "item-uid-1"
    )

    #expect(deletedUid == "item-uid-1")

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .delete)
    #expect(
      recorded.request.path
        == "/spaces/space-uid-1/template-checklists/checklist-uid-1/items/item-uid-1")
  }

  @Test("remove 404 throws unexpectedResponse")
  func removeNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await expectUnexpectedResponse(statusCode: 404) {
      _ = try await client.removeSpaceTemplateChecklistItem(
        spaceUid: "space-uid-1", templateChecklistUid: "checklist-uid-1", itemUid: "missing")
    }
  }
}
