import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

/// The company behind the live credentials has no custom directories, so these fixtures
/// come from the documentation's response examples (with invented identifiers), not from
/// live responses.
@Suite("CustomDirectoryFields")
struct CustomDirectoryFieldsTests {

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

  @Test("200 returns array of CustomDirectoryField")
  func listSuccess() async throws {
    let json = """
      [{
        "id": "field-uid-1",
        "custom_directory_id": "dir-uid-1",
        "name": "Name",
        "type": "string",
        "required": true,
        "is_display": true,
        "sort_order": 0,
        "condition": "active"
      },
      {
        "id": "field-uid-2",
        "custom_directory_id": "dir-uid-1",
        "name": "Email",
        "type": "email",
        "required": false,
        "is_display": false,
        "sort_order": 1,
        "condition": "active"
      }]
      """
    let client = try makeClient(.returning(statusCode: 200, body: json))

    let fields = try await client.listCustomDirectoryFields(directoryId: "dir-uid-1")
    #expect(fields.count == 2)
    #expect(fields[0].id == "field-uid-1")
    #expect(fields[0].custom_directory_id == "dir-uid-1")
    #expect(fields[0].fieldType == .string)
    #expect(fields[0].fieldCondition == .active)
    #expect(fields[0].required == true)
    #expect(fields[0].is_display == true)
    #expect(fields[1].fieldType == .email)
    #expect(fields[1].sort_order == 1)
  }

  @Test("list sends include_author and conditions query parameters")
  func listSendsQuery() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: "[]")
    let client = try makeClient(transport)

    let fields = try await client.listCustomDirectoryFields(
      directoryId: "dir-uid-1",
      includeAuthor: true,
      conditions: [.active, .inactive]
    )
    #expect(fields.isEmpty)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .get)
    #expect(
      recorded.request.path?.hasPrefix("/company/custom-directories/dir-uid-1/fields") == true)
    let query = try #require(recorded.request.path?.split(separator: "?").last.map(String.init))
    #expect(query.contains("include_author=true"))
    #expect(query.contains("conditions=active"))
    #expect(query.contains("conditions=inactive"))
  }

  @Test("200 with empty body returns empty array")
  func listEmptyBody() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: ""))
    let fields = try await client.listCustomDirectoryFields(directoryId: "dir-uid-1")
    #expect(fields.isEmpty)
  }

  /// Directories are addressed by string UUID, which ``KaitenError/notFound(resource:id:)``
  /// cannot represent, so a 404 surfaces as `unexpectedResponse`.
  @Test("404 throws unexpectedResponse")
  func listNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await expectUnexpectedResponse(statusCode: 404) {
      _ = try await client.listCustomDirectoryFields(directoryId: "missing")
    }
  }

  @Test("401 throws unauthorized")
  func listUnauthorized() async throws {
    let client = try makeClient(.returning(statusCode: 401))
    await #expect(throws: KaitenError.self) {
      _ = try await client.listCustomDirectoryFields(directoryId: "dir-uid-1")
    }
  }

  // MARK: - Create

  @Test("create sends name and type in the body and parses the response")
  func createSendsBody() async throws {
    let json = """
      {
        "id": "field-uid-2",
        "custom_directory_id": "dir-uid-1",
        "name": "Email",
        "type": "email",
        "custom_property_uid": null,
        "linked_directory_id": null,
        "reverse_field_id": null,
        "condition": "active",
        "required": false,
        "is_display": false,
        "sort_order": 1,
        "settings": {},
        "author_uid": "author-uid-1",
        "company_uid": "company-uid-1",
        "created": "2026-04-13T09:00:00.000Z",
        "updated": "2026-04-13T09:00:00.000Z"
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let field = try await client.createCustomDirectoryField(
      directoryId: "dir-uid-1",
      name: "Email",
      type: .email,
      sortOrder: 1,
      required: false,
      isDisplay: false
    )

    #expect(field.id == "field-uid-2")
    #expect(field.fieldType == .email)
    #expect(field.custom_property_uid == nil)
    #expect(field.author_uid == "author-uid-1")

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .post)
    #expect(recorded.request.path == "/company/custom-directories/dir-uid-1/fields")

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["name"] as? String == "Email")
    #expect(sent["type"] as? String == "email")
    #expect(sent["sort_order"] as? Int == 1)
    #expect(sent["required"] as? Bool == false)
    #expect(sent["is_display"] as? Bool == false)
  }

  @Test("create 400 throws unexpectedResponse")
  func createBadRequest() async throws {
    let client = try makeClient(.returning(statusCode: 400))
    await expectUnexpectedResponse(statusCode: 400) {
      _ = try await client.createCustomDirectoryField(
        directoryId: "dir-uid-1", name: "Email", type: .email)
    }
  }

  // MARK: - Get

  @Test("200 returns field with embedded author")
  func getSuccess() async throws {
    let json = """
      {
        "id": "field-uid-1",
        "custom_directory_id": "dir-uid-1",
        "name": "Name",
        "type": "string",
        "custom_property_uid": null,
        "linked_directory_id": null,
        "reverse_field_id": null,
        "condition": "active",
        "required": true,
        "is_display": true,
        "sort_order": 0,
        "settings": {},
        "author_uid": "author-uid-1",
        "company_uid": "company-uid-1",
        "created": "2026-04-13T09:00:00.000Z",
        "updated": "2026-04-13T09:00:00.000Z",
        "author": {
          "id": 1,
          "uid": "author-uid-1",
          "full_name": "Johnny Doe",
          "email": "admin@example.com",
          "username": "admin"
        },
        "linkedDirectory": null,
        "customProperty": null
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let field = try await client.getCustomDirectoryField(
      directoryId: "dir-uid-1", fieldId: "field-uid-1")

    #expect(field.id == "field-uid-1")
    #expect(field.fieldType == .string)
    #expect(field.fieldCondition == .active)
    #expect(field.author?.full_name == "Johnny Doe")
    #expect(field.linkedDirectory == nil)
    #expect(field.customProperty == nil)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .get)
    #expect(recorded.request.path == "/company/custom-directories/dir-uid-1/fields/field-uid-1")
  }

  /// The custom directories API is documented as beta; undocumented discriminator values
  /// must survive as `.unknown` instead of failing the whole response.
  @Test("undocumented discriminators decode as unknown")
  func getUndocumentedDiscriminators() async throws {
    let json = """
      {"id": "field-uid-1", "type": "some_new_type", "condition": "some_new_condition"}
      """
    let client = try makeClient(.returning(statusCode: 200, body: json))

    let field = try await client.getCustomDirectoryField(
      directoryId: "dir-uid-1", fieldId: "field-uid-1")
    #expect(field.fieldType == .unknown("some_new_type"))
    #expect(field.fieldCondition == .unknown("some_new_condition"))
  }

  /// Fields are addressed by string UUID, which ``KaitenError/notFound(resource:id:)``
  /// cannot represent, so a 404 surfaces as `unexpectedResponse`.
  @Test("get 404 throws unexpectedResponse")
  func getNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await expectUnexpectedResponse(statusCode: 404) {
      _ = try await client.getCustomDirectoryField(directoryId: "dir-uid-1", fieldId: "missing")
    }
  }

  // MARK: - Update

  @Test("update targets the field and sends the condition")
  func updateSuccess() async throws {
    let json = """
      {
        "id": "field-uid-2",
        "custom_directory_id": "dir-uid-1",
        "name": "Renamed",
        "type": "email",
        "custom_property_uid": null,
        "linked_directory_id": null,
        "reverse_field_id": null,
        "condition": "inactive",
        "required": false,
        "is_display": false,
        "sort_order": 2,
        "settings": {},
        "author_uid": "author-uid-1",
        "company_uid": "company-uid-1",
        "created": "2026-04-13T09:00:00.000Z",
        "updated": "2026-04-13T09:30:00.000Z"
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let field = try await client.updateCustomDirectoryField(
      directoryId: "dir-uid-1",
      fieldId: "field-uid-2",
      name: "Renamed",
      condition: .inactive,
      sortOrder: 2
    )

    #expect(field.name == "Renamed")
    #expect(field.fieldCondition == .inactive)
    #expect(field.sort_order == 2)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .patch)
    #expect(recorded.request.path == "/company/custom-directories/dir-uid-1/fields/field-uid-2")

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["name"] as? String == "Renamed")
    #expect(sent["condition"] as? String == "inactive")
    #expect(sent["sort_order"] as? Int == 2)
  }

  @Test("update 404 throws unexpectedResponse")
  func updateNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await expectUnexpectedResponse(statusCode: 404) {
      _ = try await client.updateCustomDirectoryField(
        directoryId: "dir-uid-1", fieldId: "missing", name: "Renamed")
    }
  }

  // MARK: - Delete

  /// The delete endpoint soft-deletes and answers with a partial field: the documentation's
  /// example carries only id, custom_directory_id, name, type, condition and updated.
  @Test("delete returns the removed field")
  func deleteSuccess() async throws {
    let json = """
      {
        "id": "field-uid-2",
        "custom_directory_id": "dir-uid-1",
        "name": "Email",
        "type": "email",
        "condition": "removed",
        "updated": "2026-04-13T09:30:00.000Z"
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let field = try await client.deleteCustomDirectoryField(
      directoryId: "dir-uid-1", fieldId: "field-uid-2")

    #expect(field.id == "field-uid-2")
    #expect(field.fieldCondition == .removed)
    #expect(field.required == nil)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .delete)
    #expect(recorded.request.path == "/company/custom-directories/dir-uid-1/fields/field-uid-2")
  }

  @Test("delete 401 throws unauthorized")
  func deleteUnauthorized() async throws {
    let client = try makeClient(.returning(statusCode: 401))
    await #expect(throws: KaitenError.self) {
      _ = try await client.deleteCustomDirectoryField(
        directoryId: "dir-uid-1", fieldId: "field-uid-2")
    }
  }
}
