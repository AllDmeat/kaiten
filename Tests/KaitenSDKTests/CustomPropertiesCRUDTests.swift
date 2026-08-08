import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("CustomProperties CRUD")
struct CustomPropertiesCRUDTests {

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

  /// Sanitized from a live `GET /company/custom-properties` response: the create,
  /// update and remove endpoints all answer with this same property shape.
  private let propertyJSON = """
    {
      "created": "2024-01-15T10:00:00.017Z",
      "updated": "2024-01-15T10:00:00.017Z",
      "id": 101,
      "type": "select",
      "name": "Team",
      "show_on_facade": true,
      "author_id": 42,
      "company_id": 7,
      "condition": "active",
      "colorful": true,
      "multi_select": false,
      "values_creatable_by_users": true,
      "data": null,
      "multiline": false,
      "calculation_method": null,
      "values_type": null,
      "vote_variant": null,
      "protected": false,
      "fields_settings": null,
      "color": 3,
      "external_id": null,
      "uid": "00000000-0000-4000-8000-000000000001",
      "import_uid": null,
      "is_used_as_progress": false,
      "directory_id": null,
      "fts_version": "1"
    }
    """

  // MARK: - Create

  @Test("create sends name and type in the body")
  func createSendsBody() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: propertyJSON)
    let client = try makeClient(transport)

    let property = try await client.createCustomProperty(
      name: "Team",
      type: .select,
      showOnFacade: true,
      colorful: true,
      multiSelect: false,
      valuesCreatableByUsers: true
    )

    #expect(property.id == 101)
    #expect(property.name == "Team")
    #expect(property.propertyType == .select)
    #expect(property.propertyCondition == .active)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .post)
    #expect(recorded.request.path == "/company/custom-properties")

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["name"] as? String == "Team")
    #expect(sent["type"] as? String == "select")
    #expect(sent["show_on_facade"] as? Bool == true)
    #expect(sent["multi_select"] as? Bool == false)
  }

  @Test("create 402 unsupported tariff throws unexpectedResponse")
  func createPaymentRequired() async throws {
    let client = try makeClient(.returning(statusCode: 402))
    await expectUnexpectedResponse(statusCode: 402) {
      _ = try await client.createCustomProperty(name: "Team", type: .select)
    }
  }

  @Test("create 400 throws unexpectedResponse")
  func createBadRequest() async throws {
    let client = try makeClient(.returning(statusCode: 400))
    await expectUnexpectedResponse(statusCode: 400) {
      _ = try await client.createCustomProperty(name: "")
    }
  }

  // MARK: - Update

  @Test("update targets the property ID")
  func updateSuccess() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: propertyJSON)
    let client = try makeClient(transport)

    let property = try await client.updateCustomProperty(
      id: 101, name: "Team", condition: .active, isUsedAsProgress: false)

    #expect(property.name == "Team")
    #expect(property.propertyCondition == .active)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .patch)
    #expect(recorded.request.path == "/company/custom-properties/101")

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["condition"] as? String == "active")
    #expect(sent["is_used_as_progress"] as? Bool == false)
  }

  @Test("update 404 throws notFound")
  func updateNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    do {
      _ = try await client.updateCustomProperty(id: 999, name: "Missing")
      Issue.record("expected KaitenError.notFound, no error thrown")
    } catch let error as KaitenError {
      guard case .notFound(let resource, let id) = error else {
        Issue.record("expected KaitenError.notFound, got \(error)")
        return
      }
      #expect(resource == "customProperty")
      #expect(id == 999)
    } catch {
      Issue.record("expected KaitenError, got \(error)")
    }
  }

  // MARK: - Remove

  @Test("remove returns the removed property")
  func removeSuccess() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: propertyJSON)
    let client = try makeClient(transport)

    let property = try await client.removeCustomProperty(id: 101)

    #expect(property.id == 101)
    #expect(property.name == "Team")

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .delete)
    #expect(recorded.request.path == "/company/custom-properties/101")
  }

  @Test("remove 404 throws notFound")
  func removeNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await #expect(throws: KaitenError.self) {
      _ = try await client.removeCustomProperty(id: 999)
    }
  }

  @Test("remove 403 throws unexpectedResponse")
  func removeForbidden() async throws {
    let client = try makeClient(.returning(statusCode: 403))
    await expectUnexpectedResponse(statusCode: 403) {
      _ = try await client.removeCustomProperty(id: 101)
    }
  }

  // MARK: - Discriminators

  /// The property `type` and `condition` are plain strings in the spec, so values
  /// the documentation does not list must survive as `.unknown` instead of
  /// failing the whole response.
  @Test("undocumented discriminators decode as unknown")
  func undocumentedDiscriminators() async throws {
    let json = """
      {
        "id": 102,
        "name": "Mystery",
        "type": "some_new_type",
        "condition": "some_new_condition",
        "vote_variant": "some_new_variant",
        "values_type": "some_new_values_type"
      }
      """
    let client = try makeClient(.returning(statusCode: 200, body: json))

    let property = try await client.removeCustomProperty(id: 102)
    #expect(property.propertyType == .unknown("some_new_type"))
    #expect(property.propertyCondition == .unknown("some_new_condition"))
    #expect(property.propertyVoteVariant == .unknown("some_new_variant"))
    #expect(property.propertyValuesType == .unknown("some_new_values_type"))
  }
}
