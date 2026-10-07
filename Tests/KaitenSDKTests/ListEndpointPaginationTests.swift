import ArgumentParser
import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK
@testable import kaiten

/// Pagination of list endpoints the API caps at 100 items per request (FR-035).
@Suite("List endpoint pagination")
struct ListEndpointPaginationTests {
  private func makeClient(_ transport: MockClientTransport) throws -> KaitenClient {
    try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)
  }

  private func queryItems(_ transport: MockClientTransport, at index: Int = 0) throws -> [String:
    String]
  {
    let path = try #require(transport.recordedRequests[index].request.path)
    let items = URLComponents(string: path)?.queryItems ?? []
    return Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value ?? "") })
  }

  private func collect<T: Sendable>(_ stream: AsyncThrowingStream<T, Error>) async throws -> [T] {
    var result: [T] = []
    for try await item in stream { result.append(item) }
    return result
  }

  @Test("limit and offset are sent by every capped list method")
  func limitAndOffsetSent() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: "[]")
    let client = try makeClient(transport)

    _ = try await client.listSpaces(limit: 10, offset: 20)
    _ = try await client.getCardComments(cardId: 1, limit: 10, offset: 20)
    _ = try await client.listCardChildren(cardId: 1, limit: 10, offset: 20)
    _ = try await client.getCardTimeLogs(cardId: 1, limit: 10, offset: 20)
    _ = try await client.listGroupUsers(groupUid: "group-uid", limit: 10, offset: 20)
    _ = try await client.listCardAllowedUsers(cardId: 1, limit: 10, offset: 20)

    #expect(transport.recordedRequests.count == 6)
    for index in transport.recordedRequests.indices {
      let query = try queryItems(transport, at: index)
      #expect(query["limit"] == "10")
      #expect(query["offset"] == "20")
    }
  }

  @Test("Omitted limit and offset are not sent")
  func omittedNotSent() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: "[]")
    _ = try await makeClient(transport).listSpaces()
    #expect(try queryItems(transport).isEmpty)
  }

  @Test("Space users send limit and last_user_id, never offset")
  func spaceUsersCursorSent() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: "[]")
    _ = try await makeClient(transport).listSpaceUsers(spaceId: 1, limit: 500, lastUserId: 7)
    let query = try queryItems(transport)
    #expect(query["limit"] == "500")
    #expect(query["last_user_id"] == "7")
    #expect(query["offset"] == nil)
  }

  @Test("Out-of-range pagination fails before the request", arguments: [(0, 0), (101, 0), (1, -1)])
  func capsEnforced(limit: Int, offset: Int) async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: "[]")
    let client = try makeClient(transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.listSpaces(limit: limit, offset: offset)
    }
    await #expect(throws: KaitenError.self) {
      _ = try await client.getCardComments(cardId: 1, limit: limit, offset: offset)
    }
    await #expect(throws: KaitenError.self) {
      _ = try await client.listCardChildren(cardId: 1, limit: limit, offset: offset)
    }
    await #expect(throws: KaitenError.self) {
      _ = try await client.getCardTimeLogs(cardId: 1, limit: limit, offset: offset)
    }
    await #expect(throws: KaitenError.self) {
      _ = try await client.listGroupUsers(groupUid: "group-uid", limit: limit, offset: offset)
    }
    await #expect(throws: KaitenError.self) {
      _ = try await client.listCardAllowedUsers(cardId: 1, limit: limit, offset: offset)
    }
    #expect(transport.recordedRequests.isEmpty)
  }

  @Test("Space users accept up to 500 and reject 501")
  func spaceUsersCap() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: "[]")
    let client = try makeClient(transport)

    _ = try await client.listSpaceUsers(spaceId: 1, limit: 500)
    await #expect(throws: KaitenError.self) {
      _ = try await client.listSpaceUsers(spaceId: 1, limit: 501)
    }
    #expect(transport.recordedRequests.count == 1)
  }

  @Test("allSpaces walks offsets until a short page")
  func allSpacesPages() async throws {
    let transport = MockClientTransport { request, _, _, _ in
      let body =
        request.path?.contains("offset=0") == true
        ? #"[{"id": 1, "title": "A"}, {"id": 2, "title": "B"}]"#
        : #"[{"id": 3, "title": "C"}]"#
      var fields = HTTPFields()
      fields[.contentType] = "application/json"
      return (HTTPResponse(status: .ok, headerFields: fields), .init(body))
    }
    let spaces = try await collect(try makeClient(transport).allSpaces(pageSize: 2))

    #expect(spaces.map(\.id) == [1, 2, 3])
    #expect(try queryItems(transport, at: 1)["offset"] == "2")
  }

  /// Serves space-user pages keyed by the `last_user_id` cursor; an unknown cursor gets `[]`.
  private func spaceUserPages(_ pages: [String: String]) -> MockClientTransport {
    MockClientTransport { request, _, _, _ in
      let items = URLComponents(string: request.path ?? "")?.queryItems ?? []
      let cursor = items.first { $0.name == "last_user_id" }?.value ?? ""
      var fields = HTTPFields()
      fields[.contentType] = "application/json"
      return (HTTPResponse(status: .ok, headerFields: fields), .init(pages[cursor] ?? "[]"))
    }
  }

  @Test("allSpaceUsers advances the cursor by the greatest id, not the last one")
  func allSpaceUsersCursor() async throws {
    let transport = spaceUserPages([
      "": #"[{"id": 7}, {"id": 2}, {"id": 5}]"#,
      "7": #"[{"id": 9}]"#,
    ])
    let users = try await collect(try makeClient(transport).allSpaceUsers(spaceId: 1, pageSize: 3))

    #expect(users.map(\.id) == [7, 2, 5, 9])
    let second = try queryItems(transport, at: 1)
    #expect(second["last_user_id"] == "7")
    #expect(second["offset"] == nil)
  }

  @Test("allSpaceUsers keeps going after a short page and stops on an empty one")
  func allSpaceUsersShortPage() async throws {
    let transport = spaceUserPages([
      "": #"[{"id": 3}, {"id": 1}]"#,
      "3": #"[{"id": 4}, {"id": 6}, {"id": 5}]"#,
    ])
    let users = try await collect(try makeClient(transport).allSpaceUsers(spaceId: 1, pageSize: 3))

    #expect(users.map(\.id) == [3, 1, 4, 6, 5])
    #expect(transport.recordedRequests.count == 3)
    #expect(try queryItems(transport, at: 2)["last_user_id"] == "6")
  }

  @Test("allSpaceUsers stops when the cursor does not advance")
  func allSpaceUsersStaleCursor() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: #"[{"id": 4}, {"id": 3}]"#)
    let users = try await collect(try makeClient(transport).allSpaceUsers(spaceId: 1, pageSize: 2))

    #expect(users.count == 4)
    #expect(transport.recordedRequests.count == 2)
  }

  @Test("listCustomProperties without includeValues sends no include_values")
  func customPropertiesOmitIncludeValues() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: "[]")
    _ = try await makeClient(transport).listCustomProperties()
    #expect(try queryItems(transport)["include_values"] == nil)
  }

  @available(*, deprecated)
  @Test("Deprecated includeValues overload still sends include_values")
  func customPropertiesDeprecatedIncludeValues() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: "[]")
    _ = try await makeClient(transport).listCustomProperties(includeValues: true)
    #expect(try queryItems(transport)["include_values"] == "true")
  }

  @Test("CLI rejects --include-values true before any request")
  func cliRejectsIncludeValues() async throws {
    let command = try ListCustomProperties.parse(["--include-values", "true"])
    await #expect(throws: ValidationError.self) {
      try await command.run()
    }
  }
}
