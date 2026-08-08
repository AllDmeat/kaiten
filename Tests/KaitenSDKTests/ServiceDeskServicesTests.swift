import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("Service Desk Services")
struct ServiceDeskServicesTests {

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

  /// Fixture built from the documented response schema: the live endpoint answers HTTP 403
  /// for tokens without service desk access, so no real response was available.
  @Test("200 returns array of ServiceDeskService")
  func listSuccess() async throws {
    let json = """
      [{
        "id": 11,
        "name": "Support requests",
        "fields_settings": {
          "commentDescription": {"required": false},
          "size": {"required": false},
          "dueDate": {"required": false},
          "id_12": {"required": true}
        },
        "archived": false,
        "lng": "en",
        "email_settings": 3,
        "type_id": null,
        "email_key": 101,
        "board_id": 21,
        "column_id": 31,
        "lane_id": 41,
        "display_status": "default",
        "template_description": "Describe the request",
        "settings": {"allowed_email_masks": ["*@example.com"]},
        "allow_to_add_external_recipients": true,
        "column": {
          "id": 31, "title": "Queue", "sort_order": 1, "col_count": 1, "type": 1,
          "board_id": 21, "column_id": null, "external_id": null, "rules": 0
        },
        "board": {"id": 21, "title": "Requests board", "external_id": null, "card_properties": null},
        "lane": {
          "id": 41, "title": "Default", "sort_order": 1, "board_id": 21,
          "condition": 1, "external_id": null
        },
        "voteCustomProperty": {
          "updated": "2024-01-02T03:04:05.000Z", "created": "2024-01-01T00:00:00.000Z",
          "service_id": 11, "custom_property_id": 12, "author_id": 7
        }
      }]
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let services = try await client.listServiceDeskServices()
    #expect(services.count == 1)
    let service = try #require(services.first)
    #expect(service.id == 11)
    #expect(service.name == "Support requests")
    #expect(service.archived == false)
    #expect(service.lng == "en")
    #expect(service.email_settings == 3)
    #expect(service.type_id == .none)
    #expect(service.email_key == 101)
    #expect(service.board_id == 21)
    #expect(service.column_id == 31)
    #expect(service.lane_id == 41)
    #expect(service.display_status == "default")
    #expect(service.allow_to_add_external_recipients == true)
    #expect(service.settings?.allowed_email_masks?.count == 1)
    #expect(service.column?.id == 31)
    #expect(service.column?._type == 1)
    #expect(service.column?.column_id == nil)
    #expect(service.board?.title == "Requests board")
    #expect(service.lane?.condition == 1)
    #expect(service.voteCustomProperty?.custom_property_id == 12)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .get)
    #expect(recorded.request.path == "/service-desk/services")
  }

  /// `fields_settings` and `type_id` are documented as nullable; explicit JSON null must
  /// decode to nil rather than fail the response.
  @Test("null nullable fields decode to nil")
  func listNullableFields() async throws {
    let json = """
      [{
        "id": 12,
        "name": "Archived service",
        "fields_settings": null,
        "archived": true,
        "type_id": null
      }]
      """
    let client = try makeClient(.returning(statusCode: 200, body: json))

    let services = try await client.listServiceDeskServices()
    let service = try #require(services.first)
    #expect(service.fields_settings == nil)
    #expect(service.type_id == .none)
    #expect(service.archived == true)
  }

  @Test("200 with empty body returns empty array")
  func listEmptyBody() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: ""))
    let services = try await client.listServiceDeskServices()
    #expect(services.isEmpty)
  }

  @Test("401 throws unauthorized")
  func listUnauthorized() async throws {
    let client = try makeClient(.returning(statusCode: 401))
    await #expect(throws: KaitenError.self) {
      _ = try await client.listServiceDeskServices()
    }
  }

  /// Observed live: a token without service desk access gets HTTP 403.
  @Test("403 throws unexpectedResponse")
  func listForbidden() async throws {
    let client = try makeClient(.returning(statusCode: 403))
    await expectUnexpectedResponse(statusCode: 403) {
      _ = try await client.listServiceDeskServices()
    }
  }
}
