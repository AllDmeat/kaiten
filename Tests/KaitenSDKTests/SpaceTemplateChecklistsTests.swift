import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("Space Template Checklists")
struct SpaceTemplateChecklistsTests {

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

  /// Sanitized live response. The API adds an integer `id` to both the checklist and its items,
  /// which the documentation does not list, and `sort_order` is a fractional number.
  @Test("200 returns array of SpaceTemplateChecklist")
  func listSuccess() async throws {
    let json = """
      [{
        "created": "2026-06-08T10:29:11.582Z",
        "updated": "2026-06-08T11:32:45.276Z",
        "id": 101,
        "uid": "checklist-uid-1",
        "name": "Planning process",
        "sort_order": 1.185695424827543,
        "space_uid": "space-uid-1",
        "items": [
          {
            "created": "2026-06-08T10:29:11.873Z",
            "updated": "2026-06-08T10:29:11.873Z",
            "id": 201,
            "text": "Hold the daily meeting",
            "sort_order": 1,
            "user_id": 42,
            "uid": "item-uid-1"
          },
          {
            "created": "2026-06-08T10:29:11.833Z",
            "updated": "2026-06-08T10:39:02.338Z",
            "id": 202,
            "text": "Review the sprint board",
            "sort_order": 2.5035946967394869,
            "user_id": 42,
            "uid": "item-uid-2"
          }
        ]
      }]
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let checklists = try await client.listSpaceTemplateChecklists(spaceUid: "space-uid-1")

    #expect(checklists.count == 1)
    #expect(checklists[0].uid == "checklist-uid-1")
    #expect(checklists[0].id == 101)
    #expect(checklists[0].name == "Planning process")
    #expect(checklists[0].sort_order == 1.185695424827543)
    #expect(checklists[0].space_uid == "space-uid-1")
    #expect(checklists[0].items?.count == 2)
    #expect(checklists[0].items?[0].uid == "item-uid-1")
    #expect(checklists[0].items?[0].id == 201)
    #expect(checklists[0].items?[0].text == "Hold the daily meeting")
    #expect(checklists[0].items?[0].user_id == 42)
    #expect(checklists[0].items?[1].sort_order == 2.5035946967394869)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .get)
    #expect(recorded.request.path == "/spaces/space-uid-1/template-checklists")
  }

  @Test("200 with empty body returns empty array")
  func listEmptyBody() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: ""))
    let checklists = try await client.listSpaceTemplateChecklists(spaceUid: "space-uid-1")
    #expect(checklists.isEmpty)
  }

  @Test("401 throws unauthorized")
  func listUnauthorized() async throws {
    let client = try makeClient(.returning(statusCode: 401))
    await #expect(throws: KaitenError.self) {
      _ = try await client.listSpaceTemplateChecklists(spaceUid: "space-uid-1")
    }
  }

  /// Spaces are addressed here by string UID, which ``KaitenError/notFound(resource:id:)``
  /// cannot represent, so a 404 surfaces as `unexpectedResponse`.
  @Test("404 throws unexpectedResponse")
  func listNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await expectUnexpectedResponse(statusCode: 404) {
      _ = try await client.listSpaceTemplateChecklists(spaceUid: "missing-uid")
    }
  }

  // MARK: - Create

  /// The documented create response carries the checklist without its `items`.
  @Test("create sends name and sort_order in the body")
  func createSendsBody() async throws {
    let json = """
      {
        "uid": "checklist-uid-2",
        "name": "Release checklist",
        "sort_order": 1,
        "space_uid": "space-uid-1",
        "created": "2026-06-08T10:29:11.582Z",
        "updated": "2026-06-08T10:29:11.582Z"
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let checklist = try await client.createSpaceTemplateChecklist(
      spaceUid: "space-uid-1", name: "Release checklist", sortOrder: 1)

    #expect(checklist.uid == "checklist-uid-2")
    #expect(checklist.name == "Release checklist")
    #expect(checklist.items == nil)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .post)
    #expect(recorded.request.path == "/spaces/space-uid-1/template-checklists")

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["name"] as? String == "Release checklist")
    #expect(sent["sort_order"] as? Double == 1)
  }

  @Test("create 401 throws unauthorized")
  func createUnauthorized() async throws {
    let client = try makeClient(.returning(statusCode: 401))
    await #expect(throws: KaitenError.self) {
      _ = try await client.createSpaceTemplateChecklist(
        spaceUid: "space-uid-1", name: "Release checklist")
    }
  }

  // MARK: - Update

  @Test("update targets the template checklist UID")
  func updateSuccess() async throws {
    let json = """
      {
        "uid": "checklist-uid-1",
        "name": "Renamed checklist",
        "sort_order": 2.5,
        "space_uid": "space-uid-1",
        "created": "2026-06-08T10:29:11.582Z",
        "updated": "2026-06-09T08:00:00.000Z"
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let checklist = try await client.updateSpaceTemplateChecklist(
      spaceUid: "space-uid-1",
      templateChecklistUid: "checklist-uid-1",
      name: "Renamed checklist",
      sortOrder: 2.5
    )

    #expect(checklist.name == "Renamed checklist")
    #expect(checklist.sort_order == 2.5)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .patch)
    #expect(recorded.request.path == "/spaces/space-uid-1/template-checklists/checklist-uid-1")

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["name"] as? String == "Renamed checklist")
    #expect(sent["sort_order"] as? Double == 2.5)
    #expect(sent["space_uid"] == nil)
  }

  /// Both path components are string UIDs, which ``KaitenError/notFound(resource:id:)``
  /// cannot represent, so a 404 surfaces as `unexpectedResponse`.
  @Test("update 404 throws unexpectedResponse")
  func updateNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await expectUnexpectedResponse(statusCode: 404) {
      _ = try await client.updateSpaceTemplateChecklist(
        spaceUid: "space-uid-1", templateChecklistUid: "missing-uid", name: "Renamed")
    }
  }

  // MARK: - Remove

  /// The documented remove response is an object carrying only the deleted checklist UID.
  @Test("remove returns the deleted UID")
  func removeSuccess() async throws {
    let json = """
      {"uid": "checklist-uid-1"}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let response = try await client.removeSpaceTemplateChecklist(
      spaceUid: "space-uid-1", templateChecklistUid: "checklist-uid-1")

    #expect(response.uid == "checklist-uid-1")

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .delete)
    #expect(recorded.request.path == "/spaces/space-uid-1/template-checklists/checklist-uid-1")
  }

  @Test("remove 401 throws unauthorized")
  func removeUnauthorized() async throws {
    let client = try makeClient(.returning(statusCode: 401))
    await #expect(throws: KaitenError.self) {
      _ = try await client.removeSpaceTemplateChecklist(
        spaceUid: "space-uid-1", templateChecklistUid: "checklist-uid-1")
    }
  }
}
