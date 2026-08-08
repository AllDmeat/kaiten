import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("DetachFile")
struct DetachFileTests {

  /// Fixture from the documented example response of `DELETE /cards/{card_id}/files/{id}`.
  @Test("200 returns deleted ID")
  func success() async throws {
    let json = """
      {"id": 12}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let deletedId = try await client.detachFile(cardId: 3, fileId: 12)
    #expect(deletedId == 12)

    let request = try #require(transport.recordedRequests.first)
    #expect(request.request.method == .delete)
  }

  @Test("404 throws notFound")
  func notFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.detachFile(cardId: 3, fileId: 999)
    }
  }

  @Test("401 throws unauthorized")
  func unauthorized() async throws {
    let transport = MockClientTransport.returning(statusCode: 401)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.detachFile(cardId: 3, fileId: 12)
    }
  }
}
