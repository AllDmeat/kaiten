import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("Card Time Logs")
struct CardTimeLogsTests {

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

  // MARK: - Get

  /// Fixture follows the documented GET response: the list items carry nested
  /// `role`, `user` and `author` objects, and `comment` is nullable.
  @Test("get 200 returns array of CardTimeLog")
  func getSuccess() async throws {
    let json = """
      [{
        "updated": "2024-05-21T10:15:00.000Z",
        "created": "2024-05-20T10:00:00.000Z",
        "id": 501,
        "card_id": 123,
        "user_id": 11,
        "role_id": -1,
        "author_id": 12,
        "updater_id": 12,
        "time_spent": 90,
        "for_date": "2024-05-20",
        "comment": null,
        "role": {
          "created": "2024-01-01T00:00:00.000Z",
          "updated": "2024-01-01T00:00:00.000Z",
          "id": -1,
          "name": "Employee",
          "company_id": null
        },
        "user": {
          "id": 11,
          "full_name": "Test User",
          "email": "user@example.com",
          "username": "testuser",
          "activated": true,
          "initials": "TU",
          "avatar_type": 2,
          "avatar_initials_url": "https://test.kaiten.ru/avatar/tu",
          "avatar_uploaded_url": null,
          "lng": "en",
          "timezone": "UTC",
          "theme": "auto",
          "ui_version": 2,
          "created": "2024-01-01T00:00:00.000Z",
          "updated": "2024-01-01T00:00:00.000Z"
        },
        "author": {
          "id": 12,
          "full_name": "Other User",
          "email": "other@example.com",
          "username": "otheruser",
          "activated": true,
          "initials": "OU",
          "avatar_type": 2,
          "avatar_initials_url": "https://test.kaiten.ru/avatar/ou",
          "avatar_uploaded_url": null
        }
      }]
      """
    let client = try makeClient(.returning(statusCode: 200, body: json))

    let timeLogs = try await client.getCardTimeLogs(cardId: 123)
    #expect(timeLogs.count == 1)
    #expect(timeLogs[0].id == 501)
    #expect(timeLogs[0].card_id == 123)
    #expect(timeLogs[0].role_id == -1)
    #expect(timeLogs[0].time_spent == 90)
    #expect(timeLogs[0].for_date == "2024-05-20")
    #expect(timeLogs[0].comment == nil)
    #expect(timeLogs[0].role?.name == "Employee")
    #expect(timeLogs[0].role?.company_id == nil)
    #expect(timeLogs[0].user?.id == 11)
    #expect(timeLogs[0].author?.id == 12)
  }

  /// Cards without time logs return `[]` (confirmed live).
  @Test("get 200 empty array returns empty array")
  func getEmptyList() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: "[]"))
    let timeLogs = try await client.getCardTimeLogs(cardId: 123)
    #expect(timeLogs.isEmpty)
  }

  @Test("get 200 with empty body returns empty array")
  func getEmptyBody() async throws {
    let client = try makeClient(.returning(statusCode: 200))
    let timeLogs = try await client.getCardTimeLogs(cardId: 123)
    #expect(timeLogs.isEmpty)
  }

  @Test("get sends for_date and personal query parameters")
  func getSendsQuery() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: "[]")
    let client = try makeClient(transport)

    _ = try await client.getCardTimeLogs(cardId: 123, forDate: "2024-05-20", personal: true)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .get)
    let path = try #require(recorded.request.path)
    #expect(path.hasPrefix("/cards/123/time-logs?"))
    #expect(path.contains("for_date=2024-05-20"))
    #expect(path.contains("personal=true"))
  }

  @Test("get 404 throws notFound")
  func getNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await #expect(throws: KaitenError.self) {
      _ = try await client.getCardTimeLogs(cardId: 999)
    }
  }

  @Test("get 401 throws unauthorized")
  func getUnauthorized() async throws {
    let client = try makeClient(.returning(statusCode: 401))
    await #expect(throws: KaitenError.self) {
      _ = try await client.getCardTimeLogs(cardId: 123)
    }
  }

  // MARK: - Create

  /// Fixture follows the documented POST response, which stops at `comment` and
  /// carries no nested `role`, `user` or `author` objects.
  @Test("create sends body and parses 200")
  func createSuccess() async throws {
    let json = """
      {
        "updated": "2024-05-21T10:15:00.000Z",
        "created": "2024-05-21T10:15:00.000Z",
        "id": 502,
        "card_id": 123,
        "user_id": 11,
        "role_id": -1,
        "author_id": 11,
        "updater_id": 11,
        "time_spent": 30,
        "for_date": "2024-05-21",
        "comment": "Code review"
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let timeLog = try await client.createCardTimeLog(
      cardId: 123, roleId: -1, timeSpent: 30, forDate: "2024-05-21", comment: "Code review")

    #expect(timeLog.id == 502)
    #expect(timeLog.time_spent == 30)
    #expect(timeLog.comment == "Code review")
    #expect(timeLog.role == nil)
    #expect(timeLog.user == nil)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .post)
    #expect(recorded.request.path == "/cards/123/time-logs")

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["role_id"] as? Int == -1)
    #expect(sent["time_spent"] as? Int == 30)
    #expect(sent["for_date"] as? String == "2024-05-21")
    #expect(sent["comment"] as? String == "Code review")
  }

  @Test("create 400 throws unexpectedResponse")
  func createValidationError() async throws {
    let client = try makeClient(.returning(statusCode: 400))
    await expectUnexpectedResponse(statusCode: 400) {
      _ = try await client.createCardTimeLog(
        cardId: 123, roleId: -1, timeSpent: 0, forDate: "2024-05-21")
    }
  }

  @Test("create 402 unsupported tariff throws unexpectedResponse")
  func createPaymentRequired() async throws {
    let client = try makeClient(.returning(statusCode: 402))
    await expectUnexpectedResponse(statusCode: 402) {
      _ = try await client.createCardTimeLog(
        cardId: 123, roleId: -1, timeSpent: 30, forDate: "2024-05-21")
    }
  }

  // MARK: - Update

  @Test("update targets the time log and parses 200")
  func updateSuccess() async throws {
    let json = """
      {
        "updated": "2024-05-22T09:00:00.000Z",
        "created": "2024-05-21T10:15:00.000Z",
        "id": 502,
        "card_id": 123,
        "user_id": 11,
        "role_id": -1,
        "author_id": 11,
        "updater_id": 12,
        "time_spent": 45,
        "for_date": "2024-05-21",
        "comment": null
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let timeLog = try await client.updateCardTimeLog(cardId: 123, timeLogId: 502, timeSpent: 45)

    #expect(timeLog.id == 502)
    #expect(timeLog.time_spent == 45)
    #expect(timeLog.comment == nil)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .patch)
    #expect(recorded.request.path == "/cards/123/time-logs/502")

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["time_spent"] as? Int == 45)
    #expect(sent["role_id"] == nil)
  }

  @Test("update 404 throws notFound")
  func updateNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    do {
      _ = try await client.updateCardTimeLog(cardId: 123, timeLogId: 999, timeSpent: 45)
      Issue.record("expected KaitenError.notFound, no error thrown")
    } catch let error as KaitenError {
      guard case .notFound = error else {
        Issue.record("expected KaitenError.notFound, got \(error)")
        return
      }
    } catch {
      Issue.record("expected KaitenError, got \(error)")
    }
  }

  // MARK: - Delete

  @Test("delete returns the deleted time log id")
  func deleteSuccess() async throws {
    let json = """
      {"id": 502}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let deletedId = try await client.deleteCardTimeLog(cardId: 123, timeLogId: 502)

    #expect(deletedId == 502)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .delete)
    #expect(recorded.request.path == "/cards/123/time-logs/502")
  }

  @Test("delete 403 throws unexpectedResponse")
  func deleteForbidden() async throws {
    let client = try makeClient(.returning(statusCode: 403))
    await expectUnexpectedResponse(statusCode: 403) {
      _ = try await client.deleteCardTimeLog(cardId: 123, timeLogId: 502)
    }
  }
}
