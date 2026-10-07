import Foundation
import Testing

@testable import KaitenSDK

/// FR-043: nullability and undeclared fields observed in live API responses.
@Suite("LiveNullability")
struct LiveNullabilityTests {

  private func client(_ json: String) throws -> KaitenClient {
    try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token",
      transport: MockClientTransport.returning(statusCode: 200, body: json))
  }

  @Test("External link decodes null description, uid and external_link_uid")
  func externalLink() async throws {
    let links = try await client(
      """
      [{"id": 5, "url": "https://example.com", "description": null, "card_id": 42,
        "external_link_id": 5, "uid": "link-uid", "external_link_uid": null}]
      """
    ).listExternalLinks(cardId: 42)
    #expect(links[0].description == nil)
    #expect(links[0].uid == "link-uid")
    #expect(links[0].external_link_uid == nil)
  }

  @Test("Checklist item decodes null user_id")
  func checklistItemUserId() async throws {
    let checklist = try await client(
      """
      {"id": 1, "name": "Checklist", "items": [{"id": 2, "text": "Item", "user_id": null}]}
      """
    ).getChecklist(cardId: 42, checklistId: 1)
    #expect(checklist.items?[0].id == 2)
    #expect(checklist.items?[0].user_id == nil)
  }

  @Test("Card tag decodes created and updated")
  func cardTagTimestamps() async throws {
    let tags = try await client(
      """
      [{"id": 1, "name": "tag", "color": 3, "card_id": 42, "tag_id": 1,
        "created": "2025-01-01T00:00:00.000Z", "updated": "2025-01-02T00:00:00.000Z"}]
      """
    ).listCardTags(cardId: 42)
    #expect(tags[0].created == "2025-01-01T00:00:00.000Z")
    #expect(tags[0].updated == "2025-01-02T00:00:00.000Z")
  }

  @Test("Company group decodes company_id, condition and named_permissions")
  func groupFields() async throws {
    let groups = try await client(
      """
      [{"id": 1, "uid": "group-uid", "name": "Group", "company_id": 7, "condition": 1,
        "named_permissions": {"tags": true}}]
      """
    ).listGroups()
    #expect(groups[0].company_id == 7)
    #expect(groups[0].condition == 1)
    #expect(groups[0].named_permissions?.additionalProperties.value["tags"] as? Bool == true)
  }

  @Test("Tree entity role decodes card invite_members permission")
  func treeEntityRoleInviteMembers() async throws {
    let roles = try await client(
      """
      [{"id": "role-uid", "name": "Role", "permissions": {"space": {"card": {"invite_members": true}}}}]
      """
    ).listTreeEntityRoles()
    #expect(roles[0].permissions?.space?.card?.invite_members == true)
  }

  @Test("Document access record decodes role id lists and own_* fields")
  func documentAccessRecord() async throws {
    let document = try await client(
      """
      {"uid": "doc-uid", "access_record": {"role": 1, "role_ids": ["role-a"],
        "groups_role_ids": ["role-b"], "own_role": null, "own_role_ids": null,
        "own_groups_role_ids": null, "own_access_mod": null}}
      """
    ).getDocument(uid: "doc-uid")
    #expect(document.access_record?.role_ids == ["role-a"])
    #expect(document.access_record?.groups_role_ids == ["role-b"])
    #expect(document.access_record?.own_role == nil)
    #expect(document.access_record?.own_access_mod == nil)
  }

  @Test("Document group decodes public_site_url")
  func documentGroupPublicSiteUrl() async throws {
    let group = try await client(
      """
      {"uid": "group-uid", "public_site_url": "https://docs.example.com"}
      """
    ).getDocumentGroup(uid: "group-uid")
    #expect(group.public_site_url == "https://docs.example.com")
  }

  @Test("Automation trigger decodes created; null trigger and conditions decode")
  func automationTrigger() async throws {
    let automations = try await client(
      """
      [{"id": "a1", "trigger": {"type": "card_created", "created": "2025-01-01T00:00:00.000Z"}},
       {"id": "a2", "trigger": null, "conditions": null}]
      """
    ).listAutomations(spaceId: 1)
    #expect(automations[0].trigger?.created == "2025-01-01T00:00:00.000Z")
    #expect(automations[1].trigger == nil)
    #expect(automations[1].conditions == nil)
  }

  @Test("Card blocker decodes fts_version")
  func cardBlockerFtsVersion() async throws {
    let blockers = try await client(
      """
      [{"id": 1, "uid": "blocker-uid", "card_id": 42, "fts_version": "3"}]
      """
    ).listCardBlockers(cardId: 42)
    #expect(blockers[0].fts_version == "3")
  }
}
