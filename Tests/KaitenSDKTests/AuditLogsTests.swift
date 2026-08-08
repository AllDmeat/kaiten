import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("AuditLogs")
struct AuditLogsTests {

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

  /// Fixture matches the response example in the Kaiten documentation. The live 200 body could
  /// not be verified: the endpoint needs audit-log administrative access, which the verification
  /// token does not have (the API answered 403 with an empty body, as documented).
  @Test("200 returns page of AuditLogEvent")
  func listSuccess() async throws {
    let json = """
      [{
        "id": "8f977f36-0f13-4b5f-91ab-0df9d15c7ed8",
        "app_name": "app_name",
        "company_uid": "b0979645-f543-4623-9834-b548a98821da",
        "author_id": 123,
        "author_uid": "27ca9e9f-d4fc-47dd-9d4b-35c7b6e3d105",
        "author_username": "admin@example.com",
        "author_remote_address": "192.0.2.10",
        "author": {
          "id": 123,
          "uid": "27ca9e9f-d4fc-47dd-9d4b-35c7b6e3d105",
          "username": "admin@example.com",
          "full_name": "Admin User"
        },
        "category": "auth",
        "action": "sign_in_fail",
        "message": "Failed sign-in attempt",
        "details": {"reason": "wrong_password"},
        "created": "2026-04-01T12:00:00.000Z"
      }]
      """
    let client = try makeClient(.returning(statusCode: 200, body: json))

    let page = try await client.listAuditLogs()
    #expect(page.items.count == 1)
    let event = try #require(page.items.first)
    #expect(event.id == "8f977f36-0f13-4b5f-91ab-0df9d15c7ed8")
    #expect(event.auditLogCategory == .auth)
    #expect(event.auditLogAction == .signInFail)
    #expect(event.author?.id == 123)
    #expect(event.author?.full_name == "Admin User")
    #expect(event.author_remote_address == "192.0.2.10")
    #expect(event.message == "Failed sign-in attempt")
    #expect(event.created == "2026-04-01T12:00:00.000Z")
  }

  @Test("200 with empty body returns empty page")
  func listEmptyBody() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: ""))
    let page = try await client.listAuditLogs()
    #expect(page.items.isEmpty)
    #expect(!page.hasMore)
  }

  /// Nullable fields come back as explicit JSON null for events created by the system rather
  /// than a user.
  @Test("null author fields decode to nil")
  func listNullAuthor() async throws {
    let json = """
      [{
        "id": "evt-1",
        "app_name": null,
        "company_uid": null,
        "author_id": null,
        "author_uid": null,
        "author_username": null,
        "author_remote_address": null,
        "author": null,
        "category": "app",
        "action": "start",
        "message": "Application started",
        "details": null,
        "created": "2026-04-01T00:00:00.000Z"
      }]
      """
    let client = try makeClient(.returning(statusCode: 200, body: json))

    let page = try await client.listAuditLogs()
    let event = try #require(page.items.first)
    #expect(event.author == nil)
    #expect(event.author_id == nil)
    #expect(event.details == nil)
    #expect(event.auditLogCategory == .app)
    #expect(event.auditLogAction == .start)
  }

  /// Kaiten returns discriminator values its documentation does not list. A closed enum would
  /// fail the whole response, so undocumented values must survive as `.unknown`.
  @Test("undocumented category and action decode as unknown")
  func listUndocumentedDiscriminators() async throws {
    let json = """
      [{
        "id": "evt-1",
        "category": "some_new_category",
        "action": "some_new_action",
        "message": "msg",
        "created": "2026-04-01T00:00:00.000Z"
      }]
      """
    let client = try makeClient(.returning(statusCode: 200, body: json))

    let page = try await client.listAuditLogs()
    let event = try #require(page.items.first)
    #expect(event.auditLogCategory == .unknown("some_new_category"))
    #expect(event.auditLogAction == .unknown("some_new_action"))
  }

  @Test("query parameters are sent")
  func listSendsQueryParameters() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: "[]")
    let client = try makeClient(transport)

    _ = try await client.listAuditLogs(
      authorId: 123,
      authorUid: "author-uid-1",
      categories: [.auth, .userManagement],
      actions: [.signInFail, .changePermissions],
      id: "evt-1",
      offset: 50,
      limit: 200
    )

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .get)
    let path = try #require(recorded.request.path)
    #expect(path.hasPrefix("/audit-logs?"))
    #expect(path.contains("author_id=123"))
    #expect(path.contains("author_uid=author-uid-1"))
    // The generated client percent-encodes the comma separator.
    #expect(path.contains("categories=auth%2Cuser_management"))
    #expect(path.contains("actions=sign_in_fail%2Cchange_permissions"))
    #expect(path.contains("id=evt-1"))
    #expect(path.contains("offset=50"))
    #expect(path.contains("limit=200"))
  }

  @Test("limit above 500 throws invalidPaginationRange")
  func listInvalidPagination() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: "[]"))
    await #expect(throws: KaitenError.self) {
      _ = try await client.listAuditLogs(limit: 501)
    }
  }

  @Test("401 throws unauthorized")
  func listUnauthorized() async throws {
    let client = try makeClient(.returning(statusCode: 401))
    await #expect(throws: KaitenError.self) {
      _ = try await client.listAuditLogs()
    }
  }

  /// The endpoint answers 403 with an empty body when the token's user has no access to the
  /// audit log administrative section (verified live).
  @Test("403 throws unexpectedResponse")
  func listForbidden() async throws {
    let client = try makeClient(.returning(statusCode: 403))
    await expectUnexpectedResponse(statusCode: 403) {
      _ = try await client.listAuditLogs()
    }
  }
}
