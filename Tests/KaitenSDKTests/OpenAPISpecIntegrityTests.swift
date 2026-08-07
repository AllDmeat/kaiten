import Foundation
import Testing

@testable import KaitenSDK

/// Guards against schema patterns that `swift-openapi-generator` drops silently.
///
/// When a property's schema is `anyOf: [$ref, 'null']`, the generator emits no
/// stored property for it at all. Nothing fails: the spec still declares the
/// field, the package still builds, and every existing test still passes — the
/// data simply never reaches callers. These tests make that failure loud.
@Suite("OpenAPI spec integrity")
struct OpenAPISpecIntegrityTests {

  private static var specURL: URL {
    URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()  // KaitenSDKTests
      .deletingLastPathComponent()  // Tests
      .deletingLastPathComponent()  // repository root
      .appendingPathComponent("openapi/kaiten.yaml")
  }

  // MARK: - Structural guard

  /// A property declared as `anyOf: [$ref, 'null']` anywhere in the spec.
  private struct NullableRefProperty: CustomStringConvertible {
    let schema: String
    let property: String
    let line: Int

    var description: String { "\(schema).\(property) (kaiten.yaml:\(line))" }
  }

  /// Scans `components/schemas` for the pattern.
  ///
  /// The spec is machine-formatted with fixed indentation, so a line scan is
  /// enough and keeps the test free of a YAML dependency:
  ///   - `    SchemaName:`        (4 spaces)
  ///   - `        property_name:` (8 spaces)
  ///   - `          anyOf:`       (10 spaces)
  private static func findNullableRefProperties() throws -> [NullableRefProperty] {
    let source = try String(contentsOf: specURL, encoding: .utf8)
    let lines = source.components(separatedBy: .newlines)

    guard let schemasIndex = lines.firstIndex(of: "  schemas:") else {
      Issue.record("openapi/kaiten.yaml has no components/schemas section")
      return []
    }

    var found: [NullableRefProperty] = []
    var currentSchema = "?"
    var currentProperty = "?"

    for index in schemasIndex..<lines.count {
      let line = lines[index]

      if line.hasPrefix("    ") && !line.hasPrefix("     ") && line.hasSuffix(":") {
        currentSchema = line.trimmingCharacters(in: .whitespaces).dropLast().description
        continue
      }
      if line.hasPrefix("        ") && !line.hasPrefix("         ") && line.hasSuffix(":") {
        currentProperty = line.trimmingCharacters(in: .whitespaces).dropLast().description
        continue
      }
      guard line.trimmingCharacters(in: .whitespaces) == "anyOf:" else { continue }

      // Collect the anyOf members: subsequent lines more indented than `anyOf:`.
      let anyOfIndent = line.prefix { $0 == " " }.count
      var hasRef = false
      var hasNull = false
      var cursor = index + 1
      while cursor < lines.count {
        let member = lines[cursor]
        let trimmed = member.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
          cursor += 1
          continue
        }
        guard member.prefix(while: { $0 == " " }).count >= anyOfIndent else { break }
        if trimmed.hasPrefix("- $ref:") || trimmed.hasPrefix("$ref:") { hasRef = true }
        if trimmed == "- type: 'null'" || trimmed == "type: 'null'" { hasNull = true }
        cursor += 1
      }

      if hasRef && hasNull {
        found.append(
          NullableRefProperty(
            schema: currentSchema, property: currentProperty, line: index + 1))
      }
    }
    return found
  }

  @Test("no property uses anyOf: [$ref, 'null'] — the generator drops those silently")
  func noNullableRefProperties() throws {
    let offenders = try Self.findNullableRefProperties()
    #expect(
      offenders.isEmpty,
      """
      These properties are declared in openapi/kaiten.yaml but will NOT exist on the \
      generated Swift types — swift-openapi-generator drops `anyOf: [$ref, 'null']` \
      without any diagnostic:

      \(offenders.map { "  - \($0)" }.joined(separator: "\n"))

      Use a plain `$ref` instead. The property is optional, so the synthesized decoder \
      already maps an explicit JSON `null` to `nil`.
      """)
  }

  // MARK: - Behavioural guard

  /// Every property the spec declares must survive a decode/encode round trip.
  ///
  /// If the generator dropped a property, the decoder ignores that key on the way in
  /// and the encoder omits it on the way out — so a round trip is enough to catch it
  /// without referencing a member that may not compile.
  private func assertRoundTrips<T: Codable & Sendable>(
    _ json: String,
    as type: T.Type,
    expecting keys: [String],
    sourceLocation: SourceLocation = #_sourceLocation
  ) throws {
    let decoded = try JSONDecoder().decode(T.self, from: Data(json.utf8))
    let reencoded = try JSONEncoder().encode(decoded)
    let object =
      try JSONSerialization.jsonObject(with: reencoded) as? [String: Any] ?? [:]

    let missing = keys.filter { object[$0] == nil }
    #expect(
      missing.isEmpty,
      """
      \(T.self) lost \(missing.count) property/properties declared in openapi/kaiten.yaml: \
      \(missing.joined(separator: ", ")). They are almost certainly declared as \
      `anyOf: [$ref, 'null']`, which swift-openapi-generator drops silently.
      """,
      sourceLocation: sourceLocation)
  }

  @Test("CardBlocker keeps its nested card and user objects")
  func cardBlockerKeepsNestedObjects() throws {
    let json = """
      {
        "id": 1,
        "reason": "Waiting for design",
        "card_id": 42,
        "released": false,
        "blocked_card": {"id": 7, "title": "Blocked card"},
        "card": {"id": 8, "title": "Blocking card"},
        "blocker": {"id": 9, "full_name": "Ann"}
      }
      """
    try assertRoundTrips(
      json,
      as: Components.Schemas.CardBlocker.self,
      expecting: ["blocked_card", "card", "blocker"])

    // Referencing the properties directly turns a regression into a compile error,
    // which is louder than a failing assertion.
    let blocker = try JSONDecoder().decode(
      Components.Schemas.CardBlocker.self, from: Data(json.utf8))
    #expect(blocker.blocked_card?.title == "Blocked card")
    #expect(blocker.card?.title == "Blocking card")
    #expect(blocker.blocker?.full_name == "Ann")
  }

  @Test("Automation keeps its trigger and conditions objects")
  func automationKeepsNestedObjects() throws {
    let json = """
      {
        "id": "uid-1",
        "type": "on_action",
        "status": "active",
        "trigger": {"type": "card_created", "hasToFireOnCardCreation": true},
        "conditions": {"clause": "and", "conditions": []},
        "actions": [{"type": "add_tag"}]
      }
      """
    try assertRoundTrips(
      json,
      as: Components.Schemas.Automation.self,
      expecting: ["trigger", "conditions", "actions"])
  }
}
