import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("UpdateFile")
struct UpdateFileTests {

  /// The docs define no response schema for `PATCH /cards/{card_id}/files/{id}`;
  /// the documented example body is an empty object.
  @Test("200 with empty object body succeeds")
  func success() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: "{}")
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    try await client.updateFile(cardId: 3, fileId: 12, cardCover: true)

    let request = try #require(transport.recordedRequests.first)
    #expect(request.request.method == .patch)
  }

  @Test("200 with no body succeeds")
  func successNoBody() async throws {
    let transport = MockClientTransport.returning(statusCode: 200)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    try await client.updateFile(cardId: 3, fileId: 12, cardCover: false)
  }

  @Test("404 throws notFound")
  func notFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      try await client.updateFile(cardId: 3, fileId: 999, cardCover: true)
    }
  }

  @Test("401 throws unauthorized")
  func unauthorized() async throws {
    let transport = MockClientTransport.returning(statusCode: 401)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      try await client.updateFile(cardId: 3, fileId: 12, cardCover: true)
    }
  }
}
