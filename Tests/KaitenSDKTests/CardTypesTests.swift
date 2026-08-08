import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("Card Types")
struct CardTypesTests {

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

  /// Sanitized live response of `GET /card-types/{id}`. `uid`, `author_uid`, `locked` and
  /// `card_properties[].type_uid` are absent from the documentation but present live.
  private static let cardTypeJSON = """
    {
      "created": "2024-01-10T09:00:00.000Z",
      "updated": "2024-02-20T10:30:00.000Z",
      "id": 123,
      "name": "Bug",
      "color": 7,
      "letter": "B",
      "company_id": 55,
      "description_template": "Fill in the reproduction steps",
      "archived": false,
      "properties": {
        "due_date": false,
        "id_101": true,
        "description": false
      },
      "uid": "type-uid-1",
      "author_uid": null,
      "suggest_fields": true,
      "locked": null,
      "card_properties": [
        {
          "type_uid": "type-uid-1",
          "regular_property": "due_date",
          "property_uid": null,
          "sort_order": -10,
          "required": false
        },
        {
          "type_uid": "type-uid-1",
          "regular_property": null,
          "property_uid": "prop-uid-1",
          "sort_order": 1.5,
          "required": true
        }
      ]
    }
    """

  // MARK: - Get

  @Test("200 returns CardType")
  func getSuccess() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: Self.cardTypeJSON))

    let type = try await client.getCardType(id: 123)

    #expect(type.id == 123)
    #expect(type.name == "Bug")
    #expect(type.letter == "B")
    #expect(type.color == 7)
    #expect(type.archived == false)
    #expect(type.suggest_fields == true)
    #expect(type.uid == "type-uid-1")
    #expect(type.author_uid == nil)
    #expect(type.locked == nil)
    #expect(type.card_properties?.count == 2)
    #expect(type.card_properties?[0].regularPropertyKey == .dueDate)
    #expect(type.card_properties?[0].sort_order == -10)
    #expect(type.card_properties?[1].regularPropertyKey == nil)
    #expect(type.card_properties?[1].property_uid == "prop-uid-1")
    #expect(type.card_properties?[1].required == true)
  }

  @Test("undocumented regular property decodes as unknown")
  func getUnknownRegularProperty() async throws {
    let json = """
      {
        "id": 123,
        "card_properties": [
          {"type_uid": "type-uid-1", "regular_property": "portfolio", "sort_order": 1, "required": false}
        ]
      }
      """
    let client = try makeClient(.returning(statusCode: 200, body: json))

    let type = try await client.getCardType(id: 123)
    #expect(type.card_properties?.first?.regularPropertyKey == .unknown("portfolio"))
  }

  @Test("404 throws notFound with cardType resource")
  func getNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    do {
      _ = try await client.getCardType(id: 999)
      Issue.record("expected KaitenError.notFound, no error thrown")
    } catch let error as KaitenError {
      guard case .notFound(let resource, let id) = error, resource == "cardType", id == 999 else {
        Issue.record("expected KaitenError.notFound(resource: cardType, id: 999), got \(error)")
        return
      }
    } catch {
      Issue.record("expected KaitenError, got \(error)")
    }
  }

  @Test("401 throws unauthorized")
  func getUnauthorized() async throws {
    let client = try makeClient(.returning(statusCode: 401))
    await #expect(throws: KaitenError.self) {
      _ = try await client.getCardType(id: 123)
    }
  }

  // MARK: - Create

  @Test("create sends letter, name and color in the body")
  func createSendsBody() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: Self.cardTypeJSON)
    let client = try makeClient(transport)

    let type = try await client.createCardType(
      letter: "B",
      name: "Bug",
      color: 7,
      cardProperties: [.init(regularProperty: .dueDate, required: false)],
      suggestFields: true
    )

    #expect(type.id == 123)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .post)
    #expect(recorded.request.path == "/card-types")

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["letter"] as? String == "B")
    #expect(sent["name"] as? String == "Bug")
    #expect(sent["color"] as? Int == 7)
    #expect(sent["suggest_fields"] as? Bool == true)
    let sentProperties = try #require(sent["card_properties"] as? [[String: Any]])
    #expect(sentProperties.first?["regular_property"] as? String == "due_date")
    #expect(sentProperties.first?["required"] as? Bool == false)
  }

  @Test("400 validation error throws unexpectedResponse")
  func createValidationError() async throws {
    let client = try makeClient(.returning(statusCode: 400))
    await expectUnexpectedResponse(statusCode: 400) {
      _ = try await client.createCardType(letter: "B", name: "Bug", color: 7)
    }
  }

  // MARK: - Update

  @Test("update targets the card type ID")
  func updateSuccess() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: Self.cardTypeJSON)
    let client = try makeClient(transport)

    let type = try await client.updateCardType(id: 123, name: "Bug")

    #expect(type.name == "Bug")

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .patch)
    #expect(recorded.request.path == "/card-types/123")
  }

  @Test("404 throws notFound")
  func updateNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await #expect(throws: KaitenError.self) {
      _ = try await client.updateCardType(id: 999, name: "Renamed")
    }
  }

  // MARK: - Delete

  @Test("delete sends replace_type_id and returns the removed type")
  func deleteSuccess() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: Self.cardTypeJSON)
    let client = try makeClient(transport)

    let type = try await client.deleteCardType(id: 123, replaceTypeId: 456)

    #expect(type.id == 123)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .delete)
    #expect(recorded.request.path == "/card-types/123")

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    let sentReplaceTypeId = try #require(sent["replace_type_id"] as? NSNumber)
    #expect(sentReplaceTypeId.intValue == 456)
  }

  @Test("404 throws notFound")
  func deleteNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await #expect(throws: KaitenError.self) {
      _ = try await client.deleteCardType(id: 999, replaceTypeId: 456)
    }
  }
}
