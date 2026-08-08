import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("RemoveServiceDeskExternalRecipient")
struct RemoveServiceDeskExternalRecipientTests {

  @Test("200 returns ServiceDeskExternalRecipient")
  func success() async throws {
    // Based on the documentation example response for
    // DELETE /cards/{card_id}/sd-external-recipients/{email}.
    let json = """
      {"created": "2023-01-23T16:16:08.643Z", "updated": "2023-01-23T16:16:08.643Z", "card_id": 42, "user_id": null, "email": "recipient@example.com", "unsubscribed": false, "updater_id": 7, "company_id": 3}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let recipient = try await client.removeServiceDeskExternalRecipient(
      cardId: 42, email: "recipient@example.com")
    #expect(recipient.card_id == 42)
    #expect(recipient.user_id == nil)
    #expect(recipient.email == "recipient@example.com")
    #expect(recipient.unsubscribed == false)
    #expect(recipient.updater_id == 7)
    #expect(recipient.company_id == 3)
  }

  @Test("404 throws notFound")
  func notFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.removeServiceDeskExternalRecipient(
        cardId: 999, email: "recipient@example.com")
    }
  }

  @Test("401 throws unauthorized")
  func unauthorized() async throws {
    let transport = MockClientTransport.returning(statusCode: 401)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.removeServiceDeskExternalRecipient(
        cardId: 1, email: "recipient@example.com")
    }
  }
}
