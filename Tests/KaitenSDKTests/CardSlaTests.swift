import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("Card SLA")
struct CardSlaTests {

  private func makeClient(_ transport: MockClientTransport) throws -> KaitenClient {
    try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)
  }

  /// Live responses on the verification instance carry empty arrays (no SLA rules are
  /// configured there), so the populated item shapes come from the documentation.
  @Test("200 returns measurements with calendars and rule time data")
  func success() async throws {
    let json = """
      {
        "calendars": [{
          "id": "cal-1",
          "timezone": "Europe/Moscow",
          "holidays": [{
            "created": "2024-01-01T00:00:00.000Z",
            "updated": "2024-01-01T00:00:00.000Z",
            "id": "hol-1",
            "calendar_id": "cal-1",
            "day": 1,
            "month": 1,
            "year": null,
            "description": "New Year"
          }],
          "work_days": [{
            "created": "2024-01-01T00:00:00.000Z",
            "updated": "2024-01-01T00:00:00.000Z",
            "id": "wd-1",
            "calendar_id": "cal-1",
            "day": 1,
            "date": null,
            "period_start": 9,
            "period_finish": 18
          }]
        }],
        "rulesTimeData": [{
          "rule_id": "rule-1",
          "card_id": 123,
          "actual_time": 3600,
          "started": true,
          "completed": false,
          "last_calculated_at": "2024-02-01T12:00:00.000Z",
          "is_last_calculated_at_work_time": true
        }]
      }
      """
    let client = try makeClient(.returning(statusCode: 200, body: json))

    let measurements = try await client.getCardSlaMeasurements(cardId: 123)
    #expect(measurements.calendars?.count == 1)
    #expect(measurements.calendars?.first?.id == "cal-1")
    #expect(measurements.calendars?.first?.timezone == "Europe/Moscow")
    #expect(measurements.calendars?.first?.holidays?.first?.year == nil)
    #expect(measurements.calendars?.first?.holidays?.first?.description == "New Year")
    #expect(measurements.calendars?.first?.work_days?.first?.period_finish == 18)
    #expect(measurements.rulesTimeData?.count == 1)
    #expect(measurements.rulesTimeData?.first?.rule_id == "rule-1")
    #expect(measurements.rulesTimeData?.first?.actual_time == 3600)
    #expect(measurements.rulesTimeData?.first?.started == true)
    #expect(measurements.rulesTimeData?.first?.completed == false)
  }

  /// Sanitized live response: a service desk card with no SLA rules answers with both
  /// collections empty.
  @Test("200 with empty collections parses")
  func emptyCollections() async throws {
    let json = """
      {"calendars":[],"rulesTimeData":[]}
      """
    let client = try makeClient(.returning(statusCode: 200, body: json))

    let measurements = try await client.getCardSlaMeasurements(cardId: 123)
    #expect(measurements.calendars?.isEmpty == true)
    #expect(measurements.rulesTimeData?.isEmpty == true)
  }

  /// Confirmed live: non service desk cards and archived cards answer HTTP 400,
  /// which the docs do not list.
  @Test("400 throws unexpectedResponse")
  func badRequest() async throws {
    let client = try makeClient(.returning(statusCode: 400))
    do {
      _ = try await client.getCardSlaMeasurements(cardId: 123)
      Issue.record("expected KaitenError.unexpectedResponse(statusCode: 400), no error thrown")
    } catch let error as KaitenError {
      guard case .unexpectedResponse(let code, _) = error, code == 400 else {
        Issue.record("expected KaitenError.unexpectedResponse(statusCode: 400), got \(error)")
        return
      }
    } catch {
      Issue.record("expected KaitenError, got \(error)")
    }
  }

  @Test("401 throws unauthorized")
  func unauthorized() async throws {
    let client = try makeClient(.returning(statusCode: 401))
    await #expect(throws: KaitenError.self) {
      _ = try await client.getCardSlaMeasurements(cardId: 123)
    }
  }

  @Test("404 throws notFound for the card")
  func notFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    do {
      _ = try await client.getCardSlaMeasurements(cardId: 999)
      Issue.record("expected KaitenError.notFound, no error thrown")
    } catch let error as KaitenError {
      guard case .notFound(let resource, let id) = error, resource == "card", id == 999 else {
        Issue.record("expected KaitenError.notFound(resource: card, id: 999), got \(error)")
        return
      }
    } catch {
      Issue.record("expected KaitenError, got \(error)")
    }
  }
}
