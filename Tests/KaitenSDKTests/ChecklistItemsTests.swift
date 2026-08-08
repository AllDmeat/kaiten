import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

/// Tests for the checklist-scoped item endpoints (`/checklists/{checklist_id}/items`).
/// Fixtures follow the documented example responses; these endpoints are mutating,
/// so no live response was captured.
@Suite("ChecklistItems")
struct ChecklistItemsTests {

  private func makeClient(_ transport: MockClientTransport) throws -> KaitenClient {
    try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)
  }

  private static let itemJSON = """
    {"created": "2026-01-01T00:00:00.000Z", "updated": "2026-01-01T00:00:00.000Z", "id": 100, "text": "Prepare release notes", "sort_order": 1.5, "checked": false, "checklist_id": 10, "checker_id": null, "user_id": 1, "checked_at": null, "responsible_id": null, "deleted": false, "due_date": null}
    """

  // MARK: - Add

  @Test("add: 200 returns created ChecklistItem")
  func addSuccess() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: Self.itemJSON))
    let item = try await client.createChecklistItem(
      checklistId: 10, text: "Prepare release notes")
    #expect(item.id == 100)
    #expect(item.text == "Prepare release notes")
    #expect(item.checklist_id == 10)
    #expect(item.checked == false)
    #expect(item.checker_id == nil)
  }

  @Test("add: 404 throws notFound")
  func addNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await #expect(throws: KaitenError.self) {
      _ = try await client.createChecklistItem(checklistId: 999, text: "Test")
    }
  }

  @Test("add: 401 throws unauthorized")
  func addUnauthorized() async throws {
    let client = try makeClient(.returning(statusCode: 401))
    await #expect(throws: KaitenError.self) {
      _ = try await client.createChecklistItem(checklistId: 10, text: "Test")
    }
  }

  // MARK: - Update

  @Test("update: 200 returns updated ChecklistItem")
  func updateSuccess() async throws {
    let json = """
      {"created": "2026-01-01T00:00:00.000Z", "updated": "2026-01-02T00:00:00.000Z", "id": 100, "text": "Prepare release notes", "sort_order": 2.5, "checked": true, "checklist_id": 10, "checker_id": 1, "user_id": 1, "checked_at": "2026-01-02T00:00:00.000Z", "responsible_id": 2, "deleted": false, "due_date": "2026-02-01"}
      """
    let client = try makeClient(.returning(statusCode: 200, body: json))
    let item = try await client.updateChecklistItem(
      checklistId: 10, itemId: 100, checked: true)
    #expect(item.id == 100)
    #expect(item.checked == true)
    #expect(item.checker_id == 1)
    #expect(item.responsible_id == 2)
    #expect(item.due_date == "2026-02-01")
  }

  @Test("update: 404 throws notFound")
  func updateNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await #expect(throws: KaitenError.self) {
      _ = try await client.updateChecklistItem(checklistId: 10, itemId: 999, checked: true)
    }
  }

  // MARK: - Remove

  @Test("remove: 200 returns deleted item ID")
  func removeSuccess() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: #"{"id": 100}"#))
    let deletedId = try await client.removeChecklistItem(checklistId: 10, itemId: 100)
    #expect(deletedId == 100)
  }

  @Test("remove: 404 throws notFound")
  func removeNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await #expect(throws: KaitenError.self) {
      _ = try await client.removeChecklistItem(checklistId: 10, itemId: 999)
    }
  }
}
