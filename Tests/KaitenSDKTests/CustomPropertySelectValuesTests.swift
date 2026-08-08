import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("CustomPropertySelectValues")
struct CustomPropertySelectValuesTests {

  @Test("listCustomPropertySelectValues 200 returns array")
  func listSuccess() async throws {
    let json = """
      [
        {"id": 1, "custom_property_id": 100, "value": "iOS", "color": 1, "condition": "active", "sort_order": 1.0},
        {"id": 2, "custom_property_id": 100, "value": "Android", "color": 2, "condition": "active", "sort_order": 2.0}
      ]
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let page = try await client.listCustomPropertySelectValues(propertyId: 100)
    #expect(page.items.count == 2)
    #expect(page.items[0].value == "iOS")
    #expect(page.items[1].value == "Android")
    #expect(page.offset == 0)
    #expect(page.limit == 100)
  }

  @Test("listCustomPropertySelectValues 404 throws notFound")
  func listNotFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.listCustomPropertySelectValues(propertyId: 999)
    }
  }

  @Test("getCustomPropertySelectValue 200 returns single")
  func getSuccess() async throws {
    let json = """
      {"id": 1, "custom_property_id": 100, "value": "iOS", "color": 1, "condition": "active", "sort_order": 1.0, "author_id": 42, "company_id": 1}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let value = try await client.getCustomPropertySelectValue(propertyId: 100, id: 1)
    #expect(value.value == "iOS")
    #expect(value.custom_property_id == 100)
  }

  @Test("getCustomPropertySelectValue 404 throws notFound")
  func getNotFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.getCustomPropertySelectValue(propertyId: 100, id: 999)
    }
  }

  @Test("createCustomPropertySelectValue 200 returns created value")
  func createSuccess() async throws {
    let json = """
      {"id": 3, "custom_property_id": 100, "value": "Kazakhstan", "color": null, "deleted": false, "condition": "active", "sort_order": 3.0}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let value = try await client.createCustomPropertySelectValue(
      propertyId: 100, value: "Kazakhstan")
    #expect(value.id == 3)
    #expect(value.value == "Kazakhstan")
    #expect(value.custom_property_id == 100)
    #expect(value.deleted == false)
  }

  @Test("createCustomPropertySelectValue 404 throws notFound")
  func createNotFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.createCustomPropertySelectValue(propertyId: 999, value: "Kazakhstan")
    }
  }

  @Test("updateCustomPropertySelectValue 200 returns updated value")
  func updateSuccess() async throws {
    // Shape based on a sanitized live select value plus the documented
    // created/author_id/company_id fields of the update response.
    let json = """
      {"id": 7, "uid": "00000000-0000-0000-0000-000000000001", "custom_property_id": 100, \
      "value": "Renamed", "color": 3, "deleted": false, "sort_order": 5.5, "external_id": null, \
      "updated": "2024-01-02T03:04:05.000Z", "created": "2024-01-01T00:00:00.000Z", \
      "condition": "inactive", "author_id": 42, "company_id": 1}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let value = try await client.updateCustomPropertySelectValue(
      propertyId: 100, id: 7, value: "Renamed", color: 3, condition: .inactive, sortOrder: 5.5,
      deleted: false)
    #expect(value.id == 7)
    #expect(value.uid == "00000000-0000-0000-0000-000000000001")
    #expect(value.value == "Renamed")
    #expect(value.color == 3)
    #expect(value.selectValueCondition == .inactive)
    #expect(value.sort_order == 5.5)
    #expect(value.external_id == nil)
  }

  @Test("updateCustomPropertySelectValue 404 throws notFound")
  func updateNotFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.updateCustomPropertySelectValue(propertyId: 100, id: 999, value: "X")
    }
  }

  @Test("removeCustomPropertySelectValue 200 returns removed value")
  func removeSuccess() async throws {
    // Shape based on a sanitized live select value plus the documented
    // created/author_id/company_id fields of the remove response.
    let json = """
      {"id": 7, "uid": "00000000-0000-0000-0000-000000000001", "custom_property_id": 100, \
      "value": "Obsolete", "color": 3, "deleted": true, "sort_order": 5.5, "external_id": null, \
      "updated": "2024-01-02T03:04:05.000Z", "created": "2024-01-01T00:00:00.000Z", \
      "condition": "active", "author_id": 42, "company_id": 1}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let value = try await client.removeCustomPropertySelectValue(propertyId: 100, id: 7)
    #expect(value.id == 7)
    #expect(value.deleted == true)
    #expect(value.custom_property_id == 100)
    #expect(value.selectValueCondition == .active)
  }

  @Test("removeCustomPropertySelectValue 404 throws notFound")
  func removeNotFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.removeCustomPropertySelectValue(propertyId: 100, id: 999)
    }
  }

  @Test("selectValueCondition preserves undocumented values")
  func conditionPreservesUnknown() async throws {
    let json = """
      {"id": 1, "custom_property_id": 100, "value": "iOS", "condition": "archived", "sort_order": 1.0}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let value = try await client.getCustomPropertySelectValue(propertyId: 100, id: 1)
    #expect(value.selectValueCondition == .unknown("archived"))
  }

  @Test("listCustomPropertySelectValues surfaces deleted values")
  func listExposesDeleted() async throws {
    let json = """
      [
        {"id": 1, "custom_property_id": 100, "value": "UAE", "color": null, "deleted": true, "condition": "active", "sort_order": 0.0},
        {"id": 2, "custom_property_id": 100, "value": "Serbia", "color": null, "deleted": false, "condition": "active", "sort_order": 1.0}
      ]
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)

    let page = try await client.listCustomPropertySelectValues(propertyId: 100)
    #expect(page.items[0].deleted == true)
    #expect(page.items[1].deleted == false)
  }
}
