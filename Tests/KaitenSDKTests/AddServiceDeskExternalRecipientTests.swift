import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("AddServiceDeskExternalRecipient")
struct AddServiceDeskExternalRecipientTests {

  @Test("200 returns ServiceDeskExternalRecipient")
  func success() async throws {
    // Based on the documentation example response for POST /cards/{card_id}/sd-external-recipients.
    let json = """
      {"created": "2023-01-23T13:56:24.078Z", "updated": "2023-01-23T13:56:24.078Z", "card_id": 42, "user_id": null, "email": "recipient@example.com", "unsubscribed": false, "updater_id": 7}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let recipient = try await client.addServiceDeskExternalRecipient(
      cardId: 42, email: "recipient@example.com")
    #expect(recipient.card_id == 42)
    #expect(recipient.user_id == nil)
    #expect(recipient.email == "recipient@example.com")
    #expect(recipient.unsubscribed == false)
    #expect(recipient.updater_id == 7)
  }

  @Test("404 throws notFound")
  func notFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.addServiceDeskExternalRecipient(
        cardId: 999, email: "recipient@example.com")
    }
  }

  @Test("401 throws unauthorized")
  func unauthorized() async throws {
    let transport = MockClientTransport.returning(statusCode: 401)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.addServiceDeskExternalRecipient(
        cardId: 1, email: "recipient@example.com")
    }
  }
}
