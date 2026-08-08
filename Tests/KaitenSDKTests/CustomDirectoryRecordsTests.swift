import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

/// The live company used for verification has no custom directories, so every fixture is built
/// from the documented response attributes and the documentation's request example (docs-only,
/// with invented IDs). The custom directories API is documented as beta.
@Suite("Custom Directory Records")
struct CustomDirectoryRecordsTests {

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

  @Test("200 returns page of records")
  func listSuccess() async throws {
    let json = """
      [{
        "id": "rec-1",
        "display_value": "Alpha",
        "condition": "active",
        "values": [{
          "id": "val-1",
          "field_id": "fld-1",
          "value_text": "Alpha",
          "value_number": null,
          "value_date": null,
          "select_value_uid": null,
          "catalog_value_uid": null,
          "user_uid": null,
          "directory_record_id": null
        }]
      }, {
        "id": "rec-2",
        "display_value": null,
        "condition": "inactive",
        "values": []
      }]
      """
    let client = try makeClient(.returning(statusCode: 200, body: json))

    let page = try await client.listCustomDirectoryRecords(directoryId: "dir-1")
    #expect(page.items.count == 2)
    #expect(page.items[0].id == "rec-1")
    #expect(page.items[0].display_value == "Alpha")
    #expect(page.items[0].recordCondition == .active)
    #expect(page.items[0].values?.first?.value_text == "Alpha")
    #expect(page.items[0].values?.first?.value_number == nil)
    #expect(page.items[1].display_value == nil)
    #expect(page.items[1].recordCondition == .inactive)
  }

  @Test("200 with empty body returns empty page")
  func listEmptyBody() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: ""))
    let page = try await client.listCustomDirectoryRecords(directoryId: "dir-1")
    #expect(page.items.isEmpty)
  }

  /// The API is documented as beta, so undocumented condition values must survive as `.unknown`
  /// instead of failing the whole response.
  @Test("undocumented condition decodes as unknown")
  func listUndocumentedCondition() async throws {
    let json = """
      [{"id": "rec-1", "display_value": "Alpha", "condition": "some_new_condition"}]
      """
    let client = try makeClient(.returning(statusCode: 200, body: json))

    let page = try await client.listCustomDirectoryRecords(directoryId: "dir-1")
    #expect(page.items[0].recordCondition == .unknown("some_new_condition"))
  }

  @Test("query parameters are sent")
  func listSendsQueryParameters() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: "[]")
    let client = try makeClient(transport)

    _ = try await client.listCustomDirectoryRecords(
      directoryId: "dir-1",
      query: "alpha",
      profile: .summary,
      includeValues: true,
      includeAuthor: false,
      conditions: [.active, .inactive],
      filters: "{\"fld-1\":{\"value_text\":\"Alpha\"}}",
      filterOperator: .or,
      offset: 10,
      limit: 50
    )

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .get)
    let path = try #require(recorded.request.path)
    #expect(path.hasPrefix("/company/custom-directories/dir-1/records?"))
    #expect(path.contains("query=alpha"))
    #expect(path.contains("profile=summary"))
    #expect(path.contains("include_values=true"))
    #expect(path.contains("include_author=false"))
    #expect(path.contains("conditions=active"))
    #expect(path.contains("conditions=inactive"))
    #expect(path.contains("filter_operator=or"))
    #expect(path.contains("offset=10"))
    #expect(path.contains("limit=50"))
  }

  @Test("limit above 100 throws invalidPaginationRange")
  func listInvalidPagination() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: "[]"))
    await #expect(throws: KaitenError.self) {
      _ = try await client.listCustomDirectoryRecords(directoryId: "dir-1", limit: 101)
    }
  }

  @Test("401 throws unauthorized")
  func listUnauthorized() async throws {
    let client = try makeClient(.returning(statusCode: 401))
    await #expect(throws: KaitenError.self) {
      _ = try await client.listCustomDirectoryRecords(directoryId: "dir-1")
    }
  }

  /// Directories are addressed by string ID, which ``KaitenError/notFound(resource:id:)``
  /// cannot represent, so a 404 surfaces as `unexpectedResponse`.
  @Test("404 throws unexpectedResponse")
  func listNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await expectUnexpectedResponse(statusCode: 404) {
      _ = try await client.listCustomDirectoryRecords(directoryId: "missing")
    }
  }

  // MARK: - Create

  @Test("create sends values map and parses the full record")
  func createSendsBody() async throws {
    let json = """
      {
        "id": "rec-1",
        "custom_directory_id": "dir-1",
        "display_value": "Alice",
        "condition": "active",
        "author_uid": "user-uid-1",
        "updater_uid": "user-uid-1",
        "created": "2026-04-01T00:00:00.000Z",
        "updated": "2026-04-01T00:00:00.000Z",
        "author": {"uid": "user-uid-1", "full_name": "Test User"},
        "updater": {"uid": "user-uid-1", "full_name": "Test User"},
        "values": [{
          "id": "val-1",
          "field_id": "fld-1",
          "value_text": "Alice",
          "value_number": null,
          "value_date": null,
          "select_value_uid": null,
          "catalog_value_uid": null,
          "user_uid": null,
          "directory_record_id": null
        }]
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let values = try JSONDecoder().decode(
      Components.Schemas.CreateCustomDirectoryRecordRequest.valuesPayload.self,
      from: Data("{\"fld-1\": {\"value_text\": \"Alice\"}}".utf8))
    let record = try await client.createCustomDirectoryRecord(
      directoryId: "dir-1", values: values, responseProfile: .full)

    #expect(record.id == "rec-1")
    #expect(record.custom_directory_id == "dir-1")
    #expect(record.recordCondition == .active)
    #expect(record.author_uid == "user-uid-1")
    #expect(record.values?.first?.field_id == "fld-1")

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .post)
    let path = try #require(recorded.request.path)
    #expect(path.hasPrefix("/company/custom-directories/dir-1/records"))
    #expect(path.contains("response_profile=full"))

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    let sentValues = try #require(sent["values"] as? [String: Any])
    let sentField = try #require(sentValues["fld-1"] as? [String: Any])
    #expect(sentField["value_text"] as? String == "Alice")
  }

  @Test("create 400 throws unexpectedResponse")
  func createValidationError() async throws {
    let client = try makeClient(.returning(statusCode: 400))
    await expectUnexpectedResponse(statusCode: 400) {
      _ = try await client.createCustomDirectoryRecord(
        directoryId: "dir-1", values: .init())
    }
  }

  // MARK: - Get

  @Test("200 returns the record")
  func getSuccess() async throws {
    let json = """
      {
        "id": "rec-1",
        "custom_directory_id": "dir-1",
        "display_value": "Alpha",
        "values": [{
          "id": "val-1",
          "field_id": "fld-1",
          "value_text": null,
          "value_number": 42.5,
          "value_date": null,
          "select_value_uid": "sel-1",
          "catalog_value_uid": null,
          "user_uid": null,
          "directory_record_id": null,
          "selectValue": {"uid": "sel-1", "value": "Option A"}
        }],
        "author": {"uid": "user-uid-1"},
        "updater": {"uid": "user-uid-1"}
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let record = try await client.getCustomDirectoryRecord(
      directoryId: "dir-1", recordId: "rec-1", profile: .details)

    #expect(record.id == "rec-1")
    #expect(record.display_value == "Alpha")
    let value = try #require(record.values?.first)
    #expect(value.value_number == 42.5)
    #expect(value.value_text == nil)
    #expect(value.select_value_uid == "sel-1")
    #expect(value.selectValue != nil)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .get)
    let path = try #require(recorded.request.path)
    #expect(path.hasPrefix("/company/custom-directories/dir-1/records/rec-1"))
    #expect(path.contains("profile=details"))
  }

  /// Records are addressed by string ID, which ``KaitenError/notFound(resource:id:)``
  /// cannot represent, so a 404 surfaces as `unexpectedResponse`.
  @Test("get 404 throws unexpectedResponse")
  func getNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await expectUnexpectedResponse(statusCode: 404) {
      _ = try await client.getCustomDirectoryRecord(directoryId: "dir-1", recordId: "missing")
    }
  }

  // MARK: - Update

  @Test("update targets the record and sends condition and values")
  func updateSuccess() async throws {
    let json = """
      {
        "id": "rec-1",
        "display_value": "Beta",
        "values": [],
        "author": {"uid": "user-uid-1"},
        "updater": {"uid": "user-uid-2"}
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let values = try JSONDecoder().decode(
      Components.Schemas.UpdateCustomDirectoryRecordRequest.valuesPayload.self,
      from: Data("{\"fld-1\": {\"value_text\": \"Beta\"}}".utf8))
    let record = try await client.updateCustomDirectoryRecord(
      directoryId: "dir-1",
      recordId: "rec-1",
      condition: .inactive,
      values: values
    )

    #expect(record.id == "rec-1")
    #expect(record.display_value == "Beta")

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .patch)
    let path = try #require(recorded.request.path)
    #expect(path.hasPrefix("/company/custom-directories/dir-1/records/rec-1"))

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["condition"] as? String == "inactive")
    let sentValues = try #require(sent["values"] as? [String: Any])
    let sentField = try #require(sentValues["fld-1"] as? [String: Any])
    #expect(sentField["value_text"] as? String == "Beta")
  }

  @Test("update 400 throws unexpectedResponse")
  func updateValidationError() async throws {
    let client = try makeClient(.returning(statusCode: 400))
    await expectUnexpectedResponse(statusCode: 400) {
      _ = try await client.updateCustomDirectoryRecord(
        directoryId: "dir-1", recordId: "rec-1", condition: .active)
    }
  }

  // MARK: - Delete

  @Test("delete returns the removed record")
  func deleteSuccess() async throws {
    let json = """
      {"id": "rec-1", "condition": "removed"}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let record = try await client.deleteCustomDirectoryRecord(
      directoryId: "dir-1", recordId: "rec-1")

    #expect(record.id == "rec-1")
    #expect(record.recordCondition == .removed)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .delete)
    #expect(recorded.request.path == "/company/custom-directories/dir-1/records/rec-1")
  }

  @Test("delete 404 throws unexpectedResponse")
  func deleteNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await expectUnexpectedResponse(statusCode: 404) {
      _ = try await client.deleteCustomDirectoryRecord(directoryId: "dir-1", recordId: "missing")
    }
  }

  // MARK: - Linked Cards

  @Test("200 returns page of linked cards")
  func listCardsSuccess() async throws {
    let json = """
      [
        {"id": 101, "uid": "card-uid-1", "title": "First card"},
        {"id": 102, "uid": "card-uid-2", "title": "Second card"}
      ]
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let page = try await client.listCustomDirectoryRecordCards(
      directoryId: "dir-1", recordId: "rec-1", filter: "eyJrZXkiOiAidmFsdWUifQ==")

    #expect(page.items.count == 2)
    #expect(page.items[0].id == 101)
    #expect(page.items[0].uid == "card-uid-1")
    #expect(page.items[0].title == "First card")

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .get)
    let path = try #require(recorded.request.path)
    #expect(path.hasPrefix("/company/custom-directories/dir-1/records/rec-1/cards"))
    #expect(path.contains("filter="))
  }

  @Test("linked cards 200 with empty body returns empty page")
  func listCardsEmptyBody() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: ""))
    let page = try await client.listCustomDirectoryRecordCards(
      directoryId: "dir-1", recordId: "rec-1")
    #expect(page.items.isEmpty)
  }

  @Test("linked cards limit above 100 throws invalidPaginationRange")
  func listCardsInvalidPagination() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: "[]"))
    await #expect(throws: KaitenError.self) {
      _ = try await client.listCustomDirectoryRecordCards(
        directoryId: "dir-1", recordId: "rec-1", limit: 101)
    }
  }

  @Test("linked cards 400 throws unexpectedResponse")
  func listCardsValidationError() async throws {
    let client = try makeClient(.returning(statusCode: 400))
    await expectUnexpectedResponse(statusCode: 400) {
      _ = try await client.listCustomDirectoryRecordCards(
        directoryId: "dir-1", recordId: "rec-1", filter: "not-base64")
    }
  }
}
