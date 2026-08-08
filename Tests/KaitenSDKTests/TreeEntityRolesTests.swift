import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("TreeEntityRoles")
struct TreeEntityRolesTests {

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

  /// Sanitized live response. The API answers with an array even though the
  /// documentation declares a single object, uses `permissions` where the
  /// documentation says `role_permissions`, and adds `company_uid` and `locked`
  /// the documentation does not mention.
  private static let listFixture = """
    [{
      "id": "role-uid-1",
      "created": "2025-10-20T14:45:40.507Z",
      "updated": "2025-10-21T18:25:12.663Z",
      "name": "Reviewer",
      "sort_order": 1.3732937753954515,
      "new_permissions_default_value": true,
      "company_uid": "company-uid-1",
      "locked": null,
      "permissions": {
        "root": {"move": false, "share": true, "create": false, "import": false},
        "space": {
          "card": {
            "move": true, "read": true, "create": true, "delete": true, "update": true,
            "comment": true, "read_own": false,
            "properties": {"id_101": {"read": true}}
          },
          "read": true,
          "board": {"read": true, "create": false, "delete": false, "update": false},
          "share": true,
          "addons": {"read": false, "update": false},
          "create": false,
          "delete": false,
          "import": true,
          "update": false,
          "webhook": {"read": false, "delete": false, "update": false},
          "workflow": {"read": true, "delete": true, "update": true},
          "iteration": {"read": true, "delete": true, "update": true},
          "automation": {"read": false, "delete": false, "update": false},
          "i_calendar": {"read": false, "delete": false, "update": false},
          "user_group": {"read": true},
          "move_within": false,
          "restriction": {"read": false, "delete": false, "update": false},
          "move_outside": false,
          "view_settings": false,
          "access_control": false,
          "external_webhook": {"read": false, "delete": false, "update": false},
          "public_filters_manage": true
        },
        "document": {
          "read": true, "share": true, "create": true, "delete": false, "import": true,
          "update": false, "comment": true, "user_group": {"read": true},
          "move_within": false, "move_outside": false, "access_control": false
        },
        "story_map": {
          "read": true, "share": true, "create": false, "delete": false, "import": true,
          "update": false, "user_group": {"read": true},
          "move_within": false, "move_outside": false, "access_control": false
        },
        "document_group": {
          "read": true, "share": true, "create": false, "delete": false, "import": true,
          "update": false, "user_group": {"read": true},
          "move_within": false, "move_outside": false, "access_control": false
        }
      }
    },
    {
      "id": "role-uid-2",
      "created": "2025-01-10T09:00:00.000Z",
      "updated": "2025-01-10T09:00:00.000Z",
      "name": "Editor",
      "sort_order": 2,
      "new_permissions_default_value": false,
      "company_uid": null,
      "locked": null,
      "permissions": {
        "root": {"move": true, "share": true, "create": true, "import": true},
        "space": {
          "card": {
            "move": true, "read": true, "create": true, "delete": true, "update": true,
            "comment": true, "read_own": false,
            "properties": true
          },
          "read": true,
          "board": {"read": true, "create": true, "delete": true, "update": true}
        }
      }
    }]
    """

  // MARK: - List

  @Test("200 returns array of TreeEntityRole")
  func listSuccess() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: Self.listFixture))

    let roles = try await client.listTreeEntityRoles()
    #expect(roles.count == 2)

    let custom = roles[0]
    #expect(custom.id == "role-uid-1")
    #expect(custom.name == "Reviewer")
    #expect(custom.sort_order == 1.3732937753954515)
    #expect(custom.new_permissions_default_value == true)
    #expect(custom.company_uid == "company-uid-1")
    #expect(custom.locked == nil)
    #expect(custom.role_permissions == nil)

    let permissions = try #require(custom.permissions)
    #expect(permissions.root?.move == false)
    #expect(permissions.root?.share == true)
    #expect(permissions.root?._import == false)

    let space = try #require(permissions.space)
    #expect(space.read == true)
    #expect(space.public_filters_manage == true)
    #expect(space.webhook?.read == false)
    #expect(space.webhooks == nil)
    #expect(space.workflow?.additionalProperties.value["read"] as? Bool == true)

    let card = try #require(space.card)
    #expect(card.read == true)
    #expect(card.read_own == false)
    // Per-property permissions arrive as an object keyed by custom property id.
    #expect(card.properties?.value1 == nil)
    #expect(card.properties?.value2 != nil)

    #expect(permissions.document?.comment == true)
    #expect(permissions.document_group?.read == true)
    #expect(permissions.story_map?.access_control == false)

    let builtIn = roles[1]
    #expect(builtIn.company_uid == nil)
    #expect(builtIn.sort_order == 2)
    // A blanket boolean grants or denies all custom properties at once.
    #expect(builtIn.permissions?.space?.card?.properties?.value1 == true)
    #expect(builtIn.permissions?.space?.card?.properties?.value2 == nil)
  }

  @Test("list requests GET /tree-entity-roles")
  func listRequestShape() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: "[]")
    let client = try makeClient(transport)

    _ = try await client.listTreeEntityRoles()

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .get)
    #expect(recorded.request.path == "/tree-entity-roles")
  }

  @Test("200 with empty body returns empty array")
  func listEmptyBody() async throws {
    let client = try makeClient(.returning(statusCode: 200, body: ""))
    let roles = try await client.listTreeEntityRoles()
    #expect(roles.isEmpty)
  }

  @Test("401 throws unauthorized")
  func listUnauthorized() async throws {
    let client = try makeClient(.returning(statusCode: 401))
    await #expect(throws: KaitenError.self) {
      _ = try await client.listTreeEntityRoles()
    }
  }

  @Test("403 throws unexpectedResponse")
  func listForbidden() async throws {
    let client = try makeClient(.returning(statusCode: 403))
    await expectUnexpectedResponse(statusCode: 403) {
      _ = try await client.listTreeEntityRoles()
    }
  }
}
