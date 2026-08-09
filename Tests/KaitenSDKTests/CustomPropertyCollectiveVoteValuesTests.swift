import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("CustomPropertyCollectiveVoteValues")
struct CustomPropertyCollectiveVoteValuesTests {

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

  // Fixture follows the documentation example: the live GET returned an empty
  // array on every accessible card, so the item schema could not be observed.
  @Test("list 200 returns array of CollectiveVoteValue")
  func listSuccess() async throws {
    let json = """
      [
        {
          "id": 1,
          "custom_property_id": 15,
          "number_vote": 1,
          "emoji_vote": null,
          "card_id": 214,
          "author_id": 1,
          "author": {
            "id": 1,
            "full_name": "Johnny Doe",
            "email": "user@example.com",
            "username": "jdoe",
            "avatar_initials_url": "data:image/png;base64,AAAA",
            "avatar_uploaded_url": null,
            "initials": "JD",
            "avatar_type": 2,
            "lng": "en",
            "timezone": "UTC",
            "theme": "auto",
            "created": "2022-10-21T11:37:46.946Z",
            "updated": "2022-10-21T11:37:46.946Z",
            "activated": true,
            "ui_version": 2
          }
        }
      ]
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let values = try await client.listCollectiveVoteValues(cardId: 214, propertyId: 15)
    #expect(values.count == 1)
    #expect(values[0].id == 1)
    #expect(values[0].custom_property_id == 15)
    #expect(values[0].number_vote == 1)
    #expect(values[0].emoji_vote == nil)
    #expect(values[0].author?.full_name == "Johnny Doe")

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .get)
    #expect(recorded.request.path == "/cards/214/custom-properties/15/collective-vote-values")
  }

  @Test("list 200 with empty array returns empty")
  func listEmpty() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: "[]"))
    let values = try await client.listCollectiveVoteValues(cardId: 214, propertyId: 15)
    #expect(values.isEmpty)
  }

  @Test("list 404 throws notFound")
  func listNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await #expect(throws: KaitenError.self) {
      _ = try await client.listCollectiveVoteValues(cardId: 999, propertyId: 15)
    }
  }

  // MARK: - Create

  // Fixture follows the documentation example (mutating endpoint — never sent live).
  @Test("create 200 returns created value")
  func createSuccess() async throws {
    let json = """
      {
        "created": "2022-03-06T15:43:18.051Z",
        "updated": "2022-03-06T15:43:18.051Z",
        "id": 1,
        "number_vote": null,
        "emoji_vote": "👍",
        "custom_property_id": 15,
        "author_id": 1,
        "company_id": 1,
        "card_id": 214
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let value = try await client.createCollectiveVoteValue(
      cardId: 214, propertyId: 15, emojiVote: "👍")
    #expect(value.id == 1)
    #expect(value.emoji_vote == "👍")
    #expect(value.number_vote == nil)
    #expect(value.company_id == 1)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .post)
    #expect(recorded.request.path == "/cards/214/custom-properties/15/collective-vote-values")

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["emoji_vote"] as? String == "👍")
    #expect(sent["number_vote"] == nil)
  }

  @Test("create 400 throws unexpectedResponse")
  func createValidationError() async throws {
    let client = try makeClient(.returning(statusCode: 400))
    await expectUnexpectedResponse(statusCode: 400) {
      _ = try await client.createCollectiveVoteValue(cardId: 214, propertyId: 15, numberVote: 5)
    }
  }

  @Test("create 404 throws notFound")
  func createNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await #expect(throws: KaitenError.self) {
      _ = try await client.createCollectiveVoteValue(cardId: 999, propertyId: 15, numberVote: 5)
    }
  }

  // MARK: - Update

  // Fixture follows the documentation example (mutating endpoint — never sent live).
  @Test("update 200 returns updated value")
  func updateSuccess() async throws {
    let json = """
      {
        "created": "2022-03-06T15:43:18.051Z",
        "updated": "2022-03-06T15:43:18.051Z",
        "id": 1,
        "number_vote": 4,
        "emoji_vote": null,
        "custom_property_id": 15,
        "author_id": 1,
        "company_id": 1,
        "card_id": 214
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let value = try await client.updateCollectiveVoteValue(
      cardId: 214, propertyId: 15, voteValueId: 1, numberVote: 4)
    #expect(value.number_vote == 4)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .patch)
    #expect(recorded.request.path == "/cards/214/custom-properties/15/collective-vote-values/1")

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["number_vote"] as? Double == 4)
  }

  @Test("update sends explicit null to clear the vote")
  func updateClearsVote() async throws {
    let json = """
      {"id": 1, "number_vote": null, "emoji_vote": null, "custom_property_id": 15, "author_id": 1, "company_id": 1, "card_id": 214}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    _ = try await client.updateCollectiveVoteValue(
      cardId: 214, propertyId: 15, voteValueId: 1, numberVote: .some(nil))

    let recorded = try #require(transport.recordedRequests.first)
    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent.keys.contains("number_vote"))
    #expect(sent["number_vote"] is NSNull)
  }

  @Test("update 404 throws notFound")
  func updateNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await #expect(throws: KaitenError.self) {
      _ = try await client.updateCollectiveVoteValue(
        cardId: 214, propertyId: 15, voteValueId: 999, numberVote: 4)
    }
  }

  // MARK: - Delete

  // Fixture follows the documentation example (mutating endpoint — never sent live).
  @Test("delete 200 returns removed value")
  func deleteSuccess() async throws {
    let json = """
      {
        "id": 2,
        "custom_property_id": 16,
        "number_vote": null,
        "emoji_vote": "😄",
        "card_id": 214,
        "author_id": 1
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let value = try await client.deleteCollectiveVoteValue(
      cardId: 214, propertyId: 16, voteValueId: 2, emojiVote: "😄")
    #expect(value.id == 2)
    #expect(value.emoji_vote == "😄")

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .delete)
    #expect(recorded.request.path == "/cards/214/custom-properties/16/collective-vote-values/2")

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["emoji_vote"] as? String == "😄")
  }

  @Test("delete without emoji sends no body")
  func deleteWithoutBody() async throws {
    let json = """
      {"id": 2, "custom_property_id": 16, "number_vote": 3, "emoji_vote": null, "card_id": 214, "author_id": 1}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    _ = try await client.deleteCollectiveVoteValue(cardId: 214, propertyId: 16, voteValueId: 2)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.body == nil)
  }

  @Test("delete 404 throws notFound")
  func deleteNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await #expect(throws: KaitenError.self) {
      _ = try await client.deleteCollectiveVoteValue(cardId: 214, propertyId: 16, voteValueId: 999)
    }
  }
}
