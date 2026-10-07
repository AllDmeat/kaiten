import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("Sprint Summary")
struct SprintSummaryTests {

  @Test("getSprintSummary 200 returns summary")
  @available(*, deprecated)
  func success() async throws {
    let json = """
      {"id": 5, "title": "Sprint 5", "velocity_details": {"by_members": [{"user_id": 1, "velocity": 13}]}, "children_velocity_details": {"by_members": []}}
      """
    let transport = MockClientTransport.returning(statusCode: 200, body: json)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "t", transport: transport)

    let summary = try await client.getSprintSummary(id: 5)
    #expect(summary.id == 5)
    let byMembers = try #require(summary.velocity_details?.by_members)
    #expect(byMembers.count == 1)
    #expect(byMembers[0].additionalProperties.value["velocity"] as? Int == 13)
    #expect(summary.children_velocity_details?.by_members?.isEmpty == true)
  }

  @Test("getSprintSummary 404 throws notFound")
  @available(*, deprecated)
  func notFound() async throws {
    let transport = MockClientTransport.returning(statusCode: 404)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "t", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.getSprintSummary(id: 999)
    }
  }

  @Test("getSprintSummary 401 throws unauthorized")
  @available(*, deprecated)
  func unauthorized() async throws {
    let transport = MockClientTransport.returning(statusCode: 401)
    let client = try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "t", transport: transport)

    await #expect(throws: KaitenError.self) {
      _ = try await client.getSprintSummary(id: 5)
    }
  }
}
