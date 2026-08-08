import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("Custom Directories")
struct CustomDirectoriesTests {

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

  /// Fixture shape matches a sanitized live response: `created`, `updated`, `author_uid` and
  /// `company_uid` come back even though the list documentation does not mention them, and
  /// `records_count` and `author` appear because the request asked for them.
  @Test("200 returns page of CustomDirectory")
  func listSuccess() async throws {
    let json = """
      [{
        "created": "2023-01-02T03:04:05.678Z",
        "updated": "2023-01-02T03:04:08.901Z",
        "id": "d1000000-0000-0000-0000-000000000001",
        "name": "Contacts",
        "description": null,
        "condition": "removed",
        "settings": {"multi_select": false, "allow_editing": true},
        "author_uid": "a1000000-0000-0000-0000-000000000001",
        "company_uid": "c1000000-0000-0000-0000-000000000001",
        "records_count": 0,
        "author": {
          "id": 42,
          "uid": "a1000000-0000-0000-0000-000000000001",
          "full_name": "Test User",
          "email": "user@example.com",
          "username": "test_user",
          "avatar_initials_url": "data:image/png;base64,xyz",
          "avatar_uploaded_url": "https://files.example.com/avatar.jpg",
          "initials": "TU",
          "avatar_type": 3,
          "lng": "en",
          "timezone": "UTC",
          "theme": "auto",
          "created": "2022-01-01T00:00:00.000Z",
          "updated": "2023-01-01T00:00:00.000Z",
          "activated": true,
          "ui_version": 2,
          "virtual": false,
          "email_blocked": null,
          "email_blocked_reason": null,
          "delete_requested_at": null
        }
      }]
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let page = try await client.listCustomDirectories(
      includeAuthor: true,
      includeRecordsCount: true,
      conditions: [.active, .removed]
    )
    #expect(page.items.count == 1)
    let directory = try #require(page.items.first)
    #expect(directory.id == "d1000000-0000-0000-0000-000000000001")
    #expect(directory.name == "Contacts")
    #expect(directory.description == nil)
    #expect(directory.directoryCondition == .removed)
    #expect(directory.settings?.multi_select == false)
    #expect(directory.settings?.allow_editing == true)
    #expect(directory.records_count == 0)
    #expect(directory.author?.full_name == "Test User")
  }

  /// Kaiten ignores a single bare `conditions` value, so the client must send the
  /// bracket form the API actually honors.
  @Test("conditions serialize with the bracket form")
  func listConditionsSerialization() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: "[]")
    let client = try makeClient(transport)

    _ = try await client.listCustomDirectories(conditions: [.removed])

    let recorded = try #require(transport.recordedRequests.first)
    let path = try #require(recorded.request.path)
    #expect(path.contains("conditions%5B%5D=removed") || path.contains("conditions[]=removed"))
    #expect(recorded.request.method == .get)
  }

  @Test("200 with empty body returns empty page")
  func listEmptyBody() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: ""))
    let page = try await client.listCustomDirectories()
    #expect(page.items.isEmpty)
  }

  @Test("invalid pagination throws invalidPaginationRange")
  func listInvalidPagination() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: "[]"))
    await #expect(throws: KaitenError.self) {
      _ = try await client.listCustomDirectories(limit: 201)
    }
    await #expect(throws: KaitenError.self) {
      _ = try await client.listCustomDirectories(offset: -1)
    }
  }

  @Test("401 throws unauthorized")
  func listUnauthorized() async throws {
    let client = try makeClient(.returning(statusCode: 401))
    await #expect(throws: KaitenError.self) {
      _ = try await client.listCustomDirectories()
    }
  }

  // MARK: - Get

  /// The live API answers 404 for a removed directory, so the fields and author shapes
  /// come from the documentation.
  @Test("200 returns CustomDirectory with fields")
  func getSuccess() async throws {
    let json = """
      {
        "id": "d1000000-0000-0000-0000-000000000001",
        "name": "Contacts",
        "description": "Company contacts directory",
        "condition": "active",
        "settings": {"multi_select": false, "allow_editing": false},
        "fields": [{
          "id": "f1000000-0000-0000-0000-000000000001",
          "custom_directory_id": "d1000000-0000-0000-0000-000000000001",
          "name": "Name",
          "type": "string",
          "required": true,
          "is_display": true,
          "sort_order": 0,
          "custom_property_uid": null,
          "linked_directory_id": null,
          "condition": "active",
          "created": "2023-01-02T03:04:05.678Z",
          "updated": "2023-01-02T03:04:05.678Z"
        }],
        "author": {"id": 42, "uid": "a1000000-0000-0000-0000-000000000001"}
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let directory = try await client.getCustomDirectory(
      directoryId: "d1000000-0000-0000-0000-000000000001")

    #expect(directory.directoryCondition == .active)
    #expect(directory.description == "Company contacts directory")
    let field = try #require(directory.fields?.first)
    #expect(field.fieldType == .string)
    #expect(field.fieldCondition == .active)
    #expect(field.required == true)
    #expect(field.is_display == true)
    #expect(field.custom_property_uid == nil)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .get)
    #expect(
      recorded.request.path == "/company/custom-directories/d1000000-0000-0000-0000-000000000001")
  }

  /// Directories are addressed by string ID, which ``KaitenError/notFound(resource:id:)``
  /// cannot represent, so a 404 surfaces as `unexpectedResponse`.
  @Test("get 404 throws unexpectedResponse")
  func getNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await expectUnexpectedResponse(statusCode: 404) {
      _ = try await client.getCustomDirectory(directoryId: "missing")
    }
  }

  /// Undocumented discriminator values must survive as `.unknown` instead of failing
  /// the whole response — the custom-directories API is documented as beta.
  @Test("undocumented discriminators decode as unknown")
  func undocumentedDiscriminators() async throws {
    let json = """
      {
        "id": "d1",
        "condition": "some_new_condition",
        "fields": [{"id": "f1", "type": "some_new_type", "condition": "another_condition"}]
      }
      """
    let client = try makeClient(.returning(statusCode: 200, body: json))

    let directory = try await client.getCustomDirectory(directoryId: "d1")
    #expect(directory.directoryCondition == .unknown("some_new_condition"))
    #expect(directory.fields?.first?.fieldType == .unknown("some_new_type"))
    #expect(directory.fields?.first?.fieldCondition == .unknown("another_condition"))
  }

  // MARK: - Create

  /// Response fixture follows the create documentation, which declares `author_uid`,
  /// `company_uid`, `created`, `updated` and `fields` on the created directory.
  @Test("create sends name and fields in the body")
  func createSendsBody() async throws {
    let json = """
      {
        "id": "d2000000-0000-0000-0000-000000000002",
        "name": "Contacts",
        "description": "Company contacts directory",
        "condition": "active",
        "settings": {"multi_select": false, "allow_editing": false},
        "author_uid": "a1000000-0000-0000-0000-000000000001",
        "company_uid": "c1000000-0000-0000-0000-000000000001",
        "created": "2023-01-02T03:04:05.678Z",
        "updated": "2023-01-02T03:04:05.678Z",
        "fields": [{
          "id": "f1000000-0000-0000-0000-000000000001",
          "custom_directory_id": "d2000000-0000-0000-0000-000000000002",
          "name": "Name",
          "type": "string",
          "required": true,
          "is_display": true,
          "sort_order": 0,
          "custom_property_uid": null,
          "linked_directory_id": null,
          "condition": "active",
          "created": "2023-01-02T03:04:05.678Z",
          "updated": "2023-01-02T03:04:05.678Z"
        }]
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let directory = try await client.createCustomDirectory(
      name: "Contacts",
      description: "Company contacts directory",
      fields: [
        .init(fieldType: .string, name: "Name", required: true),
        .init(fieldType: .email, name: "Email"),
      ]
    )

    #expect(directory.id == "d2000000-0000-0000-0000-000000000002")
    #expect(directory.directoryCondition == .active)
    #expect(directory.author_uid == "a1000000-0000-0000-0000-000000000001")
    #expect(directory.fields?.first?.fieldType == .string)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .post)
    #expect(recorded.request.path == "/company/custom-directories")

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["name"] as? String == "Contacts")
    let sentFields = try #require(sent["fields"] as? [[String: Any]])
    #expect(sentFields.count == 2)
    #expect(sentFields.first?["type"] as? String == "string")
    #expect(sentFields.first?["required"] as? Bool == true)
    #expect(sentFields.last?["type"] as? String == "email")
  }

  @Test("create 400 throws unexpectedResponse")
  func createBadRequest() async throws {
    let client = try makeClient(.returning(statusCode: 400))
    await expectUnexpectedResponse(statusCode: 400) {
      _ = try await client.createCustomDirectory(name: "")
    }
  }

  // MARK: - Update

  @Test("update targets the directory ID and clears description with explicit null")
  func updateSuccess() async throws {
    let json = """
      {
        "id": "d1000000-0000-0000-0000-000000000001",
        "name": "Renamed",
        "description": null,
        "condition": "inactive",
        "settings": {"multi_select": true, "allow_editing": false}
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let directory = try await client.updateCustomDirectory(
      directoryId: "d1000000-0000-0000-0000-000000000001",
      name: "Renamed",
      description: .some(nil),
      condition: .inactive,
      multiSelect: true
    )

    #expect(directory.name == "Renamed")
    #expect(directory.directoryCondition == .inactive)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .patch)
    #expect(
      recorded.request.path == "/company/custom-directories/d1000000-0000-0000-0000-000000000001")

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["name"] as? String == "Renamed")
    #expect(sent["condition"] as? String == "inactive")
    #expect(sent["multi_select"] as? Bool == true)
    // `.some(nil)` must reach the server as an explicit JSON null, not an absent key.
    #expect(sent.keys.contains("description"))
    #expect(sent["description"] is NSNull)
  }

  @Test("update 404 throws unexpectedResponse")
  func updateNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await expectUnexpectedResponse(statusCode: 404) {
      _ = try await client.updateCustomDirectory(directoryId: "missing", name: "Renamed")
    }
  }

  // MARK: - Delete

  @Test("delete returns the removed directory ID and condition")
  func deleteSuccess() async throws {
    let json = """
      {"id": "d1000000-0000-0000-0000-000000000001", "condition": "removed"}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let result = try await client.deleteCustomDirectory(
      directoryId: "d1000000-0000-0000-0000-000000000001")

    #expect(result.id == "d1000000-0000-0000-0000-000000000001")
    #expect(result.directoryCondition == .removed)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .delete)
    #expect(
      recorded.request.path == "/company/custom-directories/d1000000-0000-0000-0000-000000000001")
  }

  /// Deletion is not allowed while active custom properties are linked to the directory —
  /// the API answers 400.
  @Test("delete 400 throws unexpectedResponse")
  func deleteBadRequest() async throws {
    let client = try makeClient(.returning(statusCode: 400))
    await expectUnexpectedResponse(statusCode: 400) {
      _ = try await client.deleteCustomDirectory(directoryId: "d1")
    }
  }
}
