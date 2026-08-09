import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("Tags")
struct TagsTests {

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

  /// Fixture mirrors a sanitized live response: the API adds `uid`, `locked` and
  /// `fts_version`, which the documentation does not list.
  @Test("200 returns array of Tag")
  func listSuccess() async throws {
    let json = """
      [{
        "created": "2023-01-02T10:00:00.000Z",
        "updated": "2023-01-02T10:00:00.000Z",
        "id": 101,
        "name": "backend",
        "company_id": 7,
        "color": 4,
        "archived": false,
        "uid": "00000000-0000-0000-0000-000000000001",
        "locked": null,
        "fts_version": "12345"
      }]
      """
    let client = try makeClient(.returning(statusCode: 200, body: json))

    let tags = try await client.listTags()
    #expect(tags.count == 1)
    #expect(tags[0].id == 101)
    #expect(tags[0].name == "backend")
    #expect(tags[0].company_id == 7)
    #expect(tags[0].color == 4)
    #expect(tags[0].archived == false)
    #expect(tags[0].uid == "00000000-0000-0000-0000-000000000001")
    #expect(tags[0].locked == nil)
    #expect(tags[0].fts_version == "12345")
  }

  @Test("200 with empty body returns empty array")
  func listEmptyBody() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: ""))
    let tags = try await client.listTags()
    #expect(tags.isEmpty)
  }

  @Test("list sends all query parameters")
  func listSendsQueryParameters() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: "[]")
    let client = try makeClient(transport)

    _ = try await client.listTags(limit: 50, offset: 10, spaceId: 3, ids: "101,102", query: "back")

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .get)
    let path = try #require(recorded.request.path)
    #expect(path.hasPrefix("/tags?"))
    #expect(path.contains("limit=50"))
    #expect(path.contains("offset=10"))
    #expect(path.contains("space_id=3"))
    #expect(path.contains("ids=101%2C102"))
    #expect(path.contains("query=back"))
  }

  @Test("401 throws unauthorized on list")
  func listUnauthorized() async throws {
    let client = try makeClient(.returning(statusCode: 401))
    await #expect(throws: KaitenError.self) {
      _ = try await client.listTags()
    }
  }

  @Test("403 throws unexpectedResponse on list")
  func listForbidden() async throws {
    let client = try makeClient(.returning(statusCode: 403))
    await expectUnexpectedResponse(statusCode: 403) {
      _ = try await client.listTags()
    }
  }

  // MARK: - Add

  @Test("200 returns created Tag and sends name in the body")
  func addSuccess() async throws {
    let json = """
      {
        "created": "2023-01-02T10:00:00.000Z",
        "updated": "2023-01-02T10:00:00.000Z",
        "id": 102,
        "name": "frontend",
        "company_id": 7,
        "color": 2,
        "archived": false
      }
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    let tag = try await client.addTag(name: "frontend")
    #expect(tag.id == 102)
    #expect(tag.name == "frontend")
    #expect(tag.company_id == 7)
    #expect(tag.archived == false)

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .post)
    #expect(recorded.request.path == "/tags")

    let body = try #require(recorded.body)
    var bytes: [UInt8] = []
    for try await chunk in body { bytes.append(contentsOf: chunk) }
    let sent = try #require(
      try JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any])
    #expect(sent["name"] as? String == "frontend")
  }

  @Test("add forwards documented query parameters")
  func addSendsQueryParameters() async throws {
    let json = """
      {"id": 103, "name": "qa"}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try makeClient(transport)

    _ = try await client.addTag(
      name: "qa", ids: "1,2", query: "qa", spaceId: 3, limit: 5, offset: 1)

    let recorded = try #require(transport.recordedRequests.first)
    let path = try #require(recorded.request.path)
    #expect(path.contains("ids=1%2C2"))
    #expect(path.contains("query=qa"))
    #expect(path.contains("space_id=3"))
    #expect(path.contains("limit=5"))
    #expect(path.contains("offset=1"))
  }

  @Test("400 throws unexpectedResponse on add")
  func addValidationError() async throws {
    let client = try makeClient(.returning(statusCode: 400, body: #"{"message": "invalid"}"#))
    await expectUnexpectedResponse(statusCode: 400) {
      _ = try await client.addTag(name: "")
    }
  }

  @Test("401 throws unauthorized on add")
  func addUnauthorized() async throws {
    let client = try makeClient(.returning(statusCode: 401))
    await #expect(throws: KaitenError.self) {
      _ = try await client.addTag(name: "test")
    }
  }
}
