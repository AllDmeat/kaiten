import ArgumentParser
import Testing

@testable import kaiten

@Suite("JSON output trimming")
struct JSONOutputTests {
  /// A card shaped like the API returns it: scalars, ID references, and whole embedded entities.
  private let card: [String: Any] = [
    "id": 42,
    "title": "Fix login redirect",
    "owner_id": 7,
    "tag_ids": [4, 9],
    "files": [],
    "owner": ["id": 7, "full_name": "Aleksey Berezka"],
    "tags": [["id": 4, "name": "backend"]],
    "children": [
      [
        "id": 43,
        "title": "Child",
        "children": [["id": 51, "title": "Grandchild"]],
      ]
    ],
  ]

  private func object(_ value: Any) throws -> [String: Any] {
    try #require(value as? [String: Any])
  }

  @Test("By default scalars survive and nested entities are dropped")
  func dropsNestedByDefault() throws {
    let trimmed = try object(JSONOutput.trim(card, expand: []))

    #expect(trimmed["id"] as? Int == 42)
    #expect(trimmed["owner_id"] as? Int == 7)
    #expect(trimmed["tag_ids"] as? [Int] == [4, 9], "an array of IDs is scalar")
    #expect(trimmed["files"] as? [Int] != nil, "an empty array is indistinguishable from scalars")
    #expect(trimmed["owner"] == nil)
    #expect(trimmed["tags"] == nil)
    #expect(trimmed["children"] == nil)
  }

  @Test("Named fields are expanded, others still dropped")
  func expandsNamedField() throws {
    let trimmed = try object(JSONOutput.trim(card, expand: ["owner"]))

    #expect(try object(#require(trimmed["owner"]))["full_name"] as? String == "Aleksey Berezka")
    #expect(trimmed["tags"] == nil)
    #expect(trimmed["owner_id"] as? Int == 7, "expanding adds, it does not replace the reference")
  }

  @Test("Expansion stops after one level")
  func expandsOneLevelOnly() throws {
    let trimmed = try object(JSONOutput.trim(card, expand: ["children"]))
    let children = try #require(trimmed["children"] as? [Any])
    let child = try object(#require(children.first))

    #expect(child["id"] as? Int == 43)
    #expect(child["children"] == nil, "a child's own children are not expanded")
  }

  @Test("'all' expands every nested field")
  func expandsAll() throws {
    let trimmed = try object(JSONOutput.trim(card, expand: [JSONOutput.expandAllKeyword]))

    #expect(trimmed["owner"] != nil)
    #expect(trimmed["tags"] != nil)
    #expect(trimmed["children"] != nil)
  }

  @Test("Array responses are trimmed element by element")
  func trimsArrayResponses() throws {
    let trimmed = try #require(JSONOutput.trim([card, card], expand: ["owner"]) as? [Any])

    #expect(trimmed.count == 2)
    for element in trimmed {
      let card = try object(element)
      #expect(card["owner"] != nil)
      #expect(card["tags"] == nil)
    }
  }

  // MARK: - Pagination

  @Test("Paginated responses are trimmed through the envelope, not dropped as a nested field")
  func trimsThroughPageEnvelope() throws {
    let page: [String: Any] = ["items": [card], "offset": 0, "limit": 2, "hasMore": true]

    let trimmed = try object(JSONOutput.trim(page, expand: ["owner"]))
    let items = try #require(trimmed["items"] as? [Any])
    let row = try object(#require(items.first))

    #expect(trimmed["hasMore"] as? Bool == true, "page metadata survives")
    #expect(row["id"] as? Int == 42, "rows survive rather than being dropped with the envelope")
    #expect(row["owner"] != nil)
    #expect(row["tags"] == nil)
  }

  @Test("Expandable fields of a page are its rows', not the envelope's")
  func reportsRowFieldsForPage() {
    let page: [String: Any] = ["items": [card], "offset": 0, "limit": 2, "hasMore": true]

    #expect(JSONOutput.expandableFields(in: page) == ["owner", "tags", "children", "files"])
  }

  @Test("An entity that merely has items is not mistaken for a page")
  func doesNotMistakeEntityForPage() throws {
    let checklist: [String: Any] = ["id": 3, "items": [["id": 9, "text": "Step"]]]

    let trimmed = try object(JSONOutput.trim(checklist, expand: []))

    #expect(trimmed["items"] == nil, "checklist items are a nested entity, not a page payload")
    #expect(JSONOutput.expandableFields(in: checklist) == ["items"])
  }

  @Test("Expanding an empty result set is allowed, not a validation error")
  func allowsExpandOnEmptyResult() throws {
    let trimmed = try #require(JSONOutput.trim([], expand: ["owner"]) as? [Any])

    #expect(trimmed.isEmpty)
  }

  // MARK: - Diagnostics

  @Test("Unknown expand field is rejected")
  func rejectsUnknownField() {
    #expect(throws: ValidationError.self) {
      _ = try JSONOutput.trim(card, expand: ["ownr"])
    }
  }

  @Test("Expanding a flat response is rejected")
  func rejectsExpandOnFlatResponse() {
    let user: [String: Any] = ["id": 7, "full_name": "Aleksey Berezka"]

    #expect(throws: ValidationError.self) {
      _ = try JSONOutput.trim(user, expand: ["manager"])
    }
  }

  @Test("Expandable fields are derived from the response")
  func reportsExpandableFields() {
    #expect(JSONOutput.expandableFields(in: card) == ["owner", "tags", "children", "files"])
  }

  @Test("An empty collection stays expandable, so the same flag works on every row")
  func acceptsExpandOfEmptyCollection() throws {
    let untagged: [String: Any] = ["id": 42, "tags": []]

    #expect(JSONOutput.expandableFields(in: untagged).contains("tags"))
    let trimmed = try object(JSONOutput.trim(untagged, expand: ["tags"]))
    #expect(trimmed["tags"] as? [Int] != nil)
  }

  @Test("Expandable fields of an array response union its elements")
  func unionsExpandableFieldsAcrossElements() {
    let first: [String: Any] = ["id": 1, "owner": ["id": 7]]
    let second: [String: Any] = ["id": 2, "board": ["id": 5]]

    #expect(JSONOutput.expandableFields(in: [first, second]) == ["owner", "board"])
  }

  // MARK: - Rendering

  private struct Owner: Encodable {
    var id: Int
    var fullName: String
  }

  private struct Encoded: Encodable {
    var id: Int
    var archived: Bool
    var size: Double
    var ownerId: Int
    var owner: Owner
  }

  private let encodable = Encoded(
    id: 42,
    archived: false,
    size: 3,
    ownerId: 7,
    owner: Owner(id: 7, fullName: "Aleksey Berezka")
  )

  @Test("Rendered output is compact and trimmed")
  func rendersCompactTrimmedJSON() throws {
    let rendered = try renderJSON(encodable)

    #expect(rendered == #"{"archived":false,"id":42,"ownerId":7,"size":3}"#)
  }

  @Test("Rendered output keeps expanded entities")
  func rendersExpandedEntities() throws {
    let rendered = try renderJSON(encodable, expand: ["owner"])

    #expect(rendered.contains(#""owner":{"fullName":"Aleksey Berezka","id":7}"#))
  }

  @Test("Booleans survive the trimming round trip as booleans")
  func preservesBooleans() throws {
    let rendered = try renderJSON(encodable)

    #expect(rendered.contains(#""archived":false"#), "a bool must not degrade into 0")
  }
}
