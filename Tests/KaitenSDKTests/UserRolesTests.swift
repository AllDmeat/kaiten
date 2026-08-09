import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("User Roles")
struct UserRolesTests {

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

  /// Fixture mirrors a sanitized live response. The built-in company-wide role
  /// carries a negative id and a JSON `null` company_id, which the documentation
  /// declares as a non-nullable integer.
  @Test("200 returns array of UserRole")
  func listSuccess() async throws {
    let json = """
      [{
        "created": "2017-03-21T14:00:22.934Z",
        "updated": "2017-03-21T14:00:22.934Z",
        "id": -1,
        "name": "Employee",
        "company_id": null,
        "uid": "00000000-0000-0000-0000-000000000001"
      },
      {
        "created": "2018-03-12T07:16:37.527Z",
        "updated": "2018-03-12T07:16:37.527Z",
        "id": 12,
        "name": "Tester",
        "company_id": 55,
        "uid": "00000000-0000-0000-0000-000000000002"
      }]
      """
    let client = try makeClient(.returning(statusCode: 200, body: json))

    let roles = try await client.listUserRoles()
    #expect(roles.count == 2)
    #expect(roles[0].id == -1)
    #expect(roles[0].name == "Employee")
    #expect(roles[0].company_id == nil)
    #expect(roles[1].id == 12)
    #expect(roles[1].company_id == 55)
    #expect(roles[1].uid == "00000000-0000-0000-0000-000000000002")
  }

  @Test("200 with empty body returns empty array")
  func listEmptyBody() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: ""))
    let roles = try await client.listUserRoles()
    #expect(roles.isEmpty)
  }

  @Test("401 throws unauthorized")
  func listUnauthorized() async throws {
    let client = try makeClient(.returning(statusCode: 401))
    await #expect(throws: KaitenError.self) {
      _ = try await client.listUserRoles()
    }
  }

  // MARK: - Create

  @Test("create sends name in the body")
  func createSendsBody() async throws {
    let json = """
      {
        "created": "2026-01-01T00:00:00.000Z",
        "updated": "2026-01-01T00:00:00.000Z",
        "id": 13,
        "name": "Analyst",
        "company_id": 55,
        "uid": "00000000-0000-0000-0000-000000000003"
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let role = try await client.createUserRole(name: "Analyst")
    #expect(role.id == 13)
    #expect(role.name == "Analyst")

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .post)
    #expect(recorded.request.path == "/user-roles")

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["name"] as? String == "Analyst")
  }

  @Test("create 400 throws unexpectedResponse")
  func createValidationError() async throws {
    let client = try makeClient(.returning(statusCode: 400, body: #"{"message": "invalid"}"#))
    await expectUnexpectedResponse(statusCode: 400) {
      _ = try await client.createUserRole(name: "")
    }
  }

  // MARK: - Get

  @Test("200 returns a single UserRole")
  func getSuccess() async throws {
    let json = """
      {
        "created": "2018-03-12T07:16:37.527Z",
        "updated": "2018-03-12T07:16:37.527Z",
        "id": 12,
        "name": "Tester",
        "company_id": 55,
        "uid": "00000000-0000-0000-0000-000000000002"
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let role = try await client.getUserRole(id: 12)
    #expect(role.id == 12)
    #expect(role.name == "Tester")
    #expect(role.company_id == 55)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .get)
    #expect(recorded.request.path == "/user-roles/12")
  }

  @Test("get 404 throws notFound")
  func getNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    do {
      _ = try await client.getUserRole(id: 999)
      Issue.record("expected KaitenError.notFound, no error thrown")
    } catch let error as KaitenError {
      guard case .notFound(let resource, let id) = error else {
        Issue.record("expected KaitenError.notFound, got \(error)")
        return
      }
      #expect(resource == "userRole")
      #expect(id == 999)
    } catch {
      Issue.record("expected KaitenError, got \(error)")
    }
  }

  // MARK: - Update

  @Test("update targets the role id and sends name")
  func updateSuccess() async throws {
    let json = """
      {
        "created": "2018-03-12T07:16:37.527Z",
        "updated": "2026-01-02T00:00:00.000Z",
        "id": 12,
        "name": "Renamed",
        "company_id": 55,
        "uid": "00000000-0000-0000-0000-000000000002"
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let role = try await client.updateUserRole(id: 12, name: "Renamed")
    #expect(role.name == "Renamed")

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .patch)
    #expect(recorded.request.path == "/user-roles/12")

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["name"] as? String == "Renamed")
  }

  @Test("update 404 throws notFound")
  func updateNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await #expect(throws: KaitenError.self) {
      _ = try await client.updateUserRole(id: 999, name: "Renamed")
    }
  }

  // MARK: - Delete

  @Test("delete sends replace_role_id and returns the deleted role")
  func deleteSuccess() async throws {
    let json = """
      {
        "created": "2018-03-12T07:16:37.527Z",
        "updated": "2018-03-12T07:16:37.527Z",
        "id": 12,
        "name": "Tester",
        "company_id": 55,
        "uid": "00000000-0000-0000-0000-000000000002"
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let role = try await client.deleteUserRole(id: 12, replaceRoleId: 13)
    #expect(role.id == 12)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .delete)
    #expect(recorded.request.path == "/user-roles/12")

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["replace_role_id"] as? Int == 13)
  }

  @Test("delete 403 throws unexpectedResponse")
  func deleteForbidden() async throws {
    let client = try makeClient(.returning(statusCode: 403))
    await expectUnexpectedResponse(statusCode: 403) {
      _ = try await client.deleteUserRole(id: 12, replaceRoleId: 13)
    }
  }
}
