import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("Card Blocker Categories")
struct CardBlockerCategoriesTests {

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

  /// Fixture mirrors a sanitized live response. The documentation lists only `uid`, `name` and
  /// `color`; the live API also returns `company_uid`, `created` and `count`.
  @Test("200 returns array of BlockerCategory")
  func listSuccess() async throws {
    let json = """
      [
        {
          "uid": "cat-uid-1",
          "name": "Waiting for info",
          "company_uid": "company-uid-1",
          "color": 16,
          "created": "2026-01-01T10:00:00.000Z",
          "count": 3
        },
        {
          "uid": "cat-uid-2",
          "name": "Waiting for release",
          "company_uid": "company-uid-1",
          "color": 16,
          "created": "2026-02-01T12:30:00.000Z",
          "count": 1
        }
      ]
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let categories = try await client.listBlockerCategories()
    #expect(categories.count == 2)
    #expect(categories[0].uid == "cat-uid-1")
    #expect(categories[0].name == "Waiting for info")
    #expect(categories[0].color == 16)
    #expect(categories[0].company_uid == "company-uid-1")
    #expect(categories[0].created == "2026-01-01T10:00:00.000Z")
    #expect(categories[0].count == 3)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .get)
    #expect(recorded.request.path == "/categories")
  }

  @Test("200 with empty body returns empty array")
  func listEmptyBody() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: ""))
    let categories = try await client.listBlockerCategories()
    #expect(categories.isEmpty)
  }

  @Test("401 throws unauthorized")
  func listUnauthorized() async throws {
    let client = try makeClient(.returning(statusCode: 401))
    await #expect(throws: KaitenError.self) {
      _ = try await client.listBlockerCategories()
    }
  }

  @Test("403 throws unexpectedResponse")
  func listForbidden() async throws {
    let client = try makeClient(.returning(statusCode: 403))
    await expectUnexpectedResponse(statusCode: 403) {
      _ = try await client.listBlockerCategories()
    }
  }

  // MARK: - Add

  /// Fixture built from the documented response attributes (`uid`, `name`, `color`) — mutating
  /// endpoints are not exercised against the live API.
  @Test("add sends name in the body")
  func addSendsBody() async throws {
    let json = """
      {"uid": "cat-uid-1", "name": "Waiting for info", "color": 16}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let category = try await client.addBlockerCategory(blockerId: 501, name: "Waiting for info")

    #expect(category.uid == "cat-uid-1")
    #expect(category.name == "Waiting for info")
    #expect(category.color == 16)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .post)
    #expect(recorded.request.path == "/blockers/501/categories")

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["name"] as? String == "Waiting for info")
  }

  @Test("add 404 throws notFound")
  func addNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await #expect(throws: KaitenError.self) {
      _ = try await client.addBlockerCategory(blockerId: 999, name: "Waiting for info")
    }
  }

  // MARK: - Remove

  /// Fixture built from the documented response attributes (`uid`) — mutating endpoints are not
  /// exercised against the live API.
  @Test("remove targets the category UID and returns the removed UID")
  func removeSuccess() async throws {
    let json = """
      {"uid": "cat-uid-1"}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let removed = try await client.removeBlockerCategory(blockerId: 501, categoryUid: "cat-uid-1")

    #expect(removed.uid == "cat-uid-1")

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .delete)
    #expect(recorded.request.path == "/blockers/501/categories/cat-uid-1")
  }

  @Test("remove 403 throws unexpectedResponse")
  func removeForbidden() async throws {
    let client = try makeClient(.returning(statusCode: 403))
    await expectUnexpectedResponse(statusCode: 403) {
      _ = try await client.removeBlockerCategory(blockerId: 501, categoryUid: "cat-uid-1")
    }
  }
}
