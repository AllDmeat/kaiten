import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("Custom Property Collective Score Values")
struct CustomPropertyCollectiveScoreValuesTests {

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

  /// Fixture follows the documented GET response: list items stop at `author`, which the
  /// documentation declares as an object without describing its shape.
  @Test("list 200 returns array of CollectiveScoreValue")
  func listSuccess() async throws {
    let json = """
      [{
        "id": 501,
        "custom_property_id": 42,
        "value": "8",
        "card_id": 123,
        "author_id": 11,
        "author": {
          "id": 11,
          "full_name": "Test User"
        }
      }]
      """
    let client = try makeClient(.returning(statusCode: 200, body: json))

    let values = try await client.listCollectiveScoreValues(cardId: 123, propertyId: 42)
    #expect(values.count == 1)
    #expect(values[0].id == 501)
    #expect(values[0].custom_property_id == 42)
    #expect(values[0].value == "8")
    #expect(values[0].card_id == 123)
    #expect(values[0].author_id == 11)
    #expect(values[0].author != nil)
  }

  /// Properties without score values return `[]` (confirmed live).
  @Test("list 200 empty array returns empty array")
  func listEmptyList() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: "[]"))
    let values = try await client.listCollectiveScoreValues(cardId: 123, propertyId: 42)
    #expect(values.isEmpty)
  }

  @Test("list 200 with empty body returns empty array")
  func listEmptyBody() async throws {
    let client = try makeClient(.returning(statusCode: 200))
    let values = try await client.listCollectiveScoreValues(cardId: 123, propertyId: 42)
    #expect(values.isEmpty)
  }

  @Test("list targets the collective-score-values path")
  func listSendsRequest() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: "[]")
    let client = try makeClient(transport)

    _ = try await client.listCollectiveScoreValues(cardId: 123, propertyId: 42)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .get)
    #expect(recorded.request.path == "/cards/123/custom-properties/42/collective-score-values")
  }

  @Test("list 404 throws notFound")
  func listNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await #expect(throws: KaitenError.self) {
      _ = try await client.listCollectiveScoreValues(cardId: 999, propertyId: 42)
    }
  }

  @Test("list 401 throws unauthorized")
  func listUnauthorized() async throws {
    let client = try makeClient(.returning(statusCode: 401))
    await #expect(throws: KaitenError.self) {
      _ = try await client.listCollectiveScoreValues(cardId: 123, propertyId: 42)
    }
  }

  // MARK: - Create

  /// Fixture follows the documented POST response, which carries `created`, `updated`,
  /// `updater_id` and `company_id` and no nested `author` object.
  @Test("create sends body and parses 200")
  func createSuccess() async throws {
    let json = """
      {
        "updated": "2024-05-21T10:15:00.000Z",
        "created": "2024-05-21T10:15:00.000Z",
        "id": 502,
        "value": "13",
        "custom_property_id": 42,
        "author_id": 11,
        "updater_id": 11,
        "company_id": 77,
        "card_id": 123
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let scoreValue = try await client.createCollectiveScoreValue(
      cardId: 123, propertyId: 42, value: "13")

    #expect(scoreValue.id == 502)
    #expect(scoreValue.value == "13")
    #expect(scoreValue.custom_property_id == 42)
    #expect(scoreValue.updater_id == 11)
    #expect(scoreValue.company_id == 77)
    #expect(scoreValue.author == nil)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .post)
    #expect(recorded.request.path == "/cards/123/custom-properties/42/collective-score-values")

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["value"] as? String == "13")
  }

  @Test("create 400 throws unexpectedResponse")
  func createValidationError() async throws {
    let client = try makeClient(.returning(statusCode: 400))
    await expectUnexpectedResponse(statusCode: 400) {
      _ = try await client.createCollectiveScoreValue(cardId: 123, propertyId: 42, value: "")
    }
  }

  @Test("create 402 unsupported tariff throws unexpectedResponse")
  func createPaymentRequired() async throws {
    let client = try makeClient(.returning(statusCode: 402))
    await expectUnexpectedResponse(statusCode: 402) {
      _ = try await client.createCollectiveScoreValue(cardId: 123, propertyId: 42, value: "5")
    }
  }

  // MARK: - Update

  @Test("update targets the score value and parses 200")
  func updateSuccess() async throws {
    let json = """
      {
        "updated": "2024-05-22T09:00:00.000Z",
        "created": "2024-05-21T10:15:00.000Z",
        "id": 502,
        "value": "21",
        "custom_property_id": 42,
        "author_id": 11,
        "updater_id": 12,
        "company_id": 77,
        "card_id": 123
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let scoreValue = try await client.updateCollectiveScoreValue(
      cardId: 123, propertyId: 42, scoreValueId: 502, value: "21")

    #expect(scoreValue.id == 502)
    #expect(scoreValue.value == "21")
    #expect(scoreValue.updater_id == 12)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .patch)
    #expect(recorded.request.path == "/cards/123/custom-properties/42/collective-score-values/502")

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["value"] as? String == "21")
  }

  /// `.some(nil)` must reach the server as an explicit JSON `null` — the documented
  /// way to clear a score value — not as an absent field.
  @Test("update .some(nil) sends explicit JSON null")
  func updateSendsExplicitNull() async throws {
    let json = """
      {"id": 502, "value": "21", "custom_property_id": 42, "card_id": 123}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    _ = try await client.updateCollectiveScoreValue(
      cardId: 123, propertyId: 42, scoreValueId: 502, value: .some(nil))

    let recorded = try #require(transport.recordedRequests.first)
    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["value"] is NSNull)
  }

  @Test("update nil omits the value field")
  func updateOmitsAbsentValue() async throws {
    let json = """
      {"id": 502, "value": "21", "custom_property_id": 42, "card_id": 123}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    _ = try await client.updateCollectiveScoreValue(cardId: 123, propertyId: 42, scoreValueId: 502)

    let recorded = try #require(transport.recordedRequests.first)
    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["value"] == nil)
  }

  @Test("update 404 throws notFound")
  func updateNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    do {
      _ = try await client.updateCollectiveScoreValue(
        cardId: 123, propertyId: 42, scoreValueId: 999, value: "5")
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

  @Test("update 403 throws unexpectedResponse")
  func updateForbidden() async throws {
    let client = try makeClient(.returning(statusCode: 403))
    await expectUnexpectedResponse(statusCode: 403) {
      _ = try await client.updateCollectiveScoreValue(
        cardId: 123, propertyId: 42, scoreValueId: 502, value: "5")
    }
  }
}
