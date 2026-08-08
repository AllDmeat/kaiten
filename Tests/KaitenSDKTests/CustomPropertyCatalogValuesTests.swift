import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("CustomPropertyCatalogValues")
struct CustomPropertyCatalogValuesTests {

  // Sanitized live response: field names, types and nullability match the real API.
  static let catalogValueJSON = """
    {
      "created": "2023-05-25T16:43:49.086Z",
      "updated": "2023-05-25T16:43:49.086Z",
      "id": 11,
      "custom_property_id": 100,
      "value": {"aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee": "Backend"},
      "name": "Backend",
      "author_id": 42,
      "updater_id": null,
      "deleted": false,
      "uid": "00000000-0000-4000-8000-000000000001",
      "condition": "active",
      "fts_version": "123456"
    }
    """

  @Test("listCustomPropertyCatalogValues 200 returns array")
  func listSuccess() async throws {
    let json = """
      [
        \(Self.catalogValueJSON),
        {
          "created": "2023-10-19T14:27:03.384Z",
          "updated": "2023-10-19T14:27:03.384Z",
          "id": 12,
          "custom_property_id": 100,
          "value": {"aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee": "Frontend"},
          "name": "Frontend",
          "author_id": 42,
          "updater_id": null,
          "deleted": false,
          "uid": "00000000-0000-4000-8000-000000000002",
          "condition": "active",
          "fts_version": "123457"
        }
      ]
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let page = try await client.listCustomPropertyCatalogValues(propertyId: 100)
    #expect(page.items.count == 2)
    #expect(page.items[0].id == 11)
    #expect(page.items[0].name == "Backend")
    #expect(page.items[0].updater_id == nil)
    #expect(page.items[0].deleted == false)
    #expect(page.items[0].uid == "00000000-0000-4000-8000-000000000001")
    #expect(page.items[0].fts_version == "123456")
    #expect(page.items[0].catalogValueCondition == .active)
    #expect(page.items[1].name == "Frontend")
    #expect(page.offset == 0)
    #expect(page.limit == 100)
  }

  @Test("listCustomPropertyCatalogValues sends query parameters")
  func listQueryParameters() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: "[]")
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let page = try await client.listCustomPropertyCatalogValues(
      propertyId: 100, query: "Backend", conditions: .inactive, offset: 5, limit: 10)
    #expect(page.items.isEmpty)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .get)
    let path = try #require(recorded.request.path)
    #expect(path.hasPrefix("/company/custom-properties/100/catalog-values?"))
    #expect(path.contains("query=Backend"))
    #expect(path.contains("conditions=inactive"))
    #expect(path.contains("limit=10"))
    #expect(path.contains("offset=5"))
  }

  @Test("listCustomPropertyCatalogValues 404 throws notFound")
  func listNotFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.listCustomPropertyCatalogValues(propertyId: 999)
    }
  }

  @Test("getCustomPropertyCatalogValue 200 returns single")
  func getSuccess() async throws {
    let transport = MockClientTransport.returning(
      statusCode: 200, body: Self.catalogValueJSON)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let value = try await client.getCustomPropertyCatalogValue(propertyId: 100, id: 11)
    #expect(value.id == 11)
    #expect(value.custom_property_id == 100)
    #expect(value.name == "Backend")
    #expect(value.updater_id == nil)
    #expect(value.catalogValueCondition == .active)
  }

  @Test("getCustomPropertyCatalogValue 404 throws notFound")
  func getNotFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.getCustomPropertyCatalogValue(propertyId: 100, id: 999)
    }
  }

  @Test("createCustomPropertyCatalogValue 200 returns created value")
  func createSuccess() async throws {
    let transport = MockClientTransport.returning(
      statusCode: 200, body: Self.catalogValueJSON)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let value = try await client.createCustomPropertyCatalogValue(
      propertyId: 100,
      value: .init(
        additionalProperties: try .init(unvalidatedValue: [
          "aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee": "Backend"
        ]))
    )
    #expect(value.id == 11)
    #expect(value.custom_property_id == 100)
    #expect(value.name == "Backend")
  }

  @Test("createCustomPropertyCatalogValue 404 throws notFound")
  func createNotFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.createCustomPropertyCatalogValue(propertyId: 999, value: .init())
    }
  }

  @Test("updateCustomPropertyCatalogValue 200 returns updated value")
  func updateSuccess() async throws {
    let json = """
      {
        "created": "2023-05-25T16:43:49.086Z",
        "updated": "2023-06-01T10:00:00.000Z",
        "id": 11,
        "custom_property_id": 100,
        "value": {"aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee": "Updated value"},
        "name": "Updated value",
        "author_id": 42,
        "updater_id": 43,
        "deleted": false,
        "uid": "00000000-0000-4000-8000-000000000001",
        "condition": "inactive",
        "fts_version": "123458"
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let value = try await client.updateCustomPropertyCatalogValue(
      propertyId: 100,
      id: 11,
      condition: .inactive,
      value: .init(
        additionalProperties: try .init(unvalidatedValue: [
          "aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee": "Updated value"
        ]))
    )
    #expect(value.id == 11)
    #expect(value.name == "Updated value")
    #expect(value.updater_id == 43)
    #expect(value.catalogValueCondition == .inactive)
  }

  @Test("updateCustomPropertyCatalogValue 404 throws notFound")
  func updateNotFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.updateCustomPropertyCatalogValue(
        propertyId: 100, id: 999, deleted: true)
    }
  }

  @Test("removeCustomPropertyCatalogValue 200 returns removed value")
  func removeSuccess() async throws {
    let transport = MockClientTransport.returning(
      statusCode: 200, body: Self.catalogValueJSON)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let value = try await client.removeCustomPropertyCatalogValue(propertyId: 100, id: 11)
    #expect(value.id == 11)
    #expect(value.custom_property_id == 100)
  }

  @Test("removeCustomPropertyCatalogValue 404 throws notFound")
  func removeNotFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.removeCustomPropertyCatalogValue(propertyId: 100, id: 999)
    }
  }

  @Test("unknown condition is preserved, not failed")
  func unknownCondition() async throws {
    let json = """
      {
        "id": 11,
        "custom_property_id": 100,
        "condition": "archived"
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let value = try await client.getCustomPropertyCatalogValue(propertyId: 100, id: 11)
    #expect(value.catalogValueCondition == .unknown("archived"))
  }
}
