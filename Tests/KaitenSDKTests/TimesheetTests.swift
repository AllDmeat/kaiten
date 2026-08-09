import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("Timesheet")
struct TimesheetTests {

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

  /// Fixture follows the 200 example in the Kaiten documentation (sanitized). The live 200 body
  /// could not be verified: the endpoint needs timesheet access, which the verification token
  /// does not have (the API answered 403 with an empty body, as documented).
  @Test("200 returns page of TimeLog")
  func listSuccess() async throws {
    let json = """
      [{
        "created": "2026-04-01T10:50:30.191Z",
        "updated": "2026-04-01T10:50:30.191Z",
        "id": 1,
        "card_id": 2,
        "user_id": 3,
        "role_id": -1,
        "author_id": 3,
        "updater_id": null,
        "time_spent": 60,
        "for_date": "2026-04-01",
        "comment": "",
        "card": {
          "id": 2,
          "created": "2026-03-20T09:06:11.715Z",
          "updated": "2026-03-24T12:57:38.090Z",
          "archived": false,
          "title": "Example card",
          "asap": false,
          "due_date": null,
          "sort_order": 1.5,
          "state": 3,
          "condition": 1,
          "size": 8,
          "size_unit": null,
          "size_text": "8",
          "board_id": 4,
          "column_id": 5,
          "lane_id": 6,
          "owner_id": 3,
          "type_id": 1,
          "version": 10,
          "updater_id": 3,
          "completed_at": null,
          "sprint_id": null,
          "external_id": null,
          "comments_total": 0,
          "time_spent_sum": 60,
          "type": {
            "id": 1,
            "name": "Card",
            "color": 1,
            "letter": "C",
            "company_id": null,
            "archived": false,
            "properties": null
          },
          "lane": {
            "id": 6,
            "title": "",
            "sort_order": 1,
            "board_id": 4,
            "condition": 1,
            "external_id": null
          },
          "column": {
            "id": 5,
            "title": "Done",
            "sort_order": 3,
            "col_count": 1,
            "type": 3,
            "board_id": 4,
            "column_id": null,
            "external_id": null,
            "rules": 0
          },
          "owner": {
            "id": 3,
            "full_name": "Example User",
            "email": "user@example.com",
            "username": "example.user",
            "avatar_initials_url": "",
            "initials": "EU",
            "avatar_type": 3,
            "lng": "en",
            "timezone": "Europe/Moscow",
            "theme": "light",
            "created": "2025-07-09T13:34:04.694Z",
            "updated": "2026-03-02T14:22:36.217Z",
            "activated": true,
            "ui_version": 2
          }
        },
        "user": {
          "id": 3,
          "full_name": "Example User",
          "email": "user@example.com",
          "username": "example.user",
          "avatar_initials_url": "",
          "initials": "EU",
          "avatar_type": 3,
          "lng": "en",
          "timezone": "Europe/Moscow",
          "theme": "light",
          "created": "2025-07-09T13:34:04.694Z",
          "updated": "2026-03-02T14:22:36.217Z",
          "activated": true,
          "ui_version": 2
        },
        "role": {
          "created": "2025-03-21T14:00:22.934Z",
          "updated": "2025-03-21T14:00:22.934Z",
          "id": -1,
          "name": "Employee",
          "company_id": null
        }
      }]
      """
    let client = try makeClient(.returning(statusCode: 200, body: json))

    let page = try await client.listTimeLogs(from: "2026-04-01", to: "2026-04-30")
    #expect(page.items.count == 1)
    let timeLog = try #require(page.items.first)
    #expect(timeLog.id == 1)
    #expect(timeLog.card_id == 2)
    #expect(timeLog.user_id == 3)
    #expect(timeLog.role_id == -1)
    #expect(timeLog.author_id == 3)
    #expect(timeLog.updater_id == nil)
    #expect(timeLog.time_spent == 60)
    #expect(timeLog.for_date == "2026-04-01")
    #expect(timeLog.comment == "")
    #expect(timeLog.card?.id == 2)
    #expect(timeLog.card?.title == "Example card")
    #expect(timeLog.card?.owner?.full_name == "Example User")
    #expect(timeLog.user?.id == 3)
    #expect(timeLog.user?.email == "user@example.com")
    #expect(timeLog.role?.id == -1)
    #expect(timeLog.role?.name == "Employee")
    #expect(timeLog.role?.company_id == nil)
  }

  @Test("200 with empty body returns empty page")
  func listEmptyBody() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: ""))
    let page = try await client.listTimeLogs(from: "2026-04-01", to: "2026-04-30")
    #expect(page.items.isEmpty)
    #expect(!page.hasMore)
  }

  @Test("query parameters are sent")
  func listSendsQueryParameters() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: "[]")
    let client = try makeClient(transport)

    _ = try await client.listTimeLogs(
      from: "2026-04-01",
      to: "2026-04-30",
      tagIds: [1, 2],
      userIds: [3],
      groupIds: [4],
      spaceIds: [5],
      boardIds: [6],
      columnIds: [7],
      cardIds: [8],
      visibleColumnIds: [9],
      condition: 1,
      groupBy: 2,
      timePrecision: 2,
      timeUnit: 1,
      withDailyDistribution: 1,
      onlyGeneralSum: 1,
      offset: 50,
      limit: 200
    )

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .get)
    let path = try #require(recorded.request.path)
    #expect(path.hasPrefix("/time-logs?"))
    #expect(path.contains("from=2026-04-01"))
    #expect(path.contains("to=2026-04-30"))
    // The generated client percent-encodes the comma separator.
    #expect(path.contains("tag_ids=1%2C2"))
    #expect(path.contains("user_ids=3"))
    #expect(path.contains("group_ids=4"))
    #expect(path.contains("space_ids=5"))
    #expect(path.contains("board_ids=6"))
    #expect(path.contains("column_ids=7"))
    #expect(path.contains("card_ids=8"))
    #expect(path.contains("visible_column_ids=9"))
    #expect(path.contains("condition=1"))
    #expect(path.contains("group_by=2"))
    #expect(path.contains("time_precision=2"))
    #expect(path.contains("time_unit=1"))
    #expect(path.contains("with_daily_distribution=1"))
    #expect(path.contains("only_general_sum=1"))
    #expect(path.contains("offset=50"))
    #expect(path.contains("limit=200"))
  }

  @Test("limit above 200 throws invalidPaginationRange")
  func listInvalidPagination() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: "[]"))
    await #expect(throws: KaitenError.self) {
      _ = try await client.listTimeLogs(from: "2026-04-01", to: "2026-04-30", limit: 201)
    }
  }

  @Test("400 throws unexpectedResponse")
  func listBadRequest() async throws {
    let client = try makeClient(
      .returning(statusCode: 400, body: #"{"message": "attributes 'from' and 'to' are required"}"#)
    )
    await expectUnexpectedResponse(statusCode: 400) {
      _ = try await client.listTimeLogs(from: "", to: "")
    }
  }

  @Test("401 throws unauthorized")
  func listUnauthorized() async throws {
    let client = try makeClient(.returning(statusCode: 401))
    await #expect(throws: KaitenError.self) {
      _ = try await client.listTimeLogs(from: "2026-04-01", to: "2026-04-30")
    }
  }

  /// The endpoint answers 403 with an empty body when the token's user has no access to the
  /// timesheet (verified live).
  @Test("403 throws unexpectedResponse")
  func listForbidden() async throws {
    let client = try makeClient(.returning(statusCode: 403))
    await expectUnexpectedResponse(statusCode: 403) {
      _ = try await client.listTimeLogs(from: "2026-04-01", to: "2026-04-30")
    }
  }
}
